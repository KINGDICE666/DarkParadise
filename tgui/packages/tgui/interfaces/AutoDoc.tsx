import { type ReactNode, useState } from 'react';
import { Icon, Image } from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Occupant = {
  name: string;
  stat: number;
  health: number;
  maxHealth: number;
  brute: number;
  burn: number;
  tox: number;
  oxy: number;
  failureChance: number;
  organFailureChance: number;
  cyberCapacity: number;
  cyberLoad: number;
  hasNeuroadapter: boolean;
};

type Diagnosis = {
  id: string;
  name: string;
  organ: string;
  organUid: string;
  zone: string;
  invasive: boolean;
  risk: number;
  duration: number;
  cost: number;
  queued: boolean;
};

type Order = {
  uid: string;
  name: string;
  organ: string;
  paid: boolean;
  continuous: boolean;
  elapsed: number;
  duration: number;
  cost: number;
};

type OrganBase = {
  uid: string;
  name: string;
  damage: number;
  maxDamage: number;
  dead: boolean;
  queued: boolean;
  risk: number;
  duration: number;
  cost: number;
};

type PatientOrgan = OrganBase & {
  zone: string;
  cyberCost: number | null;
  canExtract: boolean;
  canLobotomy: boolean;
  lobotomyQueued: boolean;
};

type TrayOrgan = OrganBase & {
  cyberCost: number | null;
  cyberFreed: number;
  overCapacity: boolean;
  canInstall: boolean;
  needsModule: boolean;
  replaces: string | null;
};

type Module = {
  id: string;
  name: string;
  description: string;
  uid: string | null;
};

type AutoDocData = {
  bodyIcons: Record<string, string>;
  trayMax: number;
  cyberMax: number;
  cyberBase: number;
  cyberChipBonus: number;
  fuel: number;
  maxFuel: number;
  running: boolean;
  powered: boolean;
  autoEject: boolean;
  emagged: boolean;
  hasAccess: boolean;
  controlsLocked: boolean;
  locked: boolean;
  operating: boolean;
  mode: string;
  speedMod: number;
  costMod: number;
  occupant: Occupant | null;
  diagnosis: Diagnosis[];
  warnings: string[];
  queue: Order[];
  organs: PatientOrgan[];
  tray: TrayOrgan[];
  modules: Module[];
};

const TITLE = 'AutoDOCtor 3000';

const ZONE_NAMES: Record<string, string> = {
  head: 'Голова',
  chest: 'Грудь',
  groin: 'Живот',
  l_arm: 'Левая рука',
  r_arm: 'Правая рука',
  l_leg: 'Левая нога',
  r_leg: 'Правая нога',
};

const ZONE_ORDER = Object.keys(ZONE_NAMES);

const STAT_LABELS = [
  { label: 'В сознании', tone: 'good' },
  { label: 'Без сознания', tone: 'warn' },
  { label: 'Мёртв', tone: 'bad' },
];

const MODES = [
  { id: 'slow', label: 'Медленно', hint: 'Дольше на 50%, риск срыва ниже на 25%' },
  { id: 'medium', label: 'Средне', hint: 'Обычная скорость и обычный риск' },
  { id: 'fast', label: 'Быстро', hint: 'Быстрее на 40%, риск срыва выше на 25%' },
];

const TABS = [
  { id: 'diagnosis', label: 'Диагностика', icon: 'stethoscope' },
  { id: 'organs', label: 'Органы', icon: 'heart-pulse' },
  { id: 'cyber', label: 'Кибер', icon: 'microchip' },
  { id: 'modules', label: 'Модули', icon: 'floppy-disk' },
];

const CYBER_SEGMENT = 10;

const formatTime = (seconds: number) => {
  const total = Math.max(0, Math.ceil(seconds));
  if (total < 60) {
    return `${total} с`;
  }
  const rest = total % 60;
  return `${Math.floor(total / 60)} м${rest ? ` ${rest} с` : ''}`;
};

const formatUnits = (units: number) => `${Math.ceil(units * 10) / 10} ед.`;

const riskTone = (risk: number) => {
  if (risk >= 50) {
    return 'bad';
  }
  return risk > 0 ? 'warn' : 'good';
};

const RiskTag = (props: { risk: number }) => (
  <span
    className={`AutoDoc__riskTag AutoDoc__riskTag--${riskTone(props.risk)}`}
    title="Шанс срыва"
  >
    {props.risk}%
  </span>
);

const Stats = (props: { duration: number; cost: number }) => (
  <div className="AutoDoc__rowStats">
    <span>
      <Icon name="clock" /> {formatTime(props.duration)}
    </span>
    <span>
      <Icon name="droplet" /> {formatUnits(props.cost)}
    </span>
  </div>
);

const PushButton = (props: {
  tone: 'green' | 'red';
  icon: string;
  title: string;
  disabled?: boolean;
  onClick: () => void;
}) => (
  <button
    type="button"
    className={`AutoDoc__push AutoDoc__push--${props.tone}`}
    disabled={props.disabled}
    title={props.title}
    onClick={props.onClick}
  >
    <span className="AutoDoc__pushCap">
      <Icon name={props.icon} />
    </span>
  </button>
);

const ButtonBox = (props: { children: ReactNode }) => (
  <div className="AutoDoc__box">{props.children}</div>
);

const Header = () => {
  const { act, data } = useBackend<AutoDocData>();
  const {
    running,
    powered,
    occupant,
    queue,
    autoEject,
    emagged,
    hasAccess,
    controlsLocked,
    locked,
    operating,
    mode,
  } = data;

  let status: string | null = null;
  let tone = 'idle';
  if (!powered) {
    status = 'Нет питания';
    tone = 'bad';
  } else if (!hasAccess) {
    status = 'Нужен медицинский доступ';
    tone = 'bad';
  } else if (!running && occupant && queue.length) {
    status = 'Пауза';
    tone = 'warn';
  } else if (!running && !occupant) {
    status = 'Ожидание пациента';
  }

  return (
    <div className="AutoDoc__header">
      <div className="AutoDoc__title">
        <Icon name="kit-medical" />
        {TITLE}
      </div>
      {!!status && (
        <div className={`AutoDoc__status AutoDoc__status--${tone}`}>
          <span className="AutoDoc__statusDot" />
          {status}
        </div>
      )}
      <div className="AutoDoc__spacer" />
      <div className="AutoDoc__modes">
        {MODES.map((entry) => (
          <button
            key={entry.id}
            type="button"
            title={running ? 'Нельзя менять режим во время работы' : entry.hint}
            disabled={!hasAccess || running}
            className={classes([
              'AutoDoc__mode',
              mode === entry.id && 'AutoDoc__mode--active',
            ])}
            onClick={() => act('set_mode', { mode: entry.id })}
          >
            {entry.label}
          </button>
        ))}
        {!!emagged && (
          <button
            type="button"
            title="Быстрее втрое. Безопасность отключена"
            disabled={!hasAccess || running}
            className={classes([
              'AutoDoc__mode',
              'AutoDoc__mode--overdrive',
              mode === 'overdrive' && 'AutoDoc__mode--active',
            ])}
            onClick={() => act('set_mode', { mode: 'overdrive' })}
          >
            ОВЕРДРАЙВ
          </button>
        )}
      </div>
      <button
        type="button"
        className={classes([
          'AutoDoc__button',
          autoEject && 'AutoDoc__button--on',
        ])}
        disabled={controlsLocked}
        title="Извлекать пациента после завершения программы"
        onClick={() => act('toggle_auto_eject')}
      >
        <Icon name="right-from-bracket" />
        Автоизвлечение
      </button>
      <button
        type="button"
        className="AutoDoc__button AutoDoc__button--danger"
        disabled={!occupant || locked || (operating && !hasAccess)}
        title={
          locked
            ? 'Крышка заблокирована'
            : operating && !hasAccess
              ? 'Во время операции нужен медицинский доступ'
              : 'Прерывание операции травмирует пациента'
        }
        onClick={() => act('eject')}
      >
        <Icon name={locked ? 'lock' : 'eject'} />
        Извлечь
      </button>
    </div>
  );
};

const Meter = (props: {
  label: string;
  value: number;
  tone: string;
  max?: number;
}) => {
  const { label, value, tone, max = 100 } = props;
  return (
    <div className="AutoDoc__meter">
      <div className="AutoDoc__meterLabel">
        <span>{label}</span>
        <b>{Math.round(value)}</b>
      </div>
      <div className="AutoDoc__track">
        <div
          className={`AutoDoc__fill AutoDoc__fill--${tone}`}
          style={{
            width: `${Math.min(100, Math.max(0, (value / max) * 100))}%`,
          }}
        />
      </div>
    </div>
  );
};

const BodyMap = (props: {
  activeZone: string | null;
  setActiveZone: (zone: string | null) => void;
}) => {
  const { data } = useBackend<AutoDocData>();
  const { bodyIcons, diagnosis } = data;
  const { activeZone, setActiveZone } = props;
  const hurtZones = new Set(diagnosis.map((entry) => entry.zone));

  return (
    <div className="AutoDoc__bodyMap">
      <div className="AutoDoc__figure">
        <Image
          className="AutoDoc__layer"
          src={`data:image/png;base64,${bodyIcons.human}`}
          fixBlur
        />
        {ZONE_ORDER.filter((zone) => hurtZones.has(zone)).map((zone) => (
          <Image
            key={zone}
            className={classes([
              'AutoDoc__layer',
              'AutoDoc__layer--hurt',
              activeZone && activeZone !== zone && 'AutoDoc__layer--dim',
            ])}
            src={`data:image/png;base64,${bodyIcons[zone]}`}
            fixBlur
          />
        ))}
      </div>
      <div className="AutoDoc__zones">
        {ZONE_ORDER.map((zone) => (
          <button
            key={zone}
            type="button"
            disabled={!hurtZones.has(zone)}
            className={classes([
              'AutoDoc__zone',
              activeZone === zone && 'AutoDoc__zone--active',
              hurtZones.has(zone) && 'AutoDoc__zone--hurt',
            ])}
            onClick={() => setActiveZone(activeZone === zone ? null : zone)}
          >
            {ZONE_NAMES[zone]}
          </button>
        ))}
      </div>
    </div>
  );
};

const PatientPanel = (props: {
  activeZone: string | null;
  setActiveZone: (zone: string | null) => void;
}) => {
  const { data } = useBackend<AutoDocData>();
  const { occupant, warnings } = data;
  if (!occupant) {
    return (
      <div className="AutoDoc__panel AutoDoc__empty">
        <Icon name="bed-pulse" size={3} />
        <div>Пациента нет</div>
        <small>
          Перетащите гуманоида на автодок или закиньте его захватом.
        </small>
      </div>
    );
  }

  const stat = STAT_LABELS[occupant.stat] || STAT_LABELS[2];
  const healthPercent = (occupant.health / occupant.maxHealth) * 100;

  return (
    <div className="AutoDoc__panel AutoDoc__patient">
      <div className="AutoDoc__patientHead">
        <div className="AutoDoc__patientName">{occupant.name}</div>
        <div className={`AutoDoc__pill AutoDoc__pill--${stat.tone}`}>
          {stat.label}
        </div>
      </div>
      <BodyMap {...props} />
      <Meter
        label="Здоровье"
        value={occupant.health}
        max={occupant.maxHealth}
        tone={healthPercent > 50 ? 'good' : healthPercent > 0 ? 'warn' : 'bad'}
      />
      <div className="AutoDoc__meters">
        <Meter label="Физические" value={occupant.brute} tone="brute" />
        <Meter label="Ожоги" value={occupant.burn} tone="burn" />
        <Meter label="Токсины" value={occupant.tox} tone="tox" />
        <Meter label="Удушье" value={occupant.oxy} tone="oxy" />
      </div>
      <div className="AutoDoc__risk">
        <div>
          <Icon name="scissors" />
          <span>Срыв операции</span>
          <RiskTag risk={occupant.failureChance} />
        </div>
        <div>
          <Icon name="heart-pulse" />
          <span>Срыв лечения органа</span>
          <RiskTag risk={occupant.organFailureChance} />
        </div>
      </div>
      {!!warnings.length && (
        <div className="AutoDoc__warnings">
          <div className="AutoDoc__warningsTitle">
            Вне возможностей автодока
          </div>
          {warnings.map((warning) => (
            <div key={warning} className="AutoDoc__warning">
              <Icon name="user-doctor" />
              {warning}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const Tank = () => {
  const { data } = useBackend<AutoDocData>();
  const { fuel, maxFuel, speedMod, costMod } = data;
  const percent = maxFuel ? (fuel / maxFuel) * 100 : 0;
  return (
    <div className="AutoDoc__panel AutoDoc__tank">
      <Icon name="droplet" className="AutoDoc__tankIcon" />
      <div className="AutoDoc__tankBody">
        <div className="AutoDoc__meterLabel">
          <span>Бак синт-плоти</span>
          <b>
            {Math.round(fuel * 10) / 10} / {maxFuel} ед.
          </b>
        </div>
        <div className="AutoDoc__track AutoDoc__track--tall">
          <div
            className={classes([
              'AutoDoc__fill',
              percent < 20 ? 'AutoDoc__fill--bad' : 'AutoDoc__fill--flesh',
            ])}
            style={{ width: `${percent}%` }}
          />
        </div>
      </div>
      <div className="AutoDoc__tankStats">
        <span title="Зависит от манипуляторов и режима">
          <Icon name="gauge-high" /> ×{speedMod}
        </span>
        <span title="Зависит от микролазера">
          <Icon name="flask" /> ×{costMod}
        </span>
      </div>
    </div>
  );
};

const DiagnosisTab = (props: { activeZone: string | null }) => {
  const { act, data } = useBackend<AutoDocData>();
  const { diagnosis, occupant, controlsLocked } = data;
  const { activeZone } = props;
  const zones = ZONE_ORDER.concat(
    diagnosis
      .map((entry) => entry.zone)
      .filter((zone, index, all) => {
        return !ZONE_ORDER.includes(zone) && all.indexOf(zone) === index;
      }),
  ).filter((zone) => !activeZone || zone === activeZone);

  return (
    <>
      {!diagnosis.length && (
        <div className="AutoDoc__hint">
          <Icon name={occupant ? 'circle-check' : 'magnifying-glass'} />
          {occupant
            ? 'Автодоку нечего лечить.'
            : 'Диагностика начнётся, когда пациент окажется внутри.'}
        </div>
      )}
      {zones.map((zone) => {
        const entries = diagnosis.filter((entry) => entry.zone === zone);
        if (!entries.length) {
          return null;
        }
        return (
          <div key={zone} className="AutoDoc__group">
            <div className="AutoDoc__groupTitle">
              {ZONE_NAMES[zone] || 'Прочее'}
            </div>
            {entries.map((entry) => (
              <div
                key={`${entry.id}-${entry.organUid}`}
                className={classes([
                  'AutoDoc__row',
                  entry.queued && 'AutoDoc__row--queued',
                ])}
              >
                <div className="AutoDoc__rowText">
                  <div className="AutoDoc__rowName">{entry.name}</div>
                  <div className="AutoDoc__rowOrgan">{entry.organ}</div>
                </div>
                {entry.risk > 0 && <RiskTag risk={entry.risk} />}
                <Stats duration={entry.duration} cost={entry.cost} />
                <ButtonBox>
                  <PushButton
                    tone="green"
                    icon={entry.queued ? 'check' : 'plus'}
                    disabled={entry.queued || controlsLocked}
                    title={entry.queued ? 'Уже в очереди' : 'В очередь'}
                    onClick={() =>
                      act('add_order', {
                        id: entry.id,
                        organUid: entry.organUid,
                      })
                    }
                  />
                </ButtonBox>
              </div>
            ))}
          </div>
        );
      })}
    </>
  );
};

const OrganHealth = (props: { organ: OrganBase }) => {
  const { organ } = props;
  if (organ.dead) {
    return <div className="AutoDoc__organDead">некроз</div>;
  }
  return (
    <div className="AutoDoc__track AutoDoc__organHealth">
      <div
        className={`AutoDoc__fill AutoDoc__fill--${organ.damage ? 'warn' : 'good'}`}
        style={{
          width: `${100 - (organ.damage / (organ.maxDamage || 1)) * 100}%`,
        }}
      />
    </div>
  );
};

const OrgansTab = () => {
  const { act, data } = useBackend<AutoDocData>();
  const { organs, tray, trayMax, occupant, controlsLocked, hasAccess } = data;
  return (
    <>
      <div className="AutoDoc__group">
        <div className="AutoDoc__groupTitle">
          Лоток {tray.length} / {trayMax}
        </div>
        {!tray.length && (
          <div className="AutoDoc__note">
            Положите орган кликом по автодоку. При установке старый орган
            перейдёт в лоток.
          </div>
        )}
        {tray.map((organ) => (
          <div key={organ.uid} className="AutoDoc__row">
            <div className="AutoDoc__rowText">
              <div className="AutoDoc__rowName">{organ.name}</div>
              <div className="AutoDoc__rowOrgan">
                {organ.needsModule
                  ? 'нужен модуль установки имплантов'
                  : organ.overCapacity
                    ? 'не хватает киберсовместимости'
                    : organ.replaces
                      ? `заменит: ${organ.replaces}`
                      : 'свободное место'}
              </div>
              <OrganHealth organ={organ} />
            </div>
            <RiskTag risk={organ.risk} />
            <Stats duration={organ.duration} cost={organ.cost} />
            <ButtonBox>
              <PushButton
                tone="green"
                icon={organ.queued ? 'check' : 'arrow-right-to-bracket'}
                disabled={!organ.canInstall || organ.queued || controlsLocked}
                title={
                  organ.canInstall
                    ? 'Установить пациенту'
                    : 'Нельзя установить этому пациенту'
                }
                onClick={() => act('install_organ', { uid: organ.uid })}
              />
              <PushButton
                tone="red"
                icon="hand-holding"
                disabled={!hasAccess}
                title="Выдать из лотка"
                onClick={() => act('tray_eject', { uid: organ.uid })}
              />
            </ButtonBox>
          </div>
        ))}
      </div>
      <div className="AutoDoc__group">
        <div className="AutoDoc__groupTitle">В пациенте</div>
        {!occupant && <div className="AutoDoc__note">Пациента нет.</div>}
        {organs.map((organ) => (
          <div key={organ.uid} className="AutoDoc__row">
            <div className="AutoDoc__rowText">
              <div className="AutoDoc__rowName">{organ.name}</div>
              <div className="AutoDoc__rowOrgan">
                {ZONE_NAMES[organ.zone] || 'Прочее'}
              </div>
              <OrganHealth organ={organ} />
            </div>
            <RiskTag risk={organ.risk} />
            <Stats duration={organ.duration} cost={organ.cost} />
            <ButtonBox>
              {!!organ.canLobotomy && (
                <PushButton
                  tone="red"
                  icon={organ.lobotomyQueued ? 'check' : 'brain'}
                  disabled={organ.lobotomyQueued || controlsLocked}
                  title="Лоботомия: снимает стойкие травмы, но часто оставляет новые"
                  onClick={() => act('lobotomy', { uid: organ.uid })}
                />
              )}
              <PushButton
                tone="red"
                icon={organ.queued ? 'check' : 'arrow-right-from-bracket'}
                disabled={!organ.canExtract || organ.queued || controlsLocked}
                title={
                  organ.canExtract
                    ? 'Извлечь в лоток'
                    : 'Этот орган автодок не извлекает'
                }
                onClick={() => act('extract_organ', { uid: organ.uid })}
              />
            </ButtonBox>
          </div>
        ))}
      </div>
    </>
  );
};

const ModulesTab = () => {
  const { act, data } = useBackend<AutoDocData>();
  const { modules, hasAccess } = data;
  return (
    <>
      <div className="AutoDoc__note">
        Модули открывают новые операции. Диски печатаются в протолате и
        вставляются кликом по автодоку.
      </div>
      {modules.map((module) => (
        <div key={module.id} className="AutoDoc__row">
          <span
            className={classes([
              'AutoDoc__led',
              !!module.uid && 'AutoDoc__led--on',
            ])}
          />
          <div className="AutoDoc__rowText">
            <div className="AutoDoc__rowName">{module.name}</div>
            <div className="AutoDoc__rowOrgan">{module.description}</div>
          </div>
          <ButtonBox>
            <PushButton
              tone="red"
              icon="eject"
              disabled={!module.uid || !hasAccess}
              title={module.uid ? 'Извлечь диск' : 'Диск не вставлен'}
              onClick={() => act('eject_module', { uid: module.uid })}
            />
          </ButtonBox>
        </div>
      ))}
    </>
  );
};

type CyberPreview = {
  cost: number;
  freed: number;
};

const segmentState = (
  from: number,
  capacity: number,
  load: number,
  preview: CyberPreview | null,
) => {
  const baseLoad = preview ? load - preview.freed : load;
  if (from < baseLoad) {
    return 'used';
  }
  if (preview && from < baseLoad + preview.cost) {
    return from < capacity ? 'preview' : 'overload';
  }
  return from < capacity ? 'free' : 'locked';
};

const CapacityGauge = (props: {
  capacity: number;
  load: number;
  max: number;
  preview: CyberPreview | null;
}) => {
  const { capacity, load, max, preview } = props;
  const segments = Math.ceil(max / CYBER_SEGMENT);
  const free = capacity - load;
  const delta = preview ? preview.freed - preview.cost : 0;
  const top = load - delta;
  const position = (value: number) =>
    `${(Math.min(Math.max(value, 0), max) / max) * 100}%`;

  return (
    <div className="AutoDoc__gauge">
      <div className="AutoDoc__gaugeIcon">
        <Icon name="microchip" />
      </div>
      <div className="AutoDoc__gaugeBody">
        <div className="AutoDoc__gaugeBar">
          {Array.from({ length: segments }, (_, index) => {
            const from = (segments - 1 - index) * CYBER_SEGMENT;
            const state = segmentState(from, capacity, load, preview);
            return (
              <div
                key={index}
                className={`AutoDoc__segment AutoDoc__segment--${state}`}
              />
            );
          })}
        </div>
        <div
          className="AutoDoc__gaugeCap"
          style={{ bottom: position(capacity) }}
        >
          {capacity}
        </div>
        <div
          className="AutoDoc__gaugeFree"
          style={{ bottom: position(top) }}
        >
          <span
            className={classes([
              'AutoDoc__gaugeValue',
              free + delta < 0 && 'AutoDoc__gaugeValue--bad',
            ])}
          >
            {free + delta}
          </span>
          {!!preview && (
            <span
              className={classes([
                'AutoDoc__gaugeDelta',
                delta > 0 && 'AutoDoc__gaugeDelta--plus',
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

const CyberTab = () => {
  const { act, data } = useBackend<AutoDocData>();
  const {
    occupant,
    organs,
    tray,
    cyberMax,
    cyberBase,
    cyberChipBonus,
    controlsLocked,
  } = data;
  const [preview, setPreview] = useState<CyberPreview | null>(null);

  if (!occupant) {
    return (
      <div className="AutoDoc__cyber AutoDoc__cyber--empty">
        <Icon name="microchip" size={2} />
        <div>НЕТ ПОДКЛЮЧЕНИЯ</div>
        <small>Поместите пациента в капсулу для чтения нейроадаптера.</small>
      </div>
    );
  }

  const { cyberCapacity, cyberLoad, hasNeuroadapter } = occupant;
  const implants = organs.filter((organ) => organ.cyberCost !== null);
  const trayImplants = tray.filter((organ) => organ.cyberCost !== null);
  const chips = Math.max(
    0,
    Math.floor((cyberCapacity - cyberBase) / cyberChipBonus),
  );
  const maxChips = Math.ceil((cyberMax - cyberBase) / cyberChipBonus);

  return (
    <div className="AutoDoc__cyber">
      <div className="AutoDoc__cyberHead">
        <span className="AutoDoc__cyberTitle">Киберсовместимость</span>
        <span
          className={classes([
            'AutoDoc__cyberLink',
            !hasNeuroadapter && 'AutoDoc__cyberLink--off',
          ])}
        >
          {hasNeuroadapter ? 'нейроадаптер: онлайн' : 'нейроадаптер: нет'}
        </span>
      </div>
      <div className="AutoDoc__cyberBody">
        <CapacityGauge
          capacity={cyberCapacity}
          load={cyberLoad}
          max={cyberMax}
          preview={preview}
        />
        <div className="AutoDoc__cyberInfo">
          <div className="AutoDoc__cyberStats">
            <div>
              <small>Ёмкость</small>
              <b>
                {cyberCapacity}
                <i>/{cyberMax}</i>
              </b>
            </div>
            <div>
              <small>Нагрузка</small>
              <b>{cyberLoad}</b>
            </div>
            <div>
              <small>Свободно</small>
              <b
                className={
                  cyberCapacity < cyberLoad ? 'AutoDoc__cyberBad' : undefined
                }
              >
                {cyberCapacity - cyberLoad}
              </b>
            </div>
            <div>
              <small>Чипы</small>
              <b>
                {chips}
                <i>/{maxChips}</i>
              </b>
            </div>
          </div>
          <div className="AutoDoc__cyberGroup">Установлено</div>
          {!implants.length && (
            <div className="AutoDoc__cyberNote">Импланты не обнаружены.</div>
          )}
          {implants.map((organ) => (
            <div key={organ.uid} className="AutoDoc__cyberRow">
              <div className="AutoDoc__cyberName">
                {organ.name}
                <small>{ZONE_NAMES[organ.zone] || 'Прочее'}</small>
              </div>
              <span className="AutoDoc__cyberCost">{organ.cyberCost}</span>
              <button
                type="button"
                className="AutoDoc__cyberButton AutoDoc__cyberButton--red"
                disabled={!organ.canExtract || organ.queued || controlsLocked}
                title={organ.queued ? 'Уже в очереди' : 'Извлечь в лоток'}
                onClick={() => act('extract_organ', { uid: organ.uid })}
              >
                <Icon name={organ.queued ? 'check' : 'eject'} />
              </button>
            </div>
          ))}
          <div className="AutoDoc__cyberGroup">В лотке</div>
          {!trayImplants.length && (
            <div className="AutoDoc__cyberNote">
              Положите имплант в лоток, чтобы оценить нагрузку.
            </div>
          )}
          {trayImplants.map((organ) => (
            <div
              key={organ.uid}
              className={classes([
                'AutoDoc__cyberRow',
                organ.overCapacity && 'AutoDoc__cyberRow--bad',
              ])}
              onMouseEnter={() =>
                setPreview({
                  cost: organ.cyberCost || 0,
                  freed: organ.cyberFreed,
                })
              }
              onMouseLeave={() => setPreview(null)}
            >
              <div className="AutoDoc__cyberName">
                {organ.name}
                <small>
                  {organ.overCapacity
                    ? 'не хватает совместимости'
                    : organ.replaces
                      ? `заменит: ${organ.replaces}`
                      : 'свободный слот'}
                </small>
              </div>
              <span className="AutoDoc__cyberCost">-{organ.cyberCost}</span>
              <button
                type="button"
                className="AutoDoc__cyberButton"
                disabled={!organ.canInstall || organ.queued || controlsLocked}
                title={
                  organ.canInstall
                    ? 'Установить пациенту'
                    : 'Нельзя установить этому пациенту'
                }
                onClick={() => act('install_organ', { uid: organ.uid })}
              >
                <Icon
                  name={organ.queued ? 'check' : 'arrow-right-to-bracket'}
                />
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const MainPanel = (props: { activeZone: string | null }) => {
  const { act, data } = useBackend<AutoDocData>();
  const { diagnosis, controlsLocked } = data;
  const [tab, setTab] = useState('diagnosis');
  const pending = diagnosis.filter((entry) => !entry.queued);

  return (
    <div
      className={classes([
        'AutoDoc__panel',
        'AutoDoc__main',
        tab === 'cyber' && 'AutoDoc__main--tall',
      ])}
    >
      <div className="AutoDoc__panelTitle AutoDoc__panelTitle--tabs">
        {TABS.map((entry) => (
          <button
            key={entry.id}
            type="button"
            className={classes([
              'AutoDoc__tab',
              tab === entry.id && 'AutoDoc__tab--active',
            ])}
            onClick={() => setTab(entry.id)}
          >
            <Icon name={entry.icon} />
            {entry.label}
          </button>
        ))}
        <div className="AutoDoc__spacer" />
        {tab === 'diagnosis' && (
          <button
            type="button"
            className="AutoDoc__button AutoDoc__button--accent"
            disabled={!pending.length || controlsLocked}
            onClick={() => act('add_all')}
          >
            <Icon name="layer-group" />
            Лечить всё
          </button>
        )}
      </div>
      <div className="AutoDoc__scroll">
        {tab === 'diagnosis' && <DiagnosisTab activeZone={props.activeZone} />}
        {tab === 'organs' && <OrgansTab />}
        {tab === 'modules' && <ModulesTab />}
        {tab === 'cyber' && <CyberTab />}
      </div>
    </div>
  );
};

const QueuePanel = () => {
  const { act, data } = useBackend<AutoDocData>();
  const { queue, running, fuel, powered, occupant, controlsLocked } = data;
  const totalCost = queue.reduce(
    (sum, order) => sum + (order.paid ? 0 : order.cost),
    0,
  );
  const totalTime = queue.reduce(
    (sum, order) => sum + order.duration - (order.paid ? order.elapsed : 0),
    0,
  );
  const notEnough = totalCost > fuel;

  return (
    <div className="AutoDoc__panel AutoDoc__queue">
      <div className="AutoDoc__panelTitle">
        <Icon name="list-check" />
        Очередь
        <div className="AutoDoc__spacer" />
        <ButtonBox>
          <PushButton
            tone="green"
            icon="play"
            disabled={
              running || !queue.length || !occupant || !powered || controlsLocked
            }
            title="Запуск"
            onClick={() => act('start')}
          />
          <PushButton
            tone="red"
            icon="pause"
            disabled={!running || controlsLocked}
            title="Пауза"
            onClick={() => act('pause')}
          />
        </ButtonBox>
        <ButtonBox>
          <PushButton
            tone="red"
            icon="trash"
            disabled={!queue.length || controlsLocked}
            title="Очистить очередь. Прерывание операции травмирует пациента"
            onClick={() => act('clear')}
          />
        </ButtonBox>
      </div>
      <div className="AutoDoc__scroll">
        {!queue.length && (
          <div className="AutoDoc__hint">
            <Icon name="list-ol" />
            Очередь пуста. Выберите процедуры.
          </div>
        )}
        {queue.map((order, index) => {
          const percent = order.paid
            ? Math.min(100, (order.elapsed / (order.duration || 1)) * 100)
            : 0;
          const active = index === 0 && running;
          return (
            <div
              key={order.uid}
              className={classes([
                'AutoDoc__order',
                active && 'AutoDoc__order--active',
              ])}
            >
              <div className="AutoDoc__orderIndex">{index + 1}</div>
              <div className="AutoDoc__rowText">
                <div className="AutoDoc__rowName">{order.name}</div>
                <div className="AutoDoc__rowOrgan">{order.organ}</div>
                {!!order.paid && (
                  <div className="AutoDoc__track">
                    <div
                      className="AutoDoc__fill AutoDoc__fill--good"
                      style={{ width: `${percent}%` }}
                    />
                  </div>
                )}
              </div>
              <div className="AutoDoc__rowStats">
                <span>
                  <Icon name="clock" />{' '}
                  {formatTime(
                    order.duration - (order.paid ? order.elapsed : 0),
                  )}
                </span>
                <span>
                  <Icon name="droplet" />{' '}
                  {order.paid ? 'оплачено' : formatUnits(order.cost)}
                </span>
              </div>
              <ButtonBox>
                <PushButton
                  tone="green"
                  icon="arrow-up"
                  disabled={index === 0 || order.paid || controlsLocked}
                  title="Поднять выше"
                  onClick={() => act('raise_order', { uid: order.uid })}
                />
                <PushButton
                  tone="red"
                  icon="xmark"
                  disabled={controlsLocked}
                  title={
                    order.paid ? 'Прервать: травмирует пациента' : 'Убрать'
                  }
                  onClick={() => act('remove_order', { uid: order.uid })}
                />
              </ButtonBox>
            </div>
          );
        })}
      </div>
      <div
        className={classes([
          'AutoDoc__totals',
          notEnough && 'AutoDoc__totals--bad',
        ])}
      >
        <span>
          <Icon name="clock" /> Всего: {formatTime(totalTime)}
        </span>
        <span>
          <Icon name="droplet" /> Нужно: {formatUnits(totalCost)}
          {notEnough ? ' — в баке не хватит!' : ''}
        </span>
      </div>
    </div>
  );
};

export const AutoDoc = () => {
  const { data } = useBackend<AutoDocData>();
  const [activeZone, setActiveZone] = useState<string | null>(null);
  return (
    <Window width={960} height={680}>
      <Window.Content>
        <div
          className={classes(['AutoDoc', data.emagged && 'AutoDoc--emagged'])}
        >
          <Header />
          <div className="AutoDoc__layout">
            <div className="AutoDoc__column AutoDoc__column--left">
              <PatientPanel
                activeZone={activeZone}
                setActiveZone={setActiveZone}
              />
              <Tank />
            </div>
            <div className="AutoDoc__column">
              <MainPanel activeZone={activeZone} />
              <QueuePanel />
            </div>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
