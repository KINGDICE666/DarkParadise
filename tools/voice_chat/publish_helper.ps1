param(
    [switch]$Install
)

$project = "$PSScriptRoot\VoiceChat.Helper\VoiceChat.Helper.csproj"
$output = "$PSScriptRoot\dist"
dotnet publish $project -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o $output
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$publishedExecutable = "$output\VoiceChat.Helper.exe"
$targetExecutable = "$output\ParadiseVoiceHelper.exe"
Move-Item -LiteralPath $publishedExecutable -Destination $targetExecutable -Force
if ($Install) {
    & "$PSScriptRoot\install_helper.ps1" -ExecutablePath $targetExecutable
}
