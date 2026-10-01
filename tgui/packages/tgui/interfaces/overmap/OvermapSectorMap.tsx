import { useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

export type SectorObject = {
  name: string;
  kind: string;
  x: number;
  y: number;
  color?: string | null;
  is_self?: BooleanLike;
  heading?: number;
  distress?: BooleanLike;
  size?: number;
  leads_to?: string | null;
};

const MAP_PAD = 1.4;

export const overmapObjectLabel = (object: SectorObject) => {
  if (object.kind === 'relay' && object.leads_to) {
    return `Ретранслятор → ${object.leads_to}`;
  }
  return object.name;
};

const Glyph = (props: { object: SectorObject; radius: number }) => {
  const { object, radius } = props;
  const color = object.color || '#d8e6ea';
  switch (object.kind) {
    case 'station':
      return (
        <rect
          className="OvermapSector__glyph"
          x={-radius}
          y={-radius}
          width={radius * 2}
          height={radius * 2}
          fill={color}
        />
      );
    case 'relay':
      return (
        <rect
          className="OvermapSector__glyph"
          x={-radius * 0.8}
          y={-radius * 0.8}
          width={radius * 1.6}
          height={radius * 1.6}
          fill={color}
          transform="rotate(45)"
        />
      );
    case 'shuttle':
    case 'pod':
      return (
        <polygon
          className="OvermapSector__glyph"
          points={`0,${-radius * 1.2} ${radius},${radius} 0,${radius * 0.5} ${-radius},${radius}`}
          fill={color}
          transform={`rotate(${object.heading || 0})`}
        />
      );
    case 'ruin':
      return (
        <rect
          className="OvermapSector__glyph OvermapSector__glyph--hollow"
          x={-radius * 0.8}
          y={-radius * 0.8}
          width={radius * 1.6}
          height={radius * 1.6}
          stroke={color}
        />
      );
    case 'portal':
      return (
        <circle
          className="OvermapSector__glyph OvermapSector__glyph--hollow"
          r={radius}
          stroke={color}
        />
      );
    default:
      return (
        <>
          <circle
            className="OvermapSector__glyph OvermapSector__glyph--hollow"
            r={radius}
            stroke="#d8e6ea"
          />
          <text
            className="OvermapSector__unknown"
            fontSize={radius * 1.4}
            textAnchor="middle"
            dominantBaseline="central"
          >
            ?
          </text>
        </>
      );
  }
};

export const OvermapSectorMap = (props: {
  size: number;
  objects: SectorObject[];
  self?: number[];
  facing: number;
  viewRange?: number;
  dest?: number[];
  destName?: string;
  onPick: (x: number, y: number, name?: string) => void;
}) => {
  const { size, objects, self, facing, viewRange, dest, destName, onPick } =
    props;
  const [hover, setHover] = useState<string>();
  const toU = (x: number) => x - 0.5;
  const toV = (y: number) => size - (y - 0.5);
  const font = Math.max(size * 0.024, 0.45);
  const radius = Math.max(size * 0.012, 0.28);
  const lines: number[] = [];
  for (let line = 0; line <= size; line++) {
    lines.push(line);
  }
  const terrain = objects.filter((object) => object.kind === 'planet');
  const hazards = objects.filter((object) => object.kind === 'hazard');
  const markers = objects.filter(
    (object) =>
      !object.is_self && object.kind !== 'planet' && object.kind !== 'hazard',
  );
  const destMarked =
    !!dest &&
    markers.some((object) => object.x === dest[0] && object.y === dest[1]);
  const pickCell = (event: React.MouseEvent<SVGSVGElement>) => {
    const svg = event.currentTarget;
    const point = svg.createSVGPoint();
    point.x = event.clientX;
    point.y = event.clientY;
    const local = point.matrixTransform(svg.getScreenCTM()?.inverse());
    const cellX = Math.floor(local.x) + 1;
    const cellY = size - Math.floor(local.y);
    if (cellX < 1 || cellY < 1 || cellX > size || cellY > size) {
      return;
    }
    onPick(cellX, cellY);
  };
  return (
    <svg
      className="OvermapSector"
      viewBox={`${-MAP_PAD} ${-0.4} ${size + MAP_PAD + 0.4} ${size + MAP_PAD}`}
      preserveAspectRatio="xMidYMid meet"
      onClick={pickCell}
    >
      <rect className="OvermapSector__space" width={size} height={size} />
      {lines.map((line) => (
        <g key={line}>
          <line
            className={
              line % 5 ? 'OvermapSector__grid' : 'OvermapSector__grid--major'
            }
            x1={line}
            y1={0}
            x2={line}
            y2={size}
          />
          <line
            className={
              line % 5 ? 'OvermapSector__grid' : 'OvermapSector__grid--major'
            }
            x1={0}
            y1={line}
            x2={size}
            y2={line}
          />
          {line > 0 && (line % 5 === 0 || line === 1) && (
            <>
              <text
                className="OvermapSector__coord"
                x={toU(line)}
                y={size + font * 1.3}
                fontSize={font * 0.8}
                textAnchor="middle"
              >
                {line}
              </text>
              <text
                className="OvermapSector__coord"
                x={-font * 0.6}
                y={toV(line)}
                fontSize={font * 0.8}
                textAnchor="end"
                dominantBaseline="central"
              >
                {line}
              </text>
            </>
          )}
        </g>
      ))}
      {hazards.map((hazard) => (
        <rect
          key={`${hazard.x}-${hazard.y}`}
          className="OvermapSector__hazard"
          x={hazard.x - 1}
          y={size - hazard.y}
          width={1}
          height={1}
          style={hazard.color ? { fill: hazard.color } : undefined}
        >
          <title>{`${hazard.name} (${hazard.x}:${hazard.y})`}</title>
        </rect>
      ))}
      {!!self && !!viewRange && (
        <circle
          className="OvermapSector__sensors"
          cx={toU(self[0])}
          cy={toV(self[1])}
          r={viewRange + 0.5}
        />
      )}
      {terrain.map((planet) => {
        const half = (planet.size || 1) / 2;
        return (
          <g key={`${planet.name}-${planet.x}-${planet.y}`}>
            <circle
              className="OvermapSector__planet"
              cx={planet.x - 1 + half}
              cy={size - (planet.y - 1 + half)}
              r={half * 0.95}
            />
            <text
              className="OvermapSector__label OvermapSector__label--planet"
              x={planet.x - 1 + half}
              y={size - (planet.y - 1) + font * 1.1}
              fontSize={font}
              textAnchor="middle"
            >
              {planet.name}
            </text>
          </g>
        );
      })}
      {!!self && !!dest && (
        <line
          className="OvermapSector__route"
          x1={toU(self[0])}
          y1={toV(self[1])}
          x2={toU(dest[0])}
          y2={toV(dest[1])}
          strokeDasharray={`${font * 0.6} ${font * 0.4}`}
        />
      )}
      {markers.map((object) => {
        const key = `${object.kind}-${object.name}-${object.x}-${object.y}`;
        const label = overmapObjectLabel(object);
        const hovered = hover === key;
        return (
          <g
            key={key}
            className="OvermapSector__marker"
            transform={`translate(${toU(object.x)} ${toV(object.y)})`}
            onMouseEnter={() => setHover(key)}
            onMouseLeave={() => setHover(undefined)}
            onClick={(event) => {
              event.stopPropagation();
              onPick(object.x, object.y, label);
            }}
          >
            <title>{`${label} (${object.x}:${object.y}) — клик: сделать целью`}</title>
            <rect
              className="OvermapSector__hit"
              x={-0.5}
              y={-0.5}
              width={1}
              height={1}
            />
            {hovered && (
              <circle className="OvermapSector__hoverRing" r={radius * 2.2} />
            )}
            <Glyph object={object} radius={radius} />
            <text
              className={
                object.distress
                  ? 'OvermapSector__label OvermapSector__label--sos'
                  : 'OvermapSector__label'
              }
              x={radius * 1.8}
              y={0}
              fontSize={font}
              dominantBaseline="central"
            >
              {object.distress ? `SOS · ${label}` : label}
            </text>
          </g>
        );
      })}
      {!!dest && (
        <g
          className="OvermapSector__dest"
          transform={`translate(${toU(dest[0])} ${toV(dest[1])})`}
        >
          <circle r={radius * 2.4} />
          <line x1={-radius * 3.2} y1={0} x2={radius * 3.2} y2={0} />
          <line x1={0} y1={-radius * 3.2} x2={0} y2={radius * 3.2} />
          <text
            className="OvermapSector__destLabel"
            y={-radius * 3.6}
            fontSize={font}
            textAnchor="middle"
          >
            {destName && !destMarked ? `ЦЕЛЬ: ${destName}` : 'ЦЕЛЬ'}
          </text>
        </g>
      )}
      {!!self && (
        <g
          className="OvermapSector__self"
          transform={`translate(${toU(self[0])} ${toV(self[1])})`}
        >
          <circle className="OvermapSector__selfHalo" r={radius * 2.6} />
          <polygon
            points={`0,${-radius * 2} ${radius * 1.4},${radius * 1.4} 0,${radius * 0.6} ${-radius * 1.4},${radius * 1.4}`}
            transform={`rotate(${facing})`}
          />
          <text
            className="OvermapSector__selfLabel"
            y={radius * 4.2}
            fontSize={font}
            textAnchor="middle"
          >
            ВЫ
          </text>
        </g>
      )}
    </svg>
  );
};
