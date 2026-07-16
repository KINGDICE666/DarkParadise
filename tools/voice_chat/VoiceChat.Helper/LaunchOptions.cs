using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public sealed record LaunchOptions(Uri RelayUrl, string Token)
{
    public static bool TryParse(string[] args, out LaunchOptions options)
    {
        options = null!;
        if (args.Length != 1 || !Uri.TryCreate(args[0], UriKind.Absolute, out var launchUri) ||
            !string.Equals(launchUri.Scheme, "paradise-voice", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        var query = ParseQuery(launchUri.Query);
        if (!query.TryGetValue("relay", out var relayValue) ||
            !Uri.TryCreate(relayValue, UriKind.Absolute, out var relayUrl) ||
            relayUrl.Scheme is not ("ws" or "wss") ||
            !query.TryGetValue("token", out var token) || string.IsNullOrWhiteSpace(token) ||
            !query.TryGetValue("protocol", out var protocolValue) ||
            !int.TryParse(protocolValue, out var protocol) || protocol != VoiceProtocol.Version)
        {
            return false;
        }

        options = new LaunchOptions(relayUrl, token);
        return true;
    }

    public Uri CreateConnectionUri()
    {
        var builder = new UriBuilder(RelayUrl)
        {
            Query = $"token={Uri.EscapeDataString(Token)}&protocol={VoiceProtocol.Version}",
        };
        return builder.Uri;
    }

    private static Dictionary<string, string> ParseQuery(string value)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var pair in value.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var separator = pair.IndexOf('=');
            if (separator <= 0)
            {
                continue;
            }

            result[Uri.UnescapeDataString(pair[..separator])] =
                Uri.UnescapeDataString(pair[(separator + 1)..]);
        }

        return result;
    }
}
