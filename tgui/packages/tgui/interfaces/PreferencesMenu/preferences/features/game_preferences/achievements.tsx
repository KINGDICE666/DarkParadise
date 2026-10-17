import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_INTERFACE } from './categories';

export const achivements_sound: FeatureChoiced = {
  name: 'Звук получения достижения',
  category: CATEGORY_INTERFACE,
  component: FeatureDropdownInput,
};
