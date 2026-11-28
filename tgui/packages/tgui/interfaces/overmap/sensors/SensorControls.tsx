import {
  type MouseEvent as ReactMouseEvent,
  useEffect,
  useRef,
  useState,
} from 'react';
import { classes } from 'tgui-core/react';

const SEND_DELAY = 150;

const useWheel = (
  handler: (direction: number, fine: boolean) => void,
  disabled?: boolean,
) => {
  const ref = useRef<HTMLDivElement>(null);
  const handlerRef = useRef(handler);
  const disabledRef = useRef(disabled);
  handlerRef.current = handler;
  disabledRef.current = disabled;
  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    const wheel = (event: WheelEvent) => {
      if (disabledRef.current) return;
      event.preventDefault();
      handlerRef.current(event.deltaY > 0 ? -1 : 1, event.shiftKey);
    };
    element.addEventListener('wheel', wheel, { passive: false });
    return () => element.removeEventListener('wheel', wheel);
  }, []);
  return ref;
};

export const SensorKey = (props: {
  label: string;
  value?: string;
  on?: boolean;
  disabled?: boolean;
  big?: boolean;
  onClick: () => void;
}) => {
  const { label, value, on, disabled, big, onClick } = props;
  return (
    <button
      type="button"
      className={classes([
        'SensorKey',
        on && 'is-on',
        disabled && 'is-disabled',
        big && 'SensorKey--big',
        value !== undefined && 'SensorKey--split',
      ])}
      disabled={disabled}
      onClick={onClick}
    >
      <span>{label}</span>
      {value !== undefined && <span>{value}</span>}
    </button>
  );
};

export const SensorSegment = (props: {
  options: { id: string; label: string }[];
  value: string;
  disabled?: boolean;
  onChange: (id: string) => void;
}) => {
  const { options, value, disabled, onChange } = props;
  return (
    <div className="SensorSegment">
      {options.map((option) => (
        <SensorKey
          key={option.id}
          label={option.label}
          on={option.id === value}
          disabled={disabled}
          onClick={() => onChange(option.id)}
        />
      ))}
    </div>
  );
};

export const SensorSlider = (props: {
  label: string;
  value: number;
  onChange: (value: number) => void;
}) => {
  const { label, onChange } = props;
  const [value, setValue] = useState(props.value);
  const draggingRef = useRef(false);
  const sendRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const trackRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!draggingRef.current) setValue(props.value);
  }, [props.value]);
  const commit = (next: number) => {
    const clamped = Math.max(0, Math.min(100, Math.round(next)));
    setValue(clamped);
    clearTimeout(sendRef.current);
    sendRef.current = setTimeout(() => onChange(clamped), SEND_DELAY);
  };
  const wheelRef = useWheel((direction, fine) =>
    commit(value + direction * (fine ? 1 : 5)),
  );
  const pointAt = (clientX: number) => {
    const rect = trackRef.current?.getBoundingClientRect();
    if (!rect) return;
    commit(((clientX - rect.left) / rect.width) * 100);
  };
  const startDrag = (event: ReactMouseEvent) => {
    draggingRef.current = true;
    pointAt(event.clientX);
    const move = (moveEvent: MouseEvent) => pointAt(moveEvent.clientX);
    const stop = () => {
      draggingRef.current = false;
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', stop);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', stop);
  };
  return (
    <div className="SensorSlider" ref={wheelRef}>
      <div className="SensorSlider__head">
        <span>{label}</span>
        <span>{value}%</span>
      </div>
      <div
        className="SensorSlider__track"
        ref={trackRef}
        onMouseDown={startDrag}
      >
        <div className="SensorSlider__fill" style={{ width: `${value}%` }} />
      </div>
    </div>
  );
};

export const SensorStepper = (props: {
  value: string;
  disabled?: boolean;
  onStep: (direction: number, fine: boolean) => void;
  minusLabel?: string;
  plusLabel?: string;
}) => {
  const { value, disabled, onStep, minusLabel = '◀', plusLabel = '▶' } = props;
  const wheelRef = useWheel(onStep, disabled);
  return (
    <div
      className={classes(['SensorStepper', disabled && 'is-disabled'])}
      ref={wheelRef}
      title="Колесо мыши, с Shift точнее"
    >
      <button
        type="button"
        aria-label="Меньше"
        disabled={disabled}
        onClick={(event) => onStep(-1, event.shiftKey)}
      >
        {minusLabel}
      </button>
      <div className="SensorStepper__value">{value}</div>
      <button
        type="button"
        aria-label="Больше"
        disabled={disabled}
        onClick={(event) => onStep(1, event.shiftKey)}
      >
        {plusLabel}
      </button>
    </div>
  );
};
