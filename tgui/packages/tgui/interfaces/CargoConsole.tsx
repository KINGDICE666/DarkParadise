import { declension_ru } from 'common/l10n';
import { sortBy } from 'es-toolkit';
import { useMemo, useState } from 'react';
import {
  Box,
  Button,
  DmIcon,
  Dropdown,
  Icon,
  Input,
  LabeledList,
  Modal,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { flow } from 'tgui-core/fp';
import { capitalize, createSearch } from 'tgui-core/string';
import { useBackend, useSharedState } from '../backend';
import { Window } from '../layouts';

export type CargoPackContent = {
  name: string;
  name_en?: string | null;
  icon?: string | null;
  icon_state?: string | null;
};

type CargoSupplyPack = SupplyPack & {
  contents: CargoPackContent[];
  cost: number;
  creditsCost: number;
  ref: string;
  has_sale: boolean;
  is_enough_techs: boolean;
  goody: boolean;
};

type CargoCatalogueData = {
  categories: Category[];
  supply_packs: CargoSupplyPack[];
};

type Payment = 'supply' | 'department' | 'personal';

type PaymentProps = {
  payment: Payment;
  setPayment: React.Dispatch<React.SetStateAction<Payment>>;
};

type PaymentData = {
  has_account: boolean;
  department_name: string | null;
  personal_markup: number;
};

type PaidCargoRequest = CargoRequest & {
  payer: string;
  cost: number;
  can_cancel: boolean;
};

type CargoDetailsData = {
  canapprove: boolean;
  requests: PaidCargoRequest[];
  orders: PaidCargoRequest[];
};

const useAvailablePayment = (payment: Payment): Payment => {
  const { data } = useBackend<PaymentData>();
  if (payment === 'department' && !data.department_name) {
    return 'supply';
  }
  if (payment === 'personal' && !data.has_account) {
    return 'supply';
  }
  return payment;
};

export const CargoConsole = (_props: unknown) => {
  const [contentsModal, setContentsModal] = useState<CargoPackContent[]>([]);
  const [contentsModalTitle, setContentsModalTitle] = useState<string>('');
  const [payment, setPayment] = useState<Payment>('supply');

  return (
    <Window width={1000} height={800} theme="cargo">
      <Window.Content>
        <Stack fill vertical>
          <ContentsModal
            contentsModal={contentsModal}
            setContentsModal={setContentsModal}
            contentsModalTitle={contentsModalTitle}
            setContentsModalTitle={setContentsModalTitle}
          />
          <StatusPane payment={payment} setPayment={setPayment} />
          <CataloguePane
            setContentsModal={setContentsModal}
            setContentsModalTitle={setContentsModalTitle}
            payment={payment}
          />
          <DetailsPane />
        </Stack>
      </Window.Content>
    </Window>
  );
};

export type ContentsModalProps<T = string> = {
  contentsModal: T[];
  setContentsModal: React.Dispatch<React.SetStateAction<T[]>>;
  contentsModalTitle: string;
  setContentsModalTitle: React.Dispatch<React.SetStateAction<string>>;
};

const ContentsModal = (properties: ContentsModalProps<CargoPackContent>) => {
  const {
    contentsModal,
    setContentsModal,
    contentsModalTitle,
    setContentsModalTitle,
  } = properties;

  const groupedContents = useMemo(() => {
    const grouped = new Map<
      string,
      { content: CargoPackContent; count: number }
    >();

    for (const content of contentsModal) {
      const key = `${content.icon}|${content.icon_state}|${content.name}`;
      const existing = grouped.get(key);
      if (existing) {
        existing.count += 1;
      } else {
        grouped.set(key, { content, count: 1 });
      }
    }

    return sortBy(
      [...grouped.values()],
      [(entry) => entry.content.name.toLowerCase()],
    );
  }, [contentsModal]);

  const totalItems = contentsModal.length;

  if (contentsModal.length && contentsModalTitle !== '') {
    return (
      <Modal
        maxWidth="75%"
        width={`${window.innerWidth}px`}
        maxHeight={`${window.innerHeight * 0.75}px`}
        mx="auto"
      >
        <Section
          title={`Содержимое: ${contentsModalTitle}`}
          buttons={
            <Button
              icon="times"
              onClick={() => {
                setContentsModal([]);
                setContentsModalTitle('');
              }}
            >
              Закрыть
            </Button>
          }
        >
          <Box maxHeight="20rem" overflowY="auto" overflowX="hidden">
            <Table>
              {groupedContents.map(({ content, count }, index) => {
                const dividerStyle =
                  index < groupedContents.length - 1
                    ? {
                        borderBottom: 'var(--divider-border)',
                      }
                    : undefined;
                return (
                  <Table.Row
                    key={`${content.icon}|${content.icon_state}|${content.name}`}
                  >
                    <Table.Cell
                      collapsing
                      width="42px"
                      verticalAlign="middle"
                      style={dividerStyle}
                    >
                      {content.icon && content.icon_state ? (
                        <DmIcon
                          icon={content.icon}
                          icon_state={content.icon_state}
                          fallback={<Icon name="box" color="gray" />}
                          width="32px"
                          height="32px"
                        />
                      ) : (
                        <Icon name="box" color="gray" />
                      )}
                    </Table.Cell>
                    <Table.Cell verticalAlign="middle" style={dividerStyle}>
                      {capitalize(content.name)}
                    </Table.Cell>
                    <Table.Cell
                      collapsing
                      textAlign="right"
                      verticalAlign="middle"
                      style={dividerStyle}
                    >
                      {count > 1 && (
                        <Box color="good" bold>
                          {`× ${count} шт.`}
                        </Box>
                      )}
                    </Table.Cell>
                  </Table.Row>
                );
              })}
            </Table>
          </Box>
        </Section>
      </Modal>
    );
  } else {
    return;
  }
};

type StatusPaneData = {
  is_public: boolean;
  credits: number;
  timeleft: number;
  moving: boolean;
  at_station: boolean;
};

const StatusPane = (properties: PaymentProps) => {
  const { act, data } = useBackend<StatusPaneData & PaymentData>();
  const {
    is_public,
    credits,
    timeleft,
    moving,
    at_station,
    has_account,
    department_name,
    personal_markup,
  } = data;
  const { setPayment } = properties;
  const payment = useAvailablePayment(properties.payment);
  const markupPercent = Math.round((personal_markup - 1) * 100);

  // Shuttle status text
  let statusText: string = '';
  let shuttleButtonText: string = '';
  if (!moving && !at_station) {
    statusText = 'Не на объекте';
    shuttleButtonText = 'Вызвать шаттл';
  } else if (!moving && at_station) {
    statusText = 'Пристыкован к объекту';
    shuttleButtonText = 'Вернуть шаттл';
  } else if (moving) {
    shuttleButtonText = 'В пути';
    statusText = `В пути к объекту (прилетит через: ${timeleft})`;
  }

  return (
    <Stack.Item>
      <Section title="Статус">
        <LabeledList>
          <LabeledList.Item label="Бюджет снабжения">
            {credits} кредит{declension_ru(credits, '', 'а', 'ов')}
          </LabeledList.Item>
          <LabeledList.Item label="Статус шаттла">
            {statusText}
          </LabeledList.Item>
          <LabeledList.Item label="Оплата">
            <Button
              selected={payment === 'supply'}
              onClick={() => setPayment('supply')}
            >
              Бюджет снабжения
            </Button>
            <Button
              selected={payment === 'department'}
              disabled={!department_name}
              tooltip={
                department_name
                  ? 'Запрос одобряет снабжение, оплата с бюджета вашего отдела'
                  : 'Ваш счёт не привязан к отделу'
              }
              onClick={() => setPayment('department')}
            >
              Бюджет отдела{department_name ? ` (${department_name})` : ''}
            </Button>
            <Button
              selected={payment === 'personal'}
              disabled={!has_account}
              tooltip={
                has_account
                  ? `Без одобрения снабжения, наценка ${markupPercent}%`
                  : 'Нет ID-карты с привязанным счётом'
              }
              onClick={() => setPayment('personal')}
            >
              Личный счёт (+{markupPercent}%)
            </Button>
          </LabeledList.Item>
          {!is_public && (
            <LabeledList.Item label="Управление">
              <Button disabled={moving} onClick={() => act('moveShuttle')}>
                {shuttleButtonText}
              </Button>
              <Button onClick={() => act('showMessages')}>
                Посмотреть сообщения ЦК
              </Button>
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>
    </Stack.Item>
  );
};

export type CataloguePaneProps<T = string> = {
  setContentsModal: React.Dispatch<React.SetStateAction<T[]>>;
  setContentsModalTitle: React.Dispatch<React.SetStateAction<string>>;
};

const CataloguePane = (
  properties: CataloguePaneProps<CargoPackContent> & { payment: Payment },
) => {
  const { act, data } = useBackend<CargoCatalogueData & PaymentData>();
  const { categories, supply_packs, personal_markup } = data;
  const payment = useAvailablePayment(properties.payment);
  const getPrice = (pack: CargoSupplyPack) =>
    payment === 'personal' && !pack.goody
      ? Math.round(pack.cost * personal_markup)
      : pack.cost;

  const [category, setCategory] = useSharedState(
    'category',
    'Чрезвычайные ситуации',
  );

  const [searchText, setSearchText] = useSharedState('search_text', '');

  const { setContentsModal, setContentsModalTitle } = properties;

  const packSearch = createSearch<CargoSupplyPack>(searchText, (crate) =>
    [
      crate.name,
      ...crate.contents.flatMap((content) => [
        content.name,
        content.name_en ?? '',
      ]),
    ].join('|'),
  );

  const targetCategory = !searchText
    ? categories.filter((c) => c.name === category)[0]?.category || category
    : null;

  const cratesToShow = flow([
    (supply_packs) =>
      supply_packs.filter((pack: CargoSupplyPack) => {
        if (searchText) {
          return true;
        }
        return pack.cat === targetCategory;
      }),
    (supply_packs) =>
      searchText ? supply_packs.filter(packSearch) : supply_packs,
    (supply_packs) =>
      sortBy<CargoSupplyPack>(supply_packs, [
        (pack) => pack.name.toLowerCase(),
      ]),
  ])(supply_packs);

  let titleText = 'Перечень грузов для заказа';
  if (searchText) {
    titleText = `Результаты поиска "${searchText}":`;
  } else if (category) {
    titleText = `Просмотр категории "${category}"`;
  }
  return (
    <Stack.Item>
      <Section
        title={titleText}
        buttons={
          <Dropdown
            width="190px"
            options={categories.map((r) => r.name)}
            selected={category}
            onSelected={(val) => setCategory(val)}
          />
        }
      >
        <Input
          fluid
          placeholder="Поиск"
          expensive
          onChange={setSearchText}
          mb={1}
        />
        <Box maxHeight={25} overflowY="auto" overflowX="hidden">
          <Table m="0.5rem">
            {cratesToShow.map((c, index) => {
              const firstContent = c.contents[0];
              const dividerStyle =
                index < cratesToShow.length - 1
                  ? { borderBottom: 'var(--divider-border)' }
                  : undefined;
              return (
                <Table.Row key={c.name}>
                  <Table.Cell
                    collapsing
                    width="42px"
                    verticalAlign="middle"
                    style={dividerStyle}
                  >
                    {firstContent?.icon && firstContent.icon_state ? (
                      <DmIcon
                        icon={firstContent.icon}
                        icon_state={firstContent.icon_state}
                        fallback={<Icon name="box" color="gray" />}
                        width="32px"
                        height="32px"
                      />
                    ) : (
                      <Icon name="box" color="gray" />
                    )}
                  </Table.Cell>
                  <Table.Cell bold verticalAlign="middle" style={dividerStyle}>
                    <Box
                      color={
                        !c.is_enough_techs
                          ? 'red'
                          : c.has_sale
                            ? 'good'
                            : 'default'
                      }
                    >
                      {c.name} ({getPrice(c)} кредит
                      {declension_ru(getPrice(c), '', 'а', 'ов')})
                    </Box>
                  </Table.Cell>
                  <Table.Cell
                    textAlign="right"
                    pr={1}
                    verticalAlign="middle"
                    style={dividerStyle}
                  >
                    <Button
                      icon="shopping-cart"
                      disabled={c.goody && payment !== 'personal'}
                      tooltip={
                        c.goody && payment !== 'personal'
                          ? 'Только за личный счёт'
                          : undefined
                      }
                      onClick={() =>
                        act('order', {
                          crate: c.ref,
                          multiple: 0,
                          payment,
                        })
                      }
                    >
                      Заказать 1
                    </Button>
                    <Button
                      icon="cart-plus"
                      disabled={c.goody && payment !== 'personal'}
                      onClick={() =>
                        act('order', {
                          crate: c.ref,
                          multiple: 1,
                          payment,
                        })
                      }
                    >
                      Заказать несколько
                    </Button>
                    <Button
                      icon="search"
                      onClick={() => {
                        setContentsModal(c.contents);
                        setContentsModalTitle(c.name);
                      }}
                    >
                      Содержимое
                    </Button>
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table>
        </Box>
      </Section>
    </Stack.Item>
  );
};

const DetailsPane = (_properties) => {
  const { act, data } = useBackend<CargoDetailsData>();
  const { requests, canapprove, orders } = data;
  return (
    <Section fill scrollable title="Details">
      <Box bold>Запросы</Box>
      <Table m="0.5rem">
        {requests.map((r) => (
          <Table.Row key={r.ordernum}>
            <Table.Cell>
              <Box>
                - №{r.ordernum}: {r.supply_type} для <b>{r.orderedby}</b>
              </Box>
              <Box italic>Причина: {r.comment}</Box>
              <Box italic>
                Оплата: {r.payer}, {r.cost} кредит
                {declension_ru(r.cost, '', 'а', 'ов')}
              </Box>
              <Box italic>Требуемые тех. уровни: {r.pack_techs}</Box>
            </Table.Cell>
            <Stack.Item textAlign="right">
              <Button
                color="green"
                disabled={!canapprove}
                onClick={() =>
                  act('approve', {
                    ordernum: r.ordernum,
                  })
                }
              >
                Одобрить
              </Button>
              <Button
                color="red"
                onClick={() =>
                  act('deny', {
                    ordernum: r.ordernum,
                  })
                }
              >
                Отказать
              </Button>
            </Stack.Item>
          </Table.Row>
        ))}
      </Table>
      <Box bold>Утверждённые заказы</Box>
      <Table m="0.5rem">
        {orders.map((r) => (
          <Table.Row key={r.ordernum}>
            <Table.Cell>
              <Box>
                - №{r.ordernum}: {r.supply_type} для <b>{r.orderedby}</b>
              </Box>
              <Box italic>Причина: {r.comment}</Box>
              <Box italic>Оплата: {r.payer}</Box>
            </Table.Cell>
            <Table.Cell textAlign="right">
              {r.can_cancel && (
                <Button
                  color="red"
                  onClick={() =>
                    act('cancel', {
                      ordernum: r.ordernum,
                    })
                  }
                >
                  Отменить
                </Button>
              )}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
