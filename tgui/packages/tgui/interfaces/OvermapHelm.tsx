import { type ReactNode, useState } from 'react';
import { Icon } from 'tgui-core/components';
import { type BooleanLike, classes } from 'tgui-core/react';

import { useBackend, useLocalState } from '../backend';
import {
  OvermapFrame,
  overmapKindIcon,
  overmapKindLabel,
} from './overmap/OvermapChrome';
import {
  type GalaxyMap,
  type HazardField,
  OvermapRadar,
  type RadarContact,
  type RadarObject,
  type RadarPeel,
  type RadarProjectile,
  type RadarScatterChunk,
  type RadarShape,
  type RadarTerrain,
} from './overmap/OvermapRadar';
import type { RadarDock } from './overmap/radarInterpolation';

type Phase = 'route' | 'relay' | 'docked' | 'transit' | 'flight';

type EngineInfo = {
  name: string;
  ref: string;
  on: BooleanLike;
  thrust: number;
  status: string;
};

type LandingPad = {
  id: string;
  name: string;
  can_dock: BooleanLike;
  reason?: string;
};

type ProgrammedRoute = {
  id: string;
  name: string;
};

type Waypoint = {
  name: string;
  x: number;
  y: number;
};

type Weapon = {
  id: string;
  name: string;
  selected: BooleanLike;
  auto: BooleanLike;
  turret: BooleanLike;
  cooldown: number;
  arc: number;
  heading: number;
  x: number;
  y: number;
};

type HelmData = {
  linked: BooleanLike;
  vessel_name: string;
  status: string;
  phase: Phase;
  x: number;
  y: number;
  sector_id?: string;
  sector_name?: string;
  sector_size: number;
  sector_neighbors?: Record<string, string>;
  cell_span?: number;
  self_pos?: number[];
  speed: number;
  facing: number;
  local_space?: BooleanLike;
  radar_enabled?: BooleanLike;
  radar_reach?: number;
  map_jammed: BooleanLike;

  is_pod?: BooleanLike;
  can_steer: BooleanLike;
  piloting: BooleanLike;
  pilot_name?: string | null;
  autopilot: BooleanLike;
  autopilot_status?: string;
  eta?: number;
  navigation_target_id?: string;
  programmed_cancellable?: BooleanLike;

  dest?: number[];
  dest_name?: string;
  dest_range?: number;
  dest_relay?: string;

  can_undock: BooleanLike;
  can_ship_undock?: BooleanLike;
  ship_docked_to?: string | null;
  can_relay_jump?: BooleanLike;
  relay_to?: string;
  can_land?: BooleanLike;
  can_stop?: BooleanLike;
  host_name?: string;
  docks?: LandingPad[];
  dock_name?: string;
  dock_distance?: number;
  dock_aligning?: BooleanLike;

  engines: EngineInfo[];
  power?: {
    apc_charge: number;
    apc_max: number;
    smes_charge: number;
    smes_max: number;
    sources: number;
  };
  thrust_hint?: string;
  has_transponder: BooleanLike;
  transponder: { broadcasting: BooleanLike } | null;
  distress?: BooleanLike;
  broadcasting?: BooleanLike;
  weapons?: Weapon[];

  radar_outlines?: Record<string, string>;
  radar_peels?: RadarPeel[];
  radar_scatter?: RadarScatterChunk[];
  radar_docks?: RadarDock[];
  dock_preview?: { x: number; y: number; facing: number; tiles: number[] };
  radar_locked?: BooleanLike;
  radar_tick?: number;
  radar_epoch?: number;
  radar_shapes?: Record<string, RadarShape>;
  radar?: RadarContact[];
  radar_drifters?: number[][];
  radar_projectiles?: RadarProjectile[];
  radar_terrain?: RadarTerrain | null;
  radar_world?: number[];
  galaxy?: GalaxyMap | null;
  objects: RadarObject[];
  hazard_fields?: HazardField[];
  waypoints?: Waypoint[];

  programmed_locked?: BooleanLike;
  programmed_has_routes?: BooleanLike;
  programmed_busy?: BooleanLike;
  programmed_windup?: number;
  programmed_eta?: string;
  programmed_selected?: string;
  programmed_routes?: ProgrammedRoute[];
};

const CUSTOM_DOCK_ID = '__overmap_custom';

const etaText = (seconds?: number) => {
  if (!seconds) {
    return '';
  }
  const minutes = Math.floor(seconds / 60);
  const rest = Math.round(seconds % 60);
  return minutes ? `${minutes} мин ${rest} с` : `${rest} с`;
};

const phaseTitle = (data: HelmData) => {
  switch (data.phase) {
    case 'route':
      return 'Полёт по маршруту';
    case 'relay':
      return 'Прыжок';
    case 'docked':
      return data.status;
    case 'transit':
      return 'Гиперпространство';
    default:
      if (data.dock_aligning) {
        return 'Стыковка';
      }
      return data.local_space ? 'Полёт у объекта' : 'Открытый космос';
  }
};

const phaseHint = (data: HelmData) => {
  switch (data.phase) {
    case 'relay':
      return 'Корабль выйдет по ту сторону ретранслятора сам.';
    case 'docked':
      return 'Выберите цель и отстыкуйтесь.';
    case 'transit':
    case 'flight':
      if (data.dock_aligning) {
        return 'Шлюзы сводятся.';
      }
      if (data.dock_name) {
        return 'Подведите корабль в синюю зону на радаре — шлюзы сведутся сами.';
      }
      if (data.autopilot) {
        return `${data.autopilot_status || 'Автопилот ведёт к цели'}. Любая клавиша полёта — ручное управление.`;
      }
      if (data.pilot_name && !data.piloting) {
        return `За штурвалом ${data.pilot_name}.`;
      }
      if (data.is_pod || data.piloting) {
        return data.dest_name
          ? 'Ведите корабль клавишами или нажмите «Лететь».'
          : 'Ведите корабль клавишами или выберите цель.';
      }
      return 'Подойдите к консоли вплотную, чтобы управлять.';
    default:
      return '';
  }
};

const HelmButton = (props: {
  good?: boolean;
  danger?: boolean;
  selected?: BooleanLike;
  disabled?: BooleanLike;
  title?: string;
  onClick: () => void;
  children?: ReactNode;
}) => (
  <button
    type="button"
    title={props.title}
    disabled={!!props.disabled}
    className={classes([
      'OvermapHelm__button',
      (props.good || props.selected) && 'OvermapHelm__button--good',
      props.danger && 'OvermapHelm__button--danger',
    ])}
    onClick={props.onClick}
  >
    {props.children}
  </button>
);

const Stripe = (props: { children: ReactNode; onClick?: () => void }) => (
  <div
    className={classes([
      'OvermapHelm__stripe',
      props.onClick && 'OvermapHelm__stripe--toggle',
    ])}
    onClick={props.onClick}
  >
    {props.children}
  </div>
);

const Readouts = (props: { rows: [string, ReactNode][] }) => (
  <div className="OvermapHelm__readouts">
    {props.rows.map(([label, value]) => (
      <div key={label} className="OvermapHelm__readout">
        <span>{label}</span>
        <span>{value}</span>
      </div>
    ))}
  </div>
);

const Entry = (props: {
  icon: string;
  color?: string | null;
  name: ReactNode;
  meta?: ReactNode;
  aside?: ReactNode;
  selected?: BooleanLike;
  disabled?: BooleanLike;
  onClick?: () => void;
}) => (
  <button
    type="button"
    disabled={!!props.disabled}
    className={classes([
      'OvermapHelm__entry',
      props.selected && 'OvermapHelm__entry--selected',
    ])}
    onClick={props.onClick}
  >
    <Icon
      name={props.icon}
      className="OvermapHelm__entryIcon"
      style={props.color ? { color: props.color } : undefined}
    />
    <span className="OvermapHelm__entryBody">
      <span className="OvermapHelm__entryName">{props.name}</span>
      {!!props.meta && (
        <span className="OvermapHelm__entryMeta">{props.meta}</span>
      )}
    </span>
    {props.aside !== undefined && (
      <span className="OvermapHelm__entryAside">{props.aside}</span>
    )}
  </button>
);

export const OvermapHelm = () => {
  const { act, data } = useBackend<HelmData>();
  return (
    <OvermapFrame
      title={data.vessel_name ? `Штурвал — ${data.vessel_name}` : 'Штурвал'}
      width={1060}
      height={760}
      linked={data.linked}
      onRelink={() => act('relink')}
    >
      <div className="OvermapHelm">
        <div
          className={classes([
            'OvermapHelm__body',
            data.programmed_locked && 'OvermapHelm__body--locked',
          ])}
        >
          <div className="OvermapHelm__radar">
            <HelmRadar />
          </div>
          <aside className="OvermapHelm__side">
            <StatusSection />
            <ActionsSection />
            <DockingSection />
            <TargetSection />
            <RoutesSection />
            <PlacesSection />
            <WeaponsSection />
            <SystemsSection />
          </aside>
        </div>
        {!!data.programmed_locked && <RouteLock />}
      </div>
    </OvermapFrame>
  );
};

const HelmRadar = () => {
  const { act, data } = useBackend<HelmData>();
  const [radius, setRadius] = useLocalState('helmRadarZoom', 64);
  const [followHeading, setFollowHeading] = useLocalState(
    'helmRadarFollow',
    false,
  );
  const aiming = !!data.weapons?.some((weapon) => weapon.selected);
  if (data.map_jammed && !data.radar_locked) {
    return <div className="OvermapHelm__jam">Сигнал потерян: идёт прыжок</div>;
  }
  return (
    <OvermapRadar
      outlines={data.radar_outlines}
      locked={!!data.radar_locked}
      tick={data.radar_tick}
      epoch={data.radar_epoch}
      peels={data.radar_peels}
      scatter={data.radar_scatter}
      dockTargets={data.radar_docks}
      dockPreview={data.dock_preview}
      onSelectDock={(id) => {
        const dock = data.radar_docks?.find((entry) => entry.id === id);
        if (dock && aiming) {
          act('radar_point', { x: dock.x, y: dock.y });
        } else {
          act('select_radar_dock', { id });
        }
      }}
      onSelectPoint={(x, y) => act('radar_point', { x, y })}
      onSelectObject={(id) => act('set_dest', { id, x: 1, y: 1 })}
      shapes={data.radar_shapes || {}}
      contacts={data.radar || []}
      drifters={data.radar_drifters || []}
      projectiles={data.radar_projectiles || []}
      weaponArcs={(data.weapons || []).filter((weapon) => weapon.selected)}
      facing={data.facing || 0}
      terrain={data.radar_terrain}
      world={data.radar_world}
      objects={data.objects}
      self={data.self_pos}
      sectorSize={data.sector_size}
      sectorNeighbors={data.sector_neighbors}
      cellSpan={data.cell_span}
      sectorId={data.sector_id}
      galaxy={data.galaxy}
      radius={radius}
      onZoom={setRadius}
      onReach={(reach) => {
        if (reach !== data.radar_reach) {
          act('helm_radar_reach', { reach });
        }
      }}
      followHeading={followHeading}
      onToggleFollow={() => setFollowHeading(!followHeading)}
      dest={data.dest}
      hazardFields={data.hazard_fields || []}
    />
  );
};

const KEYS: [string, string][] = [
  ['W S', 'тяга'],
  ['A D', 'вбок'],
  ['Q E', 'поворот'],
  ['Пробел', 'тормоз'],
];

const StatusSection = () => {
  const { data } = useBackend<HelmData>();
  const hint = phaseHint(data);
  const flying = data.phase === 'flight' || data.phase === 'transit';
  const rows: [string, ReactNode][] = [
    ['Сектор', data.sector_name || '—'],
    ['Клетка', `${data.x}:${data.y}`],
  ];
  if (flying) {
    rows.push(['Скорость', `${data.speed} м/с`]);
  }
  if (data.autopilot && data.eta) {
    rows.push(['До цели', etaText(data.eta)]);
  }
  return (
    <>
      <Stripe>{phaseTitle(data)}</Stripe>
      {!!hint && <div className="OvermapHelm__note">{hint}</div>}
      <Readouts rows={rows} />
      {flying && !!data.piloting && (
        <div className="OvermapHelm__keys">
          {KEYS.map(([key, label]) => (
            <span key={key}>
              <kbd>{key}</kbd> {label}
            </span>
          ))}
        </div>
      )}
      {!!data.thrust_hint && (
        <div className="OvermapHelm__warning">{data.thrust_hint}</div>
      )}
    </>
  );
};

const ActionsSection = () => {
  const { act, data } = useBackend<HelmData>();
  if (
    !data.can_undock &&
    !data.can_ship_undock &&
    !data.can_relay_jump &&
    !data.programmed_cancellable
  ) {
    return null;
  }
  return (
    <div className="OvermapHelm__stack OvermapHelm__stack--gap">
      {!!data.can_undock && (
        <HelmButton good onClick={() => act('undock')}>
          Отстыковаться
        </HelmButton>
      )}
      {!!data.can_ship_undock && (
        <HelmButton onClick={() => act('dock_ship')}>
          {data.ship_docked_to
            ? `Отцепиться от ${data.ship_docked_to}`
            : 'Отцепить корабли'}
        </HelmButton>
      )}
      {!!data.can_relay_jump && (
        <HelmButton good onClick={() => act('relay_jump')}>
          {data.relay_to ? `Прыжок в «${data.relay_to}»` : 'Прыжок'}
        </HelmButton>
      )}
      {!!data.programmed_cancellable && (
        <HelmButton danger onClick={() => act('cancel_programmed')}>
          Отменить автомаршрут
        </HelmButton>
      )}
    </div>
  );
};

const DockingSection = () => {
  const { act, data } = useBackend<HelmData>();
  if (data.phase !== 'flight') {
    return null;
  }
  if (data.dock_name) {
    return (
      <>
        <Stripe>Стыковка</Stripe>
        <div className="OvermapHelm__plate OvermapHelm__plate--dock">
          <div className="OvermapHelm__plateName">{data.dock_name}</div>
          <div className="OvermapHelm__plateMeta">
            {data.dock_aligning
              ? 'Сводим шлюзы…'
              : `до точки стыковки ${data.dock_distance ?? 0} м`}
          </div>
          {!data.dock_aligning && (
            <HelmButton onClick={() => act('cancel_docking')}>
              Отменить
            </HelmButton>
          )}
        </div>
      </>
    );
  }
  const airlocks = (data.radar_docks || []).filter((dock) => !dock.own);
  const pads = (data.docks || []).filter((pad) => pad.id !== CUSTOM_DOCK_ID);
  if (!airlocks.length && !pads.length && !data.can_stop) {
    return null;
  }
  return (
    <>
      <Stripe>
        {pads.length && data.host_name
          ? `Стыковка: ${data.host_name}`
          : 'Стыковка'}
      </Stripe>
      <div className="OvermapHelm__list">
        {airlocks.map((dock) => (
          <Entry
            key={dock.id}
            icon="anchor"
            name={dock.name}
            meta={dock.available ? 'шлюз' : 'занят'}
            disabled={!dock.available}
            onClick={() => act('select_radar_dock', { id: dock.id })}
          />
        ))}
        {pads.map((pad) => (
          <Entry
            key={pad.id}
            icon="square-parking"
            name={pad.name}
            meta={pad.reason || 'площадка'}
            disabled={!pad.can_dock}
            onClick={() => act('prepare_landing', { id: pad.id })}
          />
        ))}
        {!!data.can_stop && (
          <Entry
            icon="location-dot"
            name={data.is_pod ? 'Сесть здесь' : 'Встать здесь'}
            meta="остановиться на месте"
            onClick={() => act(data.is_pod ? 'dock' : 'prepare_stop')}
          />
        )}
      </div>
    </>
  );
};

const TargetSection = () => {
  const { act, data } = useBackend<HelmData>();
  const { dest_name, dest_relay, dest_range, autopilot, can_steer } = data;
  if (!dest_name || data.phase === 'route') {
    return null;
  }
  return (
    <>
      <Stripe>Цель</Stripe>
      <div className="OvermapHelm__plate">
        <div className="OvermapHelm__plateName">{dest_name}</div>
        <div className="OvermapHelm__plateMeta">
          {dest_relay
            ? `ретранслятор в «${dest_relay}»`
            : `${dest_range ?? 0} кл. отсюда`}
        </div>
        <div className="OvermapHelm__pair">
          {data.phase !== 'docked' && (
            <HelmButton
              selected={autopilot}
              disabled={!can_steer}
              onClick={() => act('toggle_autopilot')}
            >
              {autopilot ? 'Стоп' : 'Лететь'}
            </HelmButton>
          )}
          <HelmButton onClick={() => act('clear_dest')}>Сбросить</HelmButton>
        </div>
      </div>
    </>
  );
};

const RoutesSection = () => {
  const { act, data } = useBackend<HelmData>();
  const routes = data.programmed_routes || [];
  if (!data.programmed_has_routes || data.programmed_locked || !routes.length) {
    return null;
  }
  return (
    <>
      <Stripe>Автомаршрут</Stripe>
      <div className="OvermapHelm__stack">
        {routes.map((route) => (
          <HelmButton
            key={route.id}
            disabled={data.programmed_busy}
            onClick={() => act('execute_programmed', { id: route.id })}
          >
            {route.name}
          </HelmButton>
        ))}
        {!!data.programmed_busy && (
          <div className="OvermapHelm__note">
            {data.programmed_windup
              ? `Отправление через ${data.programmed_windup} с`
              : `В пути, ${data.programmed_eta || ''}`}
          </div>
        )}
      </div>
    </>
  );
};

const PlacesSection = () => {
  const { act, data } = useBackend<HelmData>();
  const { objects = [], waypoints = [], self_pos, dest } = data;
  const distance = (place: { x: number; y: number }) =>
    self_pos
      ? Math.round(
          Math.max(
            Math.abs(place.x - self_pos[0]),
            Math.abs(place.y - self_pos[1]),
          ),
        )
      : 0;
  const places = objects
    .filter((object) => !object.is_self && object.kind !== 'hazard')
    .sort((a, b) => distance(a) - distance(b));
  const isDest = (place: { id?: string; x: number; y: number }) =>
    data.navigation_target_id && place.id
      ? data.navigation_target_id === place.id
      : !!dest && dest[0] === place.x && dest[1] === place.y;
  const marks = waypoints.filter(
    (mark) => !places.some((place) => place.name === mark.name),
  );
  return (
    <>
      <Stripe>Куда лететь</Stripe>
      <div className="OvermapHelm__list">
        {places.map((place) => (
          <Entry
            key={`${place.kind}-${place.name}-${place.x}-${place.y}`}
            icon={
              place.distress
                ? 'triangle-exclamation'
                : overmapKindIcon(place.kind)
            }
            color={place.distress ? undefined : place.color}
            name={place.name}
            meta={
              place.kind === 'relay' && place.leads_to
                ? `в «${place.leads_to}»`
                : overmapKindLabel(place.kind)
            }
            aside={`${distance(place)} кл.`}
            selected={isDest(place)}
            onClick={() =>
              act('set_dest', {
                id: place.id,
                x: place.x,
                y: place.y,
                name: place.name,
              })
            }
          />
        ))}
        {marks.map((mark) => (
          <Entry
            key={mark.name}
            icon="location-dot"
            name={mark.name}
            meta="метка"
            aside={`${distance(mark)} кл.`}
            selected={isDest(mark)}
            onClick={() =>
              act('set_dest', { x: mark.x, y: mark.y, name: mark.name })
            }
          />
        ))}
        {!places.length && !marks.length && (
          <div className="OvermapHelm__note">Сенсоры ничего не видят.</div>
        )}
      </div>
    </>
  );
};

const WeaponsSection = () => {
  const { act, data } = useBackend<HelmData>();
  const weapons = data.weapons || [];
  if (!weapons.length) {
    return null;
  }
  return (
    <>
      <Stripe>Орудия</Stripe>
      <div className="OvermapHelm__list">
        {weapons.map((weapon) => (
          <div key={weapon.id} className="OvermapHelm__row">
            <Entry
              icon="crosshairs"
              name={weapon.name}
              meta={
                weapon.cooldown > 0
                  ? `перезарядка ${weapon.cooldown.toFixed(1)} с`
                  : `готово, сектор ${weapon.arc}°`
              }
              selected={weapon.selected}
              onClick={() => act('select_weapon', { id: weapon.id })}
            />
            {!!weapon.turret && (
              <HelmButton
                selected={weapon.auto}
                title="Стрелять по целям самостоятельно"
                onClick={() => act('weapon_auto', { id: weapon.id })}
              >
                Авто
              </HelmButton>
            )}
          </div>
        ))}
        {weapons.some((weapon) => weapon.selected) && (
          <div className="OvermapHelm__note">Клик по радару — выстрел.</div>
        )}
      </div>
    </>
  );
};

const PowerBar = (props: { label: string; charge: number; max: number }) => {
  const percent = Math.min(100, (props.charge / props.max) * 100);
  return (
    <div className="OvermapHelm__power">
      <div className="OvermapHelm__readout">
        <span>{props.label}</span>
        <span>{Math.round(percent)}%</span>
      </div>
      <div className="OvermapHelm__powerTrack">
        <div
          className={classes([
            'OvermapHelm__powerFill',
            percent < 25 && 'OvermapHelm__powerFill--low',
          ])}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  );
};

const SystemsSection = () => {
  const { act, data } = useBackend<HelmData>();
  const [open, setOpen] = useState(false);
  const { engines = [], power, transponder, has_transponder, distress } = data;
  const working = engines.filter((engine) => engine.on).length;
  const transmitting = transponder
    ? transponder.broadcasting
    : data.broadcasting;
  return (
    <>
      <Stripe onClick={() => setOpen(!open)}>Системы {open ? '▴' : '▾'}</Stripe>
      <Readouts
        rows={[
          ['Двигатели', `${working} из ${engines.length}`],
          ['Транспондер', transmitting ? 'в эфире' : 'молчит'],
          ...(distress ? ([['Сигнал', 'SOS']] as [string, string][]) : []),
        ]}
      />
      {open && (
        <>
          <div className="OvermapHelm__list OvermapHelm__list--gap">
            {engines.map((engine) => (
              <div key={engine.ref} className="OvermapHelm__row">
                <span className="OvermapHelm__entryBody">
                  <span className="OvermapHelm__entryName">{engine.name}</span>
                  <span className="OvermapHelm__entryMeta">
                    {engine.status}, тяга {engine.thrust}
                  </span>
                </span>
                <HelmButton
                  selected={engine.on}
                  onClick={() => act('toggle_engine', { ref: engine.ref })}
                >
                  {engine.on ? 'Вкл' : 'Выкл'}
                </HelmButton>
              </div>
            ))}
          </div>
          {!!power?.sources && power.apc_max > 0 && (
            <PowerBar
              label="Заряд щитка"
              charge={power.apc_charge}
              max={power.apc_max}
            />
          )}
          {!!power?.sources && power.smes_max > 0 && (
            <PowerBar
              label="СМЭС"
              charge={power.smes_charge}
              max={power.smes_max}
            />
          )}
          {transponder ? (
            <div className="OvermapHelm__pair">
              <HelmButton
                selected={transponder.broadcasting}
                onClick={() => act('transponder', { op: 'toggle_broadcast' })}
              >
                {transponder.broadcasting ? 'В эфире' : 'Молчит'}
              </HelmButton>
              <HelmButton
                danger={!!distress}
                onClick={() => act('transponder', { op: 'toggle_distress' })}
              >
                {distress ? 'Снять SOS' : 'Подать SOS'}
              </HelmButton>
            </div>
          ) : (
            <div className="OvermapHelm__note">
              {has_transponder
                ? 'Транспондер не отвечает: нет питания или он сломан.'
                : 'Транспондера на борту нет.'}
            </div>
          )}
        </>
      )}
    </>
  );
};

const RouteLock = () => {
  const { act, data } = useBackend<HelmData>();
  const {
    programmed_has_routes,
    programmed_busy,
    programmed_windup,
    programmed_eta,
    programmed_selected,
    programmed_routes = [],
  } = data;
  return (
    <div className="OvermapHelm__lock">
      <div className="OvermapHelm__lockPanel">
        <Stripe>Ручное управление заблокировано</Stripe>
        <div className="OvermapHelm__note">
          Шаттл летает только по маршрутам поставщика.
        </div>
        {!!programmed_has_routes && (
          <div className="OvermapHelm__stack">
            {programmed_routes.map((route) => (
              <HelmButton
                key={route.id}
                selected={programmed_selected === route.id}
                disabled={programmed_busy}
                onClick={() => act('select_programmed', { id: route.id })}
              >
                {route.name}
              </HelmButton>
            ))}
            {programmed_busy ? (
              <div className="OvermapHelm__note">
                {programmed_windup
                  ? `Отправление через ${programmed_windup} с`
                  : `В пути, ${programmed_eta || ''}`}
              </div>
            ) : (
              <HelmButton
                good
                disabled={!programmed_routes.length}
                onClick={() =>
                  act('execute_programmed', { id: programmed_selected })
                }
              >
                Отправить
              </HelmButton>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
