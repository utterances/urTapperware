


function sendValue(val, index)
	local pushflowbox = _G["FBPush"]
	if pushflowbox.instances and pushflowbox.instances[index]  then
		pushflowbox.instances[index]:Push(val)
	end
end