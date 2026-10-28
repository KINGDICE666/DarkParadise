import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { dmiFrame, encodePng, loadDmi, parseDmiDescription } from './dmi.mjs';

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

function withDescription(png, text) {
  const data = Buffer.concat([Buffer.from('Description\0\0', 'latin1'), zlib.deflateSync(Buffer.from(text))]);
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  chunk.write('zTXt', 4, 'latin1');
  data.copy(chunk, 8);
  chunk.writeUInt32BE(zlib.crc32(chunk.subarray(4, 8 + data.length)), 8 + data.length);
  return Buffer.concat([png.subarray(0, 33), chunk, png.subarray(33)]);
}

function sheet(description, count, columns) {
  const rows = Math.ceil(count / columns);
  const rgba = Buffer.alloc(columns * 2 * rows * 2 * 4);
  for (let i = 0; i < count; i++) {
    for (let y = 0; y < 2; y++) {
      for (let x = 0; x < 2; x++) {
        const offset = (((Math.floor(i / columns) * 2 + y) * columns * 2) + (i % columns) * 2 + x) * 4;
        rgba[offset] = i;
        rgba[offset + 3] = 255;
      }
    }
  }
  return loadDmi(withDescription(encodePng(columns * 2, rows * 2, rgba), description));
}

function frameIndex(png) {
  const dmi = loadDmi(withDescription(png, '# BEGIN DMI\nversion = 4.0\n\twidth = 2\n\theight = 2\nstate = ""\n# END DMI'));
  const out = Buffer.alloc(4);
  dmi.image.pixel(0, 0, out, 0);
  return out[0];
}

const DESCRIPTION = `# BEGIN DMI
version = 4.0
\twidth = 2
\theight = 2
state = "single"
\tdirs = 1
\tframes = 1
state = "walk"
\tdirs = 4
\tframes = 2
\tdelay = 1,1
state = "walk"
\tdirs = 4
\tframes = 1
\tmovement = 1
state = "diagonal"
\tdirs = 8
\tframes = 1
state = ""
\tdirs = 1
\tframes = 1
# END DMI`;

test('DMI descriptions keep state order, movement and icon size', () => {
  const meta = parseDmiDescription(DESCRIPTION);
  assert.equal(meta.width, 2);
  assert.deepEqual(meta.states.map(state => [state.name, state.dirs, state.frames, state.movement]), [
    ['single', 1, 1, false], ['walk', 4, 2, false], ['walk', 4, 1, true], ['diagonal', 8, 1, false], ['', 1, 1, false],
  ]);
});

test('frames are cut in DreamSeeker frame and direction order', () => {
  const dmi = sheet(DESCRIPTION, 22, 5);
  const pick = options => frameIndex(dmiFrame(dmi, options));
  assert.equal(pick({ state: 'single', dir: 8 }), 0);
  assert.equal(pick({ state: 'walk', dir: 2 }), 1);
  assert.equal(pick({ state: 'walk', dir: 1 }), 2);
  assert.equal(pick({ state: 'walk', dir: 8, frame: 2 }), 8);
  assert.equal(pick({ state: 'walk', dir: 6 }), 3);
  assert.equal(pick({ state: 'walk', dir: 9, frame: 9 }), 8);
  assert.equal(pick({ state: 'walk', dir: 4, movement: true }), 11);
  assert.equal(pick({ state: 'diagonal', dir: 9 }), 20);
  assert.equal(pick({ state: 'missing' }), 21);
});

test('a state that does not exist without a default state is not found', () => {
  const dmi = sheet('# BEGIN DMI\nversion = 4.0\n\twidth = 2\n\theight = 2\nstate = "only"\n\tdirs = 1\n\tframes = 1\n# END DMI', 1, 1);
  assert.equal(dmiFrame(dmi, { state: 'other' }), null);
});

test('repository DMIs of every color format decode to their icon size', async () => {
  const files = {
    'icons/hud/lobby/observe.dmi': [139, 22],
    'icons/effects/32x64.dmi': [32, 64],
  };
  const seen = new Set();
  for (const directory of ['icons/obj', 'icons/mob', 'icons/turf', 'icons/effects']) {
    for (const entry of await fs.readdir(path.join(REPO, directory), { recursive: true })) {
      if (!entry.endsWith('.dmi')) continue;
      const bytes = await fs.readFile(path.join(REPO, directory, entry));
      const format = `${bytes[24]}/${bytes[25]}`;
      if (seen.has(format)) continue;
      seen.add(format);
      files[path.posix.join(directory, entry.replaceAll('\\', '/'))] = null;
    }
  }
  assert.ok(seen.has('8/6') && seen.has('8/3') && seen.has('4/3'));
  for (const [file, size] of Object.entries(files)) {
    const dmi = loadDmi(await fs.readFile(path.join(REPO, file)));
    const png = dmiFrame(dmi, { state: dmi.meta.states[0].name });
    assert.ok(png, file);
    const expected = size || [dmi.meta.width, dmi.meta.height];
    assert.deepEqual([png.readUInt32BE(16), png.readUInt32BE(20)], expected, file);
  }
});
