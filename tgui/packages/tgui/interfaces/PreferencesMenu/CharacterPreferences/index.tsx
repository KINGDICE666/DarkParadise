import { useEffect, useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Floating, Icon, Stack } from 'tgui-core/components';
import { exhaustiveCheck } from 'tgui-core/exhaustive';
import { classes } from 'tgui-core/react';

import { PageButton } from '../components/PageButton';
import type { PreferencesMenuData } from '../types';
import { AntagsPage } from './AntagsPage';
import { JobsPage } from './JobsPage';
import { LoadoutPage } from './loadout';
import { MainPage } from './MainPage';
import { QuirkPersonalityPage } from './QuirksPage';
import { SpeciesPage } from './SpeciesPage';

const CHARACTER_PREVIEW_WIDTH = 220;
const PROFILES_MENU_OFFSET = 2;
const PROFILES_MENU_BOTTOM_MARGIN = 8;
const PROFILES_MENU_ANIMATION_MS = 250;

enum Page {
  Antags,
  Main,
  Jobs,
  Species,
  Quirks,
  Loadout,
}

const STARTING_PAGES: Record<string, Page> = {
  jobs: Page.Jobs,
};

type ProfileProps = {
  activeSlot: number;
  onClick: (index: number) => void;
  profiles: (string | null)[];
};

function CharacterProfiles(props: ProfileProps) {
  const { activeSlot, onClick, profiles } = props;
  const [open, setOpen] = useState(false);
  const [menuHeight, setMenuHeight] = useState(0);
  const rootRef = useRef<HTMLDivElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const profileName = (slot: number) =>
    `${slot + 1}. ${profiles[slot] ?? 'Новый персонаж'}`;

  const handleOpenChange = (isOpen: boolean) => {
    if (isOpen && rootRef.current) {
      const controlBottom = rootRef.current.getBoundingClientRect().bottom;
      setMenuHeight(
        window.innerHeight -
          controlBottom -
          PROFILES_MENU_OFFSET -
          PROFILES_MENU_BOTTOM_MARGIN,
      );
    }
    setOpen(isOpen);
  };

  return (
    <Stack>
      <Stack.Item width={`${CHARACTER_PREVIEW_WIDTH}px`} />
      <Stack.Item grow>
        <div className="Dropdown" ref={rootRef}>
          <Floating
            closeAfterInteract
            contentAutoWidth
            animationDuration={PROFILES_MENU_ANIMATION_MS}
            contentClasses="Dropdown__menu--wrapper PreferencesMenu__profiles"
            contentStyles={{
              transitionDuration: `${PROFILES_MENU_ANIMATION_MS}ms`,
            }}
            contentOffset={PROFILES_MENU_OFFSET}
            onOpenChange={handleOpenChange}
            onMounted={() =>
              menuRef.current
                ?.querySelector('.selected')
                ?.scrollIntoView({ block: 'nearest' })
            }
            content={
              <div
                className="Dropdown__menu"
                ref={menuRef}
                style={{ maxHeight: `${menuHeight}px` }}
              >
                {profiles.map((_, slot) => (
                  <div
                    key={slot}
                    className={classes([
                      'Dropdown__menu--entry',
                      slot === activeSlot && 'selected',
                    ])}
                    onClick={() => onClick(slot)}
                  >
                    {profileName(slot)}
                  </div>
                ))}
              </div>
            }
          >
            <div className="Dropdown__control Button--color--default">
              <span className="Dropdown__selected-text">
                {profileName(activeSlot)}
              </span>
              <Icon
                className={classes([
                  'Dropdown__icon',
                  'Dropdown__icon--arrow',
                  open && 'open',
                ])}
                name="chevron-down"
              />
            </div>
          </Floating>
        </div>
      </Stack.Item>
    </Stack>
  );
}

export function CharacterPreferenceWindow(props) {
  const { act, data } = useBackend<PreferencesMenuData>();

  const [currentPage, setCurrentPage] = useState(
    STARTING_PAGES[data.starting_page ?? ''] ?? Page.Main,
  );

  useEffect(() => {
    const startingPage = STARTING_PAGES[data.starting_page ?? ''];
    if (startingPage !== undefined) {
      setCurrentPage(startingPage);
    }
  }, [data.page_request]);

  let pageContents;

  switch (currentPage) {
    case Page.Antags:
      pageContents = <AntagsPage />;
      break;
    case Page.Jobs:
      pageContents = <JobsPage />;
      break;
    case Page.Main:
      pageContents = (
        <MainPage openSpecies={() => setCurrentPage(Page.Species)} />
      );

      break;
    case Page.Species:
      pageContents = (
        <SpeciesPage closeSpecies={() => setCurrentPage(Page.Main)} />
      );

      break;
    case Page.Quirks:
      pageContents = <QuirkPersonalityPage />;
      break;

    case Page.Loadout:
      pageContents = <LoadoutPage />;
      break;

    default:
      exhaustiveCheck(currentPage);
  }

  return (
    <Stack vertical fill>
      <Stack.Item>
        <CharacterProfiles
          activeSlot={data.active_slot - 1}
          onClick={(slot) => {
            act('change_slot', {
              slot: slot + 1,
            });
          }}
          profiles={data.character_profiles}
        />
      </Stack.Item>
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
              page={Page.Quirks}
              setPage={setCurrentPage}
            >
              Особенности
            </PageButton>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Divider />
      <Stack.Item grow position="relative" overflowX="hidden" overflowY="auto">
        {pageContents}
      </Stack.Item>
    </Stack>
  );
}
