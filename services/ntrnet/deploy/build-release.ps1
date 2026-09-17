$ErrorActionPreference = 'Stop'
$serviceDirectory = Split-Path -Parent $PSScriptRoot
$repositoryDirectory = Split-Path -Parent (Split-Path -Parent $serviceDirectory)
$outputDirectory = Join-Path $repositoryDirectory '.cache'
$archive = Join-Path $outputDirectory 'ntrnet-release.zip'
$files = @(
    'app.py',
    'content.py',
    'database.py',
    'editor.py',
    'manage.py',
    'storage.py',
    'requirements.txt',
    'requirements.lock',
    'README.md',
    'deploy',
    'static',
    'templates'
)

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive
}
Push-Location $serviceDirectory
try {
    Compress-Archive -Path $files -DestinationPath $archive -CompressionLevel Optimal
} finally {
    Pop-Location
}
Write-Output $archive
