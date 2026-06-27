// Constants and Configuration
const ICE_SERVERS = [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
];
const DEFAULT_VOLUME_THRESHOLD = 0.01;
const VAD_DEBOUNCE_TIME = 200; // ms
// How often the voice-activity loop samples the mic. We use setInterval rather
// than requestAnimationFrame because rAF is paused while the page is not
// visible/focused (e.g. you switch to Discord), which would freeze voice
// detection. Timers keep firing, and a page holding an active mic + WebRTC
// connection is exempt from background timer throttling, so VAD keeps working.
const VAD_POLL_INTERVAL_MS = 50; // ms (~20 Hz, plenty for speech detection)
// While speaking, re-announce voice_activity:true on this cadence. The
// Node->BYOND bridge sends one TCP world.Topic per message over loopback and can
// silently drop packets, so a single lost "started speaking" message would mean
// no bubble. Re-sending lets a drop self-heal within one beat, and BYOND expires
// the overlay on its own once these stop (see VOICECHAT_SPEAKING_TIMEOUT).
const VOICE_ACTIVITY_HEARTBEAT_MS = 500; // ms
const GAIN_SCALE_FACTOR = 50; // Slider 0-100 maps to gain 0-2
// If an established peer connection drops to "disconnected", give ICE this long
// to recover on its own before we force an ICE restart.
const ICE_DISCONNECT_GRACE_MS = 3000;

// Global State
let socket;
let localStream = null;
let peerConnections = new Map();
let audioElements = new Map();
let audioSenders = new Map();
// Received audio is rendered through a single persistent Web Audio graph
// (playbackContext) instead of each <audio> element's own playout. A hidden /
// background tab throttles media-element playout, so the WebRTC jitter buffer
// drifts and latency grows without bound until it breaks — the "voice lags then
// dies until I refocus the tab" bug. The Web Audio render thread is not subject
// to that throttling, so playout stays in sync while the game is in front.
let playbackContext = null;
let masterGain = null; // Deafen cuts this to 0; everyone routes through it.
let peerAudioNodes = new Map(); // userCode -> { source, gain }
let audioContextWatchdog = null;
let distances = new Map();
let mutedUsers = new Map();
let gainNode = null;
let gainAudioContext = null;
let vadAudioContext = null;
let vadAnalyser = null;
let vadSource = null;
let isVoiceActive = false;
let lastActiveTime = 0;
let voiceActivityHeartbeat = null;
let vadInterval = null;
let isDeafened = false;
let isManuallyMuted = false;
let isMicTesting = false;
let previousDeafenedState = false;
let testAudioContext = null;
let testSource = null;
let delayNode = null;
let volumeThreshold = DEFAULT_VOLUME_THRESHOLD;
let sinkId = null; // Output device ID
// Set by the server (proximity packet) whenever this client is a ghost/observer.
// Ghosts may hear nearby living players but must never transmit, so this gates
// both the outbound WebRTC senders and voice-activity reporting.
let isListenOnly = false;
let micAccessGranted = false;
// Consecutive "invalid session" rejections from the server. A couple are normal
// (register/join race); after several the session is treated as dead.
let invalidJoinCount = 0;

// Extract sessionId from URL
const urlParams = new URLSearchParams(window.location.search);
const sessionId = urlParams.get('sessionId');
const isPopupMode = urlParams.get('popup') === '1';

// Extract ip from url
const address = window.location.host;

if (isPopupMode && window.outerWidth > 0) {
    window.resizeTo(360, 640);
}

// Utility Functions
function setButtonToggled(buttonId, isToggled) {
    const button = document.getElementById(buttonId);
    if (!button) {
        return;
    }

    button.classList.toggle('toggled', isToggled);
    button.setAttribute('aria-pressed', String(isToggled));
}

function toggleRoomStatus(isConnected) {
    const roomStatus = document.getElementById('room_status');
    if (isConnected) {
        roomStatus.src = 'fastclown.gif';
    } else {
        roomStatus.src = 'stopclown.png';
    }
    roomStatus.classList.toggle('active', isConnected);
}

function updateStatus(message) {
    document.getElementById('status').innerText = message;
}

// Audio Device Management
async function populateDevices() {
    const devices = await navigator.mediaDevices.enumerateDevices();
    const audioInputs = devices.filter(device => device.kind === 'audioinput');
    const audioOutputs = devices.filter(device => device.kind === 'audiooutput');

    const inputSelect = document.getElementById('audioInput');
    inputSelect.innerHTML = audioInputs.map(device =>
        `<option value="${device.deviceId}" ${device.deviceId === 'default' ? 'selected' : ''}>${device.label || 'Микрофон по умолчанию'}</option>`
    ).join('');

    const outputSelect = document.getElementById('audioOutput');
    outputSelect.innerHTML = audioOutputs.map(device =>
        `<option value="${device.deviceId}" ${device.deviceId === 'default' ? 'selected' : ''}>${device.label || 'Вывод по умолчанию'}</option>`
    ).join('');
}

async function handleInputChange(event) {
    const deviceId = event.target.value;
    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
    }

    localStream = await navigator.mediaDevices.getUserMedia({
        audio: { deviceId: { exact: deviceId } }
    });

    setupGainNode(localStream);
    setupVoiceActivityDetection();
    updateAudioSenders();

    if (isMicTesting) {
        stopMicTestPlayback();
        startMicTestPlayback();
    }
}

async function handleOutputChange(event) {
    sinkId = event.target.value;
    // Playback runs through the shared AudioContext, so the output device is
    // selected on the context (Chrome 110+). Falls back to the system default
    // on browsers without AudioContext.setSinkId.
    if (playbackContext && playbackContext.setSinkId) {
        playbackContext.setSinkId(sinkId).catch(err => console.warn('Failed to set audio output:', err));
    }
}

// Microphone Access
async function getMic() {
    if (!navigator.mediaDevices?.getUserMedia) {
        updateStatus('Браузер не поддерживает доступ к микрофону');
        return;
    }

    try {
        localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        await populateDevices();
        setupGainNode(localStream);
        setupVoiceActivityDetection();
        micAccessGranted = true;
        if (socket && socket.connected) {
            socket.emit('mic_access_granted');
        }
    } catch (err) {
        console.error('Failed to get microphone access:', err);
        updateStatus('Нет доступа к микрофону');
    }
}
// Gain and Volume Control
function setupGainNode(stream) {
    const audioTrack = stream.getAudioTracks()[0];
    if (!audioTrack) {
        console.error('No audio track found in stream');
        return;
    }

    const ctx = new AudioContext();
    gainAudioContext = ctx;
    // Chrome creates AudioContexts in "suspended" state unless the page has a
    // user gesture. A suspended context freezes the whole graph: no gain
    // processing (outgoing audio is silent) and the VAD analyser reads zeros
    // (no speech ever detected, no overlay). Try to resume immediately; if it
    // can't yet, resumeAllAudioContexts() retries on the first interaction.
    ctx.resume().catch(() => {});
    const src = ctx.createMediaStreamSource(new MediaStream([audioTrack]));
    const dst = ctx.createMediaStreamDestination();
    gainNode = ctx.createGain();

    src.connect(gainNode);
    gainNode.connect(dst);

    stream.removeTrack(audioTrack);
    stream.addTrack(dst.stream.getAudioTracks()[0]);

    updateGainFromSlider();
}

function updateGainFromSlider() {
    if (!gainNode) {
        console.warn('Gain node not initialized');
        return;
    }
    const sliderValue = parseFloat(document.getElementById('input_slider').value);
    const gainValue = sliderValue / GAIN_SCALE_FACTOR;
    gainNode.gain.value = gainValue;
}

function updateSensitivity() {
    const sliderValue = parseFloat(document.getElementById('sensitivity_slider').value);
    if (!isNaN(sliderValue)) {
        volumeThreshold = sliderValue;
    }
}

function updateVolumes() {
    const masterVolume = parseFloat(document.getElementById('volume_slider').value);
    peerAudioNodes.forEach((nodes, userCode) => {
        const isMuted = mutedUsers.get(userCode);
        if (!isMuted) {
            const dist = distances.get(userCode) || 0;
            const linearBase = Math.max(0, 1 - dist / 10);
            nodes.gain.gain.value = linearBase * masterVolume;
        } else {
            nodes.gain.gain.value = 0;
        }
    });
}

// Voice Activity Detection (VAD)
function setupVoiceActivityDetection() {
    if (vadInterval) {
        clearInterval(vadInterval);
        vadInterval = null;
    }
    if (vadAudioContext) {
        vadAudioContext.close();
    }

    vadAudioContext = new (window.AudioContext || window.webkitAudioContext)();
    // See setupGainNode: a suspended context makes the analyser read silence,
    // so voice activity is never detected and the speaking overlay never shows.
    vadAudioContext.resume().catch(() => {});
    vadSource = vadAudioContext.createMediaStreamSource(localStream);
    vadAnalyser = vadAudioContext.createAnalyser();
    vadAnalyser.fftSize = 2048;
    const bufferLength = vadAnalyser.frequencyBinCount;
    const dataArray = new Float32Array(bufferLength);

    vadSource.connect(vadAnalyser);

    function getRMS() {
        vadAnalyser.getFloatTimeDomainData(dataArray);
        let sum = 0;
        for (let i = 0; i < bufferLength; i++) {
            sum += dataArray[i] * dataArray[i];
        }
        return Math.sqrt(sum / bufferLength);
    }

    function monitorAudio() {
        const rms = getRMS();
        const now = Date.now();

        const indicator = document.getElementById('mic_test_visual_indicator');
        if (indicator) {
            const level = Math.min(1, rms / 0.5) * 100;
            const detected = rms > volumeThreshold;
            indicator.style.backgroundColor = detected ? 'green' : 'grey';
            indicator.style.width = `${level}%`;
        }

        // Ghosts (listen-only) and muted users never become "voice active", so
        // they neither transmit audio nor raise a speaking bubble in game.
        if (!isManuallyMuted && !isListenOnly) {
            if (rms > volumeThreshold) {
                lastActiveTime = now;
                if (!isVoiceActive) {
                    isVoiceActive = true;
                    handleVoiceActivityChange(true);
                }
            } else if (isVoiceActive && now - lastActiveTime > VAD_DEBOUNCE_TIME) {
                isVoiceActive = false;
                handleVoiceActivityChange(false);
            }
        } else {
            if (isVoiceActive) {
                isVoiceActive = false;
                handleVoiceActivityChange(false);
            }
        }
    }

    vadInterval = setInterval(monitorAudio, VAD_POLL_INTERVAL_MS);
}

function handleVoiceActivityChange(active) {
    const voiceStatus = document.getElementById('voice_activity_status');
    voiceStatus.classList.toggle('active', active);
    emitVoiceActivity(active);
    updateAudioSenders();
}

// Sends a voice_activity edge and manages the keep-alive heartbeat. While
// active, a timer re-emits active:true so a dropped Node->BYOND topic recovers
// on the next beat; on stop, the timer is cleared and the single active:false
// edge is sent (BYOND also auto-expires the overlay if that edge is lost).
function emitVoiceActivity(active) {
    if (socket) {
        socket.emit('voice_activity', { active });
    }

    if (active) {
        if (!voiceActivityHeartbeat) {
            voiceActivityHeartbeat = setInterval(() => {
                if (socket && isVoiceActive) {
                    socket.emit('voice_activity', { active: true });
                }
            }, VOICE_ACTIVITY_HEARTBEAT_MS);
        }
    } else if (voiceActivityHeartbeat) {
        clearInterval(voiceActivityHeartbeat);
        voiceActivityHeartbeat = null;
    }
}

// Applies a listen-only (ghost) role change pushed by the server. Becoming
// listen-only immediately stops any in-progress transmission; leaving it lets
// the normal VAD path resume.
function applyListenOnly(value) {
    if (isListenOnly === value) {
        return;
    }
    isListenOnly = value;
    if (isListenOnly && isVoiceActive) {
        isVoiceActive = false;
        handleVoiceActivityChange(false);
    }
    updateAudioSenders();
}

// Mute/Deafen Controls
// We swap senders' tracks (not track.enabled) because track.enabled=false
// silences the source, including for VAD's MediaStreamSource — that creates
// a deadlock (no voice activity ever detected). replaceTrack leaves the local
// track running for VAD; only the outbound WebRTC sender sees null when we
// shouldn't transmit. This matches the upstream SS1984 / SurfShack design.
function updateAudioSenders() {
    if (!localStream) return;
    const shouldSend = !isManuallyMuted && !isDeafened && isVoiceActive && !isListenOnly;
    const track = shouldSend ? localStream.getAudioTracks()[0] : null;
    audioSenders.forEach(sender => {
        sender.replaceTrack(track).catch(err => console.warn('replaceTrack failed:', err.message));
    });
}

function toggleMute(forceMute = false) {
    if (!localStream) return;
    if (isDeafened && !forceMute) {
        toggleDeafen();
        return;
    }
    isManuallyMuted = forceMute ? true : !isManuallyMuted;
    if (isManuallyMuted && isVoiceActive) {
        isVoiceActive = false;
        handleVoiceActivityChange(false);
    }
    updateAudioSenders();
    setButtonToggled('mute_toggle', isManuallyMuted);
}

function toggleDeafen(forceDeafen = false) {
    if (!localStream) return;
    isDeafened = forceDeafen ? true : !isDeafened;
    isManuallyMuted = isDeafened;
    // Elements stay muted (playback is via Web Audio); deafen cuts the shared
    // master gain so all incoming voice is silenced at once.
    if (masterGain) {
        masterGain.gain.value = isDeafened ? 0 : 1;
    }
    if (isDeafened && isVoiceActive) {
        isVoiceActive = false;
        handleVoiceActivityChange(false);
    }
    updateAudioSenders();
    setButtonToggled('mute_toggle', isManuallyMuted);
    setButtonToggled('deafen_toggle', isDeafened);
}

// Mic Test Functions
function startMicTestPlayback() {
    testAudioContext = new AudioContext();
    testSource = testAudioContext.createMediaStreamSource(localStream);
    delayNode = new DelayNode(testAudioContext, { delayTime: 2 });
    testSource.connect(delayNode);
    delayNode.connect(testAudioContext.destination);
}

function stopMicTestPlayback() {
    if (testSource) testSource.disconnect();
    if (delayNode) delayNode.disconnect();
    if (testAudioContext) testAudioContext.close();
    testAudioContext = null;
    testSource = null;
    delayNode = null;
}

function toggleMicTest() {
    if (!localStream) return;
    isMicTesting = !isMicTesting;
    const button = document.querySelector('.mic_test_container button');
    const buttonsContainer = document.getElementById('buttons');

    if (isMicTesting) {
        previousDeafenedState = isDeafened;
        buttonsContainer.classList.add('hide');
        toggleDeafen(true);
        startMicTestPlayback();
        button.textContent = 'Остановить';
        button.classList.add('toggled');
        button.setAttribute('aria-pressed', 'true');
    } else {
        stopMicTestPlayback();
        if (!previousDeafenedState) toggleDeafen();
        button.textContent = 'Проверить';
        button.classList.remove('toggled');
        button.setAttribute('aria-pressed', 'false');
        buttonsContainer.classList.remove('hide');
    }
}

// --- WebRTC signaling helpers ----------------------------------------------

// ICE candidates can arrive before the remote description is set (trickle ICE).
// addIceCandidate() then throws and the candidate is lost, which is a classic
// cause of half-connected, audio-less peers. Buffer until the remote
// description lands, then flush.
function addRemoteCandidate(pc, candidate) {
    if (!candidate) {
        return;
    }
    if (pc._remoteSet) {
        pc.addIceCandidate(new RTCIceCandidate(candidate))
            .catch(err => console.warn('addIceCandidate failed:', err.message));
    } else {
        pc._pendingCandidates.push(candidate);
    }
}

function flushRemoteCandidates(pc) {
    pc._remoteSet = true;
    const pending = pc._pendingCandidates;
    pc._pendingCandidates = [];
    pending.forEach(candidate =>
        pc.addIceCandidate(new RTCIceCandidate(candidate))
            .catch(err => console.warn('addIceCandidate (flush) failed:', err.message)));
}

// Creates and sends an offer. Used both for the initial offer and for ICE
// restarts (iceRestart=true), which renegotiate connectivity without tearing
// the connection down.
function negotiate(pc, userCode, iceRestart) {
    pc.createOffer(iceRestart ? { iceRestart: true } : undefined)
        .then(offer => pc.setLocalDescription(offer))
        .then(() => socket.emit('offer', { to: userCode, offer: pc.localDescription, iceRestart: !!iceRestart }))
        .catch(err => console.error('Negotiation failed:', err));
}

// Lazily build the shared playback graph: source nodes (one per peer) -> master
// gain -> destination. Created on the first received track so it inherits a user
// gesture (the mic button click), which lets resume() succeed. Routing remote
// audio here rather than through <audio>.volume keeps playout on the real-time
// audio thread, immune to the background-tab throttling that grows latency.
function ensurePlaybackContext() {
    if (!playbackContext) {
        playbackContext = new (window.AudioContext || window.webkitAudioContext)();
        masterGain = playbackContext.createGain();
        masterGain.gain.value = isDeafened ? 0 : 1;
        masterGain.connect(playbackContext.destination);
        if (sinkId && playbackContext.setSinkId) {
            playbackContext.setSinkId(sinkId).catch(err => console.warn('Failed to set audio output:', err));
        }
    }
    playbackContext.resume().catch(() => {});
    return playbackContext;
}

function teardownPeerAudioNodes(userCode) {
    const nodes = peerAudioNodes.get(userCode);
    if (nodes) {
        try { nodes.source.disconnect(); } catch (e) { /* already gone */ }
        try { nodes.gain.disconnect(); } catch (e) { /* already gone */ }
        peerAudioNodes.delete(userCode);
    }
}

// Peer Connection Management
function createPeerConnection(userCode, sendOffer) {
    const pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });
    pc._pendingCandidates = [];
    pc._remoteSet = false;
    pc._sendOffer = sendOffer;
    pc._disconnectTimer = null;
    peerConnections.set(userCode, pc);

    // The element is kept muted: it exists only so Chrome keeps delivering the
    // remote stream's frames (a known requirement for createMediaStreamSource on
    // a remote peer stream — without an attached media sink it yields silence).
    // Actual playback, volume and output-device routing all happen on the
    // playbackContext graph instead.
    const audio = document.createElement('audio');
    audio.autoplay = true;
    audio.muted = true;
    document.body.appendChild(audio);
    audioElements.set(userCode, audio);

    if (localStream) {
        const track = localStream.getAudioTracks()[0];
        const sender = pc.addTrack(track, localStream);
        audioSenders.set(userCode, sender);
        updateAudioSenders(); // Apply current mute/deafen/listen-only state.
    }

    pc.onicecandidate = (event) => {
        if (event.candidate) {
            socket.emit('ice-candidate', { to: userCode, candidate: event.candidate });
        }
    };

    pc.oniceconnectionstatechange = () => {
        const state = pc.iceConnectionState;
        console.log(`ICE connection state for ${userCode}: ${state}`);

        if (state === 'connected' || state === 'completed') {
            if (pc._disconnectTimer) {
                clearTimeout(pc._disconnectTimer);
                pc._disconnectTimer = null;
            }
            return;
        }

        if (state === 'failed') {
            if (pc._disconnectTimer) {
                clearTimeout(pc._disconnectTimer);
                pc._disconnectTimer = null;
            }
            // The offerer owns recovery so the two sides don't both renegotiate
            // at once (glare). The answerer waits for the offerer's restart.
            if (pc._sendOffer) {
                negotiate(pc, userCode, true);
            }
            return;
        }

        if (state === 'disconnected' && pc._sendOffer && !pc._disconnectTimer) {
            // Often recovers on its own; give it a moment before forcing a restart.
            pc._disconnectTimer = setTimeout(() => {
                pc._disconnectTimer = null;
                const current = pc.iceConnectionState;
                if (current === 'disconnected' || current === 'failed') {
                    negotiate(pc, userCode, true);
                }
            }, ICE_DISCONNECT_GRACE_MS);
        }
    };

    pc.ontrack = (event) => {
        const stream = event.streams[0];
        // Attach (muted) to keep frames flowing, then route through Web Audio.
        audio.srcObject = stream;
        const ctx = ensurePlaybackContext();
        teardownPeerAudioNodes(userCode); // Renegotiation can fire ontrack again.
        const source = ctx.createMediaStreamSource(stream);
        const gain = ctx.createGain();
        source.connect(gain);
        gain.connect(masterGain);
        peerAudioNodes.set(userCode, { source, gain });
        updateVolumes(); // Apply distance / per-user mute to the new gain node.
        console.log(`Receiving audio from ${userCode}`);
    };

    if (sendOffer) {
        negotiate(pc, userCode, false);
    }

    return pc;
}

function removePeer(userCode) {
    const pc = peerConnections.get(userCode);
    if (pc) {
        if (pc._disconnectTimer) {
            clearTimeout(pc._disconnectTimer);
            pc._disconnectTimer = null;
        }
        pc.close();
        peerConnections.delete(userCode);
    }
    teardownPeerAudioNodes(userCode);
    const audio = audioElements.get(userCode);
    if (audio) {
        audio.srcObject = null;
        audio.remove();
        audioElements.delete(userCode);
    }
    audioSenders.delete(userCode);
    distances.delete(userCode);
}

// Closes every peer connection without touching the microphone. Used on a
// transient socket drop: the WebSocket reconnects and proximity rebuilds the
// mesh, but the captured mic / gain / VAD graph must survive so the user can
// keep talking the instant they are back.
function closeAllPeers() {
    peerConnections.forEach((pc) => {
        if (pc._disconnectTimer) {
            clearTimeout(pc._disconnectTimer);
        }
        pc.close();
    });
    peerConnections.clear();
    peerAudioNodes.forEach((nodes) => {
        try { nodes.source.disconnect(); } catch (e) { /* already gone */ }
        try { nodes.gain.disconnect(); } catch (e) { /* already gone */ }
    });
    peerAudioNodes.clear();
    audioElements.forEach(audio => {
        audio.srcObject = null;
        audio.remove();
    });
    audioElements.clear();
    audioSenders.clear();
    distances.clear();
}

// Socket Event Handlers
function setupSocketHandlers() {
    socket.on('update', (update) => {
        if (update.type === 'status') {
            updateStatus(update.data);
        }
    });

    socket.on('loc', (data) => {
        applyListenOnly(!!data.listenOnly);

        if (data.none === 1) {
            Array.from(peerConnections.keys()).forEach(removePeer);
            toggleRoomStatus(false);
            return;
        }

        const peers = data['peers'];
        const myUserCode = data['own'];
        const newUserCodes = new Set(Object.keys(peers));
        const currentUserCodes = new Set(peerConnections.keys());

        const added = [...newUserCodes].filter(code => !currentUserCodes.has(code));
        const removed = [...currentUserCodes].filter(code => !newUserCodes.has(code));

        removed.forEach(removePeer);

        added.forEach(code => {
            // Deterministic offerer per pair (lexicographically smaller userCode)
            // so exactly one side sends the initial offer — no glare.
            const sendOffer = myUserCode < code;
            createPeerConnection(code, sendOffer);
        });

        distances = new Map(Object.entries(peers));
        updateVolumes();
        toggleRoomStatus(peerConnections.size > 0);
    });

    socket.on('offer', (data) => {
        const { from, offer, iceRestart } = data;
        console.log(`Received offer from ${from}${iceRestart ? ' (ice restart)' : ''}`);

        let pc = peerConnections.get(from);
        // A fresh (non-restart) offer for a peer we already track means that peer
        // rebuilt its connection — e.g. after its own reconnect. Drop our stale
        // one and build a matching fresh connection so both sides start clean.
        if (pc && !iceRestart) {
            removePeer(from);
            pc = null;
        }
        if (!pc) {
            pc = createPeerConnection(from, false);
        }

        pc.setRemoteDescription(new RTCSessionDescription(offer))
            .then(() => {
                flushRemoteCandidates(pc);
                return pc.createAnswer();
            })
            .then(answer => pc.setLocalDescription(answer))
            .then(() => socket.emit('answer', { to: from, answer: pc.localDescription }))
            .catch(err => console.error('Error handling offer:', err));
    });

    socket.on('answer', (data) => {
        const { from, answer } = data;
        console.log(`Received answer from ${from}`);
        const pc = peerConnections.get(from);
        if (pc) {
            pc.setRemoteDescription(new RTCSessionDescription(answer))
                .then(() => flushRemoteCandidates(pc))
                .catch(err => console.error('Error setting remote description:', err));
        }
    });

    socket.on('ice-candidate', (data) => {
        const { from, candidate } = data;
        const pc = peerConnections.get(from);
        if (pc) {
            addRemoteCandidate(pc, candidate);
        }
    });

    socket.on('server-shutdown', () => {
        console.log('Server is shutting down. Cleaning up...');
        closeAllPeers();
        updateStatus('Сервер голосового чата выключается.');
        toggleRoomStatus(false);
    });

    socket.on('session_invalid', () => {
        // A few rejections are tolerated (the BYOND 'register' for a brand-new
        // session can land just after our first 'join'). But a session that
        // stays invalid means it is genuinely dead — almost always because the
        // voice server restarted — so stop the endless reconnect attempts and
        // tell the player to reopen the link from the game.
        invalidJoinCount += 1;
        if (invalidJoinCount >= 3) {
            socket.io.reconnection(false);
            updateStatus('Сессия недействительна. Нажмите «Подключиться» в игре, чтобы открыть новую ссылку.');
            socket.disconnect();
        }
    });

    socket.on('connect', () => {
        // Fires on the initial connection AND every socket.io reconnect. Re-join
        // with our sessionId so a dropped socket restores the session instead of
        // leaving the player silently disconnected, and re-announce mic access if
        // it was already granted before the drop.
        console.log('Socket connected:', socket.id);
        if (sessionId) {
            socket.emit('join', { sessionId });
        }
        if (micAccessGranted) {
            socket.emit('mic_access_granted');
        }
    });

    socket.on('disconnect', (reason) => {
        console.log(`Socket disconnected: ${reason}`);
        // Drop the peer mesh but KEEP the mic/VAD alive: socket.io will reconnect
        // and proximity rebuilds the connections. Killing localStream here was the
        // old bug that left players permanently muted after any blip.
        closeAllPeers();
        toggleRoomStatus(false);
        updateStatus('Переподключение...');
    });

    socket.on('mute_mic', () => {
        toggleMute();
    });

    socket.on('deafen', () => {
        toggleDeafen();
    });

    // socket.emit('mute_usercode', {userCode: userCodeMuting, mute: muting})
    socket.on('mute_usercode', (data) => {
        const userCode = data['userCode'];
        if (!userCode) {
            return;
        }
        const mute = data['mute'];
        mutedUsers.set(userCode, mute);
        updateVolumes();
    });
}

// Full teardown including the microphone. Only used when the page is actually
// going away (pagehide), never on a transient socket drop.
function cleanupConnections() {
    closeAllPeers();
    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
        localStream = null;
    }
}

// Resumes every AudioContext that browsers may have parked in "suspended"
// state. resume() only succeeds inside (or shortly after) a user gesture, so
// this is wired to the first click/key/touch on the page as a fallback for the
// immediate resume() attempts made when each context is created.
function resumeAllAudioContexts() {
    [gainAudioContext, vadAudioContext, testAudioContext, playbackContext].forEach((ctx) => {
        if (ctx && ctx.state === 'suspended') {
            ctx.resume().catch(() => {});
        }
    });
}

// While the tab is kept in the background (the game window is in front the whole
// session) the focus/visibilitychange events never fire, so a context Chrome
// parks in "suspended" would otherwise stay dead until the player refocuses the
// page. Poll on a slow timer to resume them in place. A page with an active
// mic + audio output is exempt from 1-per-minute background throttling, so this
// keeps ticking at ~1s resolution even when hidden.
function startAudioContextWatchdog() {
    if (audioContextWatchdog) {
        return;
    }
    audioContextWatchdog = setInterval(resumeAllAudioContexts, 2000);
}

// UI Event Listeners
function setupUIListeners() {
    // Unlock audio on the first user interaction (covers the case where the
    // page was opened from the BYOND link with no prior gesture, leaving the
    // AudioContexts suspended — which would silence both VAD and outgoing audio).
    ['pointerdown', 'keydown', 'touchstart'].forEach((evt) => {
        document.addEventListener(evt, resumeAllAudioContexts);
    });

    // Also re-resume when the window regains focus or becomes visible again.
    // Some browsers suspend the AudioContext while another app is in front
    // (e.g. Discord over the game); this brings voice detection straight back
    // when the user returns, without needing an extra click.
    window.addEventListener('focus', resumeAllAudioContexts);
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) {
            resumeAllAudioContexts();
        }
    });

    // Tooltip handling
    const triggers = document.querySelectorAll('.tooltip');
    const tooltip = document.getElementById('tooltip_box');
    triggers.forEach(trigger => {
        trigger.addEventListener('mouseenter', () => {
            tooltip.textContent = trigger.dataset.tip;
        });
    });

    // Buttons
    document.getElementById('mic').addEventListener('click', getMic);
    document.getElementById('mute_toggle').addEventListener('click', () => toggleMute());
    document.getElementById('deafen_toggle').addEventListener('click', () => toggleDeafen());
    document.getElementById('settings_button').addEventListener('click', toggleSettings);
    document.querySelector('.mic_test_container button').addEventListener('click', toggleMicTest);

    // Device changes
    if (navigator.mediaDevices?.addEventListener) {
        navigator.mediaDevices.addEventListener('devicechange', populateDevices);
    }
    document.getElementById('audioInput').addEventListener('change', handleInputChange);
    document.getElementById('audioOutput').addEventListener('change', handleOutputChange);

    // Sliders
    document.getElementById('input_slider').addEventListener('input', updateGainFromSlider);
    document.getElementById('sensitivity_slider').addEventListener('input', updateSensitivity);
    document.getElementById('volume_slider').addEventListener('input', updateVolumes);


    // Cleanup when the page is being hidden/closed. 'unload' is deprecated and
    // unreliable (Chrome no longer fires it in many cases, breaking cleanup);
    // 'pagehide' fires reliably on tab close, navigation, and mobile backgrounding.
    window.addEventListener('pagehide', () => {
        if (vadInterval) {
            clearInterval(vadInterval);
            vadInterval = null;
        }
        if (voiceActivityHeartbeat) {
            clearInterval(voiceActivityHeartbeat);
            voiceActivityHeartbeat = null;
        }
        if (audioContextWatchdog) {
            clearInterval(audioContextWatchdog);
            audioContextWatchdog = null;
        }
        if (socket) {
            socket.emit('disconnect_page');
        }
        if (vadAudioContext) vadAudioContext.close();
        if (playbackContext) playbackContext.close();
        cleanupConnections();
    });
}

function toggleSettings() {
    const settingsMenu = document.getElementById('settings');
    const isOpen = settingsMenu.classList.toggle('open');
    setButtonToggled('settings_button', isOpen);
}

// Initialization
async function init() {
    setupUIListeners();

    if (!sessionId) {
        updateStatus('Откройте ссылку из игры');
        return;
    }

    // reconnection is on by default, but pin the timing explicitly so a flaky
    // network keeps retrying forever with a bounded backoff instead of giving up.
    socket = io(address, {
        rejectUnauthorized: false,
        reconnection: true,
        reconnectionAttempts: Infinity,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        timeout: 20000,
    });
    setupSocketHandlers();
    startAudioContextWatchdog();
    // 'join' is emitted from the socket 'connect' handler so it also runs on
    // every reconnect; no need to emit it here.
    await getMic();
}

init();
