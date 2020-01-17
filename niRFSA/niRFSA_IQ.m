clear;
clc;

NET.addAssembly('NationalInstruments.Common');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsa.Fx40');

import NationalInstruments.*
import NationalInstruments.ModularInstruments.NIRfsa.*

resourceName = 'VST2_01';
optionsString = '';
referenceClockSource = RfsaReferenceClockSource.OnboardClock;
referenceLevel = 0;
carrierFrequency = 3.5e9;  % Hz
externalAttenuation = 0;

iqRate = 120e6;
acquisitionTime = 10e-3;
fetchLength = 1e-3; % seconds
fetchTimeout = 10; % second

rfsaSession = NIRfsa(resourceName, true, false, optionsString);
rfsaSession.Configuration.ReferenceClock.Source = referenceClockSource;
rfsaSession.Configuration.AcquisitionType = RfsaAcquisitionType.IQ;
rfsaSession.Configuration.Vertical.ReferenceLevel = referenceLevel;
rfsaSession.Configuration.IQ.CarrierFrequency = carrierFrequency;
rfsaSession.Configuration.Vertical.Advanced.ExternalGain = -externalAttenuation;
rfsaSession.Configuration.IQ.IQRate = iqRate;
iqRate = rfsaSession.Configuration.IQ.IQRate; % gets coerced iq rate, if any
minSamples = ceil(acquisitionTime * iqRate);
rfsaSession.Configuration.IQ.NumberOfSamples = minSamples;

rfsaSession.Acquisition.IQ.Initiate();

scalingCoefficients = rfsaSession.Utility.GetScalingCoefficients();
scalingCoefficients = scalingCoefficients(1);
gain = scalingCoefficients.Gain;
offset = scalingCoefficients.Offset;

chunkSize = round(fetchLength * iqRate);
fetchTimeout = PrecisionTimeSpan(fetchTimeout);

samplesFetched = 0;
chunksFetched = 0;
while samplesFetched < minSamples
    [iqData, wfmInfo] = NET.invokeGenericMethod(rfsaSession.Acquisition.IQ, ...
        'FetchIQSingleRecordComplex', {'NationalInstruments.ComplexInt16'}, 0, chunkSize, fetchTimeout);
    [real, imag] = ComplexInt16.DecomposeArray(iqData);
    real = int16(real);
    imag = int16(imag);
    samplesFetched = samplesFetched + length(real);
    chunksFetched = chunksFetched + 1;
    save(sprintf('chunk%d.mat', chunksFetched), 'real', 'imag', 'gain', 'offset');
end

rfsaSession.Close();
