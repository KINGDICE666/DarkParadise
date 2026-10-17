import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_GRAPHICS } from './categories';

export const zoom_mode: FeatureChoiced = {
  name: 'Метод масштабирования',
  category: CATEGORY_GRAPHICS,
  component: FeatureDropdownInput,
};
