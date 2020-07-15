% This script is the measurement and analysis portion for dynamic EVM
% measurements. For dynamic EVm measurement we are using IQ Power edge
% trigger to start the measurement. This script is largely based on NIRFmx
% IntrumentMx, NIRFmx WlanMX and NIDCPower .NET APIs along with native
% matlab functions. An SMU/ NI DC power source is used to power up the PA.
%To Run the script use the "Run" option in matlab EDITOR.

%% Initialization
clc;
clear;
close;

%% Making NI .net assemblies visible to matlab and Importing them 
NET.addAssembly('NationalInstruments.Common');
NET.addAssembly('NationalInstruments.ModularInstruments.NIDCPower.Fx40');
Rfmx_handle = NET.addAssembly('NationalInstruments.RFmx.InstrMX.Fx40');
Wlan_handle = NET.addAssembly('NationalInstruments.RFmx.WlanMX.Fx40'); 

import NationalInstruments.*;
import 'NationalInstruments.RFmx.InstrMX'.*;
import 'NationalInstruments.RFmx.WlanMX.*';
import 'NationalInstruments.ModularInstruments.NIDCPower.*';

%% Making SMU Session
Channel_name='0';
Smu = NIDCPower('PXI2Slot11_2',Channel_name,false);


%% Configuring SMU as a voltage source
Smu.Source.Mode= DCPowerSourceMode.SinglePoint;
Output = Item(Smu.Outputs,Channel_name);                                     %"We cannot access array object in method"                                               
Output.Source.Output.Function = DCPowerSourceOutputFunction.DCVoltage;
Output.Source.Output.Function = DCPowerSourceOutputFunction.DCVoltage;
Output.Source.Voltage.VoltageLevel = 5;                                      %Unit in Volts
Output.Source.Voltage.CurrentLimit = 0.5;                                    %Unit in Amps
Output.Source.Voltage.VoltageLevelRange = 6;                                 %Unit in Volts
Output.Source.Voltage.CurrentLimitRange = 0.5;                               %Unit in Amps


%% Initiating Power generation and waiting for source to settle
Smu.Control.Initiate();
Smu.Events.SourceCompleteEvent.WaitForEvent(PrecisionTimeSpan(5.0));

%% Acquire generated voltage and current (for sanity check only)
DCPowerMeasureResult = Smu.Measurement.Measure('0');
Voltage = DCPowerMeasureResult.VoltageMeasurements(1);                       %Units in volts
Current = DCPowerMeasureResult.CurrentMeasurements(1);                       %Units in Amps

%% Setting constants for Wlan and VST
Resource_name = 'PXI2Slot5';
Center_freq = 5.77e9;                                                        % Units in Hz
Reference_level = 25;                                                        % Units in dBm
ExternalAttenuation = 20;                                                    % Units in dBm
PowerEdgeTriggerLevel= -20;                                                  % Units in dBm
TriggerDelay = 0;                                                            % Units in sec
minimumQuietTime = 5e-6;                                                     % Units in sec
TrigEnable = true;
WlanStandard = RFmxWlanMXStandard.Standard802_11ax;
ChannelBandwidth = 80e6;                                                     % Units in Hz
MeasurementOffset = 0;                                                       % Units in Symbols
MaximumMeasurementLength = 16;                                               % Units in Symbols
FrequencyErrorEstimationMethod = RFmxWlanMXOfdmModAccFrequencyErrorEstimationMethod.PreambleAndPilots;
PhaseTrackingEnabled = RFmxWlanMXOfdmModAccPhaseTrackingEnabled.True;
SymbolClockErrorCorrectionEnabled = RFmxWlanMXOfdmModAccSymbolClockErrorCorrectionEnabled.True;
ChannelEstimationType = RFmxWlanMXOfdmModAccChannelEstimationType.Reference;
AveragingEnabled = RFmxWlanMXOfdmModAccAveragingEnabled.False;
AveragingCount = 10;
Timeout= -1;                                                                 % Units in seconds

%% Creating VST session
Instr_handle = RFmxInstrMX(Resource_name, '');

%% Get Wlan configuration session
Wlan = RFmxWlanMXExtension.GetWlanSignalConfiguration(Instr_handle);

%%  Configure RF and trigger settings
Instr_handle.ConfigureFrequencyReference('','PXI_Clk',10*1e6);
Wlan.ConfigureFrequency('',Center_freq);
Wlan.ConfigureReferenceLevel('',Reference_level);
Wlan.ConfigureExternalAttenuation('',ExternalAttenuation);
Wlan.ConfigureIQPowerEdgeTrigger('','0',RFmxWlanMXIQPowerEdgeTriggerSlope.Rising,...
    PowerEdgeTriggerLevel,TriggerDelay,RFmxWlanMXTriggerMinimumQuietTimeMode.Auto,minimumQuietTime...
    ,RFmxWlanMXIQPowerEdgeTriggerLevelType.Relative,TrigEnable);
Wlan.ConfigureStandard('',WlanStandard);
Wlan.ConfigureChannelBandwidth('',ChannelBandwidth);
Wlan.SelectMeasurements('',RFmxWlanMXMeasurementTypes.OfdmModAcc,true);

%%  Configure Measurement settings
Wlan.OfdmModAcc.Configuration.ConfigureMeasurementLength(...
    '',MeasurementOffset,MaximumMeasurementLength);
Wlan.OfdmModAcc.Configuration.ConfigureFrequencyErrorEstimationMethod(...
    '',FrequencyErrorEstimationMethod);
Wlan.OfdmModAcc.Configuration.ConfigurePhaseTrackingEnabled('',PhaseTrackingEnabled);
Wlan.OfdmModAcc.Configuration.ConfigureSymbolClockErrorCorrectionEnabled(...
    '', SymbolClockErrorCorrectionEnabled);
Wlan.OfdmModAcc.Configuration.ConfigureChannelEstimationType('', ChannelEstimationType);
Wlan.OfdmModAcc.Configuration.ConfigureAveraging('',AveragingEnabled,AveragingCount);

%% Initiating Measurements
Wlan.Initiate('','');

%% Retrieving Measurements
[~,RmsEvmMean,DataRmsEvmMean,PilotRmsEvmMean] = Wlan.OfdmModAcc.Results.FetchCompositeRmsEvm('',Timeout)
[~, NumberOfsymbolsUsed] = Wlan.OfdmModAcc.Results.FetchNumberOfSymbolsUsed('',Timeout);
[~, McsIndex] = Wlan.OfdmModAcc.Results.FetchMcsIndex('',Timeout);
[~, GuardIntervalType] = Wlan.OfdmModAcc.Results.FetchGuardIntervalType('',Timeout);
[~, ParityCheckStatus] = Wlan.OfdmModAcc.Results.FetchLSigParityCheckStatus('',Timeout);
[~, SigCRCStatus] = Wlan.OfdmModAcc.Results.FetchSigCrcStatus('',Timeout);
[~, PilotConstellation] = ...                                                % This method requires ref to complexSin Array
    Wlan.OfdmModAcc.Results.FetchPilotConstellationTrace... 
    ('',Timeout,ComplexSingle.ComposeArray(1,1));  
[~, DataConstellation] = ...                                                 % This method requires ref to complexSin Array
    Wlan.OfdmModAcc.Results.FetchDataConstellationTrace... 
    ('',Timeout,ComplexSingle.ComposeArray(1,1));  
[~,RmsEvmPerSubcarrierMean] = Wlan.OfdmModAcc.Results.FetchChainRmsEvmPerSubcarrierMeanTrace('',Timeout,[]);

%% Format data and plot Measurements
[real_data,imaginary_data]= ComplexSingle.DecomposeArray(DataConstellation);
[real_pilot,imaginary_pilot]= ComplexSingle.DecomposeArray(PilotConstellation);
figure;
tiledlayout(2,1);

% Plotting constellations
ax1 = nexttile;
axis equal;
plot(ax1,real_data,imaginary_data,'o',real_pilot,imaginary_pilot,'o'); 
title('Constellation Plot');
xlabel('I');
ylabel('Q');
legend('Data Constellation','Pilot Constellation');

% Plotting RmsEvmPerSubcarrierMean
ax2 = nexttile;
 t0 = RmsEvmPerSubcarrierMean.PrecisionTiming.TimeOffset.TotalSeconds;
 dt = RmsEvmPerSubcarrierMean.PrecisionTiming.SampleInterval.TotalSeconds;
 y = RmsEvmPerSubcarrierMean.GetRawData();
 x_axis = dt*(0:RmsEvmPerSubcarrierMean.SampleCount-1)+t0;
plot(ax2,x_axis,y);
title('Rms Evm Per Subcarrier Mean');
xlabel('Subcarrier Index');
ylabel('EVM (db)');

%% Closing RFmx Session and disposing SMU settings
Instr_handle.Close();
Smu.Dispose();
Smu.Close();