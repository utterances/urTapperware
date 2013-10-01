-- =================
-- = Region Object =
-- =================

-- rewrite of the urVen region code as OO Lua

-- using the prototype facility in lua to do OO, a bit painful yes:

-- ==================
-- = Region Manager =
-- ==================

regions = {}      -- Live Regions
recycledregions = {}  -- Removed Regions
heldRegions = {}

-- Reset region to initial state
function ResetRegion(self) -- customized parameter initialization of region, events are initialized in VRegion()
	self.alpha = 1 --target alpha for animation
	self.menu = nil  --contextual menu
	self.counter = 0 --if this is a counter
	self.isHeld = false -- if the r is held by tap currently
	self.isSelected = false
	self.group = nil

	self.dx = 0  -- compute storing current movement speed, for gesture detection
	self.dy = 0
	x,y = self:Center()
	self.oldx = x
	self.oldy = y
	self.sx = 0
	self.sy = 0
	self.w = INITSIZE
	self.h = INITSIZE

-- event handling
	self.inlinks = {}
	self.outlinks = {}

-- initialize for events and signals
	self.eventlist = {}
	-- self.eventlist["OnTouchDown"] = {HoldTrigger}
	-- self.eventlist["OnTouchUp"] = {DeTrigger}
	self.eventlist["OnDoubleTap"] = {}
	self.eventlist["OnUpdate"] = {} 
	self.eventlist["OnUpdate"].currentevent = nil
 
	self.t:SetBlendMode("BLEND")
	self.tl:SetLabel(self:Name())
	self.tl:SetFontHeight(16)
	self.tl:SetFont("Avenir Next")
	self.tl:SetColor(0,0,0,255)
	self.tl:SetHorizontalAlign("JUSTIFY")
	self.tl:SetVerticalAlign("MIDDLE")
	-- self.tl:SetShadowColor(100,100,100,255)
	-- self.tl:SetShadowOffset(1,1)
	-- self.tl:SetShadowBlur(10)
	self:SetWidth(50)
	self:SetHeight(50)

end

-- Initialize a new region
function CreateRegion(ttype,name,parent,id) -- customized initialization of region
-- add a visual shadow as a second layer
	local r_s = Region(ttype,"drops"..id,parent)
	r_s.t = r_s:Texture("tw_shadow.png")
	r_s.t:SetBlendMode("BLEND")
	r_s:SetWidth(INITSIZE+70)
	r_s:SetHeight(INITSIZE+70)
	--r_s:EnableMoving(true)
	r_s:SetLayer("LOW")
	r_s:Show() 

	local r = Region(ttype,"Region "..id,parent)
	r.tl = r:TextLabel()
	r.t = r:Texture("tw_roundrec.png")
	r:SetLayer("LOW")
	r.shadow = r_s
	r.shadow:SetAnchor("CENTER",r,"CENTER",0,0) 
-- initialize for regions{} and recycledregions{}
	r.usable = 1
	r.id = id
	ResetRegion(r)
	
	r:EnableMoving(true)
	r:EnableResizing(true)
	r:EnableInput(true)

	r:Handle("OnDoubleTap", TWRegion.DoubleTap)
	r:Handle("OnTouchDown", TWRegion.TouchDown)
	r:Handle("OnTouchUp", TWRegion.TouchUp)
	r:Handle("OnUpdate", TWRegion.Update)
	--r:Handle("OnDragging", TWRegion.Move)
	--r:Handle("OnMove", )
	
	return r
end

-- Allocates and returns either a new region or a recycled region
function AllocRegion(ftype, name, parent) --CreateorRecycleregion(ftype, name, parent)
	local region
	--local TapRegion = {}
	if #recycledregions > 0 then
		region = regions[recycledregions[#recycledregions]]
		table.remove(recycledregions)
		region:EnableMoving(true)
		region:EnableResizing(true)
		region:EnableInput(true)
		region.usable = 1
		region.t:SetTexture("tw_roundrec.png") -- reset texture
	else
		region = CreateRegion(ftype, name, parent, #regions+1)
		table.insert(regions,region)
	end
	region:SetAlpha(0)
	region.shadow:SetAlpha(0)
	region:MoveToTop()
	return region
end

function RemoveRegion(self)
	CloseMenu(self)
	
	-- might need to check if links need to be removed TODO:
	ResetRegion(self)
	self:EnableInput(false)
	self:EnableMoving(false)
	self:EnableResizing(false)
	self:Hide()
	self.usable = false
	self.group = nil

	table.insert(recycledregions, self.id)
	DPrint(self:Name().." removed")
end

-- =================
-- = Region Object =
-- =================

TWRegion = {}

function TWRegion.check(self)
	DPrint(self.id)
	toDelete = self.id
end

-- constructor
function TWRegion:new(o, updateEnv)
	o = o or AllocRegion('region','backdrop',UIParent)
	setmetatable(o, self)
	self.__index = self
	o.updateEnv = updateEnv
	return o
end

function TWRegion:AddIncomingLink(l)
	table.insert(self.inlinks,l)
end

function TWRegion:RemoveIncomingLink(l)
	tableRemoveObj(self.inlinks,l)
end

function TWRegion:AddOutgoingLink(l)
	table.insert(self.outlinks,l)
end

function TWRegion:RemoveOutgoingLink(l)
	tableRemoveObj(self.outlinks,l)
end

function TWRegion:SendMessage(sender,message)
-- Respond to incoming message from sender
end

function TWRegion:RaiseToTop()
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
end

function TWRegion:Move(x,y,dx,dy)
	for k,v in pairs(self.outlinks) do
		if(v.event == "OnUpdate_Move") then
			v:SendMessageToReceivers({dx, dy})
		end
	end	

	self.updateEnv()
		-- also update the rest of the group, if needed: TODO change this later
	if self.group ~= nil then
		--DPrint("From Up Group"..self.id..": "..self.dx.." "..self.dy)
		rx,ry = self.group.r:Center()
		self.group.r:SetAnchor('CENTER', rx+self.dx, ry+self.dy)
		
		for i=1, #self.group.regions do
			if self.group.regions[i] ~= self then
				rx,ry = self.group.regions[i]:Center()
				self.group.regions[i].oldx = rx+self.dx -- FIXME: stopgap
				self.group.regions[i].oldy = ry+self.dy
				self.group.regions[i]:SetAnchor('CENTER', rx+self.dx, ry+self.dy)
			end
		end
	end

	self.oldx = x
	self.oldy = y
end

function TWRegion:Update(elapsed)
	-- DPrint(elapsed)
	if self:Alpha() ~= self.alpha then
		if math.abs(self:Alpha() - self.alpha) < EPSILON then -- just set if it's close enough
			self:SetAlpha(self.alpha)
		else
			self:SetAlpha(self:Alpha() + (self.alpha-self:Alpha()) * elapsed/FADEINTIME)
		end
		self.shadow:SetAlpha(self:Alpha())
	end
	x,y = self:Center()

-- move if we have none zero speed
	newx = x
	newy = y
	if self.sx ~= 0 then
		newx = x + self.sx*elapsed
		self.sx = self.sx*0.9
		if self.sx < 2 then
			self.sx = 0
		end
	end

	if self.sy ~= 0 then
		newy = y + self.sy*elapsed
		self.sy = self.sy*0.9
		if self.sy < 2 then
			self.sy = 0
		end
	end
	if self.sy ~= 0 or self.sx ~= 0 then
		-- DPrint(self:Name().." bounced "..self.sx.." "..self.sy)
		self:SetAnchor('CENTER', newx, newy)
		self:EnableInput(true)
	end


-- animate size if needed:
	if self.w ~= self:Width() then
		if math.abs(self:Width() - self.w) < EPSILON then -- close enough
			self:SetWidth(self.w)
		else
			self:SetWidth(self:Width() + (self.w-self:Width()) * elapsed/FADEINTIME)
		end
		self.tl:SetHorizontalAlign("JUSTIFY")
	self.tl:SetVerticalAlign("MIDDLE")
	end

	if self.h ~= self:Height() then
		if math.abs(self:Height() - self.h) < EPSILON then  -- close enough
			self:SetHeight(self.h)
		else
			self:SetHeight(self:Height() + (self.h-self:Height()) * elapsed/FADEINTIME)
		end
		self.tl:SetHorizontalAlign("JUSTIFY")
	self.tl:SetVerticalAlign("MIDDLE")
	end
	-- self:CallEvents("OnUpdate")
	
	
	if self.oldx ~= x or self.oldy ~= y then
		-- if we moved:
		self.updateEnv()
	end
	
	self.oldx = x
	self.oldy = y
end

function TWRegion:CallEvents(signal)
	local list = {}

	-- if current_mode == modes[1] then
	list = self.eventlist[signal]
	-- else
	-- 	list = vv.reventlist[signal]
	-- end
	
	DPrint(signal, list)
	for k = 1,#list do
		list[k](self)
	end
	
	for k,v in pairs(self.outlinks) do
		if(v.event == signal) then
			v:SendMessageToReceivers(signal)
		end
	end
end

function TWRegion:TouchDown()
	self:CallEvents("OnTouchDown")
	-- DPrint("hold for menu")
	self:RaiseToTop()
	self.alpha = .4
	-- isHoldingRegion = true
	table.insert(heldRegions, self)

	-- bring menu up if they are already open
	if self.menu ~= nil then
		RaiseMenu(self)
	end
end

function TWRegion:DoubleTap()
	DPrint("double tapped")
	self:CallEvents("OnDoubleTap")
end

function TWRegion:TouchUp()
	self.alpha = 1
	if initialLinkRegion == nil then
		--DPrint("")
		-- see if we can make links here, check how many regions are held
		if #heldRegions >= 2 then
			-- by default let's just link self and the first one that's different
			for i = 1, #heldRegions do
				if heldRegions[i] ~= self and RegionOverLap(self, heldRegions[i]) then
					initialLinkRegion = self
					EndLinkRegion(heldRegions[i])
					initialLinkRegion = nil
					
					-- initialize bounce back animation, it runs in TWRegion.Update later
					x1,y1 = self:Center()
					x2,y2 = heldRegions[i]:Center()
					EXRATE = 150000
					mx = (x1+x2)/2
					my = (y1+y2)/2
					ds = math.max((x1-x2)^2 + (y1-y2)^2, 400)
					
					self.sx = EXRATE*(x1 - mx)/ds
					self.sy = EXRATE*(y1 - my)/ds
					-- self.tl:SetLabel(self.sx.." "..self.sy)
					heldRegions[i].sx = EXRATE*(x2 - mx)/ds
					heldRegions[i].sy = EXRATE*(y2 - my)/ds
					-- heldRegions[i].tl:SetLabel(heldRegions[i].sx.." "..heldRegions[i].sy)
					-- DPrint(self:Name().." vs "..heldRegions[i]:Name())
					-- temp remove touch input
					-- self:EnableInput(false)
					-- heldRegions[i]:EnableInput(false)
					break
				end
			end
			
		end
		
		tableRemoveObj(heldRegions, self)
		
		-- isHoldingRegion = false
	else
		EndLinkRegion(self)
		initialLinkRegion = nil
	end
	
	self:CallEvents("OnTouchUp")
end

function TWRegion:RaiseToTop()
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
end

function move(self, message)
	x,y = self:Center()
	dx,dy = unpack(message)
	DPrint(dx.." "..dy.." "..x.." "..y)
	self.oldx = x + dx
	self.oldy = y + dy
	self:SetAnchor('CENTER',self.oldx,self.oldy)
end

function MoveLeft(self, message)
	x,y = self:Center()
	self.oldx = x - 10
	self.oldy = y
	self:SetAnchor('CENTER',x-10,y)
	linkLayer:Draw()
end
function MoveRight(self, message)
	x,y = self:Center()
	self.oldx = x + 10
	self.oldy = y
	self:SetAnchor('CENTER',x+10,y)
	linkLayer:Draw()
end

function ControllerTouchDownLeft(self) -- event for OnTouchDown of the controller
    ControllerTouchDown(self)
    MoveLeft(self)
    self:Handle("OnUpdate",TriggerLeft)
end

