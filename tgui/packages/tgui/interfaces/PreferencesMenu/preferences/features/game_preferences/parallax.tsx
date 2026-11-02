import type { Feature } from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_GRAPHICS } from './categories';

export const parallax: Feature<string> = {
  name: 'Параллакс',
  category: CATEGORY_GRAPHICS,
  component: FeatureDropdownInput,
};

export const multiz_detail: Feature<string> = {
  name: 'Качество Multi-Z параллакса',
  category: CATEGORY_GRAPHICS,
  description:
    'Сколько уровней Multi-Z отрисовывается. Уменьшите при проблемах с производительностью.',
  component: FeatureDropdownInput,
};
