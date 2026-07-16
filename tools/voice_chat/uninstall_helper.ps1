$schemePath = 'HKCU:\Software\Classes\paradise-voice'
if (Test-Path -LiteralPath $schemePath) {
    Remove-Item -LiteralPath $schemePath -Recurse -Force
}
Write-Host "Paradise Voice Helper protocol registration removed."
