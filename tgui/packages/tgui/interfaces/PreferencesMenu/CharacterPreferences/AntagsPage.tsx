import {
  Box,
  Button,
  Flex,
  LabeledList,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { useBackend } from '../../../backend';
import { FeatureValueInput } from '../features';
import type { PreferencesMenuData } from '../types';
import { useServerPrefs } from '../useServerPrefs';

const BANNED_REASON = 'Заблокировано';

export function AntagsPage() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const antagonists = useServerPrefs()?.antags?.antagonists || [];
  const selected = data.selected_antags || [];
  const locked = data.locked_antags || {};
  const prefs = data.character_preferences.manually_rendered_features;
  const className = 'PreferencesMenu__Antags__antagSelection';

  return (
    <Stack vertical fill className="PreferencesMenu__Antags">
      <Stack.Item>
        <Section>
          <Stack align="center">
            <Stack.Item grow>
              <LabeledList>
                <LabeledList.Item label="Персонаж может быть антагонистом">
                  <FeatureValueInput
                    featureId="can_be_antagonist"
                    value={prefs.can_be_antagonist}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Местоположение аплинка">
                  <FeatureValueInput
                    featureId="uplink_pref"
                    value={prefs.uplink_pref}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <Button.Checkbox
                checked={!data.skip_antag}
                tooltip="Отключите, чтобы не участвовать в отборе антагонистов в этом раунде"
                onClick={() => act('toggle_skip_antag')}
              >
                Участвовать в отборе
              </Button.Checkbox>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          scrollable
          title="Специальные роли"
          buttons={
            <>
              <Button
                color="good"
                onClick={() => act('set_antags', { enabled: true })}
              >
                Включить все
              </Button>
              <Button
                color="bad"
                onClick={() => act('set_antags', { enabled: false })}
              >
                Выключить все
              </Button>
            </>
          }
        >
          <Flex className={className} align="flex-end" wrap>
            {antagonists.map((antagonist) => {
              const lockReason = locked[antagonist.key];
              const isBanned = lockReason === BANNED_REASON;

              return (
                <Flex.Item
                  className={classes([
                    `${className}__antagonist`,
                    `${className}__antagonist--${
                      lockReason
                        ? 'banned'
                        : selected.includes(antagonist.key)
                          ? 'on'
                          : 'off'
                    }`,
                  ])}
                  key={antagonist.key}
                >
                  <Stack align="center" vertical>
                    <Stack.Item
                      style={{
                        fontWeight: 'bold',
                        marginTop: 'auto',
                        maxWidth: '100px',
                        textAlign: 'center',
                      }}
                    >
                      {antagonist.name}
                    </Stack.Item>
                    <Stack.Item align="center">
                      <Tooltip
                        content={lockReason || antagonist.name}
                        position="bottom"
                      >
                        <Box
                          className="antagonist-icon-parent"
                          onClick={() => {
                            if (!lockReason) {
                              act('toggle_antag', { role: antagonist.key });
                            }
                          }}
                        >
                          {!!antagonist.icon && (
                            <Box
                              className={classes([
                                'antagonists96x96',
                                antagonist.icon,
                                'antagonist-icon',
                              ])}
                            />
                          )}
                          {isBanned && (
                            <Box className="antagonist-banned-slash" />
                          )}
                          {!!lockReason && !isBanned && (
                            <Box className="antagonist-days-left">
                              <b>{lockReason}</b>
                            </Box>
                          )}
                        </Box>
                      </Tooltip>
                    </Stack.Item>
                  </Stack>
                </Flex.Item>
              );
            })}
          </Flex>
        </Section>
      </Stack.Item>
    </Stack>
  );
}
