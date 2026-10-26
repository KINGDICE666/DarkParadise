import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import net from 'node:net';

const TOKEN = /^dpweb-v1:[0-9a-f]{32}$/;

export function createTicketAuthority({ now = Date.now, ttl = 60_000, capacity = 4096 } = {}) {
  const tickets = new Map();
  function prune() {
    const time = now();
    for (const [token, ticket] of tickets) {
      if (ticket.expires <= time) tickets.delete(token);
    }
  }
  return {
    issue(address = '127.0.0.1') {
      if (!net.isIP(address)) throw new Error('invalid guest address');
      prune();
      if (tickets.size >= capacity) throw new Error('guest ticket capacity exceeded');
      const token = 'dpweb-v1:' + crypto.randomBytes(16).toString('hex');
      const guest = 'Guest-' + crypto.randomBytes(8).readBigUInt64BE().toString();
      tickets.set(token, { guest, address, expires: now() + ttl });
      return token;
    },
    consume(token) {
      if (!TOKEN.test(token)) return null;
      const ticket = tickets.get(token);
      tickets.delete(token);
      return ticket && ticket.expires > now() ? { guest: ticket.guest, address: ticket.address } : null;
    },
  };
}

export async function listenForTicketChecks(socketPath, authority) {
  try {
    const stat = await fs.lstat(socketPath);
    if (!stat.isSocket()) throw new Error('auth socket path is not a socket');
    await new Promise((resolve, reject) => {
      const probe = net.connect(socketPath);
      probe.once('connect', () => { probe.destroy(); reject(new Error('auth socket is already in use')); });
      probe.once('error', error => error.code === 'ECONNREFUSED' ? resolve() : reject(error));
    });
    await fs.unlink(socketPath);
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  const server = net.createServer(socket => {
    socket.setTimeout(500, () => socket.destroy());
    socket.on('error', () => {});
    let input = '';
    let finished = false;
    socket.on('data', chunk => {
      if (finished) return;
      input += chunk.toString('utf8');
      if (input.length > 64) { finished = true; socket.end('ERR\n'); return; }
      if (!input.includes('\n')) return;
      finished = true;
      const token = input.slice(0, -1);
      const ticket = TOKEN.test(token) ? authority.consume(token) : null;
      socket.end(ticket ? `OK ${ticket.guest} ${ticket.address}\n` : 'ERR\n');
    });
  });
  server.maxConnections = 64;
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(socketPath, resolve);
  });
  await fs.chmod(socketPath, 0o600);
  return server;
}
