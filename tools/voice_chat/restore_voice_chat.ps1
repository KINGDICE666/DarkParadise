Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$runtimePath = "$scriptRoot\runtime"
$relayPath = [IO.Path]::GetFullPath("$runtimePath\relay\VoiceChat.Relay.exe")
$helperPath = [IO.Path]::GetFullPath("$scriptRoot\dist\ParadiseVoiceHelper.exe")

& "$scriptRoot\stop_voice_chat.ps1"
Get-CimInstance Win32_Process -Filter "Name = 'VoiceChat.Relay.exe'" |
    Where-Object { [string]::Equals($_.ExecutablePath, $relayPath, [StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop
        Wait-Process -Id $_.ProcessId -Timeout 10 -ErrorAction SilentlyContinue
    }

Write-Host 'Building and installing Paradise Voice Helper...'
& "$scriptRoot\publish_helper.ps1" -Install
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host 'Building Paradise Voice Relay...'
& "$scriptRoot\publish_relay.ps1"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host 'Starting Paradise voice services...'
& "$scriptRoot\start_voice_chat.ps1"

$statePath = "$runtimePath\voice_chat.json"
if (!(Test-Path -LiteralPath $helperPath) -or !(Test-Path -LiteralPath $statePath)) {
    throw 'Voice chat restore did not create the expected helper and relay state files.'
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$health = Invoke-RestMethod -Uri $state.health_url -TimeoutSec 5
if ($health.protocol_version -ne 1) {
    throw 'Voice relay returned an unexpected protocol version.'
}

$healthUri = [Uri]$state.health_url
$downloadUri = [Uri]::new($healthUri, '/download/windows')
$downloadRequest = [System.Net.HttpWebRequest]::Create($downloadUri)
$downloadRequest.AddRange(0, 0)
$downloadResponse = $downloadRequest.GetResponse()
try {
    if ($downloadResponse.StatusCode -ne [System.Net.HttpStatusCode]::PartialContent) {
        throw "Helper download check returned HTTP $([int]$downloadResponse.StatusCode)."
    }
}
finally {
    $downloadResponse.Close()
}

& "$scriptRoot\voice_chat_status.ps1"
Write-Host 'Paradise voice chat was restored successfully.'
