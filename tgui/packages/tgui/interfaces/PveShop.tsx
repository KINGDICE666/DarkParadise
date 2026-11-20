import { useState } from 'react';
import {
  Box,
  Button,
  DmIcon,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Product = {
  id: string;
  title: string;
  description: string;
  price: number;
  category: string;
  class_only: string | null;
  limit: number;
  icon: string | null;
  icon_state: string | null;
};

type PlayerClass = {
  id: string;
  title: string;
  description: string;
};

type Teammate = {
  key: string;
  name: string;
  class: string;
  alive: BooleanLike;
  credits: number;
  kills: number;
  ready: BooleanLike;
  self: BooleanLike;
};

type Data = {
  available: BooleanLike;
  finished: BooleanLike;
  credits: number;
  kills: number;
  class_id: string | null;
  class_title: string | null;
  ready: BooleanLike;
  wave: number;
  final_wave: number;
  active: BooleanLike;
  enemies: number;
  seconds: number;
  mutator: string | null;
  core: number;
  discounts: Record<string, number>;
  unavailable: Record<string, string>;
  team: Teammate[];
  products: Product[];
  categories: string[];
  classes: PlayerClass[];
};

const CATEGORY_TITLES: Record<string, string> = {
  weapons: 'Оружие',
  ammo: 'Боеприпасы',
  armor: 'Снаряжение',
  medicine: 'Медицина',
  structures: 'Сооружения',
  support: 'Поддержка',
};

const CATEGORY_ICONS: Record<string, string> = {
  weapons: 'crosshairs',
  ammo: 'box',
  armor: 'shield-alt',
  medicine: 'medkit',
  structures: 'hammer',
  support: 'satellite-dish',
};

const TEAM_TAB = 'team';

const formatTime = (seconds: number) =>
  `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

export const PveShop = () => {
  const { data } = useBackend<Data>();
  const [tab, setTab] = useState(data.categories?.[0] ?? TEAM_TAB);
  if (!data.available) {
    return (
      <Window width={720} height={680}>
        <Window.Content>
          <NoticeBox>Терминал обслуживает только защитников Маяка.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }
  return (
    <Window width={720} height={680}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <StatusPanel />
          </Stack.Item>
          {!data.class_id && !data.finished && (
            <Stack.Item>
              <ClassPicker />
            </Stack.Item>
          )}
          <Stack.Item>
            <Tabs fluid>
              {data.categories.map((category) => (
                <Tabs.Tab
                  key={category}
                  icon={CATEGORY_ICONS[category]}
                  selected={tab === category}
                  onClick={() => setTab(category)}
                >
                  {CATEGORY_TITLES[category] ?? category}
                </Tabs.Tab>
              ))}
              <Tabs.Tab
                icon="users"
                selected={tab === TEAM_TAB}
                onClick={() => setTab(TEAM_TAB)}
              >
                Команда
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === TEAM_TAB ? <TeamPanel /> : <ProductList category={tab} />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const StatusPanel = () => {
  const { act, data } = useBackend<Data>();
  let waveText = `Подготовка к волне ${data.wave + 1}/${data.final_wave} — ${formatTime(data.seconds)}`;
  if (data.finished) {
    waveText = 'Оборона завершена';
  } else if (data.active) {
    waveText = `Волна ${data.wave}/${data.final_wave} — врагов: ${data.enemies}`;
  }
  return (
    <Section>
      <Stack align="center">
        <Stack.Item grow>
          <Box bold fontSize={1.3}>
            {waveText}
          </Box>
          {!!data.mutator && (
            <Box color="bad" mt={0.5}>
              <Icon name="skull" mr={1} />
              {data.mutator}
            </Box>
          )}
          <Box mt={1}>
            <ProgressBar
              value={data.core / 100}
              ranges={{ good: [0.6, 1], average: [0.3, 0.6], bad: [0, 0.3] }}
            >
              Маяк: {data.core}%
            </ProgressBar>
          </Box>
        </Stack.Item>
        <Stack.Item textAlign="right" ml={2}>
          <Box fontSize={1.8} bold color="gold">
            {data.credits} кр.
          </Box>
          <Box color="label">
            {data.class_title ?? 'Класс не выбран'} · убийств: {data.kills}
          </Box>
          {!data.active && !data.finished && (
            <Button
              mt={0.5}
              icon={data.ready ? 'check-square' : 'square'}
              color={data.ready ? 'good' : 'default'}
              onClick={() => act('ready')}
            >
              {data.ready ? 'Готов' : 'Отметиться готовым'}
            </Button>
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const ClassPicker = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section title="Выберите класс — один раз за раунд">
      <Stack wrap>
        {data.classes.map((option) => (
          <Stack.Item key={option.id} basis="48%" mb={1}>
            <Button
              fluid
              p={1}
              style={{ whiteSpace: 'normal' }}
              onClick={() => act('choose_class', { class: option.id })}
            >
              <Box bold>{option.title}</Box>
              <Box fontSize={0.9}>{option.description}</Box>
            </Button>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const ProductList = (props: { category: string }) => {
  const { act, data } = useBackend<Data>();
  const multiplier = data.discounts[props.category] ?? 1;
  const classTitles = Object.fromEntries(
    data.classes.map((option) => [option.id, option.title]),
  );
  const products = data.products.filter(
    (product) => product.category === props.category,
  );
  return (
    <Section fill scrollable>
      {multiplier < 1 && (
        <NoticeBox success>
          Скидка вашего класса: {Math.round((1 - multiplier) * 100)}%
        </NoticeBox>
      )}
      <Table>
        {products.map((product) => {
          const price = Math.round(product.price * multiplier);
          const reason = data.unavailable[product.id];
          const affordable = data.credits >= price;
          return (
            <Table.Row key={product.id} className="candystripe">
              <Table.Cell collapsing p={0.5}>
                {product.icon && product.icon_state ? (
                  <DmIcon
                    icon={product.icon}
                    icon_state={product.icon_state}
                    width="48px"
                    height="48px"
                    fallback={<Icon name="box" size={2} />}
                  />
                ) : (
                  <Icon
                    name={CATEGORY_ICONS[product.category] ?? 'box'}
                    size={2}
                    m={1}
                  />
                )}
              </Table.Cell>
              <Table.Cell p={0.5}>
                <Box bold>
                  {product.title}
                  {!!product.class_only && (
                    <Box as="span" ml={1} color="purple" fontSize={0.85}>
                      [{classTitles[product.class_only] ?? product.class_only}]
                    </Box>
                  )}
                </Box>
                <Box color="label" fontSize={0.9}>
                  {product.description}
                </Box>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right" p={0.5}>
                {price !== product.price && (
                  <Box color="label" style={{ textDecoration: 'line-through' }}>
                    {product.price}
                  </Box>
                )}
                <Box bold color={affordable ? 'gold' : 'bad'}>
                  {price} кр.
                </Box>
              </Table.Cell>
              <Table.Cell collapsing p={0.5}>
                <Button
                  icon="shopping-cart"
                  disabled={!!reason || !affordable || !!data.finished}
                  tooltip={reason}
                  onClick={() => act('buy', { id: product.id })}
                >
                  Купить
                </Button>
              </Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
    </Section>
  );
};

const TeamPanel = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section fill scrollable title="Защитники Маяка">
      <Table>
        <Table.Row header>
          <Table.Cell>Имя</Table.Cell>
          <Table.Cell>Класс</Table.Cell>
          <Table.Cell collapsing>Статус</Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Убийств
          </Table.Cell>
          <Table.Cell collapsing textAlign="right">
            Кредиты
          </Table.Cell>
          <Table.Cell collapsing>Перевести</Table.Cell>
        </Table.Row>
        {data.team.map((member) => (
          <Table.Row key={member.key} className="candystripe">
            <Table.Cell bold={!!member.self}>{member.name}</Table.Cell>
            <Table.Cell>{member.class}</Table.Cell>
            <Table.Cell collapsing>
              {member.alive ? (
                <Box color="good">
                  {member.ready && !data.active ? 'готов' : 'в строю'}
                </Box>
              ) : (
                <Box color="bad">пал</Box>
              )}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {member.kills}
            </Table.Cell>
            <Table.Cell collapsing textAlign="right">
              {member.credits}
            </Table.Cell>
            <Table.Cell collapsing>
              {!member.self &&
                [50, 200].map((amount) => (
                  <Button
                    key={amount}
                    disabled={data.credits < amount}
                    onClick={() =>
                      act('transfer', { key: member.key, amount: amount })
                    }
                  >
                    +{amount}
                  </Button>
                ))}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Section>
  );
};
