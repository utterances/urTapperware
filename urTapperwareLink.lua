-- ===============================
-- = Visual Links between regions=
-- ===============================

-- methods and appearances and menus for deleting / editing
-- assumes urTapperwareMenu.lua is already processed


link = {}

function link:new(initialLinkRegion,finishLinkRegion,event,action)
	o = {}
	setmetatable(o,self)
	self.__index = self
	o:AddSender(initialLinkRegion)
	o:AddReceiver(finishLinkRegion)
	o.event = event
	o.action = action
	o.menu = newLinkMenu(o)
	linkLayer:Add(o)	
	return o
end

function link:AddSender(r)
	DPrint("sender set")
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
	deleteLinkMenu(self.menu)
	self.menu = nil
	self:RemoveSender()
	self:RemoveReceiver()
	linkLayer:Remove(self)
	linkLayer:Draw()
	self = nil
end

function link:SendMessageToReceivers(message)
	if self.sender and self.receiver then
	--DPrint("From Link: "..message[1].." "..message[2])
		self.action(self.receiver, message)
	end
end
