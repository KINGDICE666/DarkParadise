import { createDropdownInput, type Feature } from '../base';
import { CATEGORY_GRAPHICS } from './categories';

export const zoom: Feature<number> = {
  name: 'Масштабирование пикселей',
  category: CATEGORY_GRAPHICS,
  component: createDropdownInput({
    0: 'Растянуть по окну',
    1: 'Пиксель в пиксель 1x',
    1.5: 'Пиксель в пиксель 1.5x',
    2: 'Пиксель в пиксель 2x',
    3: 'Пиксель в пиксель 3x',
    4: 'Пиксель в пиксель 4x',
    4.5: 'Пиксель в пиксель 4.5x',
    5: 'Пиксель в пиксель 5x',
    6: 'Пиксель в пиксель 6x',
    7: 'Пиксель в пиксель 7x',
    8: 'Пиксель в пиксель 8x',
    9: 'Пиксель в пиксель 9x',
  }),
};
