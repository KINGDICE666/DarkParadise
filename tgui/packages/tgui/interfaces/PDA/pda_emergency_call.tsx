import { useEffect, useState } from 'react';
import {
  Box,
  Button,
  NoticeBox,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';
import { useBackend } from '../../backend';

type Service = {
  id: string;
  name: string;
  icon: string;
};

type EmergencyCallData = {
  services: Service[];
  reason_length: number;
  pending: string | null;
  pending_left: number;
  cooldown: string | null;
};

export const pda_emergency_call = (_props: unknown) => {
  const { act, data } = useBackend<EmergencyCallData>();
  const { services, reason_length, pending, pending_left, cooldown } = data;
  const [selected, setSelected] = useState<string | null>(null);
  const [reason, setReason] = useState('');

  const onCooldown = !!cooldown;

  useEffect(() => {
    if (onCooldown) {
      setSelected(null);
      setReason('');
    }
  }, [onCooldown]);

  if (pending) {
    return (
      <Section title="Вызов отправляется">
        <Box textAlign="center" fontSize="1.4em" bold mb={1}>
          {pending}
        </Box>
        <Box textAlign="center" fontSize="2.5em" color="average" mb={2}>
          {pending_left}
        </Box>
        <Box textAlign="center" color="label" mb={2}>
          Через {pending_left} с в канал отдела уйдёт ваше местоположение
          {reason ? ' и причина вызова' : ''}.
        </Box>
        <Button
          fluid
          icon="times"
          color="bad"
          textAlign="center"
          fontSize="1.2em"
          onClick={() => act('cancel')}
        >
          Отменить вызов
        </Button>
      </Section>
    );
  }

  return (
    <Box>
      {!!cooldown && (
        <NoticeBox>Новый вызов будет доступен через {cooldown}.</NoticeBox>
      )}
      <Section title="Кого вызвать">
        <Stack vertical>
          {services.map((service) => (
            <Stack.Item key={service.id}>
              <Button
                fluid
                icon={service.icon}
                fontSize="1.2em"
                selected={selected === service.id}
                disabled={!!cooldown}
                onClick={() => setSelected(service.id)}
              >
                {service.name}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      </Section>
      <Section title="Причина (необязательно)">
        <TextArea
          fluid
          height="80px"
          maxLength={reason_length}
          placeholder="Например: человек без сознания у бара"
          value={reason}
          onChange={setReason}
        />
        <Box color="label" textAlign="right" mt={0.5}>
          {reason.length}/{reason_length}
        </Box>
      </Section>
      <Button
        fluid
        icon="phone-volume"
        color="red"
        textAlign="center"
        fontSize="1.2em"
        disabled={!selected || !!cooldown}
        onClick={() => act('call', { service: selected, reason })}
      >
        Вызвать
      </Button>
    </Box>
  );
};
