import { useState } from 'react';
import { Button, Input, NoticeBox } from 'tgui-core/components';
import { type BooleanLike, classes } from 'tgui-core/react';

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { GalaxyLayer } from './overmap/GalaxyLayer';
import type { GalaxyMap } from './overmap/OvermapRadar';
import {
  SensorDial,
  SensorSelector,
  SensorToggle,
} from './overmap/sensors/SensorControls';
import { SensorHelp } from './overmap/sensors/SensorHelp';
import { SensorScope } from './overmap/sensors/SensorScope';
import {
  SensorSilhouette,
  SensorWaterfall,
} from './overmap/sensors/SensorWaterfall';
import type {
  SensorClutter,
  SensorEmission,
  SensorTrack,
} from './overmap/sensors/types';

type JournalEntry = {
  time: string;
  text: string;
  kind?: string;
  x?: number;
  y?: number;
  name?: string;
  tone?: string;
  note?: string;
};

type ScanInfo = {
  name: string;
  kind: string;
  mass: number;
  living: number;
  engines: number;
  engines_ready: number;
  speed: number;
  heading: number;
  transponder: BooleanLike;
  size_x: number;
  size_y: number;
  has_hull?: BooleanLike;
};

type SensorPostData = {
  linked: BooleanLike;
  has_long: BooleanLike;
  has_short: BooleanLike;
  passive_on: BooleanLike;
  active_mode: string;
  sector_bearing?: number;
  long_view: number;
  short_view: number;
  sweep_period: number;
  can_run: BooleanLike;
  tracks: SensorTrack[];
  clutter: SensorClutter[];
  emission?: SensorEmission;
  locked?: string;
  haywire?: BooleanLike;
  scanning: BooleanLike;
  scan_error?: string;
  scan?: ScanInfo;
  scan_done?: BooleanLike;
  scan_target?: string;
  scan_progress: number;
  silhouette?: number[];
  can_print?: BooleanLike;
  can_dump?: BooleanLike;
  dump_loaded?: BooleanLike;
  dump_name?: string;
  dump_has_data?: BooleanLike;
  dump_count?: number;
  known_count?: number;
  selected?: string;
  map_jammed?: BooleanLike;
  journal: JournalEntry[];
  alerts?: { id: string; label: string; on: BooleanLike }[];
  vessel_name?: string;
  x?: number;
  y?: number;
  sector_name?: string;
  sector_id?: string;
  heading?: number;
  speed?: number;
  galaxy?: GalaxyMap;
};

const SCALES = [2, 4, 8, 12, 16];
const GALAXY_RADIUS = 1000;

const SOURCE_TAGS: Record<string, [string, string]> = {
  act: ['АКТ', 'act'],
  short: ['БЛИЖ', 'act'],
  pas: ['ПАС', 'pas'],
  iff: ['IFF', 'iff'],
  map: ['КАРТА', 'iff'],
  sos: ['SOS', 'sos'],
  lost: ['ПОТЕРЯН', 'lost'],
};

const LEVEL_TONES: Record<string, string> = {
  ТИШИНА: 'good',
  НИЗКАЯ: 'good',
  СРЕДНЯЯ: 'warn',
  ВЫСОКАЯ: 'bad',
};

const pad3 = (value: number) => String(Math.round(value)).padStart(3, '0');

const clock = (seconds: number) =>
  `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;

const threat = (track: SensorTrack) => {
  if (track.locked) return 0;
  if (track.source === 'sos') return 1;
  if (track.cpa_time !== undefined && track.cpa !== undefined && track.cpa < 1)
    return 2;
  if (track.source === 'map') return 6;
  if (track.source === 'lost') return 5;
  if (track.name) return 4;
  return 3;
};

const trackTitle = (track: SensorTrack) => {
  if (track.name) return track.name;
  const best = track.classes[0];
  const temper =
    track.ir >= 60 ? 'горячий' : track.em >= 50 ? 'шумный' : 'холодный';
  return best && track.source !== 'pas'
    ? `неизвестен · ${best.label}?`
    : `неизвестен · ${temper}`;
};

export const OvermapSensors = () => {
  const { act, data } = useBackend<SensorPostData>();
  const [tab, setTab] = useLocalState<string>('sensorTab', 'scope');
  const [scale, setScale] = useLocalState('sensorScale', 8);
  const [query, setQuery] = useState('');
  const {
    linked,
    has_long,
    has_short,
    passive_on,
    active_mode,
    tracks = [],
    clutter = [],
    emission,
    locked,
    journal = [],
  } = data;

  if (!linked) {
    return (
      <Window title="Sensors" width={1180} height={820}>
        <Window.Content className="SensorPost">
          <NoticeBox danger>
            Нет связи с судном. Поставьте консоль на станцию или на шаттл.
          </NoticeBox>
          <Button icon="link" onClick={() => act('relink')}>
            Подключиться
          </Button>
        </Window.Content>
      </Window>
    );
  }

  const sorted = [...tracks].sort(
    (first, second) =>
      threat(first) - threat(second) || first.range - second.range,
  );
  const selected =
    tracks.find((track) => track.ref === data.selected) ||
    tracks.find((track) => track.ref === locked) ||
    sorted[0];
  const activeOn = active_mode !== 'off';
  const passiveCount = tracks.filter((track) => track.source === 'pas').length;
  const clutterNames = [...new Set(clutter.map((cloud) => cloud.name))];

  return (
    <Window title="Sensors" width={1180} height={820}>
      <Window.Content fitted className="SensorPost">
        <div className="SensorPost__head">
          <div className="SensorPost__ship">
            <b>{data.vessel_name || 'СУДНО'}</b>
            <div>
              {data.sector_name || 'Сектор'} · {data.x}:{data.y} · КУРС{' '}
              {pad3(data.heading || 0)}° · {data.speed || 0} Гм/ч
            </div>
          </div>
          <div className="SensorPost__tabs">
            {[
              ['scope', 'ОБЗОР'],
              ['galaxy', 'ГАЛАКТИКА'],
              ['log', `ЖУРНАЛ ${journal.length}`],
              ['alerts', 'ОПОВЕЩЕНИЯ'],
              ['help', 'СПРАВКА'],
            ].map(([id, label]) => (
              <span
                key={id}
                className={classes([tab === id && 'is-on'])}
                onClick={() => setTab(id)}
              >
                {label}
              </span>
            ))}
          </div>
          {!!emission && (
            <div className="SensorPost__emcon">
              <div>
                <div className="SensorPost__label">НАША ЗАМЕТНОСТЬ</div>
                <div
                  className={`SensorPost__level SensorPost__level--${LEVEL_TONES[emission.level] || 'warn'}`}
                >
                  {emission.level === 'ТИШИНА' ? '●' : '▲'} {emission.level}
                </div>
              </div>
              {(
                [
                  ['ИК', emission.ir, '#ffb347'],
                  ['ЭМ', emission.em, '#ff5f6d'],
                  ['МАССА', emission.mass, '#7ad0e4'],
                ] as [string, number, string][]
              ).map(([label, value, color]) => (
                <div key={label} className="SensorPost__bar">
                  <i>
                    {label} {value}%
                  </i>
                  <div>
                    <b style={{ width: `${value}%`, background: color }} />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
        {tab === 'scope' && (
          <div className="SensorPost__body">
            <div className="SensorPost__left">
              <div className="SensorPost__scope">
                {data.map_jammed ? (
                  <div className="SensorPost__jam">
                    ПОМЕХИ ГИПЕРТРАНСЛЯТОРА · СВЯЗЬ ПОТЕРЯНА
                  </div>
                ) : (
                  <SensorScope
                    tracks={tracks}
                    clutter={clutter}
                    scale={scale}
                    heading={data.heading || 0}
                    speed={data.speed || 0}
                    activeMode={active_mode}
                    sectorBearing={data.sector_bearing}
                    passiveOn={!!passive_on}
                    longView={data.long_view}
                    shortView={data.short_view}
                    sweepPeriod={data.sweep_period}
                    selected={selected?.ref}
                    locked={locked}
                    onSelect={(ref) => act('select', { ref })}
                    onAim={(bearing) => act('aim', { bearing })}
                  />
                )}
                {!!data.haywire && (
                  <div className="SensorPost__haywire">
                    ⚠ ПАССИВ: СБОЙ ПОСЛЕ ЭМИ · ЛОЖНЫЕ ПЕЛЕНГИ
                  </div>
                )}
                <div className="SensorPost__corner SensorPost__corner--tl">
                  ОБЗОР{' '}
                  <b>
                    {active_mode === 'circle'
                      ? 'КРУГОВОЙ'
                      : active_mode === 'sector'
                        ? `СЕКТОР ${pad3(data.sector_bearing || 0)}°`
                        : passive_on
                          ? 'ПАССИВНЫЙ'
                          : 'ВЫКЛЮЧЕН'}
                  </b>
                  <br />
                  ПЕРИОД <b>{data.sweep_period.toFixed(1)} с</b>
                  <br />
                  ШКАЛА <b>{scale} Гм</b>
                </div>
                <div className="SensorPost__corner SensorPost__corner--tr">
                  ТРЕКОВ <b>{tracks.length}</b>
                  <br />
                  АКТИВНЫХ <b>{tracks.length - passiveCount}</b> · ПАССИВНЫХ{' '}
                  <b>{passiveCount}</b>
                  {!!clutterNames.length && (
                    <>
                      <br />
                      ПОМЕХИ <b>{clutterNames.slice(0, 2).join(', ')}</b>
                    </>
                  )}
                </div>
                <div className="SensorPost__corner SensorPost__corner--bl">
                  ◉ ВЫ &nbsp; ▲ IFF &nbsp; ◆ РАДАР &nbsp; ■ SOS &nbsp; ⌒ ПЕЛЕНГ
                  {active_mode === 'sector' && (
                    <>
                      <br />
                      клик по экрану — навести сектор
                    </>
                  )}
                </div>
                <div className="SensorPost__corner SensorPost__corner--br">
                  ШКАЛА
                  <div className="SensorPost__zoom">
                    {SCALES.map((value) => (
                      <span
                        key={value}
                        className={classes([value === scale && 'is-on'])}
                        onClick={() => setScale(value)}
                      >
                        {value}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
              <div className="SensorPost__deck">
                <SensorToggle
                  label="ТЕПЛОВОЙ ПАССИВ"
                  hint="Слушает тепло и излучение. Нас не выдаёт."
                  on={!!passive_on}
                  disabled={!has_short}
                  onToggle={() => act('toggle_passive')}
                />
                <SensorToggle
                  label="АКТИВНЫЙ РАДАР"
                  hint="Точные позиции и скорости. Нас видят все с пассивом."
                  tone="amber"
                  on={activeOn}
                  disabled={!has_long}
                  onToggle={() =>
                    act('set_active', { mode: activeOn ? 'off' : 'circle' })
                  }
                />
                <SensorSelector
                  label="РЕЖИМ ЛУЧА"
                  value={active_mode === 'sector' ? 'sector' : 'circle'}
                  disabled={!has_long || !activeOn}
                  options={[
                    { id: 'circle', label: 'КРУГ' },
                    { id: 'sector', label: 'СЕКТОР' },
                  ]}
                  onChange={(mode) => act('set_active', { mode })}
                />
                <SensorDial
                  label="АЗИМУТ СЕКТОРА"
                  value={data.sector_bearing ?? data.heading ?? 0}
                  disabled={active_mode !== 'sector'}
                  onChange={(bearing) => act('aim', { bearing })}
                />
              </div>
              <div className="SensorPost__fall">
                <div className="SensorPost__cap">
                  ПАССИВНЫЙ ВОДОПАД · ПЕЛЕНГ / ВРЕМЯ · 0–360°
                </div>
                <SensorWaterfall
                  tracks={tracks}
                  clutter={clutter}
                  live={!!passive_on || active_mode !== 'off'}
                  haywire={!!data.haywire}
                />
              </div>
            </div>
            <div className="SensorPost__right">
              <div className="SensorPost__box">
                <h3>
                  ТРЕКИ<span>сорт: угроза</span>
                </h3>
                <div className="SensorPost__table">
                  <table>
                    <thead>
                      <tr>
                        <th>ТРЕК</th>
                        <th>ОБЪЕКТ</th>
                        <th>ИСТ.</th>
                        <th>ПЕЛ.</th>
                        <th>ДАЛЬН.</th>
                        <th>СБЛИЖ.</th>
                        <th>CPA</th>
                        <th>КАЧЕСТВО</th>
                      </tr>
                    </thead>
                    <tbody>
                      {sorted.map((track) => {
                        const [tag, tone] = SOURCE_TAGS[track.source] || [
                          '?',
                          'lost',
                        ];
                        return (
                          <tr
                            key={track.ref}
                            className={classes([
                              track.ref === selected?.ref && 'is-sel',
                              track.source === 'lost' && 'is-lost',
                            ])}
                            onClick={() => act('select', { ref: track.ref })}
                          >
                            <td className="SensorPost__id">
                              {track.locked ? '⌖ ' : ''}
                              {track.id}
                            </td>
                            <td>{trackTitle(track)}</td>
                            <td>
                              <span
                                className={`SensorPost__tag SensorPost__tag--${tone}`}
                              >
                                {tag}
                              </span>
                            </td>
                            <td>{pad3(track.bearing)}°</td>
                            <td>
                              {track.range_err !== undefined
                                ? `${Math.max(0, track.range - track.range_err).toFixed(1)}–${(track.range + track.range_err).toFixed(1)}`
                                : track.range.toFixed(1)}{' '}
                              Гм
                            </td>
                            <td
                              className={
                                (track.closing || 0) < 0
                                  ? 'SensorPost__closing'
                                  : 'SensorPost__opening'
                              }
                            >
                              {track.closing !== undefined
                                ? `${track.closing > 0 ? '+' : ''}${track.closing.toFixed(1)}`
                                : '—'}
                            </td>
                            <td>
                              {track.cpa !== undefined &&
                              track.cpa_time !== undefined
                                ? `${track.cpa.toFixed(1)} · ${clock(track.cpa_time)}`
                                : '—'}
                            </td>
                            <td>
                              <span className="SensorPost__tq">
                                <b
                                  className={`SensorPost__tq--${tone}`}
                                  style={{ width: `${track.quality}%` }}
                                />
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                  {!sorted.length && (
                    <div className="SensorPost__empty">
                      {data.can_run
                        ? 'Контактов нет. Включите пассив или активный радар.'
                        : 'Нет рабочих массивов сенсоров.'}
                    </div>
                  )}
                </div>
              </div>
              {!!selected && (
                <TrackCard track={selected} data={data} act={act} />
              )}
            </div>
          </div>
        )}
        {tab === 'galaxy' && (
          <div className="SensorPost__galaxy">
            {data.galaxy ? (
              <svg
                viewBox={`${-GALAXY_RADIUS * 1.1} ${-GALAXY_RADIUS * 0.92} ${GALAXY_RADIUS * 2.2} ${GALAXY_RADIUS * 1.84}`}
                preserveAspectRatio="xMidYMid meet"
              >
                <GalaxyLayer
                  galaxy={data.galaxy}
                  sectorId={data.sector_id}
                  radius={GALAXY_RADIUS}
                  opacity={1}
                  slot={GALAXY_RADIUS / 2.4}
                />
              </svg>
            ) : (
              <NoticeBox>Карта галактики недоступна.</NoticeBox>
            )}
          </div>
        )}
        {tab === 'log' && (
          <div className="SensorPost__journal">
            <div className="SensorPost__journal-list">
              {journal
                .filter((entry) =>
                  `${entry.text} ${entry.name || ''} ${entry.note || ''}`
                    .toLowerCase()
                    .includes(query.trim().toLowerCase()),
                )
                .slice()
                .reverse()
                .map((entry, index) => (
                  <div key={index} className="SensorPost__journal-row">
                    <span className="SensorPost__time">{entry.time}</span>
                    <span
                      className={`SensorPost__tone--${entry.tone || 'info'}`}
                    >
                      {entry.text}
                      {entry.note ? ` · ${entry.note}` : ''}
                    </span>
                    {entry.x !== undefined && (
                      <span className="SensorPost__coord">
                        [{entry.x}:{entry.y}]
                      </span>
                    )}
                  </div>
                ))}
              {!journal.length && (
                <div className="SensorPost__empty">Журнал пуст.</div>
              )}
            </div>
            <div className="SensorPost__journal-tools">
              {!!data.can_dump &&
                (data.dump_loaded ? (
                  <>
                    <Button icon="download" onClick={() => act('dump_write')}>
                      Выгрузить дамп ({data.known_count || 0})
                    </Button>
                    <Button
                      icon="upload"
                      disabled={!data.dump_has_data}
                      onClick={() => act('dump_load')}
                    >
                      Загрузить дамп
                      {data.dump_has_data ? ` (${data.dump_count})` : ''}
                    </Button>
                    <Button icon="eject" onClick={() => act('dump_eject')}>
                      Достать {data.dump_name || 'листок'}
                    </Button>
                  </>
                ) : (
                  <Button disabled>Вставьте бумагу в сканер</Button>
                ))}
              <Input
                fluid
                placeholder="Поиск по журналу"
                value={query}
                onChange={(value) => setQuery(value)}
              />
            </div>
          </div>
        )}
        {tab === 'help' && <SensorHelp />}
        {tab === 'alerts' && (
          <div className="SensorPost__alerts">
            {(data.alerts || []).map((alert) => (
              <div
                key={alert.id}
                className={classes([
                  'SensorPost__alert',
                  !!alert.on && 'is-on',
                ])}
                onClick={() => act('toggle_alert', { id: alert.id })}
              >
                <span className="SensorPost__lamp" />
                {alert.label}
                <i>{alert.on ? 'звук включён' : 'без звука'}</i>
              </div>
            ))}
          </div>
        )}
      </Window.Content>
    </Window>
  );
};

const TrackCard = (props: {
  track: SensorTrack;
  data: SensorPostData;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const { track, data, act } = props;
  const scanningThis = !!data.scanning && data.scan_target === track.ref;
  const precise = track.source !== 'pas' && track.source !== 'lost';
  const scan = scanningThis && data.scan_done ? data.scan : undefined;
  return (
    <div className="SensorPost__box">
      <h3>
        ТРЕК {track.id}
        <span>ведётся {clock(track.age)}</span>
      </h3>
      <div className="SensorPost__card">
        <div className="SensorPost__sil">
          {scanningThis ? (
            <SensorSilhouette
              tiles={data.silhouette}
              progress={data.scan_progress}
              done={!!data.scan_done}
            />
          ) : (
            <div className="SensorPost__sil-empty">
              {track.can_scan
                ? 'готов к детальному скану'
                : 'вне зоны детального скана'}
            </div>
          )}
        </div>
        <div className="SensorPost__info">
          <div className="SensorPost__name">
            {(track.name || 'НЕИЗВЕСТНЫЙ КОНТАКТ').toUpperCase()}
          </div>
          <div className="SensorPost__class">
            Класс:{' '}
            {track.classes
              .map((entry) => `${entry.label} — ${entry.chance}%`)
              .join(' · ')}
          </div>
          <div className="SensorPost__kv">
            <i>пеленг / дальн.</i>
            <span>
              {pad3(track.bearing)}° · {track.range.toFixed(1)}
              {track.range_err !== undefined
                ? ` ± ${track.range_err.toFixed(1)}`
                : ''}{' '}
              Гм
            </span>
            {precise && (
              <>
                <i>скорость / курс</i>
                <span>
                  {track.speed ?? 0} Гм/ч · {pad3(track.heading || 0)}°
                </span>
                <i>сближение</i>
                <span
                  className={
                    (track.closing || 0) < 0 ? 'SensorPost__closing' : ''
                  }
                >
                  {track.closing !== undefined
                    ? `${track.closing.toFixed(2)} Гм/ч`
                    : 'нет'}
                  {track.cpa !== undefined && track.cpa_time !== undefined
                    ? ` · CPA ${track.cpa.toFixed(1)} Гм через ${clock(track.cpa_time)}`
                    : ''}
                </span>
                <i>транспондер</i>
                <span
                  className={
                    track.transponder ? 'SensorPost__good' : 'SensorPost__warn'
                  }
                >
                  {track.transponder ? 'активен' : 'молчит'}
                </span>
              </>
            )}
            {!!scan && (
              <>
                <i>масса</i>
                <span>{scan.mass} т</span>
                <i>живые сигнатуры</i>
                <span>{scan.living}</span>
                <i>двигатели</i>
                <span>
                  {scan.engines_ready}/{scan.engines}
                </span>
                {!!scan.has_hull && (
                  <>
                    <i>габарит</i>
                    <span>
                      {scan.size_x}×{scan.size_y}
                    </span>
                  </>
                )}
              </>
            )}
          </div>
          <div className="SensorPost__sig">
            {(
              [
                ['ИК', track.ir, '#ffb347'],
                ['ЭМ', track.em, '#ff5f6d'],
                ['МАССА', track.mass, '#7ad0e4'],
              ] as [string, number, string][]
            ).map(([label, value, color]) => (
              <div key={label} className="SensorPost__sig-row">
                <span>{label}</span>
                <div>
                  <b style={{ width: `${value}%`, background: color }} />
                </div>
                <span>{value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="SensorPost__actions">
        {scanningThis && !data.scan_done ? (
          <div className="SensorPost__prog">
            <b style={{ width: `${Math.round(data.scan_progress * 100)}%` }} />
            <span>
              ДЕТАЛЬНЫЙ СКАН · {Math.round(data.scan_progress * 100)}% · держите
              цель в зоне
            </span>
          </div>
        ) : scanningThis && data.scan_error ? (
          <div className="SensorPost__prog SensorPost__prog--bad">
            <span>{data.scan_error}</span>
          </div>
        ) : (
          <Button
            className="SensorPost__btn"
            disabled={!track.can_scan}
            onClick={() => act('scan', { ref: track.ref })}
          >
            {scanningThis ? 'СКАН ЗАВЕРШЁН' : 'ДЕТАЛЬНЫЙ СКАН'}
          </Button>
        )}
        {track.locked ? (
          <Button
            className="SensorPost__btn SensorPost__btn--bad"
            onClick={() => act('unlock')}
          >
            СНЯТЬ ЗАХВАТ
          </Button>
        ) : (
          <Button
            className="SensorPost__btn SensorPost__btn--pri"
            disabled={data.active_mode === 'off' || !precise}
            onClick={() => act('lock', { ref: track.ref })}
          >
            ЗАХВАТ ЦЕЛИ
          </Button>
        )}
        {scanningThis && !!data.scan_done && !!data.can_print && (
          <Button className="SensorPost__btn" onClick={() => act('print_scan')}>
            ПЕЧАТЬ
          </Button>
        )}
        {scanningThis && (
          <Button className="SensorPost__btn" onClick={() => act('close_scan')}>
            ЗАКРЫТЬ
          </Button>
        )}
      </div>
    </div>
  );
};
