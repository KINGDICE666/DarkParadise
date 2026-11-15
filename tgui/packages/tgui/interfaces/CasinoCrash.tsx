import { useEffect, useState } from 'react';
import {
  AnimatedNumber,
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type CasinoCrashData = {
  money: number | null;
  working: boolean;
  is_player: boolean;
  bet: number;
  min_bet: number;
  max_bet: number;
  last_result: string | null;
  history: number[];
  growth: number;
  elapsed: number;
  crash_point: number | null;
  cashed_out: number;
  auto_cashout: number;
};

const GRAPH_WIDTH = 340;
const GRAPH_HEIGHT = 190;
const GRAPH_POINTS = 48;
const FRAME_TIME = 50;

const multiplierAt = (growth: number, seconds: number) =>
  Math.floor(Math.exp(growth * seconds) * 100) / 100;

const chipClass = (value: number) => {
  if (value < 2) {
    return 'Casino__chip--low';
  }
  return value < 10 ? 'Casino__chip--mid' : 'Casino__chip--high';
};

const CrashGraph = (props: {
  growth: number;
  seconds: number;
  crashed: boolean;
}) => {
  const { growth, seconds, crashed } = props;
  const span = Math.max(8, seconds * 1.15);
  const top = Math.max(2, Math.exp(growth * seconds) * 1.2);
  const points: string[] = [];
  for (let step = 0; step <= GRAPH_POINTS; step++) {
    const time = (seconds * step) / GRAPH_POINTS;
    const value = Math.exp(growth * time);
    const x = (time / span) * GRAPH_WIDTH;
    const y =
      GRAPH_HEIGHT - 10 - ((value - 1) / (top - 1)) * (GRAPH_HEIGHT - 30);
    points.push(`${x.toFixed(1)},${y.toFixed(1)}`);
  }
  const color = crashed ? 'hsl(6, 78%, 57%)' : 'hsl(145, 63%, 55%)';

  return (
    <svg
      width="100%"
      height="100%"
      viewBox={`0 0 ${GRAPH_WIDTH} ${GRAPH_HEIGHT}`}
      preserveAspectRatio="none"
    >
      {[0.25, 0.5, 0.75].map((fraction) => (
        <line
          key={fraction}
          x1={0}
          x2={GRAPH_WIDTH}
          y1={GRAPH_HEIGHT * fraction}
          y2={GRAPH_HEIGHT * fraction}
          stroke="hsla(210, 30%, 50%, 0.15)"
        />
      ))}
      <polyline
        points={points.join(' ')}
        fill="none"
        stroke={color}
        strokeWidth={3}
        strokeLinejoin="round"
        strokeLinecap="round"
      />
    </svg>
  );
};

export const CasinoCrash = (_props: unknown) => {
  const { act, data } = useBackend<CasinoCrashData>();
  const {
    money,
    working,
    is_player,
    bet,
    min_bet,
    max_bet,
    last_result,
    history,
    growth,
    elapsed,
    crash_point,
    cashed_out,
  } = data;
  const [betInput, setBetInput] = useState(min_bet);
  const [autoInput, setAutoInput] = useState(0);
  const [syncedAt, setSyncedAt] = useState(Date.now());
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    setSyncedAt(Date.now());
  }, [elapsed]);

  useEffect(() => {
    if (!working) {
      return;
    }
    const timer = setInterval(() => setNow(Date.now()), FRAME_TIME);
    return () => clearInterval(timer);
  }, [working]);

  const seconds = working
    ? elapsed + Math.max(0, now - syncedAt) / 1000
    : crash_point
      ? Math.log(crash_point) / growth
      : 0;
  const multiplier = working
    ? multiplierAt(growth, seconds)
    : (crash_point ?? 1);
  const crashed = !working && !!crash_point;

  return (
    <Window width={400} height={600}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Box className="Casino__graph">
              {(working || crashed) && (
                <CrashGraph
                  growth={growth}
                  seconds={seconds}
                  crashed={crashed}
                />
              )}
              <Box
                className={classes([
                  'Casino__multiplier',
                  crashed && 'Casino__multiplier--crashed',
                  !working && !crashed && 'Casino__multiplier--idle',
                ])}
              >
                x{multiplier.toFixed(2)}
                <Box className="Casino__subtitle">
                  {crashed && 'КРАШ'}
                  {working &&
                    (cashed_out
                      ? `Игрок забрал на x${cashed_out.toFixed(2)}`
                      : `Ставка ${bet} кр.`)}
                  {!working && !crashed && 'Ожидание ставки'}
                </Box>
              </Box>
            </Box>
          </Stack.Item>
          <Stack.Item>
            {working && is_player && !cashed_out ? (
              <Button
                fluid
                icon="hand-holding-usd"
                color="good"
                fontSize="1.5em"
                textAlign="center"
                onClick={() => act('cashout')}
              >
                Забрать {Math.floor(bet * multiplier)} кр.
              </Button>
            ) : (
              <Button
                fluid
                icon="rocket"
                color="average"
                fontSize="1.5em"
                textAlign="center"
                disabled={working || money === null || money < betInput}
                onClick={() =>
                  act('start', { bet: betInput, auto_cashout: autoInput })
                }
              >
                {working ? 'Раунд идёт...' : `Старт: ${betInput} кр.`}
              </Button>
            )}
          </Stack.Item>
          <Stack.Item>
            <Box className="Casino__result" color={cashed_out ? 'good' : 'bad'}>
              {last_result}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Section title="Ставка">
              <LabeledList>
                <LabeledList.Item label="На счету">
                  {money === null ? (
                    <Box color="bad">Нет карты</Box>
                  ) : (
                    <>
                      <AnimatedNumber value={money} /> кр.
                    </>
                  )}
                </LabeledList.Item>
                <LabeledList.Item label="Сумма">
                  <NumberInput
                    value={betInput}
                    minValue={min_bet}
                    maxValue={max_bet}
                    step={10}
                    width="90px"
                    disabled={working}
                    onChange={setBetInput}
                  />{' '}
                  {[10, 50, 100, max_bet].map((amount) => (
                    <Button
                      key={amount}
                      disabled={working}
                      onClick={() => setBetInput(amount)}
                    >
                      {amount}
                    </Button>
                  ))}
                </LabeledList.Item>
                <LabeledList.Item label="Автовывод">
                  <NumberInput
                    value={autoInput}
                    minValue={0}
                    maxValue={1000}
                    step={0.1}
                    format={(value) =>
                      value ? `x${value.toFixed(2)}` : 'выкл.'
                    }
                    width="90px"
                    disabled={working}
                    onChange={setAutoInput}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Последние краши" fill>
              <Box className="Casino__chips">
                {history.map((value, index) => (
                  <Box
                    key={index}
                    className={classes(['Casino__chip', chipClass(value)])}
                  >
                    x{value.toFixed(2)}
                  </Box>
                ))}
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
