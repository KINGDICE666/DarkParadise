using System.Runtime.InteropServices;

namespace VoiceChat.Helper;

public sealed class PushToTalkMonitor
{
    private static readonly Dictionary<string, int> NamedKeys = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Space"] = 0x20,
        ["Tab"] = 0x09,
        ["Enter"] = 0x0D,
        ["Return"] = 0x0D,
        ["Escape"] = 0x1B,
        ["Back"] = 0x08,
        ["Delete"] = 0x2E,
        ["Insert"] = 0x2D,
        ["Home"] = 0x24,
        ["End"] = 0x23,
        ["PageUp"] = 0x21,
        ["PageDown"] = 0x22,
        ["North"] = 0x26,
        ["South"] = 0x28,
        ["West"] = 0x25,
        ["East"] = 0x27,
        ["LButton"] = 0x01,
        ["RButton"] = 0x02,
        ["Middle"] = 0x04,
    };

    public bool IsPressed(IReadOnlyList<string> bindings)
    {
        return bindings.Any(IsChordPressed);
    }

    private static bool IsChordPressed(string binding)
    {
        var key = binding;
        var requireControl = false;
        var requireAlt = false;
        var requireShift = false;
        var removedModifier = true;
        while (removedModifier)
        {
            removedModifier = false;
            if (!requireControl && RemovePrefix(ref key, "Ctrl"))
            {
                requireControl = true;
                removedModifier = true;
            }
            if (!requireAlt && RemovePrefix(ref key, "Alt"))
            {
                requireAlt = true;
                removedModifier = true;
            }
            if (!requireShift && RemovePrefix(ref key, "Shift"))
            {
                requireShift = true;
                removedModifier = true;
            }
        }

        return (!requireControl || KeyDown(0x11)) &&
            (!requireAlt || KeyDown(0x12)) &&
            (!requireShift || KeyDown(0x10)) &&
            TryGetVirtualKey(key, out var virtualKey) &&
            KeyDown(virtualKey);
    }

    private static bool RemovePrefix(ref string value, string prefix)
    {
        if (!value.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        value = value[prefix.Length..];
        return true;
    }

    private static bool TryGetVirtualKey(string key, out int virtualKey)
    {
        if (NamedKeys.TryGetValue(key, out virtualKey))
        {
            return true;
        }

        if (key.Length == 1 && char.IsAsciiLetterOrDigit(key[0]))
        {
            virtualKey = char.ToUpperInvariant(key[0]);
            return true;
        }

        if (key.StartsWith('F') && int.TryParse(key.AsSpan(1), out var functionKey) &&
            functionKey is >= 1 and <= 24)
        {
            virtualKey = 0x6F + functionKey;
            return true;
        }

        virtualKey = 0;
        return false;
    }

    private static bool KeyDown(int virtualKey)
    {
        return (GetAsyncKeyState(virtualKey) & 0x8000) != 0;
    }

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int virtualKey);
}
