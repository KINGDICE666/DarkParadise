import { type MouseEvent, useEffect, useRef } from 'react';

import type { SensorClutter, SensorTrack } from './types';

const SWEEP_TRAIL = 70;
const SECTOR_HALF_ARC = 30;
const SECTOR_REACH = 1.7;
const BLEND_MS = 1500;
const PICK_RADIUS = 16;
const LEAD_SECONDS = 0.3;
const SHADOW_CELLS = 0.55;

const GREEN = '57,255,106';
const MID = '31,191,74';
const PALE = '184,255,201';

export type ScopeLayers = {
  trails: boolean;
  iff: boolean;
  ebl: boolean;
  vrm: boolean;
  cpa: boolean;
  labels: boolean;
};

type ScopeProps = {
  tracks: SensorTrack[];
  clutter: SensorClutter[];
  scale: number;
  northUp: boolean;
  heading: number;
  speed: number;
  activeMode: string;
  sectorBearing?: number;
  passiveOn: boolean;
  sweepPeriod: number;
  brightness: number;
  layers: ScopeLayers;
  selected?: string;
  locked?: string;
  onSelect: (ref: string) => void;
  onAim: (bearing: number) => void;
};

type Pose = { x: number; y: number };
type Blend = { from: Pose; to: Pose; at: number };

const polar = (bearing: number, range: number): Pose => {
  const angle = ((bearing - 90) * Math.PI) / 180;
  return { x: Math.cos(angle) * range, y: Math.sin(angle) * range };
};

const seeded = (seed: number) => () => {
  seed = (seed * 16807) % 2147483647;
  return (seed - 1) / 2147483646;
};

const hashRef = (ref: string) => {
  let hash = 7;
  for (let index = 0; index < ref.length; index++) {
    hash = (hash * 31 + ref.charCodeAt(index)) % 2147483646;
  }
  return hash + 1;
};

export const SensorScope = (props: ScopeProps) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const propsRef = useRef(props);
  const blendsRef = useRef<Map<string, Blend>>(new Map());
  const layoutRef = useRef({ cx: 0, cy: 0, radius: 1, rotation: 0 });
  propsRef.current = props;

  useEffect(() => {
    const now = performance.now();
    const blends = blendsRef.current;
    const alive = new Set<string>();
    for (const track of props.tracks) {
      alive.add(track.ref);
      const target = polar(track.bearing, track.range);
      const previous = blends.get(track.ref);
      if (!previous || track.shadow) {
        blends.set(track.ref, { from: target, to: target, at: now });
        continue;
      }
      const progress = Math.min(1, (now - previous.at) / BLEND_MS);
      blends.set(track.ref, {
        from: {
          x: previous.from.x + (previous.to.x - previous.from.x) * progress,
          y: previous.from.y + (previous.to.y - previous.from.y) * progress,
        },
        to: target,
        at: now,
      });
    }
    for (const ref of [...blends.keys()]) {
      if (!alive.has(ref)) blends.delete(ref);
    }
  }, [props.tracks]);

  useEffect(() => {
    let frame = 0;
    const draw = (now: number) => {
      frame = requestAnimationFrame(draw);
      const canvas = canvasRef.current;
      const box = canvas?.parentElement;
      if (!canvas || !box) return;
      if (
        canvas.width !== box.clientWidth ||
        canvas.height !== box.clientHeight
      ) {
        canvas.width = box.clientWidth;
        canvas.height = box.clientHeight;
      }
      const ctx = canvas.getContext('2d');
      if (ctx) paint(ctx, canvas.width, canvas.height, now);
    };
    frame = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(frame);
  }, []);

  const paint = (
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    now: number,
  ) => {
    const state = propsRef.current;
    const cx = width / 2;
    const cy = height / 2;
    const radius = Math.min(width, height) / 2 - 30;
    const rotation = state.northUp ? 0 : -state.heading;
    layoutRef.current = { cx, cy, radius, rotation };
    const unit = radius / state.scale;
    const glow = 0.4 + state.brightness / 100;
    const screen = (pose: Pose) => {
      const angle = (rotation * Math.PI) / 180;
      return {
        x: cx + (pose.x * Math.cos(angle) - pose.y * Math.sin(angle)) * unit,
        y: cy + (pose.x * Math.sin(angle) + pose.y * Math.cos(angle)) * unit,
      };
    };
    const along = (bearing: number, range: number) =>
      screen(polar(bearing, range));
    ctx.clearRect(0, 0, width, height);
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fillStyle = '#010a03';
    ctx.fill();
    ctx.clip();

    const grain = seeded(11);
    for (let index = 0; index < 260; index++) {
      const spot = along(grain() * 360, grain() * state.scale);
      ctx.fillStyle = `rgba(${GREEN},${grain() * 0.12 * glow})`;
      ctx.fillRect(spot.x, spot.y, 1.2, 1.2);
    }

    const period = Math.max(state.sweepPeriod, 1) * 1000;
    let sweep: number | null = null;
    if (state.activeMode === 'circle') {
      sweep = ((now % period) / period) * 360;
    } else if (
      state.activeMode === 'sector' &&
      state.sectorBearing !== undefined
    ) {
      const swing = Math.sin(((now % period) / period) * Math.PI * 2);
      sweep = (state.sectorBearing + swing * SECTOR_HALF_ARC + 360) % 360;
    }
    if (sweep !== null) {
      for (let step = 0; step < SWEEP_TRAIL; step++) {
        const from = ((sweep - step - 90 + rotation) * Math.PI) / 180;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.arc(cx, cy, radius, from, from + Math.PI / 180);
        ctx.closePath();
        ctx.fillStyle = `rgba(${GREEN},${0.16 * (1 - step / SWEEP_TRAIL) ** 2})`;
        ctx.fill();
      }
    }

    state.clutter.forEach((cloud, cloudIndex) => {
      const noise = seeded(97 + cloudIndex * 31);
      const spread = 0.35 + cloud.density * 0.12;
      const center = polar(cloud.bearing, cloud.range);
      for (let index = 0; index < 70 + cloud.density * 30; index++) {
        const spot = screen({
          x: center.x + (noise() - 0.5) * spread * 2,
          y: center.y + (noise() - 0.5) * spread * 2,
        });
        const flicker = 0.6 + 0.4 * Math.sin(now / 280 + index);
        ctx.fillStyle = `rgba(${GREEN},${(0.25 + noise() * 0.6) * flicker * glow})`;
        ctx.fillRect(spot.x, spot.y, 1.4 + noise() * 2.6, 1.2 + noise() * 1.8);
      }
    });

    for (const track of state.tracks) {
      if (!track.shadow) continue;
      const center = polar(track.bearing, track.range);
      const noise = seeded(hashRef(track.ref));
      for (let index = 0; index < 80; index++) {
        const angle = noise() * Math.PI * 2;
        const distance = SHADOW_CELLS * (1.05 + noise() ** 0.7 * 1.3);
        const spot = screen({
          x: center.x + Math.cos(angle) * distance,
          y: center.y + Math.sin(angle) * distance,
        });
        const stretch = 1 + (2.4 - distance / SHADOW_CELLS) * 1.6;
        ctx.save();
        ctx.translate(spot.x, spot.y);
        ctx.rotate(angle + Math.PI / 2);
        ctx.fillStyle = `rgba(${GREEN},${(0.1 + noise() * 0.3) * glow})`;
        ctx.fillRect(-stretch * 1.4, -0.8, stretch * 2.8, 1.6);
        ctx.restore();
      }
      const core = screen(center);
      ctx.beginPath();
      ctx.arc(core.x, core.y, SHADOW_CELLS * unit, 0, Math.PI * 2);
      ctx.fillStyle = '#000000';
      ctx.fill();
    }
    ctx.restore();

    ctx.strokeStyle = `rgba(${GREEN},0.9)`;
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.stroke();
    ctx.lineWidth = 1;
    ctx.font = '11px "IBM Plex Mono", Consolas, monospace';
    ctx.setLineDash([2, 4]);
    ctx.strokeStyle = `rgba(${MID},0.6)`;
    for (let ring = 1; ring < 4; ring++) {
      ctx.beginPath();
      ctx.arc(cx, cy, (radius * ring) / 4, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.setLineDash([]);
    for (let bearing = 0; bearing < 360; bearing += 2) {
      const angle = ((bearing - 90 + rotation) * Math.PI) / 180;
      const length = bearing % 30 === 0 ? 12 : bearing % 10 === 0 ? 7 : 3;
      ctx.strokeStyle = `rgba(${GREEN},${bearing % 10 === 0 ? 0.9 : 0.4})`;
      ctx.beginPath();
      ctx.moveTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
      ctx.lineTo(
        cx + Math.cos(angle) * (radius - length),
        cy + Math.sin(angle) * (radius - length),
      );
      ctx.stroke();
      if (bearing % 30 === 0) {
        ctx.fillStyle = `rgba(${GREEN},1)`;
        ctx.textAlign = 'center';
        ctx.fillText(
          String(bearing).padStart(3, '0'),
          cx + Math.cos(angle) * (radius + 15),
          cy + Math.sin(angle) * (radius + 15) + 4,
        );
      }
    }
    ctx.textAlign = 'left';

    if (sweep !== null) {
      const tip = along(sweep, state.scale);
      ctx.strokeStyle = `rgba(${PALE},0.85)`;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(tip.x, tip.y);
      ctx.stroke();
    }
    if (state.activeMode === 'sector' && state.sectorBearing !== undefined) {
      ctx.setLineDash([3, 5]);
      ctx.strokeStyle = `rgba(${MID},0.8)`;
      for (const edge of [-SECTOR_HALF_ARC, SECTOR_HALF_ARC]) {
        const end = along(
          state.sectorBearing + edge,
          Math.min(state.scale, state.scale * SECTOR_REACH),
        );
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(end.x, end.y);
        ctx.stroke();
      }
      ctx.setLineDash([]);
    }
    if (state.passiveOn && state.activeMode === 'off') {
      const ripple = (now % 3000) / 3000;
      ctx.strokeStyle = `rgba(${GREEN},${0.3 * (1 - ripple)})`;
      ctx.beginPath();
      ctx.arc(cx, cy, radius * ripple, 0, Math.PI * 2);
      ctx.stroke();
    }

    const chosen = state.tracks.find((track) => track.ref === state.selected);
    if (chosen && state.layers.ebl) {
      const end = along(chosen.bearing, state.scale);
      ctx.setLineDash([10, 4, 2, 4]);
      ctx.strokeStyle = `rgba(${PALE},0.75)`;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(end.x, end.y);
      ctx.stroke();
      ctx.setLineDash([]);
    }
    if (chosen && state.layers.vrm && chosen.range <= state.scale) {
      ctx.setLineDash([4, 3]);
      ctx.strokeStyle = `rgba(${PALE},0.7)`;
      ctx.beginPath();
      ctx.arc(cx, cy, chosen.range * unit, 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    for (const track of state.tracks) {
      const label = state.layers.labels && track.name ? ` ${track.name}` : '';
      if (track.source === 'pas') {
        const end = along(track.bearing, state.scale);
        ctx.setLineDash([8, 6]);
        ctx.strokeStyle = `rgba(${GREEN},0.75)`;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(end.x, end.y);
        ctx.stroke();
        ctx.setLineDash([]);
        const tag = along(track.bearing + 3, state.scale * 0.88);
        ctx.fillStyle = `rgba(${GREEN},0.95)`;
        ctx.fillText(
          `${track.id} ${track.ir >= track.em ? 'ИК' : 'ЭМ'}`,
          tag.x - 18,
          tag.y,
        );
        continue;
      }
      const blend = blendsRef.current.get(track.ref);
      let pose = polar(track.bearing, track.range);
      if (blend && !track.shadow) {
        const progress = Math.min(1, (now - blend.at) / BLEND_MS);
        pose = {
          x: blend.from.x + (blend.to.x - blend.from.x) * progress,
          y: blend.from.y + (blend.to.y - blend.from.y) * progress,
        };
      }
      if (Math.hypot(pose.x, pose.y) > state.scale) continue;
      let spot = screen(pose);
      if (track.shadow) {
        const step = Math.floor(now / 400);
        const jitter = seeded(step + hashRef(track.ref));
        spot = {
          x: spot.x + (jitter() - 0.5) * 9,
          y: spot.y + (jitter() - 0.5) * 9,
        };
      }
      if (state.layers.trails && track.trail?.length) {
        track.trail.forEach(([bearing, range], index) => {
          if (range > state.scale) return;
          const dot = along(bearing, range);
          ctx.fillStyle = `rgba(${PALE},${0.15 + (index / track.trail!.length) * 0.6})`;
          ctx.beginPath();
          ctx.arc(dot.x, dot.y, 1.6, 0, Math.PI * 2);
          ctx.fill();
        });
      }
      const dim = track.source === 'lost' ? 0.4 : 1;
      ctx.strokeStyle = `rgba(${PALE},${dim})`;
      ctx.fillStyle = `rgba(${PALE},${dim})`;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      if (track.source === 'iff' && state.layers.iff) {
        ctx.moveTo(spot.x, spot.y - 8);
        ctx.lineTo(spot.x + 7, spot.y + 6);
        ctx.lineTo(spot.x - 7, spot.y + 6);
        ctx.closePath();
      } else if (track.source === 'sos') {
        ctx.rect(spot.x - 6, spot.y - 6, 12, 12);
      } else if (track.source === 'map') {
        ctx.arc(spot.x, spot.y, 7, 0, Math.PI * 2);
        ctx.moveTo(spot.x + 11, spot.y);
        ctx.arc(spot.x, spot.y, 11, 0, Math.PI * 2);
      } else {
        if (track.shadow || track.source === 'lost') ctx.setLineDash([3, 3]);
        ctx.arc(spot.x, spot.y, 7, 0, Math.PI * 2);
      }
      ctx.stroke();
      ctx.setLineDash([]);
      if (track.speed && track.heading !== undefined) {
        const lead = polar(track.heading, track.speed * LEAD_SECONDS);
        const tip = screen({ x: pose.x + lead.x, y: pose.y + lead.y });
        ctx.beginPath();
        ctx.moveTo(spot.x, spot.y);
        ctx.lineTo(tip.x, tip.y);
        ctx.stroke();
      }
      ctx.lineWidth = 1;
      if (
        state.layers.cpa &&
        track.ref === chosen?.ref &&
        track.cpa !== undefined &&
        track.cpa_bearing !== undefined
      ) {
        const point = along(track.cpa_bearing, track.cpa);
        ctx.setLineDash([2, 3]);
        ctx.strokeStyle = 'rgba(255,255,255,0.7)';
        ctx.beginPath();
        ctx.moveTo(spot.x, spot.y);
        ctx.lineTo(point.x, point.y);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.strokeStyle = '#ffffff';
        ctx.beginPath();
        ctx.moveTo(point.x - 5, point.y - 5);
        ctx.lineTo(point.x + 5, point.y + 5);
        ctx.moveTo(point.x + 5, point.y - 5);
        ctx.lineTo(point.x - 5, point.y + 5);
        ctx.stroke();
      }
      if (track.ref === state.locked || track.ref === state.selected) {
        const blink = track.ref === state.locked && Math.floor(now / 500) % 2;
        ctx.strokeStyle = blink ? 'rgba(255,255,255,0.45)' : '#ffffff';
        ctx.lineWidth = 1.5;
        if (track.shadow) ctx.setLineDash([4, 3]);
        for (const [dx, dy] of [
          [-1, -1],
          [1, -1],
          [-1, 1],
          [1, 1],
        ]) {
          ctx.beginPath();
          ctx.moveTo(spot.x + dx * 14, spot.y + dy * 8);
          ctx.lineTo(spot.x + dx * 14, spot.y + dy * 14);
          ctx.lineTo(spot.x + dx * 8, spot.y + dy * 14);
          ctx.stroke();
        }
        ctx.setLineDash([]);
        ctx.lineWidth = 1;
      }
      ctx.fillStyle = `rgba(${PALE},${dim})`;
      ctx.fillText(
        `${track.id.replace('T-', '')}${label}`,
        spot.x + 10,
        spot.y + 17,
      );
    }

    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 1.5;
    const nose = screen(polar(state.heading, 0.32 * state.scale));
    const facing = ((state.heading - 90 + rotation) * Math.PI) / 180;
    ctx.beginPath();
    ctx.moveTo(cx + Math.cos(facing) * 10, cy + Math.sin(facing) * 10);
    ctx.lineTo(
      cx + Math.cos(facing + 2.5) * 8,
      cy + Math.sin(facing + 2.5) * 8,
    );
    ctx.lineTo(
      cx + Math.cos(facing - 2.5) * 8,
      cy + Math.sin(facing - 2.5) * 8,
    );
    ctx.closePath();
    ctx.stroke();
    if (state.speed > 0) {
      ctx.beginPath();
      ctx.moveTo(cx + Math.cos(facing) * 10, cy + Math.sin(facing) * 10);
      ctx.lineTo(nose.x, nose.y);
      ctx.stroke();
    }
    ctx.lineWidth = 1;
  };

  const handleClick = (event: MouseEvent<HTMLCanvasElement>) => {
    const state = propsRef.current;
    const { cx, cy, radius, rotation } = layoutRef.current;
    const rect = event.currentTarget.getBoundingClientRect();
    const x = event.clientX - rect.left - cx;
    const y = event.clientY - rect.top - cy;
    const unit = radius / state.scale;
    const angle = (rotation * Math.PI) / 180;
    let best: SensorTrack | undefined;
    let bestDistance = PICK_RADIUS;
    for (const track of state.tracks) {
      if (track.source === 'pas') continue;
      const pose = polar(track.bearing, track.range);
      const px = (pose.x * Math.cos(angle) - pose.y * Math.sin(angle)) * unit;
      const py = (pose.x * Math.sin(angle) + pose.y * Math.cos(angle)) * unit;
      const distance = Math.hypot(px - x, py - y);
      if (distance < bestDistance) {
        best = track;
        bestDistance = distance;
      }
    }
    if (best) {
      state.onSelect(best.ref);
      return;
    }
    if (state.activeMode === 'sector' && Math.hypot(x, y) <= radius) {
      const bearing =
        ((Math.atan2(y, x) * 180) / Math.PI + 90 - rotation + 720) % 360;
      state.onAim(Math.round(bearing));
    }
  };

  return (
    <canvas
      ref={canvasRef}
      className="SensorPost__canvas"
      onClick={handleClick}
    />
  );
};
