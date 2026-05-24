const { userCodeToSocketId } = require('./state');

const PROXIMITY_RANGE_TILES = 8;
const prevPackets = new Map();

function normalizeStringify(packet) {
    if ('none' in packet) {
        return JSON.stringify({ none: 1 });
    }

    const sortedPeers = Object.fromEntries(
        Object.entries(packet.peers).sort((a, b) => a[0].localeCompare(b[0])),
    );
    return JSON.stringify({ peers: sortedPeers, own: packet.own });
}

function isValidLocation(location) {
    return Array.isArray(location)
        && location.length >= 2
        && Number.isFinite(location[0])
        && Number.isFinite(location[1]);
}

function handleLocationPacket(packet, io) {
    for (const zLevel in packet) {
        if (zLevel === 'cmd') {
            continue;
        }

        const locations = packet[zLevel];
        if (!locations || typeof locations !== 'object') {
            continue;
        }

        const userCodes = Object.keys(locations);
        const peersByUser = {};
        for (const userCode of userCodes) {
            peersByUser[userCode] = {};
        }

        for (let i = 0; i < userCodes.length; i++) {
            const userCode = userCodes[i];
            const userLocation = locations[userCode];
            if (!isValidLocation(userLocation)) {
                continue;
            }

            const [userX, userY] = userLocation;
            for (let j = i + 1; j < userCodes.length; j++) {
                const otherCode = userCodes[j];
                const otherLocation = locations[otherCode];
                if (!isValidLocation(otherLocation)) {
                    continue;
                }

                const [otherX, otherY] = otherLocation;
                const distanceX = Math.abs(userX - otherX);
                const distanceY = Math.abs(userY - otherY);
                if (distanceX >= PROXIMITY_RANGE_TILES || distanceY >= PROXIMITY_RANGE_TILES) {
                    continue;
                }

                const distance = Math.hypot(userX - otherX, userY - otherY);
                const roundedDistance = Math.round(distance * 10) / 10;
                peersByUser[userCode][otherCode] = roundedDistance;
                peersByUser[otherCode][userCode] = roundedDistance;
            }
        }

        for (const userCode of userCodes) {
            const peers = peersByUser[userCode];
            const socketId = userCodeToSocketId.get(userCode);
            const socket = io.sockets.sockets.get(socketId);
            if (!socketId || !socket) {
                continue;
            }

            const outPacket = Object.keys(peers).length === 0
                ? { none: 1 }
                : { peers, own: userCode };
            const newPacket = normalizeStringify(outPacket);
            const prevPacket = prevPackets.get(userCode);
            if (newPacket === prevPacket) {
                continue;
            }

            socket.emit('loc', outPacket);
            prevPackets.set(userCode, newPacket);
        }
    }
}

module.exports = { handleLocationPacket };
