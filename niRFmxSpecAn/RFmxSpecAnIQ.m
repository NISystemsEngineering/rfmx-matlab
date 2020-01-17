clear;
clc;

NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
NET.addAssembly('NationalInstruments.RFmx.SpecAnMX.Fx40');

import NationalInstruments.RFmx.InstrMX.*;
import NationalInstruments.RFmx.SpecAnMX.*;

resourceName = 'VST_01';
centerFrequency = 1e+9;         % Hz %
referenceLevel = 0.00;          % dBm %
externalAttenuation = 0.00;     % dB %
frequencySource = RFmxInstrMXConstants.OnboardClock;
frequency = 10e+6;               % Hz %
iqPowerEdgeEnabled = false;
iqPowerEdgeLevel = -20.0;        % dBm %
triggerDelay = 0.0;              % seconds %
minimumQuietTime = 0.0;          % seconds %
sampleRate = 10e+6;              % samples per second %
acquisitionTime = 0.001;         % seconds %
recordToFetch = 0;
samplesToRead = -1;
timeout = 10;                   % seconds %
sum = 0;

% Create a new RFmx Session %
instrSession = RFmxInstrMX(resourceName, '');

% Get SpecAn signal %
specAn = RFmxSpecAnMXExtension.GetSpecAnSignalConfiguration(instrSession);

% Configure measurement %
instrSession.ConfigureFrequencyReference('', frequencySource, frequency);
specAn.ConfigureRF('', centerFrequency, referenceLevel, externalAttenuation);
specAn.ConfigureIQPowerEdgeTrigger('', '0', iqPowerEdgeLevel, RFmxSpecAnMXIQPowerEdgeTriggerSlope.Rising, ...
                                  triggerDelay, RFmxSpecAnMXTriggerMinimumQuietTimeMode.Manual, ...
                                  minimumQuietTime, iqPowerEdgeEnabled);
specAn.SelectMeasurements('', RFmxSpecAnMXMeasurementTypes.IQ, false);
specAn.IQ.Configuration.ConfigureAcquisition('', sampleRate, 1, acquisitionTime, 0);
specAn.Initiate('', '');

% Retrieve results %
[~, data] = specAn.IQ.Results.FetchData('', timeout, recordToFetch, samplesToRead, []);
realArray = data.GetRealDataArray(false);
imaginaryArray = data.GetImaginaryDataArray(false);
for i = 1:data.SampleCount
    sum = sum + (realArray(i) * realArray(i)) + (imaginaryArray(i) * imaginaryArray(i));
end
meanPower = sum / double(data.SampleCount);
meanPowerInDbm = 10 * log10(meanPower / (2 * 50) / 0.001);
fprintf('Mean Power (dBm) = %f\n', meanPowerInDbm);

% Close session %
specAn.Dispose();
instrSession.Close();