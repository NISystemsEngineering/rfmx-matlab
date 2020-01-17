function niTClk_SetSampleClockDelay(session, sampleClockDelay)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense
	%% This function calls niTClk_SetAttributeViReal64 with attributeID = NITCLK_ATTR_SAMPLE_CLOCK_DELAY = 11 and channelName = ''
	NITCLK_ATTR_SAMPLE_CLOCK_DELAY = 11;
	attributeID = NITCLK_ATTR_SAMPLE_CLOCK_DELAY;
	channelName = '';

	%% Below is code from niTClk_SetAttributeViReal64:
	channelName = [int8(channelName) 0];
	errorCode = calllib('niTClk', 'niTClk_SetAttributeViReal64', ...
        session, ...
        channelName, ...
        attributeId, ...
        sampleClockDelay);
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end