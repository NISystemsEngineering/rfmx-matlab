If the .NET implementation of TClk throws some errors when calling from MATLAB, use the C functionality
This requires the system to install C make tools (a requirement for MATLAB's loadlibrary functionality), for more information please see https://www.mathworks.com/support/compilers.html

Overall programming flow:
0. load nitclk library using niTClk_LoadLibrary function. Note that niTClk_LoadLibrary.m needs to be in the environment.
1. Get all desired TClk instruments to have IntPtrs. This is typically done using DangerousGetHandle() methods on the .NET session
2. Create a TClk sessions array using all the relevant instrument sesions
    tclkSessions = [uint64(session1), uint64(session2), ... , uint64(sessionN)];
3. You can now replace .NET calls with their C equivalent:

.NET EXAMPLE with 2 RFSG Sessions, rfGenerator and envSession:
    syncDevices = NET.createArray('NationalInstruments.ModularInstruments.ITClockSynchronizableDevice', 2);
    syncDevices(1) = DeviceToSynchronize(rfGenerator).Device;
    syncDevices(2) = DeviceToSynchronize(envSession).Device;

    synchronizer = TClock(syncDevices);
    synchronizer.ConfigureForHomogeneousTriggers();

    syncDevice0 = Item(synchronizer.DevicesToSynchronize, 0);
    syncDevice0.SampleClockDelay = -1.5e-6; 	%offset by -1.5us to allow negative delays
    synchronizer.Synchronize();
    synchronizer.Initiate();

C equivalent:
    tclkSessions = [uint64(rfGenerator), uint64(envSession);
    niTClk_ConfigureForHomogeneousTriggers(tclkSessions);

    {
	niTClk_SetAttributeViReal64(tclkSessions(1), '', NITCLK_ATTR_SAMPLE_CLOCK_DELAY, -1.5e-6);	%offset by -1.5us to allow negative delays
	OR
    niTClk_SetSampleClockDelay(tclkSessions(1), -1.5e-6)    %abstracted funcitonality on top of SetAttribute
    }

    niTClk_Synchronize(tclkSessions, 0.00);
	niTClk_Initiate(tclkSessions);