import { declension_ru } from 'common/l10n';
import { sortBy } from 'es-toolkit';
import { Box, Button, LabeledList, Section, Table } from 'tgui-core/components';
import { useBackend } from '../../backend';

type DepartmentPack = {
  name: string;
  cost: number;
  group: string;
  ref: string;
};

type Statement = {
  department: string;
  balance: number;
  transactions: StatementTransaction[];
};

type StatementTransaction = {
  date: string;
  time: string;
  target_name: string;
  purpose: string;
  amount: string;
};

type DepartmentOrderData = {
  statement?: Statement;
  department_name: string | null;
  can_order: boolean;
  pending_order: string | null;
  can_cancel: boolean;
  cooldown: string | null;
  packs: DepartmentPack[];
};

const DepartmentStatement = (props: { statement: Statement }) => {
  const { department, balance, transactions } = props.statement;

  return (
    <Section title={`Выписка: бюджет отдела «${department}»`}>
      <LabeledList>
        <LabeledList.Item label="Баланс">
          {balance} кредит{declension_ru(balance, '', 'а', 'ов')}
        </LabeledList.Item>
      </LabeledList>
      <Table mt={1}>
        <Table.Row header>
          <Table.Cell>Время</Table.Cell>
          <Table.Cell>Назначение</Table.Cell>
          <Table.Cell textAlign="right">Сумма</Table.Cell>
        </Table.Row>
        {transactions.map((transaction, index) => (
          <Table.Row key={index}>
            <Table.Cell collapsing>{transaction.time}</Table.Cell>
            <Table.Cell>
              {transaction.purpose}
              <Box color="label">{transaction.target_name}</Box>
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {transaction.amount}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};

export const pda_department_order = (props: unknown) => {
  const { data } = useBackend<DepartmentOrderData>();
  const { statement } = data;

  return (
    <>
      <DepartmentOrders />
      {statement && <DepartmentStatement statement={statement} />}
    </>
  );
};

const DepartmentOrders = () => {
  const { act, data } = useBackend<DepartmentOrderData>();
  const {
    department_name,
    can_order,
    pending_order,
    can_cancel,
    cooldown,
    packs = [],
  } = data;

  if (!department_name || !can_order) {
    return (
      <Box color="average" mb={1}>
        {department_name
          ? `Отдел «${department_name}» не может делать бесплатные заказы.`
          : 'Вставьте ID-карту со счётом, привязанным к отделу.'}
      </Box>
    );
  }

  const sortedPacks = sortBy(packs, [(pack) => pack.group, (pack) => pack.name]);

  return (
    <>
      <Section title={`Отдел «${department_name}»`}>
        <LabeledList>
          <LabeledList.Item label="Текущий заказ">
            {pending_order || 'нет'}
            {can_cancel && (
              <Button ml={1} color="red" onClick={() => act('cancel')}>
                Отменить
              </Button>
            )}
          </LabeledList.Item>
          <LabeledList.Item label="Следующий заказ">
            {cooldown ? `через ${cooldown}` : 'доступен'}
          </LabeledList.Item>
        </LabeledList>
        <Box mt={1} italic>
          Заказ бесплатный. Ящик откроется только в отделе, после доставки
          снабжение получит вознаграждение.
        </Box>
      </Section>
      <Section title="Каталог">
        <Table>
          {sortedPacks.map((pack) => (
            <Table.Row key={pack.ref}>
              <Table.Cell color="label">{pack.group}</Table.Cell>
              <Table.Cell>{pack.name}</Table.Cell>
              <Table.Cell collapsing textAlign="right">
                {pack.cost} кредит{declension_ru(pack.cost, '', 'а', 'ов')}
              </Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="truck-loading"
                  disabled={!!cooldown}
                  onClick={() => act('order', { ref: pack.ref })}
                >
                  Заказать
                </Button>
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
    </>
  );
};
