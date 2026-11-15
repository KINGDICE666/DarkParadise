import { useEffect, useRef, useState } from 'react';
import { Box, Button, KeyListener, Stack } from 'tgui-core/components';
import type { KeyEvent } from 'tgui-core/events';
import { acquireHotKey, releaseHotKey } from 'tgui-core/hotkeys';
import { KEY } from 'tgui-core/keys';
import { type BooleanLike, classes } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  input_code: string;
  code_length: number;
  locked: BooleanLike;
  lock_set: BooleanLike;
  emagged: BooleanLike;
  resetting: BooleanLike;
};

const KEYPAD = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', 'E'];

const KEY_CODE_DELETE = 46;
const KEY_CODE_DIGITS = [
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 96, 97, 98, 99, 100, 101, 102, 103,
  104, 105,
];
const PRESS_FLASH_TIME = 150;
const INPUT_ERROR = 'ERROR';

const keyToButton = (key: string) => {
  if (/^[0-9]$/.test(key)) {
    return key;
  }
  switch (key) {
    case KEY.Enter:
      return 'E';
    case KEY.Backspace:
      return 'B';
    case KEY.Delete:
      return 'C';
  }
  return null;
};

const getDisplay = (data: Data) => {
  if (data.emagged) {
    return 'ERR 1701';
  }
  if (data.resetting) {
    return 'MEM 6040';
  }
  if (data.input_code === INPUT_ERROR) {
    return INPUT_ERROR;
  }
  return data.input_code.padEnd(data.code_length, '_');
};

const getStatus = (data: Data) => {
  if (data.emagged) {
    return ['Замок сломан', 'error'];
  }
  if (data.resetting) {
    return ['Сброс памяти...', 'unset'];
  }
  if (!data.lock_set) {
    return [`Задайте код: ${data.code_length} цифр и E`, 'unset'];
  }
  return data.locked ? ['Заперто', 'locked'] : ['Открыто', 'open'];
};

export const LockedSafe = (_props: unknown) => {
  const { act, data } = useBackend<Data>();
  const [pressed, setPressed] = useState<string | null>(null);
  const flashTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const disabled = !!data.emagged || !!data.resetting;
  const display = getDisplay(data);
  const [statusText, statusType] = getStatus(data);

  useEffect(() => {
    for (const keyCode of [...KEY_CODE_DIGITS, KEY_CODE_DELETE]) {
      acquireHotKey(keyCode);
    }
    return () => {
      for (const keyCode of [...KEY_CODE_DIGITS, KEY_CODE_DELETE]) {
        releaseHotKey(keyCode);
      }
      clearTimeout(flashTimer.current);
    };
  }, []);

  const press = (button: string) => {
    if (disabled) {
      return;
    }
    setPressed(button);
    clearTimeout(flashTimer.current);
    flashTimer.current = setTimeout(() => setPressed(null), PRESS_FLASH_TIME);
    act('keypad', { digit: button });
  };

  const onKeyDown = (key: KeyEvent) => {
    if (key.hasModifierKeys()) {
      return;
    }
    const button = keyToButton(key.event.key);
    if (button) {
      key.event.preventDefault();
      press(button);
    }
  };

  return (
    <Window width={260} height={410}>
      <Window.Content className="LockedSafe">
        <KeyListener onKeyDown={onKeyDown} />
        <Stack vertical fill>
          <Stack.Item>
            <Box
              className={classes([
                'LockedSafe__display',
                (disabled || display === INPUT_ERROR) &&
                  'LockedSafe__display--error',
              ])}
            >
              {display}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box
              className={classes([
                'LockedSafe__status',
                `LockedSafe__status--${statusType}`,
              ])}
            >
              {statusText}
            </Box>
          </Stack.Item>
          <Stack.Item grow>
            <Box className="LockedSafe__keypad">
              {KEYPAD.map((button) => (
                <Button
                  key={button}
                  fluid
                  bold
                  disabled={disabled}
                  textAlign="center"
                  tooltip={
                    button === 'C'
                      ? 'Сбросить ввод и запереть (Delete)'
                      : button === 'E'
                        ? 'Подтвердить код (Enter)'
                        : undefined
                  }
                  className={classes([
                    'LockedSafe__key',
                    button === 'C' && 'LockedSafe__key--clear',
                    button === 'E' && 'LockedSafe__key--enter',
                    pressed === button && 'LockedSafe__key--pressed',
                  ])}
                  onClick={() => press(button)}
                >
                  {button}
                </Button>
              ))}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box className="LockedSafe__hint">
              Можно набирать с клавиатуры: цифры, Enter, Backspace, Delete
            </Box>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
