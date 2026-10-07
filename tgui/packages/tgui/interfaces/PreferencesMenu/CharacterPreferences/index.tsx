import { type ReactNode, useState } from 'react';
import { Box, Button, Dropdown, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { ModuleBackendContext } from '../../common/ModuleBackend';
import { JobPreferencesContent } from '../../JobPreferences';
import { LoadoutContent } from '../../Loadout';
import { PageButton } from '../components/PageButton';
import type { PreferencesMenuData } from '../types';
import { AntagsPage } from './AntagsPage';
import { BodyPage } from './BodyPage';
import { MainPage } from './MainPage';

enum Page {
  Main,
  Loadout,
  Jobs,
  Antags,
  Body,
}

function CharacterSlots() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const profiles = data.character_profiles || [];
  const options = profiles.map((profile, index) => ({
    displayText: `${index + 1}. ${profile ?? 'Новый персонаж'}`,
    value: String(index + 1),
  }));

  return (
    <Stack align="center">
      <Stack.Item grow>
        <Dropdown
          width="100%"
          selected={options[data.active_slot - 1]?.displayText}
          options={options}
          onSelected={(slot) => act('change_slot', { slot: Number(slot) })}
        />
      </Stack.Item>
      <Stack.Item>
        <Button icon="save" onClick={() => act('save')}>
          Сохранить
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button icon="sync" onClick={() => act('reload')}>
          Отменить изменения
        </Button>
      </Stack.Item>
      <Stack.Item>
        <Button.Confirm
          icon="trash"
          color="bad"
          disabled={!data.saved}
          confirmContent="Удалить персонажа?"
          onClick={() => act('remove_current_slot')}
        >
          Удалить
        </Button.Confirm>
      </Stack.Item>
    </Stack>
  );
}

function EmbeddedModule(props: {
  action: string;
  data: unknown;
  children: ReactNode;
}) {
  const { act } = useBackend<PreferencesMenuData>();

  return (
    <ModuleBackendContext.Provider
      value={{
        data: props.data,
        act: (action, params) =>
          act(props.action, { action, params: params || {} }),
      }}
    >
      {props.children}
    </ModuleBackendContext.Provider>
  );
}

export function CharacterPreferenceWindow(props: { visible: boolean }) {
  const { data } = useBackend<PreferencesMenuData>();
  const [currentPage, setCurrentPage] = useState(Page.Main);

  let pageContents;
  switch (currentPage) {
    case Page.Loadout:
      pageContents = (
        <EmbeddedModule
          action="loadout_act"
          data={{ ...data.loadout_static, ...data.loadout_page }}
        >
          <LoadoutContent />
        </EmbeddedModule>
      );
      break;
    case Page.Jobs:
      pageContents = (
        <EmbeddedModule action="jobs_act" data={data.jobs_page}>
          <JobPreferencesContent />
        </EmbeddedModule>
      );
      break;
    case Page.Antags:
      pageContents = <AntagsPage />;
      break;
    case Page.Body:
      pageContents = <BodyPage />;
      break;
  }

  return (
    <Stack vertical fill>
      <Stack.Item>
        <CharacterSlots />
      </Stack.Item>
      {!data.content_unlocked && (
        <Stack.Item align="center">
          <Box color="label">
            Купите BYOND premium, чтобы получить больше слотов!
          </Box>
        </Stack.Item>
      )}
      <Stack.Divider />
      <Stack.Item>
        <Stack fill>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={Page.Main}
              setPage={setCurrentPage}
            >
              Персонаж
            </PageButton>
          </Stack.Item>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={Page.Loadout}
              setPage={setCurrentPage}
            >
              Снаряжение
            </PageButton>
          </Stack.Item>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={Page.Jobs}
              setPage={setCurrentPage}
            >
              Профессии
            </PageButton>
          </Stack.Item>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={Page.Antags}
              setPage={setCurrentPage}
            >
              Антагонисты
            </PageButton>
          </Stack.Item>
          <Stack.Item grow>
            <PageButton
              currentPage={currentPage}
              page={Page.Body}
              setPage={setCurrentPage}
            >
              Особенности и записи
            </PageButton>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Divider />
      <Stack.Item grow position="relative" overflowX="auto" overflowY="auto">
        <Box
          height="100%"
          style={{ display: currentPage === Page.Main ? undefined : 'none' }}
        >
          <MainPage visible={props.visible && currentPage === Page.Main} />
        </Box>
        {props.visible && pageContents}
      </Stack.Item>
    </Stack>
  );
}
