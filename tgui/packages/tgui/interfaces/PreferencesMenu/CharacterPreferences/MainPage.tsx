import { sortBy } from 'es-toolkit';
import { filter, map } from 'es-toolkit/compat';
import { type ReactNode, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { sendAct } from 'tgui/events/act';
import {
  Box,
  Button,
  Floating,
  Input,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import { createSearch } from 'tgui-core/string';
import {
  CHARACTER_PREVIEW_HEIGHT,
  CharacterPreview,
} from '../components/CharacterPreview';
import { RandomizationButton } from '../components/RandomizationButton';
import { features } from '../preferences/features';
import {
  type FeatureChoicedServerData,
  FeatureValueInput,
} from '../preferences/features/base';
import { GENDERS, type Gender } from '../preferences/gender';
import {
  createSetPreference,
  type PreferencesMenuData,
  RandomSetting,
  type ServerData,
} from '../types';
import { useRandomToggleState } from '../useRandomToggleState';
import { useServerPrefs } from '../useServerPrefs';
import { DeleteCharacterPopup } from './DeleteCharacterPopup';
import { HairGradientSelection } from './HairGradientSelection';
import { MultiNameInput, NameInput } from './names';

const CLOTHING_CELL_SIZE = 48;
const CLOTHING_SIDEBAR_ROWS = 9;

const CLOTHING_SELECTION_CELL_SIZE = 48;
const CLOTHING_SELECTION_WIDTH = 5.4;
const CLOTHING_SELECTION_MULTIPLIER = 5.2;

type CharacterControlsProps = {
  handleRotate: () => void;
  handleOpenSpecies: () => void;
  gender: Gender;
  genders: Gender[];
  setGender: (gender: Gender) => void;
  showGender: boolean;
  canDeleteCharacter: boolean;
  handleDeleteCharacter: () => void;
};

function CharacterControls(props: CharacterControlsProps) {
  return (
    <Stack>
      <Stack.Item>
        <Button
          onClick={props.handleRotate}
          fontSize="22px"
          icon="undo"
          tooltip="Повернуть"
          tooltipPosition="top"
        />
      </Stack.Item>

      <Stack.Item>
        <Button
          onClick={props.handleOpenSpecies}
          fontSize="22px"
          icon="paw"
          tooltip="Раса"
          tooltipPosition="top"
        />
      </Stack.Item>

      {props.showGender && (
        <Stack.Item>
          <GenderButton
            gender={props.gender}
            genders={props.genders}
            handleSetGender={props.setGender}
          />
        </Stack.Item>
      )}

      <Stack.Item>
        <Button
          onClick={props.handleDeleteCharacter}
          fontSize="22px"
          icon="trash"
          color="red"
          tooltip="Удалить персонажа"
          tooltipPosition="top"
          disabled={!props.canDeleteCharacter}
        />
      </Stack.Item>
    </Stack>
  );
}

type ChoicedSelectionProps = {
  name: string;
  catalog: FeatureChoicedServerData;
  validChoices?: string[];
  selected: string;
  supplementalFeature?: string;
  supplementalValue?: unknown;
  onSelect: (value: string) => void;
};

function ChoicedSelection(props: ChoicedSelectionProps) {
  const { catalog, supplementalFeature, supplementalValue, validChoices } =
    props;
  const [searchText, setSearchText] = useState('');

  if (!catalog.icons) {
    return <Box color="red">Provided catalog had no icons!</Box>;
  }

  const icons = validChoices
    ? Object.fromEntries(
        validChoices.map((choice) => [choice, catalog.icons![choice]]),
      )
    : catalog.icons;

  return (
    <Box
      className="ChoicedSelection"
      style={{
        height: `${
          CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_MULTIPLIER
        }px`,
        width: `${CLOTHING_SELECTION_CELL_SIZE * CLOTHING_SELECTION_WIDTH}px`,
      }}
    >
      <Stack fill vertical g={0}>
        <Stack.Item>
          <Section
            fill
            title={`Выбор: ${props.name.toLowerCase()}`}
            buttons={
              supplementalFeature &&
              supplementalValue !== undefined && (
                <FeatureValueInput
                  shrink
                  feature={features[supplementalFeature]}
                  featureId={supplementalFeature}
                  value={supplementalValue}
                />
              )
            }
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
              {searchInCatalog(searchText, icons, catalog.display_names).map(
                ([name, image], index) => {
                  return (
                    <Button
                      key={index}
                      onClick={() => {
                        props.onSelect(name);
                      }}
                      selected={name === props.selected}
                      tooltip={catalog.display_names?.[name] ?? name}
                      tooltipPosition="right"
                      style={{
                        height: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                        width: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                      }}
                    >
                      <Box
                        className={classes([
                          'preferences32x32',
                          image,
                          'centered-image',
                        ])}
                        style={{
                          transform:
                            'translateX(-50%) translateY(-50%) scale(0.8)',
                        }}
                      />
                    </Button>
                  );
                },
              )}
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

function searchInCatalog(
  searchText = '',
  catalog: Record<string, string>,
  displayNames?: Record<string, string>,
) {
  let items = Object.entries(catalog);
  if (searchText) {
    items = filter(
      items,
      createSearch(searchText, ([name, _icon]) => displayNames?.[name] ?? name),
    );
  }
  return items;
}

type GenderButtonProps = {
  handleSetGender: (gender: Gender) => void;
  gender: Gender;
  genders: Gender[];
};

function GenderButton(props: GenderButtonProps) {
  return (
    <Floating
      placement="right"
      content={
        <Stack backgroundColor="white" p={0.3}>
          {props.genders.map((gender) => {
            return (
              <Stack.Item key={gender}>
                <Button
                  selected={gender === props.gender}
                  onClick={() => {
                    props.handleSetGender(gender);
                  }}
                  fontSize="22px"
                  icon={GENDERS[gender].icon}
                  tooltip={GENDERS[gender].text}
                  tooltipPosition="top"
                />
              </Stack.Item>
            );
          })}
        </Stack>
      }
    >
      <div>
        <Button
          fontSize="22px"
          icon={GENDERS[props.gender].icon}
          tooltip="Пол"
          tooltipPosition="top"
        />
      </div>
    </Floating>
  );
}

type CatalogItem = {
  name: string;
  supplemental_feature?: string;
};

type MainFeatureProps = {
  featureId: string;
  catalog: FeatureChoicedServerData & CatalogItem;
  currentValue: string;
  handleSelect: (newClothing: string) => void;
  randomization?: RandomSetting;
  setRandomization: (newSetting: RandomSetting) => void;
};

function MainFeature(props: MainFeatureProps) {
  const { data } = useBackend<PreferencesMenuData>();
  const {
    catalog,
    currentValue,
    handleSelect,
    randomization,
    setRandomization,
  } = props;

  const supplementalFeature = catalog.supplemental_feature;

  return (
    <Floating
      stopChildPropagation
      placement="right-start"
      content={
        props.featureId === 'hair_gradient' ? (
          <HairGradientSelection
            name={catalog.name}
            catalog={catalog}
            validChoices={
              data.character_preferences.valid_choices?.[props.featureId]
            }
            selected={currentValue}
            onSelect={handleSelect}
          />
        ) : (
          <ChoicedSelection
            name={catalog.name}
            catalog={catalog}
            validChoices={
              data.character_preferences.valid_choices?.[props.featureId]
            }
            selected={currentValue}
            supplementalFeature={supplementalFeature}
            supplementalValue={
              supplementalFeature &&
              data.character_preferences.supplemental_features[
                supplementalFeature
              ]
            }
            onSelect={handleSelect}
          />
        )
      }
    >
      <Button
        style={{
          height: `${CLOTHING_CELL_SIZE}px`,
          width: `${CLOTHING_CELL_SIZE}px`,
        }}
        position="relative"
      >
        <Box
          className={classes([
            'preferences32x32',
            catalog.icons![currentValue],
            'centered-image',
          ])}
          style={{
            transform: randomization
              ? 'translateX(-70%) translateY(-70%) scale(1.1)'
              : 'translateX(-50%) translateY(-50%) scale(1.3)',
          }}
        />

        {randomization && (
          <RandomizationButton
            dropdownProps={{
              dropdownStyle: {
                bottom: 0,
                position: 'absolute',
                right: '1px',
              },

              onOpen: (event) => {
                event.cancelBubble = true;
                event.stopPropagation();
              },
            }}
            value={randomization}
            setValue={setRandomization}
          />
        )}
      </Button>
    </Floating>
  );
}

const createSetRandomization =
  (preference: string) => (newSetting: RandomSetting) => {
    sendAct('set_random_preference', {
      preference,
      value: newSetting,
    });
  };

function sortPreferences(array: [string, unknown][]) {
  return sortBy(array, [([featureId]) => features[featureId]?.name]);
}

type PreferenceListProps = {
  preferences: Record<string, unknown>;
  randomizations: Record<string, RandomSetting>;
  trailingPreferences?: Record<string, unknown>;
  maxHeight: string;
  children?: ReactNode;
};

export function PreferenceList(props: PreferenceListProps) {
  const { act } = useBackend<PreferencesMenuData>();
  const {
    preferences,
    trailingPreferences = {},
    randomizations,
    maxHeight,
    children,
  } = props;

  return (
    <Stack.Item
      basis="50%"
      grow
      style={{
        background: 'rgba(0, 0, 0, 0.5)',
        padding: '4px',
      }}
      overflowX="hidden"
      overflowY="auto"
      maxHeight={maxHeight}
    >
      <LabeledList>
        {[
          ...sortPreferences(Object.entries(preferences)),
          ...sortPreferences(Object.entries(trailingPreferences)),
        ].map(([featureId, value]) => {
          const feature = features[featureId];
          const randomSetting = randomizations[featureId];

          if (feature === undefined) {
            return (
              <Stack.Item key={featureId}>
                <b>Неизвестная настройка {featureId}.</b>
              </Stack.Item>
            );
          }

          return (
            <LabeledList.Item
              key={featureId}
              label={feature.name}
              tooltip={feature.description}
              verticalAlign="middle"
            >
              <Stack fill>
                {randomSetting && (
                  <Stack.Item>
                    <RandomizationButton
                      setValue={createSetRandomization(featureId)}
                      value={randomSetting}
                    />
                  </Stack.Item>
                )}

                <Stack.Item grow>
                  <FeatureValueInput
                    feature={feature}
                    featureId={featureId}
                    value={value}
                  />
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
          );
        })}
      </LabeledList>

      {children}
    </Stack.Item>
  );
}

export function getRandomization(
  preferences: Record<string, unknown>,
  serverData: ServerData | undefined,
  randomBodyEnabled: boolean,
): Record<string, RandomSetting> {
  const { data } = useBackend<PreferencesMenuData>();

  if (!randomBodyEnabled || !serverData) {
    return {};
  }

  return Object.fromEntries(
    map(
      filter(Object.keys(preferences), (key) =>
        serverData.random.randomizable.includes(key),
      ),
      (key) => [
        key,
        data.character_preferences.randomization[key] || RandomSetting.Disabled,
      ],
    ),
  );
}

type MainPageProps = {
  openSpecies: () => void;
};

export function MainPage(props: MainPageProps) {
  const { act, data } = useBackend<PreferencesMenuData>();

  const [deleteCharacterPopupOpen, setDeleteCharacterPopupOpen] =
    useState(false);
  const [multiNameInputOpen, setMultiNameInputOpen] = useState(false);
  const [randomToggleEnabled] = useRandomToggleState();

  const serverData = useServerPrefs();

  const contextualPreferences =
    data.character_preferences.secondary_features || [];

  const mainFeatures = [
    ...Object.entries(data.character_preferences.clothing ?? {}),
    ...Object.entries(data.character_preferences.features ?? {}),
  ];

  const randomBodyEnabled =
    data.character_preferences.non_contextual.random_body !==
      RandomSetting.Disabled || randomToggleEnabled;

  const randomizationOfMainFeatures = getRandomization(
    Object.fromEntries(mainFeatures),
    serverData,
    randomBodyEnabled,
  );

  const nonContextualPreferences = {
    ...data.character_preferences.non_contextual,
  };

  if (randomBodyEnabled) {
    nonContextualPreferences.random_species =
      data.character_preferences.randomization.species;
  }

  return (
    <>
      {multiNameInputOpen && (
        <MultiNameInput
          handleClose={() => setMultiNameInputOpen(false)}
          handleRandomizeName={(preference) =>
            act('randomize_name', {
              preference,
            })
          }
          handleUpdateName={(nameType, value) =>
            act('set_preference', {
              preference: nameType,
              value,
            })
          }
          names={data.character_preferences.names}
        />
      )}

      {deleteCharacterPopupOpen && (
        <DeleteCharacterPopup
          close={() => setDeleteCharacterPopupOpen(false)}
        />
      )}

      <Stack height={`${CLOTHING_SIDEBAR_ROWS * CLOTHING_CELL_SIZE}px`}>
        <Stack.Item>
          <Stack vertical fill>
            <Stack.Item>
              <CharacterControls
                gender={data.character_preferences.misc.gender}
                genders={
                  (data.character_preferences.valid_choices?.gender as
                    | Gender[]
                    | undefined) ?? (Object.keys(GENDERS) as Gender[])
                }
                handleOpenSpecies={props.openSpecies}
                handleRotate={() => {
                  act('rotate');
                }}
                setGender={createSetPreference(act, 'gender')}
                showGender
                canDeleteCharacter={
                  Object.values(data.character_profiles).filter(
                    (name) => !!name,
                  ).length > 1
                }
                handleDeleteCharacter={() => setDeleteCharacterPopupOpen(true)}
              />
            </Stack.Item>

            <Stack.Item grow>
              <CharacterPreview
                height={CHARACTER_PREVIEW_HEIGHT}
                id={data.character_preview_view}
              />
            </Stack.Item>

            <Stack.Item position="relative">
              <NameInput
                name={data.character_preferences.names[data.name_to_use]}
                handleUpdateName={createSetPreference(act, data.name_to_use)}
                openMultiNameInput={() => {
                  setMultiNameInputOpen(true);
                }}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack fill vertical wrap>
            {mainFeatures.map(([clothingKey, clothing]) => {
              const catalog = serverData?.[
                clothingKey
              ] as FeatureChoicedServerData & {
                name: string;
              };

              return (
                <Stack.Item key={clothingKey}>
                  {!catalog ? (
                    <Button height={4} width={4} disabled />
                  ) : (
                    <MainFeature
                      featureId={clothingKey}
                      catalog={catalog}
                      currentValue={clothing}
                      handleSelect={createSetPreference(act, clothingKey)}
                      randomization={randomizationOfMainFeatures[clothingKey]}
                      setRandomization={createSetRandomization(clothingKey)}
                    />
                  )}
                </Stack.Item>
              );
            })}
          </Stack>
        </Stack.Item>

        <Stack.Item grow basis={0}>
          <Stack vertical fill>
            <PreferenceList
              randomizations={{
                ...getRandomization(
                  contextualPreferences,
                  serverData,
                  randomBodyEnabled,
                ),
                ...getRandomization(
                  nonContextualPreferences,
                  serverData,
                  randomBodyEnabled,
                ),
              }}
              preferences={contextualPreferences}
              trailingPreferences={nonContextualPreferences}
              maxHeight="auto"
            />
          </Stack>
        </Stack.Item>
      </Stack>
    </>
  );
}
