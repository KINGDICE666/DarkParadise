import type { BooleanLike } from 'tgui-core/react';

export enum TABS {
  category,
  material,
}

export type AtomData = {
  name: string;
  is_reagent: BooleanLike;
};

export type Material = {
  atom_id: string;
  occurences: number;
};

export type Recipe = {
  category: string;
  subcategory: string;
  chem_catalysts?: Record<number, number>;
  desc?: string;
  id: number;
  name: string;
  ref: string;
  reqs: Record<number, number>;
  tool_behaviors?: string[];
  tool_paths?: string[];
};

export type CraftingData = {
  busy: BooleanLike;
  craftability: Record<string, BooleanLike>;
  display_compact: BooleanLike;
  display_craftable_only: BooleanLike;
  atom_data: AtomData[];
  categories: string[];
  icon_data: Record<number, string>;
  material_occurences: Material[];
  recipes: Recipe[];
};
