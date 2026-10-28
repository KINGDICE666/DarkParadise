import net from 'node:net';

const STATES = ['startup', 'lobby', 'starting', 'playing', 'finished'];

export function encodeTopic(query) {
  const payload = Buffer.from(query + '\0', 'utf8');
  const header = Buffer.alloc(9);
  header[1] = 0x83;
  header.writeUInt16BE(payload.length + 5, 2);
  return Buffer.concat([header, payload]);
}

export function decodeTopicReply(bytes) {
  if (bytes.length < 5 || bytes[0] !== 0x00 || bytes[1] !== 0x83) return null;
  const end = Math.min(bytes.length, 4 + bytes.readUInt16BE(2));
  if (bytes[4] === 0x2a && end >= 9) return bytes.readFloatLE(5);
  if (bytes[4] !== 0x06) return null;
  let text = bytes.subarray(5, end);
  if (text.at(-1) === 0) text = text.subarray(0, -1);
  return text.toString('utf8');
}

export function worldTopic(host, port, query, timeout = 4000) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const socket = net.connect(port, host);
    socket.setTimeout(timeout, () => socket.destroy(new Error('topic timeout')));
    socket.on('connect', () => socket.write(encodeTopic(query)));
    socket.on('data', chunk => {
      chunks.push(chunk);
      const bytes = Buffer.concat(chunks);
      if (bytes.length >= 4 && bytes.length >= 4 + bytes.readUInt16BE(2)) {
        socket.end();
        resolve(decodeTopicReply(bytes));
      }
    });
    socket.on('error', reject);
    socket.on('close', () => resolve(decodeTopicReply(Buffer.concat(chunks))));
  });
}

export function publicStatus(reply) {
  let status;
  try { status = JSON.parse(reply); } catch { return { online: false }; }
  if (!status || typeof status !== 'object') return { online: false };
  return {
    online: true,
    players: Number(status.players) || 0,
    map: typeof status.map_name === 'string' ? status.map_name : null,
    roundTime: typeof status.roundtime === 'string' ? status.roundtime : null,
    state: STATES[status.ticker_state] || 'startup',
  };
}

export function createStatusCache(fetchReply, { ttl = 10000, now = Date.now } = {}) {
  let cached = null;
  let pending = null;
  return async function status() {
    if (cached && now() - cached.at < ttl) return cached.value;
    if (!pending) {
      pending = fetchReply()
        .then(publicStatus, () => ({ online: false }))
        .then(value => { cached = { value, at: now() }; return value; })
        .finally(() => { pending = null; });
    }
    return pending;
  };
}
