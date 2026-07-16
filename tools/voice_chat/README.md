# Paradise Native Voice Chat

This implementation keeps voice controls inside the game while moving microphone capture and audio playback into a small native Windows helper. Dream Daemon remains authoritative for identity, speech permissions, position, mute state, and proximity.

## Components

- `VoiceChat.Protocol` contains the versioned JSON and binary protocol.
- `VoiceChat.Relay` authenticates game snapshots, issues one-time helper tokens, and routes proximity audio.
- `VoiceChat.Helper` captures and plays audio through Windows, applies push-to-talk before transmission, and uses Opus at 48 kHz mono with 20 ms frames.
- `VoiceChat.Tests` checks framing, launch URI validation, API-key authentication, and one-time tokens without an external test framework.

## Relay

Set a long random shared key and start the relay:

```powershell
$env:VOICE_CHAT_API_KEY = 'replace-with-a-long-random-value'
$env:VOICE_CHAT_LISTEN_URL = 'http://0.0.0.0:6180'
dotnet run --project tools\voice_chat\VoiceChat.Relay\VoiceChat.Relay.csproj -c Release
```

The relay accepts the internal game snapshot endpoint only from localhost. For production, expose `/v1/connect` as `wss://` through the same reverse proxy used for other services.

The container can be built with `tools/voice_chat` as its context:

```powershell
docker build -f VoiceChat.Relay\Dockerfile -t paradise-voice-relay .
```

## Windows helper

Publish and register the helper for the current Windows user:

```powershell
tools\voice_chat\publish_helper.ps1 -Install
```

This registers the helper under `HKCU`; administrator rights are not required. A loopback-only launcher listens on `127.0.0.1:6191`, starts with Windows, and lets TGUI launch the native voice connection without opening a browser. The helper reports its devices, levels, and errors to the in-game panel. To remove the registration and background launcher, run `tools\voice_chat\uninstall_helper.ps1`.

The published helper is a single self-contained Windows executable. A player can install it by double-clicking it; no repository, administrator access, or separate .NET installation is needed. When the relay is started by `start_voice_chat.ps1`, the same file is available to players at:

```text
http://your-server:3000/download/windows
```

## Game configuration

Copy the voice settings from `config/example/config.txt` and set matching relay values:

```text
VOICE_CHAT_ENABLED
VOICE_CHAT_RELAY_URL http://127.0.0.1:6180
VOICE_CHAT_PUBLIC_URL wss://voice.example.org/v1/connect
VOICE_CHAT_HELPER_DOWNLOAD_URL https://voice.example.org/download/windows
VOICE_CHAT_API_KEY replace-with-the-same-long-random-value
VOICE_CHAT_URI_SCHEME paradise-voice
VOICE_CHAT_PROXIMITY_RANGE 7
```

For a server without a domain or reverse proxy, the relay can listen on a forwarded port such as `3000`:

```text
VOICE_CHAT_RELAY_URL http://127.0.0.1:3000
VOICE_CHAT_PUBLIC_URL ws://203.0.113.10:3000/v1/connect
VOICE_CHAT_HELPER_DOWNLOAD_URL http://203.0.113.10:3000/download/windows
```

Allow inbound TCP `3000` in Windows Firewall and forward TCP `3000` to the host. Raw `ws://` works but does not encrypt voice traffic; a domain with TLS and `wss://` is recommended for an Internet-facing server.

Players open **Спецкоманды → Голосовой чат**. The default push-to-talk key is `Space` and can be changed in the normal keybinding preferences.

## Verification

```powershell
dotnet build tools\voice_chat\VoiceChat.Relay\VoiceChat.Relay.csproj -c Release
dotnet build tools\voice_chat\VoiceChat.Helper\VoiceChat.Helper.csproj -c Release
dotnet run --project tools\voice_chat\VoiceChat.Tests\VoiceChat.Tests.csproj -c Release
tgui\bin\tgui.bat --lint
```

## Local start and stop

After configuring `config/config.txt`, publish and install the helper once, then start the relay:

```powershell
tools\voice_chat\publish_helper.ps1 -Install
tools\voice_chat\start_all.ps1
```

Check its state or stop it with:

```powershell
tools\voice_chat\voice_chat_status.ps1
tools\voice_chat\stop_voice_chat.ps1
tools\voice_chat\stop_all.ps1
```

`stop_voice_chat.ps1` stops only voice and leaves DreamDaemon running. `stop_all.ps1` stops both the local voice relay and this repository's DreamDaemon instance.
