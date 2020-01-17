% WARNING! THIS CODE HAS NOT BEEN TESTED! %

NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
NET.addAssembly('NationalInstruments.RFmx.NRMX.Fx40');

import NationalInstruments.*;
import NationalInstruments.RFmx.InstrMX.*;
import NationalInstruments.RFmx.NRMX.*;

instrSession = RFmxInstrMX('', 'AnalysisOnly=1');
nr = RFmxNRMXExtension.GetNRSignalConfiguration(instrSession);

% Waveform Parameters %
frequencyRange = RFmxNRMXFrequencyRange.Range1;
band = 78;
subcarrierSpacing = 30e3; 
autoResourceBlockDetectionEnabled = RFmxNRMXAutoResourceBlockDetectionEnabled.True;

componentCarrierSpacingType = RFmxNRMXComponentCarrierSpacingType.Nominal;
channelRaster = 15e3;
componentCarrierAtCenterFrequency = -1;

NumberOfComponentCarriers = 2
componentCarrierBandwidth(0) = 100e6;   
componentCarrierBandwidth(1) = 100e6;   
componentCarrierFrequency(0) = -49.98e6;
componentCarrierFrequency(1) = 50.01e6; 
cellID(0) = 0;
cellID(1) = 1;

puschTransformPrecodingEnabled = RFmxNRMXPuschTransformPrecodingEnabled.False;
puschModulationType = RFmxNRMXPuschModulationType.Qpsk;
NumberOfResourceBlockClusters = 1
puschResourceBlockOffset(0) = 0;
puschNumberOfResourceBlocks(0) = -1;
puschSlotAllocation = '0-Last';
puschSymbolAllocation = '0-Last';

puschDmrsPowerMode = RFmxNRMXPuschDmrsPowerMode.CdmGroups;
puschDmrsPower = 0.0;
puschDmrsConfigurationType = RFmxNRMXPuschDmrsConfigurationType.Type1;
puschMappingType = RFmxNRMXPuschMappingType.TypeA;
puschDmrsTypeAPosition = 2;
puschDmrsDuration = RFmxNRMXPuschDmrsDuration.SingleSymbol;
puschDmrsAdditionalPositions = 0;

synchronizationMode = RFmxNRMXModAccSynchronizationMode.Slot;

measurementLengthUnit = RFmxNRMXModAccMeasurementLengthUnit.Slot;
measurementOffset = 0.0;
measurementLength = 1;

% Analysis Configuration %
nr.SetFrequencyRange('', frequencyRange);
nr.SetBand('', band);
nr.SetChannelRaster('', channelRaster);
nr.SetComponentCarrierSpacingType('', componentCarrierSpacingType);
nr.SetComponentCarrierAtCenterFrequency('', componentCarrierAtCenterFrequency);
nr.SetAutoResourceBlockDetectionEnabled('', autoResourceBlockDetectionEnabled);

nr.ComponentCarrier.SetNumberOfComponentCarriers('', NumberOfComponentCarriers);

subblockString = RFmxNRMX.BuildSubblockString('', 0);
for i = 0:NumberOfComponentCarriers - 1
    carrierString = RFmxNRMX.BuildCarrierString(subblockString, i);
    nr.ComponentCarrier.SetBandwidth(carrierString, componentCarrierBandwidth(i));
    nr.ComponentCarrier.SetCellID(carrierString, cellID(i));
    nr.ComponentCarrier.SetFrequency(carrierString, componentCarrierFrequency(i));
end

carrierString = 'carrier::all';
nr.ComponentCarrier.SetPuschTransformPrecodingEnabled(carrierString, puschTransformPrecodingEnabled);
nr.ComponentCarrier.SetPuschModulationType(carrierString, puschModulationType);
nr.ComponentCarrier.SetPuschSlotAllocation(carrierString, puschSlotAllocation);
nr.ComponentCarrier.SetPuschSymbolAllocation(carrierString, puschSymbolAllocation);

nr.ComponentCarrier.SetBandwidthPartSubcarrierSpacing(carrierString, subcarrierSpacing);
nr.ComponentCarrier.SetPuschNumberOfResourceBlockClusters(carrierString, NumberOfResourceBlockClusters);

for i = 0:NumberOfResourceBlockClusters - 1
    puschClusterString = RFmxNRMX.BuildPuschClusterString(carrierString, i);
    nr.ComponentCarrier.SetPuschResourceBlockOffset(puschClusterString, puschResourceBlockOffset(i));
    nr.ComponentCarrier.SetPuschNumberOfResourceBlocks(puschClusterString, puschNumberOfResourceBlocks(i));
end

nr.ComponentCarrier.SetPuschDmrsPowerMode(carrierString, puschDmrsPowerMode);
nr.ComponentCarrier.SetPuschDmrsPower(carrierString, puschDmrsPower);
nr.ComponentCarrier.SetPuschDmrsConfigurationType(carrierString, puschDmrsConfigurationType);
nr.ComponentCarrier.SetPuschMappingType(carrierString, puschMappingType);
nr.ComponentCarrier.SetPuschDmrsTypeAPosition(carrierString, puschDmrsTypeAPosition);
nr.ComponentCarrier.SetPuschDmrsDuration(carrierString, puschDmrsDuration);
nr.ComponentCarrier.SetPuschDmrsAdditionalPositions(carrierString, puschDmrsAdditionalPositions);

nr.SelectMeasurements('', RFmxNRMXMeasurementTypes.ModAcc, true);

nr.ModAcc.Configuration.SetSynchronizationMode('', synchronizationMode);

nr.ModAcc.Configuration.SetMeasurementLengthUnit('', measurementLengthUnit);
nr.ModAcc.Configuration.SetMeasurementOffset('', measurementOffset);
nr.ModAcc.Configuration.SetMeasurementLength('', measurementLength);

% Read Waveform From File %
[~, complexWaveform] = NIRfsgPlayback.ReadWaveformFromFileComplex('', []); % need to supply a waveform path here
wfmSampleRate = 1 / (referenceWaveform.PrecisionTiming.SampleInterval.FractionalSeconds);
[rfWaveformIArray, rfWaveformQArray] = ComplexSingle.DecomposeArray(complexWaveform.GetRawData());

% THIS IS WHERE WE SEND THE DATA THROUGH THE MODEL %

% Format the data back into NIs ComplexWaveform %
cplxSingleArray = ComplexSingle.ComposeArray(rfWaveformIArray, rfWaveformQArray);
postWaveform = NET.createGeneric('NationalInstruments.ComplexWaveform', {'NationalInstruments.ComplexSingle'}, 0, cplxSingleArray.Length);
postWaveform.Append(cplxSingleArray);

nr.ModAcc.AnalyzeIQ('', '', postWaveform, true)

% Fetch Results %
for i = 0:NumberOfComponentCarriers - 1
    carrierString = RFmxNRMX.BuildCarrierString(subblockString, i);

    [~, compositeRmsEvmMean(i)] = NR.ModAcc.Results.GetCompositeRmsEvmMean(carrierString, []);
    [~, compositePeakEvmMaximum(i)] = NR.ModAcc.Results.GetCompositePeakEvmMaximum(carrierString, []);
    [~, compositePeakEvmSlotIndex(i)] = NR.ModAcc.Results.GetCompositePeakEvmSlotIndex(carrierString, []);
    [~, compositePeakEvmSymbolIndex(i)] = NR.ModAcc.Results.GetCompositePeakEvmSymbolIndex(carrierString, []);
    [~, compositePeakEvmSubcarrierIndex(i)] = NR.ModAcc.Results.GetCompositePeakEvmSubcarrierIndex(carrierString, []);
    [~, componentCarrierFrequencyErrorMean(i)] = NR.ModAcc.Results.GetComponentCarrierFrequencyErrorMean(carrierString, []);
    [~, componentCarrierIQOriginOffsetMean(i)] = NR.ModAcc.Results.GetComponentCarrierIQOriginOffsetMean(carrierString, []);
    [~, componentCarrierIQGainImbalanceMean(i)] = NR.ModAcc.Results.GetComponentCarrierIQGainImbalanceMean(carrierString, []);
    [~, componentCarrierQuadratureErrorMean(i)] = NR.ModAcc.Results.GetComponentCarrierQuadratureErrorMean(carrierString, []);
    [~, inBandEmissionMargin(i)] = NR.ModAcc.Results.GetInBandEmissionMargin(carrierString, []);
end

for i = 0:NumberOfComponentCarriers - 1
    carrierString = RFmxNRMX.BuildCarrierString('', i);
    [~, puschDataConstellation(i)] = NR.ModAcc.Results.FetchPuschDataConstellationTrace(carrierString, timeout, []);
    [~, puschDmrsConstellation(i)] = NR.ModAcc.Results.FetchPuschDmrsConstellationTrace(carrierString, timeout, []);
end

for i = 0:NumberOfComponentCarriers - 1
    carrierString = RFmxNRMX.BuildCarrierString(subblockString, i);
    [~, rmsEvmPerSubcarrierMean(i)] = NR.ModAcc.Results.FetchRmsEvmPerSubcarrierMeanTrace(carrierString, timeout, []);
    [~, rmsEvmPerSymbolMean(i)] = NR.ModAcc.Results.FetchRmsEvmPerSymbolMeanTrace(carrierString, timeout, []);
end

[~, spectralFlatness, spectralFlatnessLowerMask, spectralFlatnessUpperMask] = NR.ModAcc.Results.FetchSpectralFlatnessTrace('', timeout, [], [], []);

% Print Results %
fprintf('------------------------Measurements------------------------\n');
for i = 0:NumberOfComponentCarriers - 1
    fprintf('Carrier  : %d', i);
    fprintf('Composite RMS EVM Mean (%)                     : %.3f', compositeRmsEvmMean(i));
    fprintf('Composite Peak EVM Maximum (%)                 : %.3f', compositePeakEvmMaximum(i));
    fprintf('Composite Peak EVM Slot Index                  : %d',   compositePeakEvmSlotIndex(i));
    fprintf('Composite Peak EVM Symbol Index                : %d',   compositePeakEvmSymbolIndex(i));
    fprintf('Composite Peak EVM Subcarrier Index            : %d',   compositePeakEvmSubcarrierIndex(i));
    fprintf('Component Carrier Frequency Error Mean (Hz)    : %.3f', componentCarrierFrequencyErrorMean(i));
    fprintf('Component Carrier IQ Origin Offset Mean (dBc)  : %.3f', componentCarrierIQOriginOffsetMean(i));
    fprintf('Component Carrier IQ Gain Imbalance Mean (dB)  : %.3f', componentCarrierIQGainImbalanceMean(i));
    fprintf('Component Carrier Quadrature Error Mean (deg)  : %.3f', componentCarrierQuadratureErrorMean(i));
    fprintf('In-Band Emission Margin (dB)                   : %.3f', inBandEmissionMargin(i));
    fprintf('-----------------------------------------------------------------\n');
end
fprintf('Reference level (dBm) : %.3f\n', referenceLevel);

% Close the Session %
NR.Dispose()
instrSession.Dispose()