(function () {
  if (!window.scheduleImmediate) window.scheduleImmediate = function (callback) { queueMicrotask(callback); };
  window.__dpMoveControl = function (container, control) {
    const hasBrowser = control.tagName === 'IFRAME' || control.querySelector?.('iframe');
    if (hasBrowser && container.moveBefore && container.isConnected && control.isConnected) {
      container.moveBefore(control, null);
      return control;
    }
    if (control.parentNode === container && container.lastChild === control) return control;
    return container.appendChild(control);
  };
  window.__dpDecodeParam = function (value) {
    try { return decodeURIComponent(value); }
    catch (_) { return unescape(value); }
  };
  window.__dpPatchSkin = function (name, source) {
    if (name === 'gamepad') source = source.replace('pi.active = !!(pad = pad[stick])', 'pi.active = !!(pad = pads[stick])');
    if (name === 'browser') source = source.replace("unescape(a[i].replace(/\\+/g,' '))", "window.__dpDecodeParam(a[i].replace(/\\+/g,' '))");
    if (name === 'pane') {
      source = source.replace('if(!this.loading) {if(v) this.popup(); else this.popdown();}', 'this.config.isVisible = v; if (!this.loading) { var existingPopup = this._pop(); if (existingPopup) existingPopup.top.style.display = v ? "" : "none"; else if (v) this.popup(); }');
    }
    if (['pane', 'pop'].includes(name)) source = source.replaceAll('byond.backstage().appendChild(t.top)', 'window.__dpMoveControl(byond.backstage(), t.top)');
    if (name === 'pop') {
      source = source.replace('if(opts) t.winset(opts);', 'if(opts && opts.titlebar != null && opts.showTitle == null) opts.showTitle = opts.titlebar; if(opts) t.winset(opts);');
      source = source.replaceAll('t.ui.contents.appendChild(e)', 'window.__dpMoveControl(t.ui.contents, e)');
      source = source.replaceAll('document.body.appendChild(t.top)', 'window.__dpMoveControl(document.body, t.top)');
      source = source.replace("byond.css(p, {left:v.x-cp.x+'px', top:v.y-cp.y+'px'});", "c._dpPlaced = true; byond.css(p, {left:v.x-cp.x+'px', top:v.y-cp.y+'px'}); window.__dpFitPop(p, false);");
      source = source.replace("byond.css(s, {width:v.x+'px', height:v.y+'px'});", "byond.css(s, {width:v.x+'px', height:v.y+'px'}); if (p.isConnected) window.__dpFitPop(p, false);");
      source = source.replace(/byond\.css\(t\.top,\{\s*left: \(window\.innerWidth-sz\.x\)\/2-cp\.x\+'px',\s*top: \(window\.innerHeight-sz\.y\)\/2-cp\.y\+'px'\s*\}\);/, 'if (!c._dpPlaced) byond.css(t.top, {left: "0px", top: "0px"});');
      source = source.replace(/t\._checkZ\(\);\s*if\(h\) h\.onshow\(\);/, 't._checkZ(); window.__dpFitPop(t.top, !c._dpPlaced); if(h) h.onshow();');
    }
    return source;
  };
  window.__dpFitPop = function (pop, center) {
    const view = pop.ownerDocument.defaultView;
    const width = pop.offsetWidth;
    const height = pop.offsetHeight;
    let left = center ? (view.innerWidth - width) / 2 : pop.offsetLeft;
    let top = center ? (view.innerHeight - height) / 2 : pop.offsetTop;
    left = Math.max(0, Math.min(left, view.innerWidth - width));
    top = Math.max(0, Math.min(top, view.innerHeight - height));
    if (left !== pop.offsetLeft) pop.style.left = Math.round(left) + 'px';
    if (top !== pop.offsetTop) pop.style.top = Math.round(top) + 'px';
  };
  const topicLimit = 6;
  const topicWindow = 1000;
  const sentTopics = [];
  const queuedTopics = [];
  const queuedTabs = [];
  const recentTabs = new Map();
  let topicTimer;
  let dispatching = false;
  function topicCapacity(now) {
    while (sentTopics.length && now - sentTopics[0] >= topicWindow) sentTopics.shift();
    return topicLimit - sentTopics.length;
  }
  function scheduleTopics(delay) {
    if (!topicTimer) topicTimer = setTimeout(flushTopics, delay);
  }
  function flushTopics() {
    topicTimer = undefined;
    const now = Date.now();
    if (topicCapacity(now) <= 0) { scheduleTopics(sentTopics[0] + topicWindow - now); return; }
    const tab = !queuedTopics.length;
    const next = queuedTopics.shift() || queuedTabs.shift();
    if (!next) return;
    dispatching = true;
    try { next.client.sendTopicMessage$1(next.topic); }
    finally {
      dispatching = false;
      if (queuedTopics.length || queuedTabs.length) scheduleTopics(tab ? 120 : 0);
    }
  }
  window.__dpScheduleTopic = function (client, topic) {
    if (directTopic) return false;
    const now = Date.now();
    if (dispatching) { sentTopics.push(now); return false; }
    const query = new URLSearchParams(topic.replace(/^\?/, ''));
    if (query.get('window_id') === 'statbrowser' && ['Send-Tabs', 'Remove-Tabs'].includes(query.get('type'))) {
      for (const [key, recent] of recentTabs) if (now - recent.time > 1000) recentTabs.delete(key);
      const tab = query.get('payload');
      if (recentTabs.get(tab)?.topic !== topic) {
        recentTabs.set(tab, { topic, time: now });
        queuedTabs.push({ client, topic });
        scheduleTopics(120);
      }
      return true;
    }
    if (!queuedTopics.length && topicCapacity(now) > 0) { sentTopics.push(now); return false; }
    queuedTopics.push({ client, topic });
    scheduleTopics(0);
    return true;
  };

  const pointer = { x: 0, y: 0 };
  if (typeof document !== 'undefined' && document.addEventListener) {
    document.addEventListener('mousemove', function (event) {
      pointer.x = event.clientX;
      pointer.y = event.clientY;
    }, true);
  }
  function controlRect(id) {
    try {
      const control = window.byond.skin.find(id);
      const element = control && (typeof control.content === 'function' ? control.content() : control.elem);
      const rect = element && element.getBoundingClientRect();
      if (rect && rect.width > 0 && rect.height > 0) return rect;
    } catch (_) {}
    return null;
  }
  function embeddedValue(id, property) {
    const rect = controlRect(id);
    if (!rect) return '0 0';
    if (property === 'size') return Math.round(rect.width) + ' ' + Math.round(rect.height);
    const x = Math.min(Math.max(pointer.x - rect.left, 0), rect.width);
    const y = Math.min(Math.max(pointer.y - rect.top, 0), rect.height);
    return Math.round(x) + ' ' + Math.round(y);
  }
  const statFallbacks = {
    set_theme: function (doc, value) {
      if (!['light', 'dark', 'ntos', 'paradise', 'syndicate'].includes(value)) return;
      doc.body.className = value === 'light' ? '' : value;
      doc.documentElement.className = value;
    },
    set_font_size: function (doc, value) { doc.body.style.setProperty('font-size', value); },
    set_font_style: function (doc, value) {
      if (value !== 'null') doc.body.style.setProperty('font-family', value);
      else doc.body.style.removeProperty('font-family');
    },
    set_tabs_style: function (doc, value) {
      const menu = doc.getElementById('menu');
      if (!menu) return;
      menu.classList.toggle('menu-wrap', value === 'default' || value === 'classic');
      menu.classList.toggle('tabs-classic', value === 'classic');
    },
  };
  function browserFrame(id) {
    try {
      const control = window.byond.skin.find(id);
      const element = control && (typeof control.content === 'function' ? control.content() : control.elem);
      if (!element) return null;
      return element.tagName === 'IFRAME' ? element : element.querySelector('iframe');
    } catch (_) { return null; }
  }
  function outputFallback(target, text) {
    const call = /^([\w.-]+):(\w+)$/.exec(target);
    const fallback = call && statFallbacks[call[2]];
    const frame = fallback && browserFrame(call[1]);
    const frameWindow = frame && frame.contentWindow;
    if (!frameWindow || typeof frameWindow[call[2]] === 'function') return false;
    const value = window.__dpDecodeParam(text.split('&')[0].replace(/\+/g, ' '));
    const apply = function () {
      const doc = frame.contentDocument;
      if (doc && doc.body && doc.getElementById('menu')) fallback(doc, value);
    };
    if (frame.contentDocument && frame.contentDocument.readyState === 'complete') apply();
    else frame.addEventListener('load', apply, { once: true });
    return true;
  }
  let directTopic = false;
  const keyCommand = /^key(down|up)\s+("(?:[^"\\]|\\.)*"|\S+)((?:\s+-?\d+){0,4})\s*$/i;
  function sendKeyTopic(client, command) {
    const match = keyCommand.exec(command);
    if (!match) return false;
    let key = match[2];
    if (key.length > 1 && key.charAt(0) === '"' && key.charAt(key.length - 1) === '"') key = key.slice(1, -1).replace(/\\(.)/g, '$1');
    const numbers = match[3].trim() ? match[3].trim().split(/\s+/) : [];
    const query = new URLSearchParams({ dp_key: key });
    ['x', 'y', 'w', 'h'].forEach(function (name, index) { if (numbers[index] != null) query.set(name, numbers[index]); });
    if (match[1].toLowerCase() === 'up') query.set('dp_up', '1');
    directTopic = true;
    try { client.sendTopicMessage$1('?' + query.toString()); }
    finally { directTopic = false; }
    return true;
  }
  function exactVerbName(client, word) {
    const wanted = word.replace(/-/g, ' ').toLowerCase();
    let found = null;
    for (let cell = client && client.verbs && client.verbs._first; cell; cell = cell._next) {
      const name = cell.hashMapCellValue && cell.hashMapCellValue._webclient$_name;
      if (typeof name !== 'string' || name.toLowerCase() !== wanted) continue;
      const dashed = name.replace(/ /g, '-');
      if (word === name || word === dashed) return word;
      found = found || dashed;
    }
    return found || word;
  }
  function exactVerbCommand(client, command) {
    return command.split('\n').map(function (line) {
      const match = /^(\s*)([^\s".][^\s"]*)([\s\S]*)$/.exec(line);
      return match ? match[1] + exactVerbName(client, match[2]) + match[3] : line;
    }).join('\n');
  }
  window.__dpExpandCommand = function (command, client) {
    if (typeof command !== 'string') return command;
    command = exactVerbCommand(client, command);
    if (command.indexOf('\n') >= 0) return command;
    const output = /^\.output\s+(\S+)\s*([\s\S]*)$/i.exec(command);
    if (output) {
      let text = output[2];
      if (text.length > 1 && text.charAt(0) === '"' && text.charAt(text.length - 1) === '"') text = text.slice(1, -1);
      if (outputFallback(output[1], text)) return null;
      try { window.byond.skin.output(output[1], { text: text }); } catch (_) {}
      return null;
    }
    const expanded = command.replace(/\[\[([\w-]+(?:\.[\w-]+)*)\.(mouse-pos|size)\]\]/g, function (_, id, property) {
      return embeddedValue(id, property);
    });
    if (client && typeof client.sendTopicMessage$1 === 'function' && sendKeyTopic(client, expanded)) return null;
    return expanded.replace(/^key(down|up)\s+(\S+)/i, function (_, direction, key) {
      const verb = direction.toLowerCase() === 'down' ? 'keyDown' : 'keyUp';
      if (key.length > 1 && key.charAt(0) === '"' && key.charAt(key.length - 1) === '"') return verb + ' ' + key;
      return verb + ' "' + key.replace(/[\\"]/g, '\\$&') + '"';
    });
  };

  const lowestPlane = -50;
  const planeRange = 107;
  const spacePlane = -21;
  const parallaxPlane = -20;
  const lightingPlane = 10;
  const overlayLightingPlane = 11;
  const emissivePlane = 13;
  const firstRenderPlate = 12;
  const lastRenderPlate = 22;
  const multiplyBlend = 4;
  const addBlend = 2;
  const mergedLightSubplane = 8;
  const keepTogetherAppearance = 67108864;
  function truePlaneOf(plane) {
    return ((plane - lowestPlane) % planeRange + planeRange) % planeRange + lowestPlane;
  }
  function isParallaxHolder(atom) {
    const core = atom && atom._appearance && atom._appearance.core;
    return Boolean(atom && atom.onScreen && atom.screenLoc && core &&
      core.plane === parallaxPlane && core.iconId === 65535 && !core.get$planeMaster());
  }
  window.__dpPrepareParallax = function (map, client) {
    let candidates = map.__dpParallaxCandidates;
    if (!candidates || candidates.generation !== map.__dpMovableGeneration) {
      const roots = [];
      for (const id of map.movs) {
        const atom = client.infoMap.$index(0, id);
        const core = atom && atom._appearance && atom._appearance.core;
        if (core && !atom.onScreen && atom.locId === 0 && core.plane === parallaxPlane) roots.push(atom);
      }
      candidates = map.__dpParallaxCandidates = { roots, generation: map.__dpMovableGeneration };
    }
    const roots = candidates.roots;
    const signature = [];
    for (const atom of roots) {
      const animation = atom._animation;
      const animating = animation && (animation.total_end == null || animation.total_end > client.currentMs);
      signature.push(atom.id, atom._appearance, atom.pixel_w, atom.pixel_z,
        animating ? client.currentMs : 0);
    }
    signature.push(client.iconInfoMap?._collection$_length);
    const old = map.__dpParallax;
    if (old && old.signature.length === signature.length && signature.every((value, i) => value === old.signature[i])) return;
    map.__dpParallax = { roots, signature };
    for (const id of map.screen) {
      const holder = client.infoMap.$index(0, id);
      if (!isParallaxHolder(holder)) continue;
      holder.icons_dirty = true;
      holder.inert = false;
      if (holder.cantick && holder.tickIndex < 0) holder.prepareTick$1(true);
    }
  };
  window.__dpParallaxAppearance = function (atom, appearance, client, clone) {
    if (!isParallaxHolder(atom)) return appearance;
    const roots = client.mapInfo.__dpParallax && client.mapInfo.__dpParallax.roots;
    if (!roots || !roots.length) return appearance;
    const result = clone(appearance, true);
    result.overlays = (result.overlays || []).concat(roots.map(function (root) {
      const layer = clone(root.get$currentAppearance(), true);
      layer.core.pixel_w += root.pixel_w || 0;
      layer.core.pixel_z += root.pixel_z || 0;
      layer.core.bits = (layer.core.bits & ~keepTogetherAppearance) >>> 0;
      layer.core.set$keepApart(true);
      return layer;
    }));
    return result;
  };
  window.__dpDmiFrameChanged = function (atom, client) {
    const appearance = atom._appearance;
    if (!appearance || appearance.overlays || appearance.underlays || atom.images?.length ||
      atom._animation || atom.flick || atom.get$moving() || atom._mapicons?.length !== 1) return true;
    const core = appearance.core;
    const sheet = client.iconInfoMap.$index(0, core.iconId);
    if (!sheet) return true;
    const frame = sheet.IconAt$4(core.iconState, false, core.dir, client.currentTime - atom.creationTime);
    return frame !== atom._mapicons[0].icon;
  };
  function setBlend(icon, mode, blends) {
    icon.blendModeNum = mode;
    icon._blendMode = blends[mode];
  }
  function isEmissiveColor(color) {
    const matrix = color && color.matrix && color.matrix.matrix;
    return Boolean(matrix) && (matrix[16] > 0 || matrix[17] > 0);
  }
  window.__dpMapIcon = function (icon, base, info, blends) {
    const plane = icon.plane;
    if (typeof plane !== 'number' || plane < -10000) return true;
    const truePlane = truePlaneOf(plane);
    const master = (icon.flags & 256) !== 0;
    const lighting = plane - truePlane + lightingPlane;
    if (truePlane === spacePlane) return true;
    if (truePlane === lightingPlane) {
      if (master) setBlend(icon, multiplyBlend, blends);
      else if (icon.info && icon.info.onScreen && base && base.iconState === 'flash' && base.blendMode !== addBlend) return false;
      else if (base && base.iconState === '' && icon.color && icon.color.matrix && info && info.still && info.still.$index(0, 'dark_lighting_object') != null) icon.__dpLight = true;
      return true;
    }
    if (truePlane === overlayLightingPlane || truePlane === emissivePlane) {
      if (master) return false;
      if (truePlane === emissivePlane) {
        if (!isEmissiveColor(icon.color)) return false;
        icon.__dpEmissive = true;
      }
      icon.plane = lighting;
      icon.subplane = (icon.subplane || 0) + mergedLightSubplane;
      setBlend(icon, addBlend, blends);
      return true;
    }
    return truePlane < firstRenderPlate || truePlane > lastRenderPlate;
  };

  const lightBasisText = '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';
  let lightBasis;
  const lightSize = 32;
  const lightCacheLimit = 4096;
  const lightBitmaps = new Map();
  function lightPixels(matrix) {
    if (!lightBasis) lightBasis = Uint8Array.from(atob(lightBasisText), function (c) { return c.charCodeAt(0); });
    const pixels = new Uint8ClampedArray(lightBasis.length);
    for (let i = 0; i < lightBasis.length; i += 4) {
      for (let channel = 0; channel < 3; channel++) {
        const row = channel * 4;
        pixels[i + channel] = lightBasis[i] * matrix[row] + lightBasis[i + 1] * matrix[row + 1] + lightBasis[i + 2] * matrix[row + 2] + lightBasis[i + 3] * matrix[row + 3] + 255 * matrix[16 + channel];
      }
      pixels[i + 3] = 255;
    }
    return pixels;
  }
  window.__dpApplyLight = function (mapAtom, makeBitmap) {
    const matrix = mapAtom.color && mapAtom.color.matrix && mapAtom.color.matrix.matrix;
    if (!matrix || matrix.length < 20 || !mapAtom.bitmap) return false;
    const key = Array.prototype.join.call(matrix, ',');
    let bitmap = lightBitmaps.get(key);
    if (bitmap) lightBitmaps.delete(key);
    else {
      bitmap = makeBitmap(lightSize, lightSize, 0, 1);
      const texture = bitmap.renderTextureQuad.renderTexture;
      texture.get$canvas().getContext('2d').putImageData(new ImageData(lightPixels(matrix), lightSize, lightSize), 0, 0);
      texture.update$0();
      if (lightBitmaps.size >= lightCacheLimit) lightBitmaps.delete(lightBitmaps.keys().next().value);
    }
    lightBitmaps.set(key, bitmap);
    mapAtom.bitmap.bitmapData = bitmap;
    return true;
  };

  const keepAliveInterval = 30000;
  window.__dpKeepAlive = function (client) {
    if (typeof Worker !== 'function' || typeof Blob !== 'function') return;
    try {
      const source = 'setInterval(function () { postMessage(0); }, ' + keepAliveInterval + ');';
      const worker = new Worker(URL.createObjectURL(new Blob([source], { type: 'text/javascript' })));
      worker.onmessage = function () { client.handleTimer$1(null); };
    } catch (_) {}
  };

  const screenEdges = { TOPLEFT: 'NORTHWEST', TOPRIGHT: 'NORTHEAST', BOTTOMLEFT: 'SOUTHWEST', BOTTOMRIGHT: 'SOUTHEAST', TOP: 'NORTH', BOTTOM: 'SOUTH', LEFT: 'WEST', RIGHT: 'EAST' };
  window.__dpScreenLoc = function (loc) {
    if (typeof loc !== 'string') return loc;
    return loc.replace(/\b(TOPLEFT|TOPRIGHT|BOTTOMLEFT|BOTTOMRIGHT|TOP|BOTTOM|LEFT|RIGHT)\b/g, function (word) { return screenEdges[word]; });
  };

  let mapClassRules;
  function mapStyleRules() {
    if (mapClassRules) return mapClassRules;
    const element = document.querySelector('[byondclass="map"][isdefault="1"]') || document.querySelector('[byondclass="map"]');
    if (!element) return new Map();
    const params = element.getAttribute('skinparams') || '';
    const match = /(?:^|;)style="((?:[^"\\]|\\.)*)"/.exec(params);
    const css = match ? match[1].replace(/\\(.)/g, '$1') : '';
    const rules = new Map();
    const ruleRx = /([^{}]+)\{([^{}]*)\}/g;
    let rule;
    while ((rule = ruleRx.exec(css))) {
      const body = rule[2].split(';').map(function (declaration) {
        const colon = declaration.indexOf(':');
        return colon > 0 ? declaration.slice(0, colon).trim() + ':' + declaration.slice(colon + 1).trim() + ';' : '';
      }).join('');
      for (const selector of rule[1].split(',')) {
        const name = /^\s*\.([\w-]+)\s*$/.exec(selector);
        if (name) rules.set(name[1], (rules.get(name[1]) || '') + body);
      }
    }
    mapClassRules = rules;
    return rules;
  }
  window.__dpTextOutline = function (format, value) {
    if (typeof value !== 'string') return;
    let width = 0;
    const color = [];
    for (const part of value.trim().split(/\s+/)) {
      const size = /^([\d.]+)(px)?$/i.exec(part);
      if (size && !width) width = parseFloat(size[1]);
      else if (!/^(sharp|square|round)$/i.test(part)) color.push(part);
    }
    format.strokeWidth = width;
    if (width > 0) format.strokeColor = color.join(' ') || 'black';
  };

  const clearColor =/(^|;)\s*color\s*:\s*rgba\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*,\s*0*\.?0*\s*\)\s*(?=;|$)/gi;
  window.__dpMaptextSize = function (size, fallback, pointSize) {
    const match = /^\s*(\d+(?:\.\d*)?|\.\d+)\s*(px|pt|%)?\s*$/i.exec(size);
    if (!match) return fallback;
    const value = Number(match[1]);
    const unit = (match[2] || 'pt').toLowerCase();
    if (unit === '%') return Math.round(pointSize * 10 * value) / 100;
    return value > 0 ? value * (unit === 'px' ? 1 : pointSize) : fallback;
  };
  window.__dpMaptextHtml = function (html) {
    if (typeof html !== 'string' || !html) return html;
    const rules = mapStyleRules();
    const template = document.createElement('template');
    template.innerHTML = html.replace(/<br\b[^>]*>[ \t]*(?:\r?\n)?/gi, '\n');
    for (const element of template.content.querySelectorAll('[class], [style]')) {
      let style = '';
      for (const name of element.classList) if (rules.has(name)) style += rules.get(name);
      style += (element.getAttribute('style') || '').replace(clearColor, '$1').replace(/;\s*;/g, ';').replace(/^\s*;/, '');
      if (style) element.setAttribute('style', style);
      else element.removeAttribute('style');
    }
    const base = rules.get('maptext');
    if (!base || /<font\b[^>]*\bface\s*=/i.test(html)) return template.innerHTML;
    return '<span style="' + base.replace(/"/g, '&quot;') + '">' + template.innerHTML + '</span>';
  };

  window.__dpEncodeMessage = function (message) {
    for (const item of message._elems) {
      const prefixed = item.func._target === message._putUTFString$1;
      if ((!prefixed && item.func._target !== message._putString$1) || item.__dpEncoded) continue;
      const original = item.val;
      if (!/[^\x00-\x7f]/.test(original)) continue;
      const bytes = new TextEncoder().encode(original);
      let encoded = '';
      for (const byte of bytes) encoded += String.fromCharCode(byte);
      message._pos += bytes.length - original.length;
      if (prefixed && original.length < 65535 && bytes.length >= 65535) message._pos += 4;
      item.val = encoded;
      item.__dpEncoded = true;
    }
  };

})();
