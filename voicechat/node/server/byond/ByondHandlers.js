const { sendJSON } = require('./ByondCommunication');
const { sessionIdToUserCode, userCodeToSocketId, socketIdToUserCode } = require('../state');
const { handleLocationPacket } = require('../proximity');

function reportCommandError(byondPort, errorMessage, data) {
    console.log(`error: ${errorMessage}`);
    sendJSON({ error: errorMessage, data }, byondPort);
}

function getSocketForUserCode(io, userCode) {
    const socketId = userCodeToSocketId.get(userCode);
    if (!socketId) {
        return null;
    }

    return io.sockets.sockets.get(socketId);
}

function handleSocketCommand(data, byondPort, io, eventName) {
    const userCode = data.userCode;
    if (!userCode) {
        reportCommandError(byondPort, 'Missing or invalid data: userCode', data);
        return;
    }

    const socket = getSocketForUserCode(io, userCode);
    if (!socket) {
        // Routine race: BYOND asked us to act on a user whose browser socket has
        // already dropped (or is mid-reconnect). Not an error worth echoing back
        // to BYOND — that would just spam the admins with "socket not found".
        console.log(`Ignoring ${eventName} for ${userCode}: no live socket.`);
        return;
    }

    socket.emit(eventName);
}

function handleRequest(data, byondPort, io, shutdown) {
    try {
        const { cmd } = data;
        if (!cmd || typeof cmd !== 'string') {
            reportCommandError(byondPort, 'Missing or invalid command', data);
            return;
        }

        const commandHandlers = {
            ping: () => {
                console.log(data.message);
                sendJSON({ pong: 'Hello from Node', time: data.time }, byondPort);
            },
            register: () => {
                if (!data.sessionId || !data.userCode) {
                    reportCommandError(byondPort, 'Missing or invalid data: sessionId or userCode', data);
                    return;
                }

                sessionIdToUserCode.set(data.sessionId, data.userCode);
                console.log(`Registered sessionId: ${data.sessionId} with userCode: ${data.userCode}`);
            },
            stop_node: () => shutdown(),
            deafen: () => handleSocketCommand(data, byondPort, io, 'deafen'),
            mute_mic: () => handleSocketCommand(data, byondPort, io, 'mute_mic'),
            loc: () => handleLocationPacket(data, io),
            disconnect: () => {
                const userCode = data.userCode;
                if (!userCode) {
                    reportCommandError(byondPort, 'Missing or invalid data: userCode', data);
                    return;
                }

                console.log(`userCode ${userCode} disconnected from byond, cleaning up...`);

                const socketId = userCodeToSocketId.get(userCode);
                const socket = getSocketForUserCode(io, userCode);
                if (!socketId || !socket) {
                    // Already gone (e.g. the browser closed first). BYOND just
                    // wants the user removed, which is already true — log quietly
                    // instead of echoing an error back and spamming the admins.
                    console.log(`Disconnect for ${userCode}: no live socket, already removed.`);
                    return;
                }

                userCodeToSocketId.delete(userCode);
                socketIdToUserCode.delete(socketId);
                socket.userCode = null;
                socket.emit('update', { type: 'status', data: 'Отключено: клиент BYOND сменился' });
                socket.disconnect();
            },
            mute_userCode: () => {
                const userCodeFiring = data.userCodeFiring;
                const userCodeMuting = data.userCodeMuting;
                const muting = data.muting;
                if (!userCodeFiring || !userCodeMuting || typeof muting !== 'boolean') {
                    reportCommandError(byondPort, 'Missing or invalid data: userCodeFiring or userCodeMuting or muting', data);
                    return;
                }

                const socket = getSocketForUserCode(io, userCodeFiring);
                if (!socket) {
                    reportCommandError(byondPort, 'socket not found', data);
                    return;
                }

                socket.emit('mute_usercode', { userCode: userCodeMuting, mute: muting });
            },
        };

        const handler = commandHandlers[cmd];
        if (!handler) {
            console.log(`error: Unknown command cmd:${cmd}`);
            sendJSON({ error: 'Unknown command', cmd, data }, byondPort);
            return;
        }

        handler();
    } catch (error) {
        console.error('Error processing request:', error);
        sendJSON({ error: error.message, data }, byondPort);
    }
}

module.exports = { handleRequest };
