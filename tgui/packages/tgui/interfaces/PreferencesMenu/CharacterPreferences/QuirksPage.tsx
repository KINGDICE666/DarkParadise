import { filter } from 'es-toolkit/compat';
import { type ReactNode, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Floating,
  Icon,
  Input,
  LabeledList,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { createSearch } from 'tgui-core/string';
import { features } from '../preferences/features';
import { FeatureValueInput } from '../preferences/features/base';
import {
  type BodyStatus,
  type PreferencesMenuData,
  type Quirk,
  RandomSetting,
  type ServerData,
} from '../types';
import { useRandomToggleState } from '../useRandomToggleState';
import { useServerPrefs } from '../useServerPrefs';
import { getRandomization, PreferenceList } from './MainPage';

function getColorValueClass(quirk: Quirk) {
  if (quirk.value > 0) {
    return 'positive';
  } else if (quirk.value < 0) {
    return 'negative';
  } else {
    return 'neutral';
  }
}

function getCorrespondingPreferences(
  customization_options: string[],
  relevant_preferences: Record<string, string> = {},
) {
  return Object.fromEntries(
    filter(Object.entries(relevant_preferences), ([key, value]) =>
      customization_options.includes(key),
    ),
  );
}

type QuirkEntry = [string, Quirk & { failTooltip?: string }];

type QuirkListProps = {
  quirks: QuirkEntry[];
};

type QuirkProps = {
  handleClick: (quirkName: string, quirk: Quirk) => void;
  randomBodyEnabled: boolean;
  selected: boolean;
  serverData: ServerData;
  quirkActionLocked: boolean;
};

function QuirkList(props: QuirkProps & QuirkListProps) {
  const {
    quirks = [],
    selected,
    handleClick,
    serverData,
    randomBodyEnabled,
    quirkActionLocked,
  } = props;

  return (
    <Stack vertical g={0}>
      {quirks.map(([quirkKey, quirk]) => (
        <Stack.Item key={quirkKey} m={0}>
          <QuirkDisplay
            handleClick={handleClick}
            quirk={quirk}
            quirkKey={quirkKey}
            randomBodyEnabled={randomBodyEnabled}
            selected={selected}
            serverData={serverData}
            quirkActionLocked={quirkActionLocked}
          />
        </Stack.Item>
      ))}
    </Stack>
  );
}

type QuirkDisplayProps = {
  quirk: Quirk & { failTooltip?: string };
  quirkKey: string;
} & QuirkProps;

function QuirkDisplay(props: QuirkDisplayProps) {
  const { quirk, quirkKey, handleClick, selected, quirkActionLocked } = props;
  const pointsEnabled = !!props.serverData.disabilities.points_enabled;
  const { icon, value, name, description, customizable, failTooltip } = quirk;

  const [customizationExpanded, setCustomizationExpanded] = useState(false);

  const className = 'PreferencesMenu__Quirks__QuirkList__quirk';

  const child = (
    <Box
      className={className}
      style={{
        opacity: props.quirkActionLocked ? 0.6 : 1,
        pointerEvents: props.quirkActionLocked ? 'none' : 'auto',
      }}
      onClick={() => {
        if (quirkActionLocked) {
          return;
        }
        if (selected) {
          setCustomizationExpanded(false);
        }

        handleClick(quirkKey, quirk);
      }}
    >
      <Stack fill g={0}>
        <Stack.Item
          align="center"
          style={{
            minWidth: '15%',
            maxWidth: '15%',
            textAlign: 'center',
          }}
        >
          <Icon color="#333" fontSize={3} name={icon} />
        </Stack.Item>

        <Stack.Item
          align="stretch"
          ml={0}
          style={{
            borderRight: '1px solid black',
          }}
        />

        <Stack.Item
          grow
          ml={0}
          style={{
            minWidth: '0%',
          }}
        >
          <Stack vertical fill>
            <Stack.Item
              className={`${className}--${getColorValueClass(quirk)}`}
              style={{
                borderBottom: '1px solid black',
                padding: '2px',
              }}
            >
              <Stack
                fill
                style={{
                  fontSize: '1.2em',
                }}
              >
                <Stack.Item grow basis="content">
                  <b>{name}</b>
                </Stack.Item>

                {pointsEnabled && (
                  <Stack.Item>
                    <b>{value}</b>
                  </Stack.Item>
                )}
              </Stack>
            </Stack.Item>

            <Stack.Item
              grow
              basis="content"
              mt={0}
              style={{
                padding: '3px',
              }}
            >
              {description}
              {!!customizable && (
                <QuirkPopper
                  {...props}
                  customizationExpanded={customizationExpanded}
                  setCustomizationExpanded={setCustomizationExpanded}
                />
              )}
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );

  if (failTooltip) {
    return <Tooltip content={failTooltip}>{child}</Tooltip>;
  } else {
    return child;
  }
}

type QuirkPopperProps = {
  customizationExpanded: boolean;
  setCustomizationExpanded: (expanded: boolean) => void;
} & QuirkDisplayProps;

function QuirkPopper(props: QuirkPopperProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const {
    customizationExpanded,
    quirk,
    randomBodyEnabled,
    selected,
    serverData,
    setCustomizationExpanded,
  } = props;

  const { customizable, customization_options } = quirk;

  const { character_preferences } = data;

  const hasExpandableCustomization =
    customizable &&
    selected &&
    customization_options &&
    Object.entries(customization_options).length > 0;

  return (
    <Floating
      stopChildPropagation
      placement="bottom-end"
      onOpenChange={setCustomizationExpanded}
      content={
        hasExpandableCustomization && (
          <Box
            onClick={(e) => {
              e.stopPropagation();
            }}
            style={{
              boxShadow: '0px 4px 8px 3px rgba(0, 0, 0, 0.7)',
            }}
          >
            <Stack maxWidth="300px" backgroundColor="black" px="5px" py="3px">
              <Stack.Item>
                <PreferenceList
                  preferences={getCorrespondingPreferences(
                    customization_options,
                    character_preferences.manually_rendered_features,
                  )}
                  randomizations={getRandomization(
                    getCorrespondingPreferences(
                      customization_options,
                      character_preferences.manually_rendered_features,
                    ),
                    serverData,
                    randomBodyEnabled,
                  )}
                  maxHeight="100px"
                />
              </Stack.Item>
            </Stack>
          </Box>
        )
      }
    >
      <div style={{ display: 'flow-root' }}>
        {selected && (
          <Button
            selected={customizationExpanded}
            icon="cog"
            tooltip="Настроить"
            style={{
              float: 'right',
            }}
          />
        )}
      </div>
    </Floating>
  );
}

function StatDisplay(props) {
  const { children } = props;

  return (
    <Box
      backgroundColor="#eee"
      bold
      color="black"
      fontSize="1.2em"
      px={3}
      py={0.5}
    >
      {children}
    </Box>
  );
}

function QuirkPage() {
  const { act, data } = useBackend<PreferencesMenuData>();

  const [randomToggleEnabled] = useRandomToggleState();
  const randomBodyEnabled =
    data.character_preferences.non_contextual.random_body !==
      RandomSetting.Disabled || randomToggleEnabled;

  const selectedQuirks = data.selected_quirks;
  function setSelectedQuirks(selected_quirks) {
    data.selected_quirks = selected_quirks;
  }

  const [quirkActionLocked, setQuirkActionLocked] = useState(false);

  function withQuirkDebounce(debounce: () => void, delay = 200) {
    if (quirkActionLocked) return;

    setQuirkActionLocked(true);
    debounce();

    setTimeout(() => {
      setQuirkActionLocked(false);
    }, delay);
  }

  const [searchQuery, setSearchQuery] = useState('');
  const server_data = useServerPrefs();
  if (!server_data) return;
  const quirkSearch = createSearch(searchQuery, (quirk: Quirk) => quirk.name);
  const {
    max_positive_quirks: maxPositiveQuirks,
    quirk_blacklist: quirkBlacklist,
    quirk_info: quirkInfo,
    points_enabled: pointsEnabled,
  } = server_data.disabilities;

  const quirks = Object.entries(quirkInfo);
  quirks.sort(([_, quirkA], [__, quirkB]) => {
    if (quirkA.value === quirkB.value) {
      return quirkA.name > quirkB.name ? 1 : -1;
    } else {
      return quirkA.value - quirkB.value;
    }
  });

  let balance = -data.default_quirk_balance;
  let positiveQuirks = 0;

  for (const selectedQuirkName of selectedQuirks) {
    const selectedQuirk = quirkInfo[selectedQuirkName];
    if (!selectedQuirk) {
      continue;
    }

    if (selectedQuirk.value > 0) {
      positiveQuirks += 1;
    }

    balance += selectedQuirk.value;
  }

  function getReasonToNotAdd(quirkName: string) {
    const quirk = quirkInfo[quirkName];

    if (quirk.value > 0) {
      if (maxPositiveQuirks !== -1 && positiveQuirks >= maxPositiveQuirks) {
        return 'Больше положительных особенностей взять нельзя!';
      } else if (pointsEnabled && balance + quirk.value > 0) {
        return 'Сначала возьмите отрицательную особенность!';
      }
    }

    const selectedQuirkNames = selectedQuirks.map((quirkKey) => {
      return quirkInfo[quirkKey]?.name;
    });

    for (const blacklist of quirkBlacklist) {
      if (blacklist.indexOf(quirk.name) === -1) {
        continue;
      }

      for (const incompatibleQuirk of blacklist) {
        if (
          incompatibleQuirk !== quirk.name &&
          selectedQuirkNames.indexOf(incompatibleQuirk) !== -1
        ) {
          return `Несовместимо с «${incompatibleQuirk}»!`;
        }
      }
    }
    if (data.species_disallowed_quirks.includes(quirkName)) {
      return 'Недоступно для выбранной расы.';
    }
    return;
  }

  function getReasonToNotRemove(quirkName: string) {
    const quirk = quirkInfo[quirkName];

    if (pointsEnabled && balance - quirk.value > 0) {
      return 'Сначала уберите положительную особенность!';
    }

    return;
  }

  return (
    <Stack fill>
      <Stack.Item basis="50%">
        <Stack vertical fill align="center">
          <Stack.Item>
            {maxPositiveQuirks > 0 ? (
              <Box fontSize="1.3em">Положительные особенности</Box>
            ) : (
              <Box mt={pointsEnabled ? 3.4 : 0} />
            )}
          </Stack.Item>

          <Stack.Item>
            {maxPositiveQuirks > 0 ? (
              <StatDisplay>
                {positiveQuirks} / {maxPositiveQuirks}
              </StatDisplay>
            ) : (
              <Box mt={pointsEnabled ? 3.4 : 0} />
            )}
          </Stack.Item>

          <Stack.Item>
            <Box as="b" fontSize="1.6em">
              Доступные особенности
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Input
              placeholder="Поиск особенностей..."
              width="200px"
              value={searchQuery}
              onChange={setSearchQuery}
            />
          </Stack.Item>
          <Stack.Item grow className="PreferencesMenu__Quirks__QuirkList">
            <QuirkList
              selected={false}
              quirkActionLocked={quirkActionLocked}
              handleClick={(quirkName, quirk) => {
                if (getReasonToNotAdd(quirkName) !== undefined) {
                  return;
                }

                withQuirkDebounce(() => {
                  setSelectedQuirks(selectedQuirks.concat(quirkName));
                  act('give_quirk', { quirk: quirkName });
                });
              }}
              quirks={quirks
                .filter(([quirkName, _]) => {
                  return (
                    selectedQuirks.indexOf(quirkName) === -1 &&
                    quirkSearch(quirkInfo[quirkName])
                  );
                })
                .map(([quirkName, quirk]) => {
                  return [
                    quirkName,
                    {
                      ...quirk,
                      failTooltip: getReasonToNotAdd(quirkName),
                    },
                  ];
                })}
              serverData={server_data}
              randomBodyEnabled={randomBodyEnabled}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>

      <Stack.Item align="center">
        <Icon name="exchange-alt" size={1.5} ml={2} mr={2} />
      </Stack.Item>

      <Stack.Item basis="50%">
        <Stack vertical fill align="center">
          <Stack.Item>
            {pointsEnabled ? (
              <Box fontSize="1.3em">Баланс особенностей</Box>
            ) : (
              <Box mt={maxPositiveQuirks > 0 ? 3.4 : 0} />
            )}
          </Stack.Item>
          <Stack.Item>
            {pointsEnabled ? (
              <StatDisplay>{balance}</StatDisplay>
            ) : (
              <Box mt={maxPositiveQuirks > 0 ? 3.4 : 0} />
            )}
          </Stack.Item>
          <Stack.Item>
            <Box as="b" fontSize="1.6em">
              Текущие особенности
            </Box>
          </Stack.Item>
          <Stack.Item p={1.5} />
          <Stack.Item grow className="PreferencesMenu__Quirks__QuirkList">
            <QuirkList
              selected
              quirkActionLocked={quirkActionLocked}
              handleClick={(quirkName, quirk) => {
                if (getReasonToNotRemove(quirkName) !== undefined) {
                  return;
                }

                withQuirkDebounce(() => {
                  setSelectedQuirks(
                    selectedQuirks.filter(
                      (otherQuirk) => quirkName !== otherQuirk,
                    ),
                  );

                  act('remove_quirk', { quirk: quirkName });
                });
              }}
              quirks={quirks
                .filter(([quirkName, _]) => {
                  return selectedQuirks.indexOf(quirkName) !== -1;
                })
                .map(([quirkName, quirk]) => {
                  return [
                    quirkName,
                    {
                      ...quirk,
                      failTooltip: getReasonToNotRemove(quirkName),
                    },
                  ];
                })}
              serverData={server_data}
              randomBodyEnabled={randomBodyEnabled}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}

const BODY_STATES: Record<string, { color: string; icon: string }> = {
  organic: { color: 'green', icon: 'heart' },
  cyborg: { color: 'blue', icon: 'robot' },
  cybernetic: { color: 'blue', icon: 'microchip' },
  amputated: { color: 'red', icon: 'times' },
};

type BodyStatusListProps = {
  title: string;
  entries: BodyStatus[];
  action: string;
  buttons?: ReactNode;
};

function BodyStatusList(props: BodyStatusListProps) {
  const { act } = useBackend<PreferencesMenuData>();

  return (
    <Section title={props.title} fill scrollable buttons={props.buttons}>
      <LabeledList>
        {props.entries.map((entry) => {
          const state = BODY_STATES[entry.state] || BODY_STATES.organic;
          return (
            <LabeledList.Item key={entry.zone} label={entry.name}>
              <Button
                fluid
                color={state.color}
                icon={state.icon}
                onClick={() => act(props.action, { zone: entry.zone })}
              >
                {entry.status}
              </Button>
            </LabeledList.Item>
          );
        })}
      </LabeledList>
    </Section>
  );
}

function BodyPartsPage() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const organs = data.organs || [];

  return (
    <Stack fill>
      <Stack.Item grow basis={0}>
        <BodyStatusList
          title="Части тела"
          entries={data.limbs || []}
          action="edit_limb"
          buttons={
            !!data.ipc_loadout && (
              <Button icon="robot" onClick={() => act('ipc_loadout')}>
                Модель оболочки
              </Button>
            )
          }
        />
      </Stack.Item>
      {organs.length > 0 && (
        <Stack.Item grow basis={0}>
          <BodyStatusList title="Органы" entries={organs} action="edit_organ" />
        </Stack.Item>
      )}
    </Stack>
  );
}

const RECORDS_LAYOUT = [
  ['flavor_text'],
  ['med_record', 'sec_record'],
  ['gen_record', 'exploit_record'],
  ['OOC_Notes'],
];

function RecordsPage() {
  const { data } = useBackend<PreferencesMenuData>();
  const records = data.character_preferences.manually_rendered_features || {};

  return (
    <Stack vertical fill>
      {RECORDS_LAYOUT.map((row) => (
        <Stack.Item key={row[0]} grow>
          <Stack fill>
            {row
              .filter((featureId) => records[featureId] !== undefined)
              .map((featureId) => (
                <Stack.Item key={featureId} grow basis={0}>
                  <Section title={features[featureId]?.name} fill>
                    <FeatureValueInput
                      feature={features[featureId]}
                      featureId={featureId}
                      value={records[featureId]}
                    />
                  </Section>
                </Stack.Item>
              ))}
          </Stack>
        </Stack.Item>
      ))}
    </Stack>
  );
}

enum QuirksSubPage {
  Quirks,
  Body,
  Records,
}

export function QuirkPersonalityPage() {
  const [contentPage, setContentPage] = useState(QuirksSubPage.Quirks);

  const tabs = [
    [QuirksSubPage.Quirks, 'Особенности'],
    [QuirksSubPage.Body, 'Тело'],
    [QuirksSubPage.Records, 'Записи'],
  ] as const;

  let content;
  switch (contentPage) {
    case QuirksSubPage.Quirks:
      content = <QuirkPage />;
      break;
    case QuirksSubPage.Body:
      content = <BodyPartsPage />;
      break;
    case QuirksSubPage.Records:
      content = <RecordsPage />;
      break;
  }

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Stack>
          {tabs.map(([page, title]) => (
            <Stack.Item grow key={page}>
              <Button
                selected={contentPage === page}
                onClick={() => setContentPage(page)}
                fluid
                align="center"
                fontSize="14px"
              >
                {title}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      </Stack.Item>
      <Stack.Item grow>{content}</Stack.Item>
    </Stack>
  );
}
