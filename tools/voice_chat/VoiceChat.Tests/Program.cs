using System.Text.Json;
using Concentus;
using Concentus.Enums;
using VoiceChat.Helper;
using VoiceChat.Protocol;
using VoiceChat.Relay;

TestAudioFrameRoundTrip();
TestUdpFrameRoundTrip();
TestOpusLossRecovery();
TestWebRtcAudioProcessing();
TestDmBooleanJson();
TestHelperFeatureVersion();
TestLaunchUri();
TestBrokerLaunchUrl();
await TestRelayTokensAsync();
Console.WriteLine("Voice chat tests passed.");

static void TestAudioFrameRoundTrip()
{
    var speakerId = Guid.NewGuid();
    var payload = new byte[] { 4, 8, 15, 16, 23, 42 };
    var clientFrame = VoiceProtocol.CreateClientAudioFrame(1234, payload);
    var relayFrame = VoiceProtocol.CreateRelayAudioFrame(speakerId, 65, clientFrame);
    Assert(
        VoiceProtocol.TryReadRelayAudioFrame(
            relayFrame,
            out var decodedSpeakerId,
            out var sequence,
            out var spatialVolume,
            out var decodedPayload),
        "Relay audio frame was rejected.");
    Assert(decodedSpeakerId == speakerId, "Speaker id changed during framing.");
    Assert(sequence == 1234, "Sequence changed during framing.");
    Assert(spatialVolume == 65, "Spatial volume changed during framing.");
    Assert(decodedPayload.SequenceEqual(payload), "Opus payload changed during framing.");
}

static void TestUdpFrameRoundTrip()
{
    var token = Enumerable.Range(0, VoiceProtocol.UdpTokenBytes)
        .Select(value => (byte)value)
        .ToArray();
    var clientFrame = VoiceProtocol.CreateClientAudioFrame(77, [1, 2, 3]);
    var datagram = VoiceProtocol.CreateUdpClientAudioFrame(token, clientFrame);
    Assert(
        VoiceProtocol.TryReadAuthenticatedUdpFrame(
            datagram,
            VoiceProtocol.UdpClientAudioFrame,
            out var decodedToken,
            out var decodedFrame),
        "UDP audio frame was rejected.");
    Assert(decodedToken.SequenceEqual(token), "UDP token changed during framing.");
    Assert(decodedFrame.SequenceEqual(clientFrame), "UDP payload changed during framing.");
    Assert(
        !VoiceProtocol.TryReadAuthenticatedUdpFrame(
            datagram,
            VoiceProtocol.UdpRegisterFrame,
            out _,
            out _),
        "UDP audio frame was accepted as a registration.");
}

static void TestOpusLossRecovery()
{
    var encoder = OpusCodecFactory.CreateEncoder(
        VoiceProtocol.SampleRate,
        VoiceProtocol.Channels,
        OpusApplication.OPUS_APPLICATION_VOIP);
    encoder.UseInbandFEC = true;
    encoder.PacketLossPercent = 20;
    var decoder = OpusCodecFactory.CreateDecoder(VoiceProtocol.SampleRate, VoiceProtocol.Channels);
    var packets = new List<byte[]>();
    var pcm = new short[VoiceProtocol.SamplesPerFrame];
    var encoded = new byte[VoiceProtocol.MaximumOpusPacketBytes];
    for (var frameIndex = 0; frameIndex < 8; frameIndex++)
    {
        for (var sampleIndex = 0; sampleIndex < pcm.Length; sampleIndex++)
        {
            pcm[sampleIndex] = (short)(
                Math.Sin((frameIndex * pcm.Length + sampleIndex) * 0.04) * 4000);
        }

        var length = encoder.Encode(pcm, pcm.Length, encoded, encoded.Length);
        packets.Add(encoded.AsSpan(0, length).ToArray());
    }

    Span<short> output = stackalloc short[VoiceProtocol.SamplesPerFrame];
    for (var index = 0; index < 4; index++)
    {
        decoder.Decode(packets[index], output, output.Length, false);
    }

    var fecSamples = decoder.Decode(packets[5], output, output.Length, true);
    Assert(fecSamples == VoiceProtocol.SamplesPerFrame, "Opus FEC did not recover a missing frame.");
    decoder.Decode(packets[5], output, output.Length, false);
    var plcSamples = decoder.Decode([], output, output.Length, false);
    Assert(plcSamples == VoiceProtocol.SamplesPerFrame, "Opus PLC did not conceal a missing frame.");
}

static void TestWebRtcAudioProcessing()
{
    using var processor = new WebRtcAudioProcessor();
    var capture = new short[VoiceProtocol.SamplesPerFrame];
    var render = new float[VoiceProtocol.SampleRate / 100];
    processor.AnalyzeRender(render);
    processor.ProcessCapture(capture);
    processor.SetNoiseSuppressionLevel(VoiceProtocol.MinimumNoiseSuppressionLevel);
    processor.SetNoiseSuppressionLevel(VoiceProtocol.MaximumNoiseSuppressionLevel);
    Assert(capture.All(sample => sample == 0), "WebRTC APM changed a silent capture frame.");
}

static void TestDmBooleanJson()
{
    const string dmJson = """
        {
            "session_id": "00000000000000000000000000000000",
            "display_name": "DM Player",
            "can_speak": 1,
            "can_listen": 0,
            "wants_connection": true
        }
        """;
    var session = JsonSerializer.Deserialize<GameSessionSnapshot>(dmJson, VoiceProtocol.JsonOptions);
    if (session is null)
    {
        throw new InvalidOperationException("DM snapshot was not deserialized.");
    }
    Assert(session.CanSpeak, "DM true value was not accepted.");
    Assert(!session.CanListen, "DM false value was not accepted.");
    Assert(session.WantsConnection, "JSON true value was not accepted.");

    var invalidValueRejected = false;
    try
    {
        JsonSerializer.Deserialize<GameSessionSnapshot>(
            dmJson.Replace("\"can_speak\": 1", "\"can_speak\": 2"),
            VoiceProtocol.JsonOptions);
    }
    catch (JsonException)
    {
        invalidValueRejected = true;
    }

    Assert(invalidValueRejected, "Invalid DM boolean value was accepted.");
}

static void TestHelperFeatureVersion()
{
    var legacyStatus = JsonSerializer.Deserialize<HelperStatusMessage>(
        "{\"type\":\"status\"}",
        VoiceProtocol.JsonOptions);
    Assert(legacyStatus?.FeatureVersion == 0, "Legacy helper was reported as current.");
    var currentStatus = new HelperStatusMessage
    {
        FeatureVersion = VoiceProtocol.HelperFeatureVersion,
    };
    Assert(currentStatus.FeatureVersion == 4, "Current helper feature version changed.");
}

static void TestLaunchUri()
{
    var relay = "wss://voice.example.org/v1/connect";
    var token = "token/value+with=symbols";
    var launchUri = $"paradise-voice://connect?relay={Uri.EscapeDataString(relay)}&token={Uri.EscapeDataString(token)}&session=unused&protocol=1";
    Assert(LaunchOptions.TryParse([launchUri], out var options), "Valid launch URI was rejected.");
    Assert(options.RelayUrl.ToString() == relay, "Relay URL changed while parsing.");
    Assert(options.Token == token, "Connect token changed while parsing.");
    Assert(options.CreateConnectionUri().Query.Contains("protocol=1"), "Protocol was omitted from relay URI.");
    Assert(!LaunchOptions.TryParse([launchUri.Replace("protocol=1", "protocol=2")], out _), "Invalid protocol was accepted.");
}

static void TestBrokerLaunchUrl()
{
    var relay = "ws://127.0.0.1:3000/v1/connect";
    var token = "abcdefghijklmnopqrstuvwxyzABCDEFGH123456789";
    var target = $"/launch?relay={Uri.EscapeDataString(relay)}&token={token}&protocol=1";
    Assert(HelperBroker.TryCreateLaunchUri(target, out var launchUri), "Valid broker launch URL was rejected.");
    Assert(LaunchOptions.TryParse([launchUri], out var options), "Broker produced an invalid launch URI.");
    Assert(options.RelayUrl.ToString() == relay, "Broker changed the relay URL.");
    Assert(options.Token == token, "Broker changed the connect token.");
    Assert(!HelperBroker.TryCreateLaunchUri(target.Replace("protocol=1", "protocol=2"), out _), "Broker accepted an invalid protocol.");
}

static async Task TestRelayTokensAsync()
{
    var relay = new RelayStore("test-key");
    Assert(relay.Authenticate("test-key"), "Valid API key was rejected.");
    Assert(!relay.Authenticate("wrong-key"), "Invalid API key was accepted.");

    var sessionId = Guid.NewGuid().ToString("N");
    var response = await relay.ApplySnapshotAsync(
        new GameSnapshotRequest
        {
            ProtocolVersion = VoiceProtocol.Version,
            ServerId = "test-server",
            ProximityRange = 7,
            Sessions =
            [
                new GameSessionSnapshot
                {
                    SessionId = sessionId,
                    DisplayName = "Test Player",
                    WantsConnection = true,
                    CanSpeak = true,
                    CanListen = true,
                    VoiceActivationEnabled = true,
                    VoiceActivationThreshold = 150,
                    NoiseSuppressionLevel = 150,
                    OutputTestSequence = 3,
                    MicrophoneTestSequence = 4,
                    CalibrationSequence = 5,
                    CalibrationRequested = true,
                    Position = new VoicePosition { X = 1, Y = 2, Z = 3 },
                    PushToTalkKeys = ["Space"],
                },
            ],
        },
        CancellationToken.None);

    var sessionResponse = response.Sessions.Single();
    Assert(sessionResponse.Status == "connecting", "Disconnected helper has an invalid status.");
    Assert(!string.IsNullOrWhiteSpace(sessionResponse.ConnectToken), "Relay did not issue a connect token.");
    var repeatedResponse = await relay.ApplySnapshotAsync(
        new GameSnapshotRequest
        {
            ProtocolVersion = VoiceProtocol.Version,
            ServerId = "test-server",
            ProximityRange = 7,
            Sessions =
            [
                new GameSessionSnapshot
                {
                    SessionId = sessionId,
                    DisplayName = "Test Player",
                    WantsConnection = true,
                    CanSpeak = true,
                    CanListen = true,
                    VoiceActivationEnabled = true,
                    VoiceActivationThreshold = 150,
                    NoiseSuppressionLevel = 150,
                    OutputTestSequence = 3,
                    MicrophoneTestSequence = 4,
                    CalibrationSequence = 5,
                    CalibrationRequested = true,
                },
            ],
        },
        CancellationToken.None);
    Assert(
        repeatedResponse.Sessions.Single().ConnectToken == sessionResponse.ConnectToken,
        "Relay replaced a still-valid connect token.");
    Assert(relay.TryConsumeToken(sessionResponse.ConnectToken, out var session), "Fresh token was rejected.");
    Assert(session.Snapshot.SessionId == sessionId, "Token resolved to the wrong session.");
    var helperConfig = session.CreateHelperConfig();
    Assert(helperConfig.VoiceActivationEnabled, "Voice activation was not forwarded to the helper.");
    Assert(helperConfig.VoiceActivationThreshold == 100, "Voice activation threshold was not clamped.");
    Assert(
        helperConfig.NoiseSuppressionLevel == VoiceProtocol.MaximumNoiseSuppressionLevel,
        "Noise suppression level was not clamped.");
    Assert(helperConfig.OutputTestSequence == 3, "Output test request was not forwarded.");
    Assert(helperConfig.MicrophoneTestSequence == 4, "Microphone test request was not forwarded.");
    Assert(helperConfig.CalibrationSequence == 5, "Calibration request was not forwarded.");
    Assert(helperConfig.CalibrationRequested, "Calibration pending state was not forwarded.");
    Assert(!relay.TryConsumeToken(sessionResponse.ConnectToken, out _), "One-time token was accepted twice.");
}

static void Assert(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}
