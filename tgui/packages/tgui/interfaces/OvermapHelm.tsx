import { useEffect } from 'react';
import {
  Box,
  Button,
  ByondUi,
  NoticeBox,
  NumberInput,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend, useLocalState } from '../backend';
import { TransponderPanel, type TransponderState } from './OvermapTransponder';
import {
  OvermapFrame,
  OvermapList,
  OvermapRail,
  OvermapRow,
  overmapKindLabel,
} from './overmap/OvermapChrome';
import {
  OvermapRadar,
  type RadarContact,
  type RadarShape,
  type RadarTerrain,
} from './overmap/OvermapRadar';
import {
  OvermapSectorMap,
  overmapObjectLabel,
  type SectorObject,
} from './overmap/OvermapSectorMap';

type OvermapObject = SectorObject & {
  nested: BooleanLike;
  speed?: number;
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

type ProgrammedRoute = {
  id: string;
  name: string;
  selected: BooleanLike;
};

type Phase = 'route' | 'jump' | 'relay' | 'docked' | 'transit' | 'flight';

type HelmScreen = 'map' | 'radar';

type OvermapHelmData = {
  linked: BooleanLike;
  mapRef: string;
  vessel_name: string;
  status: string;
  phase: Phase;
  x: number;
  y: number;
  sector_name: string;
  sector_size: number;
  self_pos?: number[];
  view_range?: number;
  speed: number;
  heading: number;
  facing: number;
  piloting: BooleanLike;
  pilot_name?: string | null;
  ship_docked_to?: string | null;
  ship_guests?: number;
  ship_dock_ready?: string | null;
  radar_enabled?: BooleanLike;
  radar_shapes?: Record<string, RadarShape>;
  radar?: RadarContact[];
  radar_drifters?: number[][];
  radar_terrain?: RadarTerrain | null;
  radar_world?: number[];
  can_jump?: BooleanLike;
  local_space?: BooleanLike;
  jump_left?: number;
  jump_spooling?: BooleanLike;
  jump_progress?: number;
  accel: number;
  can_steer: BooleanLike;
  autopilot: BooleanLike;
  dest?: number[];
  dest_name?: string;
  dest_range?: number;
  dest_relay?: string;
  dest_jump_time?: number;
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
  is_shuttle: BooleanLike;
  is_pod?: BooleanLike;
  can_undock: BooleanLike;
  can_physical_dock: BooleanLike;
  can_edge_dock?: BooleanLike;
  map_jammed: BooleanLike;
  selected_dock: string;
  docks: DockPad[];
  collars?: ShuttleCollar[];
  at_station: BooleanLike;
  near_planet: BooleanLike;
  host_name?: string;
  distress?: BooleanLike;
  broadcasting?: BooleanLike;
  pad_total?: number;
  pad_free?: number;
  objects: OvermapObject[];
  waypoints: Waypoint[];
  programmed_locked?: BooleanLike;
  programmed_has_routes?: BooleanLike;
  programmed_busy?: BooleanLike;
  programmed_windup?: number;
  programmed_eta?: string;
  programmed_selected?: string;
  programmed_routes?: ProgrammedRoute[];
};

const phaseTitle = (data: OvermapHelmData) => {
  switch (data.phase) {
    case 'route':
      return 'Полёт по маршруту';
    case 'jump':
      return data.jump_spooling ? 'Разгон гипердвигателя' : 'Гиперпрыжок';
    case 'relay':
      return 'Прыжок через ретранслятор';
    case 'docked':
      return data.status;
    case 'transit':
      return 'Переход через гиперпространство';
    default:
      if (!data.radar_enabled) {
        return 'В полёте';
      }
      return data.local_space ? 'Свободный полёт у станции' : 'Открытый космос';
  }
};

const phaseHint = (data: OvermapHelmData) => {
  switch (data.phase) {
    case 'docked':
      return 'Выберите цель на карте и отстыкуйтесь.';
    case 'jump':
      return 'Корабль сам выйдет у цели.';
    case 'flight':
      if (data.piloting) {
        return '';
      }
      return data.dest_name
        ? 'Цель выбрана — можно прыгать.'
        : 'Возьмите штурвал или выберите цель на карте.';
    default:
      return '';
  }
};

export const OvermapHelm = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    linked,
    vessel_name,
    sector_name,
    x,
    y,
    radar_enabled,
    distress,
    broadcasting,
    programmed_locked,
  } = data;
  const [screenChoice, setScreen] = useLocalState<HelmScreen | ''>(
    'helmScreen',
    '',
  );
  const [landing, setLanding] = useLocalState('helmLanding', false);
  const [systems, setSystems] = useLocalState('helmSystems', false);
  const screen: HelmScreen = !radar_enabled
    ? 'map'
    : screenChoice || (data.phase === 'flight' ? 'radar' : 'map');
  const landingMode = landing && !!data.at_station;
  useEffect(() => {
    act('helm_tab', { tab: landingMode ? 'dock' : 'flight' });
  }, [landingMode]);

  return (
    <OvermapFrame
      title="Штурвал"
      width={980}
      height={720}
      linked={linked}
      onRelink={() => act('relink')}
      rail={
        <OvermapRail
          name={vessel_name || 'Штурвал'}
          sector={sector_name}
          xy={linked ? `клетка ${x}:${y}` : undefined}
          lamps={[
            {
              label: broadcasting ? 'виден на сенсорах' : 'скрыт',
              on: !!broadcasting,
              warn: !broadcasting,
            },
            ...(distress ? [{ label: 'SOS', bad: true, on: true }] : []),
          ]}
          extra={
            <Button
              icon="gear"
              className="OvermapHelm__systemsButton"
              onClick={() => setSystems(true)}
            >
              Двигатели и транспондер
            </Button>
          }
        />
      }
    >
      <div className="OvermapHelmLockHost">
        <div
          className={
            programmed_locked
              ? 'OvermapHelm OvermapHelmLockHost__dim'
              : 'OvermapHelm'
          }
        >
          <div className="OvermapHelm__view">
            {landingMode ? (
              <LandingView />
            ) : (
              <FlightView screen={screen} onScreen={setScreen} />
            )}
          </div>
          <div className="OvermapHelm__side">
            {landingMode ? (
              <LandingPanel onBack={() => setLanding(false)} />
            ) : (
              <FlightSide onLanding={() => setLanding(true)} />
            )}
          </div>
        </div>
        {!!systems && <SystemsOverlay onClose={() => setSystems(false)} />}
        {!!programmed_locked && <RouteLock />}
      </div>
    </OvermapFrame>
  );
};

const FlightView = (props: {
  screen: HelmScreen;
  onScreen: (screen: HelmScreen) => void;
}) => {
  const { act, data } = useBackend<OvermapHelmData>();
  const { screen, onScreen } = props;
  const { radar_enabled, map_jammed } = data;
  return (
    <>
      <div className="OvermapHelm__viewBar">
        {radar_enabled ? (
          <div className="OvermapViewSwitch">
            <Button
              icon="map"
              selected={screen === 'map'}
              onClick={() => onScreen('map')}
            >
              Карта сектора
            </Button>
            <Button
              icon="satellite-dish"
              selected={screen === 'radar'}
              onClick={() => onScreen('radar')}
            >
              Радар: что рядом
            </Button>
          </div>
        ) : (
          <Box className="OvermapHelm__viewTitle">Карта сектора</Box>
        )}
        <Box className="OvermapHelm__viewHint">
          {screen === 'map'
            ? 'Клик по объекту или клетке — сделать целью'
            : 'Нос корабля всегда смотрит вверх'}
        </Box>
      </div>
      <div className="OvermapHelm__screen">
        {map_jammed ? (
          <NoticeBox danger>Сигнал потерян: идёт прыжок.</NoticeBox>
        ) : screen === 'radar' ? (
          <OvermapRadar
            shapes={data.radar_shapes || {}}
            contacts={data.radar || []}
            drifters={data.radar_drifters || []}
            facing={data.facing || 0}
            terrain={data.radar_terrain}
            world={data.radar_world}
          />
        ) : (
          <OvermapSectorMap
            size={data.sector_size || 20}
            objects={data.objects || []}
            self={data.self_pos}
            facing={radar_enabled ? data.facing : data.heading}
            viewRange={data.view_range}
            dest={data.dest}
            destName={data.dest_name}
            onPick={(pickX, pickY, name) =>
              act('set_dest', { x: pickX, y: pickY, name })
            }
          />
        )}
      </div>
      {screen === 'map' && !map_jammed && (
        <div className="OvermapLegend">
          <span>
            <i className="OvermapLegend__self" /> вы
          </span>
          <span>
            <i className="OvermapLegend__station" /> станция
          </span>
          <span>
            <i className="OvermapLegend__ship" /> корабль
          </span>
          <span>
            <i className="OvermapLegend__relay" /> ретранслятор
          </span>
          <span>
            <i className="OvermapLegend__hazard" /> опасная зона
          </span>
          <span>
            <i className="OvermapLegend__sensors" /> дальность сенсоров
          </span>
        </div>
      )}
    </>
  );
};

const FlightSide = (props: { onLanding: () => void }) => {
  const { data } = useBackend<OvermapHelmData>();
  const { phase, speed, facing, heading, radar_enabled } = data;
  const hint = phaseHint(data);
  return (
    <>
      <div className="OvermapHelm__status">
        <div className="OvermapHelm__statusTitle">{phaseTitle(data)}</div>
        {!!hint && <div className="OvermapHelm__statusHint">{hint}</div>}
        {phase !== 'docked' && (
          <div className="OvermapHelm__gauges">
            <div>
              <span>скорость</span>
              {speed} м/с
            </div>
            <div>
              <span>{radar_enabled ? 'нос' : 'курс'}</span>
              {radar_enabled ? facing : heading}°
            </div>
          </div>
        )}
      </div>
      <div className="OvermapHelm__actions">
        {phase === 'docked' && <DockedActions />}
        {phase === 'jump' && <JumpProgress />}
        {phase === 'flight' && (
          <>
            <PilotControls />
            <NearbyActions onLanding={props.onLanding} />
          </>
        )}
      </div>
      <TargetCard />
      <Destinations />
    </>
  );
};

const DockedActions = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  return (
    <Button
      fluid
      icon="arrow-up-from-bracket"
      color="good"
      className="OvermapHelm__primary"
      disabled={!data.can_undock}
      onClick={() => act('undock')}
    >
      Отстыковаться
    </Button>
  );
};

const JumpProgress = () => {
  const { data } = useBackend<OvermapHelmData>();
  const { jump_left = 0, jump_progress = 0, dest_name } = data;
  return (
    <>
      <Box>
        {dest_name || 'К цели'} · осталось {Math.max(jump_left, 0)} с
      </Box>
      <div className="OvermapGauge">
        <div
          className="OvermapGauge__fill"
          style={{ width: `${Math.min(Math.max(jump_progress, 0), 100)}%` }}
        />
      </div>
    </>
  );
};

const PilotControls = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const { piloting, pilot_name, can_steer, braking, autopilot } = data;
  return (
    <>
      <Button
        fluid
        icon="gamepad"
        color={piloting ? 'good' : undefined}
        selected={!!piloting}
        className="OvermapHelm__primary"
        disabled={!can_steer || (!!pilot_name && !piloting)}
        onClick={() => act('take_helm')}
      >
        {piloting
          ? 'Отпустить штурвал'
          : pilot_name
            ? `За штурвалом: ${pilot_name}`
            : 'Взять штурвал'}
      </Button>
      {!!piloting && (
        <div className="OvermapKeys">
          <span>W S</span>
          <span>тяга вперёд и назад</span>
          <span>A D</span>
          <span>сдвиг влево и вправо</span>
          <span>Q E</span>
          <span>поворот</span>
          <span>Пробел</span>
          <span>тормоз</span>
        </div>
      )}
      {!piloting && !!autopilot && (
        <Box className="OvermapHelm__statusHint">Сейчас ведёт автопилот.</Box>
      )}
      <Button
        fluid
        icon="hand"
        color={braking ? 'bad' : undefined}
        selected={!!braking}
        disabled={!can_steer}
        onClick={() => act('brake')}
      >
        {braking ? 'Тормозим… (нажмите, чтобы отменить)' : 'Остановить корабль'}
      </Button>
    </>
  );
};

const NearbyActions = (props: { onLanding: () => void }) => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    ship_docked_to,
    ship_guests = 0,
    ship_dock_ready,
    at_station,
    host_name,
    is_shuttle,
    is_pod,
  } = data;
  const canLand = !!at_station && !!(is_shuttle || is_pod);
  return (
    <>
      {!!ship_docked_to && (
        <Button fluid icon="link-slash" onClick={() => act('dock_ship')}>
          Отцепиться от {ship_docked_to}
        </Button>
      )}
      {!ship_docked_to && ship_guests > 0 && (
        <Button fluid icon="link-slash" onClick={() => act('dock_ship')}>
          Отцепить пристыкованные корабли
        </Button>
      )}
      {!ship_docked_to && !ship_guests && !!ship_dock_ready && (
        <Button fluid icon="link" color="good" onClick={() => act('dock_ship')}>
          Пристыковаться к {ship_dock_ready}
        </Button>
      )}
      {canLand && (
        <Button fluid icon="anchor" onClick={props.onLanding}>
          Сесть на {host_name || 'объект'}…
        </Button>
      )}
    </>
  );
};

const TargetCard = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    phase,
    dest_name,
    dest_range,
    dest_relay,
    dest_jump_time,
    can_jump,
    local_space,
    autopilot,
    max_speed,
  } = data;
  if (!dest_name) {
    return null;
  }
  const flying = phase === 'flight';
  return (
    <div className="OvermapHelm__target">
      <div className="OvermapHelm__targetHead">
        <div>
          <span className="OvermapHelm__caption">цель</span>
          <div className="OvermapHelm__targetName">{dest_name}</div>
          <div className="OvermapHelm__statusHint">
            {dest_relay
              ? `ретранслятор, ведёт в «${dest_relay}»`
              : `${dest_range ?? 0} кл. отсюда`}
          </div>
        </div>
        <Button
          icon="times"
          tooltip="Сбросить цель"
          onClick={() => act('clear_dest')}
        />
      </div>
      {flying && !!can_jump && (
        <Button
          fluid
          icon="bolt"
          color="good"
          className="OvermapHelm__primary"
          onClick={() => act('hyperjump')}
        >
          Гиперпрыжок{dest_jump_time ? ` (≈${dest_jump_time} с)` : ''}
        </Button>
      )}
      {flying && !local_space && (
        <Stack align="center">
          <Stack.Item grow>
            <Button
              fluid
              icon="route"
              selected={!!autopilot}
              onClick={() => act('toggle_autopilot')}
            >
              {autopilot ? 'Автопилот летит…' : 'Лететь автопилотом'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <NumberInput
              width="72px"
              unit="м/с"
              value={max_speed}
              minValue={1}
              maxValue={45}
              step={1}
              onChange={(value) => act('set_max_speed', { value: value })}
            />
          </Stack.Item>
        </Stack>
      )}
    </div>
  );
};

const Destinations = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const { objects = [], waypoints = [], self_pos, dest } = data;
  const places = objects.filter(
    (object) =>
      !object.is_self && object.kind !== 'hazard' && object.kind !== 'planet',
  );
  const distance = (object: { x: number; y: number }) =>
    self_pos
      ? Math.round(
          Math.max(
            Math.abs(object.x - self_pos[0]),
            Math.abs(object.y - self_pos[1]),
          ),
        )
      : 0;
  places.sort((a, b) => distance(a) - distance(b));
  const isDest = (object: { x: number; y: number }) =>
    !!dest && dest[0] === object.x && dest[1] === object.y;
  return (
    <div className="OvermapHelm__places">
      <span className="OvermapHelm__caption">куда лететь</span>
      <div className="OvermapHelm__placesList">
        <OvermapList>
          {places.map((object) => {
            const label = overmapObjectLabel(object);
            return (
              <OvermapRow
                key={`${object.kind}-${object.name}-${object.x}-${object.y}`}
                tag={overmapKindLabel(object.kind)}
                title={
                  <Box color={object.color} inline>
                    {label}
                  </Box>
                }
                meta={`${distance(object)} кл.${object.distress ? ' · SOS' : ''}`}
                selected={isDest(object)}
                bad={!!object.distress}
                onClick={() =>
                  act('set_dest', { x: object.x, y: object.y, name: label })
                }
              />
            );
          })}
          {waypoints
            .filter((waypoint) => !isDest(waypoint))
            .map((waypoint) => (
              <OvermapRow
                key={waypoint.name}
                tag="метка"
                title={waypoint.name}
                meta={`${distance(waypoint)} кл.`}
                onClick={() =>
                  act('set_dest', {
                    x: waypoint.x,
                    y: waypoint.y,
                    name: waypoint.name,
                  })
                }
              />
            ))}
        </OvermapList>
        {!places.length && !waypoints.length && (
          <Box className="OvermapHelm__statusHint">
            Сенсоры не видят ничего рядом.
          </Box>
        )}
      </div>
    </div>
  );
};

const LandingView = () => {
  const { data } = useBackend<OvermapHelmData>();
  const { mapRef, map_revision = 0, selected_dock } = data;
  return (
    <>
      <div className="OvermapHelm__viewBar">
        <Box className="OvermapHelm__viewTitle">
          {selected_dock ? `Место посадки: ${selected_dock}` : 'Место посадки'}
        </Box>
        <Box className="OvermapHelm__viewHint">
          зелёное — корабль встанет, красное — мешает
        </Box>
      </div>
      <div className="OvermapHelm__screen OvermapMinimap">
        <ByondUi
          key={`${mapRef}-${map_revision}-dock`}
          height="100%"
          width="100%"
          params={{ id: mapRef, type: 'map' }}
        />
      </div>
    </>
  );
};

const LandingPanel = (props: { onBack: () => void }) => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    is_shuttle,
    is_pod,
    host_name,
    docks = [],
    collars = [],
    can_physical_dock,
    can_edge_dock,
    can_undock,
    speed,
  } = data;
  return (
    <>
      <div className="OvermapHelm__status">
        <div className="OvermapHelm__statusTitle">
          Посадка на {host_name || 'объект'}
        </div>
        <div className="OvermapHelm__statusHint">
          {can_undock
            ? 'Корабль уже стоит в доке.'
            : !can_physical_dock && speed > 0
              ? 'Сначала остановите корабль.'
              : 'Выберите площадку и нажмите «Сесть».'}
        </div>
      </div>
      <div className="OvermapHelm__actions">
        <Button
          fluid
          icon="anchor"
          color="good"
          className="OvermapHelm__primary"
          disabled={!can_physical_dock}
          onClick={() => act('dock')}
        >
          Сесть
        </Button>
        {!!is_pod && !!can_edge_dock && (
          <Button fluid icon="border-all" onClick={() => act('dock_edge')}>
            Сесть у края сектора
          </Button>
        )}
        <Button fluid icon="arrow-left" onClick={props.onBack}>
          Назад к полёту
        </Button>
      </div>
      <div className="OvermapHelm__places">
        <span className="OvermapHelm__caption">площадка</span>
        <div className="OvermapHelm__placesList">
          <OvermapList>
            {docks.map((pad) => (
              <OvermapRow
                key={pad.id}
                selected={!!pad.selected}
                tag={
                  pad.current
                    ? 'вы тут'
                    : pad.state === 'small'
                      ? 'не влезает'
                      : pad.can_dock
                        ? 'свободно'
                        : 'занято'
                }
                title={pad.name}
                meta={pad.reason}
                muted={!pad.can_dock}
                onClick={() => act('select_dock', { id: pad.id })}
              >
                {pad.id === '__overmap_custom' && (
                  <Button
                    icon="crosshairs"
                    onClick={(event) => {
                      event.stopPropagation();
                      act('pick_custom_dock');
                    }}
                  >
                    Выбрать
                  </Button>
                )}
              </OvermapRow>
            ))}
          </OvermapList>
          {!docks.length && (
            <Box className="OvermapHelm__statusHint">Здесь негде сесть.</Box>
          )}
          {!!is_shuttle && collars.length > 1 && (
            <>
              <span className="OvermapHelm__caption">каким шлюзом</span>
              <OvermapList>
                {collars.map((collar) => (
                  <OvermapRow
                    key={collar.id}
                    selected={!!collar.selected}
                    title={collar.name}
                    meta={collar.dir || ''}
                    onClick={() => act('select_collar', { id: collar.id })}
                  />
                ))}
              </OvermapList>
            </>
          )}
        </div>
      </div>
    </>
  );
};

const SystemsOverlay = (props: { onClose: () => void }) => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    engines = [],
    engines_on,
    thrust,
    mass,
    accel,
    thrust_limit = 100,
    transponder,
    has_transponder,
    distress,
  } = data;
  const actTransponder = (op: string, params: Record<string, unknown> = {}) =>
    act('transponder', { op, ...params });
  return (
    <div className="OvermapHelm__overlay">
      <div className="OvermapHelm__overlayCard">
        <div className="OvermapHelm__overlayHead">
          <div className="OvermapHelm__statusTitle">
            Двигатели и транспондер
          </div>
          <Button icon="check" color="good" onClick={props.onClose}>
            Готово
          </Button>
        </div>
        <div className="OvermapHelm__overlayBody">
          <span className="OvermapHelm__caption">двигатели</span>
          <Stack align="center" mb={1}>
            <Stack.Item grow className="OvermapHelm__statusHint">
              тяга {thrust} · масса {mass} т · ускорение {accel} м/с²
            </Stack.Item>
            <Stack.Item className="OvermapHelm__statusHint">
              общий лимит
            </Stack.Item>
            <Stack.Item>
              <NumberInput
                width="70px"
                unit="%"
                value={thrust_limit}
                minValue={0}
                maxValue={100}
                step={5}
                onChange={(value) => act('set_thrust_limit', { value: value })}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="power-off"
                color={engines_on ? 'good' : 'average'}
                selected={!!engines_on}
                onClick={() => act('cut_engines')}
              >
                {engines_on ? 'Двигатели включены' : 'Двигатели выключены'}
              </Button>
            </Stack.Item>
          </Stack>
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
                    act('set_engine_limit', { ref: engine.ref, value: value })
                  }
                />
                <Button
                  icon="power-off"
                  selected={!!engine.on}
                  onClick={() => act('toggle_engine', { ref: engine.ref })}
                >
                  {engine.on ? 'Вкл' : 'Выкл'}
                </Button>
              </OvermapRow>
            ))}
          </OvermapList>
          {!engines.length && <NoticeBox>Двигатели не найдены.</NoticeBox>}
          <Box mt={1.5}>
            <span className="OvermapHelm__caption">транспондер</span>
          </Box>
          {transponder ? (
            <>
              <Stack mb={1}>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="tower-broadcast"
                    selected={!!transponder.broadcasting}
                    onClick={() => actTransponder('toggle_broadcast')}
                  >
                    {transponder.broadcasting
                      ? 'Корабль виден на сенсорах'
                      : 'Корабль скрыт'}
                  </Button>
                </Stack.Item>
                <Stack.Item grow>
                  <Button
                    fluid
                    icon="triangle-exclamation"
                    color={distress ? 'bad' : undefined}
                    selected={!!distress}
                    onClick={() => actTransponder('toggle_distress')}
                  >
                    {distress ? 'Сигнал бедствия подаётся' : 'Подать SOS'}
                  </Button>
                </Stack.Item>
              </Stack>
              <TransponderPanel data={transponder} act={actTransponder} />
            </>
          ) : (
            <NoticeBox danger={!!has_transponder}>
              {has_transponder
                ? 'Транспондер не отвечает: нет питания или он повреждён.'
                : 'На борту нет транспондера.'}
            </NoticeBox>
          )}
        </div>
      </div>
    </div>
  );
};

const RouteLock = () => {
  const { act, data } = useBackend<OvermapHelmData>();
  const {
    programmed_has_routes,
    programmed_busy,
    programmed_windup,
    programmed_eta,
    programmed_selected,
    programmed_routes = [],
  } = data;
  return (
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
                    onClick={() => act('select_programmed', { id: route.id })}
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
                  act('execute_programmed', { id: programmed_selected })
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
  );
};
