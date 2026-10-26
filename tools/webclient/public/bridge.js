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
  const queuedTabs = [];
  const recentTabs = new Map();
  let topicTimer;
  let dispatching = false;
  function flushTab() {
    const next = queuedTabs.shift();
    if (!next) { topicTimer = undefined; return; }
    dispatching = true;
    try { next.client.sendTopicMessage$1(next.topic); }
    finally {
      dispatching = false;
      topicTimer = setTimeout(flushTab, 120);
    }
  }
  window.__dpScheduleTopic = function (client, topic) {
    if (dispatching) return false;
    const query = new URLSearchParams(topic.replace(/^\?/, ''));
    if (query.get('window_id') !== 'statbrowser' || !['Send-Tabs', 'Remove-Tabs'].includes(query.get('type'))) return false;
    const now = Date.now();
    for (const [key, recent] of recentTabs) if (now - recent.time > 1000) recentTabs.delete(key);
    const tab = query.get('payload');
    if (recentTabs.get(tab)?.topic !== topic) {
      recentTabs.set(tab, { topic, time: now });
      queuedTabs.push({ client, topic });
      if (!topicTimer) topicTimer = setTimeout(flushTab, 120);
    }
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
  window.__dpExpandCommand = function (command) {
    if (typeof command !== 'string' || command.indexOf('\n') >= 0) return command;
    const output = /^\.output\s+(\S+)\s*([\s\S]*)$/i.exec(command);
    if (output) {
      let text = output[2];
      if (text.length > 1 && text.charAt(0) === '"' && text.charAt(text.length - 1) === '"') text = text.slice(1, -1);
      try { window.byond.skin.output(output[1], { text: text }); } catch (_) {}
      return null;
    }
    return command.replace(/\[\[([\w-]+(?:\.[\w-]+)*)\.(mouse-pos|size)\]\]/g, function (_, id, property) {
      return embeddedValue(id, property);
    });
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
