import { useEffect } from 'react';
import {
  Box,
  Button,
  ByondUi,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend, useLocalState } from '../backend';
import { TransponderPanel, type TransponderState } from './OvermapTransponder';
import {
  OvermapCoord,
  OvermapFrame,
  OvermapList,
  OvermapRail,
  OvermapRow,
  OvermapSeg,
  OvermapStat,
  OvermapStats,
  OvermapStick,
  overmapKindLabel,
} from './overmap/OvermapChrome';
import {
  OvermapRadar,
  type RadarContact,
  type RadarShape,
  type RadarTerrain,
} from './overmap/OvermapRadar';

type OvermapObject = {
  name: string;
  kind: string;
  x: number;
  y: number;
  color: string;
  is_self: BooleanLike;
  nested: BooleanLike;
  speed?: number;
  heading?: number;
  status?: string;
  distress?: BooleanLike;
  identified?: BooleanLike;
  docked_to?: string;
};

type Waypoint = {
  name: string;
  x: number;
  y: number;
};

type DockPad = {
  id: string;
  name: string;
  selected: BooleanLike;
  current: BooleanLike;
  can_dock: BooleanLike;
  state?: string;
  reason: string;
};

type ShuttleCollar = {
  id: string;
  name: string;
  selected: BooleanLike;
  dir?: string;
};

type EngineInfo = {
  name: string;
  ref: string;
  on: BooleanLike;
  thrust: number;
  limit: number;
  status: string;
};

type HelmTab = 'flight' | 'dock' | 'engines' | 'transponder';

type ProgrammedRoute = {
  id: string;
  name: string;
  selected: BooleanLike;
};

type OvermapHelmData = {
  linked: BooleanLike;
  mapRef: string;
  vessel_name: string;
  status: string;
  docked_to: string;
  x: number;
  y: number;
  sector_name: string;
  sector_size: number;
  speed: number;
  speed_slow: BooleanLike;
  speed_fast: BooleanLike;
  heading: number;
  facing: number;
  piloting: BooleanLike;
  pilot_name?: string | null;
  ship_docked_to?: string | null;
  ship_guests?: number;
  ship_neighbors?: number;
  radar_enabled?: BooleanLike;
  radar_shapes?: Record<string, RadarShape>;
  radar?: RadarContact[];
  radar_drifters?: number[][];
  radar_terrain?: RadarTerrain | null;
  radar_world?: number[];
  jumping?: BooleanLike;
  can_jump?: BooleanLike;
  accel: number;
  stick_x: number;
  stick_y: number;
  stick_power: number;
  can_steer: BooleanLike;
  autopilot: BooleanLike;
  dest_x: number;
  dest_y: number;
  dest_range?: number | null;
  dest_bearing?: number | null;
  max_speed: number;
  engines_on: BooleanLike;
  braking: BooleanLike;
  thrust: number;
  mass: number;
  thrust_limit: number;
  engines: EngineInfo[];
  has_transponder: BooleanLike;
  transponder: TransponderState | null;
  map_revision?: number;
  eta: string;
  is_shuttle: BooleanLike;
  is_pod?: BooleanLike;
  can_undock: BooleanLike;
  can_physical_dock: BooleanLike;
  can_edge_dock?: BooleanLike;
  can_custom_dock?: BooleanLike;
  can_portal: BooleanLike;
  can_hyperrelay: BooleanLike;
  map_jammed: BooleanLike;
  selected_dock: string;
  shuttle_mode: string;
  docks: DockPad[];
  collars?: ShuttleCollar[];
  dock_name: string;
  at_station: BooleanLike;
  near_planet: BooleanLike;
  host_name?: string;
  distress?: BooleanLike;
  broadcasting?: BooleanLike;
  pad_total?: number;
  pad_free?: number;
  objects: OvermapObject[];
  waypoints: Waypoint[];
  programmed?: BooleanLike;
  programmed_locked?: BooleanLike;
  programmed_has_routes?: BooleanLike;
  programmed_busy?: BooleanLike;
  programmed_windup?: number;
  programmed_eta?: string;
  programmed_selected?: string;
  programmed_routes?: ProgrammedRoute[];
};

export const OvermapHelm = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    linked,
    mapRef,
    vessel_name,
    status,
    x,
    y,
    sector_name,
    sector_size,
    speed,
    speed_slow,
    speed_fast,
    heading,
    facing = 0,
    piloting,
    pilot_name,
    ship_docked_to,
    ship_guests = 0,
    ship_neighbors = 0,
    radar_enabled,
    radar_shapes = {},
    radar = [],
    radar_drifters = [],
    radar_terrain,
    radar_world,
    jumping,
    can_jump,
    accel,
    stick_x = 0,
    stick_y = 0,
    stick_power = 0,
    can_steer,
    autopilot,
    dest_x,
    dest_y,
    dest_range,
    dest_bearing,
    max_speed,
    engines_on,
    braking,
    thrust,
    mass,
    thrust_limit = 100,
    engines = [],
    has_transponder,
    transponder,
    map_revision = 0,
    eta,
    is_shuttle,
    is_pod,
    can_undock,
    can_physical_dock,
    selected_dock,
    shuttle_mode,
    docks = [],
    collars = [],
    dock_name,
    at_station,
    near_planet,
    host_name,
    distress,
    broadcasting,
    pad_total = 0,
    pad_free = 0,
    objects = [],
    waypoints = [],
    map_jammed,
    programmed_locked,
    programmed_has_routes,
    programmed_busy,
    programmed_windup,
    programmed_eta,
    programmed_selected,
    programmed_routes = [],
  } = data;
  const [tab, setTab] = useLocalState<HelmTab>('helmTab', 'flight');
  const [helmView, setHelmView] = useLocalState<'map' | 'radar'>(
    'helmView',
    'radar',
  );
  const can_dock_mode = !!(is_shuttle || is_pod);
  const listTab = tab === 'dock' && !can_dock_mode ? 'flight' : tab;
  const mode = listTab === 'dock' ? 'dock' : 'flight';
  const showRadar =
    mode === 'flight' && !!radar_enabled && helmView === 'radar';
  const actTransponder = (op: string, params: Record<string, unknown> = {}) =>
    act('transponder', { op, ...params });
  const enginesOn = engines.filter((engine) => engine.on).length;
  useEffect(() => {
    act('helm_tab', { tab: mode });
  }, [mode]);
  const nearby = objects.filter((object) => !object.is_self);
  const speedFill = Math.max(
    0,
    Math.min(100, max_speed ? (speed / max_speed) * 100 : 0),
  );

  return (
    <OvermapFrame
      title="Helm"
      width={900}
      height={880}
      linked={linked}
      onRelink={() => act('relink')}
      rail={
        <OvermapRail
          name={vessel_name || 'Helm'}
          sector={sector_name}
          xy={linked ? `${x}:${y}` : undefined}
          lamps={[
            {
              label: status || 'оффлайн',
              on: !!linked,
              warn: status?.includes('Пристыкован'),
            },
            {
              label: broadcasting ? 'эфир' : 'эфир скрыт',
              on: !!broadcasting,
              warn: !broadcasting,
            },
            { label: 'авария', bad: !!distress, on: !!distress },
          ]}
        />
      }
      actions={
        linked && !programmed_locked ? (
          <>
            {can_dock_mode && (
              <Button
                icon="eject"
                disabled={!can_undock}
                onClick={() => act('undock')}
              >
                Отстыковка
              </Button>
            )}
            {can_dock_mode && (
              <Button
                icon="anchor"
                disabled={!at_station || !!can_undock}
                onClick={() => act('dock')}
              >
                Стыковка
              </Button>
            )}
            <Button
              icon="bolt"
              selected={!!jumping}
              disabled={!can_jump || !!jumping}
              onClick={() => act('hyperjump')}
            >
              {jumping ? 'Гиперпрыжок...' : 'Гиперпрыжок'}
            </Button>
            <Button
              icon="link"
              selected={!!ship_docked_to || ship_guests > 0}
              disabled={!ship_docked_to && !ship_guests && !ship_neighbors}
              onClick={() => act('dock_ship')}
            >
              {ship_docked_to
                ? `Расстыковка: ${ship_docked_to}`
                : ship_guests > 0
                  ? 'Отпустить корабли'
                  : 'Стыковка с кораблём'}
            </Button>
            <Button
              icon="portal-enter"
              disabled={!!map_jammed}
              onClick={() => act('portal')}
            >
              {dock_name ? `Прыжок: ${dock_name}` : 'Прыжок'}
            </Button>
          </>
        ) : null
      }
    >
      <div className="OvermapHelmLockHost">
        <Stack
          fill
          vertical
          className={programmed_locked ? 'OvermapHelmLockHost__dim' : undefined}
        >
          <Stack.Item grow minHeight={0}>
            <Stack fill>
              <Stack.Item grow minWidth={0}>
                <Section
                  fill
                  fitted
                  className="OvermapMapSection"
                  title={
                    mode === 'dock'
                      ? selected_dock
                        ? `Стыковка — ${selected_dock}`
                        : 'Нет выбранной площадки'
                      : map_jammed
                        ? 'Помехи гиперпрыжка'
                        : sector_name
                  }
                  buttons={
                    mode === 'flight' &&
                    !map_jammed &&
                    (radar_enabled ? (
                      <OvermapSeg
                        value={helmView}
                        onChange={setHelmView}
                        items={[
                          { id: 'radar', label: 'Радар' },
                          { id: 'map', label: 'Карта' },
                        ]}
                      />
                    ) : (
                      <Box className="OvermapHelmSide__meta">
                        клик по карте — цель автопилота
                      </Box>
                    ))
                  }
                >
                  <div className="OvermapMinimap">
                    {showRadar ? (
                      <OvermapRadar
                        shapes={radar_shapes}
                        contacts={radar}
                        drifters={radar_drifters}
                        facing={facing}
                        terrain={radar_terrain}
                        world={radar_world}
                      />
                    ) : map_jammed && mode === 'flight' ? (
                      <NoticeBox danger>Сигнал потерян.</NoticeBox>
                    ) : (
                      <ByondUi
                        key={`${mapRef}-${map_revision}-${mode}`}
                        height="100%"
                        width="100%"
                        params={{
                          id: mapRef,
                          type: 'map',
                        }}
                      />
                    )}
                  </div>
                </Section>
              </Stack.Item>
              <Stack.Item width="250px" shrink={0}>
                <div className="OvermapPanel OvermapHelmSide">
                  <OvermapStats grid>
                    <OvermapStat
                      label="скорость"
                      value={`${speed} Gm/h`}
                      tone={
                        speed_fast ? 'warn' : speed_slow ? 'good' : undefined
                      }
                    />
                    <OvermapStat label="курс" value={`${heading}°`} />
                    <OvermapStat label="нос" value={`${facing}°`} />
                    <OvermapStat label="ускор." value={accel} />
                    <OvermapStat label="eta" value={eta} />
                    <OvermapStat
                      label="лимит"
                      value={
                        <NumberInput
                          width="100%"
                          unit="Gm/h"
                          value={max_speed}
                          minValue={1}
                          maxValue={45}
                          step={1}
                          disabled={!!programmed_locked}
                          onChange={(value) =>
                            act('set_max_speed', { value: value })
                          }
                        />
                      }
                    />
                  </OvermapStats>
                  <div className="OvermapGauge">
                    <div
                      className="OvermapGauge__fill"
                      style={{ width: `${speedFill}%` }}
                    />
                  </div>
                  <OvermapStick
                    x={stick_x}
                    y={stick_y}
                    power={(stick_power || 0) / 100}
                    heading={heading}
                    speedRatio={max_speed ? speed / max_speed : 0}
                    disabled={!can_steer}
                    onChange={(nx, ny, power) =>
                      act('stick', { x: nx, y: ny, power })
                    }
                  />
                  <div className="OvermapHelmSide__row">
                    <Button
                      fluid
                      icon="hand"
                      color="bad"
                      selected={!!braking}
                      disabled={!can_steer}
                      onClick={() => act('brake')}
                    >
                      Тормоз
                    </Button>
                    <Button
                      fluid
                      icon="power-off"
                      selected={!!engines_on}
                      color={engines_on ? 'good' : 'average'}
                      onClick={() => act('cut_engines')}
                    >
                      {engines_on ? 'Двиг. вкл' : 'Инерция'}
                    </Button>
                  </div>
                  <Button
                    fluid
                    icon="gamepad"
                    selected={!!piloting}
                    disabled={!can_steer || (!!pilot_name && !piloting)}
                    onClick={() => act('take_helm')}
                  >
                    {piloting
                      ? 'Отпустить штурвал'
                      : pilot_name
                        ? `Штурвал: ${pilot_name}`
                        : 'Взять штурвал'}
                  </Button>
                  {!!piloting && (
                    <Box className="OvermapHelmSide__meta">
                      W/S — тяга, A/D — поворот
                    </Box>
                  )}
                  <Box className="OvermapStat__label">автопилот</Box>
                  <div className="OvermapHelmSide__row">
                    <NumberInput
                      value={dest_x || x || 1}
                      minValue={1}
                      maxValue={sector_size || 20}
                      step={1}
                      onChange={(value) =>
                        act('set_dest', { x: value, y: dest_y || y })
                      }
                    />
                    <NumberInput
                      value={dest_y || y || 1}
                      minValue={1}
                      maxValue={sector_size || 20}
                      step={1}
                      onChange={(value) =>
                        act('set_dest', { x: dest_x || x, y: value })
                      }
                    />
                  </div>
                  <Button
                    fluid
                    icon="robot"
                    selected={!!autopilot}
                    onClick={() => act('toggle_autopilot')}
                  >
                    {autopilot ? 'Автопилот вкл' : 'Автопилот выкл'}
                  </Button>
                  <Box className="OvermapHelmSide__meta">
                    {dest_range == null
                      ? 'цель не задана'
                      : `до цели ${dest_range} кл. · курс ${dest_bearing ?? 0}°`}
                  </Box>
                  <Box className="OvermapStat__label">транспондер</Box>
                  <div className="OvermapHelmSide__row">
                    <Button
                      fluid
                      icon="tower-broadcast"
                      selected={!!transponder?.broadcasting}
                      disabled={!transponder}
                      onClick={() => actTransponder('toggle_broadcast')}
                    >
                      {transponder?.broadcasting ? 'В эфире' : 'Скрыт'}
                    </Button>
                    <Button
                      fluid
                      icon="triangle-exclamation"
                      color={distress ? 'bad' : undefined}
                      selected={!!distress}
                      disabled={!transponder}
                      onClick={() => actTransponder('toggle_distress')}
                    >
                      SOS
                    </Button>
                  </div>
                </div>
              </Stack.Item>
            </Stack>
          </Stack.Item>
          <Stack.Item shrink={0}>
            <OvermapSeg
              value={listTab}
              onChange={setTab}
              items={[
                { id: 'flight', label: `Контакты · ${nearby.length}` },
                ...(can_dock_mode
                  ? [
                      {
                        id: 'dock' as const,
                        label: pad_total
                          ? `Стыковка · ${pad_free}/${pad_total}`
                          : 'Стыковка',
                      },
                    ]
                  : []),
                {
                  id: 'engines',
                  label: `Двигатели · ${enginesOn}/${engines.length}`,
                },
                { id: 'transponder', label: 'Транспондер' },
              ]}
            />
          </Stack.Item>
          <Stack.Item height="240px" shrink={0}>
            <Section fill scrollable>
              {listTab === 'flight' && (
                <OvermapList>
                  {waypoints.map((waypoint) => (
                    <OvermapRow
                      key={waypoint.name}
                      tag="метка"
                      title={waypoint.name}
                      meta={<OvermapCoord x={waypoint.x} y={waypoint.y} />}
                    >
                      <Button
                        onClick={() =>
                          act('set_dest', { x: waypoint.x, y: waypoint.y })
                        }
                      >
                        Курс
                      </Button>
                      <Button
                        icon="times"
                        onClick={() =>
                          act('remove_waypoint', { name: waypoint.name })
                        }
                      />
                    </OvermapRow>
                  ))}
                  {objects.map((object) => (
                    <OvermapRow
                      key={`${object.name}-${object.x}-${object.y}`}
                      tag={overmapKindLabel(object.kind)}
                      title={
                        <Box color={object.color} inline>
                          {object.name}
                          {object.is_self ? ' (вы)' : ''}
                          {object.distress ? ' ⚠' : ''}
                        </Box>
                      }
                      meta={
                        <>
                          <OvermapCoord x={object.x} y={object.y} />{' '}
                          {object.speed ?? 0} Gm/h · {object.heading ?? 0}°
                          {object.nested
                            ? ` · в доке${object.docked_to ? ` ${object.docked_to}` : ''}`
                            : ''}
                          {object.status ? ` · ${object.status}` : ''}
                        </>
                      }
                      muted={!!object.nested}
                      bad={!!object.distress}
                    >
                      <Button
                        onClick={() =>
                          act('set_dest', { x: object.x, y: object.y })
                        }
                      >
                        Курс
                      </Button>
                    </OvermapRow>
                  ))}
                </OvermapList>
              )}
              {listTab === 'dock' && (
                <>
                  <OvermapStats>
                    <OvermapStat label="фаза" value={shuttle_mode || '—'} />
                    <OvermapStat label="хост" value={host_name || 'космос'} />
                    <OvermapStat
                      label="скорость"
                      value={`${speed} Gm/h`}
                      tone={
                        can_physical_dock ? 'good' : speed ? 'warn' : undefined
                      }
                    />
                    <OvermapStat
                      label="площадки"
                      value={`${pad_free}/${pad_total}`}
                    />
                  </OvermapStats>
                  {!is_shuttle && !is_pod && (
                    <NoticeBox mt={1}>
                      Слишком большой объект для стыковки
                    </NoticeBox>
                  )}
                  {!!is_pod && (
                    <>
                      <NoticeBox mt={1}>
                        Отстыковка в космосе - у края сектора или у посадочного
                        маяка.
                      </NoticeBox>
                      {!!at_station && (
                        <>
                          <Box mt={1} mb={1} color="label">
                            {selected_dock || 'вариант не выбран'}
                          </Box>
                          <Box className="OvermapStat__label" mb={0.5}>
                            Посадка на {host_name || 'объект'}
                          </Box>
                          <OvermapList>
                            {docks.map((pad) => (
                              <OvermapRow
                                key={pad.id}
                                selected={!!pad.selected}
                                tag={
                                  pad.can_dock
                                    ? 'свободно'
                                    : pad.state === 'small'
                                      ? 'не влезает'
                                      : 'занято'
                                }
                                title={pad.name}
                                meta={pad.reason}
                                muted={!pad.can_dock}
                                onClick={() =>
                                  act('select_dock', { id: pad.id })
                                }
                              />
                            ))}
                          </OvermapList>
                          {!docks.length && (
                            <NoticeBox>
                              На этом объекте нет вариантов посадки.
                            </NoticeBox>
                          )}
                        </>
                      )}
                      {!at_station && (
                        <NoticeBox>
                          {near_planet
                            ? 'Лаваленд принимает челноки только на посадочный маяк. Подлетите к клетке аванпоста.'
                            : 'Подлетите к клетке объекта, чтобы сесть на маяк или край сектора.'}
                        </NoticeBox>
                      )}
                    </>
                  )}
                  {!!is_shuttle && (
                    <>
                      {!!at_station && (
                        <Box mt={1} mb={1} color="label">
                          {selected_dock || 'вариант не выбран'}
                        </Box>
                      )}
                      {!at_station && (
                        <NoticeBox>
                          {near_planet
                            ? 'Над Лавалендом: стыковка с клетки аванпоста. Кастомная посадка отключена — используйте маяк.'
                            : 'В открытом космосе стыковаться некуда.'}
                        </NoticeBox>
                      )}
                      {!!at_station && (
                        <Stack fill>
                          <Stack.Item grow minWidth={0}>
                            <Box className="OvermapStat__label" mb={0.5}>
                              Посадка на {host_name || 'хост'}
                            </Box>
                            <OvermapList>
                              {docks.map((pad) => (
                                <OvermapRow
                                  key={pad.id}
                                  selected={!!pad.selected}
                                  tag={
                                    pad.current
                                      ? 'сейчас'
                                      : pad.state === 'small'
                                        ? 'не влезает'
                                        : pad.can_dock
                                          ? 'свободно'
                                          : 'занято'
                                  }
                                  title={pad.name}
                                  meta={pad.reason}
                                  muted={!pad.can_dock}
                                  onClick={() =>
                                    act('select_dock', { id: pad.id })
                                  }
                                >
                                  {pad.id === '__overmap_custom' && (
                                    <Button
                                      icon="crosshairs"
                                      onClick={(event) => {
                                        event.stopPropagation();
                                        act('pick_custom_dock');
                                      }}
                                    >
                                      Заменить
                                    </Button>
                                  )}
                                </OvermapRow>
                              ))}
                            </OvermapList>
                          </Stack.Item>
                          <Stack.Item grow minWidth={0}>
                            <Box className="OvermapStat__label" mb={0.5}>
                              Наши шлюзы
                            </Box>
                            <OvermapList>
                              {collars.map((collar) => (
                                <OvermapRow
                                  key={collar.id}
                                  selected={!!collar.selected}
                                  tag={collar.selected ? 'активен' : 'шлюз'}
                                  title={collar.name}
                                  meta={collar.dir || ''}
                                  onClick={() =>
                                    act('select_collar', { id: collar.id })
                                  }
                                />
                              ))}
                            </OvermapList>
                          </Stack.Item>
                        </Stack>
                      )}
                    </>
                  )}
                </>
              )}
              {listTab === 'engines' && (
                <>
                  <OvermapStats>
                    <OvermapStat label="тяга" value={thrust} />
                    <OvermapStat label="масса" value={`${mass} т`} />
                    <OvermapStat label="ускор." value={accel} />
                    <OvermapStat
                      label="общий лимит"
                      value={
                        <NumberInput
                          width="70px"
                          unit="%"
                          value={thrust_limit}
                          minValue={0}
                          maxValue={100}
                          step={5}
                          onChange={(value) =>
                            act('set_thrust_limit', { value: value })
                          }
                        />
                      }
                    />
                  </OvermapStats>
                  <Box mt={1}>
                    <OvermapList>
                      {engines.map((engine) => (
                        <OvermapRow
                          key={engine.ref}
                          tag={engine.status}
                          title={engine.name}
                          meta={`тяга ${engine.thrust}`}
                          muted={!engine.on}
                        >
                          <NumberInput
                            width="60px"
                            unit="%"
                            value={engine.limit}
                            minValue={0}
                            maxValue={100}
                            step={5}
                            onChange={(value) =>
                              act('set_engine_limit', {
                                ref: engine.ref,
                                value: value,
                              })
                            }
                          />
                          <Button
                            icon="power-off"
                            selected={!!engine.on}
                            onClick={() =>
                              act('toggle_engine', { ref: engine.ref })
                            }
                          >
                            {engine.on ? 'Вкл' : 'Выкл'}
                          </Button>
                        </OvermapRow>
                      ))}
                    </OvermapList>
                    {!engines.length && (
                      <NoticeBox>Двигатели не найдены.</NoticeBox>
                    )}
                  </Box>
                </>
              )}
              {listTab === 'transponder' &&
                (transponder ? (
                  <TransponderPanel data={transponder} act={actTransponder} />
                ) : (
                  <NoticeBox danger={!!has_transponder}>
                    {has_transponder
                      ? 'Транспондер не отвечает: нет питания или он повреждён.'
                      : 'На борту нет транспондера.'}
                  </NoticeBox>
                ))}
            </Section>
          </Stack.Item>
        </Stack>
        {!!programmed_locked && (
          <div className="OvermapHelmLockOverlay">
            <div className="OvermapHelmLockOverlay__card">
              <div className="OvermapHelmLockOverlay__title">
                Прямое управление заблокировано поставщиком
              </div>
              <div className="OvermapHelmLockOverlay__sub">
                Используйте заранее заготовленный маршрут
              </div>
              {!!programmed_has_routes && (
                <>
                  <Box mt={1.5} mb={0.5} className="OvermapStat__label">
                    назначение
                  </Box>
                  <Stack vertical>
                    {programmed_routes.map((route) => (
                      <Stack.Item key={route.id}>
                        <Button
                          fluid
                          selected={
                            !!route.selected || programmed_selected === route.id
                          }
                          disabled={!!programmed_busy}
                          onClick={() =>
                            act('select_programmed', { id: route.id })
                          }
                        >
                          {route.name}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                  <Box mt={1.5}>
                    <Button
                      icon="play"
                      color="good"
                      disabled={!programmed_routes.length || !!programmed_busy}
                      onClick={() =>
                        act('execute_programmed', {
                          id: programmed_selected,
                        })
                      }
                    >
                      Исполнить
                    </Button>
                  </Box>
                  {!!programmed_busy && (
                    <Box mt={1} className="OvermapRail__meta">
                      {programmed_windup
                        ? `Отправление через ${programmed_windup} с`
                        : `В пути ${programmed_eta || ''}`}
                    </Box>
                  )}
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </OvermapFrame>
  );
};
