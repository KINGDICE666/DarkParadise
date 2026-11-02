import { Box, Dropdown, Stack } from 'tgui-core/components';

import type { Feature, FeatureNumericData, FeatureValueProps } from '../base';

type SkinTonePreset = {
  value: number;
  name: string;
  color: string;
};

type SkinToneServerData = FeatureNumericData & {
  icon_tone_names: Record<string, string[]>;
  presets: SkinTonePreset[];
};

function ToneSwatch(props: { color: string; name: string }) {
  return (
    <Stack align="center" fill>
      <Stack.Item>
        <Box
          style={{
            background: props.color,
            border: '2px solid white',
            boxSizing: 'content-box',
            height: '11px',
            width: '11px',
          }}
        />
      </Stack.Item>

      <Stack.Item grow>{props.name}</Stack.Item>
    </Stack>
  );
}

export const skin_tone: Feature<number, number, SkinToneServerData> = {
  name: 'Тон кожи',
  component: (props: FeatureValueProps<number, number, SkinToneServerData>) => {
    const { character_preferences, handleSetValue, serverData, value } = props;

    if (!serverData) {
      return null;
    }

    const toneNames =
      serverData.icon_tone_names[character_preferences.misc.species];

    const options = toneNames
      ? toneNames.map((name, index) => ({
          displayText: name,
          value: String(index + 1),
        }))
      : serverData.presets.map((preset) => ({
          displayText: <ToneSwatch color={preset.color} name={preset.name} />,
          value: String(preset.value),
        }));

    const selected = options.find((option) => option.value === String(value));

    return (
      <Dropdown
        buttons
        displayText={selected?.displayText}
        onSelected={(newValue) => handleSetValue(Number(newValue))}
        options={options}
        selected={String(value)}
        width="100%"
      />
    );
  },
};
