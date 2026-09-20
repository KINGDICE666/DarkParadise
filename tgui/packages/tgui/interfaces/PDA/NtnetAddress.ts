export type NtnetSite = {
  id: string;
  domain: string;
  title: string;
  pages: { slug: string; title: string }[];
};

export type NtnetLocation =
  | { kind: 'home' }
  | { kind: 'catalog' }
  | { kind: 'create' }
  | { kind: 'search'; query: string }
  | { kind: 'site'; siteId: string; slug: string }
  | { kind: 'missing'; address: string };

export const NTNET_HOME: NtnetLocation = { kind: 'home' };

const SEARCH_PREFIX = 'search?q=';
const SHARED_ZONE = 'ss13';
const DOMAIN =
  /^([a-z0-9\u0400-\u04ff-]{3,24}\.([a-z0-9]{2,24}))(?:\/([a-z0-9-]{0,64}))?$/i;

const decodeQuery = (value: string) => {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
};

export const findSite = (sites: NtnetSite[], siteId: string) =>
  sites.find((entry) => entry.id === siteId);

export const parseAddress = (
  raw: string,
  sites: NtnetSite[],
): NtnetLocation | null => {
  const value = raw.trim().replace(/^(?:ntnet|https?):\/\//i, '');
  const lower = value.toLowerCase();
  if (!value || lower === 'home') {
    return NTNET_HOME;
  }
  if (lower === 'sites') {
    return { kind: 'catalog' };
  }
  if (lower === 'create') {
    return { kind: 'create' };
  }
  if (lower.startsWith(SEARCH_PREFIX)) {
    const query = decodeQuery(value.slice(SEARCH_PREFIX.length)).trim();
    return query.length >= 2 ? { kind: 'search', query } : null;
  }
  const parts = value.match(DOMAIN);
  const zone = parts?.[2].toLowerCase();
  const known =
    zone === SHARED_ZONE ||
    sites.some((entry) => entry.domain.toLowerCase().endsWith(`.${zone}`));
  if (!parts || !known) {
    return value.length >= 2 ? { kind: 'search', query: value } : null;
  }
  const domain = parts[1].toLowerCase();
  const site = sites.find((entry) => entry.domain.toLowerCase() === domain);
  if (!site) {
    return { kind: 'missing', address: value };
  }
  const slug = parts[3];
  if (slug && !site.pages.some((entry) => entry.slug === slug)) {
    return { kind: 'missing', address: value };
  }
  return { kind: 'site', siteId: site.id, slug: slug || site.pages[0].slug };
};

export const formatAddress = (
  location: NtnetLocation,
  sites: NtnetSite[],
): string => {
  switch (location.kind) {
    case 'catalog':
      return 'ntnet://sites';
    case 'create':
      return 'ntnet://create';
    case 'search':
      return `ntnet://search?q=${location.query}`;
    case 'missing':
      return location.address;
    case 'site': {
      const site = findSite(sites, location.siteId);
      if (!site) {
        return 'ntnet://home';
      }
      return location.slug === site.pages[0].slug
        ? site.domain
        : `${site.domain}/${location.slug}`;
    }
    default:
      return 'ntnet://home';
  }
};

export const formatTitle = (
  location: NtnetLocation,
  sites: NtnetSite[],
): string => {
  switch (location.kind) {
    case 'catalog':
      return 'Сайты NTnet';
    case 'create':
      return 'Создать сайт';
    case 'search':
      return `${location.query} — поиск`;
    case 'missing':
      return location.address;
    case 'site': {
      const site = findSite(sites, location.siteId);
      if (!site) {
        return 'Новая вкладка';
      }
      const page = site.pages.find((entry) => entry.slug === location.slug);
      return page ? page.title : site.title;
    }
    default:
      return 'Новая вкладка';
  }
};
