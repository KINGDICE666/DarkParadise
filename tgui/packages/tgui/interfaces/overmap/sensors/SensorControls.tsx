import {
  type MouseEvent as ReactMouseEvent,
  type ReactNode,
  useEffect,
  useRef,
  useState,
} from 'react';
import { classes } from 'tgui-core/react';

const DIAL_SIZE = 92;
const DIAL_SEND_DELAY = 150;

export const SensorToggle = (props: {
  label: string;
  hint: string;
  on: boolean;
  disabled?: boolean;
  tone?: 'green' | 'amber';
  onToggle: () => void;
}) => {
  const { label, hint, on, disabled, tone = 'green', onToggle } = props;
  return (
    <div
      className={classes([
        'SensorToggle',
        `SensorToggle--${tone}`,
        on && 'is-on',
        disabled && 'is-disabled',
      ])}
      onClick={() => !disabled && onToggle()}
      title={hint}
    >
      <div className="SensorToggle__label">{label}</div>
      <div className="SensorToggle__pill">
        <span className="SensorToggle__knob" />
        <span className="SensorToggle__text">{on ? 'ON ⚡' : 'OFF ⚡'}</span>
      </div>
      <div className="SensorToggle__state">
        {disabled ? 'НЕТ МАССИВА' : on ? 'ВКЛЮЧЁН' : 'ВЫКЛЮЧЕН'}
      </div>
    </div>
  );
};

export const SensorSelector = (props: {
  label: string;
  options: { id: string; label: string }[];
  value: string;
  disabled?: boolean;
  onChange: (id: string) => void;
}) => {
  const { label, options, value, disabled, onChange } = props;
  const index = Math.max(
    0,
    options.findIndex((option) => option.id === value),
  );
  const angle =
    options.length > 1 ? -40 + (80 * index) / (options.length - 1) : 0;
  return (
    <div
      className={classes(['SensorSelector', disabled && 'is-disabled'])}
      onClick={() =>
        !disabled && onChange(options[(index + 1) % options.length].id)
      }
    >
      <div className="SensorToggle__label">{label}</div>
      <div className="SensorSelector__body">
        <div
          className="SensorSelector__knob"
          style={{ transform: `rotate(${angle}deg)` }}
        >
          <span />
        </div>
        <div className="SensorSelector__marks">
          {options.map((option) => (
            <span
              key={option.id}
              className={classes([option.id === value && 'is-on'])}
            >
              {option.label}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
};

export const SensorDial = (props: {
  label: string;
  value: number;
  disabled?: boolean;
  onChange: (value: number) => void;
}) => {
  const { label, disabled, onChange } = props;
  const [value, setValue] = useState(props.value);
  const bodyRef = useRef<HTMLDivElement>(null);
  const sendRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const dragRef = useRef(false);
  const stateRef = useRef({ value, disabled, onChange });
  stateRef.current = { value, disabled, onChange };

  useEffect(() => {
    if (!dragRef.current) setValue(props.value);
  }, [props.value]);

  const commit = (next: number) => {
    const wrapped = ((Math.round(next) % 360) + 360) % 360;
    setValue(wrapped);
    clearTimeout(sendRef.current);
    sendRef.current = setTimeout(
      () => stateRef.current.onChange(wrapped),
      DIAL_SEND_DELAY,
    );
  };

  useEffect(() => {
    const body = bodyRef.current;
    if (!body) return;
    const wheel = (event: WheelEvent) => {
      if (stateRef.current.disabled) return;
      event.preventDefault();
      const step = event.shiftKey ? 1 : 5;
      commit(stateRef.current.value + (event.deltaY > 0 ? step : -step));
    };
    body.addEventListener('wheel', wheel, { passive: false });
    return () => body.removeEventListener('wheel', wheel);
  }, []);

  const pointAt = (clientX: number, clientY: number) => {
    const body = bodyRef.current;
    if (!body) return;
    const rect = body.getBoundingClientRect();
    const x = clientX - rect.left - rect.width / 2;
    const y = clientY - rect.top - rect.height / 2;
    commit((Math.atan2(y, x) * 180) / Math.PI + 90);
  };

  const startDrag = (event: ReactMouseEvent) => {
    if (disabled) return;
    dragRef.current = true;
    pointAt(event.clientX, event.clientY);
    const move = (moveEvent: MouseEvent) =>
      pointAt(moveEvent.clientX, moveEvent.clientY);
    const stop = () => {
      dragRef.current = false;
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', stop);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', stop);
  };

  const half = DIAL_SIZE / 2;
  const ticks: ReactNode[] = [];
  for (let bearing = 0; bearing < 360; bearing += 15) {
    const major = bearing % 90 === 0;
    const angle = ((bearing - 90) * Math.PI) / 180;
    const outer = half - 2;
    const inner = outer - (major ? 8 : 4);
    ticks.push(
      <line
        key={bearing}
        x1={half + Math.cos(angle) * inner}
        y1={half + Math.sin(angle) * inner}
        x2={half + Math.cos(angle) * outer}
        y2={half + Math.sin(angle) * outer}
        className={major ? 'SensorDial__tick--major' : 'SensorDial__tick'}
      />,
    );
  }
  const pointer = ((value - 90) * Math.PI) / 180;
  return (
    <div className={classes(['SensorDial', disabled && 'is-disabled'])}>
      <div className="SensorToggle__label">{label}</div>
      <div
        ref={bodyRef}
        className="SensorDial__body"
        onMouseDown={startDrag}
        title="Колесо мыши: ±5°, с Shift: ±1°. Можно тянуть мышью."
      >
        <svg width={DIAL_SIZE} height={DIAL_SIZE}>
          {ticks}
          <path
            className="SensorDial__arc"
            d={`M${half} ${half} L${half + Math.cos(pointer - Math.PI / 6) * (half - 12)} ${half + Math.sin(pointer - Math.PI / 6) * (half - 12)} A${half - 12} ${half - 12} 0 0 1 ${half + Math.cos(pointer + Math.PI / 6) * (half - 12)} ${half + Math.sin(pointer + Math.PI / 6) * (half - 12)} Z`}
          />
          <circle
            className="SensorDial__knob"
            cx={half}
            cy={half}
            r={half - 16}
          />
          {Array.from({ length: 24 }, (_, index) => {
            const angle = (index * Math.PI * 2) / 24 + pointer;
            return (
              <line
                key={index}
                className="SensorDial__grip"
                x1={half + Math.cos(angle) * (half - 19)}
                y1={half + Math.sin(angle) * (half - 19)}
                x2={half + Math.cos(angle) * (half - 16)}
                y2={half + Math.sin(angle) * (half - 16)}
              />
            );
          })}
          <line
            className="SensorDial__pointer"
            x1={half + Math.cos(pointer) * 8}
            y1={half + Math.sin(pointer) * 8}
            x2={half + Math.cos(pointer) * (half - 18)}
            y2={half + Math.sin(pointer) * (half - 18)}
          />
          <text className="SensorDial__value" x={half} y={half + 4}>
            {String(value).padStart(3, '0')}°
          </text>
        </svg>
      </div>
    </div>
  );
};
