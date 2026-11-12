import type { Placement } from '@floating-ui/react';
import type { BooleanLike } from 'tgui-core/react';

export type PodLauncherData = {
  bayNumber: string;
  custom_rev_delay: number;
  customDropoff: BooleanLike;
  damageChoice: number;
  defaultSoundVolume: number;
  delays: Record<string, number>;
  effectAnnounce: BooleanLike;
  effectBluespace: BooleanLike;
  effectBurst: BooleanLike;
  effectCircle: BooleanLike;
  effectGas: BooleanLike;
  effectLimb: BooleanLike;
  effectMissile: BooleanLike;
  effectName: number;
  effectOrgans: BooleanLike;
  effectQuiet: BooleanLike;
  effectReverse: BooleanLike;
  effectShrapnel: BooleanLike;
  effectStealth: BooleanLike;
  effectStun: BooleanLike;
  effectTarget: string | null;
  explosionChoice: number;
  fallingSound: BooleanLike;
  gasNames: Record<string, string>;
  gasRelease: Record<string, PodGas>;
  giveLauncher: BooleanLike;
  landingSound: string | null;
  launchChoice: number;
  launchClone: BooleanLike;
  launchRandomItem: BooleanLike;
  leavingSound: string | null;
  mapRef: string;
  numObjects: number;
  oldArea: string | null;
  openingSound: string | null;
  payload: BooleanLike;
  picking_dropoff_turf: BooleanLike;
  podDesc: string;
  podName: string;
  renderLighting: BooleanLike;
  rev_delays: Record<string, number>;
  reverse_option_list: Record<string, BooleanLike>;
  shrapnelMagnitude: number;
  shrapnelType: string;
  soundVolume: number;
  styleChoice: string;
  tabIndex: number;
  podStyles: Array<Record<string, string>>;
};

export type PodGas = {
  amount: number;
  rate: number;
};

export type PodDelay = {
  title: string;
  tooltip: string;
};

export type PodEffect =
  | {
      act: string;
      choiceNumber?: number;
      content?: string;
      divider?: never;
      icon: string;
      payload?: Record<string, any>;
      selected?: string;
      soloSelected?: string;
      title: string;
      tooltipPosition?: Placement;
    }
  | { divider: boolean };
