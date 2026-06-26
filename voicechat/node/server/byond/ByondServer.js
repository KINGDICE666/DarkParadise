const fs = require('fs');
const net = require('net');
const path = require('path');

const { sendJSON } = require('./ByondCommunication');
const { handleRequest } = require('./ByondHandlers');

// Windows: net.createServer().listen() accepts the named-pipe path verbatim
// (`\\.\pipe\<name>`). We MUST NOT run it through path.resolve() — that would
// rewrite it to a normal filesystem path under cwd ("C:\.pipe\byond_node"),
// and the DLL on the BYOND side would never find the pipe to connect to.
// Linux: the unix socket lives in the project root, so we do resolve there.
const pipeName = process.platform === 'win32' ? '\\\\.\\pipe\\byond_node' : 'byond_node.sock';
const pipePath = process.platform === 'win32' ? pipeName : path.resolve(process.cwd(), pipeName);

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
        // The byondsocket library opens a fresh pipe connection, writes exactly
        // one JSON message and closes it. A stream is therefore one message — but
        // a single 'data' event is NOT guaranteed to carry the whole thing: a
        // large location packet (many players) gets split across several chunks.
        // Parsing each chunk on its own produced spurious "Invalid JSON" errors
        // and dropped commands. Accumulate every chunk and parse once on 'end'.
        let buffer = '';
        stream.on('data', (chunk) => {
            buffer += chunk.toString('utf-8');
        });

        stream.on('end', () => {
            const message = buffer.trim();
            if (!message) {
                return;
            }

            try {
                const json = JSON.parse(message);
                handleRequest(json, byondPort, io, shutdown);
            } catch (error) {
                console.error('Invalid JSON from BYOND:', error.message, '| raw:', message);
                sendJSON({ error: 'invalid JSON', data: error.message }, byondPort);
            }
        });

        stream.on('error', (error) => {
            console.error('BYOND pipe stream error:', error.message);
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
