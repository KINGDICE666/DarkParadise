import { Button, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { FeatureValueInput, features } from '../features';
import type { PreferencesMenuData } from '../types';
import { useServerPrefs } from '../useServerPrefs';

const RECORDS = [
  'flavor_text',
  'med_record',
  'sec_record',
  'gen_record',
  'exploit_record',
  'OOC_Notes',
];

function Disabilities() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const disabilities = useServerPrefs()?.disabilities || [];
  const available = data.available_disabilities || [];

  return (
    <Section
      title="Особенности"
      fill
      scrollable
      buttons={
        <Button.Confirm
          icon="undo"
          confirmContent="Сбросить?"
          onClick={() => act('reset_disabilities')}
        >
          Сбросить
        </Button.Confirm>
      }
    >
      {disabilities
        .filter((disability) => available.includes(disability.flag))
        .map((disability) => (
          <Button.Checkbox
            key={disability.flag}
            fluid
            checked={!!(data.disabilities & disability.flag)}
            onClick={() => act('toggle_disability', { flag: disability.flag })}
          >
            {disability.name}
          </Button.Checkbox>
        ))}
    </Section>
  );
}

function BodyParts() {
  const { act, data } = useBackend<PreferencesMenuData>();

  return (
    <Section
      title="Части тела и органы"
      fill
      scrollable
      buttons={
        !!data.ipc_loadout && (
          <Button icon="robot" onClick={() => act('ipc_loadout')}>
            Модель оболочки
          </Button>
        )
      }
    >
      <LabeledList>
        {(data.limbs || []).map((limb) => (
          <LabeledList.Item key={limb.zone} label={limb.name}>
            <Button fluid onClick={() => act('edit_limb', { zone: limb.zone })}>
              {limb.status}
            </Button>
          </LabeledList.Item>
        ))}
        {(data.organs || []).length > 0 && <LabeledList.Divider />}
        {(data.organs || []).map((organ) => (
          <LabeledList.Item key={organ.zone} label={organ.name}>
            <Button
              fluid
              onClick={() => act('edit_organ', { zone: organ.zone })}
            >
              {organ.status}
            </Button>
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
}

function Records() {
  const { data } = useBackend<PreferencesMenuData>();
  const prefs = data.character_preferences.manually_rendered_features;

  return (
    <Section title="Описание и записи" fill scrollable>
      <Stack vertical>
        {RECORDS.filter((key) => prefs[key] !== undefined).map((key) => (
          <Stack.Item key={key}>
            <Section title={features[key].name}>
              <FeatureValueInput featureId={key} value={prefs[key]} />
            </Section>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

export function BodyPage() {
  return (
    <Stack fill>
      <Stack.Item basis="25%">
        <Disabilities />
      </Stack.Item>
      <Stack.Item basis="30%">
        <BodyParts />
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Records />
      </Stack.Item>
    </Stack>
  );
}
