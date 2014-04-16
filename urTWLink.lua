-- ===============
-- = link object =
-- ===============

link = {}

function link:new(initialLinkRegion, finishLinkRegion, event, action, data)
	o = {}
	setmetatable(o,self)
	self.__index = self
	o:AddSender(initialLinkRegion)
	o:AddReceiver(finishLinkRegion)
	o.event = event
	o.action = action
	o.data = data or {}
	o.menu = newLinkMenu(o)
	o.origin = false
	linkLayer:Add(o)
	
	Log:print('link created '..initialLinkRegion:Name()..'->'..finishLinkRegion:Name()..' '..event)
	return o
end

function link:AddSender(r)
	-- DPrint("sender set")
	self.sender = r
	r:AddOutgoingLink(self)
end

function link:RemoveSender()
	if self.sender then
		self.sender:RemoveOutgoingLink(self)
		self.sender = nil
	end
end

function link:AddReceiver(r)
	self.receiver = r
	r:AddIncomingLink(self)
end

function link:RemoveReceiver()
	if self.receiver then
		self.receiver:RemoveIncomingLink(self)
		self.receiver = nil
	end
end

function link:destroy()
	DeleteLinkMenu(self.menu)
	Log:print('link deleted '..self.sender:Name()..'->'..self.receiver:Name()..' '..self.event)
	
	
	self.menu = nil
	self:RemoveSender()
	self:RemoveReceiver()
	linkLayer:Remove(self)
	linkLayer:Draw()
	self = nil
end

function link:SendMessageToReceivers(message, origin)
	if self.sender and self.receiver then
		if origin ~= self.receiver.lastMessageOrigin or origin == nil then
			self.receiver.lastMessageOrigin = origin
			self.action(self.receiver, message, self.data)
		end
	end
end
