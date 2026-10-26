(function () {
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

  function diag(event) {
    try {
      navigator.sendBeacon((window.__dpNative || '') + '/diag', event);
    } catch (_) {}
  }

  window.addEventListener('message', function (e) {
    if (typeof e.data !== 'string') return;
    if (e.data.indexOf('key:') === 0) diag('key-received len=' + (e.data.length - 4) + ' from=' + e.origin);
    else if (e.data === 'key_failed') diag('key-failed from=' + e.origin);
  });

  diag('play-loaded parent=' + (window.parent !== window) + ' referrer=' + document.referrer);
})();
