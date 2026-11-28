import type { BooleanLike } from 'tgui-core/react';

export type SensorClass = {
  label: string;
  chance: number;
};

export type SensorTrack = {
  ref: string;
  id: string;
  name?: string | null;
  kind: string;
  source: string;
  bearing: number;
  range: number;
  range_err?: number;
  quality: number;
  age: number;
  ir: number;
  em: number;
  mass: number;
  locked?: BooleanLike;
  can_scan?: BooleanLike;
  classes: SensorClass[];
  speed?: number;
  heading?: number;
  transponder?: BooleanLike;
  closing?: number;
  cpa?: number;
  cpa_time?: number;
  cpa_bearing?: number;
  trail?: number[][];
  shadow?: BooleanLike;
  ghost?: BooleanLike;
};

export type SensorClutter = {
  bearing: number;
  range: number;
  density: number;
  name: string;
};

export type SensorEmission = {
  ir: number;
  em: number;
  mass: number;
  level: string;
};

export type SensorStatus = {
  passive: string;
  active: string;
  lock?: string | null;
  haywire?: number | null;
  painted?: string | null;
  lost?: string | null;
};
