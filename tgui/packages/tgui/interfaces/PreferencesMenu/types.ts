import type { BooleanLike } from 'tgui-core/react';

import type { sendAct } from '../../events/act';

export enum PrefsWindow {
  Character = 0,
  Game = 1,
  Keybindings = 2,
}

export enum GamePreferencesSelectedPage {
  Settings,
  Keybindings,
}

export type CharacterPreferencesData = {
  clothing: Record<string, string>;
  features: Record<string, string>;
  game_preferences: Record<string, unknown>;
  non_contextual: Record<string, unknown>;
  secondary_features: Record<string, unknown>;
  supplemental_features: Record<string, unknown>;
  manually_rendered_features: Record<string, unknown>;
  names: Record<string, string>;
  valid_choices: Record<string, (string | number)[]>;
  valid_ranges: Record<string, [number, number]>;
};

export type LegacyToggle = {
  key: string;
  name: string;
  description: string;
  category: number;
  special: BooleanLike;
  enabled: BooleanLike;
};

export type BodyStatus = {
  zone: string;
  name: string;
  status: string;
};

export type PreferencesMenuData = {
  character_preview_view: string;
  character_profiles: (string | null)[];
  character_preferences: CharacterPreferencesData;
  content_unlocked: BooleanLike;
  max_save_slots: number;
  active_slot: number;
  saved: BooleanLike;
  window: PrefsWindow;

  keybindings: Record<string, string[]>;
  custom_emotes: Record<string, string>;

  legacy_toggles: LegacyToggle[];

  selected_antags: string[];
  locked_antags: Record<string, string>;
  skip_antag: BooleanLike;

  disabilities: number;
  available_disabilities: number[];

  limbs: BodyStatus[];
  organs: BodyStatus[];
  ipc_loadout: BooleanLike;

  jobs_page: unknown;
  loadout_page: Record<string, unknown>;
  loadout_static: Record<string, unknown>;
  tts_seed: string | null;
  tts_enabled: BooleanLike;
  appearance_banned: BooleanLike;
};

export type ChoicedServerData = {
  choices: (string | number)[];
  display_names?: Record<string, string>;
  icons?: Record<string, string | null>;
  icon_sheet?: string;
  name?: string;
};

export type NumericServerData = {
  minimum: number;
  maximum: number;
  step: number;
};

export type SpeciesData = {
  name: string;
  desc: string;
  icon: string;
  has_gender: BooleanLike;
};

export type ServerData = {
  species: Record<string, SpeciesData>;
  disabilities: { flag: number; name: string }[];
  legacy_toggles: { categories: { id: number; name: string }[] };
  antags: { antagonists: { key: string; name: string; icon: string | null }[] };
  [otherKey: string]: unknown;
};

export const createSetPreference =
  (act: typeof sendAct, preference: string) => (value: unknown) => {
    act('set_preference', {
      preference,
      value,
    });
  };
