const express = require('express');
const fs = require('fs');
const https = require('https');
const path = require('path');
const { Server } = require('socket.io');

const { createConnectionHandler } = require('./websocketHandlers');

const nodeRootPath = path.resolve(__dirname, '..', '..');
const certPath = path.resolve(nodeRootPath, 'certs');
const publicPath = path.resolve(nodeRootPath, 'public');

function startWebSocketServer(byondPort, nodePort) {
    const options = {
        key: fs.readFileSync(path.resolve(certPath, 'key.pem')),
        cert: fs.readFileSync(path.resolve(certPath, 'cert.pem')),
    };

    const app = express();
    const server = https.createServer(options, app);
    const io = new Server(server);

    app.use(express.static(publicPath));
    app.get('/', (request, response) => {
        response.sendFile(path.resolve(publicPath, 'voicechat.html'));
    });

    io.on('connection', createConnectionHandler(byondPort, io));

    server.listen(nodePort, () => {
        console.log(`HTTPS server running on port ${nodePort}`);
    });

    return { io, server };
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
