import { useEffect, useState } from 'react';
import {
  Box,
  Button,
  ByondUi,
  Floating,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { globalEvents } from 'tgui-core/events';
import { createSearch } from 'tgui-core/string';

import { useBackend } from '../../../backend';
import { ColorInput, FeatureValueInput, features } from '../features';
import {
  type ChoicedServerData,
  createSetPreference,
  type PreferencesMenuData,
} from '../types';
import { useServerPrefs } from '../useServerPrefs';

const CELL_SIZE = 48;

const SUPPLEMENTAL: Record<string, string[]> = {
  hair_style_name: ['hair_colour', 'secondary_hair_colour'],
  facial_style_name: ['facial_hair_colour', 'secondary_facial_hair_colour'],
  head_accessory_style_name: ['head_accessory_colour'],
  head_marking_style: ['head_marking_colour'],
  body_marking_style: ['body_marking_colour'],
  tail_marking_style: ['tail_marking_colour'],
  underwear: ['underwear_color'],
  undershirt: ['undershirt_color'],
};

const GENDER_ICONS: Record<string, string> = {
  male: 'mars',
  female: 'venus',
  plural: 'genderless',
};

function SupplementalColors(props: { featureId: string }) {
  const { data } = useBackend<PreferencesMenuData>();
  const supplemental = data.character_preferences.supplemental_features || {};
  const keys = (SUPPLEMENTAL[props.featureId] || []).filter(
    (key) => supplemental[key] !== undefined,
  );

  if (!keys.length) {
    return null;
  }

  return (
    <Stack g={0.5}>
      {keys.map((key) => (
        <Stack.Item key={key}>
          <ColorInput featureId={key} value={supplemental[key]} shrink />
        </Stack.Item>
      ))}
    </Stack>
  );
}

type AccessorySelectionProps = {
  featureId: string;
  catalog: ChoicedServerData;
  selected: string;
  onSelect: (value: string) => void;
};

function AccessorySelection(props: AccessorySelectionProps) {
  const { data } = useBackend<PreferencesMenuData>();
  const { featureId, catalog } = props;
  const [searchText, setSearchText] = useState('');
  const choices = (data.character_preferences.valid_choices?.[featureId] ||
    catalog.choices) as string[];
  const search = createSearch(searchText, (choice: string) => choice);

  return (
    <Box
      className="ChoicedSelection"
      style={{
        height: `${CELL_SIZE * 6}px`,
        width: `${CELL_SIZE * 6.2}px`,
      }}
    >
      <Stack fill vertical g={0}>
        <Stack.Item>
          <Section
            fill
            title={features[featureId]?.name || catalog.name}
            buttons={<SupplementalColors featureId={featureId} />}
          >
            <Input
              autoFocus
              fluid
              placeholder="Поиск..."
              onChange={setSearchText}
            />
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section fill scrollable noTopPadding>
            <Stack wrap>
              {choices.filter(search).map((choice) => (
                <Button
                  key={choice}
                  onClick={() => props.onSelect(choice)}
                  selected={choice === props.selected}
                  tooltip={choice}
                  tooltipPosition="right"
                  style={{
                    height: `${CELL_SIZE}px`,
                    width: `${CELL_SIZE}px`,
                  }}
                >
                  <AccessoryIcon catalog={catalog} value={choice} scale={1} />
                </Button>
              ))}
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

function AccessoryIcon(props: {
  catalog: ChoicedServerData;
  value: string;
  scale: number;
}) {
  const iconKey = props.catalog.icons?.[props.value];
  if (!iconKey) {
    return (
      <Box
        fontSize="0.7em"
        style={{ overflow: 'hidden', whiteSpace: 'normal', lineHeight: 1 }}
      >
        {props.value}
      </Box>
    );
  }

  return (
    <Box
      className={`${props.catalog.icon_sheet} ${iconKey}`}
      style={{
        position: 'absolute',
        left: '50%',
        top: '50%',
        imageRendering: 'pixelated',
        transform: `translateX(-50%) translateY(-50%) scale(${props.scale})`,
      }}
    />
  );
}

function MainFeature(props: { featureId: string; value: string }) {
  const { act } = useBackend<PreferencesMenuData>();
  const catalog = useServerPrefs()?.[props.featureId] as
    | ChoicedServerData
    | undefined;

  if (!catalog) {
    return (
      <Button height={`${CELL_SIZE}px`} width={`${CELL_SIZE}px`} disabled />
    );
  }

  return (
    <Stack vertical g={0.3} align="center">
      <Stack.Item>
        <Floating
          stopChildPropagation
          placement="right-start"
          content={
            <AccessorySelection
              featureId={props.featureId}
              catalog={catalog}
              selected={props.value}
              onSelect={createSetPreference(act, props.featureId)}
            />
          }
        >
          <Button
            tooltip={`${features[props.featureId]?.name}: ${props.value}`}
            tooltipPosition="right"
            position="relative"
            style={{
              height: `${CELL_SIZE}px`,
              width: `${CELL_SIZE}px`,
            }}
          >
            <AccessoryIcon catalog={catalog} value={props.value} scale={1.3} />
          </Button>
        </Floating>
      </Stack.Item>
      <Stack.Item>
        <SupplementalColors featureId={props.featureId} />
      </Stack.Item>
    </Stack>
  );
}

function PreferenceList(props: { preferences: Record<string, unknown> }) {
  const entries = Object.entries(props.preferences)
    .filter(([featureId]) => features[featureId])
    .sort(([a], [b]) => features[a].name.localeCompare(features[b].name));

  if (!entries.length) {
    return null;
  }

  return (
    <Box
      style={{
        background: 'rgba(0, 0, 0, 0.5)',
        padding: '4px',
      }}
    >
      <LabeledList>
        {entries.map(([featureId, value]) => (
          <LabeledList.Item
            key={featureId}
            label={features[featureId].name}
            tooltip={features[featureId].description}
            verticalAlign="middle"
          >
            <Stack fill>
              <Stack.Item grow>
                <FeatureValueInput featureId={featureId} value={value} />
              </Stack.Item>
              <RandomizeButton featureId={featureId} />
            </Stack>
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Box>
  );
}

function RandomizeButton(props: { featureId: string }) {
  const { act } = useBackend<PreferencesMenuData>();
  const kind = features[props.featureId]?.kind;
  if (kind === 'toggle' || kind === 'textarea') {
    return null;
  }

  return (
    <Stack.Item>
      <Button
        icon="dice"
        tooltip="Случайно"
        onClick={() =>
          act('randomize_preference', { preference: props.featureId })
        }
      />
    </Stack.Item>
  );
}

function SpeciesSelection(props: { current: string }) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const species = useServerPrefs()?.species || {};
  const choices = (data.character_preferences.valid_choices?.species ||
    Object.keys(species)) as string[];

  return (
    <Box
      className="ChoicedSelection"
      style={{ width: '360px', maxHeight: '420px' }}
    >
      <Section title="Раса" scrollable fill>
        {choices.map((speciesName) => (
          <Button
            key={speciesName}
            fluid
            selected={speciesName === props.current}
            tooltip={species[speciesName]?.desc}
            tooltipPosition="right"
            onClick={() =>
              act('set_preference', {
                preference: 'species',
                value: speciesName,
              })
            }
          >
            {species[speciesName]?.name || speciesName}
          </Button>
        ))}
      </Section>
    </Box>
  );
}

function GenderButtons(props: { gender: string }) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const choices = (data.character_preferences.valid_choices?.gender || [
    'male',
    'female',
  ]) as string[];

  return (
    <Stack g={0.5}>
      {choices.map((gender) => (
        <Stack.Item key={gender}>
          <Button
            fontSize="18px"
            icon={GENDER_ICONS[gender] || 'question'}
            selected={gender === props.gender}
            tooltip={
              gender === 'male'
                ? 'Мужской'
                : gender === 'female'
                  ? 'Женский'
                  : 'Бесполый'
            }
            onClick={() =>
              act('set_preference', { preference: 'gender', value: gender })
            }
          />
        </Stack.Item>
      ))}
    </Stack>
  );
}

function NameInput() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const [editing, setEditing] = useState(false);
  const name = data.character_preferences.names.real_name;
  const alwaysRandom =
    data.character_preferences.manually_rendered_features.name_is_always_random;

  return (
    <Stack vertical g={0.5}>
      <Stack.Item>
        <Stack>
          <Stack.Item grow>
            {editing ? (
              <Input
                autoFocus
                fluid
                value={name}
                onBlur={(value) => {
                  setEditing(false);
                  act('set_preference', { preference: 'real_name', value });
                }}
              />
            ) : (
              <Button
                fluid
                icon="edit"
                textAlign="center"
                fontSize="1.2em"
                onClick={() => setEditing(true)}
              >
                {name}
              </Button>
            )}
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="dice"
              fontSize="1.2em"
              tooltip="Случайное имя"
              onClick={() =>
                act('randomize_preference', { preference: 'real_name' })
              }
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item>
        <Button.Checkbox
          checked={!!alwaysRandom}
          onClick={() =>
            act('set_preference', {
              preference: 'name_is_always_random',
              value: !alwaysRandom,
            })
          }
        >
          Каждый раунд случайное имя
        </Button.Checkbox>
      </Stack.Item>
    </Stack>
  );
}

export function MainPage(props: { visible: boolean }) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const prefs = data.character_preferences;
  const species = useServerPrefs()?.species || {};
  const ready = !!prefs.manually_rendered_features;
  const currentSpecies = prefs.manually_rendered_features?.species as string;
  const mainFeatures = [
    ...Object.entries(prefs.features || {}),
    ...Object.entries(prefs.clothing || {}),
  ];

  useEffect(() => {
    Byond.winset(data.character_preview_view, { 'is-visible': props.visible });
    if (props.visible) {
      globalEvents.emit('window-geometry-finished');
      act('show_preview');
    }
  }, [props.visible]);

  return (
    <Stack fill>
      <Stack.Item>
        <Stack vertical fill>
          <Stack.Item>
            {ready && (
              <Stack>
                <Stack.Item>
                  <Button
                    icon="undo"
                    fontSize="18px"
                    tooltip="Повернуть"
                    onClick={() => act('rotate')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Floating
                    placement="right-start"
                    content={<SpeciesSelection current={currentSpecies} />}
                  >
                    <Button
                      icon="paw"
                      fontSize="18px"
                      tooltip={`Раса: ${species[currentSpecies]?.name || currentSpecies}`}
                    />
                  </Floating>
                </Stack.Item>
                <Stack.Item>
                  <GenderButtons
                    gender={prefs.manually_rendered_features.gender as string}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="shirt"
                    fontSize="18px"
                    tooltip="Одежда профессии"
                    onClick={() => act('toggle_job_clothes')}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button.Confirm
                    icon="random"
                    fontSize="18px"
                    tooltip="Случайная внешность"
                    confirmContent={null}
                    confirmIcon="check"
                    disabled={!!data.appearance_banned}
                    onClick={() => act('randomize_character')}
                  />
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
          <Stack.Item grow>
            <ByondUi
              width="220px"
              height="100%"
              params={{ id: data.character_preview_view, type: 'map' }}
            />
          </Stack.Item>
          <Stack.Item width="220px">{ready && <NameInput />}</Stack.Item>
        </Stack>
      </Stack.Item>

      <Stack.Item>
        <Stack vertical wrap fill>
          {ready &&
            mainFeatures.map(([featureId, value]) => (
              <Stack.Item key={featureId}>
                <MainFeature featureId={featureId} value={value} />
              </Stack.Item>
            ))}
        </Stack>
      </Stack.Item>

      <Stack.Item grow basis={0}>
        {ready && (
          <Stack vertical fill>
            {!!data.appearance_banned && (
              <Stack.Item>
                <NoticeBox danger>
                  Вам запрещено изменять внешность. После присоединения к раунду
                  персонаж будет сгенерирован случайно.
                </NoticeBox>
              </Stack.Item>
            )}
            <Stack.Item>
              <Section title={species[currentSpecies]?.name || currentSpecies}>
                <PreferenceList preferences={prefs.secondary_features || {}} />
              </Section>
            </Stack.Item>
            <Stack.Item grow>
              <Section title="Персонаж" fill scrollable>
                <PreferenceList preferences={prefs.non_contextual || {}} />
                <VoiceAndSound />
              </Section>
            </Stack.Item>
          </Stack>
        )}
      </Stack.Item>
    </Stack>
  );
}

function VoiceAndSound() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const speciesLabels = (
    useServerPrefs()?.speciesprefs as { labels?: Record<string, string> }
  )?.labels;
  const currentSpecies = data.character_preferences.manually_rendered_features
    .species as string;

  return (
    <Box mt={1}>
      <LabeledList>
        {!!data.tts_enabled && (
          <LabeledList.Item label="Голос">
            <Button icon="microphone" onClick={() => act('open_tts_explorer')}>
              {data.tts_seed || 'Не выбран'}
            </Button>
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Громкость">
          <Button icon="volume-up" onClick={() => act('open_volume_mixer')}>
            Микшер громкости
          </Button>
        </LabeledList.Item>
        {speciesLabels?.[currentSpecies] &&
          data.character_preferences.non_contextual.speciesprefs !==
            undefined && (
            <LabeledList.Item label="Расовая особенность">
              {speciesLabels[currentSpecies]}
            </LabeledList.Item>
          )}
      </LabeledList>
    </Box>
  );
}
