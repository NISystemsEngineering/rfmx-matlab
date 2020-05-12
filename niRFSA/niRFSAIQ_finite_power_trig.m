%% Initialization
clc;
clear;

%% Making NI RFSA .net assemblies visible to matlab and Importing them 
Rfsa_handle = NET.addAssembly('NationalInstruments.ModularInstruments.NIRfsa.Fx40');
NET.addAssembly('NationalInstruments.Common');
import 'NationalInstruments.ModularInstruments.NIRfsa'.*;

%% Creating session
Resource_name = 'PXI2Slot3';
rfsasession = NIRfsa(Resource_name,false,false);

%% Setting Signal path properties
rfsasession.Configuration.AcquisitionType = RfsaAcquisitionType.IQ;         % Selecting between IQ and Spectrum Acquisition
rfsasession.Configuration.Vertical.ReferenceLevel = 0.0;                    % Units in dbm
rfsasession.Configuration.IQ.CarrierFrequency = 1E+9;                       % Units in Hz
rfsasession.Configuration.IQ.NumberOfSamples = 10000;                    
rfsasession.Configuration.IQ.IQRate = 1e6;                                  % Units in samples/sec
rfsasession.Configuration.IQ.NumberOfSamplesIsFinite  = true; 

%% Configuring trigger properties
rfsasession.Configuration.Triggers.ReferenceTrigger.IQPowerEdge.Level = -20;    % Units in dBm
rfsasession.Configuration.Triggers.ReferenceTrigger.IQPowerEdge.Slope=RfsaIQPowerEdgeReferenceTriggerSlope.Rising;
rfsasession.Configuration.Triggers.ReferenceTrigger.Type = RfsaReferenceTriggerType.IQPowerEdge;

%% Configuring GUI
figure;
handles.hPlot = plot(1);                                                    % Plot handle for data update
%% Acquiring and plotting data
rfsasession.Acquisition.IQ.Initiate();                                      % Initiating acquisition                                                       
    Data= rfsasession.Acquisition.IQ.FetchIQSingleRecordComplexWaveform(... % Fetching data
        0,rfsasession.Configuration.IQ.NumberOfSamples,...
        NationalInstruments.PrecisionTimeSpan(-1));
    pause(0.001);
    RealData = Data.GetRealDataArray(false);
    ImaginaryData = Data.GetImaginaryDataArray(false);
    set(handles.hPlot,'YData',ImaginaryData);                               % This is one of the most optimal way of data update on 

%% Closing RFSA Session 
rfsasession.Close();
