import { useEffect, useRef, useState } from 'react';
import { Icon } from 'tgui-core/components';
import { type BooleanLike, classes } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Setting = {
  id: string;
  name: string;
  kind: 'toggle' | 'choice' | 'color';
  value: BooleanLike | string;
  options?: string[];
};

type Implant = {
  uid: string;
  name: string;
  desc: string;
  zone: string;
  cost: number;
  blocked: BooleanLike;
  canToggle: BooleanLike;
  broken: BooleanLike;
  settings: Setting[];
};

type LoadedImplant = Implant & {
  hidden?: BooleanLike;
};

type EncyclopediaEntry = {
  name: string;
  desc: string;
  zone: string;
  cost: number;
  icon: string;
};

type LogEntry = {
  time: string;
  text: string;
  bad: BooleanLike;
};

type Patient = {
  name: string;
  health: number;
  stat: number;
  capacity: number;
  load: number;
  neuroadapter: BooleanLike;
};

type Data = {
  maxCapacity: number;
  baseCapacity: number;
  chipBonus: number;
  encyclopedia: EncyclopediaEntry[];
  busy: BooleanLike;
  operation: string | null;
  operationTime: number;
  log: LogEntry[];
  powered: BooleanLike;
  hasAccess: BooleanLike;
  canToggle: BooleanLike;
  patient: Patient | null;
  implants: Implant[];
  loaded: LoadedImplant | null;
};

const SEGMENT = 10;
const GLOBE_RADIUS = 190;
const GLOBE_SPIN = 0.0025;
const DRAG_SPEED = 0.008;

const ZONES: Record<string, string> = {
  head: 'Голова',
  eyes: 'Глаза',
  mouth: 'Рот',
  chest: 'Торс',
  groin: 'Живот',
  l_arm: 'Левая рука',
  r_arm: 'Правая рука',
  l_leg: 'Левая нога',
  r_leg: 'Правая нога',
  tail: 'Хвост',
};

const ZONE_ORDER = Object.keys(ZONES);

const STAT_NAMES = ['в сознании', 'без сознания', 'мёртв'];

const zoneName = (zone: string) => ZONES[zone] || 'Прочее';

const Gauge = (props: { capacity: number; load: number; max: number }) => {
  const { capacity, load, max } = props;
  const segments = Math.ceil(max / SEGMENT);
  const position = (value: number) =>
    `${(Math.min(Math.max(value, 0), max) / max) * 100}%`;

  const segmentState = (from: number) => {
    if (from < load) {
      return from < capacity ? 'used' : 'over';
    }
    return from < capacity ? 'free' : 'locked';
  };

  return (
    <div className="RipperDoc__gauge">
      <div className="RipperDoc__gaugeIcon">
        <Icon name="microchip" />
      </div>
      <div className="RipperDoc__gaugeBody">
        <div className="RipperDoc__gaugeBar">
          {Array.from({ length: segments }, (_, index) => {
            const from = (segments - 1 - index) * SEGMENT;
            return (
              <div
                key={index}
                className={`RipperDoc__segment RipperDoc__segment--${segmentState(from)}`}
              />
            );
          })}
        </div>
        <div
          className="RipperDoc__gaugeCap"
          style={{ bottom: position(capacity) }}
        >
          {capacity}
        </div>
        <div
          className="RipperDoc__gaugeFree"
          style={{ bottom: position(load) }}
        >
          <span
            className={classes([
              'RipperDoc__gaugeValue',
              capacity - load < 0 && 'RipperDoc__gaugeValue--bad',
            ])}
          >
            {capacity - load}
          </span>
        </div>
      </div>
    </div>
  );
};

const Vitals = (props: { patient: Patient }) => {
  const { health, stat } = props.patient;
  const tone =
    stat === 2 || health <= 0 ? 'bad' : health < 50 ? 'warn' : 'good';
  return (
    <div className={`RipperDoc__vitals RipperDoc__vitals--${tone}`}>
      <span className="RipperDoc__pulse" />
      <span>{STAT_NAMES[stat] || STAT_NAMES[2]}</span>
      <div className="RipperDoc__vitalsBar">
        <div style={{ width: `${Math.min(Math.max(health, 0), 100)}%` }} />
      </div>
      <b>{Math.max(health, 0)}%</b>
    </div>
  );
};

const OperationLog = (props: { log: LogEntry[] }) => (
  <div className="RipperDoc__log">
    <div className="RipperDoc__label">Журнал</div>
    {!props.log.length && (
      <div className="RipperDoc__note">Сегодня стол ещё не работал.</div>
    )}
    {[...props.log].reverse().map((entry, index) => (
      <div
        key={`${entry.time}${entry.text}${index}`}
        className={classes([
          'RipperDoc__logLine',
          !!entry.bad && 'RipperDoc__logLine--bad',
        ])}
      >
        <span className="RipperDoc__logTime">{entry.time}</span>
        {entry.text}
      </div>
    ))}
  </div>
);

const SettingControl = (props: { implant: Implant; setting: Setting }) => {
  const { act, data } = useBackend<Data>();
  const { implant, setting } = props;
  const locked = !data.hasAccess || !!data.busy;
  const send = (value: BooleanLike | string) =>
    act('setting', { uid: implant.uid, id: setting.id, value });

  if (setting.kind === 'toggle') {
    return (
      <div className="RipperDoc__switch">
        {[true, false].map((state) => (
          <button
            key={String(state)}
            type="button"
            disabled={locked}
            className={classes([
              'RipperDoc__switchSide',
              !!setting.value === state && 'RipperDoc__switchSide--on',
            ])}
            onClick={() => send(state)}
          >
            {state ? 'ВКЛ' : 'ВЫКЛ'}
          </button>
        ))}
      </div>
    );
  }

  if (setting.kind === 'color') {
    return (
      <div className="RipperDoc__swatches">
        {(setting.options || []).map((option) => (
          <button
            key={option}
            type="button"
            title={option}
            disabled={locked}
            style={{ backgroundColor: option }}
            className={classes([
              'RipperDoc__swatch',
              String(setting.value).toUpperCase() === option.toUpperCase() &&
                'RipperDoc__swatch--on',
            ])}
            onClick={() => send(option)}
          />
        ))}
      </div>
    );
  }

  return (
    <div className="RipperDoc__choices">
      {(setting.options || []).map((option) => (
        <button
          key={option}
          type="button"
          disabled={locked}
          className={classes([
            'RipperDoc__choice',
            setting.value === option && 'RipperDoc__choice--on',
          ])}
          onClick={() => send(option)}
        >
          {option}
        </button>
      ))}
    </div>
  );
};

const Details = (props: { implant: Implant | null; isLoaded: boolean }) => {
  const { act, data } = useBackend<Data>();
  const { implant, isLoaded } = props;
  const locked = !data.hasAccess || !!data.busy;

  if (!implant) {
    return (
      <div className="RipperDoc__details RipperDoc__details--empty">
        <Icon name="crosshairs" size={2} />
        <div>Выберите имплант</div>
      </div>
    );
  }

  return (
    <div className="RipperDoc__details">
      <div className="RipperDoc__detailsHead">
        <div className="RipperDoc__detailsName">{implant.name}</div>
        <div className="RipperDoc__detailsMeta">
          <span>{isLoaded ? 'Лоток' : zoneName(implant.zone)}</span>
          <span className="RipperDoc__cost">{implant.cost}</span>
        </div>
      </div>
      <div className="RipperDoc__desc">{implant.desc}</div>
      {!!implant.broken && (
        <div className="RipperDoc__warning">
          <Icon name="triangle-exclamation" /> Имплант неисправен
        </div>
      )}
      {!!implant.blocked && (
        <div className="RipperDoc__blocked">
          <Icon name="power-off" /> Отключён: не работает, не боится ЭМИ и почти
          не нагружает совместимость.
        </div>
      )}
      {!implant.blocked && (
        <>
          <div className="RipperDoc__label">Прошивка</div>
          {!implant.settings.length && (
            <div className="RipperDoc__note">
              Прошивка закрыта производителем.
            </div>
          )}
          {implant.settings.map((setting) => (
            <div key={setting.id} className="RipperDoc__setting">
              <div className="RipperDoc__settingName">{setting.name}</div>
              <SettingControl implant={implant} setting={setting} />
            </div>
          ))}
        </>
      )}
      {!isLoaded && !!data.canToggle && (
        <button
          type="button"
          className={classes([
            'RipperDoc__action',
            !implant.blocked && 'RipperDoc__action--red',
          ])}
          disabled={locked || !implant.canToggle}
          onClick={() => act('toggle_power', { uid: implant.uid })}
        >
          <Icon name="power-off" /> {implant.blocked ? 'Включить' : 'Отключить'}
        </button>
      )}
    </div>
  );
};

const Tray = (props: { onSelect: () => void }) => {
  const { act, data } = useBackend<Data>();
  const { loaded, busy } = data;

  if (!loaded) {
    return (
      <div className="RipperDoc__tray RipperDoc__tray--empty">
        <Icon name="box-open" />
        Лоток пуст. Положите имплант на стол, чтобы перенастроить его заранее.
      </div>
    );
  }

  return (
    <div className="RipperDoc__tray">
      <div className="RipperDoc__trayInfo">
        <div className="RipperDoc__label">Лоток</div>
        <div className="RipperDoc__trayName">{loaded.name}</div>
        <div className="RipperDoc__note">
          {loaded.hidden
            ? 'Сканер не узнаёт прошивку'
            : `Слот: ${zoneName(loaded.zone)} · нагрузка ${loaded.cost}`}
        </div>
      </div>
      <div className="RipperDoc__trayButtons">
        {!loaded.hidden && (
          <button
            type="button"
            className="RipperDoc__action"
            onClick={props.onSelect}
          >
            <Icon name="sliders" /> Прошивка
          </button>
        )}
        <button
          type="button"
          className="RipperDoc__action RipperDoc__action--red"
          disabled={!!busy}
          onClick={() => act('eject')}
        >
          <Icon name="hand-holding" /> Забрать
        </button>
      </div>
    </div>
  );
};

const ImplantList = (props: {
  selected: string | null;
  setSelected: (uid: string) => void;
}) => {
  const { data } = useBackend<Data>();
  const { implants, patient } = data;
  const { selected, setSelected } = props;

  if (!patient) {
    return (
      <div className="RipperDoc__list RipperDoc__list--empty">
        <Icon name="bed" size={2} />
        <div>Стол пуст</div>
        <small>Уложите пациента — сканер сам найдёт его кибернетику.</small>
      </div>
    );
  }

  const zones = ZONE_ORDER.filter((zone) =>
    implants.some((implant) => implant.zone === zone),
  );
  const other = implants.filter((implant) => !ZONES[implant.zone]);

  const renderRow = (implant: Implant) => (
    <button
      key={implant.uid}
      type="button"
      className={classes([
        'RipperDoc__row',
        selected === implant.uid && 'RipperDoc__row--selected',
        !!implant.broken && 'RipperDoc__row--broken',
        !!implant.blocked && 'RipperDoc__row--blocked',
      ])}
      onClick={() => setSelected(implant.uid)}
    >
      <span className="RipperDoc__rowName">{implant.name}</span>
      {!!implant.blocked && (
        <Icon name="power-off" className="RipperDoc__rowIcon" />
      )}
      {!implant.blocked && !!implant.settings.length && (
        <Icon name="sliders" className="RipperDoc__rowIcon" />
      )}
      <span className="RipperDoc__cost">{implant.cost}</span>
    </button>
  );

  return (
    <div className="RipperDoc__list">
      {!implants.length && (
        <div className="RipperDoc__note">
          Сканер не нашёл кибернетики. Чистый, как с завода.
        </div>
      )}
      {zones.map((zone) => (
        <div key={zone} className="RipperDoc__group">
          <div className="RipperDoc__label">{ZONES[zone]}</div>
          {implants.filter((implant) => implant.zone === zone).map(renderRow)}
        </div>
      ))}
      {!!other.length && (
        <div className="RipperDoc__group">
          <div className="RipperDoc__label">Прочее</div>
          {other.map(renderRow)}
        </div>
      )}
    </div>
  );
};

const Encyclopedia = (props: { onClose: () => void }) => {
  const { data } = useBackend<Data>();
  const { encyclopedia } = data;
  const [rotation, setRotation] = useState({ yaw: 0, pitch: -0.3 });
  const [hovered, setHovered] = useState<EncyclopediaEntry | null>(null);
  const drag = useRef<{ x: number; y: number } | null>(null);
  const paused = useRef(false);

  useEffect(() => {
    let frame = 0;
    const spin = () => {
      if (!paused.current && !drag.current) {
        setRotation((current) => ({
          ...current,
          yaw: current.yaw + GLOBE_SPIN,
        }));
      }
      frame = requestAnimationFrame(spin);
    };
    frame = requestAnimationFrame(spin);
    return () => cancelAnimationFrame(frame);
  }, []);

  const count = encyclopedia.length;
  const points = encyclopedia.map((entry, index) => {
    const y = 1 - (index / Math.max(count - 1, 1)) * 2;
    const ring = Math.sqrt(1 - y * y);
    const theta = index * Math.PI * (3 - Math.sqrt(5));
    let x = Math.cos(theta) * ring;
    let z = Math.sin(theta) * ring;
    let py = y;
    const cosYaw = Math.cos(rotation.yaw);
    const sinYaw = Math.sin(rotation.yaw);
    [x, z] = [x * cosYaw - z * sinYaw, x * sinYaw + z * cosYaw];
    const cosPitch = Math.cos(rotation.pitch);
    const sinPitch = Math.sin(rotation.pitch);
    [py, z] = [py * cosPitch - z * sinPitch, py * sinPitch + z * cosPitch];
    return { entry, x, y: py, z };
  });

  return (
    <div className="RipperDoc__globeOverlay">
      <div className="RipperDoc__globeHead">
        <span className="RipperDoc__label">Справочник имплантов</span>
        <span className="RipperDoc__note">
          Тяните мышью, чтобы вращать. Наведите на имплант, чтобы прочитать.
        </span>
        <div className="RipperDoc__spacer" />
        <button
          type="button"
          className="RipperDoc__action RipperDoc__action--ghost RipperDoc__globeClose"
          onClick={props.onClose}
        >
          <Icon name="xmark" /> Закрыть
        </button>
      </div>
      <div className="RipperDoc__globeBody">
        <div
          className="RipperDoc__globe"
          onMouseDown={(event) => {
            drag.current = { x: event.clientX, y: event.clientY };
          }}
          onMouseMove={(event) => {
            if (!drag.current) {
              return;
            }
            const dx = event.clientX - drag.current.x;
            const dy = event.clientY - drag.current.y;
            drag.current = { x: event.clientX, y: event.clientY };
            setRotation((current) => ({
              yaw: current.yaw + dx * DRAG_SPEED,
              pitch: Math.max(
                -1.4,
                Math.min(1.4, current.pitch + dy * DRAG_SPEED),
              ),
            }));
          }}
          onMouseUp={() => {
            drag.current = null;
          }}
          onMouseLeave={() => {
            drag.current = null;
          }}
        >
          <div className="RipperDoc__globeCore" />
          {points.map(({ entry, x, y, z }) => {
            const depth = (z + 1) / 2;
            const size = 22 + depth * 26;
            return (
              <img
                key={entry.name}
                src={`data:image/png;base64,${entry.icon}`}
                alt={entry.name}
                draggable={false}
                className={classes([
                  'RipperDoc__globeIcon',
                  hovered === entry && 'RipperDoc__globeIcon--hovered',
                ])}
                style={{
                  width: `${size}px`,
                  height: `${size}px`,
                  left: `calc(50% + ${x * GLOBE_RADIUS - size / 2}px)`,
                  top: `calc(50% + ${y * GLOBE_RADIUS - size / 2}px)`,
                  opacity: 0.25 + depth * 0.75,
                  zIndex: Math.round(depth * 100),
                }}
                onMouseEnter={() => {
                  paused.current = true;
                  setHovered(entry);
                }}
                onMouseLeave={() => {
                  paused.current = false;
                }}
              />
            );
          })}
        </div>
        <div className="RipperDoc__globeCard">
          {hovered ? (
            <>
              <img
                className="RipperDoc__globeCardIcon"
                src={`data:image/png;base64,${hovered.icon}`}
                alt={hovered.name}
              />
              <div className="RipperDoc__detailsName">{hovered.name}</div>
              <div className="RipperDoc__detailsMeta">
                <span>{zoneName(hovered.zone)}</span>
                <span className="RipperDoc__cost">{hovered.cost}</span>
              </div>
              <div className="RipperDoc__desc">{hovered.desc}</div>
            </>
          ) : (
            <div className="RipperDoc__note">
              В справочнике {count} моделей. Наведите на любую.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export const RipperDoc = () => {
  const { data } = useBackend<Data>();
  const {
    patient,
    implants,
    loaded,
    maxCapacity,
    baseCapacity,
    chipBonus,
    busy,
    operation,
    operationTime,
    log,
    powered,
    hasAccess,
  } = data;
  const [selected, setSelected] = useState<string | null>(null);
  const [globe, setGlobe] = useState(false);

  const selectedImplant =
    implants.find((implant) => implant.uid === selected) ||
    (loaded && !loaded.hidden && loaded.uid === selected ? loaded : null);
  const chips = patient
    ? Math.max(0, Math.floor((patient.capacity - baseCapacity) / chipBonus))
    : 0;
  const maxChips = Math.ceil((maxCapacity - baseCapacity) / chipBonus);
  const overload = patient ? patient.load - patient.capacity : 0;

  return (
    <Window width={900} height={640} theme="ripperdoc">
      <Window.Content>
        <div className="RipperDoc">
          <div className="RipperDoc__sweep" />
          <div className="RipperDoc__header">
            <div className="RipperDoc__logo">RIPPERDOC</div>
            <div className="RipperDoc__subtitle">кабинет кибернетики</div>
            <div className="RipperDoc__spacer" />
            {!powered && (
              <div className="RipperDoc__pill RipperDoc__pill--bad">
                нет питания
              </div>
            )}
            {!hasAccess && (
              <div className="RipperDoc__pill RipperDoc__pill--bad">
                нет допуска к столу
              </div>
            )}
            <button
              type="button"
              className="RipperDoc__pill RipperDoc__pill--button"
              onClick={() => setGlobe(true)}
            >
              <Icon name="globe" /> справочник
            </button>
          </div>
          <div className="RipperDoc__patientBar">
            <Icon name="user" />
            <span className="RipperDoc__patientName">
              {patient ? patient.name : 'Стол пуст'}
            </span>
            {!!patient && <Vitals patient={patient} />}
            {!!patient && !patient.neuroadapter && (
              <span className="RipperDoc__link RipperDoc__link--off">
                нейроадаптер не обнаружен
              </span>
            )}
          </div>
          <div className="RipperDoc__body">
            <div className="RipperDoc__side">
              {patient ? (
                <Gauge
                  capacity={patient.capacity}
                  load={patient.load}
                  max={maxCapacity}
                />
              ) : (
                <div className="RipperDoc__gauge RipperDoc__gauge--empty" />
              )}
              <div className="RipperDoc__stats">
                <div>
                  <small>Ёмкость</small>
                  <b>{patient ? patient.capacity : '--'}</b>
                </div>
                <div>
                  <small>Нагрузка</small>
                  <b className={overload > 0 ? 'RipperDoc__bad' : undefined}>
                    {patient ? patient.load : '--'}
                  </b>
                </div>
                <div>
                  <small>Чипы</small>
                  <b>
                    {chips}
                    <i>/{maxChips}</i>
                  </b>
                </div>
                <div>
                  <small>Перегрузка</small>
                  <b className={overload > 0 ? 'RipperDoc__bad' : undefined}>
                    {Math.max(overload, 0)}
                  </b>
                </div>
              </div>
            </div>
            <ImplantList selected={selected} setSelected={setSelected} />
            <div className="RipperDoc__column">
              <Details
                implant={selectedImplant}
                isLoaded={!!loaded && selected === loaded.uid}
              />
              <OperationLog log={log} />
            </div>
          </div>
          <Tray onSelect={() => loaded && setSelected(loaded.uid)} />
          {!!busy && (
            <div className="RipperDoc__busy">
              <div className="RipperDoc__busyText">Не двигайте пациента</div>
              {!!operation && (
                <div className="RipperDoc__busyName">{operation}</div>
              )}
              {operationTime > 0 ? (
                <div className="RipperDoc__busyTrack">
                  <div
                    key={operation}
                    className="RipperDoc__busyFill"
                    style={{ animationDuration: `${operationTime}s` }}
                  />
                </div>
              ) : (
                <div className="RipperDoc__busyBar" />
              )}
            </div>
          )}
          {globe && <Encyclopedia onClose={() => setGlobe(false)} />}
        </div>
      </Window.Content>
    </Window>
  );
};
