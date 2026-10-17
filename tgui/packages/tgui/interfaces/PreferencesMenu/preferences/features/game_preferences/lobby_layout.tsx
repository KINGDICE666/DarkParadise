import { useBackend } from 'tgui/backend';
import { Button, Stack } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import type {
  FeatureChoiced,
  FeatureChoicedServerData,
  FeatureValueProps,
} from '../base';
import { FeatureDropdownInput } from '../dropdowns';
import { CATEGORY_INTERFACE } from './categories';

type LobbyLayoutData = {
  lobby_layout_editable: BooleanLike;
};

function LobbyLayoutInput(
  props: FeatureValueProps<string, string, FeatureChoicedServerData>,
) {
  const { act, data } = useBackend<LobbyLayoutData>();

  return (
    <Stack>
      <Stack.Item grow>
        <FeatureDropdownInput {...props} />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="up-down-left-right"
          disabled={!data.lobby_layout_editable}
          tooltip={
            data.lobby_layout_editable
              ? 'Расставить блоки лобби мышью'
              : 'Доступно только в лобби'
          }
          onClick={() => act('edit_lobby_layout')}
        >
          Вручную
        </Button>
      </Stack.Item>
    </Stack>
  );
}

export const lobby_layout: FeatureChoiced = {
  name: 'Раскладка лобби',
  category: CATEGORY_INTERFACE,
  description:
    'Где в лобби находятся меню, статус раунда, ссылки и надписи. «Вручную» позволяет перетащить блоки мышью.',
  component: LobbyLayoutInput,
};
