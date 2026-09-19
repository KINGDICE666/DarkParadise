import { useState } from 'react';
import { useBackend } from '../../backend';
import { Box, Button, Input, NoticeBox, Section, Stack } from 'tgui-core/components';
import { NtnetDocument } from './NtnetDocument';

type Site = {
  id: string;
  domain: string;
  title: string;
  pages: { slug: string; title: string }[];
};

type View = 'home' | 'catalog' | 'create' | 'search';

type Data = {
  ntnet: {
    available: boolean;
    loading: boolean;
    catalog: Site[];
    site: Site | null;
    page: { tree: unknown } | null;
    slug: string | null;
    search: {
      query: string | null;
      results: Site[];
      pending: boolean;
      error: string | null;
    };
    login: {
      code: string | null;
      pending: boolean;
      retry_seconds: number;
      error: string | null;
    };
  };
};

export const pda_ntnet = () => {
  const { act, data } = useBackend<Data>();
  const { available, loading, catalog, site, page, slug, search, login } =
    data.ntnet;
  const [view, setView] = useState<View>('home');
  const [query, setQuery] = useState(search.query || '');

  const navigate = (siteId: string, pageSlug: string) =>
    act('ntnet_open', { site_id: siteId, slug: pageSlug });
  const goHome = () => {
    if (site) {
      act('Back');
    }
    setView('home');
  };
  const goBack = () => {
    if (site) {
      act('Back');
    } else {
      setView('home');
    }
  };
  const submitSearch = () => {
    const value = query.trim();
    if (value.length < 2 || search.pending) {
      return;
    }
    setView('search');
    act('ntnet_search', { query: value });
  };
  const address = site
    ? site.domain
    : view === 'catalog'
      ? 'ntnet://sites'
      : view === 'create'
        ? 'ntnet://create'
        : view === 'search'
          ? `ntnet://search?q=${search.query || query}`
          : 'ntnet://home';
  const tabTitle = site
    ? site.title
    : view === 'catalog'
      ? 'Список сайтов'
      : view === 'create'
        ? 'Создать сайт'
        : view === 'search'
          ? 'Поиск'
          : 'Новая вкладка';

  return (
    <Section>
      <Box backgroundColor="#111" p={0.5}>
        <Box
          backgroundColor="#292929"
          px={1.5}
          py={0.75}
          width="190px"
          style={{ borderRadius: '6px 6px 0 0' }}
        >
          <Box inline mr={1}>🌐</Box>
          {tabTitle}
        </Box>
        <Stack align="center" mt={0.5}>
          <Stack.Item>
            <Button icon="arrow-left" tooltip="Назад" onClick={goBack} />
          </Stack.Item>
          <Stack.Item>
            <Button icon="home" tooltip="Домой" onClick={goHome} />
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="sync"
              tooltip="Обновить"
              disabled={loading}
              onClick={() => act('ntnet_refresh')}
            />
          </Stack.Item>
          <Stack.Item grow>
            <Box
              backgroundColor="#050505"
              px={1}
              py={0.75}
              style={{ border: '1px solid #555', borderRadius: '4px' }}
            >
              🔒 {address}
            </Box>
          </Stack.Item>
        </Stack>
      </Box>

      {!available && !loading ? (
        <NoticeBox>NTnet сейчас недоступен.</NoticeBox>
      ) : null}

      <Box backgroundColor="#181818" minHeight="430px" p={2}>
        {site ? (
          <>
            <Box bold fontSize={1.5} mb={0.5}>{site.title}</Box>
            <Box color="label" mb={1}>{site.domain}</Box>
            <Box mb={1}>
              {site.pages.map((entry) => (
                <Button
                  key={entry.slug}
                  selected={entry.slug === slug}
                  onClick={() => navigate(site.id, entry.slug)}
                >
                  {entry.title}
                </Button>
              ))}
            </Box>
            {page ? (
              <NtnetDocument tree={page.tree} onNavigate={navigate} />
            ) : (
              <NoticeBox>{loading ? 'Загрузка страницы…' : 'Страница не загрузилась.'}</NoticeBox>
            )}
          </>
        ) : view === 'home' ? (
          <Box textAlign="center" mt={5}>
            <Box bold fontSize="48px" lineHeight={1} mb={2}>NTnet</Box>
            <Stack justify="center">
              <Stack.Item grow basis="360px">
                <Input
                  fluid
                  value={query}
                  maxLength={80}
                  placeholder="Поиск в NTnet"
                  onChange={setQuery}
                  onEnter={submitSearch}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="search"
                  disabled={query.trim().length < 2 || search.pending}
                  onClick={submitSearch}
                />
              </Stack.Item>
            </Stack>
            <Box mt={2}>
              <Button icon="list" onClick={() => setView('catalog')}>
                Список сайтов
              </Button>
              <Button icon="plus" onClick={() => setView('create')}>
                Создать сайт
              </Button>
            </Box>
          </Box>
        ) : view === 'catalog' ? (
          <BrowserList
            title="Список сайтов"
            sites={catalog}
            empty="В NTnet пока нет сайтов."
            navigate={navigate}
          />
        ) : view === 'create' ? (
          <>
            <Box bold fontSize={1.5} mb={1}>Создать сайт</Box>
            <Box mb={2}>
              Получите одноразовый код, затем перейдите по ссылке из чата в редактор.
            </Box>
            <Button
              icon="key"
              disabled={login.pending || login.retry_seconds > 0}
              onClick={() => act('ntnet_login')}
            >
              {login.pending ? 'Получение кода…' : 'Получить код редактора'}
            </Button>
            {login.retry_seconds > 0 && !login.pending ? (
              <Box color="label" mt={1}>
                Новый код можно получить через {login.retry_seconds} с.
              </Box>
            ) : null}
            {login.code ? (
              <NoticeBox mt={2}>
                Ваш код: <b>{login.code}</b>. Ссылка на редактор отправлена Вам в чат.
              </NoticeBox>
            ) : null}
            {login.error ? <NoticeBox danger>{login.error}</NoticeBox> : null}
          </>
        ) : (
          <>
            <BrowserList
              title={`Результаты поиска: ${search.query || query}`}
              sites={search.results}
              empty="По этому запросу ничего не найдено."
              navigate={navigate}
            />
            {search.pending ? <NoticeBox>Поиск…</NoticeBox> : null}
            {search.error ? <NoticeBox danger>{search.error}</NoticeBox> : null}
          </>
        )}
      </Box>
    </Section>
  );
};

const BrowserList = (props: {
  title: string;
  sites: Site[];
  empty: string;
  navigate: (siteId: string, slug: string) => void;
}) => (
  <>
    <Box bold fontSize={1.5} mb={1}>{props.title}</Box>
    {props.sites.map((entry) => (
      <Box key={entry.id} mb={1}>
        <Button
          fluid
          icon="globe"
          onClick={() => props.navigate(entry.id, entry.pages[0].slug)}
        >
          {entry.title}
        </Button>
        <Box color="label">{entry.domain}</Box>
      </Box>
    ))}
    {!props.sites.length ? <Box color="label">{props.empty}</Box> : null}
  </>
);
