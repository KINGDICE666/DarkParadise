Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$statePath = "$PSScriptRoot\runtime\voice_chat.json"
if (!(Test-Path -LiteralPath $statePath)) {
    Write-Host 'Relay: stopped'
}
else {
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $relayProcess = Get-Process -Id $state.pid -ErrorAction SilentlyContinue
    if ($null -eq $relayProcess) {
        Write-Host 'Relay: stopped (stale state file)'
    }
    else {
        try {
            $health = Invoke-RestMethod -Uri $state.health_url -TimeoutSec 2
            Write-Host "Relay: running (PID $($state.pid), protocol $($health.protocol_version))"
        }
        catch {
            Write-Host "Relay: process exists but health check failed (PID $($state.pid))"
        }
    }
}

$schemePath = 'HKCU:\Software\Classes\paradise-voice\shell\open\command'
if (Test-Path -LiteralPath $schemePath) {
    $broker = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 6191 -State Listen -ErrorAction SilentlyContinue
    if ($null -ne $broker) {
        Write-Host 'Helper: installed, local launcher is running on 127.0.0.1:6191'
    }
    else {
        Write-Host 'Helper: installed, local launcher is not running'
    }
}
else {
    Write-Host 'Helper: not installed'
}
