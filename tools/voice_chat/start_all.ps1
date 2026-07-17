Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& "$PSScriptRoot\start_voice_chat.ps1"

$repositoryRoot = (Resolve-Path -LiteralPath "$PSScriptRoot\..\..").Path
$gamePath = "$repositoryRoot\paradise.dmb"
$daemonPath = 'C:\Program Files (x86)\BYOND\bin\dreamdaemon.exe'
$runningDaemon = Get-CimInstance Win32_Process -Filter "Name = 'dreamdaemon.exe'" |
    Where-Object { $_.CommandLine -like "*$gamePath*" } |
    Select-Object -First 1

if ($null -ne $runningDaemon) {
    Write-Host "Paradise DreamDaemon is already running (PID $($runningDaemon.ProcessId))."
    return
}

$daemon = Start-Process `
    -FilePath $daemonPath `
    -ArgumentList "`"$gamePath`"" `
    -WorkingDirectory $repositoryRoot `
    -WindowStyle Hidden `
    -PassThru
Start-Sleep -Seconds 3
$daemon.Refresh()
if ($daemon.HasExited) {
    throw "DreamDaemon exited with code $($daemon.ExitCode)."
}
Write-Host "Paradise DreamDaemon started (PID $($daemon.Id))."
