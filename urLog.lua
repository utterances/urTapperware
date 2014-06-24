-- ==========
-- = logger =
-- ==========


Log={}

function Log:start()
	local stamp = os.time()
	-- self.file = io.open(DocumentPath("out.log"), "w")
	self.file = io.open(DocumentPath(logs/stamp..".log"), "w")
	self.on = true
end

function Log:stop()
	self.on = false
	self.file:flush()
end

function Log:print(text)
	if Log.on then
		local t = string.format("%.3f", os.clock())
		self.file:write(t..' '..text..'\n')
		self.file:flush()
	end
end