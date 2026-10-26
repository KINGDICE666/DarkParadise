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
    if (name === 'browser') source = source.replace("unescape(a[i].replace(/\\+/g,' '))", "window.__dpDecodeParam(a[i].replace(/\\+/g,' '))");
    if (name === 'pane') {
      source = source.replace('if(!this.loading) {if(v) this.popup(); else this.popdown();}', 'this.config.isVisible = v; if (!this.loading) { var existingPopup = this._pop(); if (existingPopup) existingPopup.top.style.display = v ? "" : "none"; else if (v) this.popup(); }');
    }
    if (['pane', 'pop'].includes(name)) source = source.replaceAll('byond.backstage().appendChild(t.top)', 'window.__dpMoveControl(byond.backstage(), t.top)');
    if (name === 'pop') {
      source = source.replaceAll('t.ui.contents.appendChild(e)', 'window.__dpMoveControl(t.ui.contents, e)');
      source = source.replaceAll('document.body.appendChild(t.top)', 'window.__dpMoveControl(document.body, t.top)');
    }
    return source;
  };
  const topicLimit = 8;
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
  window.__dpExpandCommand = function (command) {
    if (typeof command !== 'string' || command.indexOf('\n') >= 0) return command;
    const output = /^\.output\s+(\S+)\s*([\s\S]*)$/i.exec(command);
    if (output) {
      let text = output[2];
      if (text.length > 1 && text.charAt(0) === '"' && text.charAt(text.length - 1) === '"') text = text.slice(1, -1);
      if (outputFallback(output[1], text)) return null;
      try { window.byond.skin.output(output[1], { text: text }); } catch (_) {}
      return null;
    }
    return command.replace(/\[\[([\w-]+(?:\.[\w-]+)*)\.(mouse-pos|size)\]\]/g, function (_, id, property) {
      return embeddedValue(id, property);
    });
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
  const clearColor = /(^|;)\s*color\s*:\s*rgba\(\s*[\d.]+\s*,\s*[\d.]+\s*,\s*[\d.]+\s*,\s*0*\.?0*\s*\)\s*(?=;|$)/gi;
  window.__dpMaptextHtml = function (html) {
    if (typeof html !== 'string' || (html.indexOf('class') < 0 && html.indexOf('rgba(') < 0)) return html;
    const rules = mapStyleRules();
    const template = document.createElement('template');
    template.innerHTML = html;
    for (const element of template.content.querySelectorAll('[class], [style]')) {
      let style = '';
      for (const name of element.classList) if (rules.has(name)) style += rules.get(name);
      style += (element.getAttribute('style') || '').replace(clearColor, '$1').replace(/;\s*;/g, ';').replace(/^\s*;/, '');
      if (style) element.setAttribute('style', style);
      else element.removeAttribute('style');
    }
    return template.innerHTML;
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
