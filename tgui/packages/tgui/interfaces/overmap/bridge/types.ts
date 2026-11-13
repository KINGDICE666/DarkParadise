import type { BooleanLike } from 'tgui-core/react';

import type {
  GalaxyMap,
  HazardField,
  RadarContact,
  RadarObject,
  RadarPeel,
  RadarProjectile,
  RadarScatterChunk,
  RadarShape,
  RadarTerrain,
} from '../OvermapRadar';
import type { RadarDock } from '../radarInterpolation';

export type Post = 'nav' | 'tac' | 'dock';

export type Selection =
  | { kind: 'object'; id: string }
  | { kind: 'dock'; id: string }
  | { kind: 'point'; x: number; y: number }
  | null;

export type DockPick = { kind: 'airlock' | 'pad'; id: string } | null;

export type EngineInfo = {
  name: string;
  ref: string;
  on: BooleanLike;
  thrust: number;
  status: string;
  heat?: number;
};

export type LandingPad = {
  id: string;
  name: string;
  can_dock: BooleanLike;
  reason?: string;
};

export type ProgrammedRoute = {
  id: string;
  name: string;
};

export type Waypoint = {
  name: string;
  x: number;
  y: number;
};

export type Weapon = {
  id: string;
  name: string;
  selected: BooleanLike;
  auto: BooleanLike;
  turret: BooleanLike;
  cooldown: number;
  arc: number;
  heading: number;
  x: number;
  y: number;
  ammo?: number | null;
  max_ammo?: number | null;
  kind?: string;
  ready?: BooleanLike;
  in_arc?: BooleanLike | null;
  cooldown_max?: number;
};

export type FireTarget = {
  id: string;
  name: string;
  distance: number;
  speed: number;
  shield: number;
};

export type ShieldInfo = {
  charge: number;
  capacity: number;
  generators: number;
  active: BooleanLike;
};

export type BridgeNotice = {
  text: string;
  tone?: 'warn' | 'danger' | null;
  origin?: string | null;
  age: number;
};

export type BridgeObject = RadarObject & {
  speed?: number;
  status?: string;
  identified?: BooleanLike;
};

export type HelmData = {
  linked: BooleanLike;
  gunner?: BooleanLike;
  cruise?: number;
  max_cruise?: number;
  held_brake?: BooleanLike;
  overdrive?: BooleanLike;
  notice?: BridgeNotice | null;
  fire_target?: FireTarget | null;
  free_fire?: BooleanLike;
  shield?: ShieldInfo | null;
  drift_assist?: BooleanLike;
  heading_hold?: 'prograde' | 'retrograde' | 'current' | null;
  hold_angle?: number | null;
  precision?: BooleanLike;
  can_turn?: BooleanLike;
  turn_rate?: number;
  brake_distance?: number;
  velocity_heading?: number | null;
  vessel_name: string;
  status: string;
  phase: 'route' | 'relay' | 'docked' | 'transit' | 'flight';
  x: number;
  y: number;
  sector_id?: string;
  sector_name?: string;
  sector_size: number;
  sector_neighbors?: Record<string, string>;
  cell_span?: number;
  self_pos?: number[];
  speed: number;
  facing: number;
  nose?: number;
  station_ship?: BooleanLike;
  docked_craft?: { id: string; name: string; busy: BooleanLike }[];
  local_space?: BooleanLike;
  radar_reach?: number;
  map_jammed: BooleanLike;

  is_pod?: BooleanLike;
  can_steer: BooleanLike;
  piloting: BooleanLike;
  pilot_name?: string | null;
  autopilot: BooleanLike;
  autopilot_status?: string;
  eta?: number;
  navigation_target_id?: string;
  programmed_cancellable?: BooleanLike;

  dest?: number[];
  dest_name?: string;
  dest_range?: number;
  dest_relay?: string;

  can_undock: BooleanLike;
  can_ship_undock?: BooleanLike;
  ship_docked_to?: string | null;
  can_relay_jump?: BooleanLike;
  relay_to?: string;
  can_land?: BooleanLike;
  can_stop?: BooleanLike;
  host_name?: string;
  docks?: LandingPad[];
  dock_name?: string;
  dock_distance?: number;
  dock_aligning?: BooleanLike;

  engines: EngineInfo[];
  thrust_hint?: string;
  has_transponder: BooleanLike;
  transponder: { broadcasting: BooleanLike } | null;
  distress?: BooleanLike;
  broadcasting?: BooleanLike;
  weapons?: Weapon[];

  radar_outlines?: Record<string, string>;
  radar_peels?: RadarPeel[];
  radar_scatter?: RadarScatterChunk[];
  radar_docks?: RadarDock[];
  dock_preview?: { x: number; y: number; facing: number; tiles: number[] };
  radar_locked?: BooleanLike;
  radar_tick?: number;
  radar_epoch?: number;
  radar_shapes?: Record<string, RadarShape>;
  radar?: RadarContact[];
  radar_drifters?: number[][];
  radar_projectiles?: RadarProjectile[];
  radar_terrain?: RadarTerrain | null;
  radar_world?: number[];
  galaxy?: GalaxyMap | null;
  objects: BridgeObject[];
  hazard_fields?: HazardField[];
  waypoints?: Waypoint[];

  programmed_locked?: BooleanLike;
  programmed_has_routes?: BooleanLike;
  programmed_busy?: BooleanLike;
  programmed_windup?: number;
  programmed_eta?: string;
  programmed_selected?: string;
  programmed_routes?: ProgrammedRoute[];
};
