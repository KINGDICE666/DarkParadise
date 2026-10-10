import { type ReactNode, useEffect, useState } from 'react';
import {
  Box,
  Button,
  ByondUi,
  FitText,
  Floating,
  Icon,
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
import { DeleteCharacterPopup } from './DeleteCharacterPopup';

const CLOTHING_CELL_SIZE = 48;
const CLOTHING_SIDEBAR_ROWS = 9;

const CLOTHING_SELECTION_CELL_SIZE = 48;
const CLOTHING_SELECTION_WIDTH = 5.4;
const CLOTHING_SELECTION_MULTIPLIER = 5.2;

const PREVIEW_REFRESH_DELAY = 300;

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

const GENDERS: Record<string, { icon: string; text: string }> = {
  male: { icon: 'mars', text: 'Мужской' },
  female: { icon: 'venus', text: 'Женский' },
  plural: { icon: 'transgender', text: 'Множественный' },
  neuter: { icon: 'neuter', text: 'Средний' },
};

type CharacterControlsProps = {
  handleRotate: () => void;
  handleOpenSpecies: () => void;
  gender: string;
  genders: string[];
  setGender: (gender: string) => void;
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

      {props.genders.length > 1 && (
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

type GenderButtonProps = {
  gender: string;
  genders: string[];
  handleSetGender: (gender: string) => void;
};

function GenderButton(props: GenderButtonProps) {
  return (
    <Floating
      placement="right"
      content={
        <Stack backgroundColor="white" p={0.3}>
          {props.genders.map((gender) => (
            <Stack.Item key={gender}>
              <Button
                selected={gender === props.gender}
                onClick={() => props.handleSetGender(gender)}
                fontSize="22px"
                icon={GENDERS[gender]?.icon || 'question'}
                tooltip={GENDERS[gender]?.text || gender}
                tooltipPosition="top"
              />
            </Stack.Item>
          ))}
        </Stack>
      }
    >
      <div>
        <Button
          fontSize="22px"
          icon={GENDERS[props.gender]?.icon || 'question'}
          tooltip="Пол"
          tooltipPosition="top"
        />
      </div>
    </Floating>
  );
}

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

type ChoicedSelectionProps = {
  featureId: string;
  name: string;
  catalog: ChoicedServerData;
  selected: string;
  onSelect: (value: string) => void;
};

function ChoicedSelection(props: ChoicedSelectionProps) {
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
                    height: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                    width: `${CLOTHING_SELECTION_CELL_SIZE}px`,
                  }}
                >
                  <AccessoryIcon catalog={catalog} value={choice} scale={0.8} />
                </Button>
              ))}
            </Stack>
          </Section>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

function MainFeature(props: { featureId: string; value: string }) {
  const { act } = useBackend<PreferencesMenuData>();
  const catalog = useServerPrefs()?.[props.featureId] as
    | ChoicedServerData
    | undefined;

  if (!catalog) {
    return <Button height={4} width={4} disabled />;
  }

  return (
    <Floating
      stopChildPropagation
      placement="right-start"
      content={
        <ChoicedSelection
          featureId={props.featureId}
          name={features[props.featureId]?.name || catalog.name || ''}
          catalog={catalog}
          selected={props.value}
          onSelect={createSetPreference(act, props.featureId)}
        />
      }
    >
      <Button
        style={{
          height: `${CLOTHING_CELL_SIZE}px`,
          width: `${CLOTHING_CELL_SIZE}px`,
        }}
        position="relative"
      >
        <AccessoryIcon catalog={catalog} value={props.value} scale={1.3} />
      </Button>
    </Floating>
  );
}

type PreferenceListProps = {
  preferences: Record<string, unknown>;
  children?: ReactNode;
};

function PreferenceList(props: PreferenceListProps) {
  const entries = Object.entries(props.preferences)
    .filter(([featureId]) => features[featureId])
    .sort(([a], [b]) => features[a].name.localeCompare(features[b].name));

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
            </Stack>
          </LabeledList.Item>
        ))}
        {props.children}
      </LabeledList>
    </Stack.Item>
  );
}

type NameInputProps = {
  name: string;
  handleUpdateName: (name: string) => void;
};

function NameInput(props: NameInputProps) {
  const [lastNameBeforeEdit, setLastNameBeforeEdit] = useState<string | null>(
    null,
  );
  const editing = lastNameBeforeEdit === props.name;

  function updateName(value: string) {
    setLastNameBeforeEdit(null);
    props.handleUpdateName(value);
  }

  return (
    <Button
      captureKeys={!editing}
      onClick={() => setLastNameBeforeEdit(props.name)}
      textAlign="center"
      width="100%"
      height="28px"
    >
      <Stack align="center" fill>
        <Stack.Item>
          <Icon
            style={{
              color: 'rgba(255, 255, 255, 0.5)',
              fontSize: '17px',
            }}
            name="edit"
          />
        </Stack.Item>

        <Stack.Item grow position="relative">
          {editing ? (
            <Input
              autoSelect
              onBlur={updateName}
              onEscape={() => setLastNameBeforeEdit(null)}
              value={props.name}
            />
          ) : (
            <FitText maxFontSize={16} maxWidth={130}>
              {props.name}
            </FitText>
          )}

          <Box
            style={{
              borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
              right: '50%',
              transform: 'translateX(50%)',
              position: 'absolute',
              width: '90%',
              bottom: '-1px',
            }}
          />
        </Stack.Item>
      </Stack>
    </Button>
  );
}

export function MainPage(props: { visible: boolean; openSpecies: () => void }) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const [deleteCharacterPopupOpen, setDeleteCharacterPopupOpen] =
    useState(false);
  const prefs = data.character_preferences;
  const ready = !!prefs.manually_rendered_features;
  const mainFeatures = [
    ...Object.entries(prefs.clothing || {}),
    ...Object.entries(prefs.features || {}),
  ];

  useEffect(() => {
    Byond.winset(data.character_preview_view, { 'is-visible': props.visible });
    if (!props.visible) {
      return;
    }
    let refreshTimer: ReturnType<typeof setTimeout> | undefined;
    const refreshPreview = () => {
      clearTimeout(refreshTimer);
      refreshTimer = setTimeout(
        () => act('show_preview'),
        PREVIEW_REFRESH_DELAY,
      );
    };
    globalEvents.on('window-geometry-finished', refreshPreview);
    globalEvents.emit('window-geometry-finished');
    return () => {
      clearTimeout(refreshTimer);
      globalEvents.off('window-geometry-finished', refreshPreview);
    };
  }, [props.visible]);

  const nonContextualPreferences = ready
    ? {
        ...prefs.non_contextual,
        name_is_always_random:
          prefs.manually_rendered_features.name_is_always_random,
      }
    : {};

  return (
    <>
      {deleteCharacterPopupOpen && (
        <DeleteCharacterPopup
          close={() => setDeleteCharacterPopupOpen(false)}
        />
      )}

      <Stack height={`${CLOTHING_SIDEBAR_ROWS * CLOTHING_CELL_SIZE}px`}>
        <Stack.Item>
          <Stack vertical fill>
            <Stack.Item>
              {ready && (
                <CharacterControls
                  gender={prefs.manually_rendered_features.gender as string}
                  genders={
                    (prefs.valid_choices?.gender as string[]) || [
                      'male',
                      'female',
                    ]
                  }
                  handleOpenSpecies={props.openSpecies}
                  handleRotate={() => act('rotate')}
                  setGender={createSetPreference(act, 'gender')}
                  canDeleteCharacter={!!data.saved}
                  handleDeleteCharacter={() =>
                    setDeleteCharacterPopupOpen(true)
                  }
                />
              )}
            </Stack.Item>

            <Stack.Item grow>
              <ByondUi
                width="220px"
                height="100%"
                params={{ id: data.character_preview_view, type: 'map' }}
              />
            </Stack.Item>

            <Stack.Item position="relative">
              {ready && (
                <NameInput
                  name={prefs.names.real_name}
                  handleUpdateName={createSetPreference(act, 'real_name')}
                />
              )}
            </Stack.Item>
          </Stack>
        </Stack.Item>

        <Stack.Item>
          <Stack fill vertical wrap>
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
              <PreferenceList preferences={prefs.secondary_features || {}} />

              <PreferenceList preferences={nonContextualPreferences}>
                <LabeledList.Item label="Случайная внешность">
                  <Button.Confirm
                    icon="dice"
                    confirmContent="Уверены?"
                    disabled={!!data.appearance_banned}
                    onClick={() => act('randomize_character')}
                  >
                    Сгенерировать
                  </Button.Confirm>
                </LabeledList.Item>
                <LabeledList.Item label="Одежда профессии на превью">
                  <Button
                    icon="shirt"
                    onClick={() => act('toggle_job_clothes')}
                  >
                    Переключить
                  </Button>
                </LabeledList.Item>
                <VoiceAndSound />
                {!!data.appearance_banned && (
                  <LabeledList.Item>
                    <NoticeBox danger>
                      Вам запрещено изменять внешность. После присоединения к
                      раунду персонаж будет сгенерирован случайно.
                    </NoticeBox>
                  </LabeledList.Item>
                )}
              </PreferenceList>
            </Stack>
          )}
        </Stack.Item>
      </Stack>
    </>
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
    <>
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
    </>
  );
}
