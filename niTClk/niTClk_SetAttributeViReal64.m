function niTClk_SetAttributeViReal64(session, channelName, attributeId, value)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense
	%% attributeID can be found in the header file
	channelName = [int8(channelName) 0];
	errorCode = calllib('niTClk', 'niTClk_SetAttributeViReal64', ...
        session, ...
        channelName, ...
        attributeId, ...
        value);
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end