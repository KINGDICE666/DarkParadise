import { type ReactNode, useState } from 'react';
import {
  Box,
  Button,
  Chart,
  Icon,
  Knob,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
import { toFixed } from 'tgui-core/math';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { getGasColor, getGasLabel } from '../constants';
import { Window } from '../layouts';
import { HelpDummy, HoverHelp } from './Hypertorus/helpers';

const TOTAL_CONTROL_RODS = 5;
const MAX_CELL_SIZE = 46;
const MIN_CELL_SIZE = 18;
const MAP_AREA_WIDTH = 360;
const MAP_AREA_HEIGHT = 440;

enum ChamberState {
  Down = 1,
  Up = 2,
  Open = 3,
  OverloadIdle = 4,
  OverloadActive = 5,
}

enum Tab {
  Map = 'map',
  Charts = 'charts',
  Gases = 'gases',
}

const STATUS_INFO: Record<number, { label: string; color: string }> = {
  0: { label: 'Заглушен', color: 'label' },
  1: { label: 'Штатная работа', color: 'good' },
  2: { label: 'Близко к перегреву', color: 'average' },
  3: { label: 'Повреждения', color: 'average' },
  4: { label: 'Опасность', color: 'bad' },
  5: { label: 'Авария', color: 'bad' },
  6: { label: 'Расплав', color: 'bad' },
};

const ROD_CLASS_INFO: Record<
  string,
  { label: string; icon: string; color: string }
> = {
  fuel: { label: 'Топливо', icon: 'atom', color: '#e3b341' },
  moderator: { label: 'Замедлитель', icon: 'cubes', color: '#b8c2cc' },
  coolant: { label: 'Охладитель', icon: 'snowflake', color: '#5dade2' },
};

const CHAMBER_COLORS = {
  empty: '#262626',
  raised: '#4d4d4d',
  open: '#3a3a3a',
  overload: '#8e44ad',
  enriching: '#2f6fd6',
  working: '#2e9e44',
  partial: '#d68a1f',
  idle: '#b03a2e',
};

type Gas = {
  name: string;
  amount: number;
  portion: number;
  desc?: string;
};

type Chamber = {
  x: number;
  y: number;
  state: ChamberState;
  welded: BooleanLike;
  operational: BooleanLike;
  requirements_met: BooleanLike;
  enriching: BooleanLike;
  rod?: string;
  rod_class?: string;
  durability?: number;
  power?: number;
  heat?: number;
  power_mod?: number;
  heat_mod?: number;
  requirements?: string[];
  power_enrich?: number;
  heat_enrich?: number;
};

type History = {
  power: number[];
  temperature: number[];
  integrity: number[];
};

type Data = {
  connected: BooleanLike;
  controlling: BooleanLike;
  status: number;
  offline: BooleanLike;
  starting_up: BooleanLike;
  meltdown: BooleanLike;
  control_lockout: BooleanLike;
  integrity: number;
  power: number;
  temperature: number;
  pressure: number;
  coefficient: number;
  heat_threshold: number;
  minimum_temp: number;
  throttle: number;
  rod_insertion: number;
  control_rods: number;
  venting: BooleanLike;
  vent_lockout: BooleanLike;
  scram_active: BooleanLike;
  scram_hold: BooleanLike;
  scram_lock: number;
  history: History;
  gases: Gas[];
  moderator_gases: Gas[];
  chambers: Chamber[];
};

const logScale = (value: number) => Math.log2(16 + Math.max(0, value)) - 4;

const formatPower = (kilowatts: number) =>
  kilowatts >= 10000
    ? `${toFixed(kilowatts / 1000, 1)} МВт`
    : `${toFixed(kilowatts)} кВт`;

const formatTime = (seconds: number) =>
  `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

export const ReactorMonitor = (props) => {
  const { data } = useBackend<Data>();
  const [tab, setTab] = useState(Tab.Map);

  return (
    <Window width={1020} height={700} title="Пульт управления реактором">
      <Window.Content>
        {!data.connected ? (
          <NoticeBox danger>
            Реактор не найден. Привяжите пульт мультитулом.
          </NoticeBox>
        ) : (
          <Stack fill>
            <Stack.Item width="330px">
              <Stack fill vertical>
                <Stack.Item>
                  <ReactorStatus />
                </Stack.Item>
                <Stack.Item grow>
                  <ReactorControls />
                </Stack.Item>
              </Stack>
            </Stack.Item>
            <Stack.Item grow basis={0}>
              <Stack fill vertical>
                <Stack.Item>
                  <Tabs>
                    <Tabs.Tab
                      icon="th"
                      selected={tab === Tab.Map}
                      onClick={() => setTab(Tab.Map)}
                    >
                      Карта стержней
                    </Tabs.Tab>
                    <Tabs.Tab
                      icon="chart-line"
                      selected={tab === Tab.Charts}
                      onClick={() => setTab(Tab.Charts)}
                    >
                      Графики
                    </Tabs.Tab>
                    <Tabs.Tab
                      icon="wind"
                      selected={tab === Tab.Gases}
                      onClick={() => setTab(Tab.Gases)}
                    >
                      Газы
                    </Tabs.Tab>
                  </Tabs>
                </Stack.Item>
                <Stack.Item grow>
                  {tab === Tab.Map && <RodMap />}
                  {tab === Tab.Charts && <HistoryCharts />}
                  {tab === Tab.Gases && <GasPanels />}
                </Stack.Item>
              </Stack>
            </Stack.Item>
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};

const ReactorStatus = (props) => {
  const { data } = useBackend<Data>();
  const {
    status,
    meltdown,
    starting_up,
    offline,
    integrity,
    power,
    temperature,
    heat_threshold,
    minimum_temp,
    pressure,
    coefficient,
    control_rods,
  } = data;
  const statusInfo = STATUS_INFO[status] ?? STATUS_INFO[0];
  const stateLabel = offline
    ? statusInfo.label
    : starting_up
      ? 'Запуск'
      : statusInfo.label;

  return (
    <Section
      title="Состояние"
      buttons={
        <Box bold color={statusInfo.color}>
          {stateLabel}
        </Box>
      }
    >
      {!!meltdown && (
        <NoticeBox danger>
          Идёт отсчёт до расплава! Заглушите реактор.
        </NoticeBox>
      )}
      <LabeledList>
        <LabeledList.Item label="Целостность">
          <ProgressBar
            value={integrity / 100}
            ranges={{
              good: [0.9, Infinity],
              average: [0.5, 0.9],
              bad: [-Infinity, 0.5],
            }}
          >
            {`${toFixed(integrity, 1)}%`}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Выработка">
          <ProgressBar
            value={power}
            minValue={0}
            maxValue={Math.max(2000, power)}
            color="good"
          >
            {formatPower(power)}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item
          label="Температура"
          tooltip={`Порог перегрева: ${heat_threshold} K${
            minimum_temp ? `. Минимум от стержней: ${minimum_temp} K` : ''
          }`}
        >
          <ProgressBar
            value={logScale(temperature)}
            minValue={0}
            maxValue={logScale(Math.max(10000, heat_threshold * 1.5))}
            ranges={{
              teal: [-Infinity, logScale(80)],
              good: [logScale(80), logScale(heat_threshold * 0.5)],
              average: [
                logScale(heat_threshold * 0.5),
                logScale(heat_threshold * 0.9),
              ],
              bad: [logScale(heat_threshold * 0.9), Infinity],
            }}
          >
            {`${toFixed(temperature)} / ${heat_threshold} K`}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Давление">
          <ProgressBar
            value={logScale(pressure)}
            minValue={0}
            maxValue={logScale(20000)}
            ranges={{
              good: [-Infinity, logScale(3000)],
              average: [logScale(3000), logScale(6895)],
              bad: [logScale(6895), Infinity],
            }}
          >
            {`${toFixed(pressure)} кПа`}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item
          label="Реактивность"
          tooltip="Множитель выработки. Тепло растёт вдвое быстрее мощности."
        >
          <ProgressBar
            value={coefficient}
            minValue={1}
            maxValue={30}
            ranges={{
              good: [-Infinity, 5],
              average: [5, 15],
              bad: [15, Infinity],
            }}
          >
            {`×${toFixed(coefficient, 2)}`}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item
          label="Стержни управления"
          tooltip="Заклинившие стержни поднимают минимальную мощность на 20% каждый. Чинятся гаечным ключом."
        >
          <Box color={control_rods < TOTAL_CONTROL_RODS ? 'bad' : 'good'} bold>
            {`${control_rods} / ${TOTAL_CONTROL_RODS}`}
          </Box>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const ReactorControls = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    controlling,
    throttle,
    rod_insertion,
    venting,
    vent_lockout,
    scram_active,
    scram_hold,
    scram_lock,
    control_lockout,
    offline,
  } = data;
  const locked = scram_active || scram_lock > 0;

  return (
    <Section fill title="Управление">
      {!controlling && (
        <NoticeBox>
          Реактор вне прямой видимости. Доступен только просмотр.
        </NoticeBox>
      )}
      {!!control_lockout && (
        <NoticeBox danger>
          Управление заблокировано Центральным командованием.
        </NoticeBox>
      )}
      <Stack align="center">
        <Stack.Item textAlign="center" width="130px">
          <Box color="label" mb={1}>
            Заданное погружение
          </Box>
          <Knob
            size={4}
            value={throttle}
            unit="%"
            minValue={0}
            maxValue={100}
            step={1}
            stepPixelSize={2}
            color={locked ? 'bad' : undefined}
            onChange={(e, value) => {
              if (controlling && !locked && !control_lockout) {
                act('set_throttle', { throttle: value });
              }
            }}
          />
        </Stack.Item>
        <Stack.Item grow>
          <Box color="label" mb={0.5}>
            Фактическое погружение
          </Box>
          <ProgressBar
            value={rod_insertion}
            minValue={0}
            maxValue={100}
            ranges={{
              teal: [100, Infinity],
              good: [70, 100],
              average: [30, 70],
              bad: [-Infinity, 30],
            }}
          >
            {`${toFixed(rod_insertion)}%`}
          </ProgressBar>
          <Box color="label" mt={1} fontSize="0.9em">
            100% — реактор заглушен.
          </Box>
        </Stack.Item>
      </Stack>
      <Box mt={2}>
        <Button.Confirm
          fluid
          icon="radiation"
          color="bad"
          textAlign="center"
          fontSize="1.4em"
          lineHeight={2}
          disabled={!controlling || offline || scram_active || control_lockout}
          confirmContent="Подтвердить SCRAM"
          confirmIcon="exclamation-triangle"
          tooltip="Аварийно вводит все стержни, включая заклинившие. Повторный запуск блокируется на 3 минуты."
          onClick={() => act('scram')}
        >
          {scram_active ? 'SCRAM выполняется...' : 'Аварийная остановка'}
        </Button.Confirm>
        {scram_lock > 0 ? (
          <Box mt={1} textAlign="center" color="average">
            Перезапуск заблокирован: {formatTime(scram_lock)}
          </Box>
        ) : (
          !!scram_hold &&
          !scram_active && (
            <Box mt={1} textAlign="center" color="label">
              Стержни удержаны после SCRAM. Уменьшите погружение, чтобы
              запустить реактор.
            </Box>
          )
        )}
      </Box>
      <Box mt={2}>
        <Button
          fluid
          icon={venting ? 'door-open' : 'door-closed'}
          selected={venting}
          color={vent_lockout ? 'bad' : undefined}
          disabled={!controlling}
          tooltip={
            vent_lockout
              ? 'Привод клапана заклинило. Закройте его ломом у реактора.'
              : 'Сбрасывает газ активной зоны в помещение.'
          }
          onClick={() => act('toggle_vent')}
        >
          {venting ? 'Аварийный клапан открыт' : 'Аварийный клапан закрыт'}
        </Button>
      </Box>
    </Section>
  );
};

const chamberKey = (x: number, y: number) => `${x},${y}`;

const getChamberColor = (chamber: Chamber) => {
  if (
    chamber.state === ChamberState.OverloadIdle ||
    chamber.state === ChamberState.OverloadActive
  ) {
    return CHAMBER_COLORS.overload;
  }
  if (chamber.state === ChamberState.Up) {
    return CHAMBER_COLORS.raised;
  }
  if (chamber.state === ChamberState.Open) {
    return CHAMBER_COLORS.open;
  }
  if (!chamber.rod) {
    return CHAMBER_COLORS.empty;
  }
  if (chamber.enriching) {
    return CHAMBER_COLORS.enriching;
  }
  if (chamber.operational && chamber.requirements_met) {
    return CHAMBER_COLORS.working;
  }
  if (chamber.operational || chamber.requirements_met) {
    return CHAMBER_COLORS.partial;
  }
  return CHAMBER_COLORS.idle;
};

const getChamberState = (chamber: Chamber) => {
  switch (chamber.state) {
    case ChamberState.Up:
      return 'Поднята';
    case ChamberState.Open:
      return 'Открыта';
    case ChamberState.OverloadIdle:
    case ChamberState.OverloadActive:
      return 'Режим перегрузки';
  }
  if (!chamber.rod) {
    return 'Пустая';
  }
  if (chamber.enriching) {
    return 'Обогащение';
  }
  if (chamber.operational && chamber.requirements_met) {
    return 'Работает';
  }
  if (chamber.requirements_met) {
    return 'Запускается';
  }
  if (chamber.operational) {
    return 'Теряет соседей';
  }
  return 'Нет нужных соседей';
};

const RodMap = (props) => {
  const { data } = useBackend<Data>();
  const { chambers = [] } = data;
  const [selectedKey, setSelectedKey] = useState<string>();

  const chamberMap = new Map(
    chambers.map((chamber) => [chamberKey(chamber.x, chamber.y), chamber]),
  );
  const xs = [-1, 1, ...chambers.map((chamber) => chamber.x)];
  const ys = [0, ...chambers.map((chamber) => chamber.y)];
  const minX = Math.min(...xs);
  const maxX = Math.max(...xs);
  const minY = Math.min(...ys);
  const maxY = Math.max(...ys);
  const cellSize = Math.max(
    MIN_CELL_SIZE,
    Math.min(
      MAX_CELL_SIZE,
      Math.floor(MAP_AREA_WIDTH / (maxX - minX + 1)) - 2,
      Math.floor(MAP_AREA_HEIGHT / (maxY - minY + 1)) - 2,
    ),
  );

  const rows: ReactNode[] = [];
  for (let y = maxY; y >= minY; y--) {
    const cells: ReactNode[] = [];
    for (let x = minX; x <= maxX; x++) {
      const key = chamberKey(x, y);
      if (y === 0 && x >= -1 && x <= 1) {
        cells.push(<ReactorCell key={key} center={x === 0} size={cellSize} />);
        continue;
      }
      const chamber = chamberMap.get(key);
      cells.push(
        chamber ? (
          <ChamberCell
            key={key}
            chamber={chamber}
            size={cellSize}
            selected={key === selectedKey}
            onSelect={() => setSelectedKey(key)}
          />
        ) : (
          <Box
            key={key}
            width={`${cellSize}px`}
            height={`${cellSize}px`}
            m="1px"
          />
        ),
      );
    }
    rows.push(
      <Box key={y} style={{ display: 'flex' }}>
        {cells}
      </Box>,
    );
  }

  const selected = selectedKey ? chamberMap.get(selectedKey) : undefined;
  const working = chambers.filter(
    (chamber) =>
      chamber.state === ChamberState.Down &&
      chamber.operational &&
      chamber.requirements_met,
  ).length;

  return (
    <Stack fill>
      <Stack.Item grow basis={0}>
        <Section
          fill
          scrollable
          title="Камеры"
          buttons={
            <Box color="label">
              Работает {working} из {chambers.length}
            </Box>
          }
        >
          {chambers.length === 0 ? (
            <NoticeBox>К реактору не подключено ни одной камеры.</NoticeBox>
          ) : (
            <Box style={{ overflowX: 'auto' }}>
              <Box style={{ width: 'fit-content', margin: '0 auto' }}>
                {rows}
              </Box>
            </Box>
          )}
          <MapLegend />
        </Section>
      </Stack.Item>
      <Stack.Item width="290px">
        <ChamberDetails chamber={selected} />
      </Stack.Item>
    </Stack>
  );
};

const ReactorCell = (props: { center: boolean; size: number }) => (
  <Box
    width={`${props.size}px`}
    height={`${props.size}px`}
    m="1px"
    backgroundColor="#111"
    textAlign="center"
    style={{
      border: '1px solid #f1c40f55',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
    }}
  >
    {props.center && (
      <Icon name="radiation" size={props.size / 29} color="yellow" />
    )}
  </Box>
);

const ChamberCell = (props: {
  chamber: Chamber;
  size: number;
  selected: boolean;
  onSelect: () => void;
}) => {
  const { chamber, size, selected, onSelect } = props;
  const rodClass = chamber.rod_class
    ? ROD_CLASS_INFO[chamber.rod_class]
    : undefined;
  const durability = chamber.durability ?? 0;

  return (
    <Tooltip
      content={
        chamber.rod
          ? `${chamber.rod} — ${getChamberState(chamber)}`
          : getChamberState(chamber)
      }
    >
      <Box
        width={`${size}px`}
        height={`${size}px`}
        m="1px"
        backgroundColor={getChamberColor(chamber)}
        position="relative"
        style={{
          cursor: 'pointer',
          border: selected ? '2px solid #fff' : '1px solid #000',
          boxSizing: 'border-box',
        }}
        onClick={onSelect}
      >
        {rodClass && (
          <Box
            position="absolute"
            top={`${Math.round(size * 0.13)}px`}
            left={0}
            right={0}
            textAlign="center"
          >
            <Icon
              name={rodClass.icon}
              size={size / 33}
              color={rodClass.color}
            />
          </Box>
        )}
        {!!chamber.welded && (
          <Box position="absolute" top="1px" right="3px" fontSize="0.8em">
            <Icon name="fire" color="orange" />
          </Box>
        )}
        {chamber.rod && (
          <Box
            position="absolute"
            bottom="3px"
            left="4px"
            right="4px"
            height="4px"
            backgroundColor="#00000088"
          >
            <Box
              height="4px"
              width={`${Math.max(0, Math.min(100, durability))}%`}
              backgroundColor={
                durability > 66
                  ? '#5cd65c'
                  : durability > 33
                    ? '#f0c040'
                    : '#e05050'
              }
            />
          </Box>
        )}
      </Box>
    </Tooltip>
  );
};

const LEGEND = [
  { color: CHAMBER_COLORS.working, label: 'Работает' },
  { color: CHAMBER_COLORS.partial, label: 'Запуск / теряет соседей' },
  { color: CHAMBER_COLORS.idle, label: 'Нет нужных соседей' },
  { color: CHAMBER_COLORS.enriching, label: 'Обогащение' },
  { color: CHAMBER_COLORS.raised, label: 'Поднята / открыта' },
];

const MapLegend = (props) => (
  <Box mt={2} style={{ display: 'flex', flexWrap: 'wrap', gap: '6px 14px' }}>
    {LEGEND.map((entry) => (
      <Box key={entry.label} inline color="label">
        <Box
          inline
          width="10px"
          height="10px"
          mr={0.5}
          backgroundColor={entry.color}
          verticalAlign="middle"
        />
        {entry.label}
      </Box>
    ))}
    {Object.values(ROD_CLASS_INFO).map((rodClass) => (
      <Box key={rodClass.label} inline color="label">
        <Icon name={rodClass.icon} color={rodClass.color} mr={0.5} />
        {rodClass.label}
      </Box>
    ))}
  </Box>
);

const ChamberDetails = (props: { chamber?: Chamber }) => {
  const { chamber } = props;
  if (!chamber) {
    return (
      <Section fill title="Камера">
        <Box color="label">Выберите камеру на карте.</Box>
      </Section>
    );
  }
  const rodClass = chamber.rod_class
    ? ROD_CLASS_INFO[chamber.rod_class]
    : undefined;

  return (
    <Section fill scrollable title={chamber.rod ?? 'Пустая камера'}>
      <LabeledList>
        <LabeledList.Item label="Состояние">
          <Box color={getChamberColor(chamber)} bold>
            {getChamberState(chamber)}
          </Box>
        </LabeledList.Item>
        {!!chamber.welded && (
          <LabeledList.Item label="Сварка">
            <Box color="average">Заварена</Box>
          </LabeledList.Item>
        )}
        {rodClass && (
          <LabeledList.Item label="Тип">
            <Icon name={rodClass.icon} color={rodClass.color} mr={0.5} />
            {rodClass.label}
          </LabeledList.Item>
        )}
        {chamber.rod && (
          <>
            <LabeledList.Item label="Ресурс">
              <ProgressBar
                value={(chamber.durability ?? 0) / 100}
                ranges={{
                  good: [0.66, Infinity],
                  average: [0.33, 0.66],
                  bad: [-Infinity, 0.33],
                }}
              >
                {`${toFixed(chamber.durability ?? 0, 1)}%`}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="Выработка">
              {`${toFixed(chamber.power ?? 0, 1)} кВт`}
            </LabeledList.Item>
            <LabeledList.Item label="Тепло">
              {toFixed(chamber.heat ?? 0, 1)}
            </LabeledList.Item>
            <LabeledList.Item
              label="Множители"
              tooltip="Произведение модификаторов соседних стержней."
            >
              {`мощность ×${toFixed(chamber.power_mod ?? 1, 2)}, тепло ×${toFixed(chamber.heat_mod ?? 1, 2)}`}
            </LabeledList.Item>
            {chamber.power_enrich !== undefined && (
              <LabeledList.Item label="Обогащение (мощн.)">
                <ProgressBar value={chamber.power_enrich / 100} color="blue">
                  {`${chamber.power_enrich}%`}
                </ProgressBar>
              </LabeledList.Item>
            )}
            {chamber.heat_enrich !== undefined && (
              <LabeledList.Item label="Обогащение (тепло)">
                <ProgressBar value={chamber.heat_enrich / 100} color="orange">
                  {`${chamber.heat_enrich}%`}
                </ProgressBar>
              </LabeledList.Item>
            )}
          </>
        )}
      </LabeledList>
      {chamber.rod && (
        <Box mt={2}>
          <Box bold mb={0.5}>
            Требуемые соседи
          </Box>
          {chamber.requirements?.length ? (
            chamber.requirements.map((requirement, index) => (
              <Box
                key={index}
                color={chamber.requirements_met ? 'good' : 'bad'}
              >
                • {requirement}
              </Box>
            ))
          ) : (
            <Box color="label">Не требуются</Box>
          )}
        </Box>
      )}
    </Section>
  );
};

const HistoryChart = (props: {
  title: string;
  values: number[];
  format: (value: number) => string;
  color: string;
  maxValue: number;
  threshold?: number;
}) => {
  const { title, values, format, color, maxValue, threshold } = props;
  const points = values.map((value, index) => [index, value]);
  const lastIndex = Math.max(points.length - 1, 1);
  const top = Math.max(maxValue, threshold ?? 0, ...values) * 1.05;
  const current = values.length ? values[values.length - 1] : 0;

  return (
    <Section
      title={title}
      buttons={
        <Box bold color="label">
          {format(current)}
        </Box>
      }
    >
      <Box position="relative" height="120px">
        {points.length > 1 ? (
          <>
            <Chart.Line
              fillPositionedParent
              data={points}
              rangeX={[0, lastIndex]}
              rangeY={[0, top]}
              strokeColor={color}
              fillColor={`${color}40`}
            />
            {threshold !== undefined && (
              <Chart.Line
                fillPositionedParent
                data={[
                  [0, threshold],
                  [lastIndex, threshold],
                ]}
                rangeX={[0, lastIndex]}
                rangeY={[0, top]}
                strokeColor="#e74c3c"
                fillColor="transparent"
              />
            )}
          </>
        ) : (
          <Box color="label" pt={4} textAlign="center">
            Данные ещё собираются...
          </Box>
        )}
      </Box>
    </Section>
  );
};

const HistoryCharts = (props) => {
  const { data } = useBackend<Data>();
  const { history, heat_threshold } = data;

  return (
    <Section fill scrollable title="Последние 5 минут">
      <HistoryChart
        title="Выработка"
        values={history.power}
        format={formatPower}
        color="#2ecc71"
        maxValue={500}
      />
      <HistoryChart
        title="Температура активной зоны"
        values={history.temperature}
        format={(value) => `${toFixed(value)} K`}
        color="#e67e22"
        maxValue={300}
        threshold={heat_threshold}
      />
      <HistoryChart
        title="Целостность"
        values={history.integrity}
        format={(value) => `${toFixed(value, 1)}%`}
        color="#3498db"
        maxValue={100}
      />
    </Section>
  );
};

const GasList = (props: { gases: Gas[]; empty: string }) => {
  const { gases, empty } = props;
  const filtered = gases
    .filter((gas) => gas.amount >= 0.01)
    .sort((a, b) => b.amount - a.amount);
  if (!filtered.length) {
    return <Box color="label">{empty}</Box>;
  }
  const maxPortion = Math.max(1, ...filtered.map((gas) => gas.portion));

  return (
    <LabeledList>
      {filtered.map((gas) => (
        <LabeledList.Item
          key={gas.name}
          label={
            <>
              {gas.desc ? <HoverHelp content={gas.desc} /> : <HelpDummy />}
              {getGasLabel(gas.name)}:
            </>
          }
        >
          <ProgressBar
            color={getGasColor(gas.name)}
            value={gas.portion}
            minValue={0}
            maxValue={maxPortion}
          >
            {`${toFixed(gas.amount)} моль (${gas.portion}%)`}
          </ProgressBar>
        </LabeledList.Item>
      ))}
    </LabeledList>
  );
};

const GasPanels = (props) => {
  const { data } = useBackend<Data>();
  const { gases = [], moderator_gases = [] } = data;

  return (
    <Stack fill vertical>
      <Stack.Item grow basis={0}>
        <Section fill scrollable title="Теплоноситель">
          <GasList gases={gases} empty="Активная зона пуста." />
        </Section>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Section
          fill
          scrollable
          title="Замедлитель"
          buttons={
            <Box color="label" fontSize="0.9em">
              Расходуется полностью каждый цикл
            </Box>
          }
        >
          <GasList
            gases={moderator_gases}
            empty="Газ-замедлитель не подаётся."
          />
        </Section>
      </Stack.Item>
    </Stack>
  );
};
