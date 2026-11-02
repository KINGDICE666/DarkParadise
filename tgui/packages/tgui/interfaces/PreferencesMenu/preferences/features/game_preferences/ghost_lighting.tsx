import type { FeatureChoiced } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_GHOST } from './categories';

export const ghost_darkness_level: FeatureChoiced = {
  name: 'Освещённость для призрака',
  category: CATEGORY_GHOST,
  description: 'Насколько светло вокруг, пока вы призрак.',
  component: FeatureDropdownInput,
};
