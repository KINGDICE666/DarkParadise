import {
  type Feature,
  FeatureColorInput,
  type FeatureNumeric,
  FeatureSliderInput,
} from '../base';
import { CATEGORY_INTERFACE } from './categories';

export const screentip_mode: FeatureNumeric = {
  name: 'Подсказки: размер',
  category: CATEGORY_INTERFACE,
  description:
    'Размер текста подсказки при наведении на предмет. 0 — подсказки выключены. Рекомендуется от 8 до 15.',
  component: FeatureSliderInput,
};

export const screentip_color: Feature<string> = {
  name: 'Подсказки: цвет',
  category: CATEGORY_INTERFACE,
  description: 'Цвет текста подсказки при наведении на предмет.',
  component: FeatureColorInput,
};
