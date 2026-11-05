import {
  Box,
  Button,
  Collapsible,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { formatMoney } from 'tgui-core/format';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Material = {
  id: string;
  name: string;
  price: number;
  base_price: number;
  min_threshold: number;
  max_threshold: number;
  quantity: number;
  trend: number;
  requested: number;
  elastic: number;
};

type Data = {
  materials: Material[];
  hasId: BooleanLike;
  creditBalance: number;
  orderBalance: number;
  orderingPrivate: BooleanLike;
  canOrderCargo: BooleanLike;
  privateMarkup: number;
  crateFee: number;
  updateTime: number;
};

const BUY_AMOUNTS = [1, 5, 10, 25, 50];

const trendText = (trend: number) => {
  if (trend > 0) {
    return 'растёт';
  }
  if (trend < 0) {
    return 'падает';
  }
  return 'стабилен';
};

const trendColor = (trend: number) => {
  if (trend > 0) {
    return 'green';
  }
  if (trend < 0) {
    return 'red';
  }
  return 'label';
};

export const MatMarket = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    materials = [],
    hasId,
    creditBalance,
    orderBalance,
    orderingPrivate,
    canOrderCargo,
    privateMarkup,
    crateFee,
    updateTime,
  } = data;

  const multiplier = orderingPrivate ? privateMarkup : 1;
  const orderCrateFee = orderBalance ? 0 : crateFee;
  const sorted = [...materials].sort((a, b) => a.base_price - b.base_price);

  return (
    <Window width={900} height={620}>
      <Window.Content scrollable>
        <Section
          title="Галактическая биржа материалов"
          buttons={
            !!canOrderCargo && (
              <Button.Checkbox
                checked={!orderingPrivate}
                tooltip="Оплачивать покупки из бюджета отдела снабжения"
                onClick={() => act('toggle_budget')}
              >
                {orderingPrivate ? 'Личный счёт' : 'Бюджет снабжения'}
              </Button.Checkbox>
            )
          }
        >
          {!hasId ? (
            <NoticeBox danger>
              Для торговли нужна ID-карта с привязанным счётом.
            </NoticeBox>
          ) : (
            <Stack align="center">
              <Stack.Item grow>
                Баланс: <b>{formatMoney(creditBalance)}</b> кр.
              </Stack.Item>
              <Stack.Item grow>
                Текущий заказ: <b>{formatMoney(orderBalance)}</b> кр.
              </Stack.Item>
              <Stack.Item grow color={updateTime > 150 ? 'good' : 'average'}>
                Обновление курса через <b>{Math.round(updateTime / 10)} с</b>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="times"
                  disabled={!orderBalance}
                  onClick={() => act('clear')}
                >
                  Отменить заказ
                </Button>
              </Stack.Item>
            </Stack>
          )}
        </Section>
        {sorted.map((material) => {
          const suspended = material.price <= material.min_threshold;
          return (
            <Section key={material.id}>
              <Stack align="center">
                <Stack.Item width="14%" fontSize="120%" bold>
                  {material.name}
                </Stack.Item>
                <Stack.Item width="14%">
                  <Tooltip
                    content={`Курс колеблется от ${formatMoney(material.min_threshold)} до ${formatMoney(material.max_threshold)} кр. за лист`}
                  >
                    <Box>
                      Курс: <b>{formatMoney(material.price, 2)}</b> кр.
                    </Box>
                  </Tooltip>
                </Stack.Item>
                <Stack.Item width="12%" color={trendColor(material.trend)}>
                  Курс <b>{trendText(material.trend)}</b>
                </Stack.Item>
                <Stack.Item
                  width="12%"
                  color={
                    material.elastic < 33
                      ? 'bad'
                      : material.elastic < 66
                        ? 'average'
                        : 'good'
                  }
                >
                  Спрос: <b>{Math.round(material.elastic)}%</b>
                </Stack.Item>
                <Stack.Item width="16%">
                  {suspended ? (
                    <Box color="label">Торги приостановлены</Box>
                  ) : (
                    <>
                      <Box color={material.quantity ? undefined : 'label'}>
                        На бирже: <b>{material.quantity}</b> лист.
                      </Box>
                      <Box color={material.requested ? 'teal' : 'label'}>
                        В заказе: <b>{material.requested}</b>
                      </Box>
                    </>
                  )}
                </Stack.Item>
                <Stack.Item grow textAlign="right">
                  {BUY_AMOUNTS.map((amount) => {
                    const cost =
                      Math.ceil(material.price * amount * multiplier) +
                      orderCrateFee;
                    return (
                      <Button
                        key={amount}
                        tooltip={`${formatMoney(cost)} кр.`}
                        disabled={
                          !hasId ||
                          suspended ||
                          cost > creditBalance ||
                          amount > material.quantity
                        }
                        onClick={() =>
                          act('buy', {
                            material: material.id,
                            quantity: amount,
                          })
                        }
                      >
                        {amount === 1 ? 'Купить 1' : amount}
                      </Button>
                    );
                  })}
                </Stack.Item>
              </Stack>
            </Section>
          );
        })}
        <NoticeBox info>
          <Collapsible title="Как пользоваться биржей">
            Купленные листы прибудут следующим рейсом шаттла снабжения. Деньги
            списываются сразу, при отмене заказа возвращаются. Первая покупка в
            заказе включает стоимость ящика, его можно вернуть на шаттле. Личные
            покупки идут с наценкой {Math.round((privateMarkup - 1) * 100)}% и
            приходят в ящике, запертом на ваш счёт. В одном заказе не больше
            десяти стопок.
            <br />
            <br />
            Чтобы продать материал, вставьте в терминал стопку листов. Вы
            получите биржевой блок с ценой, зафиксированной по текущему курсу.
            Через три минуты цена блока становится плавающей и следует за
            курсом. Блок продаётся через шаттл снабжения. Каждая продажа снижает
            курс материала и спрос на него, со временем они восстанавливаются.
          </Collapsible>
        </NoticeBox>
      </Window.Content>
    </Window>
  );
};
