import type { BooleanLike } from 'tgui-core/react';

import { CATEGORY_ICONS, CATEGORY_NAMES, TOOL_NAMES } from './constants';
import type { CraftingData } from './types';

export function findIcon(atom_id: number, data: CraftingData): string {
  return data.icon_data[atom_id] || `crafting32x32 a${atom_id}`;
}

export function getFAIcon(category: string): string {
  return CATEGORY_ICONS[category] || 'circle';
}

export function getCategoryName(category: string): string {
  return CATEGORY_NAMES[category] || category;
}

export function getToolName(tool: string): string {
  return TOOL_NAMES[tool] || tool;
}

export function formatAmount(amount: number, is_reagent: BooleanLike): string {
  if (is_reagent) {
    return `\xa0${amount}\xa0ед.`;
  }
  return amount > 1 ? `\xa0${amount}x` : '';
}

export function toggleArrayItem<T>(array: T[] | undefined, item: T): T[] {
  if (!array) return [item];
  return array.includes(item)
    ? array.filter((i) => i !== item)
    : [...array, item];
}
