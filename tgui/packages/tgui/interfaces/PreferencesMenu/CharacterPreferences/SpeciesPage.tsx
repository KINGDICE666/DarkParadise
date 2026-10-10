import { Box, Button, ByondUi, Section, Stack } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { useBackend } from '../../../backend';
import { LoadingScreen } from '../../common/LoadingScreen';
import {
  createSetPreference,
  type PreferencesMenuData,
  type SpeciesData,
} from '../types';
import { useServerPrefs } from '../useServerPrefs';

type SpeciesPageProps = {
  closeSpecies: () => void;
};

export function SpeciesPage(props: SpeciesPageProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const serverData = useServerPrefs();

  if (!serverData) {
    return <LoadingScreen />;
  }

  const setSpecies = createSetPreference(act, 'species');
  const currentKey = data.character_preferences.manually_rendered_features
    .species as string;
  const choices = (data.character_preferences.valid_choices?.species ||
    Object.keys(serverData.species)) as string[];

  const species: [string, SpeciesData][] = choices
    .filter((key) => serverData.species[key])
    .map((key) => [key, serverData.species[key]]);

  const humanIndex = species.findIndex(([key]) => key === 'Human');
  if (humanIndex > 0) {
    const swapWith = species[0];
    species[0] = species[humanIndex];
    species[humanIndex] = swapWith;
  }

  const currentSpecies = serverData.species[currentKey];

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Button icon="arrow-left" onClick={props.closeSpecies}>
          Назад
        </Button>
      </Stack.Item>

      <Stack.Item grow>
        <Stack fill>
          <Stack.Item>
            <Box height="calc(100vh - 170px)" overflowY="auto" pr={3}>
              {species.map(([speciesKey, speciesData]) => (
                <Button
                  key={speciesKey}
                  onClick={() => setSpecies(speciesKey)}
                  selected={currentKey === speciesKey}
                  tooltip={speciesData.name}
                  style={{
                    display: 'block',
                    height: '64px',
                    width: '64px',
                  }}
                >
                  <Box
                    className={classes(['species64x64', speciesData.icon])}
                    ml={-1}
                  />
                </Button>
              ))}
            </Box>
          </Stack.Item>

          <Stack.Item grow>
            <Stack fill>
              <Stack.Item width="70%">
                <Section title={currentSpecies?.name || currentKey}>
                  <Section title="Описание">{currentSpecies?.desc}</Section>
                </Section>
              </Stack.Item>

              <Stack.Item width="30%">
                <ByondUi
                  width="220px"
                  height="100%"
                  params={{
                    id: data.character_preview_view,
                    type: 'map',
                    'is-visible': true,
                  }}
                />
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}
