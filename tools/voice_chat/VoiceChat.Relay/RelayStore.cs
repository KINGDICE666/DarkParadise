using System.Collections.Concurrent;
using System.Net;
using System.Net.WebSockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using VoiceChat.Protocol;

namespace VoiceChat.Relay;

public sealed class RelayStore
{
    private readonly byte[] apiKey;
    private readonly ConcurrentDictionary<string, ServerState> servers = new(StringComparer.Ordinal);
    private readonly ConcurrentDictionary<string, TokenGrant> tokens = new(StringComparer.Ordinal);
    private readonly ConcurrentDictionary<RelaySession, TokenGrant> sessionTokens = new();
    private readonly ConcurrentDictionary<string, UdpBinding> udpBindings = new(StringComparer.Ordinal);

    public RelayStore(string apiKey, int udpPort = 3000)
    {
        this.apiKey = Encoding.UTF8.GetBytes(apiKey);
        UdpPort = udpPort;
    }

    public int UdpPort { get; }

    public bool Authenticate(string suppliedKey)
    {
        var suppliedBytes = Encoding.UTF8.GetBytes(suppliedKey);
        return suppliedBytes.Length == apiKey.Length &&
            CryptographicOperations.FixedTimeEquals(suppliedBytes, apiKey);
    }

    public async Task<GameSnapshotResponse> ApplySnapshotAsync(
        GameSnapshotRequest snapshot,
        CancellationToken cancellationToken)
    {
        RemoveExpiredTokens();
        var server = servers.GetOrAdd(snapshot.ServerId, static serverId => new ServerState(serverId));
        server.ProximityRange = Math.Clamp(snapshot.ProximityRange, 1, 15);
        var seenSessions = new HashSet<string>(StringComparer.Ordinal);

        foreach (var gameSession in snapshot.Sessions)
        {
            if (!Guid.TryParseExact(gameSession.SessionId, "N", out _))
            {
                continue;
            }

            seenSessions.Add(gameSession.SessionId);
            var session = server.Sessions.GetOrAdd(
                gameSession.SessionId,
                sessionId => new RelaySession(server, sessionId, UdpPort));
            session.UpdateSnapshot(gameSession);
            if (session.Connection is not null)
            {
                await session.Connection.SendConfigAsync(session.CreateHelperConfig(), cancellationToken);
            }
        }

        foreach (var existingSession in server.Sessions)
        {
            if (seenSessions.Contains(existingSession.Key) ||
                !server.Sessions.TryRemove(existingSession.Key, out var removedSession))
            {
                continue;
            }

            await removedSession.CloseConnectionAsync("session_removed", cancellationToken);
        }

        var responses = new List<RelaySessionResponse>(seenSessions.Count);
        foreach (var sessionId in seenSessions)
        {
            var session = server.Sessions[sessionId];
            if (!session.Snapshot.WantsConnection)
            {
                await session.CloseConnectionAsync("disconnected_by_game", cancellationToken);
            }

            var connectToken = string.Empty;
            if (session.Snapshot.WantsConnection && session.Connection is null)
            {
                connectToken = IssueToken(session);
            }

            responses.Add(session.CreateGameResponse(connectToken));
        }

        return new GameSnapshotResponse { Sessions = responses };
    }

    public bool TryConsumeToken(string token, out RelaySession session)
    {
        session = null!;
        if (!tokens.TryRemove(token, out var grant) || grant.ExpiresAt <= DateTimeOffset.UtcNow)
        {
            return false;
        }

        session = grant.Session;
        return session.Snapshot.WantsConnection;
    }

    public async Task RunConnectionAsync(
        RelaySession session,
        WebSocket socket,
        CancellationToken cancellationToken)
    {
        var connection = new RelayConnection(socket);
        udpBindings[connection.UdpToken] = new UdpBinding(session, connection);
        var previousConnection = session.ReplaceConnection(connection);
        if (previousConnection is not null)
        {
            await previousConnection.CloseAsync("replaced", cancellationToken);
        }

        try
        {
            await connection.SendConfigAsync(session.CreateHelperConfig(), cancellationToken);
            await ReceiveLoopAsync(session, connection, cancellationToken);
        }
        finally
        {
            session.RemoveConnection(connection);
            udpBindings.TryRemove(
                new KeyValuePair<string, UdpBinding>(
                    connection.UdpToken,
                    new UdpBinding(session, connection)));
        }
    }

    public bool TryRegisterUdpEndpoint(
        ReadOnlySpan<byte> token,
        IPEndPoint endpoint,
        out RelayConnection connection)
    {
        connection = null!;
        var tokenText = Convert.ToBase64String(token);
        if (!udpBindings.TryGetValue(tokenText, out var binding) ||
            binding.Session.Connection != binding.Connection)
        {
            return false;
        }

        binding.Connection.SetUdpEndpoint(endpoint);
        connection = binding.Connection;
        return true;
    }

    public bool TryResolveUdpSender(
        ReadOnlySpan<byte> token,
        IPEndPoint endpoint,
        out RelaySession session)
    {
        session = null!;
        var tokenText = Convert.ToBase64String(token);
        if (!udpBindings.TryGetValue(tokenText, out var binding) ||
            binding.Session.Connection != binding.Connection ||
            !binding.Connection.IsUdpEndpoint(endpoint))
        {
            return false;
        }

        session = binding.Session;
        return true;
    }

    public async Task RouteUdpAudioAsync(
        RelaySession speaker,
        ReadOnlyMemory<byte> frame,
        Func<ReadOnlyMemory<byte>, IPEndPoint, CancellationToken, ValueTask> sendUdpAsync,
        CancellationToken cancellationToken)
    {
        if (!TryValidateAudioFrame(speaker, frame.Span, out var speakerId))
        {
            return;
        }

        var sends = new List<Task>();
        foreach (var listener in speaker.Server.Sessions.Values)
        {
            var connection = listener.Connection;
            if (listener == speaker || connection is null ||
                !TryGetSpatialVolume(speaker, listener, out var spatialVolume))
            {
                continue;
            }

            var outboundFrame = VoiceProtocol.CreateRelayAudioFrame(
                speakerId,
                spatialVolume,
                frame.Span);
            var udpEndpoint = connection.UdpEndpoint;
            if (udpEndpoint is not null)
            {
                var datagram = VoiceProtocol.CreateUdpRelayAudioFrame(
                    connection.UdpTokenBytes,
                    outboundFrame);
                sends.Add(sendUdpAsync(datagram, udpEndpoint, cancellationToken).AsTask());
            }
            else
            {
                sends.Add(connection.SendBinaryAsync(outboundFrame, cancellationToken));
            }
        }

        await Task.WhenAll(sends);
    }

    private async Task ReceiveLoopAsync(
        RelaySession session,
        RelayConnection connection,
        CancellationToken cancellationToken)
    {
        var buffer = new byte[8192];
        while (connection.Socket.State == WebSocketState.Open && !cancellationToken.IsCancellationRequested)
        {
            WebSocketReceiveResult result;
            try
            {
                result = await connection.Socket.ReceiveAsync(buffer, cancellationToken);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                break;
            }
            catch (WebSocketException)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }
            if (result.MessageType == WebSocketMessageType.Close)
            {
                break;
            }

            if (!result.EndOfMessage)
            {
                await connection.CloseAsync("message_too_large", cancellationToken);
                return;
            }

            if (result.MessageType == WebSocketMessageType.Text)
            {
                ApplyHelperStatus(session, buffer.AsSpan(0, result.Count));
                continue;
            }

            if (result.MessageType == WebSocketMessageType.Binary)
            {
                await RouteAudioAsync(session, buffer.AsMemory(0, result.Count), cancellationToken);
            }
        }
    }

    private static void ApplyHelperStatus(RelaySession session, ReadOnlySpan<byte> utf8Json)
    {
        try
        {
            var status = JsonSerializer.Deserialize<HelperStatusMessage>(utf8Json, VoiceProtocol.JsonOptions);
            if (status?.Type == "status")
            {
                session.UpdateStatus(status);
            }
        }
        catch (JsonException)
        {
            session.UpdateStatus(new HelperStatusMessage { Error = "invalid_helper_status" });
        }
    }

    private static async Task RouteAudioAsync(
        RelaySession speaker,
        ReadOnlyMemory<byte> frame,
        CancellationToken cancellationToken)
    {
        if (!TryValidateAudioFrame(speaker, frame.Span, out var speakerId))
        {
            return;
        }

        var sends = new List<Task>();
        foreach (var listener in speaker.Server.Sessions.Values)
        {
            if (listener == speaker || listener.Connection is null ||
                !TryGetSpatialVolume(speaker, listener, out var spatialVolume))
            {
                continue;
            }

            var outboundFrame = VoiceProtocol.CreateRelayAudioFrame(
                speakerId,
                spatialVolume,
                frame.Span);
            sends.Add(listener.Connection.SendBinaryAsync(outboundFrame, cancellationToken));
        }

        await Task.WhenAll(sends);
    }

    private static bool TryValidateAudioFrame(
        RelaySession speaker,
        ReadOnlySpan<byte> frame,
        out Guid speakerId)
    {
        speakerId = default;
        var snapshot = speaker.Snapshot;
        return frame.Length >= 6 && frame.Length <= VoiceProtocol.MaximumOpusPacketBytes + 5 &&
            frame[0] == VoiceProtocol.ClientAudioFrame && snapshot.WantsConnection &&
            snapshot.CanSpeak && !snapshot.Muted && snapshot.Position is not null &&
            Guid.TryParseExact(snapshot.SessionId, "N", out speakerId);
    }

    private static bool TryGetSpatialVolume(
        RelaySession speaker,
        RelaySession listener,
        out byte spatialVolume)
    {
        spatialVolume = 0;
        var source = speaker.Snapshot;
        var target = listener.Snapshot;
        if (!target.WantsConnection || !target.CanListen || target.Deafened ||
            source.Position is null || target.Position is null ||
            source.Position.Z != target.Position.Z || target.MutedPeers.Contains(source.SessionId))
        {
            return false;
        }

        var distance = Math.Max(
            Math.Abs(source.Position.X - target.Position.X),
            Math.Abs(source.Position.Y - target.Position.Y));
        if (distance > speaker.Server.ProximityRange)
        {
            return false;
        }

        spatialVolume = (byte)Math.Clamp(
            100 - distance * 85 / speaker.Server.ProximityRange,
            15,
            100);
        return true;
    }

    private string IssueToken(RelaySession session)
    {
        var now = DateTimeOffset.UtcNow;
        if (sessionTokens.TryGetValue(session, out var currentGrant) &&
            currentGrant.ExpiresAt > now && tokens.ContainsKey(currentGrant.Token))
        {
            return currentGrant.Token;
        }

        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
        var grant = new TokenGrant(token, session, now.AddSeconds(30));
        tokens[token] = grant;
        sessionTokens[session] = grant;
        return token;
    }

    private void RemoveExpiredTokens()
    {
        var now = DateTimeOffset.UtcNow;
        foreach (var token in tokens)
        {
            if (token.Value.ExpiresAt <= now)
            {
                tokens.TryRemove(token.Key, out _);
            }
        }
    }

    private sealed record TokenGrant(string Token, RelaySession Session, DateTimeOffset ExpiresAt);
    private sealed record UdpBinding(RelaySession Session, RelayConnection Connection);
}

public sealed class ServerState
{
    public ServerState(string serverId)
    {
        ServerId = serverId;
    }

    public string ServerId { get; }
    public int ProximityRange { get; set; } = 7;
    public ConcurrentDictionary<string, RelaySession> Sessions { get; } = new(StringComparer.Ordinal);
}

public sealed class RelaySession
{
    private readonly object gate = new();
    private GameSessionSnapshot snapshot;
    private HelperStatusMessage helperStatus = new();
    private RelayConnection? connection;

    public RelaySession(ServerState server, string sessionId, int udpPort = 3000)
    {
        Server = server;
        UdpPort = udpPort;
        snapshot = new GameSessionSnapshot
        {
            SessionId = sessionId,
            DisplayName = string.Empty,
        };
    }

    public ServerState Server { get; }
    public int UdpPort { get; }

    public GameSessionSnapshot Snapshot
    {
        get
        {
            lock (gate)
            {
                return snapshot;
            }
        }
    }

    public RelayConnection? Connection
    {
        get
        {
            lock (gate)
            {
                return connection;
            }
        }
    }

    public void UpdateSnapshot(GameSessionSnapshot value)
    {
        lock (gate)
        {
            snapshot = value with
            {
                InputGain = Math.Clamp(value.InputGain, 0, 150),
                OutputVolume = Math.Clamp(value.OutputVolume, 0, 100),
                VoiceActivationThreshold = Math.Clamp(value.VoiceActivationThreshold, 1, 100),
                NoiseSuppressionLevel = Math.Clamp(
                    value.NoiseSuppressionLevel,
                    VoiceProtocol.MinimumNoiseSuppressionLevel,
                    VoiceProtocol.MaximumNoiseSuppressionLevel),
                PushToTalkKeys = value.PushToTalkKeys.Take(8).ToList(),
                PeerVolumes = value.PeerVolumes
                    .Take(128)
                    .Select(item => item with { Volume = Math.Clamp(item.Volume, 0, 100) })
                    .ToList(),
                MutedPeers = value.MutedPeers.Take(128).ToList(),
            };
        }
    }

    public void UpdateStatus(HelperStatusMessage value)
    {
        lock (gate)
        {
            helperStatus = value with
            {
                FeatureVersion = Math.Clamp(value.FeatureVersion, 0, VoiceProtocol.HelperFeatureVersion),
                InputLevel = Math.Clamp(value.InputLevel, 0, 100),
                CalibrationProgress = Math.Clamp(value.CalibrationProgress, 0, 100),
                RecommendedThreshold = Math.Clamp(value.RecommendedThreshold, 0, 100),
                NoiseFloor = Math.Clamp(value.NoiseFloor, 0, 100),
                Error = value.Error[..Math.Min(value.Error.Length, 256)],
                AudioTransport = value.AudioTransport[..Math.Min(value.AudioTransport.Length, 16)],
                InputDevices = value.InputDevices.Take(32).ToList(),
                OutputDevices = value.OutputDevices.Take(32).ToList(),
            };
        }
    }

    public RelayConnection? ReplaceConnection(RelayConnection value)
    {
        lock (gate)
        {
            var previous = connection;
            connection = value;
            return previous;
        }
    }

    public void RemoveConnection(RelayConnection value)
    {
        lock (gate)
        {
            if (connection == value)
            {
                connection = null;
                helperStatus = helperStatus with { Speaking = false, InputLevel = 0 };
            }
        }
    }

    public HelperConfigMessage CreateHelperConfig()
    {
        var value = Snapshot;
        return new HelperConfigMessage
        {
            SessionId = value.SessionId,
            CanSpeak = value.CanSpeak && value.WantsConnection,
            CanListen = value.CanListen && value.WantsConnection,
            Muted = value.Muted,
            Deafened = value.Deafened,
            PushToTalkKeys = value.PushToTalkKeys,
            VoiceActivationEnabled = value.VoiceActivationEnabled,
            VoiceActivationThreshold = value.VoiceActivationThreshold,
            NoiseSuppressionLevel = value.NoiseSuppressionLevel,
            OutputTestSequence = value.OutputTestSequence,
            MicrophoneTestSequence = value.MicrophoneTestSequence,
            CalibrationSequence = value.CalibrationSequence,
            CalibrationRequested = value.CalibrationRequested,
            InputGain = value.InputGain,
            OutputVolume = value.OutputVolume,
            InputDeviceId = value.InputDeviceId,
            OutputDeviceId = value.OutputDeviceId,
            PeerVolumes = value.PeerVolumes,
            MutedPeers = value.MutedPeers,
            UdpToken = Connection?.UdpToken ?? string.Empty,
            UdpPort = UdpPort,
        };
    }

    public RelaySessionResponse CreateGameResponse(string connectToken)
    {
        lock (gate)
        {
            var wantsConnection = snapshot.WantsConnection;
            return new RelaySessionResponse
            {
                SessionId = snapshot.SessionId,
                Status = connection is not null ? "connected" : wantsConnection ? "connecting" : "disconnected",
                Error = helperStatus.Error,
                ConnectToken = connectToken,
                Speaking = connection is not null && helperStatus.Speaking,
                InputLevel = connection is not null ? helperStatus.InputLevel : 0,
                HelperFeatureVersion = connection is not null ? helperStatus.FeatureVersion : 0,
                Calibrating = connection is not null && helperStatus.Calibrating,
                CalibrationProgress = connection is not null ? helperStatus.CalibrationProgress : 0,
                CalibrationSequence = connection is not null ? helperStatus.CalibrationSequence : 0,
                RecommendedThreshold = connection is not null ? helperStatus.RecommendedThreshold : 0,
                NoiseFloor = connection is not null ? helperStatus.NoiseFloor : 0,
                AudioProcessingActive = connection is not null && helperStatus.AudioProcessingActive,
                AudioTransport = connection is not null ? helperStatus.AudioTransport : string.Empty,
                InputDevices = helperStatus.InputDevices,
                OutputDevices = helperStatus.OutputDevices,
            };
        }
    }

    public async Task CloseConnectionAsync(string reason, CancellationToken cancellationToken)
    {
        var currentConnection = Connection;
        if (currentConnection is not null)
        {
            await currentConnection.CloseAsync(reason, cancellationToken);
        }
    }
}

public sealed class RelayConnection
{
    private readonly SemaphoreSlim sendGate = new(1, 1);
    private readonly object udpGate = new();
    private IPEndPoint? udpEndpoint;

    public RelayConnection(WebSocket socket)
    {
        Socket = socket;
        UdpTokenBytes = RandomNumberGenerator.GetBytes(VoiceProtocol.UdpTokenBytes);
        UdpToken = Convert.ToBase64String(UdpTokenBytes);
    }

    public WebSocket Socket { get; }
    public byte[] UdpTokenBytes { get; }
    public string UdpToken { get; }

    public IPEndPoint? UdpEndpoint
    {
        get
        {
            lock (udpGate)
            {
                return udpEndpoint;
            }
        }
    }

    public void SetUdpEndpoint(IPEndPoint value)
    {
        lock (udpGate)
        {
            udpEndpoint = value;
        }
    }

    public bool IsUdpEndpoint(IPEndPoint value)
    {
        lock (udpGate)
        {
            return udpEndpoint?.Equals(value) == true;
        }
    }

    public Task SendConfigAsync(HelperConfigMessage config, CancellationToken cancellationToken)
    {
        var json = JsonSerializer.SerializeToUtf8Bytes(config, VoiceProtocol.JsonOptions);
        return SendAsync(json, WebSocketMessageType.Text, cancellationToken);
    }

    public Task SendBinaryAsync(byte[] frame, CancellationToken cancellationToken)
    {
        return SendAsync(frame, WebSocketMessageType.Binary, cancellationToken);
    }

    public async Task CloseAsync(string reason, CancellationToken cancellationToken)
    {
        await sendGate.WaitAsync(cancellationToken);
        try
        {
            if (Socket.State is WebSocketState.Open or WebSocketState.CloseReceived)
            {
                try
                {
                    await Socket.CloseAsync(WebSocketCloseStatus.NormalClosure, reason, cancellationToken);
                }
                catch (WebSocketException)
                {
                    // The helper may exit as soon as its session disappears.
                }
                catch (ObjectDisposedException)
                {
                    // A concurrent receive loop may dispose the socket first.
                }
            }
        }
        finally
        {
            sendGate.Release();
        }
    }

    private async Task SendAsync(
        ReadOnlyMemory<byte> payload,
        WebSocketMessageType messageType,
        CancellationToken cancellationToken)
    {
        await sendGate.WaitAsync(cancellationToken);
        try
        {
            if (Socket.State == WebSocketState.Open)
            {
                await Socket.SendAsync(payload, messageType, true, cancellationToken);
            }
        }
        finally
        {
            sendGate.Release();
        }
    }
}
