using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Win32;

namespace VoiceChat.Helper;

internal static class ProtocolRegistration
{
    private const string SchemePath = @"Software\Classes\paradise-voice";
    private const string RunPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string RunValueName = "ParadiseVoiceHelper";

    public static void Install(string executablePath)
    {
        var fullPath = Path.GetFullPath(executablePath);
        using var scheme = Registry.CurrentUser.CreateSubKey(SchemePath, writable: true) ??
            throw new InvalidOperationException("Could not create the Paradise Voice protocol registration.");
        scheme.SetValue(string.Empty, "URL:Paradise Voice Protocol");
        scheme.SetValue("URL Protocol", string.Empty);

        using var icon = scheme.CreateSubKey("DefaultIcon", writable: true);
        icon?.SetValue(string.Empty, $"\"{fullPath}\",0");

        using var command = scheme.CreateSubKey(@"shell\open\command", writable: true);
        command?.SetValue(string.Empty, $"\"{fullPath}\" \"%1\"");

        using var run = Registry.CurrentUser.CreateSubKey(RunPath, writable: true);
        run?.SetValue(RunValueName, $"\"{fullPath}\" --broker");
        StartBroker(fullPath);
    }

    private static void StartBroker(string executablePath)
    {
        var startInfo = new ProcessStartInfo(executablePath)
        {
            CreateNoWindow = true,
            UseShellExecute = false,
            WindowStyle = ProcessWindowStyle.Hidden,
        };
        startInfo.ArgumentList.Add("--broker");
        Process.Start(startInfo)?.Dispose();
    }

    public static void ShowInstalledMessage()
    {
        MessageBox(
            0,
            "Paradise Voice установлен. Теперь откройте голосовой чат внутри игры и нажмите «Подключиться».",
            "Paradise Voice",
            0x40);
    }

    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "MessageBoxW")]
    private static extern int MessageBox(nint window, string text, string caption, uint type);
}
