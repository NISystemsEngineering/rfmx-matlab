clear;
clc;

NET.addAssembly('Ivi.Driver');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsg.Fx40');
NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsgPlayback.Fx40');

import System.*
import NationalInstruments.ModularInstruments.NIRfsg.*
import NationalInstruments.ModularInstruments.NIRfsgPlayback.*

% Initialize Variables %
filepath = 'Support\LTE_FDD_PUSCH_10MHz_QPSK.tdms';
resourceName = 'VST_01';
optionsString = '';
carrierFrequency = 5.18e9;  % Hz
powerLevel = -10;         % dBm
externalAttenuation = 0; % dB
referenceClockSource = RfsgFrequencyReferenceSource.OnboardClock;
waveformName = 'waveform';
script = ['script GenerateWlan ' ...
             'repeat forever ' ...
                'generate waveform ' ...
             'end repeat ' ...
          'end script'];

% Initialize RFSG %
rfsgSession = NIRfsg(resourceName, true, false, optionsString);
rfsgHandle = rfsgSession.DangerousGetInstrumentHandle();

% Configure RFSG %
rfsgSession.RF.Configure(carrierFrequency, powerLevel);
rfsgSession.FrequencyReference.Configure(referenceClockSource, 10e6);
rfsgSession.RF.ExternalGain = -externalAttenuation;
NIRfsgPlayback.ReadAndDownloadWaveformFromFile(rfsgHandle, filepath, waveformName);
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfsgHandle, script);
rfsgSession.Initiate();

input('Generating waveform. Press enter to stop.\n');

% Close Session %
rfsgSession.Abort();
rfsgSession.RF.OutputEnabled = false;
rfsgSession.Utility.Commit();
NIRfsgPlayback.ClearWaveform(rfsgHandle, waveformName);
rfsgSession.Close();
