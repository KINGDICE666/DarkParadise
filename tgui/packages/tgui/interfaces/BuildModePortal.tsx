import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  NoticeBox,
  RestrictedInput,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type PortalData = {
  presets: string[];
  sprite: string;
  spriteState: string;
  spritePreview?: string;
  spriteStates: string[];
  editing: boolean;
  missing: boolean;
  location: string | null;
  clipboard: boolean;
  instability: boolean;
  effects: boolean;
  duration: number;
  maxDuration: number;
  limit: number;
  maxEntries: number;
  used: number | null;
  allowCharacters: boolean;
  allowAnimals: boolean;
  allowMechs: boolean;
  allowItems: boolean;
  countCargo: boolean;
  bringDragged: boolean;
};

const allowedTypes = [
  ['Characters', 'allowCharacters', 'allow_characters'],
  ['Animals', 'allowAnimals', 'allow_animals'],
  ['Mechs', 'allowMechs', 'allow_mechs'],
  ['Loose items', 'allowItems', 'allow_items'],
] as const;

export function BuildModePortal() {
  const { act, data } = useBackend<PortalData>();
  const presets = Array.isArray(data.presets) ? data.presets : [];
  const spriteState = data.spriteState ?? '';
  const spriteStates = Array.isArray(data.spriteStates)
    ? data.spriteStates
    : [spriteState];

  return (
    <Window width={610} height={510}>
      <Window.Content scrollable>
        {data.missing ? (
          <NoticeBox>
            This portal has closed.{' '}
            <Button onClick={() => act('defaults')}>
              Open placement settings
            </Button>
          </NoticeBox>
        ) : (
          <>
            <Section title={data.editing ? data.location : 'New portals'}>
              <Box mb={1} style={{ display: 'flex', flexWrap: 'wrap' }}>
                {data.editing && (
                  <Button onClick={() => act('defaults')}>
                    Placement settings
                  </Button>
                )}
                <Button icon="copy" onClick={() => act('copy')}>
                  Copy
                </Button>
                <Button
                  icon="paste"
                  disabled={!data.clipboard}
                  onClick={() => act('paste')}
                >
                  Paste
                </Button>
                {data.editing && (
                  <Button.Confirm
                    color="bad"
                    icon="times"
                    onClick={() => act('close')}
                  >
                    Close pair
                  </Button.Confirm>
                )}
              </Box>
              <Stack align="center">
                <Stack.Item shrink={0}>
                  <Box
                    width="96px"
                    height="96px"
                    backgroundColor="rgba(0, 0, 0, 0.25)"
                    style={{ display: 'grid', placeItems: 'center' }}
                  >
                    {data.spritePreview ? (
                      <img
                        alt="Portal sprite preview"
                        src={`data:image/png;base64,${data.spritePreview}`}
                        style={{
                          width: '80px',
                          height: '80px',
                          objectFit: 'contain',
                          imageRendering: 'pixelated',
                        }}
                      />
                    ) : (
                      <Box color="label">No preview</Box>
                    )}
                  </Box>
                </Stack.Item>
                <Stack.Item grow>
                  <LabeledList>
                    <LabeledList.Item label="Sprite">
                      <Dropdown
                        options={presets}
                        selected={data.sprite}
                        onSelected={(value) => act('preset', { value })}
                      />
                      <Button icon="folder-open" onClick={() => act('upload')}>
                        Browse DMI…
                      </Button>
                    </LabeledList.Item>
                    <LabeledList.Item label="Icon state">
                      <Dropdown
                        options={spriteStates.map((value) => ({
                          displayText: value || '(default)',
                          value,
                        }))}
                        selected={spriteState}
                        onSelected={(value) => act('state', { value })}
                      />
                    </LabeledList.Item>
                    <LabeledList.Item label="Transit">
                      <Button.Checkbox
                        checked={data.instability}
                        onClick={() => act('instability')}
                      >
                        Bluespace item instability
                      </Button.Checkbox>
                      <Button.Checkbox
                        checked={data.effects}
                        onClick={() => act('effects')}
                      >
                        Sparks and sound
                      </Button.Checkbox>
                    </LabeledList.Item>
                    <LabeledList.Item label="Duration">
                      <Button.Checkbox
                        checked={!data.duration}
                        onClick={() =>
                          act('duration', { value: data.duration ? 0 : 30 })
                        }
                      >
                        Infinite
                      </Button.Checkbox>
                      {!!data.duration && (
                        <RestrictedInput
                          width="7em"
                          value={data.duration}
                          minValue={1}
                          maxValue={data.maxDuration}
                          onChange={(value) => act('duration', { value })}
                        />
                      )}
                      {!!data.duration && (
                        <Box inline ml={1}>
                          seconds
                        </Box>
                      )}
                    </LabeledList.Item>
                  </LabeledList>
                </Stack.Item>
              </Stack>
            </Section>
            <Section title="Passage">
              <LabeledList>
                <LabeledList.Item label="Close after">
                  <RestrictedInput
                    width="7em"
                    value={data.limit}
                    minValue={0}
                    maxValue={data.maxEntries}
                    onChange={(value) => act('limit', { value })}
                  />
                  <Box inline ml={1}>
                    {data.limit
                      ? `${data.used ?? 0} of ${data.limit} used`
                      : 'Unlimited (0)'}
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Allow entry">
                  {allowedTypes.map(([label, field, action]) => (
                    <Button.Checkbox
                      key={action}
                      checked={data[field]}
                      onClick={() => act(action)}
                    >
                      {label}
                    </Button.Checkbox>
                  ))}
                  <Box color="label">
                    Only checked types can enter, even with an unlimited entry
                    count.
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Cargo">
                  <Button.Checkbox
                    checked={data.countCargo}
                    onClick={() => act('count_cargo')}
                  >
                    Count carried and dragged cargo
                  </Button.Checkbox>
                  <Button.Checkbox
                    checked={data.bringDragged}
                    onClick={() => act('bring_dragged')}
                  >
                    Bring dragged objects
                  </Button.Checkbox>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
}
