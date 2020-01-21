clear;
clc;

%% Load assemblies and import classes relevant to RF Generator & Analyzer %
NET.addAssembly('Ivi.Driver');
NET.addAssembly('NationalInstruments.Common');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsg.Fx40');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsgPlayback.Fx40');
NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
NET.addAssembly('NationalInstruments.RFmx.SpecAnMX.Fx40');

import NationalInstruments.*;
import NationalInstruments.ModularInstruments.NIRfsg.*;
import NationalInstruments.ModularInstruments.NIRfsgPlayback.*;
import NationalInstruments.RFmx.InstrMX.*;
import NationalInstruments.RFmx.SpecAnMX.*;

NET.addAssembly('NationalInstruments.RFmx.NRMX.Fx40');
import NationalInstruments.RFmx.NRMX.*;

NET.addAssembly('NationalInstruments.ModularInstruments.Common');
NET.addAssembly('NationalInstruments.ModularInstruments.TClock.Fx40');
import NationalInstruments.ModularInstruments.*
import NationalInstruments.ModularInstruments.SystemServices.TimingServices.*;

%% Parameters Definition
vstAlias = 'PXIe-5840';
envGenAlias = 'PXIe-5820';
etEnabled = true;

% RF Generator Parameters %
centerFrequency = 4e9;
dutAverageInputPower = 14.0;   %dBm
rfsgExternalAttenuation = 0.0;  %dBm
rfMarkerExport = RfsgMarkerEventExportedOutputTerminal.PxiTriggerLine0;
rfLOOffsetMode = NIRfsgPlaybackLOOffsetMode.Auto;
rfWaveformName = 'preDPDWaveform';
rfScript = 'script preDPDRFScript repeat forever generate preDPDWaveform marker1(0) end repeat end script';
rfDPDWaveformName = 'postDPDWaveform';
rfDPDScript = 'script postDPDRFScript repeat forever generate postDPDWaveform marker1(0) end repeat end script';

rfWaveformFromCustomIQ = false;
rfWaveformPath = 'C:\\p4\\Sales\\users\\SeanMoore\\rfdrivers-matlab\\DotNET\\Examples\\Support\\NR_1x50MHz_30kHzSCS_64QAM_DFT-s-OFDM_Full_4xOS.tdms';
rfWaveformIArray = [];                      %gets defined during custom IQ waveform loading
rfWaveformQArray = [];                      %gets defined during custom IQ waveform loading
rfWaveformSampleRate = 0;                   %gets defined during custom IQ waveform loading
rfWaveformIdleDurationPresent = false;      %gets defined during custom IQ waveform loading

% NR Signal Parameters %
componentCarrierBandwidth = 50e6;                                      
cellID = 0;
subcarrierSpacing = 30e3;                                             
band = 78;

puschTransformPrecodingEnabled = RFmxNRMXPuschTransformPrecodingEnabled.True;
puschNumberOfRBClusters = 1;
puschRBOffset = 0;
puschNumberOfRBs = -1;
puschModulationType = RFmxNRMXPuschModulationType.Qam64;
puschSlotAllocation = '0-Last';
puschSymbolAllocation = '0-Last';

% Envelope Generator Parameters %
envMarker1ExportTerminal = RfsgMarkerEventExportedOutputTerminal.PxiTriggerLine1;
envWaveformName = 'preDPDEnvelope';

envScript = 'script preDPDEnvelopeScript repeat forever generate preDPDEnvelope marker1(0) end repeat end script';
envScriptName = 'preDPDEnvelopeScript';
envDPDWaveformName = 'postDPDEnvelope';
envDPDScript = 'script postDPDEnvelopeScript repeat forever generate postDPDEnvelope marker1(0) end repeat end script';
envDPDScriptName = 'postDPDEnvelopeScript';

envCommonModeOffset = 0;
envLoadImpedance = 100;
envGain = 0.5;

% Synchronization Parameters %
desiredRFDelay = 0;     %in seconds
saAmpmDelaySweepMeasurementInterval = 50e-6;
saDelaySweepStart = -100;   %in ns!
saDelaySweepStop = 100;     %in ns!
saDelaySweepStep = 5;       %in ns!

% SA Parameters %
rfAnalyzerReferenceLevel = 30.0;    %dB, will be overriden by autolevel routine later
rfAnalyzerExternalAttenuation = 0;  %dB
rfAnalyzerTriggerEnabled = true;   
rfAnalyzerTriggerType = RFmxSpecAnMXTriggerType.DigitalEdge;
rfAnalyzerTriggerDelay = 0.0;       %s
rfAnalyzerDigitalTriggerEdgeSource = RFmxInstrMXConstants.PxiTriggerLine0;
timeout = 10;

saAutoLevelBW = 100e6; %Hz
saAutoLevelTime = 10e-3; %s

saIQAcquisitionTime = 0.001;
saIQSampleRate = 0;          %Hz, will be overriden by actual RFSG waveform sample rate
saIQRecordToFetch = 0;
saIQSamplesToRead = -1;
saIQTimeout = 3;

saSpectrumSpan = 200e6;
saSpectrumRBWAuto = RFmxSpecAnMXSpectrumRbwAutoBandwidth.True;
saSpectrumRBWType = RFmxSpecAnMXSpectrumRbwFilterType.Gaussian;
saSpectrumRBW = 1000e3;
saSpectrumSweepTimeAuto = RFmxSpecAnMXSpectrumSweepTimeAuto.True;
saSpectrumSweepTime = 2e-3;

saAMPMMeasurementInterval = 0.0001;

saDPDModel = RFmxSpecAnMXDpdModel.MemoryPolynomial;
saDPDMPMOrder = 5;
saDPDMOMDepth = 1;
saDPDMeasurementInterval = 0.0001;

% NR ModAcc Parameters %
saNRModAccAveragingEnabled = RFmxNRMXModAccAveragingEnabled.False;
saNRModAccAveragingCount = 10;
saNRModAccMeasurementLengthUnit = RFmxNRMXModAccMeasurementLengthUnit.Slot;
saNRModAccMeasurementOffset = 0;
saNRModAccMeasurementLength = 1;

% NR ACP Parameters
saNRACPSweepTimeAuto = RFmxNRMXAcpSweepTimeAuto.False;
saNRACPSweepTime = 0.1e-3;
saNRACPRBWAuto = RFmxNRMXAcpRbwAutoBandwidth.False;
saNRACPRBWType = RFmxNRMXAcpRbwFilterType.Gaussian;
saNRACPRBW = 1000e3;
saNRACPNumberNROffsets = 3;

%% Code Execution
try
%% Initialize Sessions %
rfGenerator = NIRfsg(vstAlias, false, false, '');
rfGenerator.FrequencyReference.Configure(RfsgFrequencyReferenceSource.PxiClock, 10e6);
rfGeneratorHandle = rfGenerator.DangerousGetInstrumentHandle();

if etEnabled
    envSession = NIRfsg(envGenAlias, false, false, '');
    envSession.FrequencyReference.Configure(RfsgFrequencyReferenceSource.PxiClock, 10e6);
    envGeneratorHandle = envSession.DangerousGetInstrumentHandle();

    syncDevices = NET.createArray('NationalInstruments.ModularInstruments.ITClockSynchronizableDevice', 2);
    syncDevices(1) = DeviceToSynchronize(rfGenerator).Device;
    syncDevices(2) = DeviceToSynchronize(envSession).Device;

    synchronizer = TClock(syncDevices);
    synchronizer.ConfigureForHomogeneousTriggers();
end

instrSession = RFmxInstrMX(vstAlias, '');
instrSession.ConfigureFrequencyReference('', RFmxInstrMXConstants.PxiClock, 10e6);
specAn = RFmxSpecAnMXExtension.GetSpecAnSignalConfiguration(instrSession);
nr = RFmxNRMXExtension.GetNRSignalConfiguration(instrSession);

%% Configure RF and Envelope Generators %
markerEvent1 = Item(rfGenerator.DeviceEvents.MarkerEvents, 1);
markerEvent1.ExportedOutputTerminal = rfMarkerExport;
rfGenerator.Arb.GenerationMode = RfsgWaveformGenerationMode.Script;
rfGenerator.RF.PowerLevelType = RfsgRFPowerLevelType.PeakPower;
rfGenerator.RF.Configure(centerFrequency, dutAverageInputPower);
rfGenerator.RF.ExternalGain = -rfsgExternalAttenuation;

if etEnabled
    envSession.Arb.GenerationMode = RfsgWaveformGenerationMode.Script;
    markerEvent1 = Item(envSession.DeviceEvents.MarkerEvents, 1);
    markerEvent1.ExportedOutputTerminal = envMarker1ExportTerminal;

    iqOutPort = Item(envSession.IQOutPort, '');
    iqOutPort.TerminalConfiguration = RfsgTerminalConfiguration.Differential;
    iqOutPort.CommonModeOffset = envCommonModeOffset;
    iqOutPort.LoadImpedance = envLoadImpedance;
    iqOutPort.Level = 2 * envGain;
end

%% Download RF and Envelope Waveforms %
if rfWaveformFromCustomIQ
    %currently reading from TDMS file and converting to IQ arrays. Replace this code with your custom IQ data source
    [~, referenceWaveform] = NIRfsgPlayback.ReadWaveformFromFileComplex(rfWaveformPath, []);
    rfWaveformSampleRate = 1 / (referenceWaveform.PrecisionTiming.SampleInterval.FractionalSeconds);
    [rfWaveformIArray, rfWaveformQArray] = ComplexSingle.DecomposeArray(referenceWaveform.GetRawData());

    %if the waveform is bursted, change IdleDurationPresent to true. This will allow the driver to calculate
    %PAPR appropriately when loading the custom waveform to hardware
    rfWaveformIdleDurationPresent = false;

    %now that we have a sample rate, I & Q arrays, let's convert to NI's ComplexWaveform data type and load to RFSG
    ComplexSingleArray = ComplexSingle.ComposeArray(refIdata, refQdata);
    convertedReferenceWaveform = NET.createGeneric('NationalInstruments.ComplexWaveform', {'NationalInstruments.ComplexSingle'}, 0, ComplexSingleArray.Length);
    convertedReferenceWaveform.Append(ComplexSingleArray);
    convertedReferenceWaveform.PrecisionTiming = PrecisionWaveformTiming.CreateWithRegularInterval(PrecisionTimeSpan(1 / rfWaveformSampleRate));

    NIRfsgPlayback.DownloadUserWaveform(rfGeneratorHandle, rfWaveformName, convertedReferenceWaveform, rfWaveformIdleDurationPresent);

else
    NIRfsgPlayback.ReadAndDownloadWaveformFromFile(rfGeneratorHandle, rfWaveformPath, rfWaveformName);
    [~, convertedReferenceWaveform] = NIRfsgPlayback.ReadWaveformFromFileComplex(rfWaveformPath, []);
end
NIRfsgPlayback.StoreWaveformLOOffsetMode(rfGeneratorHandle, rfWaveformName, rfLOOffsetMode);
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfGeneratorHandle, rfScript);
[~, rfWaveformIQRate] = NIRfsgPlayback.RetrieveWaveformSampleRate(rfGeneratorHandle, rfWaveformName);
[~, rfWaveformSize] = NIRfsgPlayback.RetrieveWaveformSize(rfGeneratorHandle, rfWaveformName);
[~, rfWaveformPapr] = NIRfsgPlayback.RetrieveWaveformPapr(rfGeneratorHandle, rfWaveformName);
rfWaveformIdleDurationPresent = false;
fprintf('Pre DPD PAPR(dB) = %f\n', rfWaveformPapr);

if etEnabled
    envSession.Arb.IQRate = rfWaveformIQRate;
    envSession.Arb.SignalBandwidth = 0.8*rfWaveformIQRate;

    %We are simply creating temporary 1-0 waveform for the envelope for now. Add your code to shape the envelope based on RF waveform here
    iEnvData = ones(1, rfWaveformSize);
    qEnvData = zeros(1, rfWaveformSize);
    envSession.Arb.WriteWaveform(envWaveformName, iEnvData, qEnvData);
    envSession.Arb.Scripting.WriteScript(envScript);
    envSession.Arb.Scripting.SelectedScriptName = envScriptName;
    envSession.Utility.Commit();
end

%% Configure RF Analyzer and Measurements %
% Note that in this example, ReferenceLevel will be determined automatically using an AutoLevel Routine later
% SpecAn Measurements (doing DPD, AMPM, IQ and Spectrum measurements)
specAn.ConfigureRF('', centerFrequency, rfAnalyzerReferenceLevel, rfAnalyzerExternalAttenuation);
specAn.ConfigureDigitalEdgeTrigger('', rfAnalyzerDigitalTriggerEdgeSource, RFmxSpecAnMXDigitalEdgeTriggerEdge.Rising, rfAnalyzerTriggerDelay, rfAnalyzerTriggerEnabled);

% IQ (acquisition sample rate is the reference waveform's sample rate)
saIQSampleRate = rfWaveformIQRate;
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.IQ, true);
specAn.IQ.Configuration.ConfigureAcquisition('', saIQSampleRate, 1, saIQAcquisitionTime, 0);

if rfWaveformIdleDurationPresent
    saAMPMIdleDurationPresent = RFmxSpecAnMXAmpmReferenceWaveformIdleDurationPresent.True;
    saDPDIdleDurationPresent = RFmxSpecAnMXDpdReferenceWaveformIdleDurationPresent.True;
    saDPDApplyDPDIdleDurationPresent = RFmxSpecAnMXDpdApplyDpdIdleDurationPresent.True;
else
    saAMPMIdleDurationPresent = RFmxSpecAnMXAmpmReferenceWaveformIdleDurationPresent.False;
    saDPDIdleDurationPresent = RFmxSpecAnMXDpdReferenceWaveformIdleDurationPresent.False;
    saDPDApplyDPDIdleDurationPresent = RFmxSpecAnMXDpdApplyDpdIdleDurationPresent.False;
end

% Spectrum
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Spectrum, true);
specAn.Spectrum.Configuration.ConfigureSpan('', saSpectrumSpan);
specAn.Spectrum.Configuration.ConfigureRbwFilter('', saSpectrumRBWAuto, saSpectrumRBW, saSpectrumRBWType);
specAn.Spectrum.Configuration.ConfigureSweepTime('', saSpectrumSweepTimeAuto, saSpectrumSweepTime);

% AMPM
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Ampm, true);
specAn.Ampm.Configuration.ConfigureDutAverageInputPower('', dutAverageInputPower);
specAn.Ampm.Configuration.ConfigureReferenceWaveform('', convertedReferenceWaveform, saAMPMIdleDurationPresent, RFmxSpecAnMXAmpmSignalType.Modulated);
specAn.Ampm.Configuration.ConfigureMeasurementInterval('', saAMPMMeasurementInterval);

% DPD (this example will run with RFmx DPD but the code can be changed for custom DPD)
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Dpd, true);
specAn.Dpd.Configuration.ConfigureDutAverageInputPower('', dutAverageInputPower);
specAn.Dpd.Configuration.ConfigureReferenceWaveform('', convertedReferenceWaveform, saDPDIdleDurationPresent, RFmxSpecAnMXDpdSignalType.Modulated);
specAn.Dpd.Configuration.ConfigureMeasurementInterval('', saDPDMeasurementInterval);
specAn.Dpd.Configuration.ConfigureDpdModel('', saDPDModel);
specAn.Dpd.Configuration.ConfigureMemoryPolynomial('', saDPDMPMOrder, saDPDMOMDepth);

% NR Measurements (doing ModAcc and single carrier ACP)
nr.ConfigureRF('', centerFrequency, rfAnalyzerReferenceLevel, rfAnalyzerExternalAttenuation);
nr.ConfigureDigitalEdgeTrigger('', rfAnalyzerDigitalTriggerEdgeSource, RFmxNRMXDigitalEdgeTriggerEdge.Rising, rfAnalyzerTriggerDelay, rfAnalyzerTriggerEnabled);

% Signal Parameters
nr.ComponentCarrier.SetBandwidth('', componentCarrierBandwidth);
nr.ComponentCarrier.SetCellID('', cellID);
nr.ComponentCarrier.SetBandwidthPartSubcarrierSpacing('', subcarrierSpacing);
nr.ComponentCarrier.SetPuschTransformPrecodingEnabled('', puschTransformPrecodingEnabled);
nr.ComponentCarrier.SetPuschModulationType('', puschModulationType);
nr.ComponentCarrier.SetPuschSlotAllocation('', puschSlotAllocation);
nr.ComponentCarrier.SetPuschSymbolAllocation('', puschSymbolAllocation);

subblockString = RFmxNRMX.BuildSubblockString('', 0);
carrierString = RFmxNRMX.BuildCarrierString(subblockString, 0);
puschClusterString = RFmxNRMX.BuildPuschClusterString(carrierString, 0);
nr.ComponentCarrier.SetPuschResourceBlockOffset(puschClusterString, puschRBOffset);
nr.ComponentCarrier.SetPuschNumberOfResourceBlocks(puschClusterString, puschNumberOfRBs);

% ModAcc
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.ModAcc, true);
nr.ModAcc.Configuration.SetAveragingEnabled('', saNRModAccAveragingEnabled);
nr.ModAcc.Configuration.SetAveragingCount('', saNRModAccAveragingCount);
nr.ModAcc.Configuration.SetMeasurementOffset('', saNRModAccMeasurementOffset);
nr.ModAcc.Configuration.SetMeasurementLength('', saNRModAccMeasurementLength);
nr.ModAcc.Configuration.SetMeasurementLengthUnit('', saNRModAccMeasurementLengthUnit);

% ACP
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.Acp, true);
nr.Acp.Configuration.ConfigureSweepTime('', saNRACPSweepTimeAuto, saNRACPSweepTime);
nr.Acp.Configuration.ConfigureRbwFilter('', saNRACPRBWAuto, saNRACPRBW, saNRACPRBWType);
nr.Acp.Configuration.ConfigureNumberOfNROffsets('', saNRACPNumberNROffsets);

%% Initiate Synchronized Generation 
if etEnabled
    syncDevice0 = Item(synchronizer.DevicesToSynchronize, 0);
    syncDevice0.SampleClockDelay = -1.5e-6; 	%offset by -1.5us to allow negative delays
    rfGenerator.Arb.RelativeDelay = (desiredRFDelay + 1.5e-6);
    rfGenerator.DeviceEvents.Delay = (desiredRFDelay + 1.5e-6);

    synchronizer.Synchronize();
    synchronizer.Initiate();
else
    rfGenerator.Initiate();
end

%% AutoLevel the Analyzer
[~, referenceLevelFound] = specAn.AutoLevel('', saAutoLevelBW, saAutoLevelTime);

%% Sweep and Find Optimal RF to Envelope delay
if etEnabled
    %todo
    [~, ampmMeasurementTime_actual] = specAn.Ampm.Configuration.GetMeasurementInterval('');
    
    specAn.Ampm.Configuration.ConfigureMeasurementInterval('', saAmpmDelaySweepMeasurementInterval);
    specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Ampm, true);
    [OptimalRFDelay, OptimalResidual, RFDelaysArray, ResidualsArray] = SweepDelaysAndFindOptimal(rfGenerator, specAn, saDelaySweepStart, saDelaySweepStop, saDelaySweepStep);

    specAn.Ampm.Configuration.ConfigureMeasurementInterval('', ampmMeasurementTime_actual);
end

%% Perform preDPD Measurements. Not combining measurements for a slower execution time but simpler-to-read example
% IQ
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.IQ, true);
specAn.Initiate('', '');
[~, IQDataPreDPD] = specAn.IQ.Results.FetchData('', saIQTimeout, saIQRecordToFetch, saIQSamplesToRead, []);

% Spectrum
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Spectrum, true);
specAn.Initiate('', '');
[~, spectrumPreDPD] = specAn.Spectrum.Results.FetchSpectrum('', timeout, []);

% AMPM
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Ampm, true);
specAn.Initiate('', '');
[~, AMAMReferencePowersPreDPD, AMAMPreDPD, AMAMCurveFitPreDPD] = specAn.Ampm.Results.FetchAMToAMTrace('', timeout, [], [], []);
[~, AMPMReferencePowersPreDPD, AMPMPreDPD, AMPMCurveFitPreDPD] = specAn.Ampm.Results.FetchAMToPMTrace('', timeout, [], [], []);

[~, AMPMAlignedAcquiredWaveform] = specAn.Ampm.Results.FetchProcessedMeanAcquiredWaveform('', timeout, []);
[~, AMPMAlignedReferenceWaveform] = specAn.Ampm.Results.FetchProcessedReferenceWaveform('', timeout, []);

% NR EVM
nr.ConfigureReferenceLevel('', referenceLevelFound);    %use specAn autolevel ref level found. Could also call NR AutoLevel
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.ModAcc, true);
nr.Initiate('','');
[~, EVMPreDPD] = nr.ModAcc.Results.GetMeanRmsCompositeEvm('');
tempComplexSingle = ComplexSingle.ComposeArray(0, 0);
[~, DataConstellationPreDPD, DMRSConstellationPreDPD] = nr.ModAcc.Results.FetchPuschConstellationTrace('', timeout, tempComplexSingle, tempComplexSingle);

% NR ACP
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.Acp, true);
nr.Initiate('','');
[~, lowerRelativeOffsetPreDPD, upperRelativeOffsetPreDPD, ~, ~] = nr.Acp.Results.FetchOffsetMeasurementArray('', timeout, [], [], [], []);
[~, ACPSpectrumPreDPD] = nr.Acp.Results.FetchSpectrum('', timeout, []);

%% Perform DPD. Multiple available options (custom model with Raw IQ as input, custom model with Aligned IQ as input, RFmx DPD)
% Raw IQ input
%rawIQtoModel_Acquired = [IQDataPreDPD];
%rawIQtoModel_Generaterd = [];   % refer to 'load waveform' section to retrieve the appropriate IQ array based on how the waveform was loaded

% Aligned IQ Input
% Leverate AMPMAlignedAcquiredWaveform and AMPMAlignedReferenceWaveform from earlier AMPM measurement results 

% RFmx DPD
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Dpd, true);
specAn.Initiate('','');

[~, DPDWaveform, PostDPDPAPR, PostDPDPowerOffset] = specAn.Dpd.ApplyDpd.ApplyDigitalPredistortion('', convertedReferenceWaveform, saDPDApplyDPDIdleDurationPresent, timeout, []);
rfDPDWaveformPapr = PostDPDPAPR + PostDPDPowerOffset;

%% Abort Generation and Update Waveforms for DPD, Initiate DPD Generation
rfGenerator.Abort();
if etEnabled
    envSession.Abort();
end

rfGenerator.Arb.WriteWaveform(rfDPDWaveformName, DPDWaveform);
NIRfsgPlayback.StoreWaveformSampleRate(rfGeneratorHandle, rfDPDWaveformName, rfWaveformIQRate);
NIRfsgPlayback.StoreWaveformPeakPowerAdjustment(rfGeneratorHandle, rfDPDWaveformName, rfDPDWaveformPapr);
NIRfsgPlayback.StoreWaveformSignalBandwidth(rfGeneratorHandle, rfDPDWaveformName, rfWaveformIQRate*0.8);
NIRfsgPlayback.StoreWaveformRuntimeScaling(rfGeneratorHandle, rfDPDWaveformName, -1.5); 
NIRfsgPlayback.StoreWaveformLOOffsetMode(rfGeneratorHandle, rfDPDWaveformName, rfLOOffsetMode);
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfGeneratorHandle, rfDPDScript);

fprintf('Post DPD PAPR(dB) = %f\n', rfDPDWaveformPapr);

if etEnabled
    %TODO store new ET waveform if needed
    %Reshape Envelope waveform into new IQ data (iEnvDataDPD and qEnvDataDPD)
    iEnvDataDPD = iEnvData;
    qEnvDataDPD = qEnvData;
    envSession.Arb.WriteWaveform(envDPDWaveformName, iEnvDataDPD, qEnvDataDPD);
    envSession.Arb.Scripting.WriteScript(envDPDScript);
    envSession.Arb.Scripting.SelectedScriptName = envDPDScriptName;
    envSession.Utility.Commit();
    
    synchronizer.Initiate();
else
    rfGenerator.Initiate();
end

%% Perform Post DPD Measurements
% Not combining measurements for convenience. This could be changed to use composite measurements for faster execution time
% Spectrum
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Spectrum, true);
specAn.Initiate('', '');
[~, spectrumPostDPD] = specAn.Spectrum.Results.FetchSpectrum('', timeout, []);
%TODO convert spectrum to a plot

% AMPM
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Ampm, true);
specAn.Initiate('', '');
[~, AMAMReferencePowersPostDPD, AMAMPostDPD, AMAMCurveFitPostDPD] = specAn.Ampm.Results.FetchAMToAMTrace('', timeout, [], [], []);
[~, AMPMReferencePowersPostDPD, AMPMPostDPD, AMPMCurveFitPostDPD] = specAn.Ampm.Results.FetchAMToPMTrace('', timeout, [], [], []);

% NR EVM
nr.ConfigureReferenceLevel('', referenceLevelFound);    %use specAn autolevel ref level found. Could also call NR AutoLevel
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.ModAcc, true);
nr.Initiate('','');
[~, EVMPostDPD] = nr.ModAcc.Results.GetMeanRmsCompositeEvm('');
[~, DataConstellationPostDPD, DMRSConstellationPostDPD] = nr.ModAcc.Results.FetchPuschConstellationTrace('', timeout, tempComplexSingle, tempComplexSingle);

% NR ACP
nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.Acp, true);
nr.Initiate('','');
[~, lowerRelativeOffsetPostDPD, upperRelativeOffsetPostDPD, tempres, tempres2] = nr.Acp.Results.FetchOffsetMeasurementArray('', timeout, [], [], [], []);
[~, ACPSpectrumPostDPD] = nr.Acp.Results.FetchSpectrum('', timeout, []);

%% Plot Results
figure
subplot(2,3,1)
plot(RFDelaysArray,ResidualsArray, OptimalRFDelay, OptimalResidual, 'd')
title('ET Delay Sweep')
xlabel('RF to Envelope Delay (ns)')
ylabel('AMPM Residual (deg)')

subplot(2,3,2)
plot(AMAMReferencePowersPreDPD,AMAMPreDPD,'.',AMAMReferencePowersPostDPD,AMAMPostDPD,'.')
title('AMAM Pre/Post DPD')
xlabel('Input Signal Power (dBm)')
ylabel('Gain (dB)')

subplot(2,3,3)
plot(AMPMReferencePowersPreDPD,AMPMPreDPD,'.',AMPMReferencePowersPostDPD,AMPMPostDPD,'.')
title('AMPM Pre/Post DPD')
xlabel('Input Signal Power (dBm)')
ylabel('Phase (deg)')

subplot(2,3,[4 5])
f0 = ACPSpectrumPreDPD.StartFrequency;
df = ACPSpectrumPostDPD.FrequencyIncrement;
spectrumFreqArray = f0:df:(f0+double((ACPSpectrumPreDPD.SampleCount)*df));
spectrumPreDPD_Data = ACPSpectrumPreDPD.GetData();
spectrumPostDPD_Data = ACPSpectrumPostDPD.GetData();
plot(spectrumFreqArray, spectrumPreDPD_Data, spectrumFreqArray, spectrumPostDPD_Data, 'LineWidth',3)
title('Spectrum Pre/Post DPD')
xlabel('Frequency (Hz)')
ylabel('Amplitude (dBm)')

subplot(2,3,6)
[constPreDPD_i, constPreDPD_q] = ComplexSingle.DecomposeArray(DataConstellationPreDPD);
[constPostDPD_i, constPostDPD_q] = ComplexSingle.DecomposeArray(DataConstellationPostDPD);
scatter(constPreDPD_i, constPreDPD_q, '.')
hold on
scatter(constPostDPD_i, constPostDPD_q,'.')
title('Constellation Pre/Post DPD')
xlabel('I')
ylabel('Q')

catch err
fprintf("error - %s", err.message);
%% Abort Generation and Close Sessions if Error Occured
rfGenerator.Abort();
rfGenerator.RF.OutputEnabled = false;
rfGenerator.Utility.Commit();
if etEnabled
    envSession.Abort();
    envSession.RF.OutputEnabled = false;
    envSession.Utility.Commit();
end

specAn.Dispose();
nr.Dispose();
instrSession.Close();

rfGenerator.Close();
if etEnabled
    envSession.Close();
end

error(err.message);
end

%% Finalize - Ensure Sessions are closed and disposed
if ~(rfGenerator.IsDisposed)
    rfGenerator.Abort();
    rfGenerator.RF.OutputEnabled = false;
    rfGenerator.Utility.Commit();
    rfGenerator.Close();
end
if (etEnabled) && ~(envSession.IsDisposed)
    envSession.Abort();
    envSession.RF.OutputEnabled = false;
    envSession.Utility.Commit();
    envSession.Close();
end
if ~(specAn.IsDisposed)
    specAn.Dispose();
end
if ~(nr.IsDisposed)
    nr.Dispose();
end
if ~(instrSession.IsDisposed)
    instrSession.Close();
end

%% Helper Functions 
function [OptimalRFDelay, OptimalResidual, RFDelaysArray, ResidualsArray] = SweepDelaysAndFindOptimal(rfSession, specAnSession, startDelay, stopDelay, stepDelay)
    
OptimalResidual = 9999;
	OptimalRFDelay = 9999; 
    %specAnSession.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.Ampm, true);
    
	RFDelaysArray = startDelay:stepDelay:stopDelay;
	ResidualsArray = zeros(1, length(RFDelaysArray), 'single');

	index = 0;
	for currentDelay = startDelay:stepDelay:stopDelay
		actualCurrentDelay = AdjustRFtoArbDelay(rfSession, currentDelay);
		specAnSession.Initiate('', '');
		index = index +1;
		[~, ResidualsArray(index)] = specAnSession.Ampm.Results.GetAMToPMCurveFitResidual('');
		if ResidualsArray(index)<OptimalResidual
		   OptimalResidual = ResidualsArray(index);
		   OptimalRFDelay = actualCurrentDelay;
		end   
	end
end
function newRFtoArbDelay = AdjustRFtoArbDelay(sgSession, desiredAbsoluteDelay)

	desiredRFDelay = desiredAbsoluteDelay * 1e-9;   %change to s; desiredAbsoluteDelay is in ns
	sgSession.Arb.RelativeDelay = (desiredRFDelay  + 1.5e-6);	%adjust the RF relative to the envelope
	sgSession.DeviceEvents.Delay = (desiredRFDelay + 1.5e-6);	%adjust the trigger outputs to keep alignment with RF

    newRFtoArbDelay = (sgSession.Arb.RelativeDelay - 1.5e-6) * 1e9;
end