-- =================
-- = Region Object =
-- =================

-- rewrite of the urVen region code as OO Lua

-- using the prototype facility in lua to do OO, a bit painful yes:


-- ==================
-- = Region Types   =
-- ==================

RTYPE_BLANK = 0
RTYPE_VAR = 1
RTYPE_SOUND = 2
RTYPE_GROUP = 99

-- ==================
-- = Region Manager =
-- ==================

regions = {}      -- Live Regions
recycledregions = {}  -- Removed Regions
heldRegions = {}

-- ==============
-- = Parameters =
-- ==============
TIME_TO_HOLD = .6	--time to wait to activate hold behaviour (not for hold event)
HOLD_SHIFT_TOR = 2 --pixel to tolerate for holding

-- Reset region to initial state
function ResetRegion(self) -- customized parameter initialization of region, events are initialized in VRegion()
	self.alpha = 1 --target alpha for animation
	self.menu = nil --contextual menu nil when not active
	self.regionType = RTYPE_BLANK	--default blank type
	self.value = 0
	self.isHeld = false -- if the r is held by tap currently
	self.holdTimer = 0
	self.isSelected = false
	self.canBeMoved = true
	self.group = nil

	self.animationPlaying = -1
	-- -1 or 0 for not playing, otherwise increment for each frame
	self.movepath = {}
	self.loopmove = true
	self.shaking = false
	
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
	self.eventlist["OnTouchUp"] = {}
	self.eventlist["OnDoubleTap"] = {ToggleMenu}
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
	self:SetWidth(INITSIZE/3)
	self:SetHeight(INITSIZE/3)
end

-- Initialize a new region
function CreateRegion(ttype,name,parent,id) -- customized initialization of region
-- add a visual shadow as a second layer
	local r_s = Region(ttype,"drops"..id,parent)
	r_s.t = r_s:Texture("tw_shadow.png")
	r_s.t:SetBlendMode("BLEND")
	r_s:SetWidth(INITSIZE + 60)
	r_s:SetHeight(INITSIZE + 60)
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
	r:EnableClamping(true)
	

	r:Handle("OnDoubleTap", TWRegion.DoubleTap)
	r:Handle("OnTouchDown", TWRegion.TouchDown)
	r:Handle("OnTouchUp", TWRegion.TouchUp)
	r:Handle("OnUpdate", TWRegion.Update)
	r:Handle("OnLeave", TWRegion.Leave)
	r:Handle("OnDragging", TWRegion.Drag)
	r:Handle("OnMove", TWRegion.Move)
	r:Handle("OnSizeChanged", TWRegion.SizeChanged)
	
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
	
	-- check if in and out links need to be removed
	for k,v in pairs(self.outlinks) do
		v:destroy()
		CloseLinkMenu(v.menu)
	end
	self.outlinks = {}
	
	for k,v in pairs(self.inlinks) do
		v:destroy()
		CloseLinkMenu(v.menu)
	end
	self.inlinks = {}
	
	ResetRegion(self)
	self:EnableInput(false)
	self:EnableMoving(false)
	self:EnableResizing(false)
	self:Hide()
	self.usable = false
	self.group = nil

	table.insert(recycledregions, self.id)
	notifyView:ShowTimedText(self:Name().." removed")
end

-- =================
-- = Region Object =
-- =================

TWRegion = {}

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

function TWRegion:Copy(cx, cy)
	-- return a copy
	local newRegion = TWRegion:new(nil, updateEnv)
	newRegion:Show()	
	
	if cx ~= nil then
		newRegion:SetAnchor("CENTER", cx, cy)
	else
		newRegion:SetAnchor("CENTER",x+INITSIZE+20,y)
	end
	
	-- copy all links
	for _,v in ipairs(self.inlinks) do
		local link = link:new(v.sender, newRegion, v.event, v.action)
	end
	
	for _,v in ipairs(self.outlinks) do
		local link = link:new(newRegion, v.receiver, v.event, v.action)
	end
	
	newRegion.movepath = self.movepath
	-- copy type and properties
	if self.regionType == RTYPE_VAR then
		newRegion:SwitchRegionType()
		newRegion.value = self.value
		newRegion.tl:SetLabel(newRegion.value)
	else
		newRegion.h = self.h
		newRegion.w = self.w
	end
	
	notifyView:ShowTimedText("Copied")
	return newRegion
end

function TWRegion:Move(x,y,dx,dy)
	DPrint('moving '..dx..' '..dy)
	
	-- for k,v in pairs(self.outlinks) do
	-- 	if(v.event == "_Move") then
	-- 		v:SendMessageToReceivers({dx, dy})
	-- 	end
	-- end	

	self.updateEnv()

	self.oldx = x
	self.oldy = y
end

function TWRegion:StartAnimation()
	
end

function TWRegion:Drag(x,y,dx,dy,e)
	
	if math.abs(dx) > HOLD_SHIFT_TOR or math.abs(dy) > HOLD_SHIFT_TOR then
		self.isHeld = false	-- cancel hold gesture if over tolerance
	end
	gestureManager:Dragged(self, dx, dy, x, y)
	self.holdTimer = 0
	self.updateEnv()
	
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

	-- movements if we are playing back animation
	if self.animationPlaying > 0 then
		local delta = self.movepath[self.animationPlaying]
		
		-- DPrint(delta(dx)..','..delta(dy))
		self:SetAnchor('CENTER',x+delta(dx),y+delta(dy))
		
		if self.animationPlaying < #self.movepath then
			self.animationPlaying = self.animationPlaying + 1
		else
			if self.loopmove then
				self.animationPlaying = 1
			else
				self.animationPlaying = -1
				self.movepath = {}
				self.updateEnv()
			end
		end
	end
	
	if self.shaking then
		-- self.t:SetRotation(math.random(-1, 1))
		self:SetAnchor('CENTER',self.oldx+math.random(-1,1),
										self.oldy+math.random(-1,1))
	end
-- move if we have none zero speed
	-- newx = x
	-- newy = y
	-- if self.sx ~= 0 then
	-- 	newx = x + self.sx*elapsed
	-- 	self.sx = self.sx*0.9
	-- 	if self.sx < 2 then
	-- 		self.sx = 0
	-- 	end
	-- end
	-- 
	-- if self.sy ~= 0 then
	-- 	newy = y + self.sy*elapsed
	-- 	self.sy = self.sy*0.9
	-- 	if self.sy < 2 then
	-- 		self.sy = 0
	-- 	end
	-- end
	-- if self.sy ~= 0 or self.sx ~= 0 then
	-- 	-- DPrint(self:Name().." bounced "..self.sx.." "..self.sy)
	-- 	self:SetAnchor('CENTER', newx, newy)
	-- 	self:EnableInput(true)
	-- end


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
	
	self:CallEvents("OnUpdate", elapsed)
	if self.isHeld then
		
		if self.holdTimer > TIME_TO_HOLD then
			-- do hold action here
			self:CallEvents("OnTapAndHold", elapsed)
			
			gestureManager:StartHold(self)
		else
			self.holdTimer = self.holdTimer + elapsed
		end
		-- self:CallEvents("OnTapAndHold", elapsed)
	end
		
	-- if self.oldx ~= x or self.oldy ~= y then
	-- 	-- if we moved:
	-- 	self.updateEnv()
	-- end
	-- 
	-- self.oldx = x
	-- self.oldy = y
end

function TWRegion:CallEvents(signal, elapsed)
	local list = {}

	-- if current_mode == modes[1] then
	list = self.eventlist[signal]
	-- else
	-- 	list = vv.reventlist[signal]
	-- end
	
	if list~=nil then
		for k = 1,#list do
			list[k](self)
		end
	end
	
	for k,v in pairs(self.outlinks) do
		if(v.event == signal) then
			elapsed = elapsed or signal
			v:SendMessageToReceivers(elapsed)
		end
	end
end

function TWRegion:TouchDown()
	self.isHeld = true
	self.holdTimer = 0
	self:CallEvents("OnTouchDown")
	self:RaiseToTop()
	self.alpha = .6
	-- isHoldingRegion = true
	table.insert(heldRegions, self)

	-- bring menu up if they are already open
	if self.menu ~= nil then
		RaiseMenu(self)
	end
end

function TWRegion:DoubleTap()
	if self.regionType ~= RTYPE_GROUP then
		self:CallEvents("OnDoubleTap")
	end
end

function TWRegion:TouchUp()
	
	if self.isHeld and self.holdTimer < TIME_TO_HOLD then
		-- a true tap without moving/dragging
		gestureManager:Tapped(self)
	else
		gestureManager:TouchUp(self)
	end
	self.isHeld = false
	
	self.holdTimer = 0
	self.alpha = 1

	if initialLinkRegion == nil then
		--DPrint("")
		-- see if we can make links here, check how many regions are held
		-- if #heldRegions >= 2 then
		-- 	-- by default let's just link self and the first one that's different
		-- 	for i = 1, #heldRegions do
		-- 		if heldRegions[i] ~= self and RegionOverLap(self, heldRegions[i]) then
		-- 			initialLinkRegion = self
		-- 			EndLinkRegion(heldRegions[i])
		-- 			initialLinkRegion = nil
		-- 			
		-- 			-- initialize bounce back animation, it runs in TWRegion.Update later
		-- 			x1,y1 = self:Center()
		-- 			x2,y2 = heldRegions[i]:Center()
		-- 			EXRATE = 150000
		-- 			mx = (x1+x2)/2
		-- 			my = (y1+y2)/2
		-- 			ds = math.max((x1-x2)^2 + (y1-y2)^2, 400)
		-- 			
		-- 			self.sx = EXRATE*(x1 - mx)/ds
		-- 			self.sy = EXRATE*(y1 - my)/ds
		-- 			-- self.tl:SetLabel(self.sx.." "..self.sy)
		-- 			heldRegions[i].sx = EXRATE*(x2 - mx)/ds
		-- 			heldRegions[i].sy = EXRATE*(y2 - my)/ds
		-- 			-- heldRegions[i].tl:SetLabel(heldRegions[i].sx.." "..heldRegions[i].sy)
		-- 			-- DPrint(self:Name().." vs "..heldRegions[i]:Name())
		-- 			-- temp remove touch input
		-- 			-- self:EnableInput(false)
		-- 			-- heldRegions[i]:EnableInput(false)
		-- 			break
		-- 		end
		-- 	end
		-- end
		
		tableRemoveObj(heldRegions, self)
		
		-- isHoldingRegion = false
	else
		-- EndLinkRegion(self)
		initialLinkRegion = nil
	end
	
	self:CallEvents("OnTouchUp")
end

function TWRegion:Leave()
	self.isHeld = false
	self.holdTimer = 0
end

function TWRegion:RaiseToTop()
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
end

function TWRegion:SizeChanged()
	-- the user changed the size, so let's fix it 
	self.w = self:Width()
	self.h = self:Height()
end

function TWRegion:SwitchRegionType() -- TODO: change method name to reflect
	if self.regionType == RTYPE_GROUP then
		return
	end
	
	if self.regionType == RTYPE_BLANK then
		-- switch from normal region to a counter
		self.t:SetTexture("tw_roundrec_slate.png")
		-- self.tl = self:TextLabel()
		self.tl:SetLabel(self.value)
		self.tl:SetFontHeight(42)
		self.tl:SetColor(255,255,255,255) 
		self.tl:SetHorizontalAlign("JUSTIFY")
		self.tl:SetVerticalAlign("MIDDLE")
		-- self.tl:SetShadowColor(10,10,10,255)
		-- self.tl:SetShadowOffset(1,1)
		-- self.tl:SetShadowBlur(1)
		self:EnableResizing(false)
		self.w = INITSIZE
		self.h = INITSIZE
		self.regionType = RTYPE_VAR
		
	elseif self.regionType == RTYPE_VAR then
		
		self.tl:SetLabel(self:Name())		
		self.t:SetTexture("tw_roundrec.png")
		self.tl:SetFontHeight(16)
		self.tl:SetColor(0,0,0,255)
		self.tl:SetHorizontalAlign("JUSTIFY")
		self.tl:SetVerticalAlign("MIDDLE")
		-- self:EnableResizing(true)
		self.regionType = RTYPE_SOUND
		
	-- 	
	-- 	
	-- elseif self.regionType == RTYPE_SOUND then
		self:EnableResizing(true)
		self.regionType = RTYPE_BLANK	
	end
	
	CloseMenu(self)
end

function TWRegion:ToggleAnchor()
	notifyView:ShowTimedText("toggle movement")
	self.canBeMoved = not self.canBeMoved
	self:EnableMoving(self.canBeMoved)
end

-- #################################################################
-- #################################################################

function TWRegion:PlayAnimation(_, linkdata)
	-- DPrint('starting playback '..#self.movepath)
	self.movepath = linkdata
	if #self.movepath > 0 then
		if self.loopmove then
			if self.animationPlaying > 0 then
				self.animationPlaying = -1
				return
			end
		end
		self.animationPlaying = 1
	end
end
	

function AddOneToCounter(self)
	if self.regionType == RTYPE_VAR then
		self.value = self.value + 1
		self.tl:SetLabel(self.value)
	end
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
	e = tonumber(message) or 2	
	x,y = self:Center()
	self.oldx = x - 5*e
	self.oldy = y
	self:SetAnchor('CENTER',x-10,y)
	linkLayer:Draw()
end
function MoveRight(self, message)
	e = tonumber(message) or 2
	x,y = self:Center()
	self.oldx = x + 5*e
	self.oldy = y
	self:SetAnchor('CENTER',x+10,y)
	linkLayer:Draw()
end

function ControllerTouchDownLeft(self) -- event for OnTouchDown of the controller
    ControllerTouchDown(self)
    MoveLeft(self)
    self:Handle("OnUpdate",TriggerLeft)
end

