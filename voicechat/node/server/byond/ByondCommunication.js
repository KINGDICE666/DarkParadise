const net = require('net');

function formatData(data) {
    return data.startsWith('?') ? data : `?${data}`;
}

function buildPacket(data) {
    const formattedData = formatData(data);
    const dataLength = formattedData.length;
    const remainingSize = dataLength + 6; // Length field value: type (1) + padding (4) + data + null (1)

    if (remainingSize > 65535) {
        throw new Error(`Data exceeds maximum size: ${remainingSize}`);
    }

    const header = Buffer.alloc(9);
    header[1] = 0x83;
    header.writeUInt16BE(remainingSize, 2);

    const queryBuffer = Buffer.from(formattedData, 'utf8');
    const nullBuffer = Buffer.alloc(1); // 0x00

    return Buffer.concat([header, queryBuffer, nullBuffer]);
}

function sendByondTopic(host, port, data, timeout = 5000) {
    return new Promise((resolve, reject) => {
        if (typeof data !== 'string') {
            reject(new Error('Data must be a string'));
            return;
        }

        let packet;
        try {
            packet = buildPacket(data);
        } catch (err) {
            reject(err);
            return;
        }

        const client = new net.Socket();
        client.setTimeout(timeout, () => {
            client.destroy();
            reject(new Error('Connection timeout'));
        });

        client.on('error', (err) => {
            client.destroy();
            reject(err);
        });

        client.connect(port, host, () => {
            client.write(packet, () => {
                client.end();
                resolve();
            });
        });
    });
}

// DreamDaemon's topic accept loop on Windows silently drops rapid sequential
// TCP connects from the same source IP — observed empirically that the second+
// connect within ~1s often never reaches /world/Topic, and close-spaced bursts
// can trip the per-IP spam lockout (1 minute). We serialize all outbound topic
// sends and space them at least MIN_SEND_INTERVAL_MS apart so each one lands
// reliably.
const MIN_SEND_INTERVAL_MS = 1100;

let queueChain = Promise.resolve();
let lastSendAt = 0;

function enqueueSend(host, port, data) {
    const task = queueChain.then(async () => {
        const wait = Math.max(0, MIN_SEND_INTERVAL_MS - (Date.now() - lastSendAt));
        if (wait > 0) {
            await new Promise((resolve) => setTimeout(resolve, wait));
        }

        try {
            await sendByondTopic(host, port, data);
        } finally {
            lastSendAt = Date.now();
        }
    });

    // Swallow errors in the chain so one failure doesn't poison the queue.
    queueChain = task.catch(() => undefined);
    return task;
}

async function sendJSON(data, byondPort) {
    const out = JSON.stringify(data);
    try {
        await enqueueSend('127.0.0.1', byondPort, out);
    } catch (err) {
        console.error('Failed to send command:', err.message);
    }
}

module.exports = { sendJSON };
