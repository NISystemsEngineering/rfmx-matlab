function niTClk_Initiate(sessions)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense
	errorCode = calllib('niTClk', 'niTClk_Initiate', ...
        length(sessions), ...
        sessions);
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end