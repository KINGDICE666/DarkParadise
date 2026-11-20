import { useRef, useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';
import { GalaxyLayer } from './overmap/GalaxyLayer';
import type { GalaxyMap } from './overmap/OvermapRadar';
import {
  SensorKey,
  SensorSegment,
  SensorSlider,
  SensorStepper,
} from './overmap/sensors/SensorControls';
import { SensorHelp } from './overmap/sensors/SensorHelp';
import { type ScopeLayers, SensorScope } from './overmap/sensors/SensorScope';
import {
  SensorSilhouette,
  SensorWaterfall,
} from './overmap/sensors/SensorWaterfall';
import type {
  SensorClutter,
  SensorEmission,
  SensorStatus,
  SensorTrack,
} from './overmap/sensors/types';

type JournalEntry = {
  time: string;
  text: string;
  x?: number;
  y?: number;
  name?: string;
  tone?: string;
  note?: string;
};

type ScanInfo = {
  name: string;
  mass: number;
  living: number;
  engines: number;
  engines_ready: number;
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
  sweep_period: number;
  can_run: BooleanLike;
  tracks: SensorTrack[];
  clutter: SensorClutter[];
  emission?: SensorEmission;
  status?: SensorStatus;
  gain?: number;
  suppression?: number;
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
  sector_name?: string;
  sector_id?: string;
  heading?: number;
  speed?: number;
  galaxy?: GalaxyMap;
};

const SCALES = [2, 4, 8, 12, 16];
const TABS = ['scope', 'journal', 'galaxy', 'help', 'alerts'];
const GALAXY_RADIUS = 1000;
const AIM_DELAY = 150;

const DEFAULT_LAYERS: ScopeLayers = {
  trails: true,
  iff: true,
  ebl: true,
  vrm: true,
  cpa: true,
  labels: false,
};

const pad3 = (value: number) =>
  String(Math.round((value + 360) % 360)).padStart(3, '0');

const clock = (seconds: number) =>
  `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;

const meter = (value: number) => {
  const lit = Math.round(value / 12.5);
  return '▮'.repeat(lit) + '▯'.repeat(8 - lit);
};

const threat = (track: SensorTrack) => {
  if (track.locked) return 0;
  if (track.source === 'sos') return 1;
  if (track.cpa !== undefined && track.cpa < 1) return 2;
  if (track.source === 'map') return 6;
  if (track.source === 'lost') return 5;
  if (track.name) return 4;
  return 3;
};

const trackName = (track: SensorTrack) => {
  if (track.shadow) return '---';
  if (track.name) return track.name;
  if (track.source === 'pas')
    return track.ir >= track.em ? 'ИК-ИСТОЧН.' : 'ЭМ-ИСТОЧН.';
  return 'НЕИЗВЕСТЕН';
};

export const OvermapSensors = () => {
  const { act, data } = useBackend<SensorPostData>();
  const [storedTab, setTab] = useLocalState('sensorTab', 'scope');
  const tab = TABS.includes(storedTab) ? storedTab : 'scope';
  const [scale, setScale] = useLocalState('sensorScale', 8);
  const [northUp, setNorthUp] = useLocalState('sensorNorthUp', true);
  const [brightness, setBrightness] = useLocalState('sensorBrightness', 60);
  const [layers, setLayers] = useLocalState<ScopeLayers>(
    'sensorLayers',
    DEFAULT_LAYERS,
  );
  const [query, setQuery] = useState('');
  const [aim, setAim] = useState<number | null>(null);
  const aimTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const {
    tracks = [],
    clutter = [],
    journal = [],
    status,
    emission,
    active_mode,
  } = data;

  if (!data.linked) {
    return (
      <Window title="Sensors" width={1180} height={820}>
        <Window.Content fitted className="SensorPost">
          <div className="SensorPost__nolink">
            НЕТ СВЯЗИ С СУДНОМ
            <SensorKey label="ПОДКЛЮЧИТЬСЯ" onClick={() => act('relink')} />
          </div>
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
    tracks.find((track) => track.ref === data.locked) ||
    sorted.find((track) => track.source !== 'pas');
  const activeOn = active_mode !== 'off';
  const sectorBearing = aim ?? data.sector_bearing ?? data.heading ?? 0;
  const toggleLayer = (key: keyof ScopeLayers) =>
    setLayers({ ...layers, [key]: !layers[key] });
  const stepAim = (direction: number, fine: boolean) => {
    const next = (sectorBearing + direction * (fine ? 1 : 5) + 360) % 360;
    setAim(next);
    clearTimeout(aimTimer.current);
    aimTimer.current = setTimeout(() => {
      act('aim', { bearing: next });
      setAim(null);
    }, AIM_DELAY);
  };
  const stepScale = (direction: number) => {
    const index = SCALES.indexOf(scale);
    setScale(
      SCALES[
        Math.max(
          0,
          Math.min(SCALES.length - 1, (index < 0 ? 2 : index) + direction),
        )
      ],
    );
  };
  const passiveCount = tracks.filter((track) => track.source === 'pas').length;
  const clutterNames = [...new Set(clutter.map((cloud) => cloud.name))];
  const scanningSelected =
    !!selected && !!data.scanning && data.scan_target === selected.ref;

  const statusRows: [string, string, string][] = [
    [
      'ПАССИВ',
      status?.passive === 'haywire'
        ? 'СБОЙ'
        : status?.passive === 'ok'
          ? 'НОРМА'
          : 'ВЫКЛ',
      status?.passive === 'haywire'
        ? 'alarm'
        : status?.passive === 'ok'
          ? 'lit'
          : 'quiet',
    ],
    ['РАДАР', activeOn ? 'ИЗЛУЧ.' : 'ВЫКЛ', activeOn ? 'lit' : 'quiet'],
    ['ЗАХВАТ', status?.lock || '—', status?.lock ? 'alert' : 'quiet'],
    [
      'ОБЛУЧЕНИЕ',
      status?.painted === 'lock' ? 'ЗАХВАТ' : status?.painted ? 'РАДАР' : '—',
      status?.painted ? 'alarm' : 'quiet',
    ],
    [
      'ЭМИ СБОЙ',
      status?.haywire ? clock(status.haywire) : '—',
      status?.haywire ? 'alarm' : 'quiet',
    ],
    ['ПОТЕРЯ ЦЕЛИ', status?.lost || '—', status?.lost ? 'alarm' : 'quiet'],
  ];

  const targetFields: [string, string][] = !selected
    ? []
    : selected.shadow
      ? [
          ['ПЕЛЕНГ', `${pad3(selected.bearing)}°`],
          [
            'ДАЛЬНОСТЬ',
            `${selected.range.toFixed(1)} ± ${(selected.range_err || 0).toFixed(1)} ГМ`,
          ],
          ['КУРС', '---'],
          ['СКОРОСТЬ', '---'],
          ['CPA / TCPA', '---'],
          ['КЛАСС', 'НЕТ ДАННЫХ'],
          ['ТРАНСПОНДЕР', 'НЕТ'],
          ['ИК / ЭМ / М', '-- / -- / --'],
        ]
      : [
          ['ПЕЛЕНГ', `${pad3(selected.bearing)}°`],
          [
            'ДАЛЬНОСТЬ',
            selected.range_err !== undefined
              ? `${Math.max(0, selected.range - selected.range_err).toFixed(1)}–${(selected.range + selected.range_err).toFixed(1)} ГМ`
              : `${selected.range.toFixed(2)} ГМ`,
          ],
          [
            'КУРС',
            selected.heading !== undefined
              ? `${pad3(selected.heading)}°`
              : '---',
          ],
          [
            'СКОРОСТЬ',
            selected.speed !== undefined
              ? `${selected.speed.toFixed(2)} ГМ/Ч`
              : '---',
          ],
          [
            'CPA / TCPA',
            selected.cpa !== undefined && selected.cpa_time !== undefined
              ? `${selected.cpa.toFixed(2)} · ${clock(selected.cpa_time)}`
              : '---',
          ],
          [
            'КЛАСС',
            selected.classes[0]
              ? `${selected.classes[0].label} ${selected.classes[0].chance}%`
              : '---',
          ],
          [
            'ТРАНСПОНДЕР',
            selected.transponder === undefined
              ? '---'
              : selected.transponder
                ? 'ЕСТЬ'
                : 'НЕТ',
          ],
          ['ИК / ЭМ / М', `${selected.ir} / ${selected.em} / ${selected.mass}`],
        ];

  const centerView = () => {
    if (tab === 'journal') {
      return (
        <div className="SensorPost__panel SensorPost__journal">
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
                <div
                  key={index}
                  className={`SensorPost__journal-row SensorPost__tone--${entry.tone || 'info'}`}
                >
                  <span>{entry.time}</span>
                  <span>
                    {entry.text}
                    {entry.note ? ` · ${entry.note}` : ''}
                  </span>
                  {entry.x !== undefined && (
                    <span>
                      [{entry.x}:{entry.y}]
                    </span>
                  )}
                </div>
              ))}
            {!journal.length && <div>ЖУРНАЛ ПУСТ</div>}
          </div>
          <div className="SensorPost__journal-tools">
            {!!data.can_dump &&
              (data.dump_loaded ? (
                <>
                  <SensorKey
                    label={`ВЫГРУЗИТЬ ДАМП ${data.known_count || 0}`}
                    onClick={() => act('dump_write')}
                  />
                  <SensorKey
                    label={`ЗАГРУЗИТЬ ${data.dump_has_data ? data.dump_count : ''}`}
                    disabled={!data.dump_has_data}
                    onClick={() => act('dump_load')}
                  />
                  <SensorKey
                    label="ДОСТАТЬ ЛИСТ"
                    onClick={() => act('dump_eject')}
                  />
                </>
              ) : (
                <SensorKey
                  label="ВСТАВЬТЕ БУМАГУ"
                  disabled
                  onClick={() => {}}
                />
              ))}
            <input
              className="SensorPost__search"
              placeholder="ПОИСК ПО ЖУРНАЛУ"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </div>
        </div>
      );
    }
    if (tab === 'galaxy') {
      return (
        <div className="SensorPost__panel SensorPost__galaxy">
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
            <div>КАРТА НЕДОСТУПНА</div>
          )}
        </div>
      );
    }
    if (tab === 'help') {
      return (
        <div className="SensorPost__panel">
          <SensorHelp />
        </div>
      );
    }
    if (tab === 'alerts') {
      return (
        <div className="SensorPost__panel SensorPost__alerts">
          {(data.alerts || []).map((alert) => (
            <SensorKey
              key={alert.id}
              label={alert.label}
              value={alert.on ? 'ЗВУК' : 'ТИХО'}
              on={!!alert.on}
              onClick={() => act('toggle_alert', { id: alert.id })}
            />
          ))}
        </div>
      );
    }
    return (
      <>
        <div className="SensorPost__scope">
          {data.map_jammed ? (
            <div className="SensorPost__jam">ПОМЕХИ ГИПЕРТРАНСЛЯТОРА</div>
          ) : (
            <SensorScope
              tracks={tracks}
              clutter={clutter}
              scale={scale}
              northUp={northUp}
              heading={data.heading || 0}
              speed={data.speed || 0}
              activeMode={active_mode}
              sectorBearing={
                active_mode === 'sector' ? sectorBearing : undefined
              }
              passiveOn={!!data.passive_on}
              sweepPeriod={data.sweep_period}
              brightness={brightness}
              layers={layers}
              selected={selected?.ref}
              locked={data.locked}
              onSelect={(ref) => act('select', { ref })}
              onAim={(bearing) => act('aim', { bearing })}
            />
          )}
          <div className="SensorPost__corner SensorPost__corner--tl">
            ШКАЛА {scale.toFixed(1)} ГМ
            <br />
            КОЛЬЦА {(scale / 4).toFixed(1)} ГМ
            <br />
            {northUp ? 'СЕВЕР ВВЕРХ' : 'КУРС ВВЕРХ'}
            <br />
            {active_mode === 'sector'
              ? `СЕКТОР ${pad3(sectorBearing)}° ±30°`
              : 'ОТН. ДВИЖЕНИЕ'}
          </div>
          <div className="SensorPost__corner SensorPost__corner--tr">
            КУРС {pad3(data.heading || 0)}.0°
            <br />
            СКОР {(data.speed || 0).toFixed(2)} ГМ/Ч
            <br />
            ПЕЛ ЛИН{' '}
            {selected && layers.ebl ? `${pad3(selected.bearing)}°` : '---'}
            <br />
            ДАЛЬН КР{' '}
            {selected && layers.vrm ? `${selected.range.toFixed(2)} ГМ` : '---'}
          </div>
          <div className="SensorPost__corner SensorPost__corner--bl">
            {activeOn
              ? `РАДАР ${active_mode === 'sector' ? 'СЕКТОР' : 'КРУГ'} · ${data.sweep_period.toFixed(1)} С`
              : 'РАДАР ВЫКЛ'}
            <br />
            ПАССИВ · {passiveCount} ПЕЛЕНГ.
            {!!clutterNames.length && (
              <>
                <br />
                ЭХО: {clutterNames.slice(0, 2).join(', ')}
              </>
            )}
          </div>
          {!!status?.lost && (
            <div className="SensorPost__corner SensorPost__corner--br SensorPost__alarm">
              ПОТЕРЯ ЦЕЛИ {status.lost}
            </div>
          )}
        </div>
        <div className="SensorPost__fall">
          <div className="SensorPost__fall-axis">
            {[
              '000',
              '045',
              '090',
              '135',
              '180',
              '225',
              '270',
              '315',
              '360',
            ].map((mark) => (
              <span key={mark}>{mark}</span>
            ))}
          </div>
          <div className="SensorPost__fall-plot">
            <SensorWaterfall
              tracks={tracks}
              clutter={clutter}
              live={!!data.passive_on || activeOn}
              haywire={!!data.haywire}
              gain={data.gain}
            />
          </div>
        </div>
      </>
    );
  };

  return (
    <Window title="Sensors" width={1180} height={820}>
      <Window.Content fitted className="SensorPost">
        <div className="SensorPost__left">
          <div className="SensorPost__group">
            <div className="SensorPost__caption">ИСТОЧНИКИ</div>
            <SensorKey
              label="ТЕПЛ. ПАССИВ"
              value={
                data.has_short ? (data.passive_on ? 'ВКЛ' : 'ВЫКЛ') : 'НЕТ'
              }
              on={!!data.passive_on}
              disabled={!data.has_short}
              onClick={() => act('toggle_passive')}
            />
            <SensorKey
              label="РАДАР"
              value={data.has_long ? (activeOn ? 'ИЗЛ' : 'ВЫКЛ') : 'НЕТ'}
              on={activeOn}
              disabled={!data.has_long}
              onClick={() =>
                act('set_active', { mode: activeOn ? 'off' : 'circle' })
              }
            />
            <div className="SensorPost__caption">РЕЖИМ ЛУЧА</div>
            <SensorSegment
              value={active_mode === 'sector' ? 'sector' : 'circle'}
              disabled={!activeOn}
              options={[
                { id: 'circle', label: 'КРУГ' },
                { id: 'sector', label: 'СЕКТОР' },
              ]}
              onChange={(mode) => act('set_active', { mode })}
            />
          </div>
          <div className="SensorPost__group">
            <div className="SensorPost__caption">РЕГУЛИРОВКА</div>
            <SensorSlider
              label="УСИЛЕНИЕ"
              value={data.gain ?? 50}
              onChange={(value) => act('set_gain', { value })}
            />
            <SensorSlider
              label="ПОДАВЛ. ПОЛЯ"
              value={data.suppression ?? 30}
              onChange={(value) => act('set_suppression', { value })}
            />
            <SensorSlider
              label="ЯРКОСТЬ ЭХА"
              value={brightness}
              onChange={setBrightness}
            />
            <div className="SensorPost__caption">АЗИМУТ СЕКТОРА</div>
            <SensorStepper
              value={
                active_mode === 'sector' ? `${pad3(sectorBearing)}°` : '---°'
              }
              disabled={active_mode !== 'sector'}
              onStep={stepAim}
            />
          </div>
          <div className="SensorPost__group">
            <div className="SensorPost__caption">ШКАЛА / ОРИЕНТ.</div>
            <SensorStepper
              value={`${scale} ГМ`}
              minusLabel="−"
              plusLabel="+"
              onStep={(direction) => stepScale(direction)}
            />
            <SensorSegment
              value={northUp ? 'north' : 'course'}
              options={[
                { id: 'north', label: 'СЕВЕР' },
                { id: 'course', label: 'КУРС' },
              ]}
              onChange={(id) => setNorthUp(id === 'north')}
            />
          </div>
          <div className="SensorPost__group SensorPost__group--grow">
            <div className="SensorPost__caption">СТАТУС</div>
            {statusRows.map(([label, value, tone]) => (
              <div key={label} className="SensorPost__status">
                <span>{label}</span>
                <span
                  className={`SensorPost__state SensorPost__state--${tone}`}
                >
                  {value}
                </span>
              </div>
            ))}
            {!!emission && (
              <>
                <div className="SensorPost__caption">
                  ЗАМЕТНОСТЬ · {emission.level}
                </div>
                {(
                  [
                    ['ИК', emission.ir],
                    ['ЭМ', emission.em],
                    ['МАССА', emission.mass],
                  ] as [string, number][]
                ).map(([label, value]) => (
                  <div key={label} className="SensorPost__meter">
                    <span>{label}</span>
                    <span>{meter(value)}</span>
                    <span>{value}</span>
                  </div>
                ))}
              </>
            )}
          </div>
        </div>
        <div className="SensorPost__center">{centerView()}</div>
        <div className="SensorPost__right">
          <div className="SensorPost__keys">
            {(
              [
                ['scope', 'ТРЕКИ'],
                ['journal', 'ЖУРНАЛ'],
                ['galaxy', 'ГАЛАКТИКА'],
                ['help', 'СПРАВКА'],
              ] as [string, string][]
            ).map(([id, label]) => (
              <SensorKey
                key={id}
                label={label}
                on={tab === id}
                onClick={() => setTab(id)}
              />
            ))}
            {(
              [
                ['trails', 'СЛЕДЫ'],
                ['iff', 'IFF'],
                ['ebl', 'ПЕЛ ЛИН'],
                ['vrm', 'ДАЛЬН КР'],
                ['cpa', 'CPA'],
                ['labels', 'ПОДПИСИ'],
              ] as [keyof ScopeLayers, string][]
            ).map(([key, label]) => (
              <SensorKey
                key={key}
                label={label}
                on={layers[key]}
                onClick={() => toggleLayer(key)}
              />
            ))}
            <SensorKey
              label="ОПОВЕЩЕНИЯ"
              on={tab === 'alerts'}
              onClick={() => setTab('alerts')}
            />
          </div>
          <div className="SensorPost__target">
            {selected ? (
              <>
                <div className="SensorPost__target-head">
                  <span>
                    ЦЕЛЬ {selected.id.replace('T-', '')} ·{' '}
                    {selected.source === 'pas' ? 'ПАС' : 'АКТ'}
                  </span>
                  <span
                    className={
                      selected.shadow ? 'SensorPost__alarm' : undefined
                    }
                  >
                    {selected.shadow
                      ? 'НЕУСТОЙЧИВ'
                      : selected.locked
                        ? 'ЗАХВАЧЕНА'
                        : `КАЧ ${selected.quality}%`}
                  </span>
                </div>
                {targetFields.map(([label, value]) => (
                  <div key={label} className="SensorPost__field">
                    <span>{label}</span>
                    <span>{value}</span>
                  </div>
                ))}
                {scanningSelected && (
                  <div className="SensorPost__scanbox">
                    <SensorSilhouette
                      tiles={data.silhouette}
                      progress={data.scan_progress}
                      done={!!data.scan_done}
                    />
                    <div>
                      {data.scan_error ? (
                        <span className="SensorPost__alarm">
                          {data.scan_error}
                        </span>
                      ) : data.scan_done && data.scan ? (
                        <>
                          МАССА {data.scan.mass} Т<br />
                          ЭКИПАЖ {data.scan.living}
                          <br />
                          ДВИГ {data.scan.engines_ready}/{data.scan.engines}
                          {!!data.scan.has_hull && (
                            <>
                              <br />
                              КОРПУС {data.scan.size_x}×{data.scan.size_y}
                            </>
                          )}
                        </>
                      ) : (
                        `СКАН ${Math.round(data.scan_progress * 100)}%`
                      )}
                      {!!data.scan_done && !!data.can_print && (
                        <SensorKey
                          label="ПЕЧАТЬ"
                          onClick={() => act('print_scan')}
                        />
                      )}
                    </div>
                  </div>
                )}
              </>
            ) : (
              <div className="SensorPost__dim">ЦЕЛЬ НЕ ВЫБРАНА</div>
            )}
          </div>
          <div className="SensorPost__list">
            <div className="SensorPost__list-row SensorPost__list-head">
              <span>№</span>
              <span>ОБЪЕКТ</span>
              <span>ПЕЛ</span>
              <span>ДАЛЬН</span>
              <span>КАЧ</span>
            </div>
            {sorted.map((track) => (
              <button
                type="button"
                key={track.ref}
                className={`SensorPost__list-row${track.ref === selected?.ref ? ' is-on' : ''}${track.source === 'lost' ? ' is-lost' : ''}`}
                onClick={() => act('select', { ref: track.ref })}
              >
                <span>{track.id.replace('T-', '')}</span>
                <span>{trackName(track)}</span>
                <span>{pad3(track.bearing)}</span>
                <span>
                  {track.source === 'pas'
                    ? '---'
                    : track.shadow
                      ? `${track.range.toFixed(1)}±`
                      : track.range.toFixed(2)}
                </span>
                <span>{track.quality}</span>
              </button>
            ))}
            {!sorted.length && (
              <div className="SensorPost__dim">
                {data.can_run ? 'НЕТ КОНТАКТОВ' : 'НЕТ МАССИВОВ'}
              </div>
            )}
          </div>
          <div className="SensorPost__actions">
            {selected?.locked ? (
              <SensorKey
                big
                on
                label="СНЯТЬ ЗАХВАТ"
                onClick={() => act('unlock')}
              />
            ) : (
              <SensorKey
                big
                label="ЗАХВАТ"
                disabled={!selected || !activeOn || selected.source === 'pas'}
                onClick={() => selected && act('lock', { ref: selected.ref })}
              />
            )}
            {scanningSelected && data.scan_done ? (
              <SensorKey
                big
                label="ЗАКРЫТЬ СКАН"
                onClick={() => act('close_scan')}
              />
            ) : (
              <SensorKey
                big
                on={scanningSelected}
                label={
                  scanningSelected
                    ? `СКАН ${Math.round(data.scan_progress * 100)}%`
                    : selected?.can_scan
                      ? 'СКАН'
                      : 'СКАН ---'
                }
                disabled={!selected?.can_scan && !scanningSelected}
                onClick={() =>
                  scanningSelected
                    ? act('close_scan')
                    : selected && act('scan', { ref: selected.ref })
                }
              />
            )}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
