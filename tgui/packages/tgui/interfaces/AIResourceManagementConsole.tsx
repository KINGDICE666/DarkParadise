import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { capitalize } from 'tgui-core/string';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type AIEntry = {
  name: string;
  uid: string;
  memory: number;
  memory_max: number;
  bandwidth: number;
  bandwidth_max: number;
};

type NodeEntry = {
  name: string;
  uid: string;
  resource: string;
  amount: number;
  assigned_ai: string | null;
};

type Data = {
  auth: boolean;
  screen: number;
  ai_list: AIEntry[];
  nodes_list: NodeEntry[];
};

const AIResourceManagementConsoleBody = (props: unknown) => {
  const { data } = useBackend<Data>();
  const { screen } = data;
  let body;

  if (screen === 0) {
    body = <AllocatedResources />;
  } else if (screen === 1) {
    body = <OnlineNodes />;
  }
  return body;
};

export const AIResourceManagementConsole = (props: unknown) => {
  const { act, data } = useBackend<Data>();
  const { screen } = data;

  return (
    <Window width={400} height={425}>
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={screen === 0}
                icon="list"
                onClick={() => act('menu', { screen: 0 })}
              >
                Распределение ресурсов
              </Tabs.Tab>
              <Tabs.Tab
                selected={screen === 1}
                icon="circle-nodes"
                onClick={() => act('menu', { screen: 1 })}
              >
                Активные узлы
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow mt={0}>
            <Section fill scrollable>
              <AIResourceManagementConsoleBody />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const AllocatedResources = (props: unknown) => {
  const { data } = useBackend<Data>();
  const { ai_list } = data;
  return (
    <Box>
      {(!ai_list || ai_list.length === 0) && (
        <NoticeBox>ИИ не обнаружены.</NoticeBox>
      )}
      {!!ai_list &&
        ai_list.map((ai) => (
          <Section key={ai.uid} title={ai.name}>
            <LabeledList>
              <LabeledList.Item label="Память">{ai.memory}</LabeledList.Item>
              <LabeledList.Item label="Максимум памяти">
                {ai.memory_max}
              </LabeledList.Item>
              <LabeledList.Item label="Пропускная способность">
                {ai.bandwidth}
              </LabeledList.Item>
              <LabeledList.Item label="Максимум пропускной способности">
                {ai.bandwidth_max}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        ))}
    </Box>
  );
};

const OnlineNodes = (props: unknown) => {
  const { act, data } = useBackend<Data>();
  const { nodes_list } = data;
  return (
    <Box>
      {(!nodes_list || nodes_list.length === 0) && (
        <NoticeBox>Узлы не обнаружены.</NoticeBox>
      )}
      {!!nodes_list &&
        nodes_list.map((node) => (
          <Section
            key={node.uid}
            title={capitalize(node.name)}
            buttons={
              <Box>
                <Button
                  icon="circle-nodes"
                  onClick={() => act('reassign', { uid: node.uid })}
                >
                  Переназначить
                </Button>
              </Box>
            }
          >
            <LabeledList>
              <LabeledList.Item label="Назначенный ИИ">
                {node.assigned_ai}
              </LabeledList.Item>
              <LabeledList.Item label="Ресурс">
                {capitalize(node.resource)}
              </LabeledList.Item>
              <LabeledList.Item label="Количество">
                {node.amount}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        ))}
    </Box>
  );
};
