const { sessionIdToUserCode, userCodeToSocketId, socketIdToUserCode } = require('../state');
const { sendJSON } = require('../byond/ByondCommunication');
const { forgetUser } = require('../proximity');

// When a browser socket drops we do NOT immediately tear the user out of the
// in-game voice session. A short network blip, a socket.io transport upgrade,
// or the browser briefly backgrounding the tab would otherwise purge the user
// from BYOND — and since BYOND would clear its userCode bookkeeping, even a
// successful WebSocket reconnect couldn't restore the session, forcing the
// player to re-click "Подключиться". Instead we wait out a grace window; if the
// same userCode reconnects within it we cancel the purge, so transient drops
// self-heal. Only a genuine, sustained disconnect reaches BYOND.
const DISCONNECT_GRACE_MS = 12000;
const pendingPurges = new Map(); // userCode -> timeout handle

function cancelPurge(userCode) {
    if (!userCode) {
        return;
    }
    const timer = pendingPurges.get(userCode);
    if (timer) {
        clearTimeout(timer);
        pendingPurges.delete(userCode);
    }
}

function forgetSession(userCode) {
    for (const [sessionId, code] of sessionIdToUserCode) {
        if (code === userCode) {
            sessionIdToUserCode.delete(sessionId);
        }
    }
}

function purgeUser(userCode, byondPort, io) {
    pendingPurges.delete(userCode);

    // The user reconnected during the grace window — keep them.
    const socketId = userCodeToSocketId.get(userCode);
    const liveSocket = socketId && io.sockets.sockets.get(socketId);
    if (liveSocket && liveSocket.connected) {
        return;
    }

    if (socketId) {
        socketIdToUserCode.delete(socketId);
    }
    userCodeToSocketId.delete(userCode);
    forgetSession(userCode);
    forgetUser(userCode);

    sendJSON({ disconnect: userCode }, byondPort);
    console.log(`Purged userCode ${userCode} after grace period.`);
}

function schedulePurge(userCode, byondPort, io) {
    cancelPurge(userCode);
    const timer = setTimeout(() => purgeUser(userCode, byondPort, io), DISCONNECT_GRACE_MS);
    pendingPurges.set(userCode, timer);
}

// Tear the user out of BYOND right now (intentional disconnect, no grace).
function purgeUserNow(userCode, byondPort) {
    if (!userCode) {
        return;
    }
    cancelPurge(userCode);
    forgetSession(userCode);
    forgetUser(userCode);
    sendJSON({ disconnect: userCode }, byondPort);
}

// Ownership-safe teardown of a socket's userCode mapping. The userCode -> socket
// pointer is only cleared if it still points at THIS socket, so a late
// 'disconnect' fired by a stale socket can't unbind a freshly reconnected one.
function clearSocketUser(socket) {
    const userCode = socketIdToUserCode.get(socket.id);
    if (!userCode) {
        return null;
    }

    socketIdToUserCode.delete(socket.id);
    if (userCodeToSocketId.get(userCode) === socket.id) {
        userCodeToSocketId.delete(userCode);
    }
    socket.userCode = null;
    return userCode;
}

function getTargetSocket(io, userCode) {
    const targetSocketId = userCodeToSocketId.get(userCode);
    if (!targetSocketId) {
        return null;
    }

    return io.sockets.sockets.get(targetSocketId);
}

// Send confirmation to BYOND exactly once per socket. The previous code fired 4
// retries within 3 seconds, which on Windows triggered DreamDaemon's per-IP
// topic spam prevention (1-minute lockout). One send is enough since BYOND's
// confirm_user_code is idempotent and sendJSON goes through a serializing queue.
function confirmMicAccess(socket, byondPort) {
    const userCode = socketIdToUserCode.get(socket.id);
    if (!userCode || socket.micConfirmed) {
        return;
    }

    socket.micConfirmed = true;
    sendJSON({ confirmed: userCode }, byondPort);
    console.log(`Sent microphone confirmation for userCode ${userCode}.`);
}

function createConnectionHandler(byondPort, io) {
    return function handleConnection(socket) {
        console.log('A user connected:', socket.id);
        socket.micAccessGranted = false;
        socket.micConfirmed = false;

        const authTimer = setTimeout(() => {
            if (socketIdToUserCode.get(socket.id)) {
                return;
            }

            console.log(`Unauthenticated socket ${socket.id} timed out, disconnecting.`);
            socket.emit('update', { type: 'status', data: 'Отключено: истекло время авторизации' });
            socket.disconnect();
        }, 5000);

        socket.on('join', (data) => {
            const sessionId = data?.sessionId;
            const userCode = sessionIdToUserCode.get(sessionId);
            if (!userCode) {
                console.log('Invalid sessionId', sessionId);
                // Could be a genuine dead session (server restarted) OR a harmless
                // race where BYOND's 'register' hasn't arrived yet. The client
                // retries a few times and only then gives up, so we don't break
                // the race-recovery path.
                socket.emit('session_invalid');
                socket.emit('update', { type: 'status', data: 'Отключено: неверная сессия' });
                socket.disconnect();
                return;
            }

            clearTimeout(authTimer);
            cancelPurge(userCode);

            // (Re)bind this userCode to this socket. If an older socket still
            // holds it — a stale connection from before a reconnect, or a
            // duplicate tab — unbind and drop that one first so there is exactly
            // one live socket per userCode.
            const prevSocketId = userCodeToSocketId.get(userCode);
            if (prevSocketId && prevSocketId !== socket.id) {
                socketIdToUserCode.delete(prevSocketId);
                const prevSocket = io.sockets.sockets.get(prevSocketId);
                if (prevSocket) {
                    prevSocket.userCode = null;
                    prevSocket.disconnect(true);
                }
            }

            userCodeToSocketId.set(userCode, socket.id);
            socketIdToUserCode.set(socket.id, userCode);
            socket.userCode = userCode;
            // Intentionally keep sessionId -> userCode so the browser can rejoin
            // after a dropped socket. It is cleared when the session truly ends
            // (grace purge, explicit disconnect, or BYOND-side disconnect).

            // Drop any cached proximity packet so the very next location update
            // is force-sent. On a reconnect the client rebuilt from zero peers,
            // so without this the dedupe could withhold the rebuild until someone
            // happened to move, leaving the player connected but hearing nobody.
            forgetUser(userCode);

            console.log(`Associated userCode ${userCode} with socket ${socket.id}`);

            if (socket.micAccessGranted) {
                confirmMicAccess(socket, byondPort);
            }

            socket.emit('update', { type: 'status', data: 'Подключено' });
        });

        socket.on('mic_access_granted', () => {
            socket.micAccessGranted = true;
            confirmMicAccess(socket, byondPort);
        });

        socket.on('disconnect_page', () => {
            // Explicit user-initiated disconnect: purge immediately, no grace.
            const userCode = clearSocketUser(socket);
            if (userCode) {
                purgeUserNow(userCode, byondPort);
                console.log(`Removed userCode ${userCode} on user disconnect.`);
            }

            socket.emit('update', { type: 'status', data: 'Отключение...' });
            socket.disconnect();
        });

        socket.on('disconnect', (reason) => {
            clearTimeout(authTimer);
            const userCode = clearSocketUser(socket);
            if (!userCode) {
                return;
            }

            // Give the client a grace window to reconnect before BYOND is told.
            schedulePurge(userCode, byondPort, io);
            console.log(`Socket for userCode ${userCode} dropped (${reason}); grace timer started.`);
        });

        socket.on('offer', (data) => {
            const targetSocket = getTargetSocket(io, data?.to);
            if (targetSocket) {
                targetSocket.emit('offer', { from: socket.userCode, offer: data.offer, iceRestart: !!data.iceRestart });
            }
        });

        socket.on('answer', (data) => {
            const targetSocket = getTargetSocket(io, data?.to);
            if (targetSocket) {
                targetSocket.emit('answer', { from: socket.userCode, answer: data.answer });
            }
        });

        socket.on('ice-candidate', (data) => {
            const targetSocket = getTargetSocket(io, data?.to);
            if (targetSocket) {
                targetSocket.emit('ice-candidate', { from: socket.userCode, candidate: data.candidate });
            }
        });

        socket.on('voice_activity', (data) => {
            const userCode = socketIdToUserCode.get(socket.id);
            if (!userCode || typeof data?.active !== 'boolean') {
                return;
            }

            sendJSON({ voice_activity: userCode, active: data.active }, byondPort);
        });
    };
}

module.exports = { createConnectionHandler };
