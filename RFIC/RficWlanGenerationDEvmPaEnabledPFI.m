%This Script is for the generation of waveform for Dynamic EVM testing. For
%dynamic EVM testing we are using waveform markers to generate triggers
%that can be potentially used by a VSA to start a measurement. Also, we are
%using the markers for generating PA enable signal (PAEN) to enable and
%disable PA for dynamic EVM Measurments. This script is based on NIRFSG and
%NIRFSGPlayback .NET APIs along with native matlab functions. To Run the
%script use the "Run" option in matlab EDITOR. To stop generation you can
%press on the "Stop Loop" button on "Figure 1" than pops up after running 
%the code. Or you can just close "Figure 1" to Stop execution.  

%% Initialization
clc;
clear;

%% Making NI RFSG .net assemblies visible to matlab and Importing them 
Rfsg_handle = NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsg.Fx40');
Playback_handle = NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsgPlayback.Fx40');
NET.addAssembly('NationalInstruments.Common');

import 'NationalInstruments.ModularInstruments.NIRfsg'.*;
import 'NationalInstruments.ModularInstruments.NIRfsgPlayback'.*;
import NationalInstruments.*;

%% Creating session
Resource = 'PXI2Slot5';
rfsgsession = NIRfsg(Resource,false,false);
rfsgHandle = rfsgsession.DangerousGetInstrumentHandle();                    % Getting RFSG handle for RFSG playback

%% Building file path for generation
directory = matlab.desktop.editor.getActiveFilename;
[filepath,name,ext]= fileparts(directory);
path = fullfile(filepath,'80211ax_80M_MCS11.tdms');

%% Setting the values of Constants for RF generation and PAEN Pulse timing
Center_fg = 5.77e9;                                                         % Units in Hz
DUT_average_input_power = -10;                                              % Units in dBm
PAEN_Pulse_Enabled = true;                                                  % Enabling PA for Devm Measurement
Rf_waveform_name = 'Wfm';
RF_Script_name = 'RfWfmScript';                 
External_gain = 0;                                                          % Units in dBm
t1 = 500e-9;                                                                % Units in seconds (time_before_burst)
t2 = 500e-9;                                                                % Units in seconds (time_after_burst)

%% Configuring Markers and RFSG analog properties

% Specifies source of Ref Clock and its rate
rfsgsession.FrequencyReference.Source = ...                                
    RfsgFrequencyReferenceSource.PxiClock;
rfsgsession.FrequencyReference.Rate = 10e6;

% This marker is for sending digital trigger at start of waveform 
markerEvent0 = Item(rfsgsession.DeviceEvents.MarkerEvents, 0);
markerEvent0.ExportedOutputTerminal = RfsgMarkerEventExportedOutputTerminal.PxiTriggerLine0;

% This marker is for enabling and disabling PA 
markerEvent1 = Item(rfsgsession.DeviceEvents.MarkerEvents, 1);
markerEvent1.ExportedOutputTerminal = RfsgMarkerEventExportedOutputTerminal.Pfi0;
markerEvent1.OutputBehaviour = RfsgMarkerEventOutputBehaviour.Toggle;
markerEvent1.ToggleInitialState = RfsgMarkerEventToggleInitialState.DigitalHigh;


% Configuring generation properties
rfsgsession.RF.Configure(Center_fg,DUT_average_input_power);
rfsgsession.RF.PowerLevelType = RfsgRFPowerLevelType.PeakPower;
rfsgsession.RF.ExternalGain = -1*External_gain;
rfsgsession.Arb.GenerationMode = RfsgWaveformGenerationMode.Script;

% Downloading and reading file and waveform properties

% [~,version] = NIRfsgPlayback.ReadWaveformFileVersionFromFile(path)        (optional method for error checking)

[~,waveform]=NIRfsgPlayback.ReadWaveformFromFileComplex(path,[]);
NIRfsgPlayback.DownloadUserWaveform(rfsgHandle,Rf_waveform_name,waveform,true);
[~,BurstStartLocation] = NIRfsgPlayback.ReadBurstStartLocationsFromFile(path,0,[]);
NIRfsgPlayback.StoreWaveformBurstStartLocations(rfsgHandle,Rf_waveform_name,BurstStartLocation);
[~,BurstStopLocation] = NIRfsgPlayback.ReadBurstStopLocationsFromFile(path,0,[]);
NIRfsgPlayback.StoreWaveformBurstStopLocations(rfsgHandle,Rf_waveform_name,BurstStopLocation);
[~,BurstStartLocation] = NIRfsgPlayback.RetrieveWaveformBurstStartLocations(rfsgHandle,Rf_waveform_name,[]);
[~,BurstStopLocation] = NIRfsgPlayback.RetrieveWaveformBurstStopLocations(rfsgHandle,Rf_waveform_name,[]);
[~,Papr] = NIRfsgPlayback.RetrieveWaveformPapr(rfsgHandle,Rf_waveform_name);    % Units in db
[~,SampleRate] = NIRfsgPlayback.RetrieveWaveformSampleRate(rfsgHandle,Rf_waveform_name);
NIRfsgPlayback.StoreWaveformRFBlankingEnabled(rfsgHandle,Rf_waveform_name,false);

%%  Calculating Marker toggle postions and converting to string
mark1_start = BurstStopLocation(1)+(t1*SampleRate);
mark1_end = waveform.SampleCount()-(t2*SampleRate);
Marker1_start = int2str(mark1_start);
Marker1_end = int2str(mark1_end);

%% Forming script
Script = 'script' + " " + RF_Script_name + "\n" + 'repeat forever'+ "\n" +'generate' + " " + Rf_waveform_name + " " +...
    'marker0(0)' + " " + "marker1("+ Marker1_start + ','+ Marker1_end + ')'+ "\n" + 'end repeat' + "\n" + 'end script';
Script_final = compose(Script);

%% Setting the Script for generation
NIRfsgPlayback.SetScriptToGenerateSingleRfsg(rfsgHandle,Script_final);

%% Initiating Generation
rfsgsession.Initiate();

%% Creating a button for stopping generation and displaying real part of burst signal with PAEN
figure;
ButtonHandle = uicontrol('Style', 'PushButton', ...
                         'String', 'Stop loop', ...
                         'Callback', 'delete(gcbf)');
 t0 = waveform.PrecisionTiming.TimeOffset.TotalSeconds;
 dt = waveform.PrecisionTiming.SampleInterval.TotalSeconds;
 x_axis = dt*(0:double(waveform.SampleCount)-1)+t0;
plot(x_axis,waveform.GetRealDataArray(false));
waveform_size = waveform.SampleCount();
hold on;
title('Plot of Generated waveform with PAEN');
xlabel('Time (sec)');
ylabel('Voltage (V)');
plot(x_axis,[ones(1,mark1_start) zeros(1,mark1_end-mark1_start) ones(1,waveform_size-mark1_end)]);
legend('Waveform Data','PAEN Signal');
while ishandle(ButtonHandle)
    pause(0.01);                                                            % A NEW LINE
end

%% Closing RFSG Session and disposing settings
rfsgsession.Abort();
rfsgsession.Close();
