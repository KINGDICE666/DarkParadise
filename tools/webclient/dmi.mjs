import zlib from 'node:zlib';

const SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const CHANNELS = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 };
const DIR_ORDER = [2, 1, 4, 8, 6, 10, 5, 9];
const CARDINAL_FALLBACK = { 5: 4, 6: 4, 9: 8, 10: 8 };

function readChunks(bytes) {
  if (bytes.length < 8 || !bytes.subarray(0, 8).equals(SIGNATURE)) throw new Error('not a PNG');
  const chunks = [];
  for (let pos = 8; pos + 8 <= bytes.length;) {
    const length = bytes.readUInt32BE(pos);
    const type = bytes.toString('latin1', pos + 4, pos + 8);
    chunks.push({ type, data: bytes.subarray(pos + 8, pos + 8 + length) });
    pos += 12 + length;
    if (type === 'IEND') break;
  }
  return chunks;
}

function readText(chunk) {
  const nul = chunk.data.indexOf(0);
  if (nul < 0) return null;
  const keyword = chunk.data.toString('latin1', 0, nul);
  const body = chunk.type === 'zTXt' ? zlib.inflateSync(chunk.data.subarray(nul + 2)) : chunk.data.subarray(nul + 1);
  return { keyword, text: body.toString('utf8') };
}

export function parseDmiDescription(text) {
  const meta = { width: 32, height: 32, states: [] };
  let state = null;
  for (const line of text.split(/\r?\n/)) {
    const match = /^\s*([\w-]+)\s*=\s*(.*?)\s*$/.exec(line);
    if (!match) continue;
    const [, key, raw] = match;
    if (key === 'state') {
      state = { name: JSON.parse(raw), dirs: 1, frames: 1, movement: false };
      meta.states.push(state);
    } else if (!state && (key === 'width' || key === 'height')) {
      meta[key] = Number(raw);
    } else if (state && (key === 'dirs' || key === 'frames')) {
      state[key] = Number(raw);
    } else if (state && key === 'movement') {
      state.movement = raw === '1';
    }
  }
  return meta;
}

function decodePng(bytes) {
  const chunks = readChunks(bytes);
  const header = chunks.find(chunk => chunk.type === 'IHDR')?.data;
  if (!header) throw new Error('missing IHDR');
  const width = header.readUInt32BE(0);
  const height = header.readUInt32BE(4);
  const depth = header[8];
  const colorType = header[9];
  const channels = CHANNELS[colorType];
  if (!channels || header[12] !== 0 || (depth !== 8 && (colorType !== 0 && colorType !== 3 || depth > 8))) {
    throw new Error(`unsupported PNG format ${depth}/${colorType}/${header[12]}`);
  }
  const palette = chunks.find(chunk => chunk.type === 'PLTE')?.data;
  const transparency = chunks.find(chunk => chunk.type === 'tRNS')?.data;
  let description = null;
  for (const chunk of chunks) {
    if (chunk.type !== 'zTXt' && chunk.type !== 'tEXt') continue;
    const text = readText(chunk);
    if (text?.keyword === 'Description') description = text.text;
  }
  const raw = zlib.inflateSync(Buffer.concat(chunks.filter(chunk => chunk.type === 'IDAT').map(chunk => chunk.data)));
  const stride = Math.ceil(width * channels * depth / 8);
  const step = Math.max(1, channels * depth / 8);
  const rows = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const source = y * (stride + 1) + 1;
    const row = y * stride;
    for (let x = 0; x < stride; x++) {
      const left = x >= step ? rows[row + x - step] : 0;
      const up = y > 0 ? rows[row - stride + x] : 0;
      const corner = y > 0 && x >= step ? rows[row - stride + x - step] : 0;
      let value = raw[source + x];
      if (filter === 1) value += left;
      else if (filter === 2) value += up;
      else if (filter === 3) value += (left + up) >> 1;
      else if (filter === 4) {
        const estimate = left + up - corner;
        const distanceLeft = Math.abs(estimate - left);
        const distanceUp = Math.abs(estimate - up);
        const distanceCorner = Math.abs(estimate - corner);
        value += distanceLeft <= distanceUp && distanceLeft <= distanceCorner ? left : distanceUp <= distanceCorner ? up : corner;
      }
      rows[row + x] = value;
    }
  }
  const sample = (y, index) => {
    if (depth === 8) return rows[y * stride + index];
    const bit = index * depth;
    return (rows[y * stride + (bit >> 3)] >> (8 - depth - (bit & 7))) & ((1 << depth) - 1);
  };
  const scale = 255 / ((1 << depth) - 1);
  return {
    width,
    height,
    description,
    pixel(x, y, out, offset) {
      const index = x * channels;
      if (colorType === 3) {
        const entry = sample(y, index);
        out[offset] = palette[entry * 3];
        out[offset + 1] = palette[entry * 3 + 1];
        out[offset + 2] = palette[entry * 3 + 2];
        out[offset + 3] = transparency && entry < transparency.length ? transparency[entry] : 255;
      } else if (colorType === 0) {
        const grey = sample(y, index);
        out[offset] = out[offset + 1] = out[offset + 2] = Math.round(grey * scale);
        out[offset + 3] = transparency && transparency.readUInt16BE(0) === grey ? 0 : 255;
      } else if (colorType === 4) {
        out[offset] = out[offset + 1] = out[offset + 2] = sample(y, index);
        out[offset + 3] = sample(y, index + 1);
      } else {
        out[offset] = sample(y, index);
        out[offset + 1] = sample(y, index + 1);
        out[offset + 2] = sample(y, index + 2);
        out[offset + 3] = colorType === 6 ? sample(y, index + 3) : 255;
      }
    },
  };
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'latin1'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(zlib.crc32(body));
  return Buffer.concat([length, body, crc]);
}

export function encodePng(width, height, rgba) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8;
  header[9] = 6;
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) rgba.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4);
  return Buffer.concat([SIGNATURE, chunk('IHDR', header), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

function findState(states, name, movement) {
  const named = states.filter(state => state.name === name);
  return named.find(state => state.movement === movement) || named[0] || null;
}

export function loadDmi(bytes) {
  const image = decodePng(bytes);
  if (image.description == null) throw new Error('missing DMI description');
  return { image, meta: parseDmiDescription(image.description), size: image.width * image.height * 4 };
}

export function dmiFrame({ image, meta }, { state = '', dir = 2, frame = 1, movement = false } = {}) {
  const chosen = findState(meta.states, state, movement) || findState(meta.states, '', movement);
  if (!chosen) return null;
  let index = 0;
  for (const other of meta.states) {
    if (other === chosen) break;
    index += other.dirs * other.frames;
  }
  const facing = chosen.dirs === 4 ? CARDINAL_FALLBACK[dir] || dir : dir;
  const dirIndex = chosen.dirs === 1 ? 0 : Math.max(0, DIR_ORDER.slice(0, chosen.dirs).indexOf(facing));
  const frameIndex = Math.min(Math.max(Math.trunc(frame) || 1, 1), chosen.frames) - 1;
  index += frameIndex * chosen.dirs + dirIndex;
  const columns = Math.max(1, Math.floor(image.width / meta.width));
  const left = (index % columns) * meta.width;
  const top = Math.floor(index / columns) * meta.height;
  if (top + meta.height > image.height) return null;
  const rgba = Buffer.alloc(meta.width * meta.height * 4);
  for (let y = 0; y < meta.height; y++) {
    for (let x = 0; x < meta.width; x++) image.pixel(left + x, top + y, rgba, (y * meta.width + x) * 4);
  }
  return encodePng(meta.width, meta.height, rgba);
}
