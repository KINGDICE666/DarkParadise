import { type Feature, type FeatureChoiced, FeatureColorInput } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_ADMIN } from './categories';

export const ooccolor: Feature<string> = {
  name: 'Цвет OOC-сообщений',
  category: CATEGORY_ADMIN,
  description: 'Цвет ваших сообщений в OOC-чате.',
  component: FeatureColorInput,
};

export const atklog: FeatureChoiced = {
  name: 'Отображение боевых сообщений',
  category: CATEGORY_ADMIN,
  component: FeatureDropdownInput,
};
