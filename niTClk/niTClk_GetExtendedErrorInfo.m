function errorDescription = niTClk_GetExtendedErrorInfo()
	bufferSize = calllib('niTClk', 'niTClk_GetExtendedErrorInfo', [], 0);
    errorDescription = libpointer('int8Ptr', zeros(1, bufferSize, 'int8'));
    errorCode = calllib('niTClk', 'niTClk_GetExtendedErrorInfo', errorDescription, bufferSize);
    errorDescription = char(errorDescription.Value);
    if errorCode
        error(niTClk_GetExtendedErrorInfo());
    end
end