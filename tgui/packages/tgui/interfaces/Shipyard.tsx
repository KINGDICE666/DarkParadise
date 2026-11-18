import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Part = {
  id: string;
  name: string;
  category: string;
  metal: number;
  glass: number;
  plasma: number;
  credits: number;
  rotatable: BooleanLike;
  door: BooleanLike;
  access: BooleanLike;
  size: number;
  mount: BooleanLike;
};

type Access = {
  id: number;
  name: string;
};

type Stats = {
  tiles: number;
  walls: number;
  doors: number;
  engines: number;
  weapons: number;
  sensors: number;
  helms: number;
  docks: number;
  thrust: number;
  metal: number;
  glass: number;
  plasma: number;
  credits: number;
  problems: string[];
  warnings: string[];
};

type Materials = {
  metal: number;
  glass: number;
  plasma: number;
};

type Data = {
  parts: Part[];
  categories: string[];
  paints: Record<string, string>;
  accesses: Access[];
  zone: [number, number];
  ready: BooleanLike;
  name: string;
  selected: string;
  dir: number;
  paint: string;
  access: number[];
  viewing: BooleanLike;
  building: BooleanLike;
  stats: Stats | null;
  materials: Materials | null;
  progress?: number;
  time_left?: number;
  zone_busy: BooleanLike;
};

const ERASER = 'eraser';

const DIRECTIONS = [
  { dir: 1, label: 'Север' },
  { dir: 4, label: 'Восток' },
  { dir: 2, label: 'Юг' },
  { dir: 8, label: 'Запад' },
];

const costText = (part: Part) => {
  const parts: string[] = [];
  if (part.metal) parts.push(`${part.metal} мет.`);
  if (part.glass) parts.push(`${part.glass} ст.`);
  if (part.plasma) parts.push(`${part.plasma} пл.`);
  parts.push(`${part.credits} кр.`);
  return parts.join(' · ');
};

const formatTime = (seconds: number) =>
  `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

export const Shipyard = () => {
  const { data } = useBackend<Data>();
  return (
    <Window title="Верфь" width={860} height={760}>
      <Window.Content>
        {!data.ready ? (
          <NoticeBox danger>Площадка сборки не найдена.</NoticeBox>
        ) : (
          <Stack fill vertical>
            <Stack.Item grow>
              <Stack fill>
                <Stack.Item width="48%">
                  <Palette />
                </Stack.Item>
                <Stack.Item grow>
                  <Stack fill vertical>
                    <Stack.Item>
                      <Project />
                    </Stack.Item>
                    <Stack.Item grow>
                      <Tool />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Characteristics />
            </Stack.Item>
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};

const Palette = () => {
  const { act, data } = useBackend<Data>();
  const [category, setCategory] = useState(data.categories[0]);
  const parts = data.parts.filter((part) => part.category === category);
  return (
    <Section
      fill
      scrollable
      title="Детали"
      buttons={
        <Button
          icon="eraser"
          selected={data.selected === ERASER}
          disabled={!!data.building}
          onClick={() => act('select_part', { id: ERASER })}
        >
          Ластик
        </Button>
      }
    >
      <Box mb={1} style={{ display: 'flex', flexWrap: 'wrap', gap: '2px' }}>
        {data.categories.map((name) => (
          <Button
            key={name}
            selected={name === category}
            onClick={() => setCategory(name)}
          >
            {name}
          </Button>
        ))}
      </Box>
      {parts.map((part) => (
        <Button
          key={part.id}
          fluid
          selected={data.selected === part.id}
          disabled={!!data.building}
          onClick={() => act('select_part', { id: part.id })}
        >
          <Stack>
            <Stack.Item grow>
              {part.name}
              {part.size > 1 ? ` (${part.size}×${part.size})` : ''}
            </Stack.Item>
            <Stack.Item color="label">{costText(part)}</Stack.Item>
          </Stack>
        </Button>
      ))}
    </Section>
  );
};

const Project = () => {
  const { act, data } = useBackend<Data>();
  return (
    <Section
      title="Проект"
      buttons={
        <Button
          icon="eye"
          selected={!!data.viewing}
          onClick={() => act('view')}
        >
          {data.viewing ? 'Закрыть вид сверху' : 'Вид сверху'}
        </Button>
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Input
            fluid
            maxLength={32}
            placeholder="Название шаттла"
            value={data.name || ''}
            disabled={!!data.building}
            onEnter={(value) => act('set_name', { name: value })}
            onBlur={(value) => act('set_name', { name: value })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button icon="download" onClick={() => act('save')}>
            Сохранить на ПК
          </Button>
          <Button
            icon="upload"
            disabled={!!data.building}
            onClick={() => act('load')}
          >
            Загрузить с ПК
          </Button>
          <Button.Confirm
            icon="trash"
            color="bad"
            disabled={!!data.building}
            onClick={() => act('clear')}
          >
            Очистить
          </Button.Confirm>
        </Stack.Item>
        <Stack.Item color="label">
          Площадка {data.zone[0]}×{data.zone[1]}. В виде сверху: ЛКМ — поставить,
          ПКМ — убрать, Alt+ЛКМ — повернуть.
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const Tool = () => {
  const { act, data } = useBackend<Data>();
  const part = data.parts.find((entry) => entry.id === data.selected);
  if (!part) {
    return (
      <Section fill title="Инструмент">
        <Box color="label">
          {data.selected === ERASER
            ? 'Ластик: клик убирает верхнюю деталь на клетке.'
            : 'Выберите деталь слева.'}
        </Box>
      </Section>
    );
  }
  return (
    <Section fill scrollable title={part.name}>
      <LabeledList>
        <LabeledList.Item label="Цена">{costText(part)}</LabeledList.Item>
        {!!part.rotatable && (
          <LabeledList.Item label={part.mount ? 'Стена' : 'Направление'}>
            {DIRECTIONS.map((entry) => (
              <Button
                key={entry.dir}
                selected={data.dir === entry.dir}
                onClick={() => act('set_dir', { dir: entry.dir })}
              >
                {entry.label}
              </Button>
            ))}
          </LabeledList.Item>
        )}
        {!!part.door && (
          <LabeledList.Item label="Окраска">
            <Dropdown
              width="100%"
              options={Object.keys(data.paints)}
              selected={data.paint}
              onSelected={(value: string) => act('set_paint', { paint: value })}
            />
          </LabeledList.Item>
        )}
      </LabeledList>
      {!!part.access && (
        <Section
          title="Доступ"
          buttons={
            <Button icon="times" onClick={() => act('clear_access')}>
              Без доступа
            </Button>
          }
        >
          {data.accesses.map((access) => (
            <Button.Checkbox
              key={access.id}
              checked={data.access.includes(access.id)}
              onClick={() => act('toggle_access', { access: access.id })}
            >
              {access.name}
            </Button.Checkbox>
          ))}
        </Section>
      )}
    </Section>
  );
};

const Characteristics = () => {
  const { act, data } = useBackend<Data>();
  const stats = data.stats;
  if (!stats) {
    return null;
  }
  const materials = data.materials;
  const short = (have: number | undefined, need: number) =>
    have === undefined ? false : have < need;
  const lacking =
    !materials ||
    short(materials.metal, stats.metal) ||
    short(materials.glass, stats.glass) ||
    short(materials.plasma, stats.plasma);
  const blocked =
    !!data.building || !!data.zone_busy || stats.problems.length > 0 || lacking;
  return (
    <Section title={`Характеристики${data.name ? ` — ${data.name}` : ''}`}>
      <Stack>
        <Stack.Item grow>
          <LabeledList>
            <LabeledList.Item label="Корпус">
              {stats.tiles} клеток, стен {stats.walls}, дверей {stats.doors}
            </LabeledList.Item>
            <LabeledList.Item label="Двигатели">
              {stats.engines} шт., тяга {stats.thrust}
            </LabeledList.Item>
            <LabeledList.Item label="Вооружение">
              {stats.weapons} орудий, сенсоров {stats.sensors}
            </LabeledList.Item>
            <LabeledList.Item label="Управление">
              штурвалов {stats.helms}, стыковочных шлюзов {stats.docks}
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow>
          <LabeledList>
            <LabeledList.Item
              label="Металл"
              color={short(materials?.metal, stats.metal) ? 'bad' : undefined}
            >
              {stats.metal} / {materials ? materials.metal : '—'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Стекло"
              color={short(materials?.glass, stats.glass) ? 'bad' : undefined}
            >
              {stats.glass} / {materials ? materials.glass : '—'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Плазма"
              color={short(materials?.plasma, stats.plasma) ? 'bad' : undefined}
            >
              {stats.plasma} / {materials ? materials.plasma : '—'}
            </LabeledList.Item>
            <LabeledList.Item label="Кредиты">
              {stats.credits} — спишутся со счёта при запуске
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
      {stats.problems.map((text) => (
        <NoticeBox key={text} danger>
          {text}
        </NoticeBox>
      ))}
      {stats.warnings.map((text) => (
        <NoticeBox key={text}>{text}</NoticeBox>
      ))}
      {!materials && <NoticeBox danger>Загрузчик материалов не найден.</NoticeBox>}
      {!!data.zone_busy && (
        <NoticeBox danger>
          Площадка сборки занята: уведите прошлый корабль.
        </NoticeBox>
      )}
      {data.building ? (
        <ProgressBar value={(data.progress || 0) / 100}>
          Постройка: {data.progress}% · осталось {formatTime(data.time_left || 0)}
        </ProgressBar>
      ) : (
        <Button.Confirm
          fluid
          icon="hammer"
          color="good"
          textAlign="center"
          disabled={blocked}
          onClick={() => act('build')}
        >
          Начать постройку (4–5 мин)
        </Button.Confirm>
      )}
    </Section>
  );
};
