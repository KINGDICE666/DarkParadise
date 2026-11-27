import {
  BlockQuote,
  Box,
  Button,
  Icon,
  Section,
  Stack,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Objective = {
  explanation: string;
  complete: BooleanLike;
};

type ChronoLegionnaireData = {
  mission: string;
  objectives: Objective[];
  erased: string[];
  can_leave: BooleanLike;
};

export const ChronoLegionnaire = (_props: unknown) => {
  const { act, data } = useBackend<ChronoLegionnaireData>();
  const { mission, objectives = [], erased = [], can_leave } = data;

  return (
    <Window width={420} height={460}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Миссия">
              <BlockQuote>{mission}</BlockQuote>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Цели">
              {objectives.length === 0 ? (
                <Box color="label">Особых целей нет.</Box>
              ) : (
                objectives.map((objective, index) => (
                  <Box key={index} mb={0.5}>
                    <Icon
                      name={objective.complete ? 'check' : 'hourglass-half'}
                      color={objective.complete ? 'good' : 'average'}
                      mr={1}
                    />
                    {objective.explanation}
                  </Box>
                ))
              )}
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable title="Стёрты из времени">
              {erased.length === 0 ? (
                <Box color="label">Пока никого.</Box>
              ) : (
                erased.map((name, index) => <Box key={index}>{name}</Box>)
              )}
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Button.Confirm
              fluid
              textAlign="center"
              icon="hourglass-end"
              color="bad"
              disabled={!can_leave}
              tooltip={can_leave ? undefined : 'Сначала выполните цели.'}
              confirmContent="Точно покинуть реальность?"
              onClick={() => act('leave_reality')}
            >
              Покинуть реальность
            </Button.Confirm>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
