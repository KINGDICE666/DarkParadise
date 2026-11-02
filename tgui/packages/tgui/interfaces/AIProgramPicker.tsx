import { Button, LabeledList, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Program = {
  name: string;
  UID: string;
  description: string;
  memory_cost: number;
  installed: number;
  upgrade_level: number;
  is_passive: number;
};

type Data = {
  program_list: Program[];
  ai_info: {
    memory: number;
    bandwidth: number;
  };
};

export const AIProgramPicker = (props: unknown) => {
  const { act, data } = useBackend<Data>();
  const { program_list, ai_info } = data;
  return (
    <Window width={450} height={600}>
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Выбор программы">
              <LabeledList>
                <LabeledList.Item label="Доступно памяти">
                  {ai_info.memory}
                </LabeledList.Item>
                <LabeledList.Item label="Доступно пропускной способности">
                  {ai_info.bandwidth}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            {!!program_list &&
              program_list.map((program) => (
                <Section
                  key={program.UID}
                  title={program.name}
                  mb={1}
                  buttons={
                    <Button
                      icon="file"
                      onClick={() => act('select', { uid: program.UID })}
                    >
                      {program.installed === 1 ? 'Улучшить' : 'Установить'}
                    </Button>
                  }
                >
                  <Stack vertical>
                    <LabeledList>
                      <Stack.Item mb={2}>
                        <LabeledList.Item label="Описание">
                          {program.description}
                        </LabeledList.Item>
                      </Stack.Item>
                      <Stack>
                        <Stack.Item>
                          <LabeledList.Item
                            label={
                              program.installed === 1
                                ? 'Цена в пропускной способности'
                                : 'Цена в памяти'
                            }
                          >
                            {program.memory_cost}
                          </LabeledList.Item>
                          <LabeledList.Item label="Уровень улучшения">
                            {program.upgrade_level}
                          </LabeledList.Item>
                        </Stack.Item>
                        <Stack.Item>
                          <LabeledList.Item label="Установлена">
                            {program.installed === 1 ? 'Да' : 'Нет'}
                          </LabeledList.Item>
                          <LabeledList.Item label="Пассивная">
                            {program.is_passive === 1 ? 'Да' : 'Нет'}
                          </LabeledList.Item>
                        </Stack.Item>
                      </Stack>
                    </LabeledList>
                  </Stack>
                </Section>
              ))}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
