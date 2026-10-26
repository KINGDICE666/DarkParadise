import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test, { mock } from 'node:test';
import { createAssetIndex, createWebrootReader } from './assets.mjs';

test('resource roots must be an explicit list of directories', () => {
  assert.throws(() => createAssetIndex('/srv/game'), /public resource directories/);
  assert.throws(() => createAssetIndex(['']), /public resource directories/);
});

test('DD exported assets retain namespaces and cannot escape the public directory', async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'dp-web-assets-'));
  try {
    const root = path.join(directory, 'public');
    const name = 'asset.' + 'a'.repeat(32) + '.css';
    const namespace = 'namespaces/bb/' + 'b'.repeat(32);
    await fs.mkdir(path.join(root, 'aa'), { recursive: true });
    await fs.mkdir(path.join(root, namespace), { recursive: true });
    await fs.writeFile(path.join(root, 'aa', name), 'body { color: white }');
    await fs.writeFile(path.join(root, namespace, 'font.woff2'), 'font bytes');
    await fs.writeFile(path.join(directory, 'secret.css'), 'private');
    const reader = createWebrootReader(root);
    assert.equal((await reader.get('/assets/aa/' + name)).type, 'text/css; charset=utf-8');
    assert.equal((await reader.get('/assets/' + namespace + '/font.woff2')).bytes.toString(), 'font bytes');
    assert.equal(await reader.get('/assets/../secret.css'), null);
    assert.equal(await reader.get('/assets/%2e%2e/secret.css'), null);
    assert.equal(await reader.get('/assets/secret.css'), null);
    if (process.platform !== 'win32') {
      const escape = path.join(root, 'aa', 'asset.' + 'c'.repeat(32) + '.css');
      await fs.symlink(path.join(directory, 'secret.css'), escape);
      assert.equal(await reader.get('/assets/aa/' + path.basename(escape)), null);
    }
  } finally {
    assert.ok(path.resolve(directory).startsWith(path.join(path.resolve(os.tmpdir()), 'dp-web-assets-')));
    await fs.rm(directory, { recursive: true, force: true });
  }
});

test('public resources are served under their real content hash', async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'dp-web-assets-'));
  try {
    const body = Buffer.from('window.testAsset = "Проверка";');
    await fs.writeFile(path.join(directory, 'panel.js'), body);
    await fs.writeFile(path.join(directory, 'private.json'), '{"secret":"not public"}');
    const hash = crypto.createHash('md5').update(body).digest('hex');
    const index = createAssetIndex([directory]);
    const asset = await index.get(`/asset.${hash}.js`);
    assert.deepEqual(asset.bytes, body);
    assert.equal(asset.type, 'text/javascript; charset=utf-8');
    assert.equal(await index.get(`/asset.${hash}.css`), null);
    assert.equal(await index.get('/../panel.js'), null);
    const privateHash = crypto.createHash('md5').update('{"secret":"not public"}').digest('hex');
    assert.equal(await index.get(`/asset.${privateHash}.json`), null);
    await fs.writeFile(path.join(directory, 'panel.js'), 'changed revision');
    assert.deepEqual((await index.get(`/asset.${hash}.js`)).bytes, body);
  } finally {
    assert.ok(path.resolve(directory).startsWith(path.join(path.resolve(os.tmpdir()), 'dp-web-assets-')));
    await fs.rm(directory, { recursive: true, force: true });
  }
});

test('a resource removed mid-scan does not fail delivery of the others', async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'dp-web-assets-'));
  const stat = fs.stat;
  try {
    const body = Buffer.from('body { color: red; }');
    await fs.writeFile(path.join(directory, 'kept.css'), body);
    await fs.writeFile(path.join(directory, 'gone.css'), 'removed during build');
    mock.method(fs, 'stat', async filename => {
      if (path.basename(filename) === 'gone.css') throw Object.assign(new Error('gone'), { code: 'ENOENT' });
      return stat(filename);
    });
    const hash = crypto.createHash('md5').update(body).digest('hex');
    assert.deepEqual((await createAssetIndex([directory]).get(`/asset.${hash}.css`)).bytes, body);
  } finally {
    mock.restoreAll();
    await fs.rm(directory, { recursive: true, force: true });
  }
});

test('rescans read only resources that changed', async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'dp-web-assets-'));
  const readFile = fs.readFile;
  try {
    const body = Buffer.from('window.first = 1;');
    await fs.writeFile(path.join(directory, 'first.js'), body);
    const read = [];
    mock.method(fs, 'readFile', async filename => { read.push(path.basename(filename)); return readFile(filename); });
    const index = createAssetIndex([directory]);
    const hash = crypto.createHash('md5').update(body).digest('hex');
    assert.ok(await index.get(`/asset.${hash}.js`));
    const added = Buffer.from('window.second = 2;');
    await fs.writeFile(path.join(directory, 'second.js'), added);
    await new Promise(resolve => setTimeout(resolve, 1100));
    const addedHash = crypto.createHash('md5').update(added).digest('hex');
    assert.deepEqual((await index.get(`/asset.${addedHash}.js`)).bytes, added);
    assert.deepEqual(read, ['first.js', 'second.js']);
  } finally {
    mock.restoreAll();
    await fs.rm(directory, { recursive: true, force: true });
  }
});
