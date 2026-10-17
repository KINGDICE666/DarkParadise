import { Fragment, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import {
  CHARACTER_PREVIEW_HEIGHT,
  CharacterPreview,
} from '../../components/CharacterPreview';

import { useServerPrefs } from '../../useServerPrefs';
import type {
  LoadoutCategory,
  LoadoutItem,
  LoadoutManagerData,
  typePath,
} from './base';
import { ItemIcon, LoadoutTabDisplay, SearchDisplay } from './ItemDisplay';
import { LoadoutModifyDimmer } from './ModifyPanel';

export function LoadoutPage(props) {
  const { data } = useBackend<LoadoutManagerData>();
  const serverData = useServerPrefs();
  const loadout_tabs = serverData?.loadout.loadout_tabs || [];

  const [searchLoadout, setSearchLoadout] = useState('');
  const [selectedTabName, setSelectedTab] = useState(
    loadout_tabs?.[0].name || '',
  );
  const [modifyItemDimmer, setModifyItemDimmer] = useState<LoadoutItem | null>(
    null,
  );

  if (!serverData) {
    return <NoticeBox>Загрузка...</NoticeBox>;
  }

  return (
    <Stack fill>
      <Stack.Item width="220px">
        <Stack vertical fill>
          <Stack.Item>
            <LoadoutPreviewControls />
          </Stack.Item>
          <Stack.Item>
            <CharacterPreview
              height={CHARACTER_PREVIEW_HEIGHT}
              id={data.character_preview_view}
            />
          </Stack.Item>
          <Stack.Item grow>
            <LoadoutSelectedSection
              all_tabs={loadout_tabs}
              modifyItemDimmer={modifyItemDimmer}
              setModifyItemDimmer={setModifyItemDimmer}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Stack vertical fill>
          <Stack.Item>
            {!!modifyItemDimmer && (
              <LoadoutModifyDimmer
                modifyItemDimmer={modifyItemDimmer}
                setModifyItemDimmer={setModifyItemDimmer}
              />
            )}
            <Section
              fitted
              title="&nbsp;"
              buttons={
                <Input
                  width="200px"
                  onChange={setSearchLoadout}
                  placeholder="Поиск предмета..."
                  value={searchLoadout}
                />
              }
            >
              <Tabs fluid align="center" style={{ flexWrap: 'wrap' }}>
                {loadout_tabs.map((curTab) => (
                  <Tabs.Tab
                    key={curTab.name}
                    selected={
                      searchLoadout.length <= 1 &&
                      curTab.name === selectedTabName
                    }
                    onClick={() => {
                      setSelectedTab(curTab.name);
                      setSearchLoadout('');
                    }}
                  >
                    <Box>
                      {curTab.category_icon && (
                        <Icon name={curTab.category_icon} mr={1} />
                      )}
                      {curTab.name}
                    </Box>
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <LoadoutTabs
              loadout_tabs={loadout_tabs}
              currentTab={selectedTabName}
              currentSearch={searchLoadout}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
}

type LoadoutTabsProps = {
  loadout_tabs: LoadoutCategory[];
  currentTab: string;
  currentSearch: string;
};

function LoadoutTabs(props: LoadoutTabsProps) {
  const { loadout_tabs, currentTab, currentSearch } = props;
  const activeCategory = loadout_tabs.find((curTab) => {
    return curTab.name === currentTab;
  });
  const searching = currentSearch.length > 1;

  if (!searching && !activeCategory?.contents) {
    return (
      <Section fill>
        <Box>В этой категории ничего нет.</Box>
      </Section>
    );
  }

  return (
    <Section
      title={searching ? 'Результаты поиска' : 'Каталог'}
      fill
      scrollable
      buttons={
        activeCategory?.category_info ? (
          <Box italic mt={0.5}>
            {activeCategory.category_info}
          </Box>
        ) : null
      }
    >
      <Stack vertical>
        <Stack.Item>
          {searching ? (
            <SearchDisplay
              loadout_tabs={loadout_tabs}
              currentSearch={currentSearch}
            />
          ) : (
            <LoadoutTabDisplay category={activeCategory} />
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
}

function typepathToLoadoutItem(
  typepath: typePath,
  all_tabs: LoadoutCategory[],
) {
  for (const tab of all_tabs) {
    for (const item of tab.contents) {
      if (item.path === typepath) {
        return item;
      }
    }
  }
  return null;
}

type LoadoutSelectedItemProps = {
  path: typePath;
  all_tabs: LoadoutCategory[];
  modifyItemDimmer: LoadoutItem | null;
  setModifyItemDimmer: (dimmer: LoadoutItem | null) => void;
};

function LoadoutSelectedItem(props: LoadoutSelectedItemProps) {
  const { all_tabs, path, modifyItemDimmer, setModifyItemDimmer } = props;
  const { act } = useBackend();

  const item = typepathToLoadoutItem(path, all_tabs);
  if (!item) {
    return null;
  }

  return (
    <Stack align={'center'}>
      <Stack.Item>
        <ItemIcon item={item} scale={1} />
      </Stack.Item>
      <Stack.Item width="55%">{item.name}</Stack.Item>
      {item.buttons.length ? (
        <Stack.Item>
          <Button
            color="none"
            width="32px"
            onClick={() => {
              setModifyItemDimmer(item);
            }}
          >
            <Icon size={1.8} name="cogs" color="grey" />
          </Button>
        </Stack.Item>
      ) : (
        <Stack.Item width="32px" />
      )}
      <Stack.Item>
        <Button
          color="none"
          width="32px"
          onClick={() => act('select_item', { path: path, deselect: true })}
        >
          <Icon size={2.4} name="times" color="red" />
        </Button>
      </Stack.Item>
    </Stack>
  );
}

type LoadoutSelectedSectionProps = {
  all_tabs: LoadoutCategory[];
  modifyItemDimmer: LoadoutItem | null;
  setModifyItemDimmer: (dimmer: LoadoutItem | null) => void;
};

function LoadoutSelectedSection(props: LoadoutSelectedSectionProps) {
  const { act, data } = useBackend<LoadoutManagerData>();
  const { loadout_list } = data.character_preferences.misc;
  const { all_tabs, modifyItemDimmer, setModifyItemDimmer } = props;

  return (
    <Section
      title={`Выбрано (${data.loadout_points}/${data.max_loadout_points})`}
      scrollable
      fill
      buttons={
        <Button.Confirm
          icon="times"
          color="red"
          align="center"
          disabled={!loadout_list || Object.keys(loadout_list).length === 0}
          tooltip="Убирает все выбранные предметы из всех категорий."
          onClick={() => act('clear_all_items')}
        />
      }
    >
      {loadout_list &&
        Object.entries(loadout_list).map(([path, item]) => (
          <Fragment key={path}>
            <LoadoutSelectedItem
              path={path}
              all_tabs={all_tabs}
              modifyItemDimmer={modifyItemDimmer}
              setModifyItemDimmer={setModifyItemDimmer}
            />
            <Divider />
          </Fragment>
        ))}
    </Section>
  );
}

function LoadoutPreviewControls() {
  const { act, data } = useBackend<LoadoutManagerData>();

  return (
    <Stack>
      <Stack.Item>
        <Button
          fontSize="22px"
          icon="undo"
          tooltip="Повернуть влево"
          tooltipPosition="top"
          onClick={() => act('rotate_dummy', { dir: 'left' })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          fontSize="22px"
          icon="redo"
          tooltip="Повернуть вправо"
          tooltipPosition="top"
          onClick={() => act('rotate_dummy', { dir: 'right' })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          fontSize="22px"
          icon="shirt"
          selected={data.job_clothes}
          tooltip="Униформа"
          tooltipPosition="top"
          onClick={() => act('toggle_job_clothes')}
        />
      </Stack.Item>
    </Stack>
  );
}
