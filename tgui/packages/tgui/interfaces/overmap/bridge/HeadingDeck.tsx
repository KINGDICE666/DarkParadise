import { classes } from 'tgui-core/react';

import { degrees } from './bridgeMath';
import { Btn, Deck, Kbd, Toggle, useBridge } from './parts';
import type { HelmData } from './types';

type HoldMode = NonNullable<HelmData['heading_hold']>;

const DIAL_TICKS = Array.from({ length: 24 }, (_, index) => index * 15);

const holdAngle = (data: HelmData) => {
  switch (data.heading_hold) {
    case 'current':
      return data.hold_angle ?? null;
    case 'prograde':
      return data.velocity_heading ?? null;
    case 'retrograde':
      return data.velocity_heading === null ||
        data.velocity_heading === undefined
        ? null
        : data.velocity_heading + 180;
    default:
      return null;
  }
};

export const toggleHold = (
  act: (action: string, params?: Record<string, unknown>) => void,
  data: HelmData,
  mode: HoldMode,
) => act('heading_hold', { mode: data.heading_hold === mode ? null : mode });

const HeadingDial = () => {
  const { data } = useBridge();
  const held = holdAngle(data);
  return (
    <svg className="Bridge__dial" viewBox="-62 -62 124 124">
      <circle className="Bridge__dialFace" r={56} />
      {DIAL_TICKS.map((angle) => {
        const rad = (angle * Math.PI) / 180;
        const inner = angle % 90 === 0 ? 46 : 51;
        return (
          <line
            key={angle}
            className="Bridge__dialTick"
            x1={Math.sin(rad) * 56}
            y1={-Math.cos(rad) * 56}
            x2={Math.sin(rad) * inner}
            y2={-Math.cos(rad) * inner}
          />
        );
      })}
      <text className="Bridge__dialLabel" y={-38}>
        N
      </text>
      {held !== null && (
        <g transform={`rotate(${held})`}>
          <line className="Bridge__dialHold" y1={-58} y2={-44} />
        </g>
      )}
      {data.velocity_heading !== null &&
        data.velocity_heading !== undefined && (
          <g transform={`rotate(${data.velocity_heading})`}>
            <circle className="Bridge__dialVector" cy={-50} r={3.5} />
          </g>
        )}
      <g transform={`rotate(${data.nose ?? data.facing})`}>
        <path className="Bridge__dialNose" d="M0 -40l8 26-8-6-8 6z" />
        <line className="Bridge__dialSpine" y1={-12} y2={22} />
      </g>
      <text className="Bridge__dialValue" y={40}>
        {degrees(data.nose ?? data.facing)}
      </text>
    </svg>
  );
};

export const HeadingDeck = () => {
  const { act, data, flightLocked } = useBridge();
  const fixed = !data.can_turn;
  const holdLocked = flightLocked || fixed;
  return (
    <Deck title="КУРС" off={flightLocked}>
      <div
        className={classes([
          'Bridge__heading',
          fixed && 'Bridge__heading--fixed',
        ])}
      >
        <HeadingDial />
        <div className="Bridge__stack">
          <Btn
            on={data.heading_hold === 'prograde'}
            disabled={holdLocked}
            title="Нос по направлению движения"
            onClick={() => toggleHold(act, data, 'prograde')}
          >
            ПО ВЕКТОРУ <Kbd>V</Kbd>
          </Btn>
          <Btn
            on={data.heading_hold === 'retrograde'}
            disabled={holdLocked}
            title="Нос против движения — удобно тормозить"
            onClick={() => toggleHold(act, data, 'retrograde')}
          >
            ПРОТИВ <Kbd>B</Kbd>
          </Btn>
          <Btn
            on={data.heading_hold === 'current'}
            disabled={holdLocked}
            title="Зафиксировать текущий курс"
            onClick={() => toggleHold(act, data, 'current')}
          >
            ДЕРЖАТЬ{' '}
            {degrees(
              data.heading_hold === 'current'
                ? data.hold_angle
                : (data.nose ?? data.facing),
            )}{' '}
            <Kbd>C</Kbd>
          </Btn>
          {fixed && <div className="Bridge__muted">курс фиксирован</div>}
        </div>
      </div>
      <Toggle
        on={data.drift_assist}
        disabled={flightLocked}
        title="Без пилота корабль сам гасит скорость. Выключите для свободного дрейфа."
        onClick={() => act('toggle_drift_assist')}
      >
        ГАШЕНИЕ ДРЕЙФА <Kbd>Z</Kbd>
      </Toggle>
      <div className="Bridge__keys">
        <Kbd>Q</Kbd>
        <Kbd>E</Kbd> поворот{' '}
        <span className={data.precision ? 'Bridge__keys--lit' : undefined}>
          <Kbd>SHIFT</Kbd> точно
        </span>
      </div>
    </Deck>
  );
};
