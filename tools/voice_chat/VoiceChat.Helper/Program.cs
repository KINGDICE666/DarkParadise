using VoiceChat.Helper;

if (!LaunchOptions.TryParse(args, out var options))
{
    return;
}

var logDirectory = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
    "ParadiseVoice");
Directory.CreateDirectory(logDirectory);
var logPath = Path.Combine(logDirectory, "helper.log");

try
{
    await using var client = new VoiceClient(options);
    await client.RunAsync(CancellationToken.None);
}
catch (Exception exception)
{
    await File.AppendAllTextAsync(
        logPath,
        $"{DateTimeOffset.Now:O} {exception}\n");
}
