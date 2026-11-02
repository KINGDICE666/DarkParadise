import { Dropdown, NumberInput, Stack } from 'tgui-core/components';

import type { Feature, FeatureNumericData, FeatureValueProps } from '../base';
import { CATEGORY_GRAPHICS } from './categories';

const DEFAULT_FPS = 0;
const CUSTOM_FPS = 60;
const DEFAULT_OPTION = 'По умолчанию';
const CUSTOM_OPTION = 'Своё значение';

function FpsInput(
  props: FeatureValueProps<number, number, FeatureNumericData>,
) {
  const { handleSetValue, serverData, value } = props;

  return (
    <Stack fill>
      <Stack.Item basis="70%">
        <Dropdown
          selected={value === DEFAULT_FPS ? DEFAULT_OPTION : CUSTOM_OPTION}
          onSelected={(selected) =>
            handleSetValue(
              selected === DEFAULT_OPTION ? DEFAULT_FPS : CUSTOM_FPS,
            )
          }
          width="100%"
          options={[DEFAULT_OPTION, CUSTOM_OPTION]}
        />
      </Stack.Item>

      <Stack.Item>
        {serverData && value !== DEFAULT_FPS && (
          <NumberInput
            onChange={handleSetValue}
            minValue={serverData.minimum}
            maxValue={serverData.maximum}
            value={value}
            step={1}
          />
        )}
      </Stack.Item>
    </Stack>
  );
}

export const clientfps: Feature<number, number, FeatureNumericData> = {
  name: 'FPS',
  category: CATEGORY_GRAPHICS,
  description:
    '-1 — синхронизация с сервером. 20, 40 или 50 могут помочь при проблемах с плавностью.',
  component: FpsInput,
};
