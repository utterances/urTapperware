-- ==========
-- = logger =
-- ==========


Log={}

function Log:start()
	self.file = io.open(DocumentPath("out.log"), "w")
	self.on = true
end

function Log:stop()
	self.on = false
	self.file:flush()
end

function Log:print(text)
	if Log.on then
		local t = os.time()
		self.file:write(t..' '..text..'\n')
		self.file:flush()
	end
end