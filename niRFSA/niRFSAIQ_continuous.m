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

%% Setting properties
rfsasession.Configuration.AcquisitionType = RfsaAcquisitionType.IQ;         % Selecting between IQ and Spectrum Acquisition
rfsasession.Configuration.Vertical.ReferenceLevel = 0.0;                    % Units in dbm
rfsasession.Configuration.IQ.CarrierFrequency = 1E+9;                       %Units in Hz
rfsasession.Configuration.IQ.NumberOfSamples = 10000;                    
rfsasession.Configuration.IQ.IQRate = 1e6;                                  % Units in samples/sec
rfsasession.Configuration.IQ.NumberOfSamplesIsFinite  = false; 

%% Configuring GUI
figure;
handles.hPlot = plot(1);                                                    % Plot handle for data update
pause(0.1);
%% Acquiring and plotting data
rfsasession.Acquisition.IQ.Initiate();                                      % Initiating acquisition
for i=1:1000                                                        
    Data= rfsasession.Acquisition.IQ.FetchIQSingleRecordComplexWaveform(... % Fetching data
        0,rfsasession.Configuration.IQ.NumberOfSamples,...
        NationalInstruments.PrecisionTimeSpan(5));
    pause(0.001);
    RealData = Data.GetRealDataArray(false);
    ImaginaryData = Data.GetImaginaryDataArray(false);
    set(handles.hPlot,'YData',ImaginaryData);                               %This is one of the most optimal way of data update on 
end

%% Closing RFSA Session and created figure
rfsasession.Close();
close Figure 1;
