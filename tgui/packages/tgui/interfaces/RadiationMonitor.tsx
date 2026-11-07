import { useMemo, useRef, useState } from 'react';
import { NanoMap } from 'tgui/components';
import { Icon } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  dangerStatus,
  RAD_COLORS,
  STAGE_COLORS,
  STAGE_NAMES,
  statusClass,
} from './common/RadiationInstruments';

type Meter = {
  uid: string;
  holder: string | null;
  mounted: BooleanLike;
  area: string;
  department: string | null;
  x: number;
  y: number;
  z: number;
  rate: number;
  total: number;
  stage: number;
  bearing: number | null;
};

/** x, y, ширина, z */
type Span = [number, number, number, number];

type Department = {
  id: string;
  name: string;
  color: string;
  spans: Span[];
};

type Data = {
  stationLevelNum: number[];
  stationLevelName: string[];
  departments: Department[];
  meters: Meter[];
  evacuating: string[];
  authorized: BooleanLike;
  announce_ready: BooleanLike;
};

type Point = { x: number; y: number };

const MAP_TURFS = 255;
const RAY_LENGTH = 60;
const MINIMUM_SIGNAL = 1;
const CLICK_DRIFT = 4;

const bearingVector = (bearing: number): Point => {
  const radians = (bearing * Math.PI) / 180;
  return { x: Math.sin(radians), y: Math.cos(radians) };
};

/** Источник находится там, где пересекаются лучи приборов */
const triangulate = (meters: Meter[]): Point | null => {
  const heard = meters.filter(
    (meter) => meter.bearing !== null && meter.rate >= MINIMUM_SIGNAL,
  );
  const crossings: Point[] = [];
  for (let first = 0; first < heard.length; first++) {
    for (let second = first + 1; second < heard.length; second++) {
      const a = heard[first];
      const b = heard[second];
      const aRay = bearingVector(a.bearing as number);
      const bRay = bearingVector(b.bearing as number);
      const denominator = aRay.x * bRay.y - aRay.y * bRay.x;
      if (Math.abs(denominator) < 0.05) {
        continue;
      }
      const aDistance =
        ((b.x - a.x) * bRay.y - (b.y - a.y) * bRay.x) / denominator;
      const bDistance =
        ((b.x - a.x) * aRay.y - (b.y - a.y) * aRay.x) / denominator;
      if (aDistance < 0 || bDistance < 0) {
        continue;
      }
      crossings.push({
        x: a.x + aRay.x * aDistance,
        y: a.y + aRay.y * aDistance,
      });
    }
  }
  if (!crossings.length) {
    return null;
  }
  const middle = (values: number[]) =>
    values.sort((left, right) => left - right)[Math.floor(values.length / 2)];
  return {
    x: middle(crossings.map((point) => point.x)),
    y: middle(crossings.map((point) => point.y)),
  };
};

type LayerProps = {
  departments: Department[];
  zCurrent: number;
  onSelect: (id: string) => void;
};

/** Полосы пола меняются только вместе с уровнем, поэтому не перерисовываются при обновлении данных */
const DepartmentLayer = (props: LayerProps) => {
  const { departments, zCurrent, onSelect } = props;
  const pressed = useRef<Point>({ x: 0, y: 0 });

  return useMemo(
    () => (
      <svg
        className="RadScope__layer"
        viewBox={`0 0 ${MAP_TURFS} ${MAP_TURFS}`}
        shapeRendering="crispEdges"
        onMouseDown={(event) => {
          pressed.current = { x: event.clientX, y: event.clientY };
        }}
      >
        {departments.map((department) => (
          <g
            key={department.id}
            id={`rad-department-${department.id}`}
            fill={department.color}
            className="RadScope__department"
            onClick={(event) => {
              const drift =
                Math.abs(event.clientX - pressed.current.x) +
                Math.abs(event.clientY - pressed.current.y);
              if (drift < CLICK_DRIFT) {
                onSelect(department.id);
              }
            }}
          >
            {department.spans
              .filter((span) => span[3] === zCurrent)
              .map((span) => (
                <rect
                  key={`${span[0]}-${span[1]}`}
                  x={span[0] - 1}
                  y={MAP_TURFS - span[1]}
                  width={span[2]}
                  height={1}
                />
              ))}
          </g>
        ))}
      </svg>
    ),
    [departments, zCurrent],
  );
};

type OverlayProps = {
  selected: string | null;
  evacuating: string[];
  meters: Meter[];
  source: Point | null;
};

const SignalOverlay = (props: OverlayProps) => {
  const { selected, evacuating, meters, source } = props;
  const rays = meters.filter(
    (meter) => meter.bearing !== null && meter.rate >= MINIMUM_SIGNAL,
  );
  return (
    <>
      <style>
        {[
          selected
            ? `#rad-department-${selected} { fill-opacity: 0.5; }`
            : '',
          ...evacuating.map(
            (id) =>
              `#rad-department-${id} { animation: RadScope-evacuate 1.2s infinite; }`,
          ),
        ].join('\n')}
      </style>
      <svg
        className="RadScope__layer RadScope__layer--passive"
        viewBox={`0 0 ${MAP_TURFS} ${MAP_TURFS}`}
      >
        {rays.map((meter) => {
          const ray = bearingVector(meter.bearing as number);
          return (
            <line
              key={meter.uid}
              x1={meter.x - 0.5}
              y1={MAP_TURFS - meter.y + 0.5}
              x2={meter.x - 0.5 + ray.x * RAY_LENGTH}
              y2={MAP_TURFS - meter.y + 0.5 - ray.y * RAY_LENGTH}
              stroke={
                [RAD_COLORS.good, RAD_COLORS.warn, RAD_COLORS.bad][
                  dangerStatus(meter.rate)
                ]
              }
              strokeOpacity="0.65"
              strokeWidth="0.5"
              strokeDasharray="2 1.5"
            />
          );
        })}
        {source && (
          <g>
            <circle
              className="RadScope__pulse"
              cx={source.x - 0.5}
              cy={MAP_TURFS - source.y + 0.5}
              r="5"
              fill="none"
              stroke={RAD_COLORS.bad}
              strokeWidth="0.7"
            />
            <path
              d={`M ${source.x - 2.5} ${MAP_TURFS - source.y + 0.5} h 4 M ${source.x - 0.5} ${MAP_TURFS - source.y - 1.5} v 4`}
              stroke={RAD_COLORS.bad}
              strokeWidth="0.7"
            />
          </g>
        )}
      </svg>
    </>
  );
};

export const RadiationMonitor = () => {
  const { act, data } = useBackend<Data>();
  const {
    stationLevelNum,
    stationLevelName,
    departments,
    meters,
    evacuating,
    authorized,
    announce_ready,
  } = data;
  const [zCurrent, setZCurrent] = useState(stationLevelNum[0]);
  const [zoom, setZoom] = useState(1);
  const [selected, setSelected] = useState<string | null>(null);
  const [armed, setArmed] = useState(false);
  const [tab, setTab] = useState<'departments' | 'meters'>('departments');

  const levelMeters = meters.filter((meter) => meter.z === zCurrent);
  const source = triangulate(levelMeters);
  const current = departments.find((department) => department.id === selected);
  const currentMeters = meters.filter((meter) => meter.department === selected);
  const isEvacuating = !!selected && evacuating.includes(selected);
  const sortedMeters = [...meters].sort((a, b) => b.rate - a.rate);

  const peakRate = (id: string) =>
    meters
      .filter((meter) => meter.department === id)
      .reduce((highest, meter) => Math.max(highest, meter.rate), 0);

  const selectDepartment = (id: string) => {
    setSelected(id);
    setArmed(false);
    setTab('departments');
  };

  return (
    <Window width={1120} height={700}>
      <Window.Content>
        <div className="RadScope">
          <div
            className="RadScope__grid"
            style={{ gridTemplateColumns: 'minmax(0, 1.75fr) minmax(0, 1fr)' }}
          >
            <div className="RadScope__panel" style={{ padding: 0 }}>
              <NanoMap
                zoom={zoom}
                zNames={stationLevelName}
                zLevels={stationLevelNum}
                zCurrent={zCurrent}
                setZCurrent={setZCurrent}
                onZoom={(_event, value) => setZoom(value)}
              >
                <DepartmentLayer
                  departments={departments}
                  zCurrent={zCurrent}
                  onSelect={selectDepartment}
                />
                <SignalOverlay
                  selected={selected}
                  evacuating={evacuating}
                  meters={levelMeters}
                  source={source}
                />
                {levelMeters.map((meter) => (
                  <NanoMap.MarkerIcon
                    key={meter.uid}
                    x={meter.x}
                    y={meter.y}
                    z={meter.z}
                    z_current={zCurrent}
                    zoom={zoom}
                    icon={meter.mounted ? 'tower-broadcast' : 'user'}
                    color={
                      ['green', 'orange', 'red'][dangerStatus(meter.rate)]
                    }
                    tooltip={`${meter.holder || meter.area}: ${meter.rate.toFixed(1)} рад/мин`}
                    tooltipPosition={meter.x > MAP_TURFS / 2 ? 'left' : 'right'}
                  />
                ))}
              </NanoMap>
            </div>

            <div className="RadScope__panel">
              <div className="RadScope__tabs">
                <button
                  className={`RadScope__button${tab === 'departments' ? ' RadScope__button--active' : ''}`}
                  onClick={() => setTab('departments')}
                >
                  <Icon name="sitemap" mr={1} />
                  Отделы
                </button>
                <button
                  className={`RadScope__button${tab === 'meters' ? ' RadScope__button--active' : ''}`}
                  onClick={() => setTab('meters')}
                >
                  <Icon name="radiation" mr={1} />
                  Приборы ({meters.length})
                </button>
                {!authorized && (
                  <span className="RadScope__warn" style={{ marginLeft: 'auto' }}>
                    <Icon name="lock" />
                  </span>
                )}
              </div>

              {tab === 'departments' && (
                <>
                  <div className="RadScope__scroll">
                    <table className="RadScope__table">
                      <tbody>
                        {departments.map((department) => {
                          const rate = peakRate(department.id);
                          return (
                            <tr
                              key={department.id}
                              className={`RadScope__clickable${department.id === selected ? ' RadScope__selected' : ''}`}
                              onClick={() => selectDepartment(department.id)}
                            >
                              <td>
                                <span
                                  className="RadScope__swatch"
                                  style={{ background: department.color }}
                                />
                                {department.name}
                                {evacuating.includes(department.id) && (
                                  <span
                                    className="RadScope__bad"
                                    style={{ marginLeft: '6px' }}
                                  >
                                    <Icon name="person-running" />
                                  </span>
                                )}
                              </td>
                              <td
                                className={statusClass(dangerStatus(rate))}
                                style={{ textAlign: 'right' }}
                              >
                                {rate.toFixed(1)}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>

                  {current ? (
                    <div className="RadScope__selection">
                      <div className="RadScope__title">
                        <span style={{ color: current.color }}>
                          {current.name}
                        </span>
                        <span>Приборов: {currentMeters.length}</span>
                      </div>
                      {isEvacuating ? (
                        <button
                          className="RadScope__button RadScope__button--wide"
                          disabled={!authorized}
                          onClick={() =>
                            act('cancel_evacuation', { department: selected })
                          }
                        >
                          <Icon name="circle-check" mr={1} />
                          Дать отбой эвакуации
                        </button>
                      ) : (
                        <button
                          className="RadScope__button RadScope__button--wide RadScope__button--danger"
                          disabled={!authorized || !announce_ready}
                          onClick={() => {
                            if (!armed) {
                              setArmed(true);
                              return;
                            }
                            setArmed(false);
                            act('evacuate', { department: selected });
                          }}
                        >
                          <Icon name="person-running" mr={1} />
                          {armed ? 'Точно объявить?' : 'Объявить эвакуацию'}
                        </button>
                      )}
                    </div>
                  ) : (
                    <div
                      className="RadScope__muted"
                      style={{ marginTop: '8px', textAlign: 'center' }}
                    >
                      Выберите отдел на карте или в списке.
                    </div>
                  )}
                </>
              )}

              {tab === 'meters' && (
                <div className="RadScope__scroll">
                  <table className="RadScope__table">
                    <thead>
                      <tr>
                        <th>Прибор</th>
                        <th>рад/мин</th>
                        <th>Доза</th>
                        <th />
                      </tr>
                    </thead>
                    <tbody>
                      {sortedMeters.map((meter) => (
                        <tr key={meter.uid}>
                          <td>
                            <div>
                              <Icon
                                name={
                                  meter.mounted ? 'tower-broadcast' : 'user'
                                }
                                mr={1}
                              />
                              {meter.holder ||
                                (meter.mounted ? 'На стене' : 'Без владельца')}
                            </div>
                            <div className="RadScope__muted">{meter.area}</div>
                          </td>
                          <td className={statusClass(dangerStatus(meter.rate))}>
                            {meter.rate.toFixed(1)}
                          </td>
                          <td style={{ color: STAGE_COLORS[meter.stage] }}>
                            {meter.total}
                            <div style={{ fontSize: '10px' }}>
                              {STAGE_NAMES[meter.stage]}
                            </div>
                          </td>
                          <td style={{ textAlign: 'right' }}>
                            <button
                              className="RadScope__button"
                              disabled={!authorized}
                              onClick={() =>
                                act('reset_meter', { uid: meter.uid })
                              }
                            >
                              Сброс
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {!meters.length && (
                    <div className="RadScope__muted" style={{ padding: '12px' }}>
                      На станции нет включённых приборов.
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
