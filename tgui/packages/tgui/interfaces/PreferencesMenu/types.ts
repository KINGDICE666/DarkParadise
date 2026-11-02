import type { BooleanLike } from 'tgui-core/react';

import type { sendAct } from '../../events/act';
import type {
  LoadoutCategory,
  LoadoutList,
} from './CharacterPreferences/loadout/base';
import type { Gender } from './preferences/gender';

export enum Food {
  Alcohol = 'ALCOHOL',
  Breakfast = 'BREAKFAST',
  Bugs = 'BUGS',
  Cloth = 'CLOTH',
  Dairy = 'DAIRY',
  Fried = 'FRIED',
  Fruit = 'FRUIT',
  Gore = 'GORE',
  Grain = 'GRAIN',
  Gross = 'GROSS',
  Junkfood = 'JUNKFOOD',
  Meat = 'MEAT',
  Nuts = 'NUTS',
  Oranges = 'ORANGES',
  Pineapple = 'PINEAPPLE',
  Raw = 'RAW',
  Seafood = 'SEAFOOD',
  Stone = 'STONE',
  Sugar = 'SUGAR',
  Toxic = 'TOXIC',
  Vegetables = 'VEGETABLES',
  Egg = 'EGG',
}

export enum JobPriority {
  Low = 1,
  Medium = 2,
  High = 3,
}

export type Name = {
  can_randomize: BooleanLike;
  explanation: string;
  group: string;
};

export type Species = {
  name: string;
  desc: string;
  lore: string[];
  icon: string;

  use_skintones: BooleanLike;
  sexes: BooleanLike;

  enabled_features: string[];

  perks: {
    positive: Perk[];
    negative: Perk[];
    neutral: Perk[];
  };

  diet?: {
    liked_food: Food[];
    disliked_food: Food[];
    toxic_food: Food[];
  };
};

export type Perk = {
  ui_icon: string;
  name: string;
  description: string;
};

export type Department = {
  head?: string;
  name: string;
};

export type Job = {
  name: string;
  description: string | null;
  department: string;
  exclusive: BooleanLike;
  alt_titles: BooleanLike;
};

export type Quirk = {
  description: string;
  icon: string;
  name: string;
  value: number;
  customizable: boolean;
  customization_options?: string[];
};

export type QuirkInfo = {
  max_positive_quirks: number;
  quirk_info: Record<string, Quirk>;
  quirk_blacklist: string[][];
  points_enabled: boolean;
};

export type BodyStatus = {
  zone: string;
  name: string;
  status: string;
  state: string;
};

export type LegacyToggle = {
  name: string;
  description: string;
  category: string;
};

export enum RandomSetting {
  AntagOnly = 1,
  Disabled = 2,
  Enabled = 3,
}

export enum JoblessRole {
  BeRandomJob = 0,
  BeOverflow = 1,
  ReturnToLobby = 2,
}

export enum GamePreferencesSelectedPage {
  Settings,
  Keybindings,
}

export const createSetPreference =
  (act: typeof sendAct, preference: string) => (value: unknown) => {
    act('set_preference', {
      preference,
      value,
    });
  };

export enum PrefsWindow {
  Character = 0,
  Game = 1,
  Keybindings = 2,
}

export type CharacterPreferencesData = {
  clothing: Record<string, string>;
  features: Record<string, string>;
  game_preferences: Record<string, unknown>;
  non_contextual: {
    random_body: RandomSetting;
    [otherKey: string]: unknown;
  };
  secondary_features: Record<string, unknown>;
  supplemental_features: Record<string, unknown>;
  manually_rendered_features: Record<string, string>;

  names: Record<string, string>;

  misc: {
    gender: Gender;
    alternate_option: JoblessRole;
    species: string;
    loadout_list: LoadoutList;
  };

  randomization: Record<string, RandomSetting>;
  valid_choices: Record<string, string[]>;
  valid_ranges: Record<string, [number, number]>;
};

export type PreferencesMenuData = {
  character_preview_view: string;
  character_profiles: (string | null)[];

  character_preferences: CharacterPreferencesData;

  content_unlocked: BooleanLike;

  job_bans?: string[];
  job_days_left?: Record<string, number>;
  job_required_experience?: Record<
    string,
    {
      experience_type: string;
      required_playtime: number;
    }
  >;
  job_preferences: Record<string, JobPriority>;
  job_titles: Record<string, string>;
  job_restrictions: Record<string, string>;

  keybindings: Record<string, string[]>;
  custom_emotes: Record<string, string>;
  default_quirk_balance: number;
  selected_quirks: string[];
  species_disallowed_quirks: string[];

  hair_gradient_previews?: Record<string, string>;

  limbs: BodyStatus[];
  organs: BodyStatus[];
  ipc_loadout: BooleanLike;

  antag_bans?: string[];
  antag_days_left?: Record<string, number>;
  antag_playtime_left?: Record<string, number>;
  selected_antags: string[];

  active_slot: number;
  name_to_use: string;

  window: PrefsWindow;
  starting_page: string | null;
  page_request: number;
};

export type ServerData = {
  jobs: {
    departments: Record<string, Department>;
    jobs: Record<string, Job>;
  };
  names: {
    types: Record<string, Name>;
  };
  disabilities: QuirkInfo;
  random: {
    randomizable: string[];
  };
  loadout: {
    loadout_tabs: LoadoutCategory[];
  };
  species: Record<string, Species>;
  legacy_toggles: Record<string, LegacyToggle>;
  [otherKey: string]: unknown;
};
