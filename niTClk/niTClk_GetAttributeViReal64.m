function [attributeValue] = niTClk_GetAttributeViReal64(session, channelName, attributeId)
	channelName = [int8(channelName) 0];
	attributeValuePtr = libpointer('doublePtr', 0);
	errorCode = calllib('niTClk', 'niTClk_GetAttributeViReal64', session, channelName, attributeId, attributeValuePtr);
	attributeValue = attributeValuePtr.Value;
	if errorCode
		error(niTClk_GetExtendedErrorInfo());
	end
end