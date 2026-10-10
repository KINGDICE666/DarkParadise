import { useEffect, useState } from 'react';
import { Box, Button, Modal, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import type { PreferencesMenuData } from '../types';

type Props = {
  close: () => void;
};

export function DeleteCharacterPopup(props: Props) {
  const { data, act } = useBackend<PreferencesMenuData>();
  const [secondsLeft, setSecondsLeft] = useState(3);

  const { close } = props;

  useEffect(() => {
    const interval = setInterval(() => {
      setSecondsLeft((current) => current - 1);
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <Modal>
      <Stack vertical textAlign="center" align="center">
        <Stack.Item>
          <Box fontSize="3em">Стойте!</Box>
        </Stack.Item>

        <Stack.Item maxWidth="300px">
          <Box>{`Вы собираетесь навсегда удалить персонажа ${data.character_preferences.names.real_name}. Вы уверены?`}</Box>
        </Stack.Item>

        <Stack.Item>
          <Stack fill>
            <Stack.Item>
              <Button
                color="danger"
                disabled={secondsLeft > 0}
                width="100px"
                onClick={() => {
                  act('remove_current_slot');
                  close();
                }}
              >
                {secondsLeft <= 0 ? 'Удалить' : `Удалить (${secondsLeft})`}
              </Button>
            </Stack.Item>

            <Stack.Item>
              <Button onClick={close}>Нет, не удалять</Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Modal>
  );
}
