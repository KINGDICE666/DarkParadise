import type { BridgeObject, HelmData, Weapon } from './types';

export const THROTTLE_STEPS: [string, number][] = [
  ['СТОП', 0],
  ['¼', 0.25],
  ['½', 0.5],
  ['¾', 0.75],
  ['ПОЛНЫЙ', 1],
];

export const decimal = (value: number, digits = 1) =>
  value.toFixed(digits).replace('.', ',');

export const degrees = (value?: number | null) =>
  value === null || value === undefined
    ? '—'
    : `${String(Math.round(((value % 360) + 360) % 360)).padStart(3, '0')}°`;

export const objectCenter = (object: BridgeObject) => {
  const size = Math.max(object.size || 1, 1);
  return [object.x + size / 2 - 0.5, object.y + size / 2 - 0.5];
};

export const cellsTo = (data: HelmData, x: number, y: number) =>
  data.self_pos ? Math.hypot(x - data.self_pos[0], y - data.self_pos[1]) : 0;

export const bearingTo = (data: HelmData, x: number, y: number) => {
  if (!data.self_pos) {
    return null;
  }
  const angle =
    (Math.atan2(x - data.self_pos[0], y - data.self_pos[1]) * 180) / Math.PI;
  return (angle + 360) % 360;
};

const SPEED_DISPLAY_SCALE = 1000;
const DECISECONDS_PER_SECOND = 10;

export const travelText = (data: HelmData, cells: number) => {
  const cruise = Math.max(data.speed || 0, data.cruise || 0);
  if (!cruise) {
    return '—';
  }
  const seconds =
    (cells * SPEED_DISPLAY_SCALE) / cruise / DECISECONDS_PER_SECOND;
  if (seconds < 60) {
    return `≈ ${Math.max(1, Math.round(seconds))} с`;
  }
  return `≈ ${Math.round(seconds / 60)} мин`;
};

export const throttleIndex = (data: HelmData) => {
  if (data.held_brake || !data.max_cruise) {
    return 0;
  }
  const part = (data.cruise || 0) / data.max_cruise;
  let best = 1;
  for (let index = 1; index < THROTTLE_STEPS.length; index++) {
    if (
      Math.abs(THROTTLE_STEPS[index][1] - part) <
      Math.abs(THROTTLE_STEPS[best][1] - part)
    ) {
      best = index;
    }
  }
  return best;
};

export const weaponState = (weapon: Weapon): [string, string] => {
  if (weapon.max_ammo && !weapon.ammo) {
    return ['нет зарядов', 'bad'];
  }
  if (weapon.cooldown > 0) {
    return [`перезарядка ${decimal(weapon.cooldown)} с`, 'wait'];
  }
  if (weapon.in_arc === false || weapon.in_arc === 0) {
    return ['цель вне сектора', 'bad'];
  }
  if (!weapon.ready) {
    return ['не готово', 'bad'];
  }
  return [weapon.in_arc ? 'готов · цель в секторе' : 'готов', 'ok'];
};

export const celestialZone = (object: BridgeObject, cells: number) => {
  if (!object.zones) {
    return null;
  }
  if (cells <= object.zones.core) {
    return 'ядро';
  }
  if (cells <= object.zones.hazard) {
    return 'опасно';
  }
  if (cells <= object.zones.gravity) {
    return 'колодец';
  }
  return 'вне зоны';
};

export const isHostile = (object: BridgeObject) =>
  object.kind === 'unknown' || !!object.distress;
