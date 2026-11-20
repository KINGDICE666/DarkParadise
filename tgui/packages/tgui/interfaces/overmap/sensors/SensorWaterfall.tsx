import { useEffect, useRef } from 'react';

import type { SensorClutter, SensorTrack } from './types';

const HISTORY = 90;
const WIDTH = 360;
const TIME_COLUMN = 58;
const TIME_LABELS = 5;

const HEAT: [number, number[]][] = [
  [0, [0, 8, 3]],
  [0.3, [0, 70, 30]],
  [0.55, [20, 190, 80]],
  [0.75, [120, 255, 150]],
  [1, [235, 255, 240]],
];

const heat = (value: number) => {
  const level = Math.max(0, Math.min(1, value));
  for (let index = 1; index < HEAT.length; index++) {
    const [stop, color] = HEAT[index];
    if (level <= stop) {
      const [previous, base] = HEAT[index - 1];
      const mix = (level - previous) / (stop - previous);
      return base.map(
        (channel, part) => channel + (color[part] - channel) * mix,
      );
    }
  }
  return HEAT[HEAT.length - 1][1];
};

type Row = { values: Float32Array; time: string };

const clock = () => {
  const now = new Date();
  return [now.getHours(), now.getMinutes(), now.getSeconds()]
    .map((part) => String(part).padStart(2, '0'))
    .join(':');
};

const buildRow = (
  tracks: SensorTrack[],
  clutter: SensorClutter[],
  live: boolean,
  haywire: boolean,
  gain: number,
): Row => {
  const values = new Float32Array(WIDTH);
  const noise = (0.1 + gain / 500) * (haywire ? 3 : 1);
  for (let index = 0; index < WIDTH; index++) {
    values[index] = live ? Math.random() * noise : 0;
    if (live && haywire && Math.random() < 0.012) values[index] += 0.5;
  }
  if (live) {
    for (const cloud of clutter) {
      for (let step = -12; step <= 12; step++) {
        const bin = (Math.round(cloud.bearing) + step + WIDTH) % WIDTH;
        values[bin] += Math.random() * 0.2 * (1 - Math.abs(step) / 13);
      }
    }
    for (const track of tracks) {
      if (track.source === 'map' || track.source === 'lost' || track.shadow)
        continue;
      const power = (Math.max(track.ir, track.em) / 100) * (0.6 + gain / 125);
      const width = track.source === 'pas' ? 3 : 2;
      for (let step = -8; step <= 8; step++) {
        const bin = (Math.round(track.bearing) + step + WIDTH) % WIDTH;
        values[bin] +=
          power *
          Math.exp(-(step * step) / (2 * width * width)) *
          (0.8 + Math.random() * 0.3);
      }
    }
    for (const track of tracks) {
      if (!track.shadow) continue;
      for (let step = -5; step <= 5; step++) {
        values[(Math.round(track.bearing) + step + WIDTH) % WIDTH] *= 0.2;
      }
    }
  }
  return { values, time: clock() };
};

export const SensorWaterfall = (props: {
  tracks: SensorTrack[];
  clutter: SensorClutter[];
  live: boolean;
  haywire?: boolean;
  gain?: number;
}) => {
  const { tracks, clutter, live, haywire = false, gain = 50 } = props;
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const historyRef = useRef<Row[]>([]);
  const settingsRef = useRef({ live, haywire, gain });
  settingsRef.current = { live, haywire, gain };

  useEffect(() => {
    const history = historyRef.current;
    const settings = settingsRef.current;
    history.unshift(
      buildRow(tracks, clutter, settings.live, settings.haywire, settings.gain),
    );
    if (history.length > HISTORY) history.length = HISTORY;
    const canvas = canvasRef.current;
    const box = canvas?.parentElement;
    if (!canvas || !box) return;
    canvas.width = box.clientWidth;
    canvas.height = box.clientHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const plotWidth = canvas.width - TIME_COLUMN;
    const image = ctx.createImageData(plotWidth, canvas.height);
    const rowHeight = canvas.height / HISTORY;
    for (let y = 0; y < canvas.height; y++) {
      const entry = history[Math.floor(y / rowHeight)];
      const fade = 1 - (y / canvas.height) * 0.35;
      for (let x = 0; x < plotWidth; x++) {
        const offset = (y * plotWidth + x) * 4;
        image.data[offset + 3] = 255;
        if (!entry) continue;
        const color = heat(
          entry.values[Math.floor((x / plotWidth) * WIDTH)] * fade,
        );
        image.data[offset] = color[0];
        image.data[offset + 1] = color[1];
        image.data[offset + 2] = color[2];
      }
    }
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, TIME_COLUMN, canvas.height);
    ctx.putImageData(image, TIME_COLUMN, 0);
    ctx.strokeStyle = '#1d7a36';
    ctx.beginPath();
    ctx.moveTo(TIME_COLUMN - 0.5, 0);
    ctx.lineTo(TIME_COLUMN - 0.5, canvas.height);
    ctx.stroke();
    ctx.fillStyle = '#39ff6a';
    ctx.font = '9px "IBM Plex Mono", Consolas, monospace';
    for (let mark = 0; mark < TIME_LABELS; mark++) {
      const row = Math.floor((mark / (TIME_LABELS - 1)) * (HISTORY - 1));
      const entry = history[row];
      if (!entry) continue;
      ctx.fillText(
        entry.time,
        4,
        Math.min(canvas.height - 3, row * rowHeight + 10),
      );
    }
  }, [tracks, clutter]);

  return <canvas ref={canvasRef} className="SensorPost__canvas" />;
};

export const SensorSilhouette = (props: {
  tiles?: number[];
  progress: number;
  done: boolean;
}) => {
  const { tiles, progress, done } = props;
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;
    const size = canvas.width;
    ctx.clearRect(0, 0, size, size);
    ctx.strokeStyle = 'rgba(57,255,106,0.1)';
    for (let line = 0; line <= size; line += 15) {
      ctx.beginPath();
      ctx.moveTo(line, 0);
      ctx.lineTo(line, size);
      ctx.moveTo(0, line);
      ctx.lineTo(size, line);
      ctx.stroke();
    }
    if (!tiles?.length) {
      ctx.fillStyle = 'rgba(31,191,74,0.9)';
      ctx.font = '10px Consolas, monospace';
      ctx.fillText('нет данных корпуса', 18, size / 2);
      return;
    }
    let minX = Infinity;
    let maxX = -Infinity;
    let minY = Infinity;
    let maxY = -Infinity;
    for (let index = 0; index + 1 < tiles.length; index += 2) {
      minX = Math.min(minX, tiles[index]);
      maxX = Math.max(maxX, tiles[index]);
      minY = Math.min(minY, tiles[index + 1]);
      maxY = Math.max(maxY, tiles[index + 1]);
    }
    const span = Math.max(maxX - minX, maxY - minY) / 2 + 1;
    const cell = (size - 16) / span;
    const reveal = done ? 1 : progress;
    for (let index = 0; index + 1 < tiles.length; index += 2) {
      const x =
        8 +
        ((tiles[index] - minX) / 2) * cell +
        ((span - (maxX - minX) / 2 - 1) * cell) / 2;
      const y =
        8 +
        ((maxY - tiles[index + 1]) / 2) * cell +
        ((span - (maxY - minY) / 2 - 1) * cell) / 2;
      const shown = y / size < reveal;
      ctx.fillStyle = shown ? 'rgba(57,255,106,0.85)' : 'rgba(57,255,106,0.1)';
      ctx.fillRect(x, y, Math.max(1, cell - 1), Math.max(1, cell - 1));
    }
    if (!done) {
      ctx.fillStyle = 'rgba(184,255,201,0.95)';
      ctx.fillRect(0, reveal * size, size, 2);
    }
  }, [tiles, progress, done]);

  return <canvas ref={canvasRef} width={150} height={150} />;
};
