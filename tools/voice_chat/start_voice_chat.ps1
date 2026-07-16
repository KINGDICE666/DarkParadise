Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath "$PSScriptRoot\..\..").Path
$configPath = "$repositoryRoot\config\config.txt"
$runtimePath = "$PSScriptRoot\runtime"
$relayPath = "$runtimePath\relay\VoiceChat.Relay.exe"
$statePath = "$runtimePath\voice_chat.json"
$stdoutPath = "$runtimePath\relay.stdout.log"
$stderrPath = "$runtimePath\relay.stderr.log"
$helperPath = "$PSScriptRoot\dist\ParadiseVoiceHelper.exe"

function Get-VoiceConfigValue([string]$Name) {
    $pattern = "^\s*$([regex]::Escape($Name))\s+(.+?)\s*$"
    $line = Get-Content -LiteralPath $configPath | Where-Object { $_ -match $pattern } | Select-Object -Last 1
    if ($null -eq $line) {
        throw "Missing $Name in $configPath"
    }
    return ([regex]::Match($line, $pattern)).Groups[1].Value
}

New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
if (Test-Path -LiteralPath $statePath) {
    $existingState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $existingProcess = Get-Process -Id $existingState.pid -ErrorAction SilentlyContinue
    if ($null -ne $existingProcess) {
        if ([string]::Equals($existingProcess.Path, $existingState.executable, [StringComparison]::OrdinalIgnoreCase)) {
            $existingHealth = Invoke-RestMethod -Uri $existingState.health_url -TimeoutSec 2
            if ($existingHealth.protocol_version -eq 1) {
                Write-Host "Paradise voice relay is already running (PID $($existingState.pid))."
                return
            }
            throw "Relay process exists but its health check failed (PID $($existingState.pid))."
        }
    }
    Remove-Item -LiteralPath $statePath -Force
}

if (!(Test-Path -LiteralPath $relayPath)) {
    & "$PSScriptRoot\publish_relay.ps1"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$apiKey = Get-VoiceConfigValue 'VOICE_CHAT_API_KEY'
$internalUrl = (Get-VoiceConfigValue 'VOICE_CHAT_RELAY_URL').TrimEnd('/')
$internalUri = [Uri]$internalUrl
$listenUrl = "$($internalUri.Scheme)://0.0.0.0:$($internalUri.Port)"
$healthUrl = "$internalUrl/health"
$previousApiKey = $env:VOICE_CHAT_API_KEY
$previousListenUrl = $env:VOICE_CHAT_LISTEN_URL
$previousHelperPath = $env:VOICE_CHAT_HELPER_PATH
$relayProcess = $null

try {
    $env:VOICE_CHAT_API_KEY = $apiKey
    $env:VOICE_CHAT_LISTEN_URL = $listenUrl
    $env:VOICE_CHAT_HELPER_PATH = $helperPath
    $relayProcess = Start-Process `
        -FilePath $relayPath `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    $health = $null
    for ($attempt = 0; $attempt -lt 50 -and $null -eq $health; $attempt++) {
        try {
            $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 1
        }
        catch {
            Start-Sleep -Milliseconds 200
        }
    }

    if ($null -eq $health -or $health.protocol_version -ne 1) {
        throw "Relay did not pass its health check. See $stderrPath"
    }

    [ordered]@{
        pid = $relayProcess.Id
        executable = (Resolve-Path -LiteralPath $relayPath).Path
        health_url = $healthUrl
        listen_url = $listenUrl
        started_at = [DateTimeOffset]::Now.ToString('O')
    } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
    Write-Host "Paradise voice relay started (PID $($relayProcess.Id))."
}
catch {
    if ($null -ne $relayProcess -and !$relayProcess.HasExited) {
        Stop-Process -Id $relayProcess.Id -Force
    }
    throw
}
finally {
    $env:VOICE_CHAT_API_KEY = $previousApiKey
    $env:VOICE_CHAT_LISTEN_URL = $previousListenUrl
    $env:VOICE_CHAT_HELPER_PATH = $previousHelperPath
}
