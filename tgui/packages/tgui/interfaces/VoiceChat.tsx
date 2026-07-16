import { useBackend } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Icon,
  NoticeBox,
  ProgressBar,
  Section,
  Slider,
  Stack,
} from '../components';
import { Window } from '../layouts';

type VoiceDevice = {
  id: string;
  name: string;
  default: boolean;
};

type NearbyPlayer = {
  id: string;
  name: string;
  distance: number;
  volume: number;
  muted: boolean;
  speaking: boolean;
  connected: boolean;
};

type VoiceChatData = {
  enabled: boolean;
  status: string;
  error: string;
  connected: boolean;
  wants_connection: boolean;
  muted: boolean;
  deafened: boolean;
  ptt_pressed: boolean;
  ptt_keys: string[];
  input_gain: number;
  output_volume: number;
  input_level: number;
  input_device_id: string;
  output_device_id: string;
  input_devices: VoiceDevice[];
  output_devices: VoiceDevice[];
  can_speak: boolean;
  speaking: boolean;
  nearby_players: NearbyPlayer[];
};

const statusAppearance = (status: string) => {
  switch (status) {
    case 'connected':
      return { color: 'good', icon: 'circle-check', text: 'Подключён' };
    case 'connecting':
      return { color: 'average', icon: 'spinner', text: 'Подключение' };
    case 'relay_unavailable':
      return { color: 'bad', icon: 'triangle-exclamation', text: 'Реле недоступно' };
    case 'error':
      return { color: 'bad', icon: 'circle-xmark', text: 'Ошибка' };
    case 'disabled':
      return { color: 'label', icon: 'power-off', text: 'Отключён сервером' };
    default:
      return { color: 'label', icon: 'circle', text: 'Не подключён' };
  }
};

const deviceOptions = (devices: VoiceDevice[]) =>
  devices.map((device) => ({
    displayText: `${device.name}${device.default ? ' · по умолчанию' : ''}`,
    value: device.id,
  }));

export const VoiceChat = (_properties: unknown) => {
  const { act, data } = useBackend<VoiceChatData>();
  const status = statusAppearance(data.status);
  const pttLabel = data.ptt_keys.length
    ? data.ptt_keys.join(' + ')
    : 'не назначена';

  return (
    <Window width={560} height={670} theme="ntos">
      <Window.Content scrollable>
        <Section
          title={
            <Stack align="center">
              <Stack.Item>
                <Icon
                  name={status.icon}
                  spin={data.status === 'connecting'}
                  color={status.color}
                />
              </Stack.Item>
              <Stack.Item color={status.color}>{status.text}</Stack.Item>
            </Stack>
          }
          buttons={
            data.connected || data.wants_connection ? (
              <Button
                icon="plug-circle-xmark"
                color="bad"
                onClick={() => act('disconnect')}
              >
                Отключиться
              </Button>
            ) : (
              <Button
                icon="plug"
                color="good"
                disabled={!data.enabled}
                onClick={() => act('connect')}
              >
                Подключиться
              </Button>
            )
          }
        >
          {data.error && <NoticeBox danger>{data.error}</NoticeBox>}
          {!data.enabled ? (
            <NoticeBox>Голосовой чат отключён в конфигурации сервера.</NoticeBox>
          ) : (
            <Box color="label">
              Звук обрабатывает локальный Paradise Voice Helper. После нажатия
              «Подключиться» игра запустит его автоматически.
            </Box>
          )}
        </Section>

        <Section title="Быстрые действия">
          <Stack>
            <Stack.Item grow>
              <Button
                fluid
                textAlign="center"
                py={1.2}
                icon={data.muted ? 'microphone-slash' : 'microphone'}
                color={data.muted ? 'bad' : 'good'}
                selected={data.muted}
                onClick={() => act('toggle_mute')}
              >
                {data.muted ? 'Микрофон выключен' : 'Микрофон включён'}
              </Button>
            </Stack.Item>
            <Stack.Item grow>
              <Button
                fluid
                textAlign="center"
                py={1.2}
                icon={data.deafened ? 'volume-mute' : 'headphones'}
                color={data.deafened ? 'bad' : 'good'}
                selected={data.deafened}
                onClick={() => act('toggle_deafen')}
              >
                {data.deafened ? 'Звук выключен' : 'Звук включён'}
              </Button>
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="Push-to-talk">
          <Stack align="center">
            <Stack.Item>
              <Box
                width="64px"
                height="64px"
                lineHeight="64px"
                textAlign="center"
                backgroundColor={data.speaking ? 'good' : 'rgba(0, 0, 0, 0.25)'}
                color={data.speaking ? 'white' : 'label'}
                style={{ borderRadius: '50%' }}
              >
                <Icon
                  name={data.speaking ? 'wave-square' : 'microphone'}
                  size={2}
                />
              </Box>
            </Stack.Item>
            <Stack.Item grow>
              <Box fontSize="1.2rem" bold>
                {data.speaking
                  ? 'Вас слышно'
                  : data.ptt_pressed
                    ? 'Клавиша нажата'
                    : 'Ожидание'}
              </Box>
              <Box color="label" mt={0.5}>
                Удерживайте <Box as="span" bold color="white">{pttLabel}</Box>,
                чтобы говорить. Клавиша меняется в настройках управления.
              </Box>
              {!data.can_speak && (
                <Box color="bad" mt={0.5}>
                  <Icon name="ban" /> Персонаж сейчас не может говорить.
                </Box>
              )}
            </Stack.Item>
          </Stack>
        </Section>

        <Section title="Устройства и уровни">
          <Box color="label" mb={0.5}>
            <Icon name="microphone" /> Микрофон
          </Box>
          <Dropdown
            fluid
            search
            disabled={!data.input_devices.length}
            options={deviceOptions(data.input_devices)}
            selected={data.input_device_id}
            placeholder="Helper ещё не передал список микрофонов"
            onSelected={(id) => act('input_device', { id })}
          />
          <Stack align="center" mt={1}>
            <Stack.Item width="94px" color="label">
              Усиление
            </Stack.Item>
            <Stack.Item grow>
              <Slider
                minValue={0}
                maxValue={150}
                value={data.input_gain}
                unit="%"
                onChange={(_event, value) => act('input_gain', { value })}
              />
            </Stack.Item>
          </Stack>
          <ProgressBar
            mt={0.5}
            value={data.input_level}
            minValue={0}
            maxValue={100}
            color={data.input_level > 85 ? 'bad' : 'good'}
          >
            Уровень микрофона
          </ProgressBar>

          <Box color="label" mt={1.5} mb={0.5}>
            <Icon name="headphones" /> Устройство вывода
          </Box>
          <Dropdown
            fluid
            search
            disabled={!data.output_devices.length}
            options={deviceOptions(data.output_devices)}
            selected={data.output_device_id}
            placeholder="Helper ещё не передал список устройств"
            onSelected={(id) => act('output_device', { id })}
          />
          <Stack align="center" mt={1}>
            <Stack.Item width="94px" color="label">
              Громкость
            </Stack.Item>
            <Stack.Item grow>
              <Slider
                minValue={0}
                maxValue={100}
                value={data.output_volume}
                unit="%"
                onChange={(_event, value) => act('output_volume', { value })}
              />
            </Stack.Item>
          </Stack>
        </Section>

        <Section
          title="Игроки рядом"
          buttons={
            <Box color="label">
              <Icon name="location-dot" /> {data.nearby_players.length}
            </Box>
          }
        >
          {!data.nearby_players.length && (
            <Box color="label" textAlign="center" py={1}>
              Рядом пока никого нет
            </Box>
          )}
          {data.nearby_players.map((player, index) => (
            <Box
              key={player.id}
              pt={index > 0 ? 1 : 0}
              mt={index > 0 ? 1 : 0}
              style={index > 0 ? { borderTop: '1px solid #31465a' } : undefined}
            >
              <Stack align="center">
                <Stack.Item width="28px" textAlign="center">
                  <Icon
                    name={player.speaking ? 'wave-square' : 'user'}
                    color={player.speaking ? 'good' : player.connected ? 'white' : 'label'}
                  />
                </Stack.Item>
                <Stack.Item grow>
                  <Box bold>{player.name}</Box>
                  <Box color="label">Расстояние: {player.distance} кл.</Box>
                </Stack.Item>
                <Stack.Item width="175px">
                  <Slider
                    minValue={0}
                    maxValue={100}
                    value={player.volume}
                    unit="%"
                    disabled={player.muted}
                    onChange={(_event, value) =>
                      act('peer_volume', { id: player.id, value })
                    }
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon={player.muted ? 'volume-mute' : 'volume-high'}
                    color={player.muted ? 'bad' : 'transparent'}
                    tooltip={player.muted ? 'Включить игрока' : 'Заглушить игрока'}
                    onClick={() => act('toggle_peer_mute', { id: player.id })}
                  />
                </Stack.Item>
              </Stack>
            </Box>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
