import { Box, Button, LabeledList, NoticeBox, Section } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type PveShopData = {
  available: boolean;
  finished: boolean;
  credits: number;
  score: number;
  wave: number;
  completed: number;
  active: boolean;
  enemies: number;
  seconds: number;
  survivors: number;
  products: { id: string; name: string; price: number }[];
};

export const PveShop = () => {
  const { act, data } = useBackend<PveShopData>();
  return (
    <Window width={460} height={620}>
      <Window.Content scrollable>
        {!data.available ? (
          <NoticeBox>Магазин доступен участникам PvE на арене.</NoticeBox>
        ) : (
          <>
            <Section title="Оборона коридора">
              <LabeledList>
                <LabeledList.Item label="Кредиты">
                  {data.credits}
                </LabeledList.Item>
                <LabeledList.Item label="Личный счёт">
                  {data.score}
                </LabeledList.Item>
                <LabeledList.Item label="Зачищено волн">
                  {data.completed}
                </LabeledList.Item>
                <LabeledList.Item label="Выживших">
                  {data.survivors}
                </LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                {data.finished
                  ? 'Оборона завершена.'
                  : data.active
                    ? `Волна ${data.wave}: осталось врагов — ${data.enemies}.`
                    : `Следующая волна через ${data.seconds} сек.`}
              </Box>
            </Section>
            <Section title="Снаряжение">
              {data.products.map((product) => (
                <Box key={product.id} mb={0.5}>
                  <Button
                    fluid
                    icon="shopping-cart"
                    disabled={data.finished || data.credits < product.price}
                    onClick={() => act('buy', { id: product.id })}
                  >
                    {product.name} — {product.price} кр.
                  </Button>
                </Box>
              ))}
            </Section>
            <NoticeBox>
              Покупки выдаются в руки или под ноги. Комплект турели нужно
              использовать в руке. За каждую зачищенную волну выжившие получают
              кредиты и очки. После гибели всей команды раунд заканчивается.
            </NoticeBox>
          </>
        )}
      </Window.Content>
    </Window>
  );
};
