using System.Net.Sockets;
using System.Security.Cryptography;
using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public sealed class UdpAudioTransport : IAsyncDisposable
{
    private readonly Uri relayUri;
    private readonly object gate = new();
    private UdpClient? client;
    private CancellationTokenSource? lifetime;
    private Task[] tasks = [];
    private byte[] token = [];
    private string configurationKey = string.Empty;
    private bool ready;

    public UdpAudioTransport(Uri relayUri)
    {
        this.relayUri = relayUri;
    }

    public event Action<byte[]>? RelayAudioFrameReceived;

    public bool Ready
    {
        get
        {
            lock (gate)
            {
                return ready;
            }
        }
    }

    public async Task ConfigureAsync(
        string tokenText,
        int port,
        CancellationToken cancellationToken)
    {
        byte[] newToken;
        try
        {
            newToken = Convert.FromBase64String(tokenText);
        }
        catch (FormatException)
        {
            return;
        }

        if (newToken.Length != VoiceProtocol.UdpTokenBytes || port is < 1 or > ushort.MaxValue)
        {
            return;
        }

        var newConfigurationKey = $"{tokenText}:{port}";
        lock (gate)
        {
            if (configurationKey == newConfigurationKey && client is not null)
            {
                return;
            }
        }

        await StopAsync();
        var newClient = new UdpClient();
        try
        {
            await newClient.Client.ConnectAsync(relayUri.Host, port, cancellationToken);
        }
        catch
        {
            newClient.Dispose();
            throw;
        }

        var newLifetime = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        lock (gate)
        {
            client = newClient;
            lifetime = newLifetime;
            token = newToken;
            configurationKey = newConfigurationKey;
            ready = false;
            tasks =
            [
                ReceiveLoopAsync(newClient, newToken, newLifetime.Token),
                RegistrationLoopAsync(newClient, newToken, newLifetime.Token),
            ];
        }
    }

    public async ValueTask<bool> TrySendAudioAsync(
        ReadOnlyMemory<byte> clientFrame,
        CancellationToken cancellationToken)
    {
        UdpClient? currentClient;
        byte[] currentToken;
        lock (gate)
        {
            if (!ready || client is null)
            {
                return false;
            }

            currentClient = client;
            currentToken = token;
        }

        try
        {
            var datagram = VoiceProtocol.CreateUdpClientAudioFrame(currentToken, clientFrame.Span);
            await currentClient.SendAsync(datagram, cancellationToken);
            return true;
        }
        catch (SocketException)
        {
            lock (gate)
            {
                ready = false;
            }
            return false;
        }
    }

    public async ValueTask DisposeAsync()
    {
        await StopAsync();
    }

    private async Task ReceiveLoopAsync(
        UdpClient currentClient,
        byte[] currentToken,
        CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            UdpReceiveResult received;
            try
            {
                received = await currentClient.ReceiveAsync(cancellationToken);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                return;
            }
            catch (SocketException)
            {
                lock (gate)
                {
                    ready = false;
                }
                continue;
            }

            if (VoiceProtocol.TryReadAuthenticatedUdpFrame(
                    received.Buffer,
                    VoiceProtocol.UdpRegisterAckFrame,
                    out var ackToken,
                    out var ackPayload) &&
                ackPayload.IsEmpty &&
                CryptographicOperations.FixedTimeEquals(ackToken, currentToken))
            {
                lock (gate)
                {
                    if (client == currentClient)
                    {
                        ready = true;
                    }
                }
                continue;
            }

            if (VoiceProtocol.TryReadAuthenticatedUdpFrame(
                    received.Buffer,
                    VoiceProtocol.UdpRelayAudioFrame,
                    out var audioToken,
                    out var relayFrame) &&
                CryptographicOperations.FixedTimeEquals(audioToken, currentToken))
            {
                RelayAudioFrameReceived?.Invoke(relayFrame.ToArray());
            }
        }
    }

    private async Task RegistrationLoopAsync(
        UdpClient currentClient,
        byte[] currentToken,
        CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                var registration = VoiceProtocol.CreateUdpRegisterFrame(currentToken);
                await currentClient.SendAsync(registration, cancellationToken);
                await Task.Delay(
                    Ready ? TimeSpan.FromSeconds(10) : TimeSpan.FromSeconds(1),
                    cancellationToken);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                return;
            }
            catch (SocketException)
            {
                lock (gate)
                {
                    ready = false;
                }
            }
        }
    }

    private async Task StopAsync()
    {
        CancellationTokenSource? oldLifetime;
        UdpClient? oldClient;
        Task[] oldTasks;
        lock (gate)
        {
            oldLifetime = lifetime;
            oldClient = client;
            oldTasks = tasks;
            lifetime = null;
            client = null;
            tasks = [];
            token = [];
            configurationKey = string.Empty;
            ready = false;
        }

        oldLifetime?.Cancel();
        oldClient?.Dispose();
        try
        {
            await Task.WhenAll(oldTasks);
        }
        catch (OperationCanceledException)
        {
        }
        catch (ObjectDisposedException)
        {
        }
        oldLifetime?.Dispose();
    }
}
