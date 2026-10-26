import http from 'node:http';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { patchWebclient } from './patch.mjs';
import { createTicketAuthority, listenForTicketChecks } from './tickets.mjs';
import { createAssetIndex, createWebrootReader } from './assets.mjs';

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.join(ROOT, 'public');

const config = {
  listenHost: process.env.GATEWAY_HOST || '127.0.0.1',
  listenPort: Number(process.env.GATEWAY_PORT || 8090),
  ddHost: process.env.DD_HOST || '127.0.0.1',
  ddPort: Number(process.env.DD_PORT || 1337),
  publicUrl: (process.env.PUBLIC_URL || '').replace(/\/+$/, ''),
  offlineMessage: process.env.OFFLINE_MESSAGE || 'Сервер сейчас перезапускается, попробуйте через минуту.',
  keyMode: process.env.KEY_MODE === 'self' ? 'self' : 'byond',
  wsHost: process.env.DD_WS_HOST || '',
  basePath: (process.env.BASE_PATH || '').replace(/\/+$/, ''),
  authSocket: process.env.AUTH_SOCKET || '',
  byondWebDir: process.env.BYOND_WEB_DIR || '',
};

const tickets = createTicketAuthority();
const assets = createAssetIndex(JSON.parse(process.env.ASSET_ROOTS || '[]'));
const webroot = createWebrootReader(process.env.ASSET_WEBROOT);
if (config.keyMode === 'self' && !config.authSocket) {
  throw new Error('KEY_MODE=self requires AUTH_SOCKET and the DD native guest adapter');
}
const ticketServer = config.keyMode === 'self'
  ? await listenForTicketChecks(config.authSocket, tickets)
  : null;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.json': 'application/json; charset=utf-8',
};

const PASSTHROUGH_HEADERS = ['content-type', 'content-length', 'content-disposition', 'content-range', 'accept-ranges'];

let patchedCache = null;

function ddRequestOnce(pathname, headers) {
  return new Promise((resolve, reject) => {
    const req = http.request({
      host: config.ddHost,
      port: config.ddPort,
      path: pathname,
      method: 'GET',
      headers: { ...headers, Connection: 'close' },
      agent: false,
      timeout: 15000,
    }, resolve);
    req.on('timeout', () => req.destroy(new Error('dd timeout')));
    req.on('error', reject);
    req.end();
  });
}

async function ddRequest(pathname, headers = {}) {
  try {
    return await ddRequestOnce(pathname, headers);
  } catch (error) {
    console.warn(`[gateway] DD ${pathname}: ${error.message}, retrying`);
    return ddRequestOnce(pathname, headers);
  }
}

async function readBody(res) {
  const chunks = [];
  for await (const chunk of res) chunks.push(chunk);
  return Buffer.concat(chunks);
}

async function ddVersion() {
  const res = await ddRequest('/query');
  const body = JSON.parse((await readBody(res)).toString('utf8'));
  return body.version;
}

async function patchedWebclient() {
  const version = await ddVersion();
  if (patchedCache && patchedCache.version === version) return patchedCache;
  let source;
  if (config.byondWebDir) {
    source = await fs.promises.readFile(path.join(config.byondWebDir, 'webclient.dart.js'), 'utf8');
  } else {
    const res = await ddRequest('/res/webclient.dart.js');
    if (res.statusCode !== 200) throw new Error('webclient.dart.js: HTTP ' + res.statusCode);
    source = (await readBody(res)).toString('utf8');
  }
  const code = Buffer.from(patchWebclient(source, { selfKey: config.keyMode === 'self' }), 'utf8');
  const etag = '"' + crypto.createHash('sha1').update(code).digest('hex') + '"';
  patchedCache = { version, code, etag };
  console.log(`[gateway] patched webclient.dart.js for BYOND ${version}`);
  return patchedCache;
}

function publicBase(req) {
  if (config.publicUrl) return config.publicUrl;
  const proto = (req.headers['x-forwarded-proto'] || 'http').split(',')[0].trim();
  const host = req.headers['x-forwarded-host'] || req.headers.host;
  return `${proto}://${host}`;
}

function playerAddress(req) {
  let address = req.socket.remoteAddress || '';
  if (address.startsWith('::ffff:')) address = address.slice(7);
  if ((address === '127.0.0.1' || address === '::1') && req.headers['x-forwarded-for']) {
    address = req.headers['x-forwarded-for'].split(',').at(-1).trim();
  }
  return address;
}

function playPage() {
  const base = config.basePath;
  return `<!DOCTYPE html>
<html style="width:100%;height:100%"><head><meta charset="utf-8">
<script>window.__dpNative=${JSON.stringify(base)};</script>
<script src="${base}/static/bridge.js"></script>
<script>try{window.parent.postMessage('scripts:begin','*');}catch(_){}</script>
<script src="${base}/res/ext.js"></script>
<script src="${base}/res/webclient.dart.js"></script>
<script>try{window.parent.postMessage('scripts:end','*');}catch(_){}</script>
<style type="text/css">* {box-sizing:border-box;}</style></head>
<body style="width:100%;height:100%;margin:0;overflow:hidden;"><div id=skin style="width:100%;height:100%;"></div></body></html>`;
}

function send(res, status, body, type = 'text/plain; charset=utf-8', extra = {}) {
  res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store', ...extra });
  res.end(body);
}

async function serveStatic(res, rel) {
  const file = path.normalize(path.join(PUBLIC_DIR, rel));
  if (!file.startsWith(PUBLIC_DIR + path.sep)) return send(res, 403, 'forbidden');
  try {
    const stat = await fs.promises.stat(file);
    if (!stat.isFile()) return send(res, 404, 'not found');
    res.writeHead(200, {
      'Content-Type': MIME[path.extname(file)] || 'application/octet-stream',
      'Content-Length': stat.size,
      'Cache-Control': 'no-cache',
    });
    fs.createReadStream(file).pipe(res);
  } catch {
    send(res, 404, 'not found');
  }
}

async function proxyToDD(req, res, target) {
  try {
    const headers = {};
    if (req.headers.range) headers.range = req.headers.range;
    const upstream = await ddRequest(target, headers);
    if (target.startsWith('/html/') && upstream.headers['content-type']?.includes('text/html')) {
      let html = (await readBody(upstream)).toString('utf8').replace(/<base\s+href="[^"]*"\s*\/?\s*>/i, `<base href="${config.basePath}/">`);
      html = html.replace('window.byond.topic(query.join("&"))', 'webClient.fn.topic(query.join("&"))');
      return send(res, upstream.statusCode, html, MIME['.html']);
    }
    const out = { 'Access-Control-Allow-Origin': '*' };
    for (const name of PASSTHROUGH_HEADERS) {
      if (upstream.headers[name]) out[name] = upstream.headers[name];
    }
    out['Cache-Control'] = target.startsWith('/cache/') ? 'public, max-age=604800, immutable' : 'no-cache';
    res.writeHead(upstream.statusCode, out);
    upstream.pipe(res);
  } catch {
    send(res, 502, 'game server unavailable');
  }
}

async function handle(req, res) {
  const url = new URL(req.url, 'http://gateway');
  if (config.basePath && (url.pathname === config.basePath || url.pathname.startsWith(config.basePath + '/'))) {
    url.pathname = url.pathname.slice(config.basePath.length) || '/';
  }
  if (req.method !== 'GET' && req.method !== 'HEAD') return send(res, 405, 'method not allowed');
  const p = url.pathname;
  const cors = { 'Access-Control-Allow-Origin': '*' };

  if (p.startsWith('/assets/')) {
    const exported = await webroot.get(p);
    if (!exported) return send(res, 404, 'asset not found');
    return send(res, 200, exported.bytes, exported.type, { ...cors, 'Cache-Control': 'public, max-age=31536000, immutable' });
  }
  const asset = await assets.get(p);
  if (asset) return send(res, 200, asset.bytes, asset.type, { ...cors, 'Cache-Control': 'public, max-age=31536000, immutable' });

  if (p === '/query') {
    try {
      const version = await ddVersion();
      return send(res, 200, JSON.stringify({ url: publicBase(req) + '/play', version }), MIME['.json'], cors);
    } catch (error) {
      console.error(`[gateway] /query failed: ${error.message}`);
      return send(res, 200, JSON.stringify({ fail: config.offlineMessage }), MIME['.json'], cors);
    }
  }

  if (p === '/play') return send(res, 200, playPage(), MIME['.html']);

  if (p === '/res/webclient.dart.js') {
    try {
      const patched = await patchedWebclient();
      const headers = { ETag: patched.etag, 'Cache-Control': 'no-cache', ...cors };
      if (req.headers['if-none-match'] === patched.etag) {
        res.writeHead(304, headers);
        return res.end();
      }
      return send(res, 200, patched.code, MIME['.js'], headers);
    } catch (error) {
      console.error('[gateway] patch failed:', error.message);
      return send(res, 502, 'webclient unavailable');
    }
  }

  if (p === '/auth/key' && config.keyMode === 'self') {
    try {
      return send(res, 200, JSON.stringify({ key: tickets.issue(playerAddress(req)) }), MIME['.json']);
    } catch {
      return send(res, 503, JSON.stringify({ error: 'Вход временно занят, попробуйте ещё раз.' }), MIME['.json']);
    }
  }

  if (config.byondWebDir && /^\/res\/[\w.-]+$/.test(p)) {
    try {
      const filename = p.slice('/res/'.length);
      const data = await fs.promises.readFile(path.join(config.byondWebDir, filename));
      return send(res, 200, data, MIME[path.extname(filename)] || 'text/plain; charset=utf-8');
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }

  if (p === '/' || p === '/index.html') return serveStatic(res, config.keyMode === 'self' ? 'self.html' : 'index.html');
  if (p.startsWith('/static/')) return serveStatic(res, p.slice('/static/'.length));

  return proxyToDD(req, res, p + url.search);
}

const server = http.createServer((req, res) => {
  handle(req, res).catch((error) => {
    console.error('[gateway]', error);
    if (!res.headersSent) send(res, 500, 'internal error');
    else res.end();
  });
});

server.on('upgrade', (req, socket, head) => {
  const upstream = net.connect(config.ddPort, config.ddHost);
  upstream.setNoDelay(true);
  socket.setNoDelay(true);
  upstream.on('connect', () => {
    const target = new URL(req.url, 'http://gateway');
    if (config.basePath && target.pathname.startsWith(config.basePath + '/')) {
      target.pathname = target.pathname.slice(config.basePath.length);
    }
    const lines = [`GET ${target.pathname}${target.search} HTTP/1.1`];
    for (let i = 0; i < req.rawHeaders.length; i += 2) {
      const name = req.rawHeaders[i];
      const lower = name.toLowerCase();
      if (config.wsHost && lower === 'host') lines.push(`Host: ${config.wsHost}`);
      else if (config.wsHost && lower === 'origin') lines.push(`Origin: http://${config.wsHost}`);
      else lines.push(`${name}: ${req.rawHeaders[i + 1]}`);
    }
    upstream.write(lines.join('\r\n') + '\r\n\r\n');
    if (head && head.length) upstream.write(head);
    socket.pipe(upstream).pipe(socket);
  });
  const close = () => {
    socket.destroy();
    upstream.destroy();
  };
  upstream.on('error', close);
  socket.on('error', close);
  upstream.on('close', close);
  socket.on('close', close);
});

server.listen(config.listenPort, config.listenHost, () => {
  console.log(`[gateway] listening on http://${config.listenHost}:${config.listenPort} -> DD ${config.ddHost}:${config.ddPort}`);
});

process.on('SIGTERM', () => {
  server.close();
  ticketServer?.close();
  setTimeout(() => process.exit(0), 1000).unref();
});
