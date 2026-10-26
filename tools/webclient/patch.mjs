const BASE = '(window.location.origin + window.__dpNative)';
const WS_BASE = '((window.location.protocol === "https:" ? "wss://" : "ws://") + window.location.host + window.__dpNative)';

const RULES = [
  {
    name: 'browser message origin excludes the gateway path',
    pattern: /t2 !== "http:\/\/" \+ H\.S\(t1\.host\) \+ ":" \+ H\.S\(\$\.me\.port\)/g,
    replace: 't2 !== window.location.origin',
    min: 1,
  },
  {
    name: 'generated document base keeps a trailing slash',
    pattern: /base\.setAttribute\("href", "http:\/\/" \+ H\.S\(\$\.me\.host\) \+ ":" \+ H\.S\(\$\.me\.port\)\)/g,
    replace: `base.setAttribute("href", ${BASE} + "/")`,
    min: 1,
  },
  {
    name: 'http base',
    pattern: /"http:\/\/" \+ H\.S\([\w$.]+\.host\) \+ ":" \+ H\.S\([\w$.]+\.port\)/g,
    replace: BASE,
    min: 10,
  },
  {
    name: 'http base (string add)',
    pattern: /C\.JSString_methods\.\$add\("http:\/\/", \$\.me\.host\) \+ ":" \+ J\.toString\$0\$\(\$\.me\.port\)/g,
    replace: BASE,
    min: 1,
  },
  {
    name: 'websocket base',
    pattern: /"ws:\/\/" \+ H\.S\(this\.host\) \+ ":" \+ H\.S\(this\.port\)/g,
    replace: WS_BASE,
    min: 1,
  },
];

const SELF_KEY_RULES = [
  {
    name: 'key origin check',
    pattern: /J\.endsWith\$1\$s\(t2, "\.byond\.com"\)/g,
    replace: '(e.source === window.parent && e.origin === window.location.origin)',
    min: 1,
  },
];

const STATUS_RULES = [
  {
    name: 'keep loaded browser windows alive when hidden or moved',
    pattern: /\$\.\$get\$ByondJS_skin\(\)\.defineClass\$4\(\$name, js,/g,
    replace: '$.$get$ByondJS_skin().defineClass$4($name, window.__dpPatchSkin($name, js),',
    min: 1,
  },
  {
    name: 'preserve loaded frames when moving controls backstage',
    pattern: /N\.ByondJS_backstage\(\)\.appendChild\((e|\$top)\)/g,
    replace: 'window.__dpMoveControl(N.ByondJS_backstage(), $1)',
    min: 3,
  },
  {
    name: 'provide browser DPI and URL to native winget calls',
    pattern: /\$\.\$get\$ByondJS_skin\(\)\.winget\$2\(ctrlName, obj\);/g,
    replace: 'var dpDpiRequested = obj.hasProperty$1("dpi"), dpUrlRequested = obj.hasProperty$1("url"); $.$get$ByondJS_skin().winget$2(ctrlName, obj); if (!ctrlName) { if (dpDpiRequested) obj.$indexSet(0, "dpi", String(96 * (window.devicePixelRatio || 1))); if (dpUrlRequested) obj.$indexSet(0, "url", window.location.href); }',
    min: 1,
  },
  {
    name: 'coalesce initial stat tab notifications',
    pattern: /msg = N\.ByondMessage\$\(129\);/g,
    replace: 'if (window.__dpScheduleTopic(this, topic)) return; msg = N.ByondMessage$(129);',
    min: 1,
  },
  {
    name: 'report DreamSeeker control types for winexists',
    pattern: /value = obj\.\$index\(0, property\);/g,
    replace: 'value = obj.$index(0, property); if (property === "type" && typeof value === "string") value = value.toUpperCase();',
    min: 1,
  },
  {
    name: 'browse into an existing window browser control',
    pattern: /if \(control != null && !N\.ByondJS_toBool\(J\.\$index\$asx\(J\.\$index\$asx\(control, "config"\), "acceptBrowse"\), false\)\)\s*control = null;/g,
    replace: 'if (control != null && !N.ByondJS_toBool(J.$index$asx(J.$index$asx(control, "config"), "acceptBrowse"), false)) control = this.find$2(0, id + ".browser", "browser");',
    min: 1,
  },
  {
    name: 'send a complete Topic query to Dream Daemon',
    pattern: /sendTopicMessage\$1: function\(topic\) \{/g,
    replace: 'sendTopicMessage$1: function(topic) { if (topic.charAt(0) !== "?") topic = "?" + topic;',
    min: 1,
  },
  {
    name: 'decode BYOND 516 UTF-8 strings',
    pattern: /(getString\$1: function\(_, strlen\) \{[\s\S]*?)return C\.Latin1Codec_false\.decode\$1\(bytes\);/g,
    replace: '$1return new TextDecoder("utf-8").decode(bytes);',
    min: 1,
  },
  {
    name: 'encode BYOND 516 UTF-8 strings with byte lengths',
    pattern: /send\$1: function\(_, socket\) \{\s*var t1, t2, _i, elem;/g,
    replace: 'send$1: function(_, socket) { var t1, t2, _i, elem; window.__dpEncodeMessage(this);',
    min: 1,
  },
  {
    name: 'load gameplay resources on demand',
    pattern: /this\.cacheQueue\.add\$1\(0, new N\.CacheItem\(url, C\.JSInt_methods\.toString\$0\(val\), type, val0, 0, 0, false\)\);/g,
    replace: '',
    min: 1,
  },
  {
    name: 'resource failure diagnostics',
    pattern: /return this\.\$this\.failed\$1\(this\._box_0\.c\);/g,
    replace: 'P.print("Cache request error: " + H.S(e)); return this.$this.failed$1(this._box_0.c);',
    min: 1,
  },
  {
    name: 'continue resource queue after a failed request',
    pattern: /\$\.me\.updateLoader\$1\(c\.bytes - c\.received\);/g,
    replace: '$.me.updateLoader$1(c.bytes - c.received); P.print("Cache load failed: " + c.url); if (this._requested.length < 4) this.next$0();',
    min: 1,
  },
  {
    name: 'authentication status',
    pattern: /this\.server_has_key = true;/g,
    replace: 'this.server_has_key = true; window.parent.postMessage({type:"dp-client",stage:"authenticated"}, window.location.origin);',
    min: 1,
  },
  {
    name: 'quit status',
    pattern: /line = "Quit: code " \+ val;/g,
    replace: 'line = "Quit: code " + val; window.parent.postMessage({type:"dp-client",stage:"quit",code:val}, window.location.origin);',
    min: 1,
  },
  {
    name: 'socket close status',
    pattern: /P\.print\("Socket: close"\);/g,
    replace: 'P.print("Socket: close"); window.parent.postMessage({type:"dp-client",stage:"closed"}, window.location.origin);',
    min: 1,
  },
];

export function patchWebclient(source, { selfKey = false } = {}) {
  let out = source;
  for (const rule of RULES.concat(selfKey ? SELF_KEY_RULES : [], STATUS_RULES)) {
    const count = (out.match(rule.pattern) || []).length;
    if (count < rule.min) {
      throw new Error(`webclient patch "${rule.name}" matched ${count} times, expected at least ${rule.min}`);
    }
    out = out.replace(rule.pattern, rule.replace);
  }
  const leftovers = out.match(/"http:\/\/"/g);
  if (leftovers) {
    console.warn(`[patch] ${leftovers.length} hardcoded scheme literal(s) left untouched`);
  }
  return out;
}
