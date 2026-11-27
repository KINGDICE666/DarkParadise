export const RAD_COLORS = {
  good: '#48ff78',
  warn: '#ffba40',
  bad: '#ff4638',
  muted: '#6e8f7d',
  edge: '#1d2f27',
};

export const STAGE_NAMES = [
  'Норма',
  'Лёгкая',
  'Средняя',
  'Тяжёлая',
  'Смертельная',
];

export const STAGE_DOSES = [0, 100, 300, 600, 1000];

/** Границы цветовых зон шкалы, в радах в минуту */
const DANGER_RATE_ELEVATED = 10;
const DANGER_RATE_HIGH = 100;

export const dangerStatus = (rate: number) =>
  rate >= DANGER_RATE_HIGH ? 2 : rate >= DANGER_RATE_ELEVATED ? 1 : 0;

export const STAGE_COLORS = [
  '#48ff78',
  '#d2f050',
  '#ffba40',
  '#ff7832',
  '#ff4638',
];

export const statusClass = (status: number) =>
  status >= 2 ? 'RadScope__bad' : status === 1 ? 'RadScope__warn' : 'RadScope__good';

const GAUGE_START_ANGLE = -120;
const GAUGE_SWEEP = 240;

const polar = (cx: number, cy: number, radius: number, angle: number) => {
  const radians = ((angle - 90) * Math.PI) / 180;
  return [cx + radius * Math.cos(radians), cy + radius * Math.sin(radians)];
};

const arcPath = (
  cx: number,
  cy: number,
  radius: number,
  startAngle: number,
  endAngle: number,
) => {
  const [startX, startY] = polar(cx, cy, radius, startAngle);
  const [endX, endY] = polar(cx, cy, radius, endAngle);
  const largeArc = endAngle - startAngle > 180 ? 1 : 0;
  return `M ${startX} ${startY} A ${radius} ${radius} 0 ${largeArc} 1 ${endX} ${endY}`;
};

type GaugeProps = {
  value: number;
  /** Отметка на шкале, 0 её скрывает */
  mark: number;
  maximum: number;
};

/** Шкала логарифмическая, чтобы и фон, и расплавление помещались на один циферблат */
export const RadGauge = (props: GaugeProps) => {
  const { value, mark, maximum } = props;
  const toAngle = (rate: number) => {
    const share = Math.log10(1 + Math.max(rate, 0)) / Math.log10(1 + maximum);
    return GAUGE_START_ANGLE + Math.min(share, 1) * GAUGE_SWEEP;
  };
  const warningAngle = toAngle(DANGER_RATE_ELEVATED);
  const alarmAngle = toAngle(DANGER_RATE_HIGH);
  const [markInnerX, markInnerY] = polar(100, 100, 77, toAngle(mark));
  const [markOuterX, markOuterY] = polar(100, 100, 92, toAngle(mark));
  const needleAngle = toAngle(value);
  const [needleX, needleY] = polar(100, 100, 74, needleAngle);
  const ticks = [1, 10, 100, 1000].filter((tick) => tick <= maximum);

  return (
    <svg viewBox="0 0 200 165" width="100%" height="100%">
      <path
        d={arcPath(100, 100, 84, GAUGE_START_ANGLE, warningAngle)}
        fill="none"
        stroke={RAD_COLORS.good}
        strokeWidth="9"
      />
      <path
        d={arcPath(100, 100, 84, warningAngle, alarmAngle)}
        fill="none"
        stroke={RAD_COLORS.warn}
        strokeWidth="9"
      />
      <path
        d={arcPath(100, 100, 84, alarmAngle, GAUGE_START_ANGLE + GAUGE_SWEEP)}
        fill="none"
        stroke={RAD_COLORS.bad}
        strokeWidth="9"
      />
      {ticks.map((tick) => {
        const angle = toAngle(tick);
        const [x1, y1] = polar(100, 100, 77, angle);
        const [x2, y2] = polar(100, 100, 70, angle);
        const [textX, textY] = polar(100, 100, 59, angle);
        return (
          <g key={tick}>
            <line
              x1={x1}
              y1={y1}
              x2={x2}
              y2={y2}
              stroke={RAD_COLORS.muted}
              strokeWidth="1.5"
            />
            <text
              x={textX}
              y={textY + 3}
              fill={RAD_COLORS.muted}
              fontSize="9"
              textAnchor="middle"
            >
              {tick}
            </text>
          </g>
        );
      })}
      {mark > 0 && (
        <line
          x1={markInnerX}
          y1={markInnerY}
          x2={markOuterX}
          y2={markOuterY}
          stroke="#fff"
          strokeWidth="2"
        />
      )}
      <line
        x1="100"
        y1="100"
        x2={needleX}
        y2={needleY}
        stroke="#fff"
        strokeWidth="2.5"
        strokeLinecap="round"
        style={{ transition: 'all 0.6s' }}
      />
      <circle cx="100" cy="100" r="6" fill="#1d2f27" stroke="#fff" />
    </svg>
  );
};

type CompassProps = {
  bearing: number | null;
  color: string;
};

export const RadCompass = (props: CompassProps) => {
  const { bearing, color } = props;
  const labels = [
    ['С', 0],
    ['В', 90],
    ['Ю', 180],
    ['З', 270],
  ] as const;
  return (
    <svg viewBox="0 0 100 100" width="100%" height="100%">
      <circle
        cx="50"
        cy="50"
        r="42"
        fill="#050907"
        stroke={RAD_COLORS.edge}
        strokeWidth="2"
      />
      <circle
        cx="50"
        cy="50"
        r="26"
        fill="none"
        stroke={RAD_COLORS.edge}
        strokeDasharray="2 3"
      />
      {labels.map(([label, angle]) => {
        const [x, y] = polar(50, 50, 34, angle);
        return (
          <text
            key={label}
            x={x}
            y={y + 3.5}
            fill={RAD_COLORS.muted}
            fontSize="10"
            textAnchor="middle"
          >
            {label}
          </text>
        );
      })}
      {bearing !== null && bearing !== undefined ? (
        <g
          transform={`rotate(${bearing} 50 50)`}
          style={{ transition: 'transform 0.6s' }}
        >
          <polygon points="50,12 44,30 56,30" fill={color} />
          <line
            x1="50"
            y1="30"
            x2="50"
            y2="50"
            stroke={color}
            strokeWidth="2"
          />
        </g>
      ) : (
        <circle cx="50" cy="50" r="3" fill={RAD_COLORS.muted} />
      )}
    </svg>
  );
};

type TraceProps = {
  values: number[];
  color: string;
  /** Горизонтальные пунктирные линии */
  marks?: { value: number; color: string }[];
  /** Сколько замеров помещается в ширину */
  length?: number;
};

export const RadTrace = (props: TraceProps) => {
  const { values, color, marks = [], length = 60 } = props;
  const width = 300;
  const height = 100;
  const top = Math.max(1, ...values, ...marks.map((mark) => mark.value)) * 1.1;
  const toX = (index: number) => (index / Math.max(length - 1, 1)) * width;
  const toY = (value: number) => height - (value / top) * height;
  const offset = length - values.length;
  const points = values
    .map((value, index) => `${toX(index + offset)},${toY(value)}`)
    .join(' ');
  const area =
    values.length > 1
      ? `${toX(offset)},${height} ${points} ${toX(length - 1)},${height}`
      : '';

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      width="100%"
      height="100%"
      preserveAspectRatio="none"
    >
      {[25, 50, 75].map((y) => (
        <line
          key={y}
          x1="0"
          x2={width}
          y1={y}
          y2={y}
          stroke={RAD_COLORS.edge}
          strokeWidth="0.7"
          vectorEffect="non-scaling-stroke"
        />
      ))}
      {marks.map((mark) => (
        <line
          key={mark.value}
          x1="0"
          x2={width}
          y1={toY(mark.value)}
          y2={toY(mark.value)}
          stroke={mark.color}
          strokeDasharray="4 4"
          vectorEffect="non-scaling-stroke"
        />
      ))}
      {area && <polygon points={area} fill={color} fillOpacity="0.12" />}
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth="1.8"
        vectorEffect="non-scaling-stroke"
      />
    </svg>
  );
};

type BarProps = {
  value: number;
  maximum: number;
  color: string;
  mark?: number;
};

export const RadBar = (props: BarProps) => {
  const { value, maximum, color, mark } = props;
  const percent = Math.min((value / Math.max(maximum, 1)) * 100, 100);
  return (
    <div className="RadScope__bar">
      <div
        className="RadScope__barFill"
        style={{
          width: `${percent}%`,
          backgroundColor: color,
          boxShadow: `0 0 8px ${color}`,
        }}
      />
      {mark !== undefined && (
        <div
          className="RadScope__barMark"
          style={{ left: `${(mark / Math.max(maximum, 1)) * 100}%` }}
        />
      )}
    </div>
  );
};
