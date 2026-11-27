import { Icon, NumberInput } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  dangerStatus,
  RAD_COLORS,
  RadBar,
  RadCompass,
  RadGauge,
  RadTrace,
  STAGE_COLORS,
  STAGE_DOSES,
  STAGE_NAMES,
  statusClass,
} from './common/RadiationInstruments';

type Data = {
  scanning: BooleanLike;
  mounted: BooleanLike;
  area: string | null;
  rate: number;
  peak: number;
  total: number;
  stage: number;
  bearing: number | null;
  history: number[];
  beep_level: number;
  max_beep_level: number;
};

const MILD_STAGE_DOSE = 100;

const formatSafeTime = (rate: number) => {
  if (rate < 0.1) {
    return 'без ограничений';
  }
  const minutes = MILD_STAGE_DOSE / rate;
  if (minutes >= 60) {
    return `${(minutes / 60).toFixed(1)} ч`;
  }
  if (minutes >= 1) {
    return `${minutes.toFixed(1)} мин`;
  }
  return `${Math.round(minutes * 60)} с`;
};

export const RadiationMeter = () => {
  const { act, data } = useBackend<Data>();
  const {
    scanning,
    mounted,
    area,
    rate,
    peak,
    total,
    stage,
    bearing,
    history,
    beep_level,
    max_beep_level,
  } = data;

  const status = dangerStatus(rate);
  const statusColor = [RAD_COLORS.good, RAD_COLORS.warn, RAD_COLORS.bad][status];
  const beeping = beep_level > 0 && rate >= beep_level;

  return (
    <Window width={640} height={520}>
      <Window.Content>
        <div className="RadScope">
          <div
            className="RadScope__grid"
            style={{
              gridTemplateColumns: '1.15fr 1fr',
              gridTemplateRows: 'auto 1fr',
            }}
          >
            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>
                  <span
                    className={`RadScope__lamp RadScope__lamp--${scanning ? status : 'off'}`}
                  />
                  {mounted ? area : 'Переносной режим'}
                </span>
                <button
                  className={`RadScope__button${scanning ? ' RadScope__button--active' : ''}`}
                  onClick={() => act('toggle_power')}
                >
                  <Icon name="power-off" mr={1} />
                  {scanning ? 'Вкл' : 'Выкл'}
                </button>
              </div>
              <div style={{ height: '150px' }}>
                <RadGauge
                  value={rate}
                  mark={beep_level}
                  maximum={max_beep_level}
                />
              </div>
              <div style={{ textAlign: 'center' }}>
                <span className={`RadScope__big ${statusClass(status)}`}>
                  {rate.toFixed(1)}
                </span>
                <span className="RadScope__unit">рад/мин</span>
              </div>
              <div className="RadScope__row">
                <span className="RadScope__muted">Пик</span>
                <span>
                  {peak.toFixed(1)} рад/мин{' '}
                  <button
                    className="RadScope__button"
                    onClick={() => act('reset_peak')}
                  >
                    сброс
                  </button>
                </span>
              </div>
              <div className="RadScope__row">
                <span className="RadScope__muted">Без защиты до лёгкой стадии</span>
                <span className={statusClass(status)}>
                  {formatSafeTime(rate)}
                </span>
              </div>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>Источник</span>
                <span>{bearing !== null ? `${bearing}°` : '—'}</span>
              </div>
              <div style={{ height: '132px' }}>
                <RadCompass bearing={bearing} color={statusColor} />
              </div>
              <div className="RadScope__title" style={{ marginTop: '8px' }}>
                <span>Накопленная доза</span>
                <button
                  className="RadScope__button"
                  onClick={() => act('reset_dose')}
                >
                  сброс
                </button>
              </div>
              <div>
                <span
                  className="RadScope__big"
                  style={{ color: STAGE_COLORS[stage], fontSize: '24px' }}
                >
                  {total}
                </span>
                <span className="RadScope__unit">рад</span>
                <span
                  style={{ color: STAGE_COLORS[stage], marginLeft: '8px' }}
                >
                  {STAGE_NAMES[stage]}
                </span>
              </div>
              <div style={{ marginTop: '6px' }}>
                <RadBar
                  value={total}
                  maximum={STAGE_DOSES[STAGE_DOSES.length - 1]}
                  color={STAGE_COLORS[stage]}
                />
              </div>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>График за 2 минуты</span>
                <span>рад/мин</span>
              </div>
              <div style={{ flex: 1, minHeight: 0 }}>
                <RadTrace
                  values={history}
                  color={statusColor}
                  marks={
                    beep_level > 0
                      ? [{ value: beep_level, color: RAD_COLORS.warn }]
                      : []
                  }
                />
              </div>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>Звуковой сигнал</span>
                <span className={beeping ? 'RadScope__warn' : undefined}>
                  <Icon name={beep_level > 0 ? 'volume-high' : 'volume-xmark'} />
                </span>
              </div>
              <div className="RadScope__row">
                <span className="RadScope__muted">Пищать от, рад/мин</span>
                <NumberInput
                  width="70px"
                  value={beep_level}
                  minValue={0}
                  maxValue={max_beep_level}
                  step={5}
                  stepPixelSize={2}
                  onChange={(value) => act('set_beep_level', { value })}
                />
              </div>
              <div className="RadScope__muted" style={{ marginTop: '4px' }}>
                {beep_level > 0
                  ? 'Прибор пищит, пока мощность не ниже этого уровня. 0 выключает писк.'
                  : 'Писк выключен.'}
              </div>
              <div className="RadScope__muted" style={{ marginTop: 'auto' }}>
                {mounted
                  ? 'Закреплён на стене. Снимается отвёрткой.'
                  : 'Нажмите прибором по стене, чтобы закрепить его.'}
              </div>
            </div>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
