using System.Net.WebSockets;
using System.Text.Json;
using System.Threading.Channels;
using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public sealed class VoiceClient : IAsyncDisposable
{
    private readonly LaunchOptions options;
    private readonly ClientWebSocket socket = new();
    private readonly AudioEngine audio = new();
    private readonly PushToTalkMonitor pushToTalk = new();
    private readonly UdpAudioTransport udpAudio;
    private readonly SemaphoreSlim sendGate = new(1, 1);
    private readonly Channel<byte[]> outgoingAudio = Channel.CreateBounded<byte[]>(
        new BoundedChannelOptions(16)
        {
            FullMode = BoundedChannelFullMode.DropOldest,
            SingleReader = true,
            SingleWriter = true,
        });
    private uint sequence;

    public VoiceClient(LaunchOptions options)
    {
        this.options = options;
        udpAudio = new UdpAudioTransport(options.RelayUrl);
        audio.AudioFrameReady += OnAudioFrameReady;
        udpAudio.RelayAudioFrameReceived += OnRelayAudioFrameReceived;
    }

    public async Task RunAsync(CancellationToken cancellationToken)
    {
        await socket.ConnectAsync(options.CreateConnectionUri(), cancellationToken);
        using var lifetime = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        var receiveTask = ReceiveLoopAsync(lifetime.Token);
        var audioTask = AudioSendLoopAsync(lifetime.Token);
        var statusTask = StatusLoopAsync(lifetime.Token);
        var pushToTalkTask = PushToTalkLoopAsync(lifetime.Token);

        await receiveTask;
        lifetime.Cancel();
        await IgnoreCancellationAsync(audioTask, statusTask, pushToTalkTask);
    }

    public async ValueTask DisposeAsync()
    {
        audio.AudioFrameReady -= OnAudioFrameReady;
        udpAudio.RelayAudioFrameReceived -= OnRelayAudioFrameReceived;
        await udpAudio.DisposeAsync();
        audio.Dispose();
        if (socket.State is WebSocketState.Open or WebSocketState.CloseReceived)
        {
            await socket.CloseAsync(
                WebSocketCloseStatus.NormalClosure,
                "helper_exit",
                CancellationToken.None);
        }

        socket.Dispose();
        sendGate.Dispose();
    }

    private async Task ReceiveLoopAsync(CancellationToken cancellationToken)
    {
        var buffer = new byte[8192];
        while (socket.State == WebSocketState.Open && !cancellationToken.IsCancellationRequested)
        {
            var result = await socket.ReceiveAsync(buffer, cancellationToken);
            if (result.MessageType == WebSocketMessageType.Close)
            {
                return;
            }

            if (!result.EndOfMessage)
            {
                throw new InvalidOperationException("Relay message exceeded the supported size.");
            }

            if (result.MessageType == WebSocketMessageType.Text)
            {
                var config = JsonSerializer.Deserialize<HelperConfigMessage>(
                    buffer.AsSpan(0, result.Count),
                    VoiceProtocol.JsonOptions);
                if (config is null || config.Type != "config" ||
                    config.ProtocolVersion != VoiceProtocol.Version)
                {
                    throw new InvalidOperationException("Relay returned an incompatible configuration.");
                }

                audio.ApplyConfig(config);
                await udpAudio.ConfigureAsync(config.UdpToken, config.UdpPort, cancellationToken);
                continue;
            }

            if (result.MessageType == WebSocketMessageType.Binary &&
                VoiceProtocol.TryReadRelayAudioFrame(
                    buffer.AsSpan(0, result.Count),
                    out var speakerId,
                    out var sequence,
                    out var spatialVolume,
                    out var opusPacket))
            {
                audio.Play(speakerId, sequence, spatialVolume, opusPacket);
            }
        }
    }

    private async Task AudioSendLoopAsync(CancellationToken cancellationToken)
    {
        await foreach (var opusPacket in outgoingAudio.Reader.ReadAllAsync(cancellationToken))
        {
            var frame = VoiceProtocol.CreateClientAudioFrame(sequence++, opusPacket);
            if (!await udpAudio.TrySendAudioAsync(frame, cancellationToken))
            {
                await SendAsync(frame, WebSocketMessageType.Binary, cancellationToken);
            }
        }
    }

    private async Task StatusLoopAsync(CancellationToken cancellationToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(250));
        while (await timer.WaitForNextTickAsync(cancellationToken))
        {
            var status = new HelperStatusMessage
            {
                FeatureVersion = VoiceProtocol.HelperFeatureVersion,
                Speaking = audio.Speaking,
                InputLevel = audio.InputLevel,
                Error = audio.Error,
                InputDevices = audio.InputDevices,
                OutputDevices = audio.OutputDevices,
                Calibrating = audio.Calibrating,
                CalibrationProgress = audio.CalibrationProgress,
                CalibrationSequence = audio.CalibrationSequence,
                RecommendedThreshold = audio.RecommendedThreshold,
                NoiseFloor = audio.NoiseFloor,
                AudioProcessingActive = audio.AudioProcessingActive,
                AudioTransport = udpAudio.Ready ? "udp" : "websocket",
            };
            var json = JsonSerializer.SerializeToUtf8Bytes(status, VoiceProtocol.JsonOptions);
            await SendAsync(json, WebSocketMessageType.Text, cancellationToken);
        }
    }

    private async Task PushToTalkLoopAsync(CancellationToken cancellationToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(10));
        while (await timer.WaitForNextTickAsync(cancellationToken))
        {
            audio.SetPushToTalk(pushToTalk.IsPressed(audio.PushToTalkKeys));
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
            if (socket.State == WebSocketState.Open)
            {
                await socket.SendAsync(payload, messageType, true, cancellationToken);
            }
        }
        finally
        {
            sendGate.Release();
        }
    }

    private void OnAudioFrameReady(byte[] opusPacket)
    {
        outgoingAudio.Writer.TryWrite(opusPacket);
    }

    private void OnRelayAudioFrameReceived(byte[] frame)
    {
        if (VoiceProtocol.TryReadRelayAudioFrame(
                frame,
                out var speakerId,
                out var packetSequence,
                out var spatialVolume,
                out var opusPacket))
        {
            audio.Play(speakerId, packetSequence, spatialVolume, opusPacket);
        }
    }

    private static async Task IgnoreCancellationAsync(params Task[] tasks)
    {
        try
        {
            await Task.WhenAll(tasks);
        }
        catch (OperationCanceledException)
        {
        }
    }
}
