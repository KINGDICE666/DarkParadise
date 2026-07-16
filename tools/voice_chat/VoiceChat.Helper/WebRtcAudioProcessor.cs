using NAudio.Wave;
using SoundFlow.Extensions.WebRtc.Apm;
using VoiceChat.Protocol;

namespace VoiceChat.Helper;

public delegate void RenderAnalyzer(ReadOnlySpan<float> samples);

public sealed class WebRtcAudioProcessor : IDisposable
{
    private const int FrameSamples = 480;
    private readonly object gate = new();
    private readonly AudioProcessingModule module;
    private readonly StreamConfig streamConfig;
    private readonly float[][] captureInput = [new float[FrameSamples]];
    private readonly float[][] captureOutput = [new float[FrameSamples]];
    private readonly float[][] renderInput = [new float[FrameSamples]];
    private readonly float[] pendingRender = new float[FrameSamples];
    private int pendingRenderCount;
    private int noiseSuppressionLevel = -1;

    public WebRtcAudioProcessor()
    {
        module = new AudioProcessingModule();
        streamConfig = new StreamConfig(48000, 1);
        EnsureSuccess(module.Initialize(), "initialize");
        SetNoiseSuppressionLevel(VoiceProtocol.DefaultNoiseSuppressionLevel);
        module.SetStreamDelayMs(60);
    }

    public void SetNoiseSuppressionLevel(int value)
    {
        lock (gate)
        {
            var level = Math.Clamp(
                value,
                VoiceProtocol.MinimumNoiseSuppressionLevel,
                VoiceProtocol.MaximumNoiseSuppressionLevel);
            if (level == noiseSuppressionLevel)
            {
                return;
            }

            using var config = new ApmConfig();
            config.SetEchoCanceller(true, false);
            config.SetNoiseSuppression(
                level > VoiceProtocol.MinimumNoiseSuppressionLevel,
                (NoiseSuppressionLevel)Math.Max(0, level - 1));
            config.SetGainController1(true, GainControlMode.AdaptiveDigital, -3, 9, true);
            config.SetGainController2(false);
            config.SetHighPassFilter(true);
            config.SetPreAmplifier(false, 1);
            config.SetPipeline(48000, false, false, DownmixMethod.AverageChannels);
            EnsureSuccess(module.ApplyConfig(config), "configure");
            noiseSuppressionLevel = level;
        }
    }

    public void ProcessCapture(Span<short> samples)
    {
        if (samples.Length % FrameSamples != 0)
        {
            throw new ArgumentException("WebRTC APM requires 10 ms capture frames.", nameof(samples));
        }

        lock (gate)
        {
            for (var offset = 0; offset < samples.Length; offset += FrameSamples)
            {
                for (var index = 0; index < FrameSamples; index++)
                {
                    captureInput[0][index] = samples[offset + index] / 32768f;
                }

                EnsureSuccess(
                    module.ProcessStream(captureInput, streamConfig, streamConfig, captureOutput),
                    "process capture");
                for (var index = 0; index < FrameSamples; index++)
                {
                    samples[offset + index] = (short)Math.Clamp(
                        Math.Round(captureOutput[0][index] * 32768),
                        short.MinValue,
                        short.MaxValue);
                }
            }
        }
    }

    public void AnalyzeRender(ReadOnlySpan<float> samples)
    {
        lock (gate)
        {
            var offset = 0;
            while (offset < samples.Length)
            {
                var copied = Math.Min(FrameSamples - pendingRenderCount, samples.Length - offset);
                samples.Slice(offset, copied).CopyTo(pendingRender.AsSpan(pendingRenderCount));
                pendingRenderCount += copied;
                offset += copied;
                if (pendingRenderCount < FrameSamples)
                {
                    continue;
                }

                pendingRender.CopyTo(renderInput[0], 0);
                EnsureSuccess(module.AnalyzeReverseStream(renderInput, streamConfig), "analyze render");
                pendingRenderCount = 0;
            }
        }
    }

    public void Dispose()
    {
        lock (gate)
        {
            streamConfig.Dispose();
            module.Dispose();
        }
    }

    private static void EnsureSuccess(ApmError result, string operation)
    {
        if ((int)result != 0)
        {
            throw new InvalidOperationException($"WebRTC APM failed to {operation}: {result}.");
        }
    }
}

public sealed class RenderReferenceSampleProvider : ISampleProvider
{
    private readonly ISampleProvider source;
    private readonly RenderAnalyzer analyze;

    public RenderReferenceSampleProvider(
        ISampleProvider source,
        RenderAnalyzer analyze)
    {
        this.source = source;
        this.analyze = analyze;
    }

    public WaveFormat WaveFormat => source.WaveFormat;

    public int Read(float[] buffer, int offset, int count)
    {
        var read = source.Read(buffer, offset, count);
        analyze(buffer.AsSpan(offset, read));
        return read;
    }
}
