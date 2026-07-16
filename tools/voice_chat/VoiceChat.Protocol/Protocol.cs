using System.Buffers.Binary;
using System.Text.Json;

namespace VoiceChat.Protocol;

public static class VoiceProtocol
{
    public const int Version = 1;
    public const int HelperFeatureVersion = 3;
    public const int SampleRate = 48000;
    public const int Channels = 1;
    public const int FrameMilliseconds = 20;
    public const int SamplesPerFrame = SampleRate * FrameMilliseconds / 1000;
    public const int MaximumOpusPacketBytes = 4000;
    public const byte ClientAudioFrame = 1;
    public const byte RelayAudioFrame = 2;
    public const int UdpTokenBytes = 32;
    public const byte UdpRegisterFrame = 3;
    public const byte UdpRegisterAckFrame = 4;
    public const byte UdpClientAudioFrame = 5;
    public const byte UdpRelayAudioFrame = 6;

    private static ReadOnlySpan<byte> UdpMagic => "PVC1"u8;

    public static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        Converters = { new DmBooleanJsonConverter() },
    };

    public static byte[] CreateClientAudioFrame(uint sequence, ReadOnlySpan<byte> opusPacket)
    {
        var frame = new byte[5 + opusPacket.Length];
        frame[0] = ClientAudioFrame;
        BinaryPrimitives.WriteUInt32LittleEndian(frame.AsSpan(1, 4), sequence);
        opusPacket.CopyTo(frame.AsSpan(5));
        return frame;
    }

    public static byte[] CreateRelayAudioFrame(
        Guid speakerId,
        byte spatialVolume,
        ReadOnlySpan<byte> clientFrame)
    {
        var frame = new byte[17 + clientFrame.Length];
        frame[0] = RelayAudioFrame;
        speakerId.TryWriteBytes(frame.AsSpan(1, 16));
        clientFrame.Slice(1, 4).CopyTo(frame.AsSpan(17, 4));
        frame[21] = spatialVolume;
        clientFrame[5..].CopyTo(frame.AsSpan(22));
        return frame;
    }

    public static bool TryReadRelayAudioFrame(
        ReadOnlySpan<byte> frame,
        out Guid speakerId,
        out uint sequence,
        out byte spatialVolume,
        out ReadOnlySpan<byte> opusPacket)
    {
        speakerId = default;
        sequence = default;
        spatialVolume = default;
        opusPacket = default;
        if (frame.Length < 23 || frame[0] != RelayAudioFrame)
        {
            return false;
        }

        speakerId = new Guid(frame.Slice(1, 16));
        sequence = BinaryPrimitives.ReadUInt32LittleEndian(frame.Slice(17, 4));
        spatialVolume = Math.Min(frame[21], (byte)100);
        opusPacket = frame[22..];
        return opusPacket.Length <= MaximumOpusPacketBytes;
    }

    public static byte[] CreateUdpRegisterFrame(ReadOnlySpan<byte> token)
    {
        return CreateAuthenticatedUdpFrame(UdpRegisterFrame, token, []);
    }

    public static byte[] CreateUdpRegisterAckFrame(ReadOnlySpan<byte> token)
    {
        return CreateAuthenticatedUdpFrame(UdpRegisterAckFrame, token, []);
    }

    public static byte[] CreateUdpClientAudioFrame(
        ReadOnlySpan<byte> token,
        ReadOnlySpan<byte> clientFrame)
    {
        return CreateAuthenticatedUdpFrame(UdpClientAudioFrame, token, clientFrame);
    }

    public static byte[] CreateUdpRelayAudioFrame(
        ReadOnlySpan<byte> token,
        ReadOnlySpan<byte> relayFrame)
    {
        return CreateAuthenticatedUdpFrame(UdpRelayAudioFrame, token, relayFrame);
    }

    public static bool TryReadAuthenticatedUdpFrame(
        ReadOnlySpan<byte> datagram,
        byte expectedType,
        out ReadOnlySpan<byte> token,
        out ReadOnlySpan<byte> payload)
    {
        token = default;
        payload = default;
        var headerLength = UdpMagic.Length + 1 + UdpTokenBytes;
        if (datagram.Length < headerLength ||
            !datagram[..UdpMagic.Length].SequenceEqual(UdpMagic) ||
            datagram[UdpMagic.Length] != expectedType)
        {
            return false;
        }

        token = datagram.Slice(UdpMagic.Length + 1, UdpTokenBytes);
        payload = datagram[headerLength..];
        return true;
    }

    private static byte[] CreateAuthenticatedUdpFrame(
        byte type,
        ReadOnlySpan<byte> token,
        ReadOnlySpan<byte> payload)
    {
        if (token.Length != UdpTokenBytes)
        {
            throw new ArgumentException($"UDP token must contain {UdpTokenBytes} bytes.", nameof(token));
        }

        var frame = new byte[UdpMagic.Length + 1 + token.Length + payload.Length];
        UdpMagic.CopyTo(frame);
        frame[UdpMagic.Length] = type;
        token.CopyTo(frame.AsSpan(UdpMagic.Length + 1));
        payload.CopyTo(frame.AsSpan(UdpMagic.Length + 1 + token.Length));
        return frame;
    }
}

public sealed record VoicePosition
{
    public int X { get; init; }
    public int Y { get; init; }
    public int Z { get; init; }
}

public sealed record GameSnapshotRequest
{
    public int ProtocolVersion { get; init; }
    public required string ServerId { get; init; }
    public int ProximityRange { get; init; }
    public required List<GameSessionSnapshot> Sessions { get; init; }
}

public sealed record GameSessionSnapshot
{
    public required string SessionId { get; init; }
    public required string DisplayName { get; init; }
    public VoicePosition? Position { get; init; }
    public bool CanSpeak { get; init; }
    public bool CanListen { get; init; }
    public bool WantsConnection { get; init; }
    public bool Muted { get; init; }
    public bool Deafened { get; init; }
    public bool PushToTalkPressed { get; init; }
    public List<string> PushToTalkKeys { get; init; } = [];
    public bool VoiceActivationEnabled { get; init; }
    public int VoiceActivationThreshold { get; init; } = 15;
    public int OutputTestSequence { get; init; }
    public int MicrophoneTestSequence { get; init; }
    public int CalibrationSequence { get; init; }
    public bool CalibrationRequested { get; init; }
    public int InputGain { get; init; } = 100;
    public int OutputVolume { get; init; } = 100;
    public string InputDeviceId { get; init; } = string.Empty;
    public string OutputDeviceId { get; init; } = string.Empty;
    public List<PeerVolume> PeerVolumes { get; init; } = [];
    public List<string> MutedPeers { get; init; } = [];
}

public sealed record GameSnapshotResponse
{
    public int ProtocolVersion { get; init; } = VoiceProtocol.Version;
    public required List<RelaySessionResponse> Sessions { get; init; }
}

public sealed record RelaySessionResponse
{
    public required string SessionId { get; init; }
    public required string Status { get; init; }
    public string Error { get; init; } = string.Empty;
    public string ConnectToken { get; init; } = string.Empty;
    public bool Speaking { get; init; }
    public int InputLevel { get; init; }
    public int HelperFeatureVersion { get; init; }
    public bool Calibrating { get; init; }
    public int CalibrationProgress { get; init; }
    public int CalibrationSequence { get; init; }
    public int RecommendedThreshold { get; init; }
    public int NoiseFloor { get; init; }
    public bool AudioProcessingActive { get; init; }
    public string AudioTransport { get; init; } = string.Empty;
    public List<VoiceDevice> InputDevices { get; init; } = [];
    public List<VoiceDevice> OutputDevices { get; init; } = [];
}

public sealed record VoiceDevice
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public bool Default { get; init; }
}

public sealed record PeerVolume
{
    public required string SessionId { get; init; }
    public int Volume { get; init; }
}

public sealed record HelperStatusMessage
{
    public string Type { get; init; } = "status";
    public int FeatureVersion { get; init; }
    public bool Speaking { get; init; }
    public int InputLevel { get; init; }
    public string Error { get; init; } = string.Empty;
    public bool Calibrating { get; init; }
    public int CalibrationProgress { get; init; }
    public int CalibrationSequence { get; init; }
    public int RecommendedThreshold { get; init; }
    public int NoiseFloor { get; init; }
    public bool AudioProcessingActive { get; init; }
    public string AudioTransport { get; init; } = "websocket";
    public List<VoiceDevice> InputDevices { get; init; } = [];
    public List<VoiceDevice> OutputDevices { get; init; } = [];
}

public sealed record HelperConfigMessage
{
    public string Type { get; init; } = "config";
    public int ProtocolVersion { get; init; } = VoiceProtocol.Version;
    public required string SessionId { get; init; }
    public bool CanSpeak { get; init; }
    public bool CanListen { get; init; }
    public bool Muted { get; init; }
    public bool Deafened { get; init; }
    public List<string> PushToTalkKeys { get; init; } = [];
    public bool VoiceActivationEnabled { get; init; }
    public int VoiceActivationThreshold { get; init; } = 15;
    public int OutputTestSequence { get; init; }
    public int MicrophoneTestSequence { get; init; }
    public int CalibrationSequence { get; init; }
    public bool CalibrationRequested { get; init; }
    public int InputGain { get; init; }
    public int OutputVolume { get; init; }
    public string InputDeviceId { get; init; } = string.Empty;
    public string OutputDeviceId { get; init; } = string.Empty;
    public List<PeerVolume> PeerVolumes { get; init; } = [];
    public List<string> MutedPeers { get; init; } = [];
    public string UdpToken { get; init; } = string.Empty;
    public int UdpPort { get; init; }
}
