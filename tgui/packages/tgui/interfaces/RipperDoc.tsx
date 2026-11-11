import { useState } from 'react';
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
  removable: BooleanLike;
  broken: BooleanLike;
  settings: Setting[];
};

type LoadedImplant = Implant & {
  freed?: number;
  replaces?: string | null;
  risk?: number;
};

type Patient = {
  name: string;
  capacity: number;
  load: number;
  neuroadapter: BooleanLike;
  psychosisStage: number;
  psychosisName: string | null;
};

type Data = {
  maxCapacity: number;
  baseCapacity: number;
  chipBonus: number;
  psychoStage: number;
  busy: BooleanLike;
  powered: BooleanLike;
  hasAccess: BooleanLike;
  patient: Patient | null;
  implants: Implant[];
  loaded: LoadedImplant | null;
};

const SEGMENT = 10;

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

const STAGES = [
  'Сбой синхронизации',
  'Диссоциация',
  'Распад личности',
  'Киберпсихоз',
];

const zoneName = (zone: string) => ZONES[zone] || 'Прочее';

const riskTone = (risk: number) => {
  if (risk >= 30) {
    return 'bad';
  }
  return risk > 0 ? 'warn' : 'good';
};

const Gauge = (props: {
  capacity: number;
  load: number;
  max: number;
  cost: number;
  freed: number;
}) => {
  const { capacity, load, max, cost, freed } = props;
  const segments = Math.ceil(max / SEGMENT);
  const baseLoad = load - freed;
  const after = baseLoad + cost;
  const delta = freed - cost;
  const position = (value: number) =>
    `${(Math.min(Math.max(value, 0), max) / max) * 100}%`;

  const segmentState = (from: number) => {
    if (from < baseLoad) {
      return from < capacity ? 'used' : 'over';
    }
    if (cost && from < after) {
      return from < capacity ? 'preview' : 'overload';
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
          style={{ bottom: position(after) }}
        >
          <span
            className={classes([
              'RipperDoc__gaugeValue',
              capacity - after < 0 && 'RipperDoc__gaugeValue--bad',
            ])}
          >
            {capacity - after}
          </span>
          {!!cost && (
            <span
              className={classes([
                'RipperDoc__gaugeDelta',
                delta > 0 && 'RipperDoc__gaugeDelta--plus',
              ])}
            >
              {delta > 0 ? `+${delta}` : delta}
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

const Psychosis = (props: { stage: number; total: number }) => {
  const { stage, total } = props;
  return (
    <div className="RipperDoc__psychosis">
      <div className="RipperDoc__label">Киберпсихоз</div>
      <div className="RipperDoc__psychosisBar">
        {Array.from({ length: total }, (_, index) => (
          <div
            key={index}
            title={STAGES[index]}
            className={classes([
              'RipperDoc__psychosisCell',
              index < stage && 'RipperDoc__psychosisCell--on',
              index === total - 1 &&
                stage >= total &&
                'RipperDoc__psychosisCell--psycho',
            ])}
          />
        ))}
      </div>
      <div
        className={classes([
          'RipperDoc__psychosisText',
          stage >= total && 'RipperDoc__psychosisText--psycho',
        ])}
      >
        {stage ? STAGES[stage - 1] : 'Не обнаружен'}
      </div>
    </div>
  );
};

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
      <div className="RipperDoc__label">Прошивка</div>
      {!implant.settings.length && (
        <div className="RipperDoc__note">Настраиваемых параметров нет.</div>
      )}
      {implant.settings.map((setting) => (
        <div key={setting.id} className="RipperDoc__setting">
          <div className="RipperDoc__settingName">{setting.name}</div>
          <SettingControl implant={implant} setting={setting} />
        </div>
      ))}
      {!isLoaded && (
        <button
          type="button"
          className="RipperDoc__action RipperDoc__action--red"
          disabled={locked || !implant.removable}
          onClick={() => act('extract', { uid: implant.uid })}
        >
          <Icon name="eject" />{' '}
          {implant.removable ? 'Извлечь в лоток' : 'Не извлекается'}
        </button>
      )}
    </div>
  );
};

const Tray = () => {
  const { act, data } = useBackend<Data>();
  const { loaded, patient, busy, hasAccess } = data;

  if (!loaded) {
    return (
      <div className="RipperDoc__tray RipperDoc__tray--empty">
        <Icon name="box-open" />
        Лоток пуст. Положите имплант на стол, чтобы подготовить установку.
      </div>
    );
  }

  const risk = loaded.risk || 0;

  return (
    <div className="RipperDoc__tray">
      <div className="RipperDoc__trayInfo">
        <div className="RipperDoc__label">Лоток</div>
        <div className="RipperDoc__trayName">{loaded.name}</div>
        <div className="RipperDoc__note">
          {loaded.replaces
            ? `Заменит: ${loaded.replaces}`
            : `Слот: ${zoneName(loaded.zone)}`}
        </div>
      </div>
      <div className="RipperDoc__trayStat">
        <div className="RipperDoc__label">Нагрузка</div>
        <div className="RipperDoc__trayValue">-{loaded.cost}</div>
      </div>
      <div className="RipperDoc__trayStat">
        <div className="RipperDoc__label">Риск психоза</div>
        <div
          className={`RipperDoc__trayValue RipperDoc__trayValue--${riskTone(risk)}`}
        >
          {risk}%
        </div>
      </div>
      <div className="RipperDoc__trayButtons">
        <button
          type="button"
          className="RipperDoc__action"
          disabled={!patient || !hasAccess || !!busy}
          onClick={() => act('install')}
        >
          <Icon name="syringe" /> Установить
        </button>
        <button
          type="button"
          className="RipperDoc__action RipperDoc__action--red"
          disabled={!!busy}
          onClick={() => act('eject')}
        >
          <Icon name="hand-holding" /> Выдать
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
        <Icon name="user-slash" size={2} />
        <div>НЕТ ПАЦИЕНТА</div>
        <small>Уложите пациента на стол.</small>
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
      ])}
      onClick={() => setSelected(implant.uid)}
    >
      <span className="RipperDoc__rowName">{implant.name}</span>
      {!!implant.settings.length && (
        <Icon name="sliders" className="RipperDoc__rowIcon" />
      )}
      <span className="RipperDoc__cost">{implant.cost}</span>
    </button>
  );

  return (
    <div className="RipperDoc__list">
      {!implants.length && (
        <div className="RipperDoc__note">Кибернетика не обнаружена.</div>
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

export const RipperDoc = () => {
  const { data } = useBackend<Data>();
  const {
    patient,
    implants,
    loaded,
    maxCapacity,
    baseCapacity,
    chipBonus,
    psychoStage,
    busy,
    powered,
    hasAccess,
  } = data;
  const [selected, setSelected] = useState<string | null>(null);

  const selectedImplant =
    implants.find((implant) => implant.uid === selected) ||
    (loaded && loaded.uid === selected ? loaded : null);
  const chips = patient
    ? Math.max(0, Math.floor((patient.capacity - baseCapacity) / chipBonus))
    : 0;
  const maxChips = Math.ceil((maxCapacity - baseCapacity) / chipBonus);
  const overload = patient ? patient.load - patient.capacity : 0;

  return (
    <Window width={900} height={640} theme="ripperdoc">
      <Window.Content>
        <div className="RipperDoc">
          <div className="RipperDoc__header">
            <div className="RipperDoc__logo" data-text="RIPPERDOC">
              RIPPERDOC
            </div>
            <div className="RipperDoc__subtitle">
              {'нейрохирургический терминал // v2.077'}
            </div>
            <div className="RipperDoc__spacer" />
            <div
              className={classes([
                'RipperDoc__pill',
                !powered && 'RipperDoc__pill--bad',
              ])}
            >
              {powered ? 'питание' : 'нет питания'}
            </div>
            <div
              className={classes([
                'RipperDoc__pill',
                !hasAccess && 'RipperDoc__pill--bad',
              ])}
            >
              {hasAccess ? 'доступ открыт' : 'нужен доступ робототехники'}
            </div>
          </div>
          <div className="RipperDoc__patientBar">
            <Icon name="user" />
            <span className="RipperDoc__patientName">
              {patient ? patient.name : 'Стол пуст'}
            </span>
            {!!patient && (
              <span
                className={classes([
                  'RipperDoc__link',
                  !patient.neuroadapter && 'RipperDoc__link--off',
                ])}
              >
                {patient.neuroadapter
                  ? 'нейроадаптер: онлайн'
                  : 'нейроадаптер: нет'}
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
                  cost={loaded ? loaded.cost : 0}
                  freed={loaded?.freed || 0}
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
              <Psychosis
                stage={patient ? patient.psychosisStage : 0}
                total={psychoStage}
              />
            </div>
            <ImplantList selected={selected} setSelected={setSelected} />
            <div className="RipperDoc__column">
              <Details
                implant={selectedImplant}
                isLoaded={!!loaded && selected === loaded.uid}
              />
              {!!loaded && selected !== loaded.uid && (
                <button
                  type="button"
                  className="RipperDoc__action RipperDoc__action--ghost"
                  onClick={() => setSelected(loaded.uid)}
                >
                  <Icon name="sliders" /> Прошивка импланта в лотке
                </button>
              )}
            </div>
          </div>
          <Tray />
          {!!busy && (
            <div className="RipperDoc__busy">
              <div className="RipperDoc__busyText">ОПЕРАЦИЯ</div>
              <div className="RipperDoc__busyBar" />
            </div>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};
