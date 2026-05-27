const { execSync } = require('child_process');
const minimist = require('minimist');

const { startWebSocketServer, disconnectAllClients } = require('./client/websocketServer.js');
const { sendJSON } = require('./byond/ByondCommunication.js');

const argv = minimist(process.argv.slice(2));
const byondPort = Number(argv['byond-port']);
const nodePort = Number(argv['node-port']);
const byondPid = argv['byond-pid'] ? Number(argv['byond-pid']) : null;
const authToken = typeof argv['auth-token'] === 'string' ? argv['auth-token'] : null;

if (!Number.isInteger(byondPort) || !Number.isInteger(nodePort)) {
    console.error('Missing or invalid --byond-port / --node-port arguments.');
    process.exit(1);
}

if (!authToken) {
    console.error('Missing --auth-token argument.');
    process.exit(1);
}

let io = null;
let webSocketServer = null;
let bridgeServer = null;
let shuttingDown = false;

function closeServer(server, callback) {
    if (!server || !server.listening) {
        callback();
        return;
    }

    server.close(callback);
}

function shutdown() {
    if (shuttingDown) {
        return;
    }

    shuttingDown = true;
    sendJSON({ shutting_down: 1 }, byondPort);
    disconnectAllClients(io);

    if (!io) {
        process.exit(0);
        return;
    }

    io.close(() => {
        closeServer(webSocketServer, () => {
            closeServer(bridgeServer, () => {
                console.log('Voice chat server shut down.');
                setTimeout(() => process.exit(0), 2000);
            });
        });
    });
}

function isParentRunning() {
    if (!byondPid) {
        return true;
    }

    if (process.platform === 'win32') {
        try {
            const output = execSync(`tasklist /FI "PID eq ${byondPid}"`).toString();
            return output.includes(byondPid.toString());
        } catch (error) {
            return false;
        }
    }

    try {
        process.kill(byondPid, 0);
        return true;
    } catch (error) {
        return false;
    }
}

function monitorParentProcess() {
    setInterval(() => {
        if (isParentRunning()) {
            return;
        }

        console.log('Parent process terminated, shutting down Node.js server.');
        shutdown();
    }, 10_000);
}

if (byondPid) {
    monitorParentProcess();
}

({ io, server: webSocketServer, bridgeServer } = startWebSocketServer(byondPort, nodePort, authToken, shutdown));

setTimeout(() => {
    sendJSON({ node_started: process.pid }, byondPort);
}, 1500);

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
