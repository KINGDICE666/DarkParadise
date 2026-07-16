param(
    [switch]$Install
)

$project = "$PSScriptRoot\VoiceChat.Helper\VoiceChat.Helper.csproj"
$scriptRoot = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$output = [IO.Path]::GetFullPath("$scriptRoot\dist")
$targetExecutable = "$output\ParadiseVoiceHelper.exe"
Get-CimInstance Win32_Process -Filter "Name = 'ParadiseVoiceHelper.exe'" |
    Where-Object { [string]::Equals($_.ExecutablePath, $targetExecutable, [StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop }
if (Test-Path -LiteralPath $output) {
    $resolvedOutput = (Resolve-Path -LiteralPath $output).Path
    if (![string]::Equals($resolvedOutput, "$scriptRoot\dist", [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean unexpected helper output path: $resolvedOutput"
    }
    Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
}

dotnet publish $project -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:EnableCompressionInSingleFile=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    -o $output
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$publishedExecutable = "$output\VoiceChat.Helper.exe"
Move-Item -LiteralPath $publishedExecutable -Destination $targetExecutable -Force
if ($Install) {
    & $targetExecutable --install
}
