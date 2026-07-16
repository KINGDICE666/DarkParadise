$schemePath = 'HKCU:\Software\Classes\paradise-voice'
$runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runValueName = 'ParadiseVoiceHelper'

if (Test-Path -LiteralPath $runPath) {
    Remove-ItemProperty -LiteralPath $runPath -Name $runValueName -ErrorAction SilentlyContinue
}
if (Test-Path -LiteralPath $schemePath) {
    Remove-Item -LiteralPath $schemePath -Recurse -Force
}
Get-CimInstance Win32_Process -Filter "Name = 'ParadiseVoiceHelper.exe'" |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host "Paradise Voice Helper registration and background process removed."
