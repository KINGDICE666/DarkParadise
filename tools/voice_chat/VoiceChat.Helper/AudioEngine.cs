using System.Diagnostics;
using Concentus;
using Concentus.Enums;
using NAudio;
using NAudio.Wave;
using NAudio.Wave.SampleProviders;
using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public sealed class AudioEngine : IDisposable
{
    private const int PcmBytesPerFrame = VoiceProtocol.SamplesPerFrame * sizeof(short);
    private const int VoiceActivationHoldMilliseconds = 600;
    private const int MicrophoneTestSeconds = 5;
    private const double OutputTestFrequency = 660;
    private const double OutputTestGain = 0.2;

    private readonly object gate = new();
    private readonly IOpusEncoder encoder = OpusCodecFactory.CreateEncoder(
        VoiceProtocol.SampleRate,
        VoiceProtocol.Channels,
        OpusApplication.OPUS_APPLICATION_VOIP);
    private readonly Dictionary<Guid, SpeakerPlayback> speakers = [];
    private readonly byte[] pendingPcm = new byte[PcmBytesPerFrame * 8];
    private HelperConfigMessage? config;
    private WaveInEvent? capture;
    private WaveOutEvent? output;
    private MixingSampleProvider? mixer;
    private BufferedWaveProvider? microphoneMonitor;
    private VolumeSampleProvider? microphoneMonitorVolume;
    private int pendingPcmCount;
    private bool pushToTalkPressed;
    private bool testSequencesInitialized;
    private string activeInputDevice = string.Empty;
    private string activeOutputDevice = string.Empty;
    private int inputLevel;
    private int lastOutputTestSequence;
    private int lastMicrophoneTestSequence;
    private long voiceActivationUntilTimestamp;
    private long microphoneTestUntilTimestamp;
    private string error = string.Empty;

    public AudioEngine()
    {
        encoder.Bitrate = 24000;
        encoder.UseVBR = true;
        encoder.UseInbandFEC = true;
        encoder.PacketLossPercent = 10;
        InputDevices = EnumerateInputDevices();
        OutputDevices = EnumerateOutputDevices();
    }

    public event Action<byte[]>? AudioFrameReady;

    public List<VoiceDevice> InputDevices { get; }
    public List<VoiceDevice> OutputDevices { get; }
    public int InputLevel => Volatile.Read(ref inputLevel);
    public string Error => error;

    public bool Speaking
    {
        get
        {
            lock (gate)
            {
                return ShouldTransmit();
            }
        }
    }

    public IReadOnlyList<string> PushToTalkKeys
    {
        get
        {
            lock (gate)
            {
                return config?.PushToTalkKeys ?? [];
            }
        }
    }

    public void ApplyConfig(HelperConfigMessage value)
    {
        lock (gate)
        {
            config = value;
            error = string.Empty;
            var outputTestRequested = testSequencesInitialized &&
                value.OutputTestSequence != lastOutputTestSequence;
            var microphoneTestRequested = testSequencesInitialized &&
                value.MicrophoneTestSequence != lastMicrophoneTestSequence;
            lastOutputTestSequence = value.OutputTestSequence;
            lastMicrophoneTestSequence = value.MicrophoneTestSequence;
            testSequencesInitialized = true;
            if (!value.VoiceActivationEnabled)
            {
                voiceActivationUntilTimestamp = 0;
            }

            if (value.CanSpeak || microphoneTestRequested || IsMicrophoneTestActive())
            {
                try
                {
                    EnsureCapture(value.InputDeviceId);
                }
                catch (Exception exception) when (exception is MmException or InvalidOperationException or ArgumentException)
                {
                    error = $"Микрофон: {exception.Message}";
                }
            }
            else
            {
                StopCapture();
            }
            if (value.CanListen || outputTestRequested || microphoneTestRequested ||
                IsMicrophoneTestActive())
            {
                try
                {
                    EnsureOutput(value.OutputDeviceId);
                }
                catch (Exception exception) when (exception is MmException or InvalidOperationException or ArgumentException)
                {
                    error = string.IsNullOrEmpty(error)
                        ? $"Устройство вывода: {exception.Message}"
                        : $"{error}; устройство вывода: {exception.Message}";
                }
            }
            if (microphoneTestRequested && capture is not null && mixer is not null)
            {
                StartMicrophoneTest();
            }
            if (outputTestRequested && mixer is not null)
            {
                PlayOutputTest();
            }
            UpdateMicrophoneMonitorVolume();
            UpdateSpeakerVolumes();
        }
    }

    public void SetPushToTalk(bool pressed)
    {
        lock (gate)
        {
            pushToTalkPressed = pressed;
            if (!ShouldTransmit())
            {
                pendingPcmCount = 0;
            }
        }
    }

    public void Play(Guid speakerId, byte spatialVolume, ReadOnlySpan<byte> opusPacket)
    {
        lock (gate)
        {
            if (config is null || !config.CanListen || config.Deafened ||
                config.MutedPeers.Contains(speakerId.ToString("N")))
            {
                return;
            }

            if (!speakers.TryGetValue(speakerId, out var speaker))
            {
                speaker = CreateSpeaker(speakerId);
            }

            speaker.SpatialVolume = spatialVolume / 100f;
            UpdateSpeakerVolume(speakerId, speaker);
            speaker.DecodeAndBuffer(opusPacket);
        }
    }

    public void Dispose()
    {
        lock (gate)
        {
            capture?.StopRecording();
            capture?.Dispose();
            output?.Stop();
            output?.Dispose();
            capture = null;
            output = null;
            microphoneMonitor = null;
            microphoneMonitorVolume = null;
            speakers.Clear();
        }
    }

    private void EnsureCapture(string requestedDevice)
    {
        var selectedDevice = ResolveInputDevice(requestedDevice);
        if (capture is not null && activeInputDevice == selectedDevice)
        {
            return;
        }

        capture?.StopRecording();
        capture?.Dispose();
        capture = null;
        activeInputDevice = selectedDevice;
        pendingPcmCount = 0;

        if (!TryParseDeviceNumber(selectedDevice, "wavein:", out var deviceNumber))
        {
            throw new InvalidOperationException("No microphone is available.");
        }

        capture = new WaveInEvent
        {
            DeviceNumber = deviceNumber,
            WaveFormat = new WaveFormat(VoiceProtocol.SampleRate, 16, VoiceProtocol.Channels),
            BufferMilliseconds = VoiceProtocol.FrameMilliseconds,
            NumberOfBuffers = 3,
        };
        capture.DataAvailable += OnCaptureData;
        capture.RecordingStopped += OnRecordingStopped;
        capture.StartRecording();
    }

    private void StopCapture()
    {
        capture?.StopRecording();
        capture?.Dispose();
        capture = null;
        activeInputDevice = string.Empty;
        pendingPcmCount = 0;
        voiceActivationUntilTimestamp = 0;
        microphoneTestUntilTimestamp = 0;
        Volatile.Write(ref inputLevel, 0);
    }

    private void EnsureOutput(string requestedDevice)
    {
        var selectedDevice = ResolveOutputDevice(requestedDevice);
        if (output is not null && activeOutputDevice == selectedDevice)
        {
            return;
        }

        output?.Stop();
        output?.Dispose();
        output = null;
        activeOutputDevice = selectedDevice;
        speakers.Clear();

        if (!TryParseDeviceNumber(selectedDevice, "waveout:", out var deviceNumber))
        {
            deviceNumber = -1;
        }

        mixer = new MixingSampleProvider(
            WaveFormat.CreateIeeeFloatWaveFormat(VoiceProtocol.SampleRate, VoiceProtocol.Channels))
        {
            ReadFully = true,
        };
        microphoneMonitor = new BufferedWaveProvider(
            new WaveFormat(VoiceProtocol.SampleRate, 16, VoiceProtocol.Channels))
        {
            BufferDuration = TimeSpan.FromMilliseconds(240),
            DiscardOnBufferOverflow = true,
            ReadFully = true,
        };
        microphoneMonitorVolume = new VolumeSampleProvider(microphoneMonitor.ToSampleProvider());
        mixer.AddMixerInput(microphoneMonitorVolume);
        output = new WaveOutEvent
        {
            DeviceNumber = deviceNumber,
            DesiredLatency = 60,
            NumberOfBuffers = 3,
        };
        output.Init(mixer);
        output.Play();
    }

    private void OnCaptureData(object? sender, WaveInEventArgs eventArgs)
    {
        lock (gate)
        {
            UpdateInputLevel(eventArgs.Buffer.AsSpan(0, eventArgs.BytesRecorded));
            UpdateVoiceActivation();
            if (IsMicrophoneTestActive())
            {
                microphoneMonitor?.AddSamples(eventArgs.Buffer, 0, eventArgs.BytesRecorded);
            }
            if (!ShouldTransmit())
            {
                pendingPcmCount = 0;
                return;
            }

            var available = Math.Min(eventArgs.BytesRecorded, pendingPcm.Length - pendingPcmCount);
            eventArgs.Buffer.AsSpan(0, available).CopyTo(pendingPcm.AsSpan(pendingPcmCount));
            pendingPcmCount += available;
            while (pendingPcmCount >= PcmBytesPerFrame)
            {
                EncodeFrame(pendingPcm.AsSpan(0, PcmBytesPerFrame));
                pendingPcmCount -= PcmBytesPerFrame;
                pendingPcm.AsSpan(PcmBytesPerFrame, pendingPcmCount).CopyTo(pendingPcm);
            }
        }
    }

    private void OnRecordingStopped(object? sender, StoppedEventArgs eventArgs)
    {
        if (eventArgs.Exception is not null)
        {
            error = eventArgs.Exception.Message;
        }
    }

    private void EncodeFrame(ReadOnlySpan<byte> pcmBytes)
    {
        Span<short> pcm = stackalloc short[VoiceProtocol.SamplesPerFrame];
        for (var index = 0; index < pcm.Length; index++)
        {
            var sample = BitConverter.ToInt16(pcmBytes.Slice(index * sizeof(short), sizeof(short)));
            var gainedSample = sample * (config?.InputGain ?? 100) / 100;
            pcm[index] = (short)Math.Clamp(gainedSample, short.MinValue, short.MaxValue);
        }

        Span<byte> encoded = stackalloc byte[VoiceProtocol.MaximumOpusPacketBytes];
        var encodedLength = encoder.Encode(
            pcm,
            VoiceProtocol.SamplesPerFrame,
            encoded,
            encoded.Length);
        AudioFrameReady?.Invoke(encoded[..encodedLength].ToArray());
    }

    private void UpdateInputLevel(ReadOnlySpan<byte> pcmBytes)
    {
        var peak = 0;
        for (var offset = 0; offset + 1 < pcmBytes.Length; offset += sizeof(short))
        {
            var sample = Math.Abs((int)BitConverter.ToInt16(pcmBytes.Slice(offset, sizeof(short))));
            peak = Math.Max(peak, sample);
        }

        var gainedPeak = peak * (config?.InputGain ?? 100) / 100;
        Volatile.Write(ref inputLevel, Math.Clamp(gainedPeak * 100 / short.MaxValue, 0, 100));
    }

    private bool ShouldTransmit()
    {
        if (config is not { CanSpeak: true, Muted: false } || IsMicrophoneTestActive())
        {
            return false;
        }

        return config.VoiceActivationEnabled
            ? Stopwatch.GetTimestamp() <= voiceActivationUntilTimestamp
            : pushToTalkPressed;
    }

    private void UpdateVoiceActivation()
    {
        if (config is not { VoiceActivationEnabled: true } ||
            InputLevel < config.VoiceActivationThreshold)
        {
            return;
        }

        voiceActivationUntilTimestamp = Stopwatch.GetTimestamp() +
            VoiceActivationHoldMilliseconds * Stopwatch.Frequency / 1000;
    }

    private bool IsMicrophoneTestActive()
    {
        return Stopwatch.GetTimestamp() <= microphoneTestUntilTimestamp;
    }

    private void StartMicrophoneTest()
    {
        microphoneMonitor?.ClearBuffer();
        microphoneTestUntilTimestamp = Stopwatch.GetTimestamp() +
            MicrophoneTestSeconds * Stopwatch.Frequency;
    }

    private void UpdateMicrophoneMonitorVolume()
    {
        if (microphoneMonitorVolume is null || config is null)
        {
            return;
        }

        microphoneMonitorVolume.Volume = Math.Clamp(
            config.InputGain / 100f * config.OutputVolume / 100f,
            0,
            1);
    }

    private void PlayOutputTest()
    {
        var signal = new SignalGenerator(VoiceProtocol.SampleRate, VoiceProtocol.Channels)
        {
            Frequency = OutputTestFrequency,
            Gain = OutputTestGain,
            Type = SignalGeneratorType.Sin,
        };
        var duration = new OffsetSampleProvider(signal)
        {
            Take = TimeSpan.FromMilliseconds(700),
        };
        var volume = new VolumeSampleProvider(duration)
        {
            Volume = Math.Clamp((config?.OutputVolume ?? 100) / 100f, 0, 1),
        };
        mixer!.AddMixerInput(volume);
    }

    private SpeakerPlayback CreateSpeaker(Guid speakerId)
    {
        if (mixer is null)
        {
            EnsureOutput(config?.OutputDeviceId ?? string.Empty);
        }

        var speaker = new SpeakerPlayback();
        speakers[speakerId] = speaker;
        mixer!.AddMixerInput(speaker.VolumeProvider);
        UpdateSpeakerVolume(speakerId, speaker);
        return speaker;
    }

    private void UpdateSpeakerVolumes()
    {
        foreach (var speaker in speakers)
        {
            UpdateSpeakerVolume(speaker.Key, speaker.Value);
        }
    }

    private void UpdateSpeakerVolume(Guid speakerId, SpeakerPlayback speaker)
    {
        if (config is null)
        {
            speaker.VolumeProvider.Volume = 0;
            return;
        }

        var peerId = speakerId.ToString("N");
        var peerVolume = config.PeerVolumes
            .FirstOrDefault(item => item.SessionId == peerId)?.Volume ?? 100;
        speaker.VolumeProvider.Volume = config.Deafened || config.MutedPeers.Contains(peerId)
            ? 0
            : Math.Clamp(
                config.OutputVolume / 100f * peerVolume / 100f * speaker.SpatialVolume,
                0,
                1);
    }

    private string ResolveInputDevice(string requestedDevice)
    {
        if (InputDevices.Any(device => device.Id == requestedDevice))
        {
            return requestedDevice;
        }

        return InputDevices.FirstOrDefault(device => device.Default)?.Id ?? string.Empty;
    }

    private string ResolveOutputDevice(string requestedDevice)
    {
        if (OutputDevices.Any(device => device.Id == requestedDevice))
        {
            return requestedDevice;
        }

        return OutputDevices.First(device => device.Default).Id;
    }

    private static bool TryParseDeviceNumber(string value, string prefix, out int deviceNumber)
    {
        deviceNumber = 0;
        return value.StartsWith(prefix, StringComparison.Ordinal) &&
            int.TryParse(value.AsSpan(prefix.Length), out deviceNumber);
    }

    private static List<VoiceDevice> EnumerateInputDevices()
    {
        var devices = new List<VoiceDevice>();
        for (var index = 0; index < WaveIn.DeviceCount; index++)
        {
            var capabilities = WaveIn.GetCapabilities(index);
            devices.Add(new VoiceDevice
            {
                Id = $"wavein:{index}",
                Name = capabilities.ProductName,
                Default = index == 0,
            });
        }

        return devices;
    }

    private static List<VoiceDevice> EnumerateOutputDevices()
    {
        var devices = new List<VoiceDevice>
        {
            new() { Id = "waveout:-1", Name = "Системное устройство", Default = true },
        };
        for (var index = 0; index < WaveOut.DeviceCount; index++)
        {
            var capabilities = WaveOut.GetCapabilities(index);
            devices.Add(new VoiceDevice
            {
                Id = $"waveout:{index}",
                Name = capabilities.ProductName,
            });
        }

        return devices;
    }

    private sealed class SpeakerPlayback
    {
        private readonly IOpusDecoder decoder = OpusCodecFactory.CreateDecoder(
            VoiceProtocol.SampleRate,
            VoiceProtocol.Channels);
        private readonly BufferedWaveProvider buffer = new(
            new WaveFormat(VoiceProtocol.SampleRate, 16, VoiceProtocol.Channels))
        {
            BufferDuration = TimeSpan.FromMilliseconds(240),
            DiscardOnBufferOverflow = true,
        };

        public SpeakerPlayback()
        {
            VolumeProvider = new VolumeSampleProvider(buffer.ToSampleProvider());
        }

        public VolumeSampleProvider VolumeProvider { get; }
        public float SpatialVolume { get; set; } = 1;

        public void DecodeAndBuffer(ReadOnlySpan<byte> opusPacket)
        {
            Span<short> pcm = stackalloc short[VoiceProtocol.SamplesPerFrame];
            var decodedSamples = decoder.Decode(
                opusPacket,
                pcm,
                VoiceProtocol.SamplesPerFrame,
                false);
            var bytes = new byte[decodedSamples * sizeof(short)];
            for (var index = 0; index < decodedSamples; index++)
            {
                BitConverter.TryWriteBytes(bytes.AsSpan(index * sizeof(short), sizeof(short)), pcm[index]);
            }

            buffer.AddSamples(bytes, 0, bytes.Length);
        }
    }
}
