import assert from 'node:assert/strict';
import net from 'node:net';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { createTicketAuthority, listenForTicketChecks } from './tickets.mjs';

test('tickets are unique, expire, and can only admit a guest once', () => {
  let time = 0;
  const auth = createTicketAuthority({ now: () => time, ttl: 10 });
  const first = auth.issue();
  const second = auth.issue();
  assert.notEqual(first, second);
  assert.equal(auth.consume('aleph-guest-v1:' + '0'.repeat(32)), null);
  const accepted = auth.consume(first);
  assert.match(accepted.guest, /^Guest-\d+$/);
  assert.equal(accepted.address, '127.0.0.1');
  assert.equal(auth.consume(first), null);
  time = 10;
  assert.equal(auth.consume(second), null);
});

test('unconsumed tickets are bounded and expired capacity is recovered', () => {
  let time = 0;
  const auth = createTicketAuthority({ now: () => time, ttl: 10, capacity: 1 });
  auth.issue();
  assert.throws(() => auth.issue(), /capacity/);
  time = 10;
  assert.match(auth.issue(), /^dpweb-v1:[0-9a-f]{32}$/);
});

test('socket rejects malformed, oversized, and replayed requests', { skip: process.platform === 'win32' }, async () => {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'dp-web-auth-'));
  const socketPath = path.join(dir, 'auth.sock');
  const auth = createTicketAuthority();
  const server = await listenForTicketChecks(socketPath, auth);
  const request = input => new Promise((resolve, reject) => {
    const socket = net.connect(socketPath, () => socket.end(input));
    let reply = '';
    socket.on('data', data => { reply += data; });
    socket.on('end', () => resolve(reply));
    socket.on('error', reject);
  });
  try {
    const token = auth.issue();
    assert.equal(await request(token + '\nextra\n'), 'ERR\n');
    assert.equal(await request('x'.repeat(65)), 'ERR\n');
    assert.match(await request(token + '\n'), /^OK Guest-\d+ 127\.0\.0\.1\n$/);
    assert.equal(await request(token + '\n'), 'ERR\n');
    assert.equal((await fs.stat(socketPath)).mode & 0o777, 0o600);
    await assert.rejects(listenForTicketChecks(socketPath, auth), /already in use/);
  } finally {
    await new Promise(resolve => server.close(resolve));
    await fs.rm(dir, { recursive: true });
  }
});
