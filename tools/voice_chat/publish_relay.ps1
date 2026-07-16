$project = "$PSScriptRoot\VoiceChat.Relay\VoiceChat.Relay.csproj"
$output = "$PSScriptRoot\runtime\relay"
dotnet publish $project -c Release --no-self-contained -o $output
exit $LASTEXITCODE
