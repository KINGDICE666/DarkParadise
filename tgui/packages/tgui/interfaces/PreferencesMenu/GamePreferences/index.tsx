import { useState } from 'react';
import { Stack } from 'tgui-core/components';

import { PageButton } from '../components/PageButton';
import { GamePreferencesSelectedPage } from '../types';
import { GamePreferencesPage } from './GamePreferencesPage';
import { KeybindingsPage } from './KeybindingsPage';

type Props = {
  startingPage?: GamePreferencesSelectedPage;
};

export function GamePreferenceWindow(props: Props) {
  const [currentPage, setCurrentPage] = useState(
    props.startingPage ?? GamePreferencesSelectedPage.Settings,
  );

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Stack fill>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={GamePreferencesSelectedPage.Settings}
              setPage={setCurrentPage}
            >
              Настройки
            </PageButton>
          </Stack.Item>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={GamePreferencesSelectedPage.Keybindings}
              setPage={setCurrentPage}
            >
              Привязка клавиш
            </PageButton>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Divider />
      <Stack.Item grow shrink basis="1px">
        {currentPage === GamePreferencesSelectedPage.Keybindings ? (
          <KeybindingsPage />
        ) : (
          <GamePreferencesPage />
        )}
      </Stack.Item>
    </Stack>
  );
}
