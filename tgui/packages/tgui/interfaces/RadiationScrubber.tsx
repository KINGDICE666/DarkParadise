import { Icon } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  RAD_COLORS,
  RadBar,
  RadTrace,
  STAGE_COLORS,
  STAGE_NAMES,
} from './common/RadiationInstruments';

type Patient = {
  name: string;
  dose: number;
  stage: number;
  blood: number;
  blood_safe: number;
  blood_normal: number;
  health: number;
  max_health: number;
  dead: BooleanLike;
};

type Reagent = {
  name: string;
  volume: number;
  chelator: BooleanLike;
};

type Data = {
  active: BooleanLike;
  powered: BooleanLike;
  flow_rate: number;
  min_flow: number;
  max_flow: number;
  safe_flow: number;
  safety: BooleanLike;
  inject_beaker: BooleanLike;
  stress: number;
  max_stress: number;
  purge_rate: number;
  blood_loss: number;
  history: number[];
  patient: Patient | null;
  filter: { saturation: number; capacity: number } | null;
  beaker: { volume: number; maximum: number; contents: Reagent[] } | null;
};

const STAGE_DOSES = [0, 100, 300, 600, 1000];

const formatTime = (seconds: number) => {
  if (seconds >= 60) {
    return `${Math.floor(seconds / 60)} мин ${Math.round(seconds % 60)} с`;
  }
  return `${Math.round(seconds)} с`;
};

export const RadiationScrubber = () => {
  const { act, data } = useBackend<Data>();
  const {
    active,
    powered,
    flow_rate,
    min_flow,
    max_flow,
    safe_flow,
    safety,
    inject_beaker,
    stress,
    max_stress,
    purge_rate,
    blood_loss,
    history,
    patient,
    filter,
    beaker,
  } = data;

  const stageColor = patient ? STAGE_COLORS[patient.stage] : RAD_COLORS.muted;
  const flowValues: number[] = [];
  for (let flow = min_flow; flow <= max_flow; flow++) {
    flowValues.push(flow);
  }
  const hasChelator = beaker?.contents.some((reagent) => reagent.chelator);
  const timeLeft =
    patient && patient.dose > 0 && purge_rate > 0
      ? patient.dose / purge_rate
      : 0;
  const filterShare = filter ? filter.saturation / filter.capacity : 0;
  const stressShare = stress / max_stress;

  return (
    <Window width={700} height={560}>
      <Window.Content>
        <div
          className={`RadScope${patient?.dead || stressShare > 0.8 ? ' RadScope--alarm' : ''}`}
        >
          <div
            className="RadScope__grid"
            style={{
              gridTemplateColumns: '1.3fr 1fr',
              gridTemplateRows: 'auto 1fr',
            }}
          >
            <div className="RadScope__panel" style={{ gridColumn: '1 / 3' }}>
              <div className="RadScope__title">
                <span>
                  <Icon name="user-injured" mr={1} />
                  {patient ? patient.name : 'Пациент не подключён'}
                </span>
                {patient ? (
                  <button
                    className="RadScope__button"
                    onClick={() => act('detach')}
                  >
                    Отключить трубку
                  </button>
                ) : (
                  <span>перетащите установку на пациента</span>
                )}
              </div>
              <div className="RadScope__row">
                <div>
                  <span className="RadScope__big" style={{ color: stageColor }}>
                    {patient ? patient.dose : '—'}
                  </span>
                  <span className="RadScope__unit">рад</span>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: stageColor }}>
                    {patient ? STAGE_NAMES[patient.stage] : ''}
                  </div>
                  {!!active && timeLeft > 0 && (
                    <div className="RadScope__muted">
                      Осталось примерно {formatTime(timeLeft)}
                    </div>
                  )}
                </div>
              </div>
              <div className="RadScope__stages">
                {STAGE_NAMES.map((name, index) => {
                  const reached = patient ? patient.stage >= index : false;
                  return (
                    <div
                      key={name}
                      className={`RadScope__stage${reached ? ' RadScope__stage--reached' : ''}`}
                      style={
                        reached ? { background: STAGE_COLORS[index] } : undefined
                      }
                    >
                      {name} {STAGE_DOSES[index]}+
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>Доза пациента</span>
                <span>рад</span>
              </div>
              <div style={{ flex: 1, minHeight: 0 }}>
                <RadTrace values={history} color={stageColor} />
              </div>
              <div style={{ marginTop: '8px' }}>
                <div className="RadScope__row">
                  <span className="RadScope__muted">Кровь</span>
                  <span>
                    {patient
                      ? `${Math.round((patient.blood / patient.blood_normal) * 100)}%`
                      : '—'}
                  </span>
                </div>
                <RadBar
                  value={patient?.blood ?? 0}
                  maximum={patient?.blood_normal ?? 1}
                  mark={patient?.blood_safe}
                  color={
                    patient && patient.blood < patient.blood_safe
                      ? RAD_COLORS.bad
                      : '#d94452'
                  }
                />
                <div className="RadScope__row">
                  <span className="RadScope__muted">Нагрузка на сердце</span>
                  <span>{stress}%</span>
                </div>
                <RadBar
                  value={stress}
                  maximum={max_stress}
                  color={
                    stressShare > 0.7
                      ? RAD_COLORS.bad
                      : stressShare > 0.3
                        ? RAD_COLORS.warn
                        : RAD_COLORS.good
                  }
                />
              </div>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__title">
                <span>Насос</span>
                <span>{powered ? 'Питание есть' : 'Нет питания'}</span>
              </div>
              <div className="RadScope__flow">
                {flowValues.map((flow) => (
                  <button
                    key={flow}
                    className={`RadScope__button${flow === flow_rate ? (flow > safe_flow ? ' RadScope__button--danger' : ' RadScope__button--active') : ''}`}
                    onClick={() => act('set_flow', { value: flow })}
                  >
                    {flow}
                  </button>
                ))}
              </div>
              <div className="RadScope__row">
                <span className="RadScope__muted">Очистка</span>
                <span>{purge_rate} рад/с</span>
              </div>
              <div className="RadScope__row">
                <span className="RadScope__muted">Потеря крови</span>
                <span>{blood_loss} ед/с</span>
              </div>
              <button
                className={`RadScope__button RadScope__button--wide${active ? ' RadScope__button--danger' : ' RadScope__button--active'}`}
                disabled={!patient || !filter || !powered}
                onClick={() => act('toggle_pump')}
              >
                <Icon name={active ? 'stop' : 'play'} mr={1} />
                {active ? 'Остановить' : 'Запустить'}
              </button>
              <div className="RadScope__row" style={{ marginTop: '6px' }}>
                <span className="RadScope__muted">Автозащита пациента</span>
                <button
                  className={`RadScope__button${safety ? ' RadScope__button--active' : ' RadScope__button--danger'}`}
                  onClick={() => act('toggle_safety')}
                >
                  {safety ? 'Вкл' : 'Откл'}
                </button>
              </div>

              <div className="RadScope__title" style={{ marginTop: '10px' }}>
                <span>Фильтр</span>
                {filter && (
                  <button
                    className="RadScope__button"
                    onClick={() => act('eject_filter')}
                  >
                    Извлечь
                  </button>
                )}
              </div>
              {filter ? (
                <>
                  <RadBar
                    value={filter.saturation}
                    maximum={filter.capacity}
                    color={
                      filterShare > 0.5 ? RAD_COLORS.bad : RAD_COLORS.good
                    }
                  />
                  <div className="RadScope__row">
                    <span className="RadScope__muted">Насыщение</span>
                    <span
                      className={filterShare > 0.5 ? 'RadScope__bad' : undefined}
                    >
                      {filter.saturation} / {filter.capacity} рад
                    </span>
                  </div>
                </>
              ) : (
                <div className="RadScope__warn">Вставьте картридж.</div>
              )}

              <div className="RadScope__title" style={{ marginTop: '10px' }}>
                <span>Линия впрыска</span>
                {beaker && (
                  <button
                    className="RadScope__button"
                    onClick={() => act('eject_beaker')}
                  >
                    Извлечь
                  </button>
                )}
              </div>
              {beaker ? (
                <>
                  <div className="RadScope__row">
                    <span className="RadScope__muted">
                      {beaker.volume} / {beaker.maximum} ед.
                    </span>
                    <button
                      className={`RadScope__button${inject_beaker ? ' RadScope__button--active' : ''}`}
                      onClick={() => act('toggle_injection')}
                    >
                      {inject_beaker ? 'Подача вкл' : 'Подача откл'}
                    </button>
                  </div>
                  <div className={hasChelator ? 'RadScope__good' : 'RadScope__muted'}>
                    {hasChelator
                      ? 'Хелатор найден: очистка ×1,5'
                      : 'Хелатора нет: йодид калия или пентетовая кислота ускорят очистку'}
                  </div>
                </>
              ) : (
                <div className="RadScope__muted">Ёмкость не установлена.</div>
              )}
            </div>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
