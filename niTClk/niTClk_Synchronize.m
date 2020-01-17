function niTClk_Synchronize(sessions, minTime)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense

	errorCode = calllib('niTClk', 'niTClk_Synchronize', length(sessions), sessions, minTime);
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end