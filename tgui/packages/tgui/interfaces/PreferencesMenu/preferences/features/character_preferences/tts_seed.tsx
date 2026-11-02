import { useBackend } from 'tgui/backend';
import { Button, Stack } from 'tgui-core/components';

import type { Feature, FeatureValueProps } from '../base';

function FeatureTTSSeedInput(props: FeatureValueProps<string>) {
  const { act } = useBackend();

  return (
    <Stack>
      <Stack.Item grow>
        <Button
          fluid
          icon="microphone"
          onClick={() => act('open_tts_explorer')}
        >
          {props.value || 'Не выбран'}
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button
          disabled={!props.value}
          icon="play"
          tooltip="Прослушать"
          onClick={() => act('play_voice')}
        />
      </Stack.Item>
    </Stack>
  );
}

export const tts_seed: Feature<string> = {
  name: 'Голос',
  component: FeatureTTSSeedInput,
};
