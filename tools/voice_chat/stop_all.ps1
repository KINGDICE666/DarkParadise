Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& "$PSScriptRoot\stop_voice_chat.ps1"
$repositoryRoot = (Resolve-Path -LiteralPath "$PSScriptRoot\..\..").Path
$gamePath = "$repositoryRoot\paradise.dmb"
$runningDaemons = Get-CimInstance Win32_Process -Filter "Name = 'dreamdaemon.exe'" |
    Where-Object { $_.CommandLine -like "*$gamePath*" }

if ($null -eq $runningDaemons) {
    Write-Host 'Paradise DreamDaemon is not running.'
    return
}

foreach ($daemon in $runningDaemons) {
    Stop-Process -Id $daemon.ProcessId -Force
    Wait-Process -Id $daemon.ProcessId -Timeout 10 -ErrorAction SilentlyContinue
    Write-Host "Paradise DreamDaemon stopped (PID $($daemon.ProcessId))."
}
