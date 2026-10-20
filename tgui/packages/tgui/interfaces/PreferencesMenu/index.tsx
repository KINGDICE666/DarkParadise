import { logger } from 'common/logging';
import { Suspense, useEffect, useState } from 'react';
import { exhaustiveCheck } from 'tgui-core/exhaustive';
import { fetchRetry } from 'tgui-core/http';
import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { LoadingScreen } from '../common/LoadingScreen';
import { CharacterPreferenceWindow } from './CharacterPreferences';
import { destroyCharacterPreview } from './components/CharacterPreview';
import { GamePreferenceWindow } from './GamePreferences';
import {
  GamePreferencesSelectedPage,
  type PreferencesMenuData,
  PrefsWindow,
  type ServerData,
} from './types';
import { RandomToggleState } from './useRandomToggleState';
import { ServerPrefs } from './useServerPrefs';

export function PreferencesMenu(props) {
  const { data } = useBackend<PreferencesMenuData>();

  useEffect(
    () => () => destroyCharacterPreview(data.character_preview_view),
    [data.character_preview_view],
  );

  return (
    <Window width={920} height={770}>
      <Window.Content className="PreferencesMenu">
        <Suspense fallback={<LoadingScreen />}>
          <PrefsWindowInner />
        </Suspense>
      </Window.Content>
    </Window>
  );
}

function PrefsWindowInner(props) {
  const { data } = useBackend<PreferencesMenuData>();
  const { window } = data;

  const [serverData, setServerData] = useState<ServerData>();
  const randomization = useState(false);

  useEffect(() => {
    fetchRetry(resolveAsset('preferences.json'))
      .then((response) => response.json())
      .then((data) => {
        setServerData(data);
      })
      .catch((error) => {
        logger.log('Failed to fetch preferences.json', error);
      });
  }, []);

  let content;
  switch (window) {
    case PrefsWindow.Character:
      content = <CharacterPreferenceWindow />;
      break;
    case PrefsWindow.Game:
      content = <GamePreferenceWindow />;
      break;
    case PrefsWindow.Keybindings:
      content = (
        <GamePreferenceWindow
          startingPage={GamePreferencesSelectedPage.Keybindings}
        />
      );
      break;
    default:
      exhaustiveCheck(window);
  }

  return (
    <ServerPrefs.Provider value={serverData}>
      <RandomToggleState.Provider value={randomization}>
        {content}
      </RandomToggleState.Provider>
    </ServerPrefs.Provider>
  );
}
