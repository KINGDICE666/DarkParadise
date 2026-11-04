import { declension_ru } from 'common/l10n';
import { sortBy } from 'es-toolkit';
import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  Modal,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { flow } from 'tgui-core/fp';
import { createSearch } from 'tgui-core/string';
import { useBackend, useSharedState } from '../backend';
import { Window } from '../layouts';

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
  const [contentsModal, setContentsModal] = useState<string[]>([]);
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

export type ContentsModalProps = {
  contentsModal: string[];
  setContentsModal: React.Dispatch<React.SetStateAction<string[]>>;
  contentsModalTitle: string;
  setContentsModalTitle: React.Dispatch<React.SetStateAction<string>>;
};

const ContentsModal = (properties: ContentsModalProps) => {
  const {
    contentsModal,
    setContentsModal,
    contentsModalTitle,
    setContentsModalTitle,
  } = properties;

  if (contentsModal.length && contentsModalTitle !== '') {
    return (
      <Modal
        maxWidth="75%"
        width={`${window.innerWidth}px`}
        maxHeight={`${window.innerHeight * 0.75}px`}
        mx="auto"
      >
        <Box width="100%" bold>
          <h1>Содержимое {contentsModalTitle}:</h1>
        </Box>
        <Box>
          {contentsModal.map((i) => (
            // This needs keying. I hate it.
            <Box key={i}>- {i}</Box>
          ))}
        </Box>
        <Box m={2}>
          <Button
            onClick={() => {
              setContentsModal([]);
              setContentsModalTitle('');
            }}
          >
            Close
          </Button>
        </Box>
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

export type CataloguePaneProps = {
  setContentsModal: React.Dispatch<React.SetStateAction<string[]>>;
  setContentsModalTitle: React.Dispatch<React.SetStateAction<string>>;
};

const CataloguePane = (
  properties: CataloguePaneProps & { payment: Payment },
) => {
  const { act, data } = useBackend<CataloguePaneData & PaymentData>();
  const { categories, supply_packs, personal_markup } = data;
  const payment = useAvailablePayment(properties.payment);
  const getPrice = (cost: number) =>
    payment === 'personal' ? Math.round(cost * personal_markup) : cost;

  const [category, setCategory] = useSharedState(
    'category',
    'Чрезвычайные ситуации',
  );

  const [searchText, setSearchText] = useSharedState('search_text', '');

  const { setContentsModal, setContentsModalTitle } = properties;

  const packSearch = createSearch<SupplyPack>(
    searchText,
    (crate) => crate.name,
  );

  const targetCategory = !searchText
    ? categories.filter((c) => c.name === category)[0]?.category || category
    : null;

  const cratesToShow = flow([
    (supply_packs) =>
      supply_packs.filter((pack: SupplyPack) => {
        if (searchText) {
          return true;
        }
        return pack.cat === targetCategory;
      }),
    (supply_packs) =>
      searchText ? supply_packs.filter(packSearch) : supply_packs,
    (supply_packs) =>
      sortBy<SupplyPack>(supply_packs, [(pack) => pack.name.toLowerCase()]),
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
            {cratesToShow.map((c) => (
              <Table.Row key={c.name}>
                <Table.Cell bold>
                  <Box
                    color={
                      !c.is_enough_techs
                        ? 'red'
                        : c.has_sale
                          ? 'good'
                          : 'default'
                    }
                  >
                    {c.name} ({getPrice(c.cost)} кредит
                    {declension_ru(getPrice(c.cost), '', 'а', 'ов')})
                  </Box>
                </Table.Cell>
                <Table.Cell textAlign="right" pr={1}>
                  <Button
                    icon="shopping-cart"
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
            ))}
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
