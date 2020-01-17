function [isDone] = niTClk_IsDone(sessions)
	%% Please refer to the equivalent C function in the niTClk documentation for help.
	%% This code is covered under the sample code license at http://ni.com/samplecodelicense
	donePtr = libpointer('logical', 0);
	errorCode = calllib('niTClk', 'niTClk_IsDone', length(sessions), sessions, donePtr);
	isDone = donePtr.Value;
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end