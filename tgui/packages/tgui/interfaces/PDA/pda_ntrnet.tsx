import { useState } from 'react';
import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { NtrnetDocument } from './NtrnetDocument';

type Site = {
  id: string;
  domain: string;
  title: string;
  pages: { slug: string; title: string }[];
};

type Data = {
  ntrnet: {
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

export const pda_ntrnet = () => {
  const { act, data } = useBackend<Data>();
  const { available, loading, catalog, site, page, slug, search, login } =
    data.ntrnet;
  const [query, setQuery] = useState(search.query || '');
  const [showCatalog, setShowCatalog] = useState(false);

  const navigate = (siteId: string, pageSlug: string) =>
    act('ntrnet_open', { site_id: siteId, slug: pageSlug });
  const submitSearch = () => {
    const trimmedQuery = query.trim();
    if (trimmedQuery.length < 2 || search.pending) {
      return;
    }
    setShowCatalog(false);
    act('ntrnet_search', { query: trimmedQuery });
  };
  const openHome = () => {
    setShowCatalog(false);
    act('Back');
  };

  if (site) {
    return (
      <Stack vertical>
        <Stack.Item>
          <Section>
            <Stack align="center">
              <Stack.Item>
                <Button icon="arrow-left" onClick={openHome} />
              </Stack.Item>
              <Stack.Item>
                <Button icon="home" onClick={openHome} />
              </Stack.Item>
              <Stack.Item grow>
                <Box
                  backgroundColor="rgba(0, 0, 0, 0.25)"
                  p={0.75}
                  color="label"
                >
                  {site.domain}
                </Box>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="sync"
                  disabled={loading}
                  onClick={() => act('ntrnet_refresh')}
                />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        {!available && !loading && (
          <Stack.Item>
            <NoticeBox>
              НТрнет недоступен. Сохранённые страницы доступны из кэша.
            </NoticeBox>
          </Stack.Item>
        )}
        <Stack.Item>
          <Section title={site.title}>
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
              <NtrnetDocument tree={page.tree} onNavigate={navigate} />
            ) : loading ? (
              <NoticeBox>Загрузка страницы…</NoticeBox>
            ) : (
              <NoticeBox>
                Страница не загрузилась. Нажмите кнопку обновления сверху.
              </NoticeBox>
            )}
          </Section>
        </Stack.Item>
      </Stack>
    );
  }

  const visibleSites = showCatalog ? catalog : search.results;
  const resultsTitle = showCatalog
    ? 'Список сайтов'
    : `Результаты поиска: ${search.query}`;

  return (
    <Stack vertical>
      <Stack.Item>
        <Section>
          <Box textAlign="center" mt={2} mb={2}>
            <Box bold fontSize="48px" lineHeight={1} mb={2}>
              НТрнет
            </Box>
            <Stack justify="center">
              <Stack.Item grow basis="360px">
                <Input
                  fluid
                  value={query}
                  maxLength={80}
                  placeholder="Найти сайт"
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
            <Box mt={1}>
              <Button
                color="transparent"
                icon="list"
                onClick={() => setShowCatalog(true)}
              >
                Список сайтов
              </Button>
              <Button
                color="transparent"
                icon="plus"
                disabled={login.pending || login.retry_seconds > 0}
                onClick={() => act('ntrnet_login')}
              >
                Создать сайт
              </Button>
            </Box>
          </Box>
        </Section>
      </Stack.Item>

      {!available && !loading && (
        <Stack.Item>
          <NoticeBox>НТрнет сейчас недоступен.</NoticeBox>
        </Stack.Item>
      )}
      {(loading || search.pending) && (
        <Stack.Item>
          <NoticeBox>Загрузка…</NoticeBox>
        </Stack.Item>
      )}
      {!!search.error && (
        <Stack.Item>
          <NoticeBox danger>{search.error}</NoticeBox>
        </Stack.Item>
      )}
      {login.retry_seconds > 0 && !login.pending && (
        <Stack.Item>
          <Box color="label">
            Новый код можно получить через {login.retry_seconds} с.
          </Box>
        </Stack.Item>
      )}
      {!!login.code && (
        <Stack.Item>
          <NoticeBox>
            Ваш код: <b>{login.code}</b>. Введите его в редакторе в течение 15
            минут. Ссылка отправлена Вам в чат.
          </NoticeBox>
        </Stack.Item>
      )}
      {!!login.error && (
        <Stack.Item>
          <NoticeBox danger>{login.error}</NoticeBox>
        </Stack.Item>
      )}

      {(showCatalog || !!search.query) && !search.pending && (
        <Stack.Item>
          <Section
            title={resultsTitle}
            buttons={
              <Button
                icon="sync"
                disabled={loading}
                onClick={() => act('ntrnet_refresh')}
              >
                Обновить
              </Button>
            }
          >
            {visibleSites.map((entry) => (
              <Box key={entry.id} mb={1}>
                <Button
                  fluid
                  icon="globe"
                  onClick={() => navigate(entry.id, entry.pages[0].slug)}
                >
                  {entry.title}
                </Button>
                <Box color="label">{entry.domain}</Box>
              </Box>
            ))}
            {!visibleSites.length && !loading && (
              <Box color="label">
                {showCatalog
                  ? 'В списке пока нет сайтов.'
                  : 'По этому запросу ничего не найдено.'}
              </Box>
            )}
          </Section>
        </Stack.Item>
      )}
    </Stack>
  );
};
