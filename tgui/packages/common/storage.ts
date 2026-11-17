/**
 * Browser-agnostic abstraction of key-value web storage.
 *
 * Settings live in a storage that is local to the client: BYOND 516
 * `serverStorage` inside DreamSeeker, or `localStorage` when the page has a
 * stable origin. The configured iframe storage is only used to move data
 * saved by older builds, or as a last resort when nothing local is available.
 *
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export type StorageDiagnostic = {
  level: 'info' | 'warn' | 'error';
  message: string;
};

type KeyValueStore = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>;

type StorageBackend = {
  get(key: string): Promise<any>;
  set(key: string, value: any): Promise<void>;
  remove(key: string): Promise<void>;
  processChatMessages(messages: any[]): Promise<void>;
  getChatMessages(): Promise<any>;
};

const KEY_PREFIX = 'paradise-';
const CHAT_MESSAGES_KEY = 'chat-messages';
const MIGRATED_KEY = 'iframe-migrated';
const MAX_MIGRATED_MESSAGES = 1000;
const BYOND_STORAGE_WAIT = 3000;
const STORAGE_CDN_TIMEOUT = 15000;

const LEGACY_KEYS = [
  'panel-settings',
  'chat-state',
  'chat-saving-enabled',
  'telemetry',
  'geometries',
  'adminverbpanel-favourites',
  'adminverbpanel-user-categories',
  'adminverbpanel-selected-category',
  'podlauncher_presetlist',
  'spawnpanel-searchText',
  'spawnpanel-searchBy',
  'spawnpanel-sortBy',
  'spawnpanel-hideMapping',
  'spawnpanel-showIcons',
  'spawnpanel-showPreview',
  'spawnpanel-selectedObj',
  'spawnpanel-offset_type',
  'spawnpanel-where_target_type',
  'spawnpanel-direction',
  'spawnpanel-atom_name',
  'spawnpanel-offset',
  'spawnpanel-atom_amount',
];

class LocalBackend implements StorageBackend {
  constructor(private readonly store: KeyValueStore) {}

  has(key: string): boolean {
    return this.read(key) !== undefined;
  }

  async get(key: string): Promise<any> {
    return this.read(key);
  }

  async set(key: string, value: any): Promise<void> {
    if (value === undefined) {
      this.store.removeItem(KEY_PREFIX + key);
      return;
    }
    try {
      this.store.setItem(KEY_PREFIX + key, JSON.stringify(value));
    } catch (error) {
      console.warn(`Failed to save '${key}':`, error);
    }
  }

  async remove(key: string): Promise<void> {
    this.store.removeItem(KEY_PREFIX + key);
  }

  async processChatMessages(messages: any[]): Promise<void> {
    return this.set(CHAT_MESSAGES_KEY, messages);
  }

  async getChatMessages(): Promise<any> {
    return this.read(CHAT_MESSAGES_KEY);
  }

  private read(key: string): any {
    const raw: unknown = this.store.getItem(KEY_PREFIX + key);
    if (raw === null || raw === undefined) {
      return undefined;
    }
    if (typeof raw !== 'string') {
      return raw;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return undefined;
    }
  }
}

class IFrameIndexedDbBackend implements StorageBackend {
  private documentElement: HTMLIFrameElement | null = null;
  private iframeWindow: Window | null = null;

  async ready(): Promise<boolean> {
    const iframe = document.createElement('iframe');
    iframe.allow = 'storage-access';
    iframe.style.display = 'none';
    iframe.src = Byond.storageCdn;

    const completePromise: Promise<boolean> = new Promise((resolve) => {
      const listener = (message: MessageEvent) => {
        if (
          message.source === iframe.contentWindow &&
          message.data === 'ready'
        ) {
          resolveReady(true);
        }
      };
      const resolveReady = (ready: boolean) => {
        clearTimeout(timeout);
        window.removeEventListener('message', listener);
        resolve(ready);
      };
      const timeout = setTimeout(
        () => resolveReady(false),
        STORAGE_CDN_TIMEOUT,
      );

      fetch(Byond.storageCdn, { method: 'HEAD' })
        .then((response) => {
          if (response.status !== 200) {
            resolveReady(false);
          }
        })
        .catch(() => {
          resolveReady(false);
        });

      window.addEventListener('message', listener);
    });

    this.documentElement = document.body.appendChild(iframe);
    if (!this.documentElement.contentWindow) {
      return false;
    }
    this.iframeWindow = this.documentElement.contentWindow;

    return completePromise;
  }

  async get(key: string): Promise<any> {
    const promise = new Promise((resolve, reject) => {
      const listener = (message: MessageEvent) => {
        if (
          message.source === this.iframeWindow &&
          message.data.key &&
          message.data.key === key
        ) {
          clearTimeout(timeout);
          window.removeEventListener('message', listener);
          resolve(message.data.value);
        }
      };
      const timeout = setTimeout(() => {
        window.removeEventListener('message', listener);
        reject(new Error(`Iframe storage timed out reading '${key}'`));
      }, STORAGE_CDN_TIMEOUT);

      window.addEventListener('message', listener);
    });

    this.iframeWindow?.postMessage({ type: 'get', key: key }, '*');
    return promise;
  }

  async set(key: string, value: any): Promise<void> {
    this.iframeWindow?.postMessage(
      { type: 'set', key: key, value: value },
      '*',
    );
  }

  async remove(key: string): Promise<void> {
    this.iframeWindow?.postMessage({ type: 'remove', key: key }, '*');
  }

  async processChatMessages(messages: any[]): Promise<void> {
    this.iframeWindow?.postMessage(
      { type: 'processChatMessages', messages: messages },
      '*',
    );
  }

  async getChatMessages(): Promise<any> {
    const promise = new Promise((resolve) => {
      const listener = (message: MessageEvent) => {
        if (message.source === this.iframeWindow && message.data.messages) {
          clearTimeout(timeout);
          window.removeEventListener('message', listener);
          resolve(message.data.messages);
        }
      };
      const timeout = setTimeout(() => {
        window.removeEventListener('message', listener);
        resolve(undefined);
      }, STORAGE_CDN_TIMEOUT);

      window.addEventListener('message', listener);
    });

    this.iframeWindow?.postMessage({ type: 'getChatMessages' }, '*');
    return promise;
  }

  destroy(): void {
    this.documentElement?.remove();
    this.documentElement = null;
    this.iframeWindow = null;
  }
}

function createMemoryStore(): KeyValueStore {
  const values = new Map<string, string>();
  return {
    getItem: (key) => values.get(key) ?? null,
    setItem: (key, value) => {
      values.set(key, value);
    },
    removeItem: (key) => {
      values.delete(key);
    },
  };
}

function getByondStorage(): KeyValueStore | null {
  const store = window.serverStorage;
  return store && typeof store.getItem === 'function' ? store : null;
}

function requestByondStorage(): Promise<KeyValueStore | null> {
  const available = getByondStorage();
  if (available || !Byond.IS_BYOND) {
    return Promise.resolve(available);
  }
  return new Promise((resolve) => {
    let done = false;
    const finish = () => {
      if (done) {
        return;
      }
      done = true;
      clearTimeout(timeout);
      document.removeEventListener('byondstorageupdated', onUpdated);
      resolve(getByondStorage());
    };
    const onUpdated = () => setTimeout(finish, 1);
    const timeout = setTimeout(finish, BYOND_STORAGE_WAIT);
    document.addEventListener('byondstorageupdated', onUpdated);
    Byond.winset(null, 'browser-options', '+byondstorage');
  });
}

function getBrowserStorage(): KeyValueStore | null {
  if (Byond.IS_BYOND) {
    return null;
  }
  try {
    const store = window.localStorage;
    const probe = `${KEY_PREFIX}probe`;
    store.setItem(probe, '1');
    store.removeItem(probe);
    return store;
  } catch {
    return null;
  }
}

function messageIdentity(message: any): string {
  return `${message?.createdAt}|${message?.type}|${message?.html ?? message?.text}`;
}

function dedupeMessages(messages: any[]): any[] {
  const seen = new Set<string>();
  const unique: any[] = [];
  for (const message of messages) {
    if (!message) {
      continue;
    }
    const identity = messageIdentity(message);
    if (seen.has(identity)) {
      continue;
    }
    seen.add(identity);
    unique.push(message);
  }
  return unique.slice(-MAX_MIGRATED_MESSAGES);
}

class StorageProxy implements StorageBackend {
  public diagnostics: StorageDiagnostic[] = [];

  private backendPromise: Promise<StorageBackend>;
  private migrationPromise: Promise<void> | null = null;
  private unreadKeys = new Set<string>();

  constructor() {
    this.backendPromise = this.selectBackend();
  }

  async get(key: string): Promise<any> {
    const backend = await this.awaitKey(key);
    try {
      const value = await backend.get(key);
      this.unreadKeys.delete(key);
      return value;
    } catch {
      this.unreadKeys.add(key);
      this.log('warn', `Failed to read '${key}', keeping saved value intact`);
      return undefined;
    }
  }

  async set(key: string, value: any): Promise<void> {
    const backend = await this.backendPromise;
    if (this.unreadKeys.has(key)) {
      return;
    }
    return backend.set(key, value);
  }

  async remove(key: string): Promise<void> {
    const backend = await this.backendPromise;
    return backend.remove(key);
  }

  async processChatMessages(messages: any[]): Promise<void> {
    const backend = await this.backendPromise;
    return backend.processChatMessages(messages);
  }

  async getChatMessages(): Promise<any> {
    const backend = await this.awaitKey(CHAT_MESSAGES_KEY);
    return backend.getChatMessages();
  }

  private log(level: StorageDiagnostic['level'], message: string): void {
    this.diagnostics.push({ level, message });
  }

  private async awaitKey(key: string): Promise<StorageBackend> {
    const backend = await this.backendPromise;
    if (
      this.migrationPromise &&
      backend instanceof LocalBackend &&
      !backend.has(key)
    ) {
      await this.migrationPromise;
    }
    return backend;
  }

  private async selectBackend(): Promise<StorageBackend> {
    const byondStore = await requestByondStorage();
    if (byondStore) {
      this.log('info', 'Using BYOND server storage');
      return this.withMigration(new LocalBackend(byondStore));
    }

    const browserStore = getBrowserStorage();
    if (browserStore) {
      this.log('info', 'Using browser storage');
      return this.withMigration(new LocalBackend(browserStore));
    }

    if (Byond.storageCdn) {
      const iframe = new IFrameIndexedDbBackend();
      if (await iframe.ready()) {
        this.log(
          'warn',
          `Local storage unavailable, using ${Byond.storageCdn}`,
        );
        return iframe;
      }
      iframe.destroy();
    }

    this.log('error', 'No persistent storage available, settings will reset');
    return new LocalBackend(createMemoryStore());
  }

  private withMigration(local: LocalBackend): LocalBackend {
    if (Byond.storageCdn && !local.has(MIGRATED_KEY)) {
      this.migrationPromise = this.migrateFromIframe(local).catch(() => {
        this.log('info', 'Moving settings from iframe storage failed');
      });
    }
    return local;
  }

  private async migrateFromIframe(local: LocalBackend): Promise<void> {
    const legacy = new IFrameIndexedDbBackend();
    try {
      if (!(await legacy.ready())) {
        this.log(
          'info',
          `Old settings storage is unreachable (${Byond.storageCdn}), will retry next time`,
        );
        return;
      }

      let complete = true;
      const readLegacy = async (key: string): Promise<any> => {
        try {
          return await legacy.get(key);
        } catch {
          complete = false;
          return undefined;
        }
      };
      const copy = async (key: string, value: any): Promise<void> => {
        if (value !== undefined && !local.has(key)) {
          await local.set(key, value);
        }
      };

      const [geometries, presets] = await Promise.all([
        readLegacy('geometries'),
        readLegacy('podlauncher_presetlist'),
      ]);
      const keys = new Set(LEGACY_KEYS);
      if (Array.isArray(geometries)) {
        for (const key of geometries) {
          if (typeof key === 'string') {
            keys.add(key);
          }
        }
      }
      if (Array.isArray(presets)) {
        for (const preset of presets) {
          if (preset?.id) {
            keys.add(`podlauncher_preset_${preset.id}`);
          }
        }
      }

      await Promise.all(
        [...keys].map(async (key) => {
          if (!local.has(key)) {
            await copy(key, await readLegacy(key));
          }
        }),
      );

      if (!local.has(CHAT_MESSAGES_KEY)) {
        const messages = await legacy.getChatMessages();
        if (Array.isArray(messages)) {
          await copy(CHAT_MESSAGES_KEY, dedupeMessages(messages));
        } else {
          complete = false;
        }
      }

      if (!complete) {
        this.log(
          'info',
          'Old settings were moved partially, will retry next time',
        );
        return;
      }
      await local.set(MIGRATED_KEY, true);
      this.log('info', 'Moved settings from iframe storage');
    } finally {
      legacy.destroy();
    }
  }
}

export const storage = new StorageProxy();
