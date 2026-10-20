import {
  Box,
  Button,
  Icon,
  LabeledList,
  Modal,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type HoloCall = {
  caller: string;
  connected: boolean;
  ref: string;
};

type HolopadData = {
  calling: boolean;
  on_cooldown: boolean;
  allowed: boolean;
  holo_calls: HoloCall[];
  disk: boolean;
  disk_record: boolean;
  replay_mode: boolean;
  loop_mode: boolean;
  record_mode: boolean;
};

export const Holopad = (props: unknown) => {
  const { act, data } = useBackend<HolopadData>();
  const { calling } = data;
  return (
    <Window width={440} height={330}>
      {!!calling && (
        <Modal fontSize="36px" fontFamily="monospace">
          <Stack align="center">
            <Stack.Item mr={2} mt={2}>
              <Icon name="phone-alt" rotation={25} />
            </Stack.Item>
            <Stack.Item mr={2}>Вызов...</Stack.Item>
          </Stack>
          <Box mt={2} textAlign="center" fontSize="24px">
            <Button
              lineHeight="40px"
              icon="times"
              color="bad"
              onClick={() => act('hang_up')}
            >
              Сбросить
            </Button>
          </Box>
        </Modal>
      )}
      <Window.Content scrollable>
        <HolopadContent />
        <HolodiskContent />
      </Window.Content>
    </Window>
  );
};

const HolopadContent = (props: unknown) => {
  const { act, data } = useBackend<HolopadData>();
  const { on_cooldown, allowed, holo_calls = [] } = data;
  return (
    <Section
      title="Голопад"
      buttons={
        <Button
          icon="bell"
          disabled={on_cooldown}
          onClick={() => act('AIrequest')}
        >
          {on_cooldown ? 'ИИ уже вызван' : 'Вызвать ИИ'}
        </Button>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Связь">
          <Button
            icon="phone-alt"
            onClick={() => act('holocall', { headcall: allowed })}
          >
            {allowed ? 'Подключиться к голопаду' : 'Позвонить на голопад'}
          </Button>
        </LabeledList.Item>
        {holo_calls.map((call) => (
          <LabeledList.Item
            label={call.connected ? 'Текущий звонок' : 'Входящий звонок'}
            key={call.ref}
          >
            <Button
              icon={call.connected ? 'phone-slash' : 'phone-alt'}
              color={call.connected ? 'bad' : 'good'}
              onClick={() =>
                act(call.connected ? 'disconnectcall' : 'connectcall', {
                  holopad: call.ref,
                })
              }
            >
              {call.connected
                ? `Завершить звонок от ${call.caller}`
                : `Ответить ${call.caller}`}
            </Button>
          </LabeledList.Item>
        ))}
        {holo_calls.some((call) => !call.connected) && (
          <LabeledList.Item>
            <Button
              icon="phone-slash"
              color="bad"
              onClick={() => act('rejectall')}
            >
              Отклонить входящие
            </Button>
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

const HolodiskContent = (props: unknown) => {
  const { act, data } = useBackend<HolopadData>();
  const { disk, disk_record, replay_mode, loop_mode, record_mode } = data;
  return (
    <Section
      title="Голодиск"
      buttons={
        <Button
          icon="eject"
          disabled={!disk || replay_mode || record_mode}
          onClick={() => act('disk_eject')}
        >
          Извлечь
        </Button>
      }
    >
      {!disk ? (
        <NoticeBox>Диск не вставлен</NoticeBox>
      ) : (
        <LabeledList>
          <LabeledList.Item label="Проигрыватель">
            <Button
              icon={replay_mode ? 'pause' : 'play'}
              selected={replay_mode}
              disabled={record_mode || !disk_record}
              onClick={() => act('replay_mode')}
            >
              {replay_mode ? 'Стоп' : 'Воспроизвести'}
            </Button>
            <Button
              icon="sync"
              selected={loop_mode}
              disabled={record_mode || !disk_record}
              onClick={() => act('loop_mode')}
            >
              {loop_mode ? 'Повтор вкл.' : 'Повтор'}
            </Button>
            <Button
              icon="exchange-alt"
              disabled={!replay_mode}
              onClick={() => act('offset')}
            >
              Сместить
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Запись">
            <Button
              icon={record_mode ? 'pause' : 'video'}
              selected={record_mode}
              disabled={(disk_record && !record_mode) || replay_mode}
              onClick={() => act('record_mode')}
            >
              {record_mode ? 'Закончить запись' : 'Записать'}
            </Button>
            <Button
              icon="trash"
              color="bad"
              disabled={!disk_record || replay_mode || record_mode}
              onClick={() => act('record_clear')}
            >
              Стереть запись
            </Button>
          </LabeledList.Item>
        </LabeledList>
      )}
    </Section>
  );
};
