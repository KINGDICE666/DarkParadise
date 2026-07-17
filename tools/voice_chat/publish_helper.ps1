param(
    [switch]$Install
)

$project = "$PSScriptRoot\VoiceChat.Helper\VoiceChat.Helper.csproj"
$scriptRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$output = [IO.Path]::GetFullPath("$scriptRoot\dist")
$stagingOutput = [IO.Path]::GetFullPath("$scriptRoot\runtime\helper-publish")
$targetExecutable = "$output\ParadiseVoiceHelper.exe"
if (Test-Path -LiteralPath $stagingOutput) {
    $resolvedStagingOutput = (Resolve-Path -LiteralPath $stagingOutput).Path
    if (![string]::Equals($resolvedStagingOutput, "$scriptRoot\runtime\helper-publish", [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean unexpected helper staging path: $resolvedStagingOutput"
    }
    Remove-Item -LiteralPath $resolvedStagingOutput -Recurse -Force
}

dotnet publish $project -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    -o $stagingOutput
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$publishedExecutable = "$stagingOutput\VoiceChat.Helper.exe"
if (!(Test-Path -LiteralPath $publishedExecutable)) {
    throw "Published helper executable was not created: $publishedExecutable"
}

Get-CimInstance Win32_Process -Filter "Name = 'ParadiseVoiceHelper.exe'" |
    Where-Object { [string]::Equals($_.ExecutablePath, $targetExecutable, [StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop }
New-Item -ItemType Directory -Path $output -Force | Out-Null
Move-Item -LiteralPath $publishedExecutable -Destination $targetExecutable -Force
Remove-Item -LiteralPath $stagingOutput -Recurse -Force
if ($Install) {
    & $targetExecutable --install
}
