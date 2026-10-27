import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';
import { patchWebclient } from './patch.mjs';

const vendorFile = process.env.BYOND_WEBCLIENT_JS;
const patched = vendorFile ? patchWebclient(fs.readFileSync(vendorFile, 'utf8'), { selfKey: true }) : null;

function method(name, nextName, context) {
  const start = patched.indexOf(`${name}: function`);
  assert.notEqual(start, -1);
  const end = patched.indexOf(`\n      ${nextName}:`, start);
  assert.ok(end > start);
  return vm.runInNewContext('(' + patched.slice(start + name.length + 2, end).replace(/,\s*$/, '') + ')', context);
}

function protocol() {
  const sent = [];
  function MessageElem(val, func) { this.val = val; this.func = func; }
  return {
    sent,
    N: {
      MessageElem,
      ByondMessage$(type) {
        return { _elems: [], _pos: 2, get$_putString() {}, get$_putUint32() {}, get$_putUint16() {}, get$_putUTFString() {},
          send$1() { sent.push({ type, values: this._elems.map(item => item.val) }); } };
      },
    },
  };
}

test('the patched vendor remains valid JavaScript', { skip: !patched }, () => {
  new vm.Script(patched);
  const appearanceFlags = patched.slice(patched.indexOf('Appearance$fromMsg$1: function'), patched.indexOf('Appearance$fromMsg$1: function') + 2500);
  assert.ok(!appearanceFlags.includes('isScreen'), 'appearance flags keep their separate original format');
});

test('world packets preserve adjacent full references, vis_contents and reentry; HUD stays byte-sized', { skip: !patched }, () => {
  const atoms = new Map();
  const me = { stage: {}, infoMap: {
    $index: (_, id) => atoms.get(id), $indexSet: (_, id, atom) => atoms.set(id, atom),
  } };
  const arrays = {
    remove$1(list, id) { const i = list.indexOf(id); if (i >= 0) list.splice(i, 1); },
    contains$1: (list, id) => list.includes(id), add$1: (list, id) => list.push(id),
  };
  const read = method('readMovableChanges$3$isScreen', 'readMovableChanges$2', {
    $: { me }, C: { JSArray_methods: arrays },
    N: { AtomInfo$(id) { return { id, addPendingImages$0() {}, prepareTick$1() {} }; } },
    P: { List_List$from: list => [...list] },
  });
  const state = { movs: [], screen: [], viewChanged: true };
  function packet(records, screen = false) {
    const bytes = [];
    const u16 = n => bytes.push(n & 255, (n >>> 8) & 255);
    const u32 = n => { u16(n); u16(n >>> 16); };
    u16(records.length);
    for (const record of records) {
      if (screen) bytes.push(record.flags); else u16(record.flags);
      u32(record.id);
      if (record.flags & 256) { u16(record.children.length); record.children.forEach(u32); }
    }
    const data = new DataView(Uint8Array.from(bytes).buffer);
    const msg = { _pos: 0, _webclient$_data: data,
      getUint16$0() { const n = data.getUint16(this._pos, true); this._pos += 2; return n; },
      getUint32$0() { const n = data.getUint32(this._pos, true); this._pos += 4; return n; },
    };
    read.call(state, msg, screen ? state.screen : state.movs, screen);
    assert.equal(msg._pos, data.byteLength, 'consume exactly the complete packet');
  }
  const first = 0x0200b9d4, second = first + 1, child = 0x0200ba99;
  packet([{ flags: 258, id: first, children: [child] }, { flags: 2, id: second }]);
  assert.deepEqual(state.movs, [first, second]);
  assert.deepEqual(Array.from(atoms.get(first).__dpVisContents), [child]);
  packet([{ flags: 0, id: first }]);
  assert.deepEqual(state.movs, [second]);
  packet([{ flags: 258, id: first, children: [] }, { flags: 2, id: first }]);
  assert.deepEqual(state.movs, [second, first], 'restore a cached atom once');
  assert.deepEqual(Array.from(atoms.get(first).__dpVisContents), [], 'clear removed children');
  packet([{ flags: 0, id: first }, { flags: 2, id: first }]);
  assert.deepEqual(state.movs, [second, first], 'remove then reenter within one packet');
  packet([{ flags: 2, id: 0x04000123 }], true);
  assert.deepEqual(state.screen, [0x04000123]);
  packet([{ flags: 0, id: 0x04000123 }], true);
  assert.deepEqual(state.screen, []);
  packet([{ flags: 2, id: 0x04000123 }], true);
  assert.equal(atoms.get(0x04000123).onScreen, true, 'show cached HUD atoms again');
});

test('real vendor Topic messages contain one query prefix', { skip: !patched }, () => {
  const transport = protocol();
  const sendTopic = method('sendTopicMessage$1', 'getIconInfo$1', {
    N: transport.N, P: { print() {} }, window: { __dpScheduleTopic() { return false; } },
  });
  const client = { loggedIn: true, socket: {} };
  sendTopic.call(client, 'type=ready&tgui=1&window_id=browseroutput');
  sendTopic.call(client, '?type=ready&tgui=1&window_id=statbrowser');
  assert.deepEqual(transport.sent.map(packet => packet.values[0]), [
    '?type=ready&tgui=1&window_id=browseroutput', '?type=ready&tgui=1&window_id=statbrowser',
  ]);
});

test('real vendor winget reports BROWSER and preserves requested global properties', { skip: !patched }, () => {
  function check(control, requested) {
    const transport = protocol();
    const create = () => ({
      values: {}, $index(_, key) { return this.values[key]; }, $indexSet(_, key, value) { this.values[key] = value; },
      hasProperty$1(key) { return Object.hasOwn(this.values, key); },
    });
    const sizes = { 'mainwindow.split': '1280x720', mapwindow: '900x720' };
    const get = method('processWingetMessage$1', 'sendStats$0', {
      N: { ...transport.N, ByondJS_keys(obj) { return Object.keys(obj.values); } },
      P: { JsObject_JsObject$jsify: create, LinkedHashMap__makeEmpty() {}, List_List$from(values) { return [...values]; } },
      $: { $get$ByondJS_skin() { return { winget$2(id, obj) {
        if (sizes[id]) obj.values.size = sizes[id];
        else if (id) obj.values.type = 'browser';
        else obj.values = {};
      } }; } },
      J: { toString$0$(value) { return String(value); } },
      window: { devicePixelRatio: 1.5, location: { href: 'https://game.example/game/' } },
    });
    const names = requested.slice();
    get.call({}, {
      _pos: 0, _webclient$_data: { getUint16() { return 3; } },
      getUint32$0() { return 7; }, getUTFString$0() { return control; }, getUint16$0() { return requested.length; },
      getString$1() { return names.shift(); },
    });
    return transport.sent[0].values;
  }
  assert.deepEqual(check('statbrowser', ['type']), [7, 1, 'type', 'BROWSER']);
  assert.deepEqual(check('', ['dpi', 'url']), [7, 2, 'dpi', '1', 'url', 'https://game.example/game/']);
  assert.deepEqual(check('mainwindow.split;mapwindow', ['size']),
    [7, 2, 'mainwindow.split.size', '1280x720', 'mapwindow.size', '900x720']);
});

test('real vendor input expands map placeholders and runs output locally', { skip: !patched }, () => {
  const start = patched.indexOf('call$1: [function(s) { var m, t1, idx, exception; s = window.__dpExpandCommand(s, $.me);');
  assert.notEqual(start, -1);
  const end = patched.indexOf(', null, null, 2, 0, null, 9, "call"]', start);
  const sent = [];
  const outputs = [];
  const winsets = [];
  const window = { byond: { skin: {
    find(id) {
      return id === 'map' ? { content() { return { getBoundingClientRect() { return { left: 10, top: 20, width: 640, height: 480 }; } }; } } : null;
    },
    output(id, params) { outputs.push([id, params.text]); },
  } } };
  vm.runInNewContext(fs.readFileSync(new URL('./public/bridge.js', import.meta.url), 'utf8'), { window, TextEncoder, URLSearchParams });
  const context = {
    window,
    J: {
      indexOf$1$asx: (s, x) => s.indexOf(x), substring$1$s: (s, a) => s.substring(a), substring$2$s: (s, a, b) => s.substring(a, b),
      $eq$: (a, b) => a === b, $index$asx: (s, i) => s[i], startsWith$1$s: (s, x) => s.startsWith(x), endsWith$1$s: (s, x) => s.endsWith(x),
      get$length$asx: s => s.length, $sub$n: (a, b) => a - b,
    },
    P: { RegExp_RegExp: source => ({ matchAsPrefix$2(_, s, at) {
      const match = new RegExp(source, 'iy');
      match.lastIndex = at;
      const found = match.exec(s);
      return found ? { get$_match: () => found } : null;
    } }) },
    N: { ByondJS_builtinCommands: () => ({ $index: (_, name) => name === 'winset' ? { call$1: value => winsets.push(value) } : null }) },
    C: { JSString_methods: { trim$0: s => s.trim() } },
    H: { unwrapException: error => error },
    $: { me: { sendCommandMessage$1: command => sent.push(command) }, $get$ByondJS_skin: () => ({ doInput$1: line => input(line) }) },
  };
  const input = vm.runInNewContext('(' + patched.slice(start + 'call$1: ['.length, end) + ')', context);
  input('keyDown "T" [[map.mouse-pos]] [[map.size]]');
  input('keyUp "T" [[missing.mouse-pos]] [[missing.size]]');
  input('.output statbrowser:set_theme dark');
  input('.output output_browser.browseroutput:update {"type":"x"}\n.winset "input.text=\\"\\""');
  assert.deepEqual(sent, ['keyDown "T" 0 0 640 480', 'keyUp "T" 0 0 0 0']);
  assert.deepEqual(outputs, [['statbrowser:set_theme', 'dark'], ['output_browser.browseroutput:update', '{"type":"x"}']]);
  assert.deepEqual(winsets, ['input.text=\\"\\"']);
});

test('real vendor places maptext overlays from the bottom-left of their icon', { skip: !patched }, () => {
  const copyPos = method('copyPos$2', 'updateScreen$0', { $: { me: { iconHeight: 32 } } });
  const text = { icon: { _height: 75, _text: 'Delta' }, iconOffsetX: 12, iconOffsetY: -5, pixel_w: 12, pixel_z: 5, copyPos$2: copyPos };
  const plain = { icon: { _height: 32, _text: null }, iconOffsetX: 3, iconOffsetY: -4, copyPos$2: copyPos };
  const tv = { icon: { _height: 96 }, iconOffsetX: 0, iconOffsetY: -96, overlays: [plain, text], copyPos$2: copyPos };
  tv.copyPos$2(10, 200);
  assert.deepEqual([tv.baseX, tv.baseY], [10, 104]);
  assert.deepEqual([text.baseX, text.baseY], [12, 16]);
  assert.deepEqual([plain.baseX, plain.baseY], [3, 60]);
});

test('grouped 64px speech bubbles and 32px underlays share their parent bottom edge', { skip: !patched }, () => {
  const copyPos = method('copyPos$2', 'updateScreen$0', { $: { me: { iconHeight: 32 } } });
  const bubble = { icon: { _height: 64 }, iconOffsetX: 0, iconOffsetY: 0, copyPos$2: copyPos };
  const marking = { icon: { _height: 32 }, iconOffsetX: 0, iconOffsetY: 3, copyPos$2: copyPos };
  const mob = { icon: { _height: 32 }, iconOffsetX: 0, iconOffsetY: -32, overlays: [bubble], underlays: [marking], copyPos$2: copyPos };
  mob.copyPos$2(0, 100);
  assert.equal(mob.baseY + bubble.baseY + 64, 100);
  assert.equal(marking.baseY, 3);
});

test('SEE_TURFS SEE_OBJS and SEE_MOBS do not expose abstract landmarks or hidden mobs', { skip: !patched }, () => {
  const me = { mapHomeZ: 0 };
  const visible = method('atomIsVisible$2', 'atomIsVisibleDefault$3', {
    $: { me }, C: { JSInt_methods: { _shrOtherPositive$1: (id, bits) => id >>> bits } },
  });
  const defaultVisible = method('atomIsVisibleDefault$3', 'atomIsVisibleDefault$2', { $: { me } });
  for (const [type, sight] of [[1, 16], [2, 8], [3, 4]]) {
    const state = { sight, seeInvisible: 60, atomIsVisibleDefault$2(atom, vis) { return defaultVisible.call(this, atom, vis, 0); } };
    for (const [invisibility, expected] of [[0, true], [60, true], [61, false], [101, false]]) {
      const atom = { id: (type << 24) + 7, x: 0, z: 0, _isVisible: true, _normalVis: true,
        set$drawDark() {},
        get$currentAppearance() { return { core: { invisibility } }; } };
      visible.call(state, atom.id, atom);
      assert.equal(atom._isVisible, expected, `type ${type}, invisibility ${invisibility}`);
    }
  }
});

test('SEE_TURFS removes cached darkness masks after leaving a living body', { skip: !patched }, () => {
  const C = { JSInt_methods: { _shrOtherPositive$1: (id, bits) => id >>> bits },
    JSArray_methods: { remove$1(list, value) { list.splice(list.indexOf(value), 1); } } };
  const visible = method('atomIsVisible$2', 'atomIsVisibleDefault$3', { $: { me: { mapHomeZ: 2 } }, C });
  const drawDark = method('set$drawDark', 'alwaysGlide$0', { C });
  const blackness = {};
  const atom = { id: 0x01000007, x: 5, z: 2, _isVisible: true, _normalVis: true,
    _drawDark: true, icons_dirty: false, _blackness: blackness, _mapicons: [blackness], set$drawDark: drawDark };
  visible.call({ sight: 16, atomIsVisibleDefault$2: () => true }, atom.id, atom);
  assert.equal(atom._drawDark, false);
  assert.equal(atom._mapicons.length, 0);
  assert.equal(atom.position_dirty, true);
});

test('an unchanged DMI frame stays scheduled for future animation ticks', { skip: !patched }, () => {
  let changed = false;
  const tick = method('tick$0', 'beginGlide$0', { $: { me: {} }, window: { __dpDmiFrameChanged: () => changed } });
  const scheduled = [];
  const atom = { glide: null, icons_dirty: false, cantick: true, get$animating: () => true,
    prepareTick$1(value) { scheduled.push(value); } };
  tick.call(atom);
  assert.equal(atom.icons_dirty, false);
  assert.equal(atom.inert, false);
  assert.deepEqual(scheduled, [true]);
  changed = true;
  tick.call(atom);
  assert.equal(atom.icons_dirty, true);
});
