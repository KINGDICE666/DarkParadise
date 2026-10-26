import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';

const types = {
  '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.gif': 'image/gif', '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf',
};

export function createAssetIndex(roots) {
  if (!Array.isArray(roots) || roots.some(root => typeof root !== 'string' || !root.trim())) {
    throw new TypeError('ASSET_ROOTS must be an array of public resource directories');
  }
  let assets = new Map();
  let files = new Map();
  let scannedAt = 0;
  let scanning;
  const vanished = (error, nested) => nested && error?.code === 'ENOENT';
  async function scan(directory, next, seen, nested) {
    let entries;
    try { entries = await fs.readdir(directory, { withFileTypes: true }); }
    catch (error) { if (vanished(error, nested)) return; throw error; }
    for (const entry of entries) {
      const filename = path.join(directory, entry.name);
      if (entry.isDirectory()) { await scan(filename, next, seen, true); continue; }
      const extension = path.extname(entry.name).toLowerCase();
      if (!entry.isFile() || !types[extension]) continue;
      try {
        const stat = await fs.stat(filename);
        if (stat.size > 32 * 1024 * 1024) continue;
        let file = files.get(filename);
        if (!file || file.size !== stat.size || file.mtimeMs !== stat.mtimeMs) {
          const bytes = await fs.readFile(filename);
          const hash = crypto.createHash('md5').update(bytes).digest('hex');
          file = { size: stat.size, mtimeMs: stat.mtimeMs, name: `asset.${hash}${extension}`, asset: { bytes, type: types[extension], hash } };
        }
        seen.set(filename, file);
        next.set(file.name, file.asset);
      } catch (error) {
        if (!vanished(error, true)) throw error;
      }
    }
  }
  return {
    async get(requestPath) {
      const name = requestPath.replace(/^\//, '');
      if (!/^asset\.[a-f0-9]{32}\.[a-z0-9]+$/.test(name) || !roots.length) return null;
      if (!assets.has(name) && Date.now() - scannedAt > 1000) {
        if (!scanning) {
          const next = new Map();
          const seen = new Map();
          scanning = Promise.all(roots.map(directory => scan(directory, next, seen, false)))
            .then(() => { assets = next; files = seen; })
            .finally(() => { scannedAt = Date.now(); scanning = null; });
        }
        await scanning;
      }
      return assets.get(name) || null;
    },
  };
}
