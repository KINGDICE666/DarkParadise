import { useEffect, useRef } from 'react';

import type { SensorClutter, SensorTrack } from './types';

const HISTORY = 90;
const WIDTH = 360;

type Row = Float32Array;
type Hot = Uint8Array;

const buildRow = (
  tracks: SensorTrack[],
  clutter: SensorClutter[],
  live: boolean,
  haywire: boolean,
) => {
  const row: Row = new Float32Array(WIDTH);
  const hot: Hot = new Uint8Array(WIDTH);
  for (let index = 0; index < WIDTH; index++) {
    row[index] = live ? Math.random() * (haywire ? 0.45 : 0.14) : 0;
    if (haywire && Math.random() < 0.01) hot[index] = 1;
  }
  if (!live) return { row, hot };
  for (const cloud of clutter) {
    for (let step = -12; step <= 12; step++) {
      const bin = (Math.round(cloud.bearing) + step + WIDTH) % WIDTH;
      row[bin] += Math.random() * 0.18 * (1 - Math.abs(step) / 13);
    }
  }
  for (const track of tracks) {
    if (track.source === 'map' || track.source === 'lost') continue;
    const power = Math.max(track.ir, track.em) / 100;
    const width = track.source === 'pas' ? 3 : 2;
    for (let step = -8; step <= 8; step++) {
      const bin = (Math.round(track.bearing) + step + WIDTH) % WIDTH;
      const gain = power * Math.exp(-(step * step) / (2 * width * width));
      row[bin] += gain;
      if (track.source === 'pas' && gain > 0.15) hot[bin] = 1;
    }
  }
  return { row, hot };
};

export const SensorWaterfall = (props: {
  tracks: SensorTrack[];
  clutter: SensorClutter[];
  live: boolean;
  haywire?: boolean;
}) => {
  const { tracks, clutter, live, haywire = false } = props;
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const historyRef = useRef<{ row: Row; hot: Hot }[]>([]);

  useEffect(() => {
    const history = historyRef.current;
    history.unshift(buildRow(tracks, clutter, live, haywire));
    if (history.length > HISTORY) history.length = HISTORY;
    const canvas = canvasRef.current;
    const box = canvas?.parentElement;
    if (!canvas || !box) return;
    canvas.width = box.clientWidth;
    canvas.height = box.clientHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const image = ctx.createImageData(canvas.width, canvas.height);
    const rowHeight = canvas.height / HISTORY;
    for (let y = 0; y < canvas.height; y++) {
      const entry = history[Math.floor(y / rowHeight)];
      const age = y / canvas.height;
      for (let x = 0; x < canvas.width; x++) {
        const offset = (y * canvas.width + x) * 4;
        image.data[offset + 3] = 255;
        if (!entry) continue;
        const bin = Math.floor((x / canvas.width) * WIDTH);
        const value = Math.min(1, entry.row[bin]) * (1 - age * 0.4);
        if (entry.hot[bin]) {
          image.data[offset] = 255 * value;
          image.data[offset + 1] = 179 * value;
          image.data[offset + 2] = 71 * value;
        } else {
          image.data[offset] = 60 * value;
          image.data[offset + 1] = 255 * value;
          image.data[offset + 2] = 194 * value;
        }
      }
    }
    ctx.putImageData(image, 0, 0);
    ctx.fillStyle = 'rgba(170,230,220,0.6)';
    ctx.font = '9px Consolas, monospace';
    for (let bearing = 0; bearing <= 360; bearing += 45) {
      ctx.fillText(
        String(bearing).padStart(3, '0'),
        (bearing / 360) * canvas.width - (bearing === 360 ? 20 : 0) + 2,
        canvas.height - 4,
      );
    }
  }, [tracks, clutter, live, haywire]);

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
    ctx.strokeStyle = 'rgba(93,255,194,0.1)';
    for (let line = 0; line <= size; line += 15) {
      ctx.beginPath();
      ctx.moveTo(line, 0);
      ctx.lineTo(line, size);
      ctx.moveTo(0, line);
      ctx.lineTo(size, line);
      ctx.stroke();
    }
    if (!tiles?.length) {
      ctx.fillStyle = 'rgba(110,144,152,0.8)';
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
      ctx.fillStyle = shown ? 'rgba(93,255,194,0.75)' : 'rgba(93,255,194,0.1)';
      ctx.fillRect(x, y, Math.max(1, cell - 1), Math.max(1, cell - 1));
    }
    if (!done) {
      ctx.fillStyle = 'rgba(170,255,225,0.9)';
      ctx.fillRect(0, reveal * size, size, 2);
    }
  }, [tiles, progress, done]);

  return <canvas ref={canvasRef} width={150} height={150} />;
};
