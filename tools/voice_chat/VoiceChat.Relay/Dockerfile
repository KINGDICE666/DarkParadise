FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY VoiceChat.Protocol/ VoiceChat.Protocol/
COPY VoiceChat.Relay/ VoiceChat.Relay/
COPY Directory.Build.props .
RUN dotnet publish VoiceChat.Relay/VoiceChat.Relay.csproj -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
EXPOSE 6180
ENTRYPOINT ["dotnet", "VoiceChat.Relay.dll"]
