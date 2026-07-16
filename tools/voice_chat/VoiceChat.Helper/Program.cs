using VoiceChat.Helper;

var executablePath = Environment.ProcessPath ??
    throw new InvalidOperationException("Helper path is unavailable.");
var logDirectory = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
    "ParadiseVoice");
Directory.CreateDirectory(logDirectory);
var logPath = Path.Combine(logDirectory, "helper.log");

if (args is ["--broker"])
{
    using var mutex = new Mutex(true, @"Local\ParadiseVoiceHelperBroker", out var createdNew);
    if (!createdNew)
    {
        return;
    }

    try
    {
        await new HelperBroker(executablePath).RunAsync(CancellationToken.None);
    }
    catch (Exception exception)
    {
        await File.AppendAllTextAsync(logPath, $"{DateTimeOffset.Now:O} broker {exception}\n");
    }
    return;
}

if (args.Length == 0 || args is ["--install"])
{
    ProtocolRegistration.Install(executablePath);
    if (args.Length == 0)
    {
        ProtocolRegistration.ShowInstalledMessage();
    }
    return;
}

if (!LaunchOptions.TryParse(args, out var options))
{
    return;
}

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
