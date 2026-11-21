import { memo, useEffect, useId, useMemo, useState } from 'react';
import { classes } from 'tgui-core/react';

import type { GalaxyMap, GalaxySector } from './OvermapRadar';

const STAR_COUNT = 720;
const ARMS = 3;

const KIND_TONES: Record<string, string> = {
  station: '#6ff2d0',
  service: '#ffc46b',
  wilderness: '#c48bff',
  unknown: '#7f8ea3',
};

const KIND_LABELS: Record<string, string> = {
  station: 'Обжитой сектор',
  service: 'Сервисный сектор',
  wilderness: 'Дикий сектор',
  unknown: 'Неисследованная сигнатура',
};

const STAR_TONES = ['#fff4e0', '#bcd4ff', '#ffd9a0', '#f2b8ff'];

const seeded = (seed: number) => () => {
  seed = (seed * 16807) % 2147483647;
  return (seed - 1) / 2147483646;
};

const dotPath = (x: number, y: number, r: number) =>
  `M${x - r} ${y}a${r} ${r} 0 1 0 ${r * 2} 0a${r} ${r} 0 1 0 ${-r * 2} 0`;

const StarField = memo((props: { radius: number; ids: string }) => {
  const { radius, ids } = props;
  const paths = useMemo(() => {
    const random = seeded(4242);
    const buckets = STAR_TONES.map(() => '');
    for (let index = 0; index < STAR_COUNT; index++) {
      const arm = index % ARMS;
      const along = random() ** 0.7;
      const twist = along * 4.2 + (arm * Math.PI * 2) / ARMS;
      const scatter = (random() - 0.5) * (0.12 + along * 0.22);
      const reach = radius * (0.06 + along * 0.88);
      const x = Math.cos(twist + scatter) * reach;
      const y = Math.sin(twist + scatter) * reach * 0.62;
      const size =
        radius * (random() < 0.06 ? 0.0042 : 0.0016 + random() * 0.0016);
      const tone = along < 0.25 ? 2 : Math.floor(random() * STAR_TONES.length);
      buckets[tone] += dotPath(x, y, size);
    }
    for (let index = 0; index < 160; index++) {
      const x = (random() - 0.5) * radius * 2;
      const y = (random() - 0.5) * radius * 2;
      buckets[1] += dotPath(x, y, radius * 0.0011);
    }
    return buckets;
  }, [radius]);
  return (
    <g className="OvermapGalaxy__field">
      <animateTransform
        attributeName="transform"
        type="rotate"
        from="0"
        to="-360"
        dur="900s"
        repeatCount="indefinite"
      />
      <ellipse
        rx={radius * 0.98}
        ry={radius * 0.62}
        fill={`url(#${ids}-disc)`}
      />
      {paths.map((path, index) => (
        <path
          key={index}
          d={path}
          fill={STAR_TONES[index]}
          opacity={index === 1 ? 0.55 : 0.75}
        />
      ))}
      <ellipse
        cx={radius * 0.32}
        cy={-radius * 0.18}
        rx={radius * 0.3}
        ry={radius * 0.14}
        fill={`url(#${ids}-nebula-violet)`}
      />
      <ellipse
        cx={-radius * 0.4}
        cy={radius * 0.2}
        rx={radius * 0.26}
        ry={radius * 0.12}
        fill={`url(#${ids}-nebula-teal)`}
      />
      <circle r={radius * 0.22} fill={`url(#${ids}-core)`} />
    </g>
  );
});

const toneFor = (sector: GalaxySector) =>
  KIND_TONES[sector.unknown ? 'unknown' : sector.kind] || KIND_TONES.station;

export const GalaxyLayer = (props: {
  galaxy: GalaxyMap;
  sectorId?: string;
  radius: number;
  opacity: number;
  slot: number;
  rotation?: number;
}) => {
  const { galaxy, sectorId, radius, opacity, slot } = props;
  const ids = useId().replace(/:/g, '');
  const [selectedId, setSelectedId] = useState<string | undefined>(sectorId);
  const [flightAge, setFlightAge] = useState(0);
  useEffect(() => {
    setFlightAge(0);
    if (!galaxy.transits?.length) return;
    const started = performance.now();
    let animation = 0;
    const tick = (now: number) => {
      setFlightAge(now - started);
      animation = requestAnimationFrame(tick);
    };
    animation = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animation);
  }, [galaxy.transits]);
  const nodes = useMemo(() => {
    const sectors = galaxy.sectors;
    const center = sectors.find((sector) => sector.id === galaxy.center);
    const centerX = center?.x || 0;
    const centerY = center?.y || 0;
    const extent = Math.max(
      1,
      ...sectors.map((sector) =>
        Math.max(Math.abs(sector.x - centerX), Math.abs(sector.y - centerY)),
      ),
    );
    const scale = (slot * 2.4 * 1.15 * 0.68) / extent;
    return sectors.map((sector) => ({
      sector,
      x: (sector.x - centerX) * scale,
      y: -(sector.y - centerY) * scale * 0.8,
    }));
  }, [galaxy, slot]);
  if (!nodes.length || opacity <= 0) return null;
  const selected =
    nodes.find((node) => node.sector.id === selectedId) ||
    nodes.find((node) => node.sector.id === sectorId);
  const byId = new Map(nodes.map((node) => [node.sector.id, node]));
  const dot = radius * 0.014;
  const curve = (
    from: { x: number; y: number },
    to: { x: number; y: number },
  ) => {
    const midX = (from.x + to.x) / 2;
    const midY = (from.y + to.y) / 2 - radius * 0.06;
    return { midX, midY };
  };
  const panelX = -radius * 0.21;
  const panelY = radius * 0.5;
  return (
    <g className="OvermapGalaxy" opacity={opacity}>
      <defs>
        <radialGradient id={`${ids}-core`}>
          <stop offset="0%" stopColor="#fff6dd" stopOpacity={0.95} />
          <stop offset="25%" stopColor="#ffcf8a" stopOpacity={0.55} />
          <stop offset="60%" stopColor="#c27cff" stopOpacity={0.16} />
          <stop offset="100%" stopColor="#000" stopOpacity={0} />
        </radialGradient>
        <radialGradient id={`${ids}-disc`}>
          <stop offset="0%" stopColor="#3b2a5c" stopOpacity={0.55} />
          <stop offset="55%" stopColor="#14263a" stopOpacity={0.35} />
          <stop offset="100%" stopColor="#000" stopOpacity={0} />
        </radialGradient>
        <radialGradient id={`${ids}-nebula-violet`}>
          <stop offset="0%" stopColor="#b26bff" stopOpacity={0.28} />
          <stop offset="100%" stopColor="#b26bff" stopOpacity={0} />
        </radialGradient>
        <radialGradient id={`${ids}-nebula-teal`}>
          <stop offset="0%" stopColor="#4fe0c4" stopOpacity={0.22} />
          <stop offset="100%" stopColor="#4fe0c4" stopOpacity={0} />
        </radialGradient>
        <radialGradient id={`${ids}-glow`}>
          <stop offset="0%" stopColor="#fff" stopOpacity={0.9} />
          <stop offset="35%" stopColor="#fff" stopOpacity={0.25} />
          <stop offset="100%" stopColor="#fff" stopOpacity={0} />
        </radialGradient>
      </defs>
      <StarField radius={radius} ids={ids} />
      {nodes.flatMap((node) =>
        node.sector.links.map((id) => {
          const target = byId.get(id);
          if (!target || id < node.sector.id) return null;
          const active = node === selected || target === selected;
          const signal =
            node.sector.signal_links?.includes(id) ||
            target.sector.signal_links?.includes(node.sector.id);
          const { midX, midY } = curve(node, target);
          const path = `M${node.x} ${node.y} Q${midX} ${midY} ${target.x} ${target.y}`;
          const distance =
            node.sector.distances?.[id] ||
            target.sector.distances?.[node.sector.id];
          return (
            <g key={`${node.sector.id}-${id}`}>
              <path className="OvermapGalaxy__lane-glow" d={path} />
              <path
                className={classes([
                  'OvermapGalaxy__lane',
                  active && 'OvermapGalaxy__lane--active',
                  !signal && 'OvermapGalaxy__lane--uncertain',
                ])}
                d={path}
              />
              {!!distance && (
                <g
                  transform={`translate(${midX} ${(node.y + target.y) / 2 - radius * 0.03})`}
                >
                  <rect
                    className="OvermapGalaxy__pill"
                    x={-radius * 0.03}
                    y={-radius * 0.013}
                    width={radius * 0.06}
                    height={radius * 0.024}
                    rx={radius * 0.012}
                  />
                  <text
                    className="OvermapGalaxy__pill-text"
                    y={radius * 0.0055}
                    fontSize={radius * 0.016}
                    textAnchor="middle"
                  >
                    {distance}
                  </text>
                </g>
              )}
            </g>
          );
        }),
      )}
      {galaxy.transits?.map((flight) => {
        const from = byId.get(flight.from);
        const to = byId.get(flight.to);
        if (!from || !to) return null;
        const t = Math.min(
          1,
          flight.progress +
            ((1 - flight.progress) * flightAge) / Math.max(flight.remaining, 1),
        );
        const u = 1 - t;
        const { midX, midY } = curve(from, to);
        const x = u * u * from.x + 2 * u * t * midX + t * t * to.x;
        const y = u * u * from.y + 2 * u * t * midY + t * t * to.y;
        const angle =
          (Math.atan2(
            u * (midY - from.y) + t * (to.y - midY),
            u * (midX - from.x) + t * (to.x - midX),
          ) *
            180) /
          Math.PI;
        const size = radius * 0.013;
        const color = flight.own ? '#76ffc1' : '#f3ba85';
        return (
          <g
            key={flight.id}
            transform={`translate(${x} ${y}) rotate(${angle})`}
          >
            <path
              d={`M${-size * 0.6} 0L${-size * 6} 0`}
              stroke={color}
              strokeOpacity={0.45}
              strokeWidth={size * 0.5}
              strokeLinecap="round"
            />
            <circle r={size * 2.4} fill={`url(#${ids}-glow)`} opacity={0.35} />
            <path
              d={`M${size} 0L${-size} ${size * 0.7}L${-size * 0.5} 0L${-size} ${-size * 0.7}Z`}
              fill={color}
            >
              <title>{flight.own ? 'Ваш корабль' : 'Корабль в переходе'}</title>
            </path>
          </g>
        );
      })}
      {nodes.map((node, index) => {
        const current = node.sector.id === sectorId;
        const picked = node === selected;
        const unknown = !!node.sector.unknown;
        const tone = toneFor(node.sector);
        if (unknown) {
          return (
            <g
              key={node.sector.id}
              transform={`translate(${node.x} ${node.y})`}
              className={classes([
                'OvermapGalaxy__node',
                'OvermapGalaxy__node--unknown',
                picked && 'OvermapGalaxy__node--selected',
              ])}
              onClick={() => setSelectedId(node.sector.id)}
            >
              <title>Неизвестная сигнатура</title>
              <circle r={dot * 2.4} fill="transparent" />
              <circle
                className="OvermapGalaxy__orbit-ring"
                r={dot * 1.1}
                stroke={tone}
              />
              <circle r={dot * 0.3} fill={tone} />
              {picked && (
                <text
                  className="OvermapGalaxy__sub"
                  x={dot * 1.8}
                  y={dot * 0.5}
                  fontSize={radius / 56}
                  fill={tone}
                >
                  ?
                </text>
              )}
            </g>
          );
        }
        return (
          <g
            key={node.sector.id}
            transform={`translate(${node.x} ${node.y})`}
            className={classes([
              'OvermapGalaxy__node',
              current && 'OvermapGalaxy__node--current',
              picked && 'OvermapGalaxy__node--selected',
              unknown && 'OvermapGalaxy__node--unknown',
            ])}
            role="button"
            tabIndex={0}
            aria-label={node.sector.name}
            onClick={() => setSelectedId(node.sector.id)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ')
                setSelectedId(node.sector.id);
            }}
          >
            <title>{unknown ? 'Неизвестный сектор' : node.sector.name}</title>
            <circle r={dot * 4} fill="transparent" />
            <circle
              r={dot * 3.2}
              fill={`url(#${ids}-glow)`}
              opacity={unknown ? 0.15 : 0.4}
              style={{ color: tone }}
            />
            <circle r={dot * 2.8} fill={tone} opacity={unknown ? 0.04 : 0.12} />
            <circle
              className="OvermapGalaxy__sun"
              r={unknown ? dot * 0.45 : dot}
              fill={unknown ? '#8796a8' : '#fff7e6'}
              stroke={tone}
            />
            {current && (
              <circle
                className="OvermapGalaxy__pulse"
                r={dot * 2}
                stroke={tone}
              />
            )}
            {!!node.sector.distress && (
              <circle className="OvermapGalaxy__sos" r={dot * 3.4} />
            )}
            {picked && (
              <path
                className="OvermapGalaxy__bracket"
                d={`M${-dot * 4} ${-dot * 2}v${-dot * 1.4}h${dot * 1.4} M${dot * 4} ${-dot * 2}v${-dot * 1.4}h${-dot * 1.4} M${-dot * 4} ${dot * 2}v${dot * 1.4}h${dot * 1.4} M${dot * 4} ${dot * 2}v${dot * 1.4}h${-dot * 1.4}`}
              />
            )}
            <text
              className="OvermapGalaxy__name"
              x={dot * 4.4}
              y={-dot * 0.3}
              fontSize={radius / 38}
              fill="#e3eefb"
            >
              {node.sector.name}
            </text>
            <text
              className="OvermapGalaxy__sub"
              x={dot * 4.4}
              y={dot * 1.7}
              fontSize={radius / 56}
              fill={tone}
            >
              {current ? '◉ ВЫ ЗДЕСЬ' : `${node.sector.contacts} конт.`}
            </text>
          </g>
        );
      })}
      <text
        className="OvermapGalaxy__heading"
        x={0}
        y={-radius * 0.86}
        textAnchor="middle"
        fontSize={radius / 26}
      >
        КАРТА ГАЛАКТИКИ
      </text>
      <text
        className="OvermapGalaxy__subheading"
        x={0}
        y={-radius * 0.815}
        textAnchor="middle"
        fontSize={radius / 52}
      >
        МЕЖСЕКТОРНАЯ СЕТЬ ·{' '}
        {nodes.filter((node) => !node.sector.unknown).length} СЕКТОРОВ
      </text>
      {!!selected && (
        <g transform={`translate(${panelX} ${panelY})`}>
          <rect
            className="OvermapGalaxy__panel"
            width={radius * 0.42}
            height={radius * 0.3}
            rx={radius * 0.01}
          />
          <rect
            width={radius * 0.006}
            height={radius * 0.3}
            fill={toneFor(selected.sector)}
          />
          <text
            className="OvermapGalaxy__panel-title"
            x={radius * 0.025}
            y={radius * 0.05}
            fontSize={radius / 34}
          >
            {selected.sector.unknown
              ? 'НЕИЗВЕСТНЫЙ СЕКТОР'
              : selected.sector.name}
          </text>
          <text
            x={radius * 0.025}
            y={radius * 0.09}
            fontSize={radius / 52}
            fill={toneFor(selected.sector)}
          >
            {KIND_LABELS[
              selected.sector.unknown ? 'unknown' : selected.sector.kind
            ] || 'Сектор'}
          </text>
          {(selected.sector.unknown
            ? ['Сигнатура не исследована', 'Маршрут не проложен']
            : [
                `Гиперкоридоров: ${selected.sector.links.length}`,
                `Контактов в секторе: ${selected.sector.contacts}`,
                selected.sector.distress
                  ? 'Принят сигнал бедствия'
                  : 'Сигналов бедствия нет',
                selected.sector.id === sectorId
                  ? 'Текущее положение судна'
                  : `Маяки: ${selected.sector.signal_links?.length || 0}`,
              ]
          ).map((line, index) => (
            <text
              key={index}
              className="OvermapGalaxy__panel-line"
              x={radius * 0.025}
              y={radius * (0.135 + index * 0.038)}
              fontSize={radius / 56}
              fill={line === 'Принят сигнал бедствия' ? '#ff7b86' : '#a9c0d6'}
            >
              {line}
            </text>
          ))}
        </g>
      )}
    </g>
  );
};
