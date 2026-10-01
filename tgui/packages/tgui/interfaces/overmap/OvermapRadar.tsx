import { useMemo, useState } from 'react';
import { OvermapSeg } from './OvermapChrome';

export type RadarShape = {
  tiles: number[];
  collars: number[];
};

export type RadarTerrain = {
  x: number;
  y: number;
  cells: number[];
};

export type RadarContact = {
  id: string;
  name?: string;
  x: number;
  y: number;
  rot: number;
  own?: boolean;
  distance?: number;
  closing?: number;
  docked?: boolean;
};

const RADAR_RANGES = ['16', '32', '64'] as const;
type RadarRange = (typeof RADAR_RANGES)[number];

const cellsPath = (cells: number[]) => {
  let path = '';
  for (let i = 0; i + 1 < cells.length; i += 2) {
    path += `M${cells[i] / 2 - 0.5} ${cells[i + 1] / 2 - 0.5}h1v1h-1z`;
  }
  return path;
};

const RadarHull = (props: { shape?: RadarShape; contact: RadarContact }) => {
  const { shape, contact } = props;
  const hull = useMemo(() => cellsPath(shape?.tiles || []), [shape]);
  const collars = useMemo(() => cellsPath(shape?.collars || []), [shape]);
  const tone = contact.own
    ? 'OvermapRadar__hull--own'
    : contact.docked
      ? 'OvermapRadar__hull--docked'
      : 'OvermapRadar__hull--other';
  return (
    <g
      transform={`translate(${contact.x} ${contact.y}) rotate(${-contact.rot})`}
    >
      {shape ? (
        <>
          <path className={`OvermapRadar__hull ${tone}`} d={hull} />
          <path className="OvermapRadar__collar" d={collars} />
        </>
      ) : (
        <circle className={`OvermapRadar__hull ${tone}`} r={1.5} />
      )}
    </g>
  );
};

export const OvermapRadar = (props: {
  shapes: Record<string, RadarShape>;
  contacts: RadarContact[];
  drifters: number[][];
  facing: number;
  terrain?: RadarTerrain | null;
  world?: number[];
}) => {
  const { shapes, contacts, drifters, facing, terrain, world } = props;
  const terrainPath = useMemo(() => cellsPath(terrain?.cells || []), [terrain]);
  const terrainShift =
    terrain && world ? [terrain.x - world[0], terrain.y - world[1]] : [0, 0];
  const [range, setRange] = useState<RadarRange>('32');
  const radius = Number(range);
  const north = (-facing * Math.PI) / 180;
  const labelSize = radius / 22;
  return (
    <div className="OvermapRadar">
      <svg
        className="OvermapRadar__screen"
        viewBox={`${-radius} ${-radius} ${radius * 2} ${radius * 2}`}
        preserveAspectRatio="xMidYMid meet"
      >
        {[0.25, 0.5, 0.75, 1].map((ring) => (
          <circle key={ring} className="OvermapRadar__ring" r={radius * ring} />
        ))}
        <g transform="scale(1 -1)">
          {!!terrain && (
            <g transform={`rotate(${facing})`}>
              <path
                className="OvermapRadar__terrain"
                transform={`translate(${terrainShift[0]} ${terrainShift[1]})`}
                d={terrainPath}
              />
            </g>
          )}
          {contacts.map((contact) => (
            <RadarHull
              key={contact.id}
              shape={shapes[contact.id]}
              contact={contact}
            />
          ))}
          {drifters.map((drifter, index) => (
            <circle
              key={index}
              className="OvermapRadar__drifter"
              cx={drifter[0]}
              cy={drifter[1]}
              r={radius / 80}
            />
          ))}
        </g>
        <text
          className="OvermapRadar__north"
          x={Math.sin(north) * radius * 0.92}
          y={-Math.cos(north) * radius * 0.92}
          fontSize={labelSize * 1.4}
          textAnchor="middle"
          dominantBaseline="middle"
        >
          N
        </text>
        {contacts
          .filter((contact) => !contact.own)
          .map((contact) => (
            <text
              key={contact.id}
              className="OvermapRadar__label"
              x={contact.x}
              y={-contact.y - labelSize * 4}
              fontSize={labelSize}
              textAnchor="middle"
            >
              {`${contact.name} · ${contact.distance} м · ${
                (contact.closing || 0) > 0 ? '▼' : '▲'
              }${Math.abs(contact.closing || 0)} м/с`}
            </text>
          ))}
      </svg>
      <div className="OvermapRadar__range">
        <OvermapSeg<RadarRange>
          value={range}
          onChange={setRange}
          items={RADAR_RANGES.map((id) => ({ id, label: `${id} м` }))}
        />
      </div>
    </div>
  );
};
