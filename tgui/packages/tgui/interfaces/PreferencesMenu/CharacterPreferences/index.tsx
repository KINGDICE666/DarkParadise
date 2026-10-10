import { type ReactNode, useState } from 'react';
import { Box, Dropdown, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { ModuleBackendContext } from '../../common/ModuleBackend';
import { JobPreferencesContent } from '../../JobPreferences';
import { LoadoutContent } from '../../Loadout';
import { PageButton } from '../components/PageButton';
import type { PreferencesMenuData } from '../types';
import { AntagsPage } from './AntagsPage';
import { BodyPage } from './BodyPage';
import { MainPage } from './MainPage';
import { SpeciesPage } from './SpeciesPage';

const PROFILES_VISIBLE_UNLOCKED = 3;
const PROFILES_VISIBLE_LOCKED = 4;

enum Page {
  Main,
  Species,
  Loadout,
  Jobs,
  Antags,
  Body,
}

function CharacterProfiles() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const options = (data.character_profiles || []).map((profile, index) => ({
    displayText: `${index + 1}. ${profile ?? 'Новый персонаж'}`,
    value: String(index + 1),
  }));

  return (
    <Dropdown
      width="100%"
      maxItems={
        data.content_unlocked
          ? PROFILES_VISIBLE_UNLOCKED
          : PROFILES_VISIBLE_LOCKED
      }
      selected={options[data.active_slot - 1]?.displayText}
      options={options}
      onSelected={(slot) => act('change_slot', { slot: Number(slot) })}
    />
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
    case Page.Species:
      pageContents = (
        <SpeciesPage closeSpecies={() => setCurrentPage(Page.Main)} />
      );
      break;
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
        <CharacterProfiles />
      </Stack.Item>
      {!data.content_unlocked && (
        <Stack.Item align="center">
          Купите BYOND premium, чтобы получить больше слотов!
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
              otherActivePages={[Page.Species]}
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
      <Stack.Item grow position="relative" overflowX="hidden" overflowY="auto">
        <Box
          height="100%"
          style={{ display: currentPage === Page.Main ? undefined : 'none' }}
        >
          <MainPage
            visible={props.visible && currentPage === Page.Main}
            openSpecies={() => setCurrentPage(Page.Species)}
          />
        </Box>
        {props.visible && pageContents}
      </Stack.Item>
    </Stack>
  );
}
