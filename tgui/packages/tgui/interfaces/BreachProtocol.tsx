import { Box, Button, ProgressBar, Section, Stack } from 'tgui-core/components';
import { classes } from 'tgui-core/react';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Daemon = {
  id: string;
  name: string;
  desc: string;
  sequence: string[];
  done: BooleanLike;
};

type Data = {
  zone: string;
  black: BooleanLike;
  grid: string[][];
  used: BooleanLike[][];
  axis_row: BooleanLike;
  active: number;
  buffer: string[];
  buffer_size: number;
  daemons: Daemon[];
  time_left: number;
  time_limit: number;
};

const CodeMatrix = () => {
  const { act, data } = useBackend<Data>();
  const { grid, used, axis_row, active } = data;

  return (
    <div
      className="Cyberdeck__breachGrid Cyberdeck__mono"
      style={{ gridTemplateColumns: `repeat(${grid.length}, 1fr)` }}
    >
      {grid.map((line, row) =>
        line.map((code, column) => {
          const inLine = axis_row ? row === active : column === active;
          const spent = !!used[row][column];
          return (
            <div
              key={`${row}-${column}`}
              className={classes([
                'Cyberdeck__breachCell',
                inLine && 'Cyberdeck__breachCell--line',
                spent && 'Cyberdeck__breachCell--used',
                inLine && !spent && 'Cyberdeck__breachCell--pickable',
              ])}
              onClick={() => inLine && !spent && act('pick', { row, column })}
            >
              {spent ? '[ ]' : code}
            </div>
          );
        }),
      )}
    </div>
  );
};

const BufferRow = () => {
  const { data } = useBackend<Data>();
  const { buffer, buffer_size } = data;

  return (
    <div className="Cyberdeck__breachBuffer Cyberdeck__mono">
      {Array.from({ length: buffer_size }, (_, index) => (
        <div
          key={index}
          className={classes([
            'Cyberdeck__breachSlot',
            index < buffer.length && 'Cyberdeck__breachSlot--filled',
          ])}
        >
          {buffer[index] || ''}
        </div>
      ))}
    </div>
  );
};

const DaemonList = () => {
  const { data } = useBackend<Data>();

  return (
    <Stack vertical>
      {data.daemons.map((daemon) => (
        <Stack.Item key={daemon.id}>
          <div
            className={classes([
              'Cyberdeck__breachDaemon',
              !!daemon.done && 'Cyberdeck__breachDaemon--done',
            ])}
          >
            <div className="Cyberdeck__breachDaemonHead">
              <span>{daemon.name}</span>
              <span className="Cyberdeck__breachCodes Cyberdeck__mono">
                {daemon.sequence.join(' ')}
              </span>
            </div>
            <Box className="Cyberdeck__breachDaemonDesc">
              {daemon.done ? 'Загружено' : daemon.desc}
            </Box>
          </div>
        </Stack.Item>
      ))}
    </Stack>
  );
};

export const BreachProtocol = () => {
  const { act, data } = useBackend<Data>();
  const { zone, black, time_left, time_limit, daemons } = data;
  const iceDone = daemons.some((daemon) => daemon.id === 'ice' && daemon.done);

  return (
    <Window
      width={460}
      height={620}
      theme={black ? 'cyberdeck_black' : 'cyberdeck'}
    >
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <div className="Cyberdeck__header">
              <div className="Cyberdeck__deckName">
                {black ? 'Чёрный лёд' : 'Лёд'}: {zone}
              </div>
              <Button
                icon="right-from-bracket"
                color={iceDone ? 'good' : 'bad'}
                onClick={() => act('complete')}
              >
                {iceDone ? 'Завершить взлом' : 'Сдаться'}
              </Button>
            </div>
            <ProgressBar
              mt={0.5}
              value={time_left / time_limit}
              ranges={{
                good: [0.5, Infinity],
                average: [0.25, 0.5],
                bad: [-Infinity, 0.25],
              }}
            >
              {Math.ceil(time_left / 10)} с
            </ProgressBar>
          </Stack.Item>
          <Stack.Item>
            <Section title="Буфер">
              <BufferRow />
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Матрица кода">
              <CodeMatrix />
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section title="Демоны" fill>
              <DaemonList />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
