using Microsoft.AspNetCore.Http.Json;
using VoiceChat.Protocol;
using VoiceChat.Relay;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls(builder.Configuration["VOICE_CHAT_LISTEN_URL"] ?? "http://0.0.0.0:6180");
builder.Services.Configure<JsonOptions>(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = VoiceProtocol.JsonOptions.PropertyNamingPolicy;
});

var apiKey = builder.Configuration["VOICE_CHAT_API_KEY"];
if (string.IsNullOrWhiteSpace(apiKey))
{
    throw new InvalidOperationException("VOICE_CHAT_API_KEY must be configured.");
}

builder.Services.AddSingleton(new RelayStore(apiKey));
var app = builder.Build();
app.UseWebSockets(new WebSocketOptions
{
    KeepAliveInterval = TimeSpan.FromSeconds(20),
});

app.MapGet("/health", () => Results.Ok(new { status = "ok", protocol_version = VoiceProtocol.Version }));

app.MapPost("/v1/game/snapshot", async (
    HttpRequest httpRequest,
    GameSnapshotRequest snapshot,
    RelayStore relay,
    CancellationToken cancellationToken) =>
{
    if (!httpRequest.Headers.TryGetValue("X-Voice-Key", out var suppliedKey) ||
        !relay.Authenticate(suppliedKey.ToString()))
    {
        return Results.Unauthorized();
    }

    if (snapshot.ProtocolVersion != VoiceProtocol.Version)
    {
        return Results.BadRequest(new { error = "protocol_mismatch" });
    }

    var response = await relay.ApplySnapshotAsync(snapshot, cancellationToken);
    return Results.Ok(response);
});

app.Map("/v1/connect", async context =>
{
    var relay = context.RequestServices.GetRequiredService<RelayStore>();
    if (!context.WebSockets.IsWebSocketRequest)
    {
        context.Response.StatusCode = StatusCodes.Status400BadRequest;
        return;
    }

    if (!int.TryParse(context.Request.Query["protocol"], out var protocol) ||
        protocol != VoiceProtocol.Version ||
        !relay.TryConsumeToken(context.Request.Query["token"].ToString(), out var session))
    {
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        return;
    }

    using var socket = await context.WebSockets.AcceptWebSocketAsync();
    await relay.RunConnectionAsync(session, socket, context.RequestAborted);
});

await app.RunAsync();
