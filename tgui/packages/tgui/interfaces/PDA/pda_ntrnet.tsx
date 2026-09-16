import { useBackend } from '../../backend';
import { Box, Button, NoticeBox, Section, Stack } from '../../components';
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
  };
};

export const pda_ntrnet = () => {
  const { act, data } = useBackend<Data>();
  const { available, loading, catalog, site, page, slug } = data.ntrnet;
  const navigate = (siteId: string, pageSlug: string) =>
    act('ntrnet_open', { site_id: siteId, slug: pageSlug });
  return (
    <Stack vertical>
      <Stack.Item>
        <Section
          title="НТрнет"
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
          Межсерверная сеть сайтов
        </Section>
      </Stack.Item>
      {!available && !loading && (
        <Stack.Item>
          <NoticeBox>
            НТрнет недоступен. Сохранённые страницы доступны из кэша.
          </NoticeBox>
        </Stack.Item>
      )}
      {loading && (
        <Stack.Item>
          <NoticeBox>Загрузка…</NoticeBox>
        </Stack.Item>
      )}
      <Stack.Item>
        {site ? (
          <Section title={site.title}>
            <Box color="label" mb={1}>
              {site.domain}
            </Box>
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
            ) : (
              !loading && (
                <NoticeBox>
                  Страница не загружена. Нажмите «Обновить», чтобы повторить
                  запрос.
                </NoticeBox>
              )
            )}
          </Section>
        ) : (
          <Section title="Каталог сайтов">
            {catalog.map((entry) => (
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
            {!catalog.length && !loading && (
              <Box color="label">В каталоге пока нет сайтов.</Box>
            )}
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};
