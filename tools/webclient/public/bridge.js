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
