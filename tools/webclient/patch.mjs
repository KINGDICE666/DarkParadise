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
    replace: 'var dpDpiRequested = obj.hasProperty$1("dpi"), dpUrlRequested = obj.hasProperty$1("url"); if (typeof ctrlName === "string" && ctrlName.indexOf(";") >= 0) { var dpIds = ctrlName.split(";"), dpProps = P.List_List$from(N.ByondJS_keys(obj), true, null), dpAll = P.JsObject_JsObject$jsify(P.LinkedHashMap__makeEmpty()); for (var dpI = 0; dpI < dpIds.length; ++dpI) { var dpId = dpIds[dpI].trim(); if (!dpId) continue; var dpOne = P.JsObject_JsObject$jsify(P.LinkedHashMap__makeEmpty()); for (var dpJ = 0; dpJ < dpProps.length; ++dpJ) dpOne.$indexSet(0, dpProps[dpJ], ""); $.$get$ByondJS_skin().winget$2(dpId, dpOne); var dpKeys = P.List_List$from(N.ByondJS_keys(dpOne), true, null); for (var dpK = 0; dpK < dpKeys.length; ++dpK) dpAll.$indexSet(0, dpId + "." + dpKeys[dpK], dpOne.$index(0, dpKeys[dpK])); } obj = dpAll; } else { $.$get$ByondJS_skin().winget$2(ctrlName, obj); if (!ctrlName) { if (dpDpiRequested) obj.$indexSet(0, "dpi", "1"); if (dpUrlRequested) obj.$indexSet(0, "url", window.location.href); } }',
    min: 1,
  },
  {
    name: 'show and hide the popup that holds a browser window',
    pattern: /N\.ByondJS_css\(\[e, "display", vis \? "" : "none"\]\);/g,
    replace: 'N.ByondJS_css([e, "display", vis ? "" : "none"]); if (b == null || b === "") { var dpPop = c.callMethod$2("_pop", []); if (dpPop != null) N.ByondJS_css([J.$index$asx(dpPop, "top"), "display", vis ? "" : "none"]); }',
    min: 1,
  },
  {
    name: 'do not glide atoms whose appearance has not arrived yet',
    pattern: /(t2\.name = t1 != null \? t1\.name : "";)(\s*c = t1\.core;)/g,
    replace: '$1 if (t1 == null) return;$2',
    min: 1,
  },
  {
    name: 'fold lighting planes into one multiplied lighting layer',
    pattern: /icons\.push\(ic\);/g,
    replace: 'if (window.__dpMapIcon(ic, base, inf, C.List_eLp)) icons.push(ic);',
    min: 1,
  },
  {
    name: 'keep lighting fields when map atoms are reused',
    pattern: /this\._blendMode = o\._blendMode;/g,
    replace: 'this._blendMode = o._blendMode; this.blendModeNum = o.blendModeNum; this.__dpLight = o.__dpLight; this.__dpEmissive = o.__dpEmissive;',
    min: 1,
  },
  {
    name: 'draw turf lighting from the raw corner weights',
    pattern: /t1\.bitmapData = hasIcon \? this\.icon\.get\$bitmapData\(\) : null;/g,
    replace: 't1.bitmapData = hasIcon ? this.icon.get$bitmapData() : null; var dpLit = this.__dpLight === true && window.__dpApplyLight(this, A.BitmapData_BitmapData);',
    min: 1,
  },
  {
    name: 'turn emissives into light',
    pattern: /t1 = this\.color;(\s*if \(t1 != null && !t1\.get\$isWhite\(\)\) \{\s*t1 = this\.color;\s*t2 = t1\.matrix;)/g,
    replace: 'if (this.__dpEmissive) this._filters.push(D.ColorMatrixFilter$([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], [255, 255, 255, 0])); t1 = dpLit || this.__dpEmissive ? null : this.color;$1',
    min: 1,
  },
  {
    name: 'keep idle background tabs connected',
    pattern: /this\.activityTimer = P\.Timer_Timer\$periodic\(P\.Duration\$\(0, 0, 0, 0, 0, 120\), this\.get\$handleTimer\(\)\);/g,
    replace: 'this.activityTimer = P.Timer_Timer$periodic(P.Duration$(0, 0, 0, 0, 0, 30), this.get$handleTimer()); window.__dpKeepAlive(this);',
    min: 1,
  },
  {
    name: 'skip empty plane masters instead of flattening zero-size planes',
    pattern: /--i;\s*m\.UpdateChildren\$1\(subs\);\s*continue;/g,
    replace: '--i; m.UpdateChildren$1(subs); if (subs.length === 0) { m._visible = false; m.__dpEmpty = true; } else if (m.__dpEmpty) { m._visible = true; m.__dpEmpty = false; } continue;',
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
    replace: 'if (control != null && !N.ByondJS_toBool(J.$index$asx(J.$index$asx(control, "config"), "acceptBrowse"), false)) { control = this.find$2(0, id + ".browser", "browser"); var dpOptions = obj.$index(0, "options"); if (control != null && dpOptions != null && J.$index$asx(dpOptions, "titlebar") != null) this.winset$2(id, P.JsObject_JsObject$jsify(P.LinkedHashMap__makeLiteral(["titlebar", J.$index$asx(dpOptions, "titlebar")]))); }',
    min: 1,
  },
  {
    name: 'run client-side output and expand map placeholders before sending input',
    pattern: /call\$1: \[function\(s\) \{\s*var m, t1, idx, exception;\s*t1 = s;/g,
    replace: 'call$1: [function(s) { var m, t1, idx, exception; s = window.__dpExpandCommand(s, $.me); if (s == null) return; t1 = s;',
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
    name: 'load gameplay resources on demand except map fonts',
    pattern: /this\.cacheQueue\.add\$1\(0, new N\.CacheItem\(url, C\.JSInt_methods\.toString\$0\(val\), type, val0, 0, 0, false\)\);/g,
    replace: 'if (type === ".ttf" || type === ".otf") this.cacheQueue.add$1(0, new N.CacheItem(url, C.JSInt_methods.toString$0(val), type, val0, 0, 0, false));',
    min: 1,
  },
  {
    name: 'accept BYOND 515 screen edge keywords',
    pattern: /(ScreenCorner: \{\s*"\^": "[^"]*",\s*Parse\$1: function\(str\) \{\s*var [^;]+;)/g,
    replace: '$1 str = window.__dpScreenLoc(str);',
    min: 1,
  },
  {
    name: 'apply map style classes to maptext',
    pattern: /(HtmlField\$2: function\(str, map\) \{\s*var [^;]+;)/g,
    replace: '$1 str = window.__dpMaptextHtml(str);',
    min: 1,
  },
  {
    name: 'place maptext overlays from the bottom-left of their icon',
    pattern: /this\.overlays\[i0\]\.copyPos\$2\(0, 0\);/g,
    replace: '{ this.overlays[i0].copyPos$2(0, 0); var dpText = this.overlays[i0]; if (dpText.icon != null && dpText.icon._text != null) { dpText.baseX = dpText.iconOffsetX != null ? dpText.iconOffsetX : dpText.pixel_w; dpText.baseY = (dpText.iconOffsetY != null ? dpText.iconOffsetY : -dpText.pixel_z) + (this.icon != null ? this.icon._height : $.me.iconHeight) - dpText.icon._height; } }',
    min: 1,
  },
  {
    name: 'read the maptext outline style',
    pattern: /(value = style\.\$index\(0, "vertical-align"\);\s*if \(value != null\) \{\s*this\._valign = value;\s*this\._refreshPending \|= 3;\s*\})/g,
    replace: '$1 window.__dpTextOutline(fmt, style.$index(0, "-dm-text-outline"));',
    min: 1,
  },
  {
    name: 'stroke each maptext span once at its own position',
    pattern: /for \(t2 = t1\.length, _i = 0; _i < t1\.length; t1\.length === t2 \|\| \(0, H\.throwConcurrentModificationError\)\(t1\), \+\+_i\) \{\s*lm0 = t1\[_i\];\s*context\.strokeText\(text, lm0\._x, lm0\._y \+ offsetY\);\s*\}/g,
    replace: 'context.lineJoin = "round"; context.strokeText(text, lm._x + offsetX, lm._y + offsetY);',
    min: 1,
  },
  {
    name: 'space maptext lines by the font height like DreamSeeker',
    pattern: /C\.JSNumber_methods\.round\$0\(fontStyleMetricsAscent \* this\.lineSpacing\)/g,
    replace: 'C.JSNumber_methods.round$0(fontStyleMetricsAscent + fontStyleMetricsDescent)',
    min: 1,
  },
  {
    name: 'maptext percent font sizes are relative to 10pt like DD output',
    pattern: /return C\.JSNumber_methods\.round\$0\(this\._textFormats\[0\]\.size \* val\) \/ 100;/g,
    replace: 'return C.JSNumber_methods.round$0(N.ByondJS_toPx("pt") * 10 * val) / 100;',
    min: 1,
  },
  {
    name: 'trim maptext inline style values',
    pattern: /map\.\$indexSet\(0, J\.toLowerCase\$0\$s\(J\.trim\$0\$s\(L2\[0\]\)\), L2\[1\]\);/g,
    replace: 'map.$indexSet(0, J.toLowerCase$0$s(J.trim$0$s(L2[0])), J.trim$0$s(L2[1]));',
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
