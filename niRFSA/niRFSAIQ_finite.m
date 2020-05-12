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
rfsasession.Configuration.IQ.NumberOfSamples = 100000;                    
rfsasession.Configuration.IQ.IQRate = 1e8;                                  % Units in samples/sec

%% Initiating acquisition and acquiring data
rfsasession.Acquisition.IQ.Initiate();
Data= rfsasession.Acquisition.IQ.FetchIQSingleRecordComplexWaveform(0, rfsasession.Configuration.IQ.NumberOfSamples,NationalInstruments.PrecisionTimeSpan(5));

%% Plotting Data
RealData = Data.GetRealDataArray(false);
ImaginaryData = Data.GetImaginaryDataArray(false);
plot(ImaginaryData);

%% Closing RFSA Session 
rfsasession.Close();
