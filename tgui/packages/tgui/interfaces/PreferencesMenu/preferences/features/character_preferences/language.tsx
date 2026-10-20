import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';

export const language: FeatureChoiced = {
  name: 'Дополнительный язык',
  component: FeatureDropdownInput,
};

export const autohiss: FeatureChoiced = {
  name: 'Авто-акцент',
  description: 'Заменяет звуки в речи на характерные для вашей расы.',
  component: FeatureDropdownInput,
};
