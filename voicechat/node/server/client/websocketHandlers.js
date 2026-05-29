const { sessionIdToUserCode, userCodeToSocketId, socketIdToUserCode } = require('../state');
const { sendJSON } = require('../byond/ByondCommunication');

function clearSocketUser(socket) {
    const userCode = socketIdToUserCode.get(socket.id);
    if (!userCode) {
        return null;
    }

    userCodeToSocketId.delete(userCode);
    socketIdToUserCode.delete(socket.id);
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

// Send confirmation to BYOND exactly once. The previous code fired 4 retries
// within 3 seconds, which on Windows triggered DreamDaemon's per-IP topic spam
// prevention (1-minute lockout after 5 close-spaced requests), and the lockout
// kept extending as more retries piled in. Result: confirms only succeeded
// "sometimes". One send is enough since BYOND's confirm_user_code is idempotent
// and sendJSON now goes through a serializing queue in ByondCommunication.js.
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
                socket.emit('update', { type: 'status', data: 'Отключено: неверная сессия' });
                socket.disconnect();
                return;
            }

            clearTimeout(authTimer);

            if (!socket.userCode) {
                userCodeToSocketId.set(userCode, socket.id);
                socketIdToUserCode.set(socket.id, userCode);
                sessionIdToUserCode.delete(sessionId);
                socket.userCode = userCode;
                console.log(`Associated userCode ${userCode} with socket ${socket.id}`);
            }

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
            const userCode = clearSocketUser(socket);
            if (userCode) {
                sendJSON({ disconnect: userCode }, byondPort);
                console.log(`Removed userCode ${userCode} on disconnect.`);
            }

            socket.emit('update', { type: 'status', data: 'Отключение...' });
            socket.disconnect();
            console.log('User disconnected:', socket.id);
        });

        socket.on('disconnect', (reason) => {
            clearTimeout(authTimer);
            const userCode = clearSocketUser(socket);
            if (!userCode) {
                return;
            }

            sendJSON({ disconnect: userCode }, byondPort);
            console.log(`Removed userCode ${userCode} after socket disconnect: ${reason}`);
        });

        socket.on('offer', (data) => {
            const targetSocket = getTargetSocket(io, data?.to);
            if (targetSocket) {
                targetSocket.emit('offer', { from: socket.userCode, offer: data.offer });
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

            // [VADIAG] Temporary diagnostic: log only real start/stop edges (not
            // hb:true keep-alives) so out.log shows what the browser VAD detected.
            if (!data.hb) {
                console.log(`[VADIAG] ${new Date().toISOString()} userCode=${userCode} active=${data.active} EDGE`);
            }

            sendJSON({ voice_activity: userCode, active: data.active }, byondPort);
        });
    };
}

module.exports = { createConnectionHandler };
