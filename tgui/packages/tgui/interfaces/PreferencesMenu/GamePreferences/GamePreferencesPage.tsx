import { type ReactNode, useState } from 'react';
import { Box, Button, Flex, Tooltip } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { FeatureValueInput, features } from '../features';
import type { LegacyToggle, PreferencesMenuData } from '../types';
import { useServerPrefs } from '../useServerPrefs';
import { TabbedMenu } from './TabbedMenu';

type Entry = {
  name: string;
  node: ReactNode;
};

function Row(props: {
  name: string;
  description?: string;
  children: ReactNode;
}) {
  let label: ReactNode = (
    <Flex.Item grow={1} pr={2} basis={0} ml={2}>
      {props.description ? (
        <Box
          as="span"
          style={{ borderBottom: '2px dotted rgba(255, 255, 255, 0.8)' }}
        >
          {props.name}
        </Box>
      ) : (
        props.name
      )}
    </Flex.Item>
  );

  if (props.description) {
    label = (
      <Tooltip content={props.description} position="bottom-start">
        {label}
      </Tooltip>
    );
  }

  return (
    <Flex align="center" pb={2}>
      {label}
      <Flex.Item grow={1} basis={0}>
        {props.children}
      </Flex.Item>
    </Flex>
  );
}

function ToggleRow(props: { toggle: LegacyToggle }) {
  const { act } = useBackend<PreferencesMenuData>();
  const { toggle } = props;

  return (
    <Row name={toggle.name} description={toggle.description}>
      {toggle.special ? (
        <Button onClick={() => act('toggle_legacy', { key: toggle.key })}>
          Изменить
        </Button>
      ) : (
        <Button.Checkbox
          checked={!!toggle.enabled}
          onClick={() => act('toggle_legacy', { key: toggle.key })}
        >
          {toggle.enabled ? 'Включено' : 'Выключено'}
        </Button.Checkbox>
      )}
    </Row>
  );
}

export function GamePreferencesPage() {
  const { data } = useBackend<PreferencesMenuData>();
  const categories = useServerPrefs()?.legacy_toggles?.categories || [];
  const [searchText, setSearchText] = useState('');

  const grouped: Record<string, Entry[]> = {};
  const push = (category: string, entry: Entry) => {
    grouped[category] = grouped[category] || [];
    grouped[category].push(entry);
  };

  for (const [featureId, value] of Object.entries(
    data.character_preferences.game_preferences || {},
  )) {
    const feature = features[featureId];
    const name = feature?.name || featureId;
    push(feature?.category || 'Прочее', {
      name,
      node: (
        <Row key={featureId} name={name} description={feature?.description}>
          <FeatureValueInput featureId={featureId} value={value} />
        </Row>
      ),
    });
  }

  for (const toggle of data.legacy_toggles || []) {
    const category =
      categories.find((entry) => entry.id === toggle.category)?.name ||
      'Прочее';
    push(category, {
      name: toggle.name,
      node: <ToggleRow key={toggle.key} toggle={toggle} />,
    });
  }

  const matches = (name: string) =>
    !searchText ||
    searchText.length < 2 ||
    name.toLowerCase().includes(searchText.toLowerCase());

  const entries: [string, ReactNode[]][] = Object.entries(grouped)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([category, list]) => [
      category,
      list
        .filter((entry) => matches(entry.name))
        .sort((a, b) => a.name.localeCompare(b.name))
        .map((entry) => entry.node),
    ]);

  return (
    <TabbedMenu
      categoryEntries={entries}
      contentProps={{ fontSize: 1.2 }}
      searchText={searchText}
      setSearchText={setSearchText}
    />
  );
}
