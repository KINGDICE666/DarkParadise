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

type DepartmentOrderData = {
  department_name: string | null;
  can_order: boolean;
  pending_order: string | null;
  can_cancel: boolean;
  cooldown: string | null;
  packs: DepartmentPack[];
};

export const pda_department_order = (props: unknown) => {
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
      <Box color="average">
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
          снабжение получит его стоимость.
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
