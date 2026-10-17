import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_GRAPHICS } from './categories';

export const viewrange: FeatureChoiced = {
  name: 'Диапазон обзора',
  category: CATEGORY_GRAPHICS,
  component: FeatureDropdownInput,
};
