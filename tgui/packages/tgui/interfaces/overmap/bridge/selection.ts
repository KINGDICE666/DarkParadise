import { overmapKindIcon, overmapKindLabel } from '../OvermapChrome';
import { formatRadarDistance } from '../OvermapRadar';
import {
  bearingTo,
  celestialZone,
  cellsTo,
  decimal,
  isHostile,
  objectCenter,
  travelText,
} from './bridgeMath';
import type { BridgeObject, HelmData, Post, Selection } from './types';

export type Resolved = {
  name: string;
  sub: string;
  icon: string;
  color?: string | null;
  danger: boolean;
  range: string;
  bearing: number | null;
  third: [string, string];
  object?: BridgeObject;
  dockId?: string;
  point?: [number, number];
  lockable: boolean;
};

const LOCKABLE = ['shuttle', 'pod', 'station', 'unknown'];

export const kindLabel = (kind?: string) => {
  switch (kind) {
    case 'star':
      return 'звезда';
    case 'black_hole':
      return 'чёрная дыра';
    default:
      return overmapKindLabel(kind);
  }
};

export const kindIcon = (kind?: string) => {
  switch (kind) {
    case 'star':
      return 'sun';
    case 'black_hole':
      return 'circle';
    default:
      return overmapKindIcon(kind);
  }
};

export const visibleObjects = (data: HelmData) =>
  (data.objects || [])
    .filter((object) => !object.is_self && object.kind !== 'hazard')
    .map((object) => {
      const [x, y] = objectCenter(object);
      return { object, cells: cellsTo(data, x, y) };
    })
    .sort((a, b) => a.cells - b.cells);

export const contactNote = (
  data: HelmData,
  object: BridgeObject,
  cells: number,
) => {
  if (object.id && object.id === data.navigation_target_id) {
    return 'цель маршрута';
  }
  if (object.id && object.id === data.fire_target?.id) {
    return 'цель захвачена';
  }
  if (object.zones) {
    const zone = celestialZone(object, cells);
    return zone === 'вне зоны' ? kindLabel(object.kind) : `опасно · ${zone}`;
  }
  if (object.kind === 'unknown') {
    return 'не опознан';
  }
  if (object.distress) {
    return 'сигнал бедствия';
  }
  if (object.kind === 'relay' && object.leads_to) {
    return `в «${object.leads_to}»`;
  }
  return kindLabel(object.kind);
};

export const resolveSelection = (
  data: HelmData,
  selection: Selection,
): Resolved | null => {
  if (!selection) {
    return null;
  }
  const span = data.cell_span || 100;
  const world = data.radar_world;
  if (selection.kind === 'object') {
    const object = (data.objects || []).find(
      (entry) => entry.id === selection.id,
    );
    if (!object) {
      return null;
    }
    const [x, y] = objectCenter(object);
    const cells = cellsTo(data, x, y);
    const ship = LOCKABLE.includes(object.kind);
    const zone = celestialZone(object, cells);
    return {
      name: object.name,
      sub:
        object.kind === 'relay' && object.leads_to
          ? `ретранслятор · ведёт в «${object.leads_to}»`
          : contactNote(data, object, cells),
      icon: object.distress ? 'triangle-exclamation' : kindIcon(object.kind),
      color: object.color,
      danger: isHostile(object) || (!!zone && zone !== 'вне зоны'),
      range: `${decimal(cells)} кл`,
      bearing: bearingTo(data, x, y),
      third: zone
        ? ['ЗОНА', zone]
        : ship && object.speed !== undefined
          ? ['СКОРОСТЬ', `${decimal(object.speed)} м/с`]
          : ['В ПУТИ', travelText(data, cells)],
      object,
      lockable: ship,
    };
  }
  if (selection.kind === 'dock') {
    const dock = data.radar_docks?.find((entry) => entry.id === selection.id);
    if (!dock) {
      return null;
    }
    const metres = world ? Math.hypot(dock.x - world[0], dock.y - world[1]) : 0;
    return {
      name: dock.name,
      sub:
        dock.available === false || dock.available === 0
          ? 'шлюз · занят'
          : 'шлюз · свободен',
      icon: 'anchor',
      danger: false,
      range: formatRadarDistance(metres, span),
      bearing: world
        ? ((Math.atan2(dock.x - world[0], dock.y - world[1]) * 180) / Math.PI +
            360) %
          360
        : null,
      third: ['В ПУТИ', travelText(data, metres / span)],
      dockId: dock.id,
      lockable: false,
    };
  }
  const cells = world
    ? Math.hypot(selection.x - world[0], selection.y - world[1]) / span
    : 0;
  return {
    name: 'Метка',
    sub: 'точка в пространстве',
    icon: 'location-dot',
    danger: false,
    range: `${decimal(cells)} кл`,
    bearing: world
      ? ((Math.atan2(selection.x - world[0], selection.y - world[1]) * 180) /
          Math.PI +
          360) %
        360
      : null,
    third: ['В ПУТИ', travelText(data, cells)],
    point: [selection.x, selection.y],
    lockable: false,
  };
};

export type BridgeAction = 'course' | 'lock' | 'approach';

export const POST_ACTIONS: Record<Post, BridgeAction[]> = {
  nav: ['course', 'lock', 'approach'],
  tac: ['lock', 'course', 'approach'],
  dock: ['approach', 'course', 'lock'],
};

export const ACTION_LABELS: Record<BridgeAction, string> = {
  course: 'ПРОЛОЖИТЬ КУРС',
  lock: 'ЗАХВАТ',
  approach: 'ЗАХОД',
};

export const actionAvailable = (
  action: BridgeAction,
  resolved: Resolved,
  flightLocked: boolean,
) => {
  switch (action) {
    case 'lock':
      return resolved.lockable;
    case 'course':
      return !flightLocked && !resolved.dockId;
    case 'approach':
      return !flightLocked && (!!resolved.dockId || !!resolved.object);
  }
};

export const runAction = (
  act: (action: string, params?: Record<string, unknown>) => void,
  action: BridgeAction,
  resolved: Resolved,
) => {
  if (action === 'lock') {
    if (resolved.object?.id) {
      act('lock_target', { id: resolved.object.id });
    }
    return;
  }
  if (resolved.dockId) {
    act('select_radar_dock', { id: resolved.dockId });
    return;
  }
  if (resolved.object) {
    act('nav_dest', {
      id: resolved.object.id,
      x: resolved.object.x,
      y: resolved.object.y,
      name: resolved.object.name,
    });
    return;
  }
  if (resolved.point) {
    act('nav_point', { x: resolved.point[0], y: resolved.point[1] });
  }
};
