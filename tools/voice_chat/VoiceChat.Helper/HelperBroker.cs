using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Text;
using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public sealed class HelperBroker
{
    public const int Port = 6191;
    private const int MaximumRequestBytes = 8192;
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(3);
    private readonly string executablePath;
    private long lastLaunchTimestamp;

    public HelperBroker(string executablePath)
    {
        this.executablePath = executablePath;
    }

    public async Task RunAsync(CancellationToken cancellationToken)
    {
        var listener = new TcpListener(IPAddress.Loopback, Port);
        listener.Start();
        try
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                var client = await listener.AcceptTcpClientAsync(cancellationToken);
                _ = HandleClientAsync(client, cancellationToken);
            }
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
        }
        finally
        {
            listener.Stop();
        }
    }

    private async Task HandleClientAsync(TcpClient client, CancellationToken cancellationToken)
    {
        using (client)
        using (var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken))
        {
            timeout.CancelAfter(RequestTimeout);
            try
            {
                var stream = client.GetStream();
                var request = await ReadRequestAsync(stream, timeout.Token);
                if (request is null)
                {
                    await WriteResponseAsync(stream, "400 Bad Request", timeout.Token);
                    return;
                }

                if (request.Method == "OPTIONS")
                {
                    await WriteResponseAsync(stream, "204 No Content", timeout.Token);
                    return;
                }

                if (request.Method != "GET" || !IsAllowedHost(request.Host) ||
                    !TryCreateLaunchUri(request.Target, out var launchUri))
                {
                    await WriteResponseAsync(stream, "404 Not Found", timeout.Token);
                    return;
                }

                var now = Stopwatch.GetTimestamp();
                var previous = Interlocked.Read(ref lastLaunchTimestamp);
                if (previous != 0 && Stopwatch.GetElapsedTime(previous, now) < TimeSpan.FromSeconds(1))
                {
                    await WriteResponseAsync(stream, "429 Too Many Requests", timeout.Token);
                    return;
                }

                Interlocked.Exchange(ref lastLaunchTimestamp, now);
                var startInfo = new ProcessStartInfo(executablePath)
                {
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    WindowStyle = ProcessWindowStyle.Hidden,
                };
                startInfo.ArgumentList.Add(launchUri);
                Process.Start(startInfo)?.Dispose();
                await WriteResponseAsync(stream, "204 No Content", timeout.Token);
            }
            catch (OperationCanceledException)
            {
            }
            catch (IOException)
            {
            }
            catch (SocketException)
            {
            }
        }
    }

    public static bool TryCreateLaunchUri(string requestTarget, out string launchUri)
    {
        launchUri = string.Empty;
        try
        {
            if (!Uri.TryCreate($"http://127.0.0.1{requestTarget}", UriKind.Absolute, out var requestUri) ||
                requestUri.AbsolutePath != "/launch")
            {
                return false;
            }

            var query = ParseQuery(requestUri.Query);
            if (!query.TryGetValue("relay", out var relay) ||
                !query.TryGetValue("token", out var token) ||
                !query.TryGetValue("protocol", out var protocol) ||
                token.Length != 43 || !token.All(IsTokenCharacter) ||
                protocol != VoiceProtocol.Version.ToString())
            {
                return false;
            }

            launchUri = $"paradise-voice://connect?relay={Uri.EscapeDataString(relay)}" +
                $"&token={Uri.EscapeDataString(token)}&protocol={protocol}";
            return LaunchOptions.TryParse([launchUri], out _);
        }
        catch (UriFormatException)
        {
            return false;
        }
    }

    private static async Task<BrokerRequest?> ReadRequestAsync(
        NetworkStream stream,
        CancellationToken cancellationToken)
    {
        var buffer = new byte[MaximumRequestBytes];
        var count = 0;
        while (count < buffer.Length)
        {
            var read = await stream.ReadAsync(buffer.AsMemory(count), cancellationToken);
            if (read == 0)
            {
                return null;
            }

            count += read;
            if (FindHeaderEnd(buffer.AsSpan(0, count)) >= 0)
            {
                break;
            }
        }

        if (FindHeaderEnd(buffer.AsSpan(0, count)) < 0)
        {
            return null;
        }

        var lines = Encoding.ASCII.GetString(buffer, 0, count)
            .Split("\r\n", StringSplitOptions.None);
        var requestLine = lines[0].Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (requestLine.Length != 3 || requestLine[2] is not ("HTTP/1.0" or "HTTP/1.1"))
        {
            return null;
        }

        var host = string.Empty;
        foreach (var line in lines.Skip(1))
        {
            if (line.Length == 0)
            {
                break;
            }

            var separator = line.IndexOf(':');
            if (separator > 0 && line[..separator].Equals("Host", StringComparison.OrdinalIgnoreCase))
            {
                host = line[(separator + 1)..].Trim();
            }
        }

        return new BrokerRequest(requestLine[0], requestLine[1], host);
    }

    private static int FindHeaderEnd(ReadOnlySpan<byte> buffer)
    {
        return buffer.IndexOf("\r\n\r\n"u8);
    }

    private static bool IsAllowedHost(string host)
    {
        return host.Equals($"127.0.0.1:{Port}", StringComparison.OrdinalIgnoreCase) ||
            host.Equals($"localhost:{Port}", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsTokenCharacter(char value)
    {
        return char.IsAsciiLetterOrDigit(value) || value is '-' or '_';
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

    private static Task WriteResponseAsync(
        NetworkStream stream,
        string status,
        CancellationToken cancellationToken)
    {
        var response = Encoding.ASCII.GetBytes(
            $"HTTP/1.1 {status}\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Access-Control-Allow-Methods: GET, OPTIONS\r\n" +
            "Access-Control-Allow-Private-Network: true\r\n" +
            "Cache-Control: no-store\r\n" +
            "Connection: close\r\n" +
            "Content-Length: 0\r\n\r\n");
        return stream.WriteAsync(response, cancellationToken).AsTask();
    }

    private sealed record BrokerRequest(string Method, string Target, string Host);
}
