import {
  Box,
  Button,
  DmIcon,
  Dropdown,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type BioprinterData = {
  biomass: number;
  capacity: number;
  selected_species: string;
  species: { id: string; name: string }[];
  products: {
    slot: string;
    name: string;
    cost: number;
    icon: string;
    icon_state: string;
  }[];
  printing: boolean | 0 | 1;
  remaining: number;
  available: boolean;
};

export const Bioprinter = () => {
  const { act, data } = useBackend<BioprinterData>();
  const { biomass, capacity, selected_species, species, products } = data;
  const printing = !!data.printing;
  return (
    <Window width={510} height={620}>
      <Window.Content scrollable>
        <Section title="Биомасса">
          <ProgressBar value={biomass} maxValue={capacity}>
            {biomass.toFixed(1)} / {capacity}
          </ProgressBar>
          <Box mt={1}>
            Загрузите сырое мясо. Стандартный кусок даёт 10 единиц биомассы;
            частично съеденное мясо даёт меньше.
          </Box>
        </Section>
        <NoticeBox>
          Прочность органов — 50% от исходной. Органические копии приживаются
          три минуты после каждой пересадки: расходуют питание пациента и
          повреждаются при голодании. Мозг и импланты не печатаются. Копии не
          принимаются по заказам карго.
        </NoticeBox>
        {!data.available && (
          <NoticeBox danger>
            Печать приостановлена: проверьте питание и панель обслуживания.
          </NoticeBox>
        )}
        {printing && (
          <NoticeBox info>
            Идёт печать. Осталось {data.remaining} сек.
          </NoticeBox>
        )}
        <Section title="Анатомический профиль">
          <Dropdown
            width="100%"
            selected={selected_species}
            displayText={
              species.find((entry) => entry.id === selected_species)?.name
            }
            disabled={printing}
            options={species.map((entry) => ({
              value: entry.id,
              displayText: entry.name,
            }))}
            onSelected={(value) => act('species', { species: value })}
          />
        </Section>
        <Section title="Органы">
          <Stack vertical>
            {products.map((product) => (
              <Stack.Item key={product.slot}>
                <Stack align="center">
                  <Stack.Item>
                    <DmIcon
                      icon={product.icon}
                      icon_state={product.icon_state}
                      width="32px"
                      height="32px"
                    />
                  </Stack.Item>
                  <Stack.Item grow>{product.name}</Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="print"
                      disabled={
                        printing || !data.available || biomass < product.cost
                      }
                      onClick={() => act('print', { slot: product.slot })}
                    >
                      {product.cost} биомассы
                    </Button>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
