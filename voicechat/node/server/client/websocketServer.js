const express = require('express');
const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');
const { Server } = require('socket.io');

const { createConnectionHandler } = require('./websocketHandlers');
const { handleRequest } = require('../byond/ByondHandlers');
const { sendJSON } = require('../byond/ByondCommunication');

const nodeRootPath = path.resolve(__dirname, '..', '..');
const certPath = path.resolve(nodeRootPath, 'certs');
const publicPath = path.resolve(nodeRootPath, 'public');

function createByondMiddleware(authToken, byondPort, io, shutdown) {
    const router = express.Router();
    router.use(express.json({ limit: '256kb' }));

    router.post('/cmd', (request, response) => {
        const provided = request.get('x-byond-auth');
        if (!authToken || provided !== authToken) {
            response.status(401).json({ error: 'unauthorized' });
            return;
        }

        const payload = request.body;
        if (!payload || typeof payload !== 'object') {
            response.status(400).json({ error: 'bad payload' });
            return;
        }

        try {
            handleRequest(payload, byondPort, io, shutdown);
        } catch (error) {
            console.error('Failed to handle BYOND command:', error);
            sendJSON({ error: error.message, data: payload }, byondPort);
        }

        response.json({ ok: 1 });
    });

    return router;
}

function startWebSocketServer(byondPort, nodePort, authToken, shutdown) {
    const options = {
        key: fs.readFileSync(path.resolve(certPath, 'key.pem')),
        cert: fs.readFileSync(path.resolve(certPath, 'cert.pem')),
    };

    const app = express();
    const httpsServer = https.createServer(options, app);
    const io = new Server(httpsServer);

    // Browser-facing static page + WebSocket signaling (HTTPS, open to LAN).
    app.use(express.static(publicPath));
    app.get('/', (request, response) => {
        response.sendFile(path.resolve(publicPath, 'voicechat.html'));
    });

    // BYOND-facing command endpoint (HTTP, localhost only).
    app.use('/byond', createByondMiddleware(authToken, byondPort, io, shutdown));

    io.on('connection', createConnectionHandler(byondPort, io));

    httpsServer.listen(nodePort, () => {
        console.log(`HTTPS server (browser) running on port ${nodePort}`);
    });

    const bridgePort = nodePort + 1;
    const bridgeServer = http.createServer(app);
    bridgeServer.listen(bridgePort, '127.0.0.1', () => {
        console.log(`HTTP bridge (BYOND) running on 127.0.0.1:${bridgePort}`);
    });

    return { io, server: httpsServer, bridgeServer };
}

function disconnectAllClients(io) {
    if (!io) {
        return;
    }

    io.emit('server-shutdown');
    setTimeout(() => {
        io.sockets.sockets.forEach((socket) => {
            socket.emit('update', { type: 'status', data: 'Отключено: сервер выключается' });
            socket.disconnect(true);
        });
    }, 2000);
}

module.exports = { startWebSocketServer, disconnectAllClients };
