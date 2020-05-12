%% Initialization
clc;
clear;

%% Making NI .net assemblies visible to matlab and Importing them 
Rfmx_handle = NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
SpecAn_handle = NET.addAssembly('NationalInstruments.RFmx.SpecAnMX.Fx40'); 
import 'NationalInstruments.RFmx.InstrMX'.*;
import 'NationalInstruments.RFmx.SpecAnMX.*';

%% Setting constants
Resource_name = 'PXI2Slot3';
Sampling_rate = 100*1e6;                                                    % Units Samples/sec
Center_freq = 1e9;                                                          % Units in Hz
Clock_source = RFmxInstrMXConstants.OnboardClock;
Reference_level = 0;                                                        % Units in dBm
num_of_records = 1;
Acquisitiontime = 0.001;                                                     % Units in seconds
Samplestoread = -1;
Timeout= 10;                                                                % Units in seconds


%% Creating session
Instr_handle = RFmxInstrMX(Resource_name, '');

%% Get SpecAn configuration session
SpecAn = RFmxSpecAnMXExtension.GetSpecAnSignalConfiguration(Instr_handle);

%%  Configure RF and ADC settings
SpecAn.ConfigureRF('',Center_freq,Reference_level,0);
SpecAn.IQ.Configuration.ConfigureAcquisition('',Sampling_rate,num_of_records,Acquisitiontime,0);  % Using a seperate class in RFmxSpecAn
SpecAn.SelectMeasurements('',RFmxSpecAnMXMeasurementTypes.IQ,false);

%% Initiating and Fetching data
SpecAn.Initiate('','');
[~, Data]=SpecAn.IQ.Results.FetchData('',Timeout,0,Samplestoread,[]);
%% Plotting Data
RealData = Data.GetRealDataArray(false);
ImaginaryData = Data.GetImaginaryDataArray(false);
plot(RealData);

%% Closing RFmx Session and disposing SpecAn settings
SpecAn.Dispose();
Instr_handle.Close();