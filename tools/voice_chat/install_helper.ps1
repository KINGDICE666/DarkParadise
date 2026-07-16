param(
    [string]$ExecutablePath = "$PSScriptRoot\dist\ParadiseVoiceHelper.exe"
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$schemePath = 'HKCU:\Software\Classes\paradise-voice'
New-Item -Path $schemePath -Force | Out-Null
Set-ItemProperty -Path $schemePath -Name '(Default)' -Value 'URL:Paradise Voice Protocol'
Set-ItemProperty -Path $schemePath -Name 'URL Protocol' -Value ''
New-Item -Path "$schemePath\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$schemePath\DefaultIcon" -Name '(Default)' -Value "`"$resolvedExecutable`",0"
New-Item -Path "$schemePath\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$schemePath\shell\open\command" -Name '(Default)' -Value "`"$resolvedExecutable`" `"%1`""
Write-Host "Paradise Voice Helper registered for the current Windows user."
