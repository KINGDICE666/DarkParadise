Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$runtimePath = "$PSScriptRoot\runtime"
$statePath = "$runtimePath\voice_chat.json"
if (!(Test-Path -LiteralPath $statePath)) {
    Write-Host 'Paradise voice relay is not running.'
    return
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$relayProcess = Get-Process -Id $state.pid -ErrorAction SilentlyContinue
if ($null -eq $relayProcess) {
    Remove-Item -LiteralPath $statePath -Force
    Write-Host 'Paradise voice relay was already stopped.'
    return
}

$actualPath = $relayProcess.Path
if (![string]::Equals($actualPath, $state.executable, [StringComparison]::OrdinalIgnoreCase)) {
    throw "PID $($state.pid) now belongs to another process; refusing to stop it."
}

Stop-Process -Id $state.pid -Force
Wait-Process -Id $state.pid -Timeout 10 -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $statePath -Force
Write-Host 'Paradise voice relay stopped. Connected helpers will exit automatically.'
