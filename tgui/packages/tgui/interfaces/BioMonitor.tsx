import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import {
  Box,
  Chart,
  LabeledList,
  ProgressBar,
  Section,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

const WINDOW_ALPHA = 215;
const WINDOW_ALPHA_OPAQUE = 255;
const BLOOD_LEVEL_SAFE = 501;
const BLOOD_LEVEL_OKAY = 346;
const HEALTH_CHART_MAX = 100;
const PULSE_CHART_MAX = 260;
const WINDOW_WIDTH = 480;
const WINDOW_DEFAULT_HEIGHT = 680;
const WINDOW_MIN_HEIGHT = 240;
const WINDOW_RESIZE_THRESHOLD = 4;

type Disease = {
  form: string;
  name: string;
  stage: string;
  max_stages: string;
};

type Scan = {
  health: number;
  pulse: string;
  pulse_status: number;
  bodyTemperatureC: string;
  genes: number;
  damageLevels: {
    oxy: string;
    tox: string;
    burn: string;
    brute: string;
  };
  bloodData?: {
    blood_percent: number;
    blood_level: number;
    blood_type: string;
  };
  bleed?: BooleanLike;
  heartCondition?: string;
  liverCondition?: string;
  brainDamage: number | string;
  staminaStatus?: BooleanLike;
  cloneStatus?: number;
  brainWorms?: BooleanLike;
  fractureList: string[];
  infectedList: string[];
  bleedingList: string[];
  extraFacture?: BooleanLike;
  extraBleeding?: BooleanLike;
  diseases: Disease[];
  traumaList?: string[];
};

type Nutrition = {
  required: BooleanLike;
  value: number;
  max: number;
  state: string;
  severity: string;
};

type DietNote = {
  text: string;
  tone: string;
};

type Implant = {
  name: string;
  kind: string;
  status: string;
  failed: BooleanLike;
};

type Data = {
  name: string;
  species: string;
  scan: Scan;
  exotic_blood: BooleanLike;
  nutrition: Nutrition;
  diet: DietNote[];
  implants: Implant[];
  health_history: number[];
  pulse_history: number[];
  history_length: number;
};

type Problem = {
  text: string;
  critical?: boolean;
};

const getProblems = (scan: Scan): Problem[] => {
  const problems: Problem[] = [];
  const add = (text: string, critical = false) =>
    problems.push({ text, critical });

  if (scan.heartCondition === 'CRIT') {
    add('Остановка сердца', true);
  } else if (scan.heartCondition === 'NECROSIS') {
    add('Некроз сердца', true);
  } else if (scan.heartCondition === 'LESS') {
    add('Сердце не обнаружено', true);
  }

  if (scan.liverCondition === 'NECROSIS') {
    add('Острая печёночная недостаточность', true);
  } else if (scan.liverCondition === 'LESS') {
    add('Печень не обнаружена', true);
  }

  if (scan.brainDamage === 'LESS') {
    add('Мозг не обнаружен', true);
  } else if (Number(scan.brainDamage) > 60) {
    add('Серьёзное повреждение мозга', true);
  } else if (Number(scan.brainDamage) > 10) {
    add('Значительное повреждение мозга');
  }

  if (scan.brainWorms) {
    add('Отклонения в работе мозга', true);
  }
  for (const trauma of scan.traumaList ?? []) {
    add(`Психическая травма: ${trauma}`, true);
  }

  for (const bleeding of scan.bleedingList) {
    add(bleeding, true);
  }
  if (scan.bleed && !scan.bleedingList.length) {
    add('Кровотечение', true);
  }
  if (scan.extraBleeding) {
    add('Внутреннее кровотечение', true);
  }

  for (const limb of scan.fractureList) {
    add(`Перелом в ${limb}`);
  }
  if (scan.extraFacture && !scan.fractureList.length) {
    add('Обнаружены переломы');
  }
  for (const limb of scan.infectedList) {
    add(`Заражение в ${limb}`);
  }

  for (const disease of scan.diseases) {
    add(
      `${disease.form}: ${disease.name} (стадия ${disease.stage}/${disease.max_stages})`,
      true,
    );
  }

  if (scan.cloneStatus) {
    add('Клеточное повреждение', scan.cloneStatus > 30);
  }
  if (scan.genes < 85) {
    add('Генная нестабильность', scan.genes < 40);
  }
  if (scan.staminaStatus) {
    add('Истощение');
  }

  return problems;
};

const DamageCell = (props: { label: string; value: string; color: string }) => {
  const { label, value, color } = props;
  const damage = Math.round(Number(value));

  return (
    <div className="BioMonitor__damageCell">
      <Box className="BioMonitor__damageValue" color={damage ? color : ''}>
        {damage}
      </Box>
      <div className="BioMonitor__damageLabel">{label}</div>
    </div>
  );
};

const HistoryChart = (props: {
  title: string;
  unit: string;
  history: number[];
  capacity: number;
  maxValue: number;
  stroke: string;
  fill: string;
}) => {
  const { title, unit, history, capacity, maxValue, stroke, fill } = props;
  const points = history.map((value, index) => [
    capacity - history.length + index,
    Math.min(value, maxValue),
  ]);

  return (
    <div className="BioMonitor__chartBox">
      <div className="BioMonitor__chartHeader">
        <span>{title}</span>
        <span style={{ color: stroke }}>
          {history.length ? `${history[history.length - 1]} ${unit}` : '—'}
        </span>
      </div>
      <div className="BioMonitor__chart">
        {points.length > 1 ? (
          <Chart.Line
            fillPositionedParent
            data={points}
            rangeX={[0, capacity - 1]}
            rangeY={[0, maxValue]}
            strokeColor={stroke}
            strokeWidth={1.5}
            fillColor={fill}
          />
        ) : (
          <div className="BioMonitor__chartEmpty">Сбор данных...</div>
        )}
      </div>
    </div>
  );
};

const VitalsSection = (props: {
  scan: Scan;
  healthHistory: number[];
  pulseHistory: number[];
  historyLength: number;
}) => {
  const { scan, healthHistory, pulseHistory, historyLength } = props;

  return (
    <Section title="Жизненные показатели">
      <ProgressBar
        value={Math.max(scan.health, 0)}
        maxValue={100}
        ranges={{
          good: [70, Infinity],
          average: [30, 70],
          bad: [-Infinity, 30],
        }}
      >
        Здоровье: {Math.round(scan.health)}%
      </ProgressBar>
      <div className="BioMonitor__damage">
        <DamageCell
          label="Мех."
          value={scan.damageLevels.brute}
          color="#ff4040"
        />
        <DamageCell
          label="Терм."
          value={scan.damageLevels.burn}
          color="#ff8000"
        />
        <DamageCell
          label="Токс."
          value={scan.damageLevels.tox}
          color="#3cff8c"
        />
        <DamageCell
          label="Удушье"
          value={scan.damageLevels.oxy}
          color="#40a0ff"
        />
      </div>
      <Box mt={1}>
        <LabeledList>
          <LabeledList.Item label="Температура">
            {Number(scan.bodyTemperatureC).toFixed(1)} °C
          </LabeledList.Item>
          <LabeledList.Item label="Пульс">
            {scan.pulse_status ? `${scan.pulse} уд/мин` : 'отсутствует'}
          </LabeledList.Item>
        </LabeledList>
      </Box>
      <div className="BioMonitor__charts">
        <HistoryChart
          title="Здоровье"
          unit="%"
          history={healthHistory}
          capacity={historyLength}
          maxValue={HEALTH_CHART_MAX}
          stroke="#3CFF8C"
          fill="rgba(60, 255, 140, 0.15)"
        />
        {!!scan.pulse_status && (
          <HistoryChart
            title="Пульс"
            unit="уд/мин"
            history={pulseHistory}
            capacity={historyLength}
            maxValue={PULSE_CHART_MAX}
            stroke="#FF6E8A"
            fill="rgba(255, 110, 138, 0.15)"
          />
        )}
      </div>
      <div className="BioMonitor__chartCaption">За последнюю минуту</div>
    </Section>
  );
};

const BloodSection = (props: { scan: Scan; exotic: BooleanLike }) => {
  const { scan, exotic } = props;
  const blood = scan.bloodData;
  const title = exotic ? 'Биожидкость' : 'Кровь';

  if (!blood) {
    return <Section title={title}>Кровеносная система отсутствует.</Section>;
  }

  return (
    <Section title={title}>
      <ProgressBar
        value={blood.blood_percent}
        maxValue={100}
        color={
          blood.blood_level <= BLOOD_LEVEL_OKAY
            ? 'bad'
            : blood.blood_level <= BLOOD_LEVEL_SAFE
              ? 'average'
              : 'good'
        }
      >
        {blood.blood_percent}%
      </ProgressBar>
      <Box mt={1}>
        <LabeledList>
          <LabeledList.Item label="Тип">{blood.blood_type}</LabeledList.Item>
        </LabeledList>
      </Box>
    </Section>
  );
};

const NutritionSection = (props: {
  nutrition: Nutrition;
  diet: DietNote[];
}) => {
  const { nutrition, diet } = props;

  return (
    <Section title="Питание">
      {nutrition.required ? (
        <ProgressBar
          value={nutrition.value}
          maxValue={nutrition.max}
          color={nutrition.severity}
        >
          {nutrition.state}
        </ProgressBar>
      ) : (
        <Box>Организм не нуждается в пище.</Box>
      )}
      <Box mt={1}>
        {diet.map((note) => (
          <Box key={note.text} color={note.tone} mb={0.5}>
            {note.text}
          </Box>
        ))}
      </Box>
    </Section>
  );
};

const ProblemsSection = (props: { scan: Scan }) => {
  const problems = getProblems(props.scan);

  return (
    <Section title="Проблемы со здоровьем">
      {problems.length ? (
        problems.map((problem, index) => (
          <div
            className={`BioMonitor__problem ${problem.critical ? 'BioMonitor__problem--critical' : ''}`}
            key={index}
          >
            {problem.text}
          </div>
        ))
      ) : (
        <Box color="good">Отклонений не обнаружено.</Box>
      )}
    </Section>
  );
};

const ImplantsSection = (props: { implants: Implant[] }) => {
  const { implants } = props;

  return (
    <Section title="Импланты">
      {implants.map((implant, index) => (
        <div className="BioMonitor__row" key={index}>
          <div>
            <div>{implant.name}</div>
            <div className="BioMonitor__kind">{implant.kind}</div>
          </div>
          <span
            className={`BioMonitor__tag BioMonitor__tag--${implant.failed ? 'bad' : 'good'}`}
          >
            {implant.status}
          </span>
        </div>
      ))}
    </Section>
  );
};

export const BioMonitor = () => {
  const { data } = useBackend<Data>();
  const { name, species, scan, exotic_blood, nutrition, diet, implants } = data;

  const contentRef = useRef<HTMLDivElement>(null);
  const [windowHeight, setWindowHeight] = useState(WINDOW_DEFAULT_HEIGHT);

  useLayoutEffect(() => {
    const content = contentRef.current;
    const titleBar = document.querySelector('.TitleBar');
    if (!content || !titleBar) {
      return;
    }
    const bounds = content.getBoundingClientRect();
    const fitted = Math.max(
      Math.ceil(
        bounds.height +
          titleBar.getBoundingClientRect().height +
          bounds.left * 2,
      ),
      WINDOW_MIN_HEIGHT,
    );
    if (Math.abs(fitted - windowHeight) > WINDOW_RESIZE_THRESHOLD) {
      setWindowHeight(fitted);
    }
  });

  useEffect(() => {
    Byond.winset(Byond.windowId, { alpha: WINDOW_ALPHA });
    return () => {
      Byond.winset(Byond.windowId, { alpha: WINDOW_ALPHA_OPAQUE });
    };
  }, []);

  return (
    <Window width={WINDOW_WIDTH} height={windowHeight} theme="biomonitor">
      <Window.Content scrollable>
        {!!scan && (
          <div ref={contentRef}>
            <div className="BioMonitor__header">
              <div className="BioMonitor__species">{species}</div>
              <div className="BioMonitor__name">{name}</div>
            </div>
            <VitalsSection
              scan={scan}
              healthHistory={data.health_history}
              pulseHistory={data.pulse_history}
              historyLength={data.history_length}
            />
            <BloodSection scan={scan} exotic={exotic_blood} />
            <NutritionSection nutrition={nutrition} diet={diet} />
            <ProblemsSection scan={scan} />
            <ImplantsSection implants={implants} />
          </div>
        )}
      </Window.Content>
    </Window>
  );
};
