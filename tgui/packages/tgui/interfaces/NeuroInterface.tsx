import { useState } from 'react';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

const WINDOW_WIDTH = 580;
const WINDOW_HEIGHT = 720;

const TAB_NETWORK = 'network';
const TAB_SCANNER = 'scanner';
const TAB_DECK = 'deck';

type DeviceButton = {
  id: string;
  label: string;
  icon: string;
  cost: number;
  danger: BooleanLike;
};

type DeviceTag = {
  text: string;
  tone?: 'good' | 'warn' | 'bad' | null;
};

type Device = {
  uid: string;
  name: string;
  kind: string;
  tags: DeviceTag[];
  distance: number;
  reachable: BooleanLike;
  direction: string;
  buttons: DeviceButton[];
};

type NearbyDevice = {
  uid: string;
  name: string;
  kind: string;
  distance: number;
  direction: string;
};

type Hack = {
  uid: string;
  name: string;
  progress: number;
};

type Module = {
  uid: string;
  name: string;
  summary: string;
};

type Deck = {
  name: string;
  black: BooleanLike;
  slots: number;
  modules: Module[];
};

type LogLine = {
  time: string;
  text: string;
  bad: BooleanLike;
};

type Data = {
  links_used: number;
  links_max: number;
  range: number;
  link_mode: BooleanLike;
  rebooting: BooleanLike;
  scanner: BooleanLike;
  buffer: number;
  buffer_max: number;
  buffer_regen: number;
  deck: Deck | null;
  kinds: string[];
  devices: Device[];
  hacks: Hack[];
  nearby: NearbyDevice[];
  log: LogLine[];
  sensor_mode: string;
  sensor_modes: string[];
};

type KindInfo = {
  id: string;
  title: string;
  icon: string;
  hint: string;
};

const KINDS: KindInfo[] = [
  {
    id: 'door',
    title: 'Двери',
    icon: 'door-closed',
    hint: 'Работает без кибердека. Засовы и аварийный доступ — драйвер шлюзов.',
  },
  {
    id: 'firelock',
    title: 'Пожарные шлюзы',
    icon: 'fire-extinguisher',
    hint: 'Нужен кибердек.',
  },
  {
    id: 'button',
    title: 'Кнопки дверей',
    icon: 'hand-pointer',
    hint: 'Нужен кибердек.',
  },
  {
    id: 'console',
    title: 'Консоли',
    icon: 'desktop',
    hint: 'Работает без кибердека.',
  },
  {
    id: 'apc',
    title: 'АПЦ',
    icon: 'car-battery',
    hint: 'Нужен кибердек. Свет отсека — драйвер освещения.',
  },
  {
    id: 'air_alarm',
    title: 'Датчики воздуха',
    icon: 'wind',
    hint: 'Нужен кибердек.',
  },
  {
    id: 'vending',
    title: 'Автоматы',
    icon: 'store',
    hint: 'Нужен кибердек.',
  },
  {
    id: 'intercom',
    title: 'Интеркомы',
    icon: 'microphone',
    hint: 'Нужен кибердек.',
  },
  {
    id: 'light',
    title: 'Лампы',
    icon: 'lightbulb',
    hint: 'Нужен драйвер освещения.',
  },
  {
    id: 'bot',
    title: 'Боты',
    icon: 'robot',
    hint: 'Нужен модуль перехвата ботов.',
  },
  {
    id: 'turret',
    title: 'Турели',
    icon: 'crosshairs',
    hint: 'Нужен драйвер безопасности.',
  },
  {
    id: 'flasher',
    title: 'Вспышки',
    icon: 'sun',
    hint: 'Нужен драйвер безопасности.',
  },
  {
    id: 'camera',
    title: 'Камеры',
    icon: 'video',
    hint: 'Только встроенный взломщик.',
  },
  {
    id: 'weapon',
    title: 'Оружие',
    icon: 'gun',
    hint: 'Только встроенный взломщик.',
  },
];

const groupByKind = <T extends { kind: string }>(items: T[]) =>
  KINDS.map((kind) => ({
    kind,
    items: items.filter((item) => item.kind === kind.id),
  })).filter((group) => group.items.length > 0);

const SensorPicker = () => {
  const { act, data } = useBackend<Data>();
  const { sensor_mode, sensor_modes, rebooting } = data;

  return (
    <div className="Cyberdeck__sensors">
      <span className="Cyberdeck__gaugeLabel">Датчики</span>
      {sensor_modes.map((mode) => (
        <Button
          key={mode}
          compact
          selected={mode === sensor_mode}
          disabled={!!rebooting}
          onClick={() => act('set_sensors', { mode })}
        >
          {mode}
        </Button>
      ))}
    </div>
  );
};

const Header = () => {
  const { act, data } = useBackend<Data>();
  const { deck, rebooting, link_mode, links_used, links_max, range } = data;
  const { buffer, buffer_max, buffer_regen } = data;
  const bufferPercent = buffer_max > 0 ? (buffer / buffer_max) * 100 : 0;

  return (
    <div className="Cyberdeck__header">
      <Stack align="center">
        <Stack.Item grow>
          <div className="Cyberdeck__deckName">
            <span
              className={classes([
                'Cyberdeck__led',
                !deck && 'Cyberdeck__led--off',
                !!rebooting && 'Cyberdeck__led--bad',
              ])}
            />
            {deck ? deck.name : 'Кибердек не подключён'}
          </div>
        </Stack.Item>
        {!!deck && (
          <Stack.Item>
            <Button
              icon="link"
              selected={!!link_mode}
              disabled={!!rebooting}
              onClick={() => act('toggle_link_mode')}
            >
              {link_mode ? 'Подключение: вкл' : 'Подключение: выкл'}
            </Button>
          </Stack.Item>
        )}
      </Stack>
      <SensorPicker />
      {!deck && (
        <div className="Cyberdeck__linkMode">
          Без кибердека нейроадаптер передаёт только показатели носителя. Чтобы
          взламывать и подключать устройства, вставьте деку: используйте её в
          руке.
        </div>
      )}
      {!!deck && (
        <div className="Cyberdeck__gauges Cyberdeck__mono">
          <div className="Cyberdeck__gauge">
            <div className="Cyberdeck__gaugeLabel">Каналы</div>
            <div className="Cyberdeck__gaugeValue">
              {links_used} / {links_max}
            </div>
            <div className="Cyberdeck__pips">
              {Array.from({ length: links_max }, (_, index) => (
                <div
                  key={index}
                  className={classes([
                    'Cyberdeck__pip',
                    index < links_used && 'Cyberdeck__pip--on',
                  ])}
                />
              ))}
            </div>
          </div>
          <div className="Cyberdeck__gauge">
            <div className="Cyberdeck__gaugeLabel">Дальность</div>
            <div className="Cyberdeck__gaugeValue">{range} м</div>
          </div>
          <div className="Cyberdeck__gauge Cyberdeck__gauge--wide">
            <div className="Cyberdeck__gaugeLabel">Буфер</div>
            <div className="Cyberdeck__gaugeValue">
              {deck ? `${buffer} / ${buffer_max} · +${buffer_regen}/с` : 'нет'}
            </div>
            <div className="Cyberdeck__bar">
              <div
                className="Cyberdeck__barFill"
                style={{ width: `${bufferPercent}%` }}
              />
            </div>
          </div>
        </div>
      )}
      {!!link_mode && (
        <div className="Cyberdeck__linkMode">
          Кликайте по устройствам в мире, чтобы подключить или отключить их.
          Обычные действия заблокированы, пока режим включён.
        </div>
      )}
    </div>
  );
};

const DeviceCard = (props: { device: Device }) => {
  const { act, data } = useBackend<Data>();
  const { device } = props;
  const { uid, reachable } = device;

  return (
    <div
      className={classes([
        'Cyberdeck__card',
        !reachable && 'Cyberdeck__card--lost',
      ])}
    >
      <div className="Cyberdeck__cardHead">
        <div className="Cyberdeck__cardName">{device.name}</div>
        <div className="Cyberdeck__cardMeta Cyberdeck__mono">
          {reachable
            ? `${device.distance} м ${device.direction}`
            : 'нет сигнала'}
          <Button
            ml={0.5}
            icon="link-slash"
            color="transparent"
            tooltip="Отключить"
            onClick={() => act('unlink', { uid })}
          />
        </div>
      </div>
      <div className="Cyberdeck__tags">
        {device.tags.map((tag) => (
          <span
            key={tag.text}
            className={classes([
              'Cyberdeck__tag',
              !!tag.tone && `Cyberdeck__tag--${tag.tone}`,
            ])}
          >
            {tag.text}
          </span>
        ))}
      </div>
      {device.buttons.length > 0 && (
        <div className="Cyberdeck__actions">
          {device.buttons.map((button) => (
            <Button
              key={button.id}
              icon={button.icon}
              color={button.danger ? 'red' : undefined}
              disabled={!reachable || button.cost > data.buffer}
              tooltip={
                button.cost > data.buffer
                  ? `Нужно ${button.cost} буфера`
                  : undefined
              }
              onClick={() => act('device_action', { uid, id: button.id })}
            >
              {button.label}
              {button.cost > 0 && (
                <span className="Cyberdeck__cost Cyberdeck__mono">
                  {button.cost}
                </span>
              )}
            </Button>
          ))}
        </div>
      )}
    </div>
  );
};

const NetworkTab = () => {
  const { data } = useBackend<Data>();
  const { devices, hacks } = data;

  return (
    <>
      {hacks.length > 0 && (
        <>
          <div className="Cyberdeck__groupTitle">Идёт взлом</div>
          {hacks.map((hack) => (
            <Box key={hack.uid} mb={0.4}>
              <ProgressBar value={hack.progress} color="average">
                {hack.name}
              </ProgressBar>
            </Box>
          ))}
        </>
      )}
      {devices.length === 0 && hacks.length === 0 && (
        <Box color="label" textAlign="center" mt={2}>
          Нет подключённых устройств. Включите режим подключения и кликните по
          устройству или найдите его сканером.
        </Box>
      )}
      {groupByKind(devices).map(({ kind, items }) => (
        <Box key={kind.id}>
          <div className="Cyberdeck__groupTitle">
            <Icon name={kind.icon} mr={0.5} />
            {kind.title}
          </div>
          {items.map((device) => (
            <DeviceCard key={device.uid} device={device} />
          ))}
        </Box>
      ))}
    </>
  );
};

const ScannerTab = () => {
  const { act, data } = useBackend<Data>();
  const { nearby, scanner, links_used, links_max } = data;

  if (!scanner) {
    return (
      <Box color="label" textAlign="center" mt={2}>
        Сканер не установлен. Вставьте в кибердек модуль сканера сети, чтобы
        видеть устройства рядом и подключаться к ним без прямой видимости.
      </Box>
    );
  }
  if (nearby.length === 0) {
    return (
      <Box color="label" textAlign="center" mt={2}>
        Рядом нет свободных устройств.
      </Box>
    );
  }
  return (
    <>
      {groupByKind(nearby).map(({ kind, items }) => (
        <Box key={kind.id}>
          <div className="Cyberdeck__groupTitle">
            <Icon name={kind.icon} mr={0.5} />
            {kind.title}
          </div>
          {items.map((device) => (
            <div className="Cyberdeck__card" key={device.uid}>
              <div className="Cyberdeck__cardHead">
                <div>
                  <div className="Cyberdeck__cardName">{device.name}</div>
                  <Box className="Cyberdeck__mono" color="label">
                    {device.distance} м {device.direction}
                  </Box>
                </div>
                <Button
                  icon="link"
                  disabled={links_used >= links_max}
                  onClick={() => act('link', { uid: device.uid })}
                >
                  Подключить
                </Button>
              </div>
            </div>
          ))}
        </Box>
      ))}
    </>
  );
};

const DeckTab = () => {
  const { act, data } = useBackend<Data>();
  const { deck, kinds } = data;

  return (
    <>
      {deck ? (
        <Section
          title={`Слоты модулей: ${deck.modules.length} / ${deck.slots}`}
          buttons={
            <Button icon="eject" onClick={() => act('eject_deck')}>
              Извлечь кибердек
            </Button>
          }
        >
          <div className="Cyberdeck__slots">
            {deck.modules.map((module) => (
              <div className="Cyberdeck__slot" key={module.uid}>
                <Stack>
                  <Stack.Item grow>
                    <Box bold>{module.name}</Box>
                    <Box color="label">{module.summary}</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="eject"
                      color="transparent"
                      tooltip="Извлечь модуль"
                      onClick={() => act('eject_module', { uid: module.uid })}
                    />
                  </Stack.Item>
                </Stack>
              </div>
            ))}
            {Array.from(
              { length: Math.max(deck.slots - deck.modules.length, 0) },
              (_, index) => (
                <div
                  className="Cyberdeck__slot Cyberdeck__slot--empty"
                  key={index}
                >
                  Пустой слот. Вставьте модуль в извлечённый кибердек.
                </div>
              ),
            )}
          </div>
        </Section>
      ) : (
        <Section title="Кибердек">
          <Box color="label">
            Кибердек не подключён. Возьмите его в руку и используйте, чтобы
            расширить связь, получить буфер и добавить модули.
          </Box>
        </Section>
      )}
      <Section title="Доступные устройства">
        <div className="Cyberdeck__kinds">
          {KINDS.map((kind) => {
            const available = kinds.includes(kind.id);
            return (
              <div
                key={kind.id}
                className={classes([
                  'Cyberdeck__kind',
                  available && 'Cyberdeck__kind--on',
                ])}
                title={kind.hint}
              >
                <Icon name={kind.icon} mr={0.5} />
                {kind.title}
              </div>
            );
          })}
        </div>
      </Section>
    </>
  );
};

const EventLog = () => {
  const { data } = useBackend<Data>();

  return (
    <div className="Cyberdeck__log Cyberdeck__mono">
      {data.log.length === 0 && <Box color="label">Журнал пуст.</Box>}
      {data.log.map((line, index) => (
        <div
          key={index}
          className={classes([!!line.bad && 'Cyberdeck__logLine--bad'])}
        >
          <span className="Cyberdeck__logTime">{line.time}</span>
          {line.text}
        </div>
      ))}
    </div>
  );
};

export const NeuroInterface = () => {
  const { data } = useBackend<Data>();
  const { deck, devices, nearby, scanner, rebooting } = data;
  const [tab, setTab] = useState(TAB_NETWORK);

  return (
    <Window
      width={WINDOW_WIDTH}
      height={WINDOW_HEIGHT}
      theme={deck?.black ? 'cyberdeck_black' : 'cyberdeck'}
    >
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Header />
            {!!rebooting && (
              <NoticeBox danger mt={0.5} mb={0}>
                Нейропорт перезагружается после сбоя.
              </NoticeBox>
            )}
          </Stack.Item>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="network-wired"
                selected={tab === TAB_NETWORK}
                onClick={() => setTab(TAB_NETWORK)}
              >
                Сеть ({devices.length})
              </Tabs.Tab>
              <Tabs.Tab
                icon="satellite-dish"
                selected={tab === TAB_SCANNER}
                onClick={() => setTab(TAB_SCANNER)}
              >
                Сканер{scanner ? ` (${nearby.length})` : ''}
              </Tabs.Tab>
              <Tabs.Tab
                icon="microchip"
                selected={tab === TAB_DECK}
                onClick={() => setTab(TAB_DECK)}
              >
                Кибердек
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow basis={0} style={{ overflowY: 'auto' }}>
            {tab !== TAB_DECK && !deck && (
              <NoticeBox info>
                Сеть и сканер работают только с подключённым кибердеком.
              </NoticeBox>
            )}
            {tab === TAB_NETWORK && !!deck && <NetworkTab />}
            {tab === TAB_SCANNER && !!deck && <ScannerTab />}
            {tab === TAB_DECK && <DeckTab />}
          </Stack.Item>
          <Stack.Item>
            <EventLog />
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
