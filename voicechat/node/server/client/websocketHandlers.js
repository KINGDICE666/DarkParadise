const { sessionIdToUserCode, userCodeToSocketId, socketIdToUserCode } = require('../state');
const { sendJSON } = require('../byond/ByondCommunication');

const MIC_CONFIRM_RETRY_DELAYS_MS = [0, 500, 1500, 3000];

function clearSocketUser(socket) {
    const userCode = socketIdToUserCode.get(socket.id);
    if (!userCode) {
        return null;
    }

    clearMicConfirmTimers(socket);
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

function clearMicConfirmTimers(socket) {
    if (!socket.micConfirmTimers) {
        return;
    }

    socket.micConfirmTimers.forEach((timer) => clearTimeout(timer));
    socket.micConfirmTimers = null;
}

function confirmMicAccess(socket, byondPort) {
    const userCode = socketIdToUserCode.get(socket.id);
    if (!userCode || socket.micConfirmed) {
        return;
    }

    socket.micConfirmed = true;
    clearMicConfirmTimers(socket);
    socket.micConfirmTimers = MIC_CONFIRM_RETRY_DELAYS_MS.map((delayMs, index) => setTimeout(() => {
        const currentUserCode = socketIdToUserCode.get(socket.id);
        if (!currentUserCode) {
            return;
        }

        sendJSON({ confirmed: currentUserCode }, byondPort);
        const suffix = index === 0 ? '' : ` retry ${index}`;
        console.log(`Sent microphone confirmation for userCode ${currentUserCode}.${suffix}`);
    }, delayMs));
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

            sendJSON({ voice_activity: userCode, active: data.active }, byondPort);
        });
    };
}

module.exports = { createConnectionHandler };
