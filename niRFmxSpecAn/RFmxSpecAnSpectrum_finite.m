%% Initialization
clc;
clear;

%% Making NI RFmx .net assemblies visible to matlab and Importing them 
Rfmx_handle = NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
SpecAn_handle = NET.addAssembly('NationalInstruments.RFmx.SpecAnMX.Fx40'); 
import 'NationalInstruments.RFmx.InstrMX'.*;
import 'NationalInstruments.RFmx.SpecAnMX.*';

%% Setting constants
Resource_name = 'PXI2Slot3';
Center_freq = 1e9;                                                          % Units in Hz
Clock_source = RFmxInstrMXConstants.OnboardClock;
Reference_level = 0;                                                        % Units in dBm
Span = 10*1e6;                                                              % Units in Hz
Rbw = 100*1e3;                                                              %Units in Hz
no_of_Averages = 10;
Timeout= 10;                                                                % Units in seconds


%% Creating session
Instr_handle = RFmxInstrMX(Resource_name, '');

%% Get SpecAn configuration session
SpecAn = RFmxSpecAnMXExtension.GetSpecAnSignalConfiguration(Instr_handle);

%%  Configure Receiver's analog RF and Spectrum settings using "RFmxSpecAnMXSpectrumConfiguration Class" mostly
SpecAn.ConfigureRF('',Center_freq,Reference_level,0);
SpecAn.Spectrum.Configuration.ConfigureSpan('',Span);
SpecAn.Spectrum.Configuration.ConfigureRbwFilter(...
    '',RFmxSpecAnMXSpectrumRbwAutoBandwidth.True,Rbw,...
    RFmxSpecAnMXSpectrumRbwFilterType.FftBased);
SpecAn.Spectrum.Configuration.ConfigureAveraging(...
    '',RFmxSpecAnMXSpectrumAveragingEnabled.True,...
    no_of_Averages,RFmxSpecAnMXSpectrumAveragingType.Rms);
SpecAn.SelectMeasurements('',RFmxSpecAnMXMeasurementTypes.Spectrum,false);  % Important for avoiding error by specifying measurement type

%% Acquiring data and measurements using "RFmxSpecAnMXSpectrumResults Class" 
SpecAn.Initiate('','');
[~,Data]=SpecAn.Spectrum.Results.FetchSpectrum('',Timeout,[]);

%% Extracting information and Plotting Data (Use Measurement Studio Help and object browser in visual studio to see how to extract data)
f0 = Data.StartFrequency;
df = Data.FrequencyIncrement;
spectrum_d = Data.GetData();                                                % Use GetRawData() method for waveform
x_axis = df*(0:Data.SampleCount-1)+f0;
plot(x_axis,spectrum_d);
%% Closing RFmx Session and disposing SpecAn settings
SpecAn.Dispose();
Instr_handle.Close();