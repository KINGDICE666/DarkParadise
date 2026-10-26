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
  const native = { fn: { topic(query) { topics.push(query); } }, skin: {
    winset(id, values) { settings.push([id, JSON.parse(JSON.stringify(values))]); },
    winget(id, requested) {
      if ('*' in requested) return { size: '650x475', type: 'pane' };
      if ('pos' in requested) return { pos: '20,-30' };
      return { isVisible: true };
    },
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
  assert.equal((await window.Byond.winget('chat')).size, '650x475');
  assert.deepEqual(JSON.parse(JSON.stringify(await window.Byond.winget('chat', 'pos'))), { x: 20, y: -30 });
});

test('stat tab notifications coalesce while ready messages are immediate', () => {
  const timers = [];
  const delivered = [];
  const window = { parent: {}, addEventListener() {} };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), {
    window, document: { referrer: '' }, navigator: { sendBeacon() {} }, TextEncoder, URLSearchParams,
    setTimeout(callback) { timers.push(callback); return timers.length; },
  });
  const client = { sendTopicMessage$1(topic) { if (!window.__dpScheduleTopic(client, topic)) delivered.push(topic); } };
  const first = '?tgui=1&window_id=statbrowser&type=Send-Tabs&payload=one';
  const second = '?tgui=1&window_id=statbrowser&type=Remove-Tabs&payload=one';
  client.sendTopicMessage$1(first);
  client.sendTopicMessage$1(first);
  client.sendTopicMessage$1(second);
  client.sendTopicMessage$1('?tgui=1&window_id=browseroutput&type=ready');
  assert.deepEqual(delivered, ['?tgui=1&window_id=browseroutput&type=ready']);
  while (timers.length) timers.shift()();
  assert.deepEqual(delivered.slice(1), [first, second]);
});

test('moving a loaded browser control preserves its browsing context', () => {
  const window = { parent: {}, addEventListener() {} };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), {
    window, document: { referrer: '' }, navigator: { sendBeacon() {} }, TextEncoder,
  });
  const moved = [];
  const control = { tagName: 'DIV', isConnected: true, querySelector() { return {}; } };
  const parent = { isConnected: true, moveBefore(child, anchor) { moved.push([child, anchor]); },
    appendChild() { assert.fail('appendChild would reload the iframe'); } };
  assert.equal(window.__dpMoveControl(parent, control), control);
  assert.deepEqual(moved, [[control, null]]);
});

test('a stat tab removed and added again is delivered in order', () => {
  const timers = [];
  const delivered = [];
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), {
    window, URLSearchParams, setTimeout(callback) { timers.push(callback); return timers.length; },
  });
  let failNext = true;
  const client = { sendTopicMessage$1(topic) {
    if (window.__dpScheduleTopic(client, topic)) return;
    if (failNext) { failNext = false; throw new Error('socket busy'); }
    delivered.push(topic);
  } };
  const tab = encodeURIComponent(JSON.stringify({ tab: 'Объекты' }));
  const add = `?tgui=1&window_id=statbrowser&type=Send-Tabs&payload=${tab}`;
  const remove = `?tgui=1&window_id=statbrowser&type=Remove-Tabs&payload=${tab}`;
  const other = `?tgui=1&window_id=statbrowser&type=Send-Tabs&payload=${encodeURIComponent(JSON.stringify({ tab: 'IC' }))}`;
  for (const topic of [other, add, remove, add, add]) client.sendTopicMessage$1(topic);
  assert.throws(() => timers.shift()(), /socket busy/);
  while (timers.length) timers.shift()();
  assert.deepEqual(delivered, [add, remove, add]);
});

test('browser links with a literal percent sign still decode', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, unescape });
  const source = window.__dpPatchSkin('browser', "v=unescape(a[i].replace(/\\+/g,' '))");
  const a = ['%D0%9F%D1%80%D0%B8+%D0%B2%D0%B5%D1%82', '100%+готово'];
  const decoded = a.map((_, i) => vm.runInNewContext(`${source}; v`, { window, a, i }));
  assert.deepEqual(decoded, ['При вет', '100% готово']);
});

function loadHelpers(context) {
  const elements = [];
  context.window = Object.assign({ parent: null, setTimeout: context.setTimeout }, context.window);
  context.window.parent = context.window;
  Object.assign(context, {
    location: { origin: 'https://game.example', hostname: 'game.example', search: '' },
    navigator: { userAgent: 'Chrome/120.0' },
  });
  context.document = Object.assign({
    getElementById() { return { getAttribute() { return '0'; } }; },
    createElement(tag) { const node = { tag, style: {}, click() { node.clicked = true; } }; elements.push(node); return node; },
    body: {
      childNodes: [{ parentNode: { insertBefore(node) { node.parentNode = { removeChild() {} }; } } }],
      appendChild(node) { node.parentNode = this; }, removeChild() {},
    },
  }, context.document);
  vm.runInNewContext(fs.readFileSync(new URL('../../tgui/packages/tgui-setup/helpers.js', import.meta.url), 'utf8'), context);
  return elements;
}

test('a missing tgui asset stops retrying after the attempt limit', () => {
  const timers = [];
  const context = { setTimeout(callback) { timers.push(callback); } };
  const elements = loadHelpers(context);
  context.window.Byond.loadJs('https://game.example/asset.missing.js');
  let failure;
  for (let step = 0; step < 20 && !failure; step++) {
    try { elements.at(-1).onerror(); } catch (error) { failure = error; }
    while (timers.length) timers.shift()();
  }
  assert.match(failure?.message, /after several attempts/);
  assert.equal(elements.length, 6);
});

test('chat logs can be saved without the file picker', () => {
  const urls = [];
  const context = {
    setTimeout(callback) { callback(); },
    URL: { createObjectURL() { urls.push('blob:log'); return 'blob:log'; }, revokeObjectURL(url) { urls.push(`revoked ${url}`); } },
  };
  context.window = { navigator: {}, URL: context.URL };
  const elements = loadHelpers(context);
  context.window.Byond.saveBlob({ type: 'text/plain' }, 'ss13-chatlog.html', '.html');
  const link = elements.find(node => node.tag === 'a');
  assert.equal(link.download, 'ss13-chatlog.html');
  assert.equal(link.href, 'blob:log');
  assert.ok(link.clicked);
  assert.deepEqual(urls, ['blob:log', 'revoked blob:log']);
});

test('web client panels keep settings in browser storage without waiting for BYOND', async () => {
  const items = new Map();
  const localStorage = {
    getItem: key => items.get(key) ?? null,
    setItem(key, value) { if (value.length > 64) throw new Error('QuotaExceededError'); items.set(key, value); },
    removeItem: key => items.delete(key), clear: () => items.clear(),
  };
  const winsets = [];
  const window = { localStorage, parent: { location: { origin: 'https://game.example' }, byond: { skin: {} } } };
  Object.assign(globalThis, {
    window, location: { origin: 'https://game.example' }, document: {},
    Byond: { storageCdn: 'https://cdn.example/storage.html', winset(...args) { winsets.push(args); } },
  });
  try {
    const { storage } = await import(`../../tgui/packages/common/storage.ts?web=${Date.now()}`);
    await storage.set('panel-settings', { theme: 'dark' });
    assert.deepEqual(await storage.get('panel-settings'), { theme: 'dark' });
    assert.equal(items.get('paradise-panel-settings'), '{"theme":"dark"}');
    await storage.processChatMessages([{ html: 'x'.repeat(100) }]);
    assert.equal(await storage.getChatMessages(), undefined);
    assert.deepEqual(storage.diagnostics.map(d => d.level), ['info']);
    assert.deepEqual(winsets, []);
    items.set('webclient-session', 'keep');
    Object.assign(localStorage, Object.fromEntries(items));
    await storage.clear();
    assert.equal(items.get('webclient-session'), 'keep');
    assert.equal(items.has('paradise-panel-settings'), false);
  } finally {
    for (const key of ['window', 'location', 'document', 'Byond']) delete globalThis[key];
  }
});

test('key macros receive the pointer position relative to the map', () => {
  let move;
  const document = { addEventListener(type, listener) { if (type === 'mousemove') move = listener; } };
  const map = { getBoundingClientRect() { return { left: 10, top: 20, width: 640, height: 480 }; } };
  const window = { byond: { skin: { find: id => (id === 'mapwindow.map' ? { elem: map } : null) } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, document, TextEncoder });
  move({ clientX: 330, clientY: 260 });
  assert.equal(window.__dpExpandCommand('KeyDown "W" [[mapwindow.map.mouse-pos]] [[mapwindow.map.size]]'), 'KeyDown "W" 320 240 640 480');
  move({ clientX: 2000, clientY: -5 });
  assert.equal(window.__dpExpandCommand('KeyUp "W" [[mapwindow.map.mouse-pos]] [[mapwindow.map.size]]'), 'KeyUp "W" 640 0 640 480');
  assert.equal(window.__dpExpandCommand('say "[[not a placeholder]]"'), 'say "[[not a placeholder]]"');
});

test('topics beyond the server rate limit wait in order', () => {
  let clock = 0;
  const timers = [];
  const delivered = [];
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), {
    window, URLSearchParams, Date: { now: () => clock },
    setTimeout(callback, delay) { timers.push({ callback, at: clock + delay }); return timers.length; },
  });
  const client = { sendTopicMessage$1(topic) { if (!window.__dpScheduleTopic(client, topic)) delivered.push(topic); } };
  const topics = Array.from({ length: 11 }, (_, index) => `?tgui=1&window_id=browseroutput&type=font&index=${index}`);
  for (const topic of topics) client.sendTopicMessage$1(topic);
  assert.deepEqual(delivered, topics.slice(0, 8));
  while (timers.length) {
    const next = timers.shift();
    clock = Math.max(clock, next.at);
    next.callback();
  }
  assert.deepEqual(delivered, topics);
  assert.ok(clock >= 1000);
});

test('screen edges from BYOND 515 map to the web client compass keywords', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  assert.equal(window.__dpScreenLoc('TOP:-70,CENTER:-54'), 'NORTH:-70,CENTER:-54');
  assert.equal(window.__dpScreenLoc('BOTTOMLEFT to TOPRIGHT'), 'SOUTHWEST to NORTHEAST');
  assert.equal(window.__dpScreenLoc('map2:LEFT+1,BOTTOM'), 'map2:WEST+1,SOUTH');
  assert.equal(window.__dpScreenLoc('EAST-3,CENTER:140'), 'EAST-3,CENTER:140');
});

test('maptext uses the map style classes and ignores transparent colors', () => {
  const span = {
    classList: ['maptext'], attributes: { class: 'maptext', style: 'color:rgba(0,0,0,0.000);text-align:center' },
    getAttribute(name) { return this.attributes[name] ?? null; },
    setAttribute(name, value) { this.attributes[name] = value; },
    removeAttribute(name) { delete this.attributes[name]; },
  };
  const map = { getAttribute() { return 'pos=0,0;style=".maptext { font-family: \'Grand9K Pixel\'; color: white; } .other, .maptext { font-size: 6pt }";zoom=0'; } };
  const document = {
    querySelector() { return map; },
    createElement() {
      return { content: { querySelectorAll() { return [span]; } }, set innerHTML(value) { this.source = value; }, get innerHTML() { return span.attributes.style; } };
    },
  };
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, document });
  assert.equal(window.__dpMaptextHtml('<span class="maptext">x</span>'), "font-family:'Grand9K Pixel';color:white;font-size:6pt;text-align:center");
  assert.equal(window.__dpMaptextHtml('plain'), 'plain');
});

test('stat panel theme commands apply when its functions are not global', () => {
  const classes = new Set(['menu-wrap']);
  const doc = {
    readyState: 'complete', body: { className: '', style: { setProperty() {}, removeProperty() {} } }, documentElement: { className: '' },
    getElementById() { return { classList: { toggle(name, on) { if (on) classes.add(name); else classes.delete(name); } } }; },
  };
  const frame = { tagName: 'IFRAME', contentWindow: {}, contentDocument: doc };
  const outputs = [];
  const window = { byond: { skin: { find: id => (id === 'statbrowser' ? { elem: frame } : null), output(id, data) { outputs.push([id, data.text]); } } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, decodeURIComponent });
  assert.equal(window.__dpExpandCommand('.output statbrowser:set_theme dark'), null);
  assert.equal(doc.documentElement.className, 'dark');
  assert.equal(doc.body.className, 'dark');
  window.__dpExpandCommand('.output statbrowser:set_tabs_style classic');
  assert.deepEqual([...classes].sort(), ['menu-wrap', 'tabs-classic']);
  frame.contentWindow.set_theme = () => {};
  window.__dpExpandCommand('.output statbrowser:set_theme light');
  assert.deepEqual(outputs, [['statbrowser:set_theme', 'light']]);
});
