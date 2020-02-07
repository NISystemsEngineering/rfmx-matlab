// Extension methods for simplifying datatype conversion between .NET and MATLAB

using System;

namespace NationalInstruments.ModularInstruments.NIRfsgPlayback
{
    public static class NIRfsgPlaybackExtensions
    {
        public static int DownloadUserWaveform(IntPtr rfsgSession, string waveformName, double[] real, double[] imaginary, double sampleInterval, bool burstPresent)
        {
            var iq = ComplexDouble.ComposeArray(real, imaginary);
            var iqWfm = ComplexWaveform<ComplexDouble>.FromArray1D(iq);
            iqWfm.PrecisionTiming = PrecisionWaveformTiming.CreateWithRegularInterval(new PrecisionTimeSpan(sampleInterval));
            return NIRfsgPlayback.DownloadUserWaveform(rfsgSession, waveformName, iqWfm, burstPresent);
        }

        public static int ReadWaveformFromFileComplex(string filePath, out double[] real, out double[] imag, out double sampleInterval)
        {
            ComplexWaveform<ComplexDouble> outputWaveform = null;
            int result = NIRfsgPlayback.ReadWaveformFromFileComplex(filePath, ref outputWaveform);
            real = outputWaveform.GetRealDataArray(false);
            imag = outputWaveform.GetImaginaryDataArray(false);
            sampleInterval = outputWaveform.PrecisionTiming.SampleInterval.TotalSeconds;
            return result;
        }
    }
}
