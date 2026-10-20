import { Button } from 'tgui-core/components';

import type { BooleanLike } from 'tgui-core/react';

import type { Feature, FeatureValueProps } from '../base';

type SpeciesPreferenceServerData = {
  labels: Record<string, string>;
};

export const speciesprefs: Feature<
  BooleanLike,
  boolean,
  SpeciesPreferenceServerData
> = {
  name: 'Расовая особенность',
  component: (
    props: FeatureValueProps<BooleanLike, boolean, SpeciesPreferenceServerData>,
  ) => {
    const { character_preferences, handleSetValue, serverData, value } = props;
    const label =
      serverData?.labels[character_preferences.misc.species] ?? 'Включено';

    return (
      <Button.Checkbox checked={!!value} onClick={() => handleSetValue(!value)}>
        {label}
      </Button.Checkbox>
    );
  },
};
