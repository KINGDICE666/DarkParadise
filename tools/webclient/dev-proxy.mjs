import fs from 'node:fs/promises';
import http from 'node:http';
import net from 'node:net';
import { fileURLToPath } from 'node:url';
import { patchWebclient } from './patch.mjs';
import { createAssetIndex } from './assets.mjs';

const upstreamHost = process.env.DEV_UPSTREAM_HOST || '92.63.189.21';
const upstreamPort = Number(process.env.DEV_UPSTREAM_PORT || 7779);
const port = Number(process.env.DEV_PORT || 8179);
const vendor = process.env.DEV_VENDOR_FILE;
const source = vendor ? patchWebclient(await fs.readFile(vendor, 'utf8'), { selfKey: true }).replace('$.me = N.ByondClient$();', '$.me = N.ByondClient$(); window.__dpMe = $.me;') : null;
const assets = createAssetIndex(process.env.DEV_ASSET_DIR ? [process.env.DEV_ASSET_DIR] : []);
const legacyHelpers = process.env.DEV_LEGACY_HELPERS ? (await fs.readFile(process.env.DEV_LEGACY_HELPERS, 'utf8')).trim().replace('window.byond.topic(query.join("&"))', 'webClient.fn.topic(query.join("&"))') : null;
const newHelpers = process.env.DEV_TGUI_HELPERS ? (await fs.readFile(process.env.DEV_TGUI_HELPERS, 'utf8')).trim() : null;

function observeFrames(label) {
  let pending = Buffer.alloc(0);
  let remaining = 40;
  return chunk => {
    pending = Buffer.concat([pending, chunk]);
    while (pending.length >= 2) {
      const opcode = pending[0] & 15;
      const masked = Boolean(pending[1] & 128);
      let length = pending[1] & 127;
      let offset = 2;
      if (length === 126) {
        if (pending.length < 4) return;
        length = pending.readUInt16BE(2);
        offset = 4;
      } else if (length === 127) {
        if (pending.length < 10) return;
        const size = pending.readBigUInt64BE(2);
        if (size > 32n * 1024n * 1024n) { remaining = 0; return; }
        length = Number(size);
        offset = 10;
      }
      const maskOffset = offset;
      if (masked) offset += 4;
      if (pending.length < offset + length) return;
      const payload = Buffer.from(pending.subarray(offset, offset + length));
      if (masked) for (let i = 0; i < length; i++) payload[i] ^= pending[maskOffset + i % 4];
      pending = pending.subarray(offset + length);
      if (opcode !== 2 || length < 2) continue;
      const type = payload.readUInt16BE(0);
      if (label === 'server' && ![0, 26, 39, 143, 144, 225].includes(type)) continue;
      if (remaining <= 0 && ![0, 26, 129, 143, 144, 209, 214, 215, 225].includes(type)) continue;
      let detail = '';
      if (type === 129) {
        const query = new URLSearchParams(payload.subarray(2).toString('utf8').replace(/\0$/, '').replace(/^\?/, '').replace(/;/g, '&'));
        const keys = [...query.keys()].filter(key => /^[\w-]{1,32}$/.test(key)).slice(0, 6).join(',');
        detail = ` window=${(query.get('window_id') || '').replace(/[^\w-]/g, '')} event=${(query.get('type') || '').replace(/[^\w/-]/g, '')} keys=${keys}`;
      } else if (label === 'server' && type === 0 && length > 2) detail = ` quit=${payload.readUInt16LE(2)}`;
      else if (label === 'server' && type === 39) {
        const end = payload.indexOf(0, 2);
        const name = end < 0 ? '' : payload.subarray(end + 1, payload.indexOf(0, end + 1)).toString('utf8');
        detail = ` target=${/^[\w:.-]{1,64}$/.test(name) ? name : 'other'}`;
      }
      console.log(`[${new Date().toISOString()} wire ${label}] type=${type} bytes=${length}${detail}`);
      remaining--;
    }
  };
}

const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://local').pathname.replace(/^\/webtest\//, '/');
  const asset = await assets.get(pathname);
  if (asset) {
    res.writeHead(200, { 'Content-Type': asset.type, 'Cache-Control': 'public, max-age=31536000, immutable', 'Access-Control-Allow-Origin': '*' });
    return res.end(asset.bytes);
  }
  if (pathname === '/dev-diag' && req.method === 'POST') {
    let body = '';
    for await (const chunk of req) { body += chunk; if (body.length > 3000) break; }
    console.log('[frame diagnostic] ' + body.slice(0, 3000));
    res.writeHead(204); return res.end();
  }
  if (pathname === '/res/webclient.dart.js' && source) {
    res.writeHead(200, { 'Content-Type': 'text/javascript; charset=utf-8', 'Cache-Control': 'no-store' });
    return res.end(source);
  }
  if (pathname === '/static/bridge.js') {
    res.writeHead(200, { 'Content-Type': 'text/javascript; charset=utf-8', 'Cache-Control': 'no-store' });
    return res.end(await fs.readFile(fileURLToPath(new URL('./public/bridge.js', import.meta.url))));
  }
  const request = http.request({ host: upstreamHost, port: upstreamPort, path: req.url, method: req.method, headers: req.headers }, response => {
    if (response.headers['content-type']?.includes('text/html')) {
      const chunks = [];
      response.on('data', chunk => chunks.push(chunk));
      response.on('end', () => {
        let html = Buffer.concat(chunks).toString('utf8').replace('<head>', `<head><script>addEventListener('error',function(e){navigator.sendBeacon('/dev-diag',location.pathname+' '+e.message+' '+(e.error&&e.error.stack||''));});</script>`);
        if (legacyHelpers && newHelpers) html = html.replace(legacyHelpers, () => newHelpers);
        const headers = { ...response.headers, 'Cache-Control': 'no-store' };
        delete headers['content-length'];
        res.writeHead(response.statusCode, headers); res.end(html);
      });
      return;
    }
    res.writeHead(response.statusCode, response.headers);
    response.pipe(res);
  });
  request.on('error', error => { if (!res.headersSent) res.writeHead(502); res.end(error.message); });
  req.pipe(request);
});

server.on('upgrade', (req, socket, head) => {
  const upstream = net.connect(upstreamPort, upstreamHost);
  const observeClient = observeFrames('client');
  const observeServer = observeFrames('server');
  let responseHeader = Buffer.alloc(0);
  let upgraded = false;
  upstream.on('connect', () => {
    const headers = [`GET ${req.url} HTTP/1.1`];
    for (let i = 0; i < req.rawHeaders.length; i += 2) headers.push(`${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}`);
    upstream.write(headers.join('\r\n') + '\r\n\r\n');
    if (head.length) { observeClient(head); upstream.write(head); }
    socket.on('data', observeClient);
    socket.pipe(upstream).pipe(socket);
  });
  upstream.on('data', chunk => {
    if (upgraded) return observeServer(chunk);
    responseHeader = Buffer.concat([responseHeader, chunk]);
    const end = responseHeader.indexOf('\r\n\r\n');
    if (end < 0) return;
    upgraded = true;
    observeServer(responseHeader.subarray(end + 4));
    responseHeader = null;
  });
  const close = () => { socket.destroy(); upstream.destroy(); };
  socket.on('error', close);
  upstream.on('error', close);
  socket.on('close', close);
  upstream.on('close', close);
});
server.listen(port, '127.0.0.1', () => console.log(`Development proxy http://127.0.0.1:${port}; production processes unchanged`));
