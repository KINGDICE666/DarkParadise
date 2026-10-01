import type { ReactNode } from 'react';
import { Button, NoticeBox, Stack } from 'tgui-core/components';
import { type BooleanLike, classes } from 'tgui-core/react';

import { Window } from '../../layouts';

export type OvermapLamp = {
  label: string;
  on?: BooleanLike;
  warn?: BooleanLike;
  bad?: BooleanLike;
};

type FrameProps = {
  title: string;
  width: number;
  height: number;
  linked?: BooleanLike;
  onRelink?: () => void;
  rail?: ReactNode;
  modes?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
};

export const OvermapFrame = (props: FrameProps) => {
  const {
    title,
    width,
    height,
    linked,
    onRelink,
    rail,
    modes,
    actions,
    children,
  } = props;
  return (
    <Window title={title} width={width} height={height}>
      <Window.Content fitted className="OvermapConsole">
        {!linked ? (
          <div className="OvermapConsole__pad">
            <NoticeBox danger>
              Нет связи с судном. Поставьте консоль на станцию или на шаттл.
            </NoticeBox>
            {!!onRelink && (
              <Button icon="link" onClick={onRelink}>
                Подключиться
              </Button>
            )}
          </div>
        ) : (
          <Stack fill vertical>
            {!!rail && <Stack.Item shrink={0}>{rail}</Stack.Item>}
            {!!modes && <Stack.Item shrink={0}>{modes}</Stack.Item>}
            <Stack.Item grow minHeight={0}>
              {children}
            </Stack.Item>
            {!!actions && (
              <Stack.Item shrink={0}>
                <div className="OvermapActions">{actions}</div>
              </Stack.Item>
            )}
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};

export const OvermapRail = (props: {
  name: string;
  sector?: string;
  xy?: string;
  lamps?: OvermapLamp[];
  extra?: ReactNode;
}) => {
  const { name, sector, xy, lamps = [], extra } = props;
  return (
    <div className="OvermapRail">
      <div className="OvermapRail__id">
        <div className="OvermapRail__name">{name}</div>
        <div className="OvermapRail__meta">
          {sector}
          {sector && xy ? ' · ' : ''}
          {xy}
        </div>
      </div>
      <div className="OvermapRail__lamps">
        {lamps.map((lamp) => (
          <div
            key={lamp.label}
            className={classes([
              'OvermapLamp',
              lamp.warn && 'OvermapLamp--warn',
              lamp.bad && 'OvermapLamp--bad',
              lamp.on && !lamp.bad && 'OvermapLamp--on',
            ])}
          >
            <span className="OvermapLamp__dot" />
            {lamp.label}
          </div>
        ))}
      </div>
      {extra}
    </div>
  );
};

export const OvermapSeg = <T extends string>(props: {
  value: T;
  onChange: (id: T) => void;
  items: { id: T; label: string }[];
}) => {
  const { value, onChange, items } = props;
  return (
    <div className="OvermapSeg">
      {items.map((item) => (
        <button
          key={item.id}
          type="button"
          className={classes([
            'OvermapSeg__item',
            value === item.id && 'OvermapSeg__item--on',
          ])}
          onClick={() => onChange(item.id)}
        >
          {item.label}
        </button>
      ))}
    </div>
  );
};

export const OvermapStats = (props: {
  children: ReactNode;
  grid?: boolean;
}) => (
  <div
    className={classes(['OvermapStats', props.grid && 'OvermapStats--grid'])}
  >
    {props.children}
  </div>
);

export const OvermapStat = (props: {
  label: string;
  value: ReactNode;
  tone?: 'good' | 'warn' | 'bad';
  hero?: boolean;
  scan?: boolean;
}) => {
  const { label, value, tone, hero, scan } = props;
  return (
    <div
      className={classes([
        'OvermapStat',
        tone && `OvermapStat--${tone}`,
        hero && 'OvermapStat--hero',
        scan && 'OvermapStat--scan',
      ])}
    >
      <div className="OvermapStat__label">{label}</div>
      <div className="OvermapStat__value">{value}</div>
    </div>
  );
};

export const OvermapCoord = (props: { x?: number; y?: number }) => {
  if (props.x == null || props.y == null) {
    return null;
  }
  return (
    <span className="OvermapCoord">
      {props.x}:{props.y}
    </span>
  );
};

export const overmapKindLabel = (kind?: string) => {
  switch (kind) {
    case 'station':
      return 'станция';
    case 'shuttle':
      return 'шаттл';
    case 'pod':
      return 'челнок';
    case 'planet':
      return 'планета';
    case 'portal':
      return 'портал';
    case 'ruin':
      return 'руина';
    case 'hazard':
      return 'угроза';
    case 'relay':
      return 'гипертранслятор';
    case 'unknown':
      return 'неизв.';
    default:
      return kind || 'объект';
  }
};

export const OvermapList = (props: { children: ReactNode }) => (
  <div className="OvermapList">{props.children}</div>
);

export const OvermapRow = (props: {
  title: ReactNode;
  meta?: ReactNode;
  tag?: string;
  selected?: BooleanLike;
  muted?: BooleanLike;
  bad?: BooleanLike;
  tone?: string;
  onClick?: () => void;
  children?: ReactNode;
}) => {
  const { title, meta, tag, selected, muted, bad, tone, onClick, children } =
    props;
  return (
    <div
      className={classes([
        'OvermapRow',
        selected && 'OvermapRow--on',
        muted && 'OvermapRow--muted',
        (bad || tone === 'bad') && 'OvermapRow--bad',
        tone && tone !== 'bad' && `OvermapRow--${tone}`,
        onClick && 'OvermapRow--click',
      ])}
      onClick={onClick}
    >
      {!!tag && <span className="OvermapRow__tag">{tag}</span>}
      <div className="OvermapRow__body">
        <div className="OvermapRow__title">{title}</div>
        {!!meta && <div className="OvermapRow__meta">{meta}</div>}
      </div>
      {!!children && <div className="OvermapRow__act">{children}</div>}
    </div>
  );
};

export const OvermapKey = (props: {
  icon?: string;
  iconRotation?: number;
  tooltip?: string;
  selected?: BooleanLike;
  disabled?: BooleanLike;
  color?: string;
  onClick: () => void;
}) => {
  const { icon, iconRotation, tooltip, selected, disabled, color, onClick } =
    props;
  return (
    <Button
      className="OvermapKey"
      icon={icon}
      iconRotation={iconRotation}
      tooltip={tooltip}
      selected={!!selected}
      disabled={disabled}
      color={color}
      onClick={onClick}
    />
  );
};
