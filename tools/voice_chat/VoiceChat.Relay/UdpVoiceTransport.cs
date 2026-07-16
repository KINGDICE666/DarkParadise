using System.Net;
using System.Net.Sockets;
using VoiceChat.Protocol;

namespace VoiceChat.Relay;

public sealed class UdpVoiceTransport : BackgroundService
{
    private readonly RelayStore relay;
    private UdpClient? client;

    public UdpVoiceTransport(RelayStore relay)
    {
        this.relay = relay;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        client = new UdpClient(new IPEndPoint(IPAddress.Any, relay.UdpPort));
        while (!stoppingToken.IsCancellationRequested)
        {
            UdpReceiveResult received;
            try
            {
                received = await client.ReceiveAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (SocketException)
            {
                continue;
            }

            await HandleDatagramAsync(received, stoppingToken);
        }
    }

    public override void Dispose()
    {
        client?.Dispose();
        base.Dispose();
    }

    private async Task HandleDatagramAsync(
        UdpReceiveResult received,
        CancellationToken cancellationToken)
    {
        if (VoiceProtocol.TryReadAuthenticatedUdpFrame(
                received.Buffer,
                VoiceProtocol.UdpRegisterFrame,
                out var registrationToken,
                out var registrationPayload) &&
            registrationPayload.IsEmpty &&
            relay.TryRegisterUdpEndpoint(
                registrationToken,
                received.RemoteEndPoint,
                out var connection))
        {
            var ack = VoiceProtocol.CreateUdpRegisterAckFrame(connection.UdpTokenBytes);
            await SendAsync(ack, received.RemoteEndPoint, cancellationToken);
            return;
        }

        if (!VoiceProtocol.TryReadAuthenticatedUdpFrame(
                received.Buffer,
                VoiceProtocol.UdpClientAudioFrame,
                out var audioToken,
                out var clientFrame) ||
            !relay.TryResolveUdpSender(audioToken, received.RemoteEndPoint, out var session))
        {
            return;
        }

        await relay.RouteUdpAudioAsync(
            session,
            clientFrame.ToArray(),
            SendAsync,
            cancellationToken);
    }

    private async ValueTask SendAsync(
        ReadOnlyMemory<byte> datagram,
        IPEndPoint endpoint,
        CancellationToken cancellationToken)
    {
        if (client is not null)
        {
            await client.SendAsync(datagram, endpoint, cancellationToken);
        }
    }
}
