import { useState } from 'react';
import {
  Box,
  Button,
  Flex,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  pad: BooleanLike;
  sending: BooleanLike;
  status_report: string;
  picking: BooleanLike;
  id_inserted: BooleanLike;
  id_bounty_info: string;
  id_bounty_value: number;
  id_bounty_num: string;
  id_bounty_names: string[];
  id_bounty_infos: string[];
  id_bounty_values: number[];
  listBounty: SingleBounty[];
  claimed_bounties: number;
  bounty_cut: number;
};

type SingleBounty = {
  name: string;
  description: string;
  reward: number;
  shipped: number;
  claimed: BooleanLike;
  maximum: number;
  priority: BooleanLike;
  unique: BooleanLike;
};

export const CivCargoHoldTerminal = (props) => {
  const { data } = useBackend<Data>();
  const { id_inserted } = data;
  const [tab, setTab] = useState('personal');

  return (
    <Window width={580} height={420}>
      <Window.Content scrollable>
        <Section>
          <Tabs fluid>
            <Tabs.Tab
              icon="user"
              onClick={() => setTab('personal')}
              selected={tab === 'personal'}
            >
              Личные баунти
            </Tabs.Tab>
            <Tabs.Tab
              icon="space-shuttle"
              onClick={() => setTab('station')}
              selected={tab === 'station'}
            >
              Баунти станции
            </Tabs.Tab>
          </Tabs>
        </Section>
        <NoticeBox color={id_inserted ? 'blue' : 'default'}>
          {id_inserted
            ? 'Добро пожаловать, ценный сотрудник.'
            : 'Чтобы начать, вставьте ID-карту в консоль.'}
        </NoticeBox>
        {tab === 'personal' ? <PersonalBountyBlock /> : <GlobalBountyBlock />}
      </Window.Content>
    </Window>
  );
};

const PersonalBountyBlock = (props) => {
  const { act, data } = useBackend<Data>();
  const { pad, sending, status_report, id_inserted, id_bounty_info, picking } =
    data;

  return (
    <>
      <Section
        title="Платформа"
        buttons={
          <>
            <Button
              icon="sync"
              tooltip="Проверить груз"
              disabled={!pad || !id_inserted}
              onClick={() => act('recalc')}
            />
            <Button
              icon={sending ? 'times' : 'arrow-up'}
              tooltip={sending ? 'Остановить отправку' : 'Отправить груз'}
              selected={sending}
              disabled={!pad || !id_inserted}
              onClick={() => act(sending ? 'stop' : 'send')}
            />
            <Button
              icon={id_bounty_info ? 'recycle' : 'pen'}
              color={id_bounty_info ? 'green' : 'default'}
              tooltip={id_bounty_info ? 'Заменить баунти' : 'Новая баунти'}
              disabled={!id_inserted}
              onClick={() => act('bounty')}
            />
            <Button
              icon="download"
              disabled={!id_inserted}
              onClick={() => act('eject')}
            >
              Извлечь ID
            </Button>
          </>
        }
      >
        <LabeledList>
          <LabeledList.Item label="Статус" color={pad ? 'good' : 'bad'}>
            {pad ? 'В сети' : 'Не найдена'}
          </LabeledList.Item>
          <LabeledList.Item label="Отчёт">{status_report}</LabeledList.Item>
        </LabeledList>
      </Section>
      {picking ? <BountyPickBox /> : <BountyTextBox />}
    </>
  );
};

const BountyTextBox = (props) => {
  const { data } = useBackend<Data>();
  const { id_bounty_info, id_bounty_value, id_bounty_num } = data;

  return (
    <Section title="Текущая баунти">
      <LabeledList>
        <LabeledList.Item label="Описание">
          {id_bounty_info || 'Н/Д, возьмите новую баунти.'}
        </LabeledList.Item>
        <LabeledList.Item label="Количество">
          {id_bounty_info ? id_bounty_num : 'Н/Д'}
        </LabeledList.Item>
        <LabeledList.Item label="Ваша доля">
          {id_bounty_info ? `${Math.round(id_bounty_value)} кр.` : 'Н/Д'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const BountyPickBox = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    id_bounty_names = [],
    id_bounty_infos = [],
    id_bounty_values = [],
  } = data;

  return (
    <Section title="Выберите баунти:" textAlign="center">
      <Flex width="100%" wrap>
        {id_bounty_names.map((bountyName, index) => (
          <Flex.Item key={bountyName} shrink={0} grow={0.5} px={0.5}>
            <Button
              fluid
              color="green"
              onClick={() => act('pick', { value: index + 1 })}
              style={{
                display: 'flex',
                textWrap: 'wrap',
                whiteSpace: 'normal',
              }}
            >
              <Box>{bountyName}</Box>
              <Box
                textAlign="left"
                color="black"
                backgroundColor="linen"
                lineHeight="1.2em"
                p={1}
              >
                <Box
                  dangerouslySetInnerHTML={{ __html: id_bounty_infos[index] }}
                />
              </Box>
              <Box>Выплата: {Math.round(id_bounty_values[index])} кр.</Box>
            </Button>
          </Flex.Item>
        ))}
      </Flex>
    </Section>
  );
};

const GlobalBountyBlock = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    listBounty = [],
    sending,
    pad,
    id_inserted,
    claimed_bounties,
    bounty_cut,
  } = data;
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const selected = listBounty[selectedIndex];

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <Tabs vertical fluid>
          {listBounty.length < 1 ? (
            <Tabs.Tab
              icon="refresh"
              onClick={() => {
                act('update_list');
                setSelectedIndex(-1);
              }}
            >
              Обновить список
            </Tabs.Tab>
          ) : (
            <Tabs.Tab>
              <Tooltip content="Общих баунти становится на одну больше за каждые три выполненные!">
                <Box>Выполнено баунти: {claimed_bounties}</Box>
              </Tooltip>
            </Tabs.Tab>
          )}
          <Tabs.Tab icon="print" onClick={() => act('print')}>
            Распечатать список
          </Tabs.Tab>
          {listBounty.map((bounty, index) => (
            <Tabs.Tab
              key={`${bounty.name}${index}`}
              icon={bounty.priority ? 'star' : bounty.unique ? 'gem' : ''}
              selected={selectedIndex === index}
              color={bounty.priority ? 'yellow' : bounty.unique ? 'teal' : ''}
              onClick={() => setSelectedIndex(index)}
            >
              {bounty.name}
            </Tabs.Tab>
          ))}
        </Tabs>
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <Section title={selected.name}>
            <ProgressBar
              value={selected.shipped}
              maxValue={selected.maximum}
              mb={1}
            >
              Отправлено: {selected.shipped} / {selected.maximum}
            </ProgressBar>
            <Box dangerouslySetInnerHTML={{ __html: selected.description }} />
            <Box my={1} p={1} backgroundColor="green" color="white">
              <Tooltip
                content={`Ваша доля составит ${Math.round(selected.reward * bounty_cut)} кр.`}
              >
                <b>Награда:</b> {selected.reward} кр.
              </Tooltip>
            </Box>
            <Button
              fluid
              icon={sending ? 'times' : 'arrow-up'}
              selected={sending}
              disabled={!pad || !id_inserted}
              onClick={() => {
                act(sending ? 'stop' : 'send', { global: true });
                setSelectedIndex(-1);
              }}
            >
              Отправить и получить
            </Button>
          </Section>
        ) : (
          <NoticeBox>Выберите баунти из списка.</NoticeBox>
        )}
      </Stack.Item>
    </Stack>
  );
};
