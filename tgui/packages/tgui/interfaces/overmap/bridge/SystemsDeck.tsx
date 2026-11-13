import { Deck, HoldButton, Toggle, useBridge } from './parts';

const CELLS = 11;
const HEAT_WARN = 50;
const HEAT_DANGER = 85;
const OVERHEAT = 100;

const Cells = (props: { part: number; tone?: (index: number) => string }) => (
  <div className="Bridge__cells">
    {Array.from({ length: CELLS }, (_, index) => (
      <i
        key={index}
        className={
          index < Math.round(Math.max(0, Math.min(1, props.part)) * CELLS)
            ? props.tone?.(index)
            : 'Bridge__cells--empty'
        }
      />
    ))}
  </div>
);

export const SystemsDeck = () => {
  const { act, data } = useBridge();
  const { shield, engines } = data;
  const hottest = Math.max(0, ...engines.map((engine) => engine.heat || 0));
  const stalled = engines.filter(
    (engine) => (engine.heat || 0) >= OVERHEAT,
  ).length;
  const transmitting = data.transponder
    ? data.transponder.broadcasting
    : data.broadcasting;
  const heatTone = (index: number) => {
    const at = ((index + 1) / CELLS) * OVERHEAT;
    if (at > HEAT_DANGER) {
      return 'Bridge__cells--danger';
    }
    return at > HEAT_WARN ? 'Bridge__cells--warn' : 'Bridge__cells--good';
  };
  return (
    <Deck title="СИСТЕМЫ">
      {shield ? (
        <>
          <div className="Bridge__sys">
            <span>ЩИТ</span>
            <small>
              {shield.capacity > 0
                ? `${shield.charge} / ${shield.capacity}`
                : 'нет питания'}
            </small>
            <Cells
              part={shield.capacity > 0 ? shield.charge / shield.capacity : 0}
              tone={() => 'Bridge__cells--shield'}
            />
          </div>
          <Toggle
            on={shield.active}
            title={`Генераторов: ${shield.generators}`}
            onClick={() => act('toggle_shields')}
          >
            ГЕНЕРАТОРЫ ЩИТА
          </Toggle>
        </>
      ) : (
        <div className="Bridge__muted">щит не установлен</div>
      )}
      <div className="Bridge__sys">
        <span>НАГРЕВ ДВИГАТЕЛЕЙ</span>
        <small>
          {Math.round(hottest)}°{stalled ? ` · ${stalled} заглохло` : ''}
        </small>
        <Cells part={hottest / OVERHEAT} tone={heatTone} />
      </div>
      <Toggle
        on={transmitting}
        disabled={!data.transponder || !!data.gunner}
        title={
          data.has_transponder
            ? data.transponder
              ? undefined
              : 'Транспондер не отвечает: нет питания или он сломан.'
            : 'Транспондера на борту нет.'
        }
        onClick={() => act('transponder', { op: 'toggle_broadcast' })}
      >
        ТРАНСПОНДЕР В ЭФИРЕ
      </Toggle>
      <HoldButton
        className="Bridge__sos"
        disabled={!data.transponder || !!data.gunner}
        title="Удерживайте, чтобы подать или снять сигнал бедствия"
        onHold={() => act('transponder', { op: 'toggle_distress' })}
      >
        {data.distress ? 'СНЯТЬ СИГНАЛ БЕДСТВИЯ' : 'СИГНАЛ БЕДСТВИЯ'}
      </HoldButton>
    </Deck>
  );
};
