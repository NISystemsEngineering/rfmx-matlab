function niTClk_WaitUntilDone(sessions, timeout)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense
	errorCode = calllib('niTClk', 'niTClk_WaitUntilDone', length(sessions), sessions, timeout);
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end