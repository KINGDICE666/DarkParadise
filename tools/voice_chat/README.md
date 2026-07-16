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

For production, expose `/v1/connect` as `wss://` through the same reverse proxy used for other services. Do not expose the internal game snapshot endpoint without TLS and network restrictions.

The container can be built with `tools/voice_chat` as its context:

```powershell
docker build -f VoiceChat.Relay\Dockerfile -t paradise-voice-relay .
```

## Windows helper

Publish and register the helper for the current Windows user:

```powershell
tools\voice_chat\publish_helper.ps1 -Install
```

This registers the `paradise-voice://` URL scheme under `HKCU`; administrator rights are not required. The helper runs in the background and reports its devices, levels, and errors to the in-game panel. To remove the registration, run `tools\voice_chat\uninstall_helper.ps1`.

## Game configuration

Copy the voice settings from `config/example/config.txt` and set matching relay values:

```text
VOICE_CHAT_ENABLED
VOICE_CHAT_RELAY_URL http://127.0.0.1:6180
VOICE_CHAT_PUBLIC_URL wss://voice.example.org/v1/connect
VOICE_CHAT_API_KEY replace-with-the-same-long-random-value
VOICE_CHAT_URI_SCHEME paradise-voice
VOICE_CHAT_PROXIMITY_RANGE 7
```

Players open **Спецкоманды → Голосовой чат**. The default push-to-talk key is `Space` and can be changed in the normal keybinding preferences.

## Verification

```powershell
dotnet build tools\voice_chat\VoiceChat.Relay\VoiceChat.Relay.csproj -c Release
dotnet build tools\voice_chat\VoiceChat.Helper\VoiceChat.Helper.csproj -c Release
dotnet run --project tools\voice_chat\VoiceChat.Tests\VoiceChat.Tests.csproj -c Release
tgui\bin\tgui.bat --lint
```
