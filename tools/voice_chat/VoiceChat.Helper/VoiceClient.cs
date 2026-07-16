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
        audio.AudioFrameReady += OnAudioFrameReady;
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
                continue;
            }

            if (result.MessageType == WebSocketMessageType.Binary &&
                VoiceProtocol.TryReadRelayAudioFrame(
                    buffer.AsSpan(0, result.Count),
                    out var speakerId,
                    out _,
                    out var spatialVolume,
                    out var opusPacket))
            {
                audio.Play(speakerId, spatialVolume, opusPacket);
            }
        }
    }

    private async Task AudioSendLoopAsync(CancellationToken cancellationToken)
    {
        await foreach (var opusPacket in outgoingAudio.Reader.ReadAllAsync(cancellationToken))
        {
            var frame = VoiceProtocol.CreateClientAudioFrame(sequence++, opusPacket);
            await SendAsync(frame, WebSocketMessageType.Binary, cancellationToken);
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
