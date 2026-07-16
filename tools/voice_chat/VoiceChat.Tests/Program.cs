using VoiceChat.Helper;
using VoiceChat.Protocol;
using VoiceChat.Relay;

TestAudioFrameRoundTrip();
TestLaunchUri();
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
                    Position = new VoicePosition { X = 1, Y = 2, Z = 3 },
                    PushToTalkKeys = ["Space"],
                },
            ],
        },
        CancellationToken.None);

    var sessionResponse = response.Sessions.Single();
    Assert(sessionResponse.Status == "connecting", "Disconnected helper has an invalid status.");
    Assert(!string.IsNullOrWhiteSpace(sessionResponse.ConnectToken), "Relay did not issue a connect token.");
    Assert(relay.TryConsumeToken(sessionResponse.ConnectToken, out var session), "Fresh token was rejected.");
    Assert(session.Snapshot.SessionId == sessionId, "Token resolved to the wrong session.");
    Assert(!relay.TryConsumeToken(sessionResponse.ConnectToken, out _), "One-time token was accepted twice.");
}

static void Assert(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}
