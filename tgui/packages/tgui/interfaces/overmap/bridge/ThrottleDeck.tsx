import { classes } from 'tgui-core/react';

import { THROTTLE_STEPS, throttleIndex } from './bridgeMath';
import { Deck, HoldButton, Kbd, useBridge } from './parts';

const DETENTS = THROTTLE_STEPS.length;

export const setThrottle = (
  act: (action: string, params?: Record<string, unknown>) => void,
  maxCruise: number,
  index: number,
) => {
  if (index <= 0) {
    act('full_stop');
    return;
  }
  const step = THROTTLE_STEPS[Math.min(index, DETENTS - 1)];
  act('set_cruise', { value: Math.round(maxCruise * step[1]) });
};

const detentSpot = (index: number) =>
  `calc((100% - 14px) * ${index / DETENTS})`;

export const ThrottleDeck = () => {
  const { act, data, flightLocked } = useBridge();
  const maxCruise = data.max_cruise || 0;
  const current = throttleIndex(data);
  const speedPart = maxCruise ? Math.min(1, (data.speed || 0) / maxCruise) : 0;
  const speedSpot = `calc((100% - 14px) * ${(speedPart * (DETENTS - 1)) / DETENTS} + 7px)`;
  const locked = flightLocked || !maxCruise;
  return (
    <Deck title="ТЯГА" off={locked}>
      <div className="Bridge__telegraph">
        <div className="Bridge__lever">
          <div
            className={classes([
              'Bridge__burn',
              data.overdrive && 'Bridge__burn--on',
            ])}
          />
          <div className="Bridge__leverFill" style={{ height: speedSpot }} />
          <div className="Bridge__leverNow" style={{ bottom: speedSpot }} />
          <div
            className="Bridge__knob"
            style={{ bottom: detentSpot(current) }}
          />
        </div>
        <div className="Bridge__detents">
          <HoldButton
            className={classes([
              'Bridge__detent',
              'Bridge__detent--hot',
              data.overdrive && 'Bridge__detent--burning',
            ])}
            disabled={locked}
            title="Удерживайте, чтобы включить или выключить форсаж"
            onHold={() => act('toggle_overdrive')}
          >
            ФОРСАЖ <b>{data.overdrive ? 'ВКЛ' : '×1,5'}</b>
          </HoldButton>
          {[...THROTTLE_STEPS]
            .map((step, index) => [step, index] as const)
            .reverse()
            .map(([[label, part], index]) => (
              <button
                key={label}
                type="button"
                disabled={locked}
                className={classes([
                  'Bridge__detent',
                  index === current && 'Bridge__detent--on',
                ])}
                onClick={() => setThrottle(act, maxCruise, index)}
              >
                {label} <b>{Math.round(maxCruise * part)}</b>
              </button>
            ))}
        </div>
      </div>
      <div className="Bridge__keys">
        <Kbd>R</Kbd>
        <Kbd>F</Kbd> ход <Kbd>ПРОБЕЛ</Kbd> тормоз
      </div>
    </Deck>
  );
};
