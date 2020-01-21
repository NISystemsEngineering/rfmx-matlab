clear;
clc;

% Load assemblies and import classes relevant to RF Generator & Analyzer %
NET.addAssembly('Ivi.Driver');
NET.addAssembly('NationalInstruments.Common');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsg.Fx40');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsgPlayback.Fx40');
NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
NET.addAssembly('NationalInstruments.RFmx.SpecAnMX.Fx40');

import NationalInstruments.*
import NationalInstruments.ModularInstruments.NIRfsg.*
import NationalInstruments.ModularInstruments.NIRfsgPlayback.*
import NationalInstruments.RFmx.InstrMX.*;
import NationalInstruments.RFmx.SpecAnMX.*;

% Initialize Common Parameters %
centerFrequency = 1.950e9;
vstResourceName = 'VST_01';

% Initialize RF Generator Parameters %
dutAverageInputPower = -10.0;   %dBm
rfsgExternalAttenuation = 0.0;  %dBm
rfMarkerExport = RfsgMarkerEventExportedOutputTerminal.PxiTriggerLine0;
rfWaveformName = 'RFWfm';
rfScript = 'script RFSscript repeat forever generate RFWfm marker1(0) end repeat end script';
rfWaveformPath = 'C:\\p4\\rfdrivers-matlab\\DotNET\\Examples\\Support\\LTE_FDD_PUSCH_10MHz_QPSK.tdms';
rfWaveformIArray = [];
rfWaveformQArray = [];
rfWaveformSampleRate = 0;
rfWaveformIdleDurationPresent = false;

% Initialize RF Analyzer Parameters %
rfAnalyzerReferenceLevel = 10.0;    %dB
rfAnalyzerExternalAttenuation = 0;  %dB
rfAnalyzerTriggerEnabled = false;   
rfAnalyzerTriggerType = RFmxSpecAnMXTriggerType.DigitalEdge;
rfAnalyzerTriggerDelay = 0.0;       %s
rfAnalyzerDigitalTriggerEdgeSource = RFmxInstrMXConstants.PxiTriggerLine0;

iqMeasurementInterval = 100.0e-6;   %s
iqSampleRate = 0;               %Hz, will be overriden by actual waveform sampling rate

try
% Initialize Hardware Sessions %
rfGenerator = NIRfsg(vstResourceName, false, false, '');
instrSession = RFmxInstrMX(vstResourceName, '');
specAn = RFmxSpecAnMXExtension.GetSpecAnSignalConfiguration(instrSession);

% Configure RF Generator %
rfGenerator.FrequencyReference.Configure(RfsgFrequencyReferenceSource.PxiClock, 10e6);

markerEvent1 = Item(rfGenerator.DeviceEvents.MarkerEvents, 1);
markerEvent1.ExportedOutputTerminal = rfMarkerExport;
rfGenerator.Arb.GenerationMode = RfsgWaveformGenerationMode.Script;
rfGenerator.RF.PowerLevelType = RfsgRFPowerLevelType.PeakPower;
rfGenerator.RF.Configure(centerFrequency, dutAverageInputPower);
rfGenerator.RF.ExternalGain = -rfsgExternalAttenuation;

% Download RF Waveform %
% We will load a TDMS file to memory, extract the I & Q arrays and sample
% rate, and input those manually. This will be similar to leveraging custom
% waveforms if no TDMS waveforms are available or desired
[~, referenceWaveform] = NIRfsgPlayback.ReadWaveformFromFileComplex(rfWaveformPath, []);
rfWaveformSampleRate = 1 / (referenceWaveform.PrecisionTiming.SampleInterval.FractionalSeconds);
[refIdata, refQdata] = ComplexSingle.DecomposeArray(referenceWaveform.GetRawData());

% create a waveform compatible with the RFSGPlayback Library from
% user-defined I, Q arrays and SampleRate
ComplexSingleArray = ComplexSingle.ComposeArray(refIdata, refQdata);
convertedReferenceWaveform = NET.createGeneric('NationalInstruments.ComplexWaveform', {'NationalInstruments.ComplexSingle'}, 0, ComplexSingleArray.Length);
convertedReferenceWaveform.Append(ComplexSingleArray);
convertedReferenceWaveform.PrecisionTiming = PrecisionWaveformTiming.CreateWithRegularInterval(PrecisionTimeSpan(1 / rfWaveformSampleRate));

rfGeneratorHandle = rfGenerator.DangerousGetInstrumentHandle();
NIRfsgPlayback.DownloadUserWaveform(rfGeneratorHandle, rfWaveformName, convertedReferenceWaveform, rfWaveformIdleDurationPresent);
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfGeneratorHandle, rfScript);

[~, rfWaveformIQRate] = NIRfsgPlayback.RetrieveWaveformSampleRate(rfGeneratorHandle, rfWaveformName);
[~, rfWaveformPapr] = NIRfsgPlayback.RetrieveWaveformPapr(rfGeneratorHandle, rfWaveformName);
fprintf('Pre DPD PAPR(dB) = %f\n', rfWaveformPapr);

% Configure Analyzer %
instrSession.ConfigureFrequencyReference('', RFmxInstrMXConstants.PxiClock, 10e6);
specAn.ConfigureRF('', centerFrequency, rfAnalyzerReferenceLevel, rfAnalyzerExternalAttenuation);
specAn.ConfigureDigitalEdgeTrigger('', rfAnalyzerDigitalTriggerEdgeSource, RFmxSpecAnMXDigitalEdgeTriggerEdge.Rising, rfAnalyzerTriggerDelay, rfAnalyzerTriggerEnabled);

% Configure IQ Acquisition, Sampling rate will be RF waveform's%
iqSampleRate = rfWaveformIQRate;
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.IQ, false);
specAn.IQ.Configuration.ConfigureAcquisition('', iqSampleRate, 1, iqMeasurementInterval, 0);

% Initiate Generation and Acquire IQ %
rfGenerator.Initiate();
specAn.Initiate('', '');
[~, IQData] = specAn.IQ.Results.FetchData('', 10.0, 0, -1, []);

% Abort RF Generation and prepare for DPD Waveform %
rfGenerator.Abort();
NationalInstruments.ModularInstruments.NIRfsgPlayback.NIRfsgPlayback.ClearWaveform(rfGeneratorHandle, rfWaveformName);

% Assume a DPD waveform is processed offline, refer to "Download RF Waveform
% Waveform" section for formatting it into a ComplexWaveform<ComplexSingle[]>
% ComplexWaveform<ComplexSingle[]> data type
dpdWaveform = referenceWaveform;

NIRfsgPlayback.DownloadUserWaveform(rfGeneratorHandle, rfWaveformName, dpdWaveform, rfWaveformIdleDurationPresent);
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfGeneratorHandle, rfScript);

[~, dpdWaveformPapr] = NIRfsgPlayback.RetrieveWaveformPapr(rfGeneratorHandle, rfWaveformName);
fprintf('Post DPD PAPR(dB) = %f\n', dpdWaveformPapr);

% Initiate DPD Waveform Generation for further measurements %
rfGenerator.Initiate();
input('Generating DPD waveform. Press enter to stop.\n');

catch err    
    % Close Hardware Sessions %
    rfGenerator.Abort();
    rfGenerator.RF.OutputEnabled = false;
    rfGenerator.Utility.Commit();
    rfGenerator.Close();

    specAn.Dispose();
    instrSession.Close();
    
    error(err.message);
end
try
    specAn.Dispose();
    instrSession.Close();
    
    rfGenerator.Abort();
    rfGenerator.RF.OutputEnabled = false;
    rfGenerator.Utility.Commit();
    rfGenerator.Close();
catch err
 end