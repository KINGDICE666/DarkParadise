import {
  type Feature,
  FeatureColorInput,
  type FeatureNumeric,
  FeatureSliderInput,
} from './base';

export const eye_colour: Feature<string> = {
  name: 'Цвет глаз',
  component: FeatureColorInput,
};

export const skin_colour: Feature<string> = {
  name: 'Цвет кожи',
  component: FeatureColorInput,
};

export const hair_colour: Feature<string> = {
  name: 'Цвет причёски',
  component: FeatureColorInput,
};

export const secondary_hair_colour: Feature<string> = {
  name: 'Дополнительный цвет причёски',
  component: FeatureColorInput,
};

export const facial_hair_colour: Feature<string> = {
  name: 'Цвет лицевой растительности',
  component: FeatureColorInput,
};

export const secondary_facial_hair_colour: Feature<string> = {
  name: 'Дополнительный цвет лицевой растительности',
  component: FeatureColorInput,
};

export const hair_gradient_colour: Feature<string> = {
  name: 'Цвет градиента',
  component: FeatureColorInput,
};

export const hair_gradient_alpha: FeatureNumeric = {
  name: 'Сила градиента',
  component: (props) => (
    <FeatureSliderInput
      {...props}
      format={(value) => `${Math.round((value / 255) * 100)}%`}
    />
  ),
};

export const head_accessory_colour: Feature<string> = {
  name: 'Цвет аксессуаров на голове',
  component: FeatureColorInput,
};

export const head_marking_colour: Feature<string> = {
  name: 'Цвет отметок на голове',
  component: FeatureColorInput,
};

export const body_marking_colour: Feature<string> = {
  name: 'Цвет отметок на теле',
  component: FeatureColorInput,
};

export const tail_marking_colour: Feature<string> = {
  name: 'Цвет отметок на хвосте',
  component: FeatureColorInput,
};

export const underwear_color: Feature<string> = {
  name: 'Цвет нижнего белья',
  component: FeatureColorInput,
};

export const undershirt_color: Feature<string> = {
  name: 'Цвет нательной рубашки',
  component: FeatureColorInput,
};
