import { useEffect, useState } from 'react';
import {
  AnimatedNumber,
  Box,
  Button,
  LabeledList,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type SlotMachineData = {
  money: number | null;
  plays: number;
  working: boolean;
  resultlvl: string;
  result: string;
  reels: string[];
  spin_time: number;
  prize_mod: number;
};

const SYMBOLS: Record<string, string> = {
  cherry: '🍒',
  lemon: '🍋',
  bell: '🔔',
  clover: '🍀',
  bar: 'BAR',
  seven: '7',
};

const SYMBOL_IDS = Object.keys(SYMBOLS);

const PAYTABLE = [
  ['cherry', 50],
  ['lemon', 200],
  ['bell', 500],
  ['bar', 1000],
  ['seven', 10000],
] as const;

const REEL_STOPS = [0.45, 0.7, 0.95];
const SPIN_FRAME_TIME = 70;

const ReelSymbol = (props: { id: string; spinning?: boolean }) => {
  const { id, spinning } = props;
  return (
    <Box
      className={classes([
        'Casino__symbol',
        `Casino__symbol--${id}`,
        spinning ? 'Casino__symbol--spinning' : 'Casino__symbol--stopped',
      ])}
    >
      {SYMBOLS[id]}
    </Box>
  );
};

export const SlotMachine = (_props: unknown) => {
  const { act, data } = useBackend<SlotMachineData>();
  const {
    money,
    plays,
    working,
    result,
    resultlvl,
    reels,
    spin_time,
    prize_mod,
  } = data;
  const [spinStart, setSpinStart] = useState<number | null>(null);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!working) {
      setSpinStart(null);
      return;
    }
    setSpinStart(Date.now());
    const timer = setInterval(() => setNow(Date.now()), SPIN_FRAME_TIME);
    return () => clearInterval(timer);
  }, [working]);

  const elapsed = spinStart ? (now - spinStart) / 1000 : Infinity;
  const isSpinning = (index: number) =>
    working && elapsed < spin_time * REEL_STOPS[index];
  const isJackpotLine =
    !working && !!result && reels.every((reel) => reel === reels[0]);

  if (money === null) {
    return (
      <Window width={380} height={200}>
        <Window.Content>
          <Section>
            <Box bold>Невозможно определить платёжный аккаунт!</Box>
            <Box>
              Наденьте или возьмите в руки вашу карту и попробуйте заново.
            </Box>
          </Section>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={380} height={520}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Box
              className={classes([
                'Casino__reels',
                isJackpotLine && 'Casino__reels--win',
              ])}
            >
              {reels.map((reel, index) => (
                <Box key={index} className="Casino__reel">
                  <ReelSymbol
                    id={
                      isSpinning(index)
                        ? SYMBOL_IDS[
                            Math.floor(now / SPIN_FRAME_TIME + index * 2) %
                              SYMBOL_IDS.length
                          ]
                        : reel
                    }
                    spinning={isSpinning(index)}
                  />
                </Box>
              ))}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box className="Casino__result" color={resultlvl}>
              {working ? 'Барабаны крутятся...' : result}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="coins"
              fontSize="1.4em"
              textAlign="center"
              color="good"
              disabled={working || money < 50}
              onClick={() => act('spin')}
            >
              {working ? 'Подождите...' : 'Крутить за 50 кр.'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <LabeledList>
                <LabeledList.Item label="На счету">
                  <AnimatedNumber value={money} /> кр.
                </LabeledList.Item>
                <LabeledList.Item label="Игр сегодня">{plays}</LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Выплаты" fill>
              <Table>
                {PAYTABLE.map(([id, prize]) => (
                  <Table.Row key={id}>
                    <Table.Cell>
                      {SYMBOLS[id]} {SYMBOLS[id]} {SYMBOLS[id]}
                    </Table.Cell>
                    <Table.Cell textAlign="right" color="good">
                      {prize * prize_mod} кр.
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
