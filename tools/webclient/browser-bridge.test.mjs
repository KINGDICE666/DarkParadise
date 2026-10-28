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

test('lighting planes fold into one multiplied layer on every z offset', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const blends = ['normal', 'overlay', 'add', 'subtract', 'multiply'];
  const icon = (plane, extra) => Object.assign({ plane, flags: 0, subplane: 0 }, extra);
  const keep = plane => window.__dpMapIcon(icon(plane), {}, null, blends);
  assert.deepEqual([12, 14, 22, 12 - 107, 20 - 214].map(keep), [false, false, false, false, false]);
  assert.deepEqual([-21, -21 - 107].map(keep), [true, true]);
  assert.deepEqual([-8, -4, 9, 10, 23, 40, -4 - 107, -32767, undefined].map(keep), [true, true, true, true, true, true, true, true, true]);
  const master = icon(10 - 107, { flags: 256 });
  assert.equal(window.__dpMapIcon(master, {}, null, blends), true);
  assert.equal(master._blendMode, 'multiply');
  const overlayLight = icon(11 - 107);
  assert.equal(window.__dpMapIcon(overlayLight, {}, null, blends), true);
  assert.deepEqual([overlayLight.plane, overlayLight._blendMode], [10 - 107, 'add']);
  assert.equal(window.__dpMapIcon(icon(11, { flags: 256 }), {}, null, blends), false);
  const matrix = new Array(20).fill(0);
  matrix[16] = 1;
  matrix[15] = 1;
  const emissive = icon(13, { color: { matrix: { matrix } } });
  assert.equal(window.__dpMapIcon(emissive, {}, null, blends), true);
  assert.equal(emissive.__dpEmissive, true);
  assert.equal(window.__dpMapIcon(icon(13, { color: { red: 0 } }), {}, null, blends), false);
  const backdrop = icon(10, { info: { onScreen: true } });
  assert.equal(window.__dpMapIcon(backdrop, { iconState: 'flash', blendMode: 1 }, null, blends), false);
  assert.equal(window.__dpMapIcon(icon(10, { info: { onScreen: true } }), { iconState: 'flash', blendMode: 2 }, null, blends), true);
});

test('native parallax layers rebuild only when their appearance or motion changes', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const core = (plane, iconId) => ({ plane, iconId, pixel_w: 0, pixel_z: 0,
    get$planeMaster: () => false, set$keepApart() {} });
  const layer = { id: 2, locId: 0, pixel_w: 12, pixel_z: -8, _appearance: { core: core(-20, 7) },
    get$currentAppearance() { return this._appearance; } };
  const holder = { id: 4, onScreen: true, screenLoc: {}, _appearance: { core: core(-20, 65535) } };
  const ordinary = { locId: 0, _appearance: { core: core(-4, 7) } };
  const atoms = new Map([[2, layer], [3, ordinary], [4, holder]]);
  const map = { movs: [2, 3], screen: [4] };
  const client = { mapInfo: map, currentMs: 100, infoMap: { $index: (_, id) => atoms.get(id) } };
  window.__dpPrepareParallax(map, client);
  assert.equal(holder.icons_dirty, true);
  holder.icons_dirty = false;
  window.__dpPrepareParallax(map, client);
  assert.equal(holder.icons_dirty, false);
  const clone = a => ({ ...a, core: { ...a.core } });
  const appearance = window.__dpParallaxAppearance(holder, holder._appearance, client, clone);
  assert.equal(appearance.overlays.length, 1);
  assert.deepEqual([appearance.overlays[0].core.pixel_w, appearance.overlays[0].core.pixel_z], [12, -8]);
  assert.equal(layer._appearance.core.pixel_w, 0, 'never mutate cached server appearances');
  layer.pixel_w++;
  window.__dpPrepareParallax(map, client);
  assert.equal(holder.icons_dirty, true);
  holder.icons_dirty = false;
  layer._animation = { total_end: 150 };
  client.currentMs = 125;
  window.__dpPrepareParallax(map, client);
  assert.equal(holder.icons_dirty, true, 'animate active layers');
  holder.icons_dirty = false;
  client.currentMs = 160;
  window.__dpPrepareParallax(map, client);
  holder.icons_dirty = false;
  client.currentMs = 180;
  window.__dpPrepareParallax(map, client);
  assert.equal(holder.icons_dirty, false, 'expired off-map animation does not rebuild forever');
  map.movs = [3];
  map.__dpMovableGeneration = 1;
  window.__dpPrepareParallax(map, client);
  assert.equal(map.__dpParallax.roots.length, 0);
  assert.equal(holder.icons_dirty, true, 'remove layers on the next world packet');
});

test('DMI frame reuse preserves moving flicked and layered appearances', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const first = {}, next = {};
  let frame = first;
  const client = { currentTime: 4, iconInfoMap: { $index: () => ({ IconAt$4: () => frame }) } };
  const atom = { _appearance: { core: { iconId: 7, iconState: 'blink', dir: 2 } }, creationTime: 0,
    _mapicons: [{ icon: first }], get$moving: () => false };
  assert.equal(window.__dpDmiFrameChanged(atom, client), false);
  frame = next;
  assert.equal(window.__dpDmiFrameChanged(atom, client), true);
  frame = first;
  atom.flick = {};
  assert.equal(window.__dpDmiFrameChanged(atom, client), true);
  atom.flick = null;
  atom._appearance.overlays = [{}];
  assert.equal(window.__dpDmiFrameChanged(atom, client), true);
  atom._appearance.overlays = null;
  atom.get$moving = () => true;
  assert.equal(window.__dpDmiFrameChanged(atom, client), true);
});

test('gamepad polling reads the pad list instead of an undefined pad', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const source = window.__dpPatchSkin('gamepad', 'wa = pi.active; pi.active = !!(pad = pad[stick]);');
  assert.equal(source, 'wa = pi.active; pi.active = !!(pad = pads[stick]);');
});

test('browse windows opened without a titlebar hide the popup title', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const source = window.__dpPatchSkin('pop', 'var t={winset(o){applied=o;}}; if(opts) t.winset(opts);');
  const applied = vm.runInNewContext(`var applied; ${source}; applied`, { opts: { titlebar: '0', canResize: '0' } });
  assert.equal(applied.showTitle, '0');
});

test('popups keep the position TGUI gave them and stay on screen', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const source = window.__dpPatchSkin('pop', [
    "var fn={pos:function(v){byond.css(p, {left:v.x-cp.x+'px', top:v.y-cp.y+'px'});},",
    "size:function(v){byond.css(s, {width:v.x+'px', height:v.y+'px'});},",
    "show:function(){var t=this;byond.css(t.top,{\n\t\t\t\tleft: (window.innerWidth-sz.x)/2-cp.x+'px',\n\t\t\t\ttop: (window.innerHeight-sz.y)/2-cp.y+'px'\n\t\t\t});",
    "t._checkZ();\n\t\t\tif(h) h.onshow();}};",
  ].join(''));
  const view = { innerWidth: 1600, innerHeight: 1000 };
  const p = { ownerDocument: { defaultView: view }, isConnected: false, offsetLeft: 0, offsetTop: 0, offsetWidth: 0, offsetHeight: 0, style: {} };
  const apply = styles => {
    if (styles.width) { p.offsetWidth = parseInt(styles.width, 10); p.offsetHeight = parseInt(styles.height, 10); }
    if (styles.left) { p.offsetLeft = parseInt(styles.left, 10); p.offsetTop = parseInt(styles.top, 10); p.style.left = styles.left; p.style.top = styles.top; }
  };
  const context = { window, byond: { css(element, styles) { apply(styles); } }, p, s: {}, c: {}, cp: { x: 0, y: 0 }, sz: { x: 0, y: 0 }, h: null };
  const fn = vm.runInNewContext(`${source}; fn`, context);
  const pop = { top: p, _checkZ() {} };
  fn.size({ x: 1000, y: 600 });
  fn.show.call(pop);
  assert.deepEqual([p.style.left, p.style.top], ['300px', '200px']);
  const placed = { ...context, c: {} };
  const fn2 = vm.runInNewContext(`${source}; fn`, placed);
  p.isConnected = true;
  fn2.pos({ x: 294, y: 150 });
  fn2.show.call(pop);
  assert.deepEqual([p.style.left, p.style.top], ['294px', '150px']);
  fn2.pos({ x: 1400, y: 900 });
  assert.deepEqual([p.style.left, p.style.top], ['600px', '400px']);
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
  assert.equal(window.__dpExpandCommand('keyDown "W" [[mapwindow.map.mouse-pos]] [[mapwindow.map.size]]'), 'keyDown "W" 320 240 640 480');
  move({ clientX: 2000, clientY: -5 });
  assert.equal(window.__dpExpandCommand('keyUp "W" [[mapwindow.map.mouse-pos]] [[mapwindow.map.size]]'), 'keyUp "W" 640 0 640 480');
  assert.equal(window.__dpExpandCommand('say "[[not a placeholder]]"'), 'say "[[not a placeholder]]"');
  assert.equal(window.__dpExpandCommand('keyDown O [[mapwindow.map.mouse-pos]] [[mapwindow.map.size]]'), 'keyDown "O" 640 0 640 480');
  assert.equal(window.__dpExpandCommand('keyUp Shift 1 2 3 4'), 'keyUp "Shift" 1 2 3 4');
});

test('key macros use the exact verb name', () => {
  const window = { byond: { skin: { find: () => null } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, TextEncoder });
  assert.equal(window.__dpExpandCommand('KeyDown "W" 1 2 3 4'), 'keyDown "W" 1 2 3 4');
  assert.equal(window.__dpExpandCommand('KEYUP Shift 1 2 3 4'), 'keyUp "Shift" 1 2 3 4');
  assert.equal(window.__dpExpandCommand('KeyDown " 1 2 3 4'), 'keyDown "\\"" 1 2 3 4');
  assert.equal(window.__dpExpandCommand('keyboard 1'), 'keyboard 1');
});

test('key macros bypass the command parser as immediate topics', () => {
  const window = { byond: { skin: { find: () => null } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, URLSearchParams, Date });
  const sent = [];
  const client = { sendTopicMessage$1(topic) { if (!window.__dpScheduleTopic(client, topic)) sent.push(topic); } };
  for (let index = 0; index < 10; index++) assert.equal(window.__dpExpandCommand('KeyDown "W" 1 2 3 4', client), null);
  assert.equal(window.__dpExpandCommand('keyUp Shift 5 -6 7 8', client), null);
  assert.equal(window.__dpExpandCommand('KeyDown "\\"" 1 2 3 4', client), null);
  assert.equal(sent.length, 12);
  assert.equal(sent[0], '?dp_key=W&x=1&y=2&w=3&h=4');
  assert.equal(sent[10], '?dp_key=Shift&x=5&y=-6&w=7&h=8&dp_up=1');
  assert.equal(new URLSearchParams(sent[11].slice(1)).get('dp_key'), '"');
  assert.equal(window.__dpExpandCommand('say "hi"', client), 'say "hi"');
});

test('typed commands use the exact spelling of a known verb', () => {
  const window = { byond: { skin: { find: () => null } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, URLSearchParams, Date });
  const cells = ['OOC', 'Сказать', 'Полный экран', 'Cast', 'cast'].map(name => ({ hashMapCellValue: { _webclient$_name: name } }));
  cells.forEach((cell, index) => { cell._next = cells[index + 1]; });
  const client = { verbs: { _first: cells[0] }, sendTopicMessage$1() {} };
  assert.equal(window.__dpExpandCommand('ooc "hi there"', client), 'OOC "hi there"');
  assert.equal(window.__dpExpandCommand('сказать "привет"', client), 'Сказать "привет"');
  assert.equal(window.__dpExpandCommand('полный-ЭКРАН', client), 'Полный-экран');
  assert.equal(window.__dpExpandCommand('Полный экран', client), 'Полный экран');
  assert.equal(window.__dpExpandCommand('cast', client), 'cast');
  assert.equal(window.__dpExpandCommand('CAST', client), 'Cast');
  assert.equal(window.__dpExpandCommand('.winset "a=1"\nooc "x"', client), '.winset "a=1"\nOOC "x"');
  assert.equal(window.__dpExpandCommand('Hotkeys-Help', client), 'Hotkeys-Help');
  assert.equal(window.__dpExpandCommand('ooc "x"'), 'ooc "x"');
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
  assert.deepEqual(delivered, topics.slice(0, 6));
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
  assert.equal(window.__dpScreenLoc('CENTER'), 'CENTER,CENTER');
  assert.equal(window.__dpScreenLoc('map2:CENTER'), 'map2:CENTER,CENTER');
  assert.equal(window.__dpScreenLoc('CENTER:5'), 'CENTER:5');
  assert.equal(window.__dpScreenLoc('CENTER: 16,SOUTH+1:5'), 'CENTER:16,SOUTH+1:5');
});

test('non-Latin layouts send the key code of the physical key', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, URLSearchParams });
  const press = (key, code, keyCode) => {
    const event = { key, code, keyCode, which: keyCode };
    window.__dpLatinKeyCode(event);
    return [event.keyCode, event.which];
  };
  assert.deepEqual(press('ф', 'KeyA', 0), [65, 65]);
  assert.deepEqual(press('ц', 'KeyW', 1062), [87, 87]);
  assert.deepEqual(press('б', 'Comma', 0), [188, 188]);
  assert.deepEqual(press('"', 'Digit2', 50), [50, 50]);
  assert.deepEqual(press('a', 'KeyA', 65), [65, 65]);
  assert.deepEqual(press('Enter', 'Enter', 13), [13, 13]);
});

test('maptext uses the map style classes and ignores transparent colors', () => {
  const span = () => ({
    classList: ['maptext'], attributes: { class: 'maptext', style: 'color:rgba(0,0,0,0.000);text-align:center' },
    getAttribute(name) { return this.attributes[name] ?? null; },
    setAttribute(name, value) { this.attributes[name] = value; },
    removeAttribute(name) { delete this.attributes[name]; },
  });
  const map = { getAttribute() { return 'pos=0,0;style=".maptext { font-family: \'Grand9K Pixel\'; color: white; } .other, .maptext { font-size: 6pt }";zoom=0'; } };
  const document = {
    querySelector() { return map; },
    createElement() {
      const element = span();
      return { content: { querySelectorAll() { return [element]; } }, set innerHTML(value) { this.source = value; }, get innerHTML() { return element.attributes.style; } };
    },
  };
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, document });
  const base = "font-family:'Grand9K Pixel';color:white;font-size:6pt;";
  assert.equal(window.__dpMaptextHtml('<span class="maptext">x</span>'), `<span style="${base}">${base}text-align:center</span>`);
  assert.equal(window.__dpMaptextHtml("<font face='Small Fonts'>2</font>"), `${base}text-align:center`);
  assert.equal(window.__dpMaptextHtml(''), '');
});

test('maptext outlines follow the DreamSeeker outline style', () => {
  const window = {};
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window });
  const format = { strokeWidth: 0, strokeColor: 0 };
  window.__dpTextOutline(format, '1px black');
  assert.deepEqual(format, { strokeWidth: 1, strokeColor: 'black' });
  window.__dpTextOutline(format, '2px sharp rgb(0, 0, 0)');
  assert.deepEqual(format, { strokeWidth: 2, strokeColor: 'rgb(0, 0, 0)' });
  window.__dpTextOutline(format, undefined);
  assert.equal(format.strokeWidth, 2);
});

test('maptext line breaks survive the text-only renderer without doubling newlines', () => {
  const window = {};
  const document = { querySelector: () => null,
    createElement: () => ({ innerHTML: '', content: { querySelectorAll: () => [] } }) };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, document });
  assert.equal(window.__dpMaptextHtml('ВРЕМЯ<br>12:34'), 'ВРЕМЯ\n12:34');
  assert.equal(window.__dpMaptextHtml('ВРЕМЯ<br/>\n12:34'), 'ВРЕМЯ\n12:34');
  assert.equal(window.__dpMaptextHtml('A<BR /><br>B'), 'A\n\nB');
  assert.equal(window.__dpMaptextSize('8px', 12, 4 / 3), 8);
  assert.equal(window.__dpMaptextSize('6pt', 12, 4 / 3), 8);
  assert.equal(window.__dpMaptextSize('50%', 30, 4 / 3), 6.67);
  assert.equal(window.__dpMaptextSize('invalid', 12, 4 / 3), 12);
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
