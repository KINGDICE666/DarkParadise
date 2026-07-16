using System.Text.Json;
using System.Text.Json.Serialization;

namespace VoiceChat.Protocol;

public sealed class DmBooleanJsonConverter : JsonConverter<bool>
{
    public override bool Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.True)
        {
            return true;
        }

        if (reader.TokenType == JsonTokenType.False)
        {
            return false;
        }

        if (reader.TokenType == JsonTokenType.Number &&
            reader.TryGetInt32(out var value) &&
            value is 0 or 1)
        {
            return value == 1;
        }

        throw new JsonException("Expected a JSON boolean or the DM boolean number 0 or 1.");
    }

    public override void Write(
        Utf8JsonWriter writer,
        bool value,
        JsonSerializerOptions options)
    {
        writer.WriteBooleanValue(value);
    }
}
