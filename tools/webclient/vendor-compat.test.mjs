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
  const start = patched.indexOf('call$1: [function(s) { var m, t1, idx, exception; s = window.__dpExpandCommand(s);');
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
  const text = { icon: { _height: 75, _text: 'Delta' }, iconOffsetX: null, iconOffsetY: null, pixel_w: 12, pixel_z: 5, copyPos$2: copyPos };
  const plain = { icon: { _height: 32, _text: null }, iconOffsetX: 3, iconOffsetY: -4, copyPos$2: copyPos };
  const tv = { icon: { _height: 96 }, iconOffsetX: 0, iconOffsetY: -96, overlays: [plain, text], copyPos$2: copyPos };
  tv.copyPos$2(10, 200);
  assert.deepEqual([tv.baseX, tv.baseY], [10, 104]);
  assert.deepEqual([text.baseX, text.baseY], [12, 16]);
  assert.deepEqual([plain.baseX, plain.baseY], [3, -4]);
});
