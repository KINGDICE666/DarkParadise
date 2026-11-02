import { CheckboxInput, type FeatureToggle } from '../base';

export const can_be_antagonist: FeatureToggle = {
  name: 'Может быть антагонистом',
  description:
    'Если выключено, при выборе в антагонисты вместо этого персонажа будет взят случайный подходящий.',
  component: CheckboxInput,
};
