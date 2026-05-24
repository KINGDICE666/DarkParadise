const fs = require('fs');
const net = require('net');
const path = require('path');

const { sendJSON } = require('./ByondCommunication');
const { handleRequest } = require('./ByondHandlers');

const pipeName = process.platform === 'win32' ? '\\\\.\\pipe\\byond_node' : 'byond_node.sock';
const pipePath = path.resolve(process.cwd(), pipeName);

function cleanUpExistingSocket(socketPath) {
    if (process.platform === 'win32') {
        return;
    }

    if (!fs.existsSync(socketPath)) {
        return;
    }

    console.log(`Found existing named socket at ${pipeName}, removing...`);
    fs.unlinkSync(socketPath);
}

function startByondServer(byondPort, io, shutdown) {
    const byondServer = net.createServer((stream) => {
        stream.on('data', (data) => {
            const jsonString = data.toString('utf-8');

            try {
                const json = JSON.parse(jsonString);
                handleRequest(json, byondPort, io, shutdown);
            } catch (error) {
                console.log(jsonString);
                console.error('Invalid JSON:', error);
                sendJSON({ error: 'invalid JSON', data: error.message }, byondPort);
            }
        });
    });

    cleanUpExistingSocket(pipePath);
    byondServer.listen(pipePath, () => {
        console.log(`socket server listening on ${pipeName}`);
    });

    byondServer.on('error', (error) => {
        console.error('Pipe server error:', error);
    });

    return byondServer;
}

module.exports = { startByondServer };
