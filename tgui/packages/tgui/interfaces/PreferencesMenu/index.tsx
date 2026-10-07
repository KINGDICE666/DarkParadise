import { logger } from 'common/logging';
import { useEffect, useState } from 'react';
import { Box } from 'tgui-core/components';
import { fetchRetry } from 'tgui-core/http';
import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { LoadingScreen } from '../common/LoadingScreen';
import { CharacterPreferenceWindow } from './CharacterPreferences';
import { GamePreferenceWindow } from './GamePreferences';
import {
  GamePreferencesSelectedPage,
  type PreferencesMenuData,
  PrefsWindow,
  type ServerData,
} from './types';
import { ServerPrefs } from './useServerPrefs';

export function PreferencesMenu() {
  const { data } = useBackend<PreferencesMenuData>();
  const [serverData, setServerData] = useState<ServerData>();

  useEffect(() => {
    fetchRetry(resolveAsset('preferences.json'))
      .then((response) => response.json())
      .then((json) => setServerData(json))
      .catch((error) => logger.log('Failed to fetch preferences.json', error));
  }, []);

  const isCharacterWindow = data.window === PrefsWindow.Character;
  let title = 'Настройка персонажа';
  let content;
  if (data.window === PrefsWindow.Game) {
    title = 'Настройки игры';
    content = <GamePreferenceWindow />;
  } else if (data.window === PrefsWindow.Keybindings) {
    title = 'Привязка клавиш';
    content = (
      <GamePreferenceWindow
        startingPage={GamePreferencesSelectedPage.Keybindings}
      />
    );
  }

  return (
    <Window title={title} width={1100} height={770}>
      <Window.Content>
        {serverData ? (
          <ServerPrefs.Provider value={serverData}>
            <Box
              height="100%"
              style={{ display: isCharacterWindow ? undefined : 'none' }}
            >
              <CharacterPreferenceWindow visible={isCharacterWindow} />
            </Box>
            {content}
          </ServerPrefs.Provider>
        ) : (
          <LoadingScreen />
        )}
      </Window.Content>
    </Window>
  );
}
