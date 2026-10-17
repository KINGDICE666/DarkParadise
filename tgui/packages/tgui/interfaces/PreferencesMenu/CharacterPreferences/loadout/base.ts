import type { BooleanLike } from 'tgui-core/react';

import type { PreferencesMenuData } from '../../types';
import type { LoadoutButton } from './ModifyPanel';

export type DmIconFile = string;
export type DmIconState = string;
export type FAIcon = string;
export type typePath = string;

type LoadoutInfoKey = string;
type LoadoutInfoValue = string;
type LoadoutListInfo = Record<LoadoutInfoKey, LoadoutInfoValue> | [];
export type LoadoutList = Record<typePath, LoadoutListInfo>;

export type ReskinOption = {
  name: string;
  tooltip: string;
  skin_icon: DmIconFile | null;
  skin_icon_state: DmIconState;
};

export type LoadoutTooltip = {
  icon: string;
  tooltip: string;
};

export type LoadoutItem = {
  name: string;
  group: string;
  path: typePath;
  icon: DmIconFile | null;
  icon_state: DmIconState | null;
  buttons: LoadoutButton[];
  reskins: ReskinOption[] | null;
  information: LoadoutTooltip[];
};

export type LoadoutCategory = {
  name: string;
  category_icon: FAIcon | null;
  category_info: string | null;
  contents: LoadoutItem[];
};

export type LoadoutManagerData = PreferencesMenuData & {
  job_clothes: BooleanLike;
  loadout_points: number;
  max_loadout_points: number;
};
