const { userCodeToSocketId } = require('./state');

const PROXIMITY_RANGE_TILES = 8;
// Cap how many ghost listeners a single living speaker can have at once. Every
// listening ghost is a real WebRTC peer connection on the speaker's browser, so
// without a cap a crowd of ghosts gathered around one player (very common in
// SS13 — they flock to fights, executions, etc.) would spawn dozens of
// connections on that one player's client and choke it. This bounds the damage.
const MAX_GHOST_LISTENERS_PER_SPEAKER = 8;
const prevPackets = new Map();

function normalizeStringify(packet) {
    if ('none' in packet) {
        return JSON.stringify({ none: 1, listenOnly: !!packet.listenOnly });
    }

    const sortedPeers = Object.fromEntries(
        Object.entries(packet.peers).sort((a, b) => a[0].localeCompare(b[0])),
    );
    return JSON.stringify({ peers: sortedPeers, own: packet.own, listenOnly: !!packet.listenOnly });
}

function isValidLocation(location) {
    return Array.isArray(location)
        && location.length >= 2
        && Number.isFinite(location[0])
        && Number.isFinite(location[1]);
}

// BYOND sends locations keyed by "<z>_<room>", e.g. "2_living" / "2_ghost".
// Room names never contain "_", so split on the last underscore.
function parseZoneKey(key) {
    const sep = key.lastIndexOf('_');
    if (sep === -1) {
        return null;
    }
    return { z: key.slice(0, sep), roomType: key.slice(sep + 1) };
}

function handleLocationPacket(packet, io) {
    // Merge the living and ghost rooms of each z-level into a single proximity
    // pool so ghosts can hear living players around them. Each entry keeps an
    // isGhost flag; the actual hearing rules (who hears whom) are applied below.
    const pools = new Map(); // z -> Map(userCode -> { loc, isGhost })

    for (const key in packet) {
        if (key === 'cmd') {
            continue;
        }

        const locations = packet[key];
        if (!locations || typeof locations !== 'object') {
            continue;
        }

        const parsed = parseZoneKey(key);
        if (!parsed) {
            continue;
        }

        const isGhost = parsed.roomType === 'ghost';
        let pool = pools.get(parsed.z);
        if (!pool) {
            pool = new Map();
            pools.set(parsed.z, pool);
        }

        for (const userCode in locations) {
            pool.set(userCode, { loc: locations[userCode], isGhost });
        }
    }

    for (const pool of pools.values()) {
        emitForPool(pool, io);
    }
}

function emitForPool(pool, io) {
    const entries = [...pool.entries()]; // [userCode, { loc, isGhost }]
    const peersByUser = {};
    const ghostListenerCount = {}; // livingCode -> number of ghosts listening
    for (const [userCode] of entries) {
        peersByUser[userCode] = {};
    }

    for (let i = 0; i < entries.length; i++) {
        const [aCode, a] = entries[i];
        if (!isValidLocation(a.loc)) {
            continue;
        }

        for (let j = i + 1; j < entries.length; j++) {
            const [bCode, b] = entries[j];
            if (!isValidLocation(b.loc)) {
                continue;
            }

            // Two ghosts: neither one transmits, so there is nothing to hear.
            if (a.isGhost && b.isGhost) {
                continue;
            }

            const distanceX = Math.abs(a.loc[0] - b.loc[0]);
            const distanceY = Math.abs(a.loc[1] - b.loc[1]);
            if (distanceX >= PROXIMITY_RANGE_TILES || distanceY >= PROXIMITY_RANGE_TILES) {
                continue;
            }

            const distance = Math.hypot(a.loc[0] - b.loc[0], a.loc[1] - b.loc[1]);
            const roundedDistance = Math.round(distance * 10) / 10;

            if (a.isGhost !== b.isGhost) {
                // Ghost <-> living. They become mutual WebRTC peers, but the
                // ghost is flagged listen-only (see the per-user packet below) so
                // its browser never transmits — the living talks, the ghost only
                // hears. Keeping the pairing mutual makes proximity add/remove
                // symmetric on both clients, which avoids the connection from
                // flapping every location tick.
                const livingCode = a.isGhost ? bCode : aCode;
                const count = ghostListenerCount[livingCode] || 0;
                if (count >= MAX_GHOST_LISTENERS_PER_SPEAKER) {
                    continue;
                }
                ghostListenerCount[livingCode] = count + 1;
                peersByUser[aCode][bCode] = roundedDistance;
                peersByUser[bCode][aCode] = roundedDistance;
            } else {
                // Living <-> living: mutual proximity, both hear each other.
                peersByUser[aCode][bCode] = roundedDistance;
                peersByUser[bCode][aCode] = roundedDistance;
            }
        }
    }

    for (const [userCode, info] of entries) {
        const socketId = userCodeToSocketId.get(userCode);
        const socket = socketId && io.sockets.sockets.get(socketId);
        if (!socket) {
            continue;
        }

        const peers = peersByUser[userCode];
        const outPacket = Object.keys(peers).length === 0
            ? { none: 1, listenOnly: info.isGhost }
            : { peers, own: userCode, listenOnly: info.isGhost };

        const newPacket = normalizeStringify(outPacket);
        const prevPacket = prevPackets.get(userCode);
        if (newPacket === prevPacket) {
            continue;
        }

        socket.emit('loc', outPacket);
        prevPackets.set(userCode, newPacket);
    }
}

// Drop cached proximity state for a user that has fully left, so a recycled
// userCode can't inherit a stale "same packet" dedupe entry.
function forgetUser(userCode) {
    prevPackets.delete(userCode);
}

module.exports = { handleLocationPacket, forgetUser };
