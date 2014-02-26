-- ==========
-- = logger =
-- ==========


Log={}
Log.file = io.open(DocumentPath("out.log"), "w")

function Log:print(text)
	-- DPrint(text)
	
	self.file:write(text..'\n')
	self.file:flush()
end