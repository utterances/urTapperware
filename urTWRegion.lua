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
SHADOW_MARGIN = 60
TIME_TO_HOLD = 0.75	--time to wait to activate hold behaviour (not for hold event)
HOLD_SHIFT_TOR = 2 --pixel to tolerate for holding

-- Reset region to initial state
function ResetRegion(self) -- customized parameter initialization of region, events are initialized in VRegion()
	self.alpha = 1 --target alpha for animation
	self.menu = nil --contextual menu nil when not active
	self.regionType = RTYPE_BLANK	--default blank type
	self.value = {0}
	self.isHeld = false -- if the r is held by tap currently
	self.holdTimer = 0
	self.isSelected = false
	self.canBeMoved = true
	self.group = nil
	self.textureFile = nil

	self.animationPlaying = -1
	-- -1 or 0 for not playing, otherwise increment for each frame
	self.movepath = {}
	self.rx = 0
	self.ry = 0
	self.loopmove = false
	self.shaking = false
	
	self.dx = 0  -- compute storing current movement speed, for gesture detection
	self.dy = 0
	local x,y = self:Center()
	self.oldx = x
	self.oldy = y
	self.x = x
	self.y = y
	self.relativeX = 0
	self.relativeY = 0
	self.w = INITSIZE
	self.h = INITSIZE
	self.oldw = self.w
	self.oldh = self.h

-- event handling
	self.inlinks = {}
	self.outlinks = {}
	self.lastMessageOrigin = {}

-- initialize for events and signals
	-- self.eventlist = {}
	-- self.eventlist["OnTouchDown"] = {HoldTrigger}
	-- self.eventlist["OnTouchUp"] = {}
	-- self.eventlist["OnDoubleTap"] = {ToggleMenu}
	-- self.eventlist["OnUpdate"] = {} 
	-- self.eventlist["OnUpdate"].currentevent = nil
	
	self.t:SetBlendMode("BLEND")
	self.tl:SetLabel(self:Name())
	self.tl:SetFontHeight(26)
	self.tl:SetFont("Avenir Next")
	self.tl:SetColor(0,0,0,255)
	-- self.tl:SetHorizontalAlign("CENTER")
	self.tl:SetVerticalAlign("MIDDLE")
	-- self.tl:SetShadowColor(100,100,100,255)
	-- self.tl:SetShadowOffset(1,1)
	-- self.tl:SetShadowBlur(5)
	self:SetWidth(INITSIZE/3)
	self:SetHeight(INITSIZE/3)
	
	self:EnableMoving(true)
	self:EnableResizing(true)
	self:EnableInput(true)
	self:EnableClamping(true)

	self.usable = true
	self.t:SetTexture("tw_roundrec.png") -- reset texture
	self.shadow:Show()
	
	self:Handle("OnDoubleTap", TWRegion.OnDoubleTap)
	self:Handle("OnTouchDown", TWRegion.OnTouchDown)
	self:Handle("OnTouchUp", TWRegion.OnTouchUp)
	self:Handle("OnUpdate", TWRegion.Update)
	self:Handle("OnLeave", TWRegion.OnLeave)
	self:Handle("OnDragging", TWRegion.OnDrag)
	self:Handle("OnMove", TWRegion.OnMove)
	self:Handle("OnSizeChanged", TWRegion.OnSizeChanged)
	self:Handle("OnHorizontalScroll", TWRegion.OnHScroll)
end


-- Initialize a new region
function CreateRegion(ttype,name,parent,id) -- customized initialization of region
-- add a visual shadow as a second layer
	local r_s = Region(ttype,"drops"..id,parent)
	r_s.t = r_s:Texture("tw_shadow.png")
	r_s.t:SetBlendMode("BLEND")
	r_s:SetWidth(INITSIZE + SHADOW_MARGIN)
	r_s:SetHeight(INITSIZE + SHADOW_MARGIN)
	r_s:SetLayer("LOW")
	r_s:Show() 

	local r = Region(ttype,'R'..id,parent)
	r.tl = r:TextLabel()
	r.t = r:Texture("tw_roundrec.png")
	r:SetLayer("LOW")
	r.shadow = r_s
	r.shadow:SetAnchor("CENTER",r,"CENTER",0,0) 
-- initialize for regions{} and recycledregions{}
	r.id = id
	
	return r
end

-- Allocates and returns either a new region or a recycled region
function AllocRegion(ftype, name, parent) --CreateorRecycleregion(ftype, name, parent)
	local region
	--local TapRegion = {}
	if #recycledregions > 0 then
		region = regions[recycledregions[#recycledregions]]
		table.remove(recycledregions)
	else
		region = CreateRegion(ftype, name, parent, #regions+1)
		table.insert(regions,region)
	end
	ResetRegion(region)
	
	region:SetAlpha(0)
	region.shadow:SetAlpha(0)
	region:MoveToTop()
	return region
end

function DisableRegion(self)
	self:EnableInput(false)
	self:EnableMoving(false)
	self:EnableResizing(false)
	self:Hide()
	self.usable = false
	self.group = nil
	
	self:Handle("OnDoubleTap", nil)
	self:Handle("OnTouchDown", nil)
	self:Handle("OnTouchUp", nil)
	self:Handle("OnUpdate", nil)
	self:Handle("OnLeave", nil)
	self:Handle("OnDragging", nil)
	self:Handle("OnMove", nil)
	self:Handle("OnSizeChanged", nil)
end

function RemoveRegion(self)
	CloseMenu(self)
	Log:print(self:Name()..' removed')
	
	if self.regionType == RTYPE_GROUP then
		-- remove all the children if needed
		for _,r in pairs(self.groupObj.regions) do
			RemoveRegion(r)
		end
		
		self.groupObj:Destroy()
	end
		
	-- check if in and out links need to be removed
	for _,v in pairs(self.outlinks) do
		v:destroy()
	end
	self.outlinks = {}
	
	for _,v in pairs(self.inlinks) do
		v:destroy()
	end
	self.inlinks = {}
	
	DisableRegion(self)

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
	Log:print(o:Name()..' created')
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

function TWRegion:HasLinkTo(r, linkEvent)
	-- see if there exist a link to region r
	for _,link in ipairs(self.outlinks) do
		if (link.receiver == r) then
			if linkEvent ~= nil then
				if link.event == linkEvent then
					return true
				end
			else
				return true
			end
		end
	end
	return false
end

-- function TWRegion:SendMessage(sender,message)
-- -- Respond to incoming message from sender
-- end

function TWRegion:RaiseToTop()
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
end

-- creates a copy and return it, groupregion optional
function TWRegion:Copy(cx, cy, groupregion)
	
	if self.regionType == RTYPE_GROUP then
		notifyView:ShowTimedText('Copying Group')
		-- copy all the group's child, then regroup them and move to new place
		local newRegions = {}	
		for _,r in ipairs(self.groupObj.regions) do
			-- find position delta first
			local x,y = self:Center()
			local x2,y2 = r:Center()
			
			table.insert(newRegions, r:Copy(cx+x2-x,cy+y2-y, self))
		end
	
		-- create inner links here, use region list as a map
		-- FIXME: needs deduplication of inner links
		
		for _,r in ipairs(self.groupObj.regions) do
			
			for _,link in ipairs(r.inlinks) do
				local i = tableIndexOf(self.groupObj.regions, link.sender)
				if i>0 then
					local j = tableIndexOf(self.groupObj.regions, r)
					
					local newlink = link:new(newRegions[i], newRegions[j], link.event, link.action)
					newlink.data = link.data
				end
			end
	
		end
				
		local group_copy = ToggleLockGroup(newRegions)
		group_copy.r.h = self:Height()
		group_copy.r.w = self:Width()
		group_copy.r:LoadTexture(self.textureFile)

		Log:print(self.groupObj.regions[1]:Name()..' copied group to '..group_copy.r:Name())

		return group_copy
	end
	
	local newRegion = TWRegion:new(nil, updateEnv)
	newRegion:Show()	
	
	if cx ~= nil then
		-- newRegion:SetAnchor("CENTER",cx,cy)
		newRegion:SetPosition(cx, cy)
	else
		newRegion:SetAnchor("CENTER",x+INITSIZE+20,y)
	end
	
	-- copy all links
	for _,link in ipairs(self.inlinks) do
		if not (groupregion and link.sender.group == groupregion.groupObj) then
			local newlink = link:new(link.sender, newRegion, link.event, link.action)
			newlink.data = link.data
		end
	end
	
	for _,link in ipairs(self.outlinks) do
		if not (groupregion and link.receiver.group == groupregion.groupObj) then
			local newlink = link:new(newRegion, link.receiver, link.event, link.action)
			newlink.data = link.data
		end
	end
	
	newRegion.movepath = self.movepath
	-- newRegion.canBeMoved = self.canBeMoved
	-- copy type and properties
	if self.regionType == RTYPE_VAR then
		newRegion:SwitchRegionType()
		newRegion.value = self.value
		newRegion.tl:SetLabel(newRegion.value)
		newRegion.tl:SetLabel(0)
	else
		newRegion:LoadTexture(self.textureFile)
		newRegion.h = self.h
		newRegion.w = self.w
	end
	
	notifyView:ShowTimedText("Copied")
	Log:print(self:Name()..' copied to '..newRegion:Name())
	
	return newRegion
end

function TWRegion:OnMove(x,y,dx,dy)
	
	-- DPrint('moved on '..x..' '..y)
	-- for k,v in pairs(self.outlinks) do
	-- 	if(v.event == "_Move") then
	-- 		v:SendMessageToReceivers({dx, dy})
	-- 	end
	-- end

	self.updateEnv()

	self.oldx = x
	self.oldy = y
end

function TWRegion:OnDrag(x,y,dx,dy,e)
	-- x,y current pos after the drag
	-- dx dy change in the last e seconds
	-- Log:print('drag '..self:Name()..' '..x..' '..y)
	if math.abs(dx) > HOLD_SHIFT_TOR or math.abs(dy) > HOLD_SHIFT_TOR then
		self.isHeld = false	-- cancel hold gesture if over tolerance
	end
	
	self.dx = dx
	self.dy = dy
	local ndx, ndy
	
	if not (gestureManager:IsMultiTouch(self) or gestureManager:IsGestMenuOpen()) then
		ndx, ndy = self:ClampedMovement(x-dx, y-dy, dx, dy)
	else
		ndx, ndy = dx, dy
	end
	
	if self.group ~= nil then
		if ndx~=dx or ndy~=dy then
		-- need to undo the move here, should only be ones in a group
			self:SetAnchor('CENTER', self.group.r, 'CENTER', x-dx+ndx - self.group.r.x, y-dy+ndy - self.group.r.y)
		-- else
			-- self:SetAnchor('CENTER', self.group.r, 'CENTER', x - self.group.r.x, y - self.group.r.y)
		elseif gestureManager:IsMultiTouch(self) then
			self:SetAnchor('CENTER', x,y)
		end
	end
	
	self:UpdateRelativePos()
	
	if self.group ~= nil then
		-- if GestureMode then
		-- 	if self.relativeX > 1.05 or self.relativeX < -1.05 then
		-- 		bubbleView:ShowEvent('crossing boundary', self, true)
		-- 	end
		-- 
		-- 	if self.relativeY > 1.05 or self.relativeY < -1.05 then
		-- 		bubbleView:ShowEvent('crossing boundary', self, true)
		-- 	end
		-- end
	else
		-- not in a group
		if not self.canBeMoved then
			-- ok this should actually not print at all, just to be sure
			DPrint('tries to move but fail')
		end
	end
	
	gestureManager:Dragged(self, dx, dy, x, y)
	
	self.holdTimer = 0
	self.updateEnv()
	self.oldx = self.x
	self.oldy = self.y
	self.x = x
	self.y = y
	
	Log:print(self:Name()..' drag '..self.x..' '..self.y)
	
	local message = {ndx, ndy, self.relativeX, self.relativeY}
	self.lastMessageOrigin = message
	-- use same table twice, 2nd time as the origin marker to avoid loops
	self:CallEvents('OnDragging', message, message)
end

function TWRegion:Update(elapsed)
	if self:Alpha() ~= self.alpha then
		if math.abs(self:Alpha() - self.alpha) < EPSILON then -- just set if it's close enough
			self:SetAlpha(self.alpha)
		else
			self:SetAlpha(self:Alpha() + (self.alpha-self:Alpha()) * elapsed/FADEINTIME)
		end
		self.shadow:SetAlpha(self:Alpha())
	end
	local x,y = self:Center()

	-- movements if we are playing back animation
	if self.animationPlaying > 0 then
		local delta = self.movepath[self.animationPlaying]
		
		self:SetAnchor('CENTER',x+delta(deltax),y+delta(deltay))
		self:CallEvents('OnDragging', {delta(deltax), delta(deltay)})
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
		self:SetAnchor('CENTER',self.oldx+math.random()*2-1, self.oldy+math.random()*2-1)
		
		-- self.t:SetRotation(math.random(-1, 1))
		-- if self.dx == 0 and self.dy == 0 then
		-- 	self.dx = math.random(-10, 10)*100
		-- 	self.dy = math.random(-10, 10)*100
		-- 	self.oldx = x
		-- 	self.oldy = y
		-- end
		-- 
		-- self:SetAnchor('CENTER',x+self.dx*elapsed, y+self.dy*elapsed)
		-- 
		-- x,y has current value
		-- self.dx = self.dx + (self.oldx - x)*elapsed
		-- self.dy = self.dy + (self.oldy - y)*elapsed
		
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
	local sizeChanged = false
	if self.w ~= self:Width() then
		if math.abs(self:Width() - self.w) < EPSILON then -- close enough
			self:SetWidth(self.w)
		else
			self:SetWidth(self:Width() + (self.w-self:Width()) * elapsed/FADEINTIME)
		end
		sizeChanged = true
	end
	
	if self.h ~= self:Height() then
		if math.abs(self:Height() - self.h) < EPSILON then  -- close enough
			self:SetHeight(self.h)
		else
			self:SetHeight(self:Height() + (self.h-self:Height()) * elapsed/FADEINTIME)
		end
		sizeChanged = true
	end

	if sizeChanged then
		self.tl:SetHorizontalAlign("JUSTIFY")
		self.tl:SetVerticalAlign("MIDDLE")
		self.shadow:SetWidth(self.w + SHADOW_MARGIN)
		self.shadow:SetHeight(self.h + SHADOW_MARGIN)
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
	end
	
	-- -- animate move if we are not at x,y
	-- if self.x ~= x or self.y ~= y then
	-- 	if math.abs(self.x - x) < EPSILON and math.abs(self.y - y) < EPSILON then
	-- 		self:SetAnchor('CENTER', self.x, self.y)
	-- 	else
	-- 		local newx = self.x + (self.x - x)*elapsed/FADEINTIME
	-- 		local newy = self.y + (self.y - y)*elapsed/FADEINTIME
	-- 		self:SetAnchor('CENTER', newx, newy)
	-- 	end
	-- end
	
	-- if self.oldx ~= x or self.oldy ~= y then
	-- 	local oldoldx = self.oldx
	-- 	local oldoldy = self.oldy
	-- 	self.x = x
	-- 	self.y = y
	-- end
end

function TWRegion:OnTouchDown()
	self.rx, self.ry = self:Center()
	Log:print(self:Name()..' touchdown '..self.rx..' '..self.ry)
	gestureManager:BeginGestureOnRegion(self)
	if self.regionType == RTYPE_GROUP then
		self.isHeld = true
		self.holdTimer = -1
		return
	end
	
	self.isHeld = true
	self.holdTimer = 0
	self:CallEvents("OnTouchDown")
	self:RaiseToTop()
	self.alpha = .9
	-- isHoldingRegion = true
	-- table.insert(heldRegions, self)

	-- bring menu up if they are already open
	if self.menu ~= nil then
		RaiseMenu(self)
	end
end

function TWRegion:OnDoubleTap()
	Log:print(self:Name()..' doubletap '..self.x..' '..self.y)
	self:CallEvents("OnDoubleTap")
	if InputMode == 3 then
		self:ToggleMovement()
		
		if self.menu ~= nil then
			CloseMenu(self)
		end
		OpenRegionMenu(self)
	end 
	-- bubbleView:ShowEvent('Double Tap', self)
	-- self:ToggleMenu()
end

function TWRegion:OnTouchUp()
	Log:print(self:Name()..' touchup '..self.x..' '..self.y)
	gestureManager:EndGestureOnRegion(self)
	if self.isHeld and self.holdTimer < TIME_TO_HOLD then
		-- a true tap without moving/dragging
		gestureManager:Tapped(self)
		self:ToggleMenu()
	else
		gestureManager:EndHold(self)
	end
	
	self.isHeld = false
	
	self.holdTimer = 0
	self.alpha = 1

	if self.regionType == RTYPE_GROUP then
		return
	end

	-- if initialLinkRegion == nil then
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
		
		-- tableRemoveObj(heldRegions, self)
		-- isHoldingRegion = false
	-- else
		-- EndLinkRegion(self)
	-- 	initialLinkRegion = nil
	-- end
	
	self:CallEvents("OnTouchUp")
	
	-- if self.group ~=nil then
	-- 	self:ReanchorToGroup()
	-- 	-- see if we need to reanchor to group region
	-- end
	
end

function TWRegion:OnLeave()
	gestureManager:Leave(self)
	self.isHeld = false
	self.holdTimer = 0
end

function TWRegion:RaiseToTop()
	if self.canBeMoved then
		self.shadow:MoveToTop()
		self.shadow:SetLayer("LOW")
		self:MoveToTop()
		self:SetLayer("LOW")
	end
end

function TWRegion:OnSizeChanged()
	-- the user changed the size, so let's fix it 
	-- DPrint('size changed')
	self.w = self:Width()
	self.h = self:Height()
	self.shadow:SetWidth(self.w + SHADOW_MARGIN)
	self.shadow:SetHeight(self.h + SHADOW_MARGIN)
	Log:print(self:Name()..' resized '..self.w..' '..self.h)
end

function TWRegion:CallEvents(signal, messageData, setOrigin)
	-- local list = {}
	-- 
	-- list = self.eventlist[signal]
	-- -- DPrint(#list..' '..signal)
	-- 
	-- 
	-- if list~=nil and #list>0 then
	-- 	for k = 1,#list do
	-- 		list[k](self)
	-- 	end
	-- end
	
	-- TODO: remove legacy above^^
	
	local origin = setOrigin
	-- if signal == 'OnDragging' then
	-- 	for _, inlink in pairs(self.inlinks) do
	-- 		if inlink.event == signal and inlink.origin ~= nil then
	-- 			origin = inlink.origin
	-- 		end
	-- 	end
	-- end
	
	for k,v in pairs(self.outlinks) do
		if(v.event == signal) then
			local send = true
			
			-- if signal == 'OnDragging' then
			-- 	for _, inlink in pairs(self.inlinks) do
			-- 		if inlink.event == signal and inlink.origin == v.receiver then
			-- 			send = false
			-- 			inlink.origin = nil
			-- 		end
			-- 	end
			-- end
			
			if send then
				messageData = messageData or signal
				
				v:SendMessageToReceivers(messageData, origin)
			end
		end
	end
end

-- #################################################################
-- #################################################################

function TWRegion:SwitchRegionType() -- TODO: change method name to reflect
	if self.regionType == RTYPE_GROUP then
		return
	end
	
	if self.regionType == RTYPE_BLANK then
		-- switch from normal region to a counter
		self.t:SetTexture("tw_roundrec_slate.png")
		-- self.tl = self:TextLabel()
		self.value = {0}
		self.tl:SetLabel(self.value[1])
		self.tl:SetFontHeight(32)
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
		self.tl:SetFontHeight(26)
		self.tl:SetColor(0,0,0,255)
		self.tl:SetHorizontalAlign("JUSTIFY")
		self.tl:SetVerticalAlign("MIDDLE")
		self:EnableResizing(true)
		-- self.regionType = RTYPE_SOUND
		
	-- 	
	-- 	
	-- elseif self.regionType == RTYPE_SOUND then
		self.regionType = RTYPE_BLANK	
	end
	
	CloseMenu(self)
end

function TWRegion:ToggleMovement()
	notifyView:ShowTimedText("toggled movement")
	self.canBeMoved = not self.canBeMoved
	if self.group==nil then
		self:EnableMoving(self.canBeMoved)
	end
end

function TWRegion:LoadTexture(filename)
	if filename ~= nil then
		self.textureFile = filename
		self.t:SetTexture(filename)
		self.tl:SetLabel('')
		self.shadow:Hide()
		notifyView:ShowTimedText("texture changed to "..filename)
		Log:print(self:Name()..' texture changed '..filename)
	end
end

-- right now just sets new position directly
-- does not trigger move event
-- TODO: make this animate movement
function TWRegion:SetPosition(x, y, noevent)
	if self.group == nil then
		self:SetAnchor('CENTER', x, y)
		self.oldx = x
		self.oldy = y
	else
		self:SetAnchor('CENTER', self.group.r, 'CENTER', 
			x - self.group.r.x, y - self.group.r.y)
	end
	
	if not noevent then
		self.x = x
		self.y = y
		self:UpdateRelativePos()
	end
end

function TWRegion:ToggleMenu()
	if self.menu == nil then
		OpenRegionMenu(self)
	else
		CloseMenu(self)
	end
	self.updateEnv()
end

function TWRegion:RemoveFromGroup()
	if menu~=nil then
		menu:dismiss()
		-- menu=nil
	end
	if self.group then
		self.group:RemoveRegion(self)
		notifyView:ShowTimedText('removed '..self:Name()..' from group')
	end
	
	if self.menu ~=nil then
		CloseMenu(self)
		OpenRegionMenu(self)
	end
end

function TWRegion:ExistLinkBetween(other)
	for _,link in ipairs(self.outlinks) do
		if link.receiver == other then
			return true
		end
	end

	for _,link in ipairs(self.inlinks) do
		if link.sender == other then
			return true
		end
	end
end

-- #################################################################
-- #################################################################

-- updates relative position
function TWRegion:UpdateRelativePos()
	if self.group ~= nil then
		-- also anchor movement here within group
		self.relativeX = (self.x - self.group.r.x)/(self.group.r.w - self.w)*2
		self.relativeY = (self.y - self.group.r.y)/(self.group.r.h - self.h)*2
	else
		self.relativeX = (self.x - ScreenWidth()/2)/(ScreenWidth()-self.w)*2
		self.relativeY = (self.y - ScreenHeight()/2)/(ScreenHeight()-self.h)*2
	end
end

-- private helper to clamp movement
-- check if dx dy is possible
-- return the clampped deltas, (ndx, ndy)
-- does _NOT_ actually do the anchoring.moving
function TWRegion:ClampedMovement(oldx,oldy,dx,dy)
	if self.group ~= nil then
		local ndx = dx
		local ndy = dy
		-- also anchor movement here within group
		-- if not self.canBeMoved then
			if oldx+dx + self.w/2 > self.group.r.x + self.group.r.w/2 then
				ndx = self.group.r.x + self.group.r.w/2 - oldx - self.w/2
			elseif oldx+dx - self.w/2 < self.group.r.x - self.group.r.w/2 then
				ndx = self.group.r.x - self.group.r.w/2 - oldx + self.w/2
			end
			
			if oldy+dy + self.h/2 > self.group.r.y + self.group.r.h/2 then
				ndy = self.group.r.y + self.group.r.h/2 - oldy - self.h/2
			elseif oldy+dy - self.h/2 < self.group.r.y - self.group.r.h/2 then
				ndy = self.group.r.y - self.group.r.h/2 - oldy + self.h/2
			end
		-- end
		return ndx,ndy
	else
		return dx, dy
	end
end

function TWRegion:ReanchorToGroup()
	assert(self.group~=nil)
	_, relativeToRegion = self:Anchor()
	if relativeToRegion ~= self.group.r then
		-- DPrint('reanchoring')
		-- re anchor:
		self:SetAnchor('CENTER', self.group.r, 'CENTER', self.x - self.group.r.x, self.y - self.group.r.y)
	end
end

function TWRegion:PlayAnimation(_, linkdata)
	self.movepath = linkdata
	if #self.movepath > 0 then
		if self.loopmove then
			if self.animationPlaying > 0 then
				self.animationPlaying = -1
				self.updateEnv()
				return
			end
		end
		self.animationPlaying = 1
	end
end
	
function TWRegion:AnimateShaking(shake)
	if shake then
		self.oldx, self.oldy = self:Center()
	end
	self.shaking = shake
end

function TWRegion:UpdateVal(message)
	if self.regionType == RTYPE_VAR then
		
		if message ~= 'OnTouchUp' then
			-- TODO: right now it shows x,y
			if #message == 4 then
				self.value = message
				self.tl:SetLabel(round(message[3],3)..'\n'..round(message[4],3))
			end
		else
			local incre = 1
			self.value[1] = self.value[1] + incre
			self.tl:SetLabel(self.value[1])
		end
	end	
end

function TWRegion:UpdateX(message)
	if self.regionType == RTYPE_VAR then
		if message == 'OnTouchUp' then
			self:UpdateVal(message)			
		else
			if #message == 4 then
				self.value = message[3]
				self.tl:SetLabel(round(self.value,3))
				sendValue(self.value,1) 
			end
		end
	end
end

function TWRegion:UpdateY(message)
	if self.regionType == RTYPE_VAR then
		if message == 'OnTouchUp' then
			self:UpdateVal(message)			
		else
			if #message == 4 then
				self.value = message[4]
				self.tl:SetLabel(round(self.value,3))
				sendValue(self.value,2)	
			end
		end
	end
end

-- FIXME: learned linked movement is not working correctly, when dragging
-- but it works for animation
function TWRegion:Move(message, linkdata)
	local x,y = self:Center()
	
	local dx,dy = unpack(message)
	local cosT = 1
	local sinT = 0
	
	if #linkdata > 0 then
		cosT,sinT = unpack(linkdata)
	end
	
	local moveX = cosT*dx - sinT*dy
	local moveY = sinT*dx + cosT*dy
	
	local ndx, ndy = self:ClampedMovement(x, y, moveX, moveY)
	-- only move if we are not also holding this event in gesture manager:
	if not gestureManager:IsMultiTouch(self) then
		self:SetPosition(x + ndx, y + ndy)
		self:CallEvents('OnDragging', {ndx, ndy, self.relativeX, self.relativeY}, self.lastMessageOrigin)
	end
	Log:print(self:Name()..' move '..self.x..' '..self.y)
end

function MoveLeft(self, message)
	local e = tonumber(message) or 2	
	local x,y = self:Center()
	self.oldx = x - 5*e
	self.oldy = y
	self:SetAnchor('CENTER',x-10,y)
	linkLayer:Draw()
end

function MoveRight(self, message)
	local e = tonumber(message) or 2
	local x,y = self:Center()
	self.oldx = x + 5*e
	self.oldy = y
	self:SetAnchor('CENTER',x+10,y)
	linkLayer:Draw()
end

-- function ControllerTouchDownLeft(self) -- event for OnTouchDown of the controller
--     ControllerTouchDown(self)
--     MoveLeft(self)
--     self:Handle("OnUpdate",TriggerLeft)
-- end

