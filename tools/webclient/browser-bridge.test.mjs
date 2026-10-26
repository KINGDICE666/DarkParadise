import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';

test('wire strings use UTF-8 bytes and are not encoded twice', () => {
  const window = { parent: {}, addEventListener() {} };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), {
    window, document: { referrer: '' }, navigator: { sendBeacon() {} }, TextEncoder,
  });
  const stringWriter = () => {};
  const utfWriter = () => {};
  const first = 'Привет 🚀';
  const large = 'я'.repeat(40_000);
  const message = {
    _putString$1: stringWriter, _putUTFString$1: utfWriter,
    _pos: 2 + first.length + 1 + large.length + 2,
    _elems: [{ val: first, func: { _target: stringWriter } }, { val: large, func: { _target: utfWriter } }],
  };
  window.__dpEncodeMessage(message);
  const expected = 2 + Buffer.byteLength(first) + 1 + Buffer.byteLength(large) + 6;
  assert.equal(message._pos, expected);
  assert.equal(Buffer.from(message._elems[0].val, 'latin1').toString('utf8'), first);
  window.__dpEncodeMessage(message);
  assert.equal(message._pos, expected);
});

test('embedded TGUI can send Topic and window calls through the web client', async () => {
  const topics = [];
  const settings = [];
  const native = { skin: {
    winset(id, values) { settings.push([id, JSON.parse(JSON.stringify(values))]); },
    winget() { return { isVisible: true }; },
  } };
  const window = {
    parent: { location: { origin: 'https://game.example' }, byond: native },
    byond: { topic(query) { topics.push(query); } }, setTimeout, Promise,
  };
  const context = {
    window, location: { origin: 'https://game.example', hostname: 'game.example', search: '' },
    navigator: { userAgent: 'Chrome/120.0' },
    document: { getElementById(id) { return { getAttribute() { return id === 'tgui:strictMode' ? '0' : 'test'; } }; } },
  };
  vm.runInNewContext(fs.readFileSync(new URL('../../tgui/packages/tgui-setup/helpers.js', import.meta.url), 'utf8'), context);
  assert.equal(window.Byond.IS_BYOND, true);
  window.Byond.sendMessage('ready', { test: true });
  assert.equal(new URLSearchParams(topics[0]).get('tgui'), '1');
  window.Byond.winset('chat', 'is-visible', true);
  assert.deepEqual(settings[0], ['chat', { isVisible: true }]);
  assert.equal(await window.Byond.winget('chat', 'is-visible'), true);
});
