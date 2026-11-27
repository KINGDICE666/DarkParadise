import { useRef, useState } from 'react';
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

type Sector = {
  id: string;
  name: string;
  multiplier: number;
};

type CasinoWheelData = {
  money: number | null;
  working: boolean;
  is_player: boolean;
  bet: number;
  min_bet: number;
  max_bet: number;
  last_result: string | null;
  history: string[];
  layout: string[];
  sectors: Sector[];
  spin_time: number;
  result_index: number;
  spins: number;
  bet_color: string | null;
};

const SECTOR_COLORS: Record<string, string> = {
  blue: 'hsl(210, 70%, 52%)',
  green: 'hsl(145, 63%, 42%)',
  red: 'hsl(6, 78%, 52%)',
  black: 'hsl(0, 0%, 10%)',
};

const WHEEL_RADIUS = 100;
const FULL_TURNS = 6;

const sectorPath = (index: number, count: number) => {
  const start = (index / count) * 2 * Math.PI - Math.PI / 2;
  const end = ((index + 1) / count) * 2 * Math.PI - Math.PI / 2;
  const x1 = WHEEL_RADIUS + WHEEL_RADIUS * Math.cos(start);
  const y1 = WHEEL_RADIUS + WHEEL_RADIUS * Math.sin(start);
  const x2 = WHEEL_RADIUS + WHEEL_RADIUS * Math.cos(end);
  const y2 = WHEEL_RADIUS + WHEEL_RADIUS * Math.sin(end);
  return `M${WHEEL_RADIUS},${WHEEL_RADIUS} L${x1},${y1} A${WHEEL_RADIUS},${WHEEL_RADIUS} 0 0,1 ${x2},${y2} Z`;
};

export const CasinoWheel = (_props: unknown) => {
  const { act, data } = useBackend<CasinoWheelData>();
  const {
    money,
    working,
    min_bet,
    max_bet,
    last_result,
    history,
    layout,
    sectors,
    spin_time,
    result_index,
    spins,
    bet_color,
  } = data;
  const [betInput, setBetInput] = useState(min_bet);
  const openedSpins = useRef(spins);
  const animate = spins !== openedSpins.current;

  const sectorAngle = 360 / layout.length;
  const rotation =
    spins * 360 * FULL_TURNS - (result_index - 0.5) * sectorAngle;
  const won = !working && !!last_result && history[0] === bet_color;

  return (
    <Window width={400} height={640}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Box className="Casino__wheelBox">
              <Box className="Casino__pointer" />
              <svg
                className="Casino__wheel"
                viewBox={`0 0 ${WHEEL_RADIUS * 2} ${WHEEL_RADIUS * 2}`}
                style={{
                  transform: `rotate(${rotation}deg)`,
                  transition: animate
                    ? `transform ${spin_time}s cubic-bezier(0.15, 0.6, 0.1, 1)`
                    : 'none',
                }}
              >
                {layout.map((color, index) => (
                  <path
                    key={index}
                    d={sectorPath(index, layout.length)}
                    fill={SECTOR_COLORS[color]}
                    stroke="hsla(45, 95%, 58%, 0.55)"
                    strokeWidth={0.6}
                  />
                ))}
                <circle
                  cx={WHEEL_RADIUS}
                  cy={WHEEL_RADIUS}
                  r={16}
                  fill="hsl(45, 95%, 58%)"
                  stroke="hsl(45, 60%, 30%)"
                  strokeWidth={3}
                />
              </svg>
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box
              className="Casino__result"
              color={won ? 'good' : working ? 'label' : 'bad'}
            >
              {working ? 'Колесо крутится...' : last_result}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Stack>
              {sectors.map((sector) => (
                <Stack.Item grow key={sector.id}>
                  <Button
                    fluid
                    className={classes([
                      'Casino__colorButton',
                      `Casino__colorButton--${sector.id}`,
                    ])}
                    disabled={working || money === null || money < betInput}
                    tooltip={`${sector.name}: выигрыш x${sector.multiplier}`}
                    onClick={() =>
                      act('spin', { color: sector.id, bet: betInput })
                    }
                  >
                    {sector.name} x{sector.multiplier}
                  </Button>
                </Stack.Item>
              ))}
            </Stack>
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
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Последние результаты" fill>
              <Box className="Casino__chips">
                {history.map((color, index) => (
                  <Box
                    key={index}
                    className={classes([
                      'Casino__chip',
                      `Casino__chip--${color}`,
                    ])}
                  >
                    {sectors.find((sector) => sector.id === color)?.name}
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
