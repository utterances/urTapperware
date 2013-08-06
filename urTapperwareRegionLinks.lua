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
function ResetRegion(r) -- customized parameter initialization of region, events are initialized in VRegion()
	r.alpha = 1 --target alpha for animation
	r.menu = nil  --contextual menu
	r.counter = 0 --if this is a counter
	r.isHeld = false -- if the r is held by tap currently
	r.isSelected = false
	r.group = nil

	r.dx = 0  -- compute storing current movement speed, for gesture detection
	r.dy = 0
	x,y = r:Center()
	r.oldx = x
	r.oldy = y
	r.sx = 0
	r.sy = 0
	r.w = INITSIZE
	r.h = INITSIZE

-- event handling
	r.links = {}
	r.links["OnTouchDown"] = {}
	r.links["OnTouchUp"] = {}
	r.links["OnDoubleTap"] = {}

-- initialize for events and signals
	r.eventlist = {}
	r.eventlist["OnTouchDown"] = {HoldTrigger}
	r.eventlist["OnTouchUp"] = {DeTrigger} 
	r.eventlist["OnDoubleTap"] = {} --{CloseSharedStuff,OpenOrCloseKeyboard} 
	r.eventlist["OnUpdate"] = {} 
	r.eventlist["OnUpdate"].currentevent = nil
 
	r.t:SetBlendMode("BLEND")
	r.tl:SetLabel(r:Name())
	r.tl:SetFontHeight(16)
	r.tl:SetFont("Ariel.ttf")
	r.tl:SetColor(0,0,0,255) 
	r.tl:SetHorizontalAlign("JUSTIFY")
	r.tl:SetVerticalAlign("MIDDLE")
	r.tl:SetShadowColor(100,100,100,255)
	r.tl:SetShadowOffset(1,1)
	r.tl:SetShadowBlur(1)
	r:SetWidth(50)
	r:SetHeight(50)

end

-- Initialize a new region
function CreateRegion(ttype,name,parent,id) -- customized initialization of region
-- add a visual shadow as a second layer
	local r_s = Region(ttype,"drops"..id,parent)
	--r_s.t = r_s:Texture("urMus-Intro_106.png")
	
	r_s.t = r_s:Texture("tw_shadow2.png")
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

	r:Handle("OnDoubleTap",TapperRegion.DoubleTap)
	r:Handle("OnTouchDown",TapperRegion.TouchDown)
	r:Handle("OnTouchUp",TapperRegion.TouchUp)
	--r:Handle("OnDragStop",VDrag)
	r:Handle("OnUpdate",TapperRegion.Update)
	--r:Handle("OnMove",VDrag)
	
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

TapperRegion = {}

function TapperRegion.check(self)
	DPrint(self.id)
	toDelete = self.id
end

-- constructor
function TapperRegion:new(o)
	o = o or {}     -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o = AllocRegion('region','backdrop',UIParent)

	return o
end

function TapperRegion:Show()
	--self.shadow:Show()
	self:Show()
end

function TapperRegion.Update(self,elapsed)
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
	if x ~= self.oldx then
		self.dx = x - self.oldx
	end
	if y ~= self.oldy then
		self.dy = y - self.oldy
	end
	
	if x ~= self.oldx or y ~= self.oldy then
		-- moved, draw link
		linkLayer:Draw()
		-- also update the rest of the group, if needed: TODO change this later
		if self.group ~= nil then
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
	end
	
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

	self.oldx = x
	self.oldy = y

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
end

function TapperRegion.CallEvents(signal,vv)
	local list = {}

	if current_mode == modes[1] then
		list = vv.eventlist[signal]
	else
		list = vv.reventlist[signal]
	end
	for k = 1,#list do
		list[k](vv)
	end
	
	linkLayer:SendMessageToReceivers(vv, signal)

-- fire off messages to linked regions
	--[[list = vv.links[signal]
	if list ~= nil then
		for k = 1,#list do
			list[k][1](list[k][2])
		end
	end]]--
end

function TapperRegion.TouchDown(self)
	TapperRegion.CallEvents("OnTouchDown",self)
	-- DPrint("hold for menu")
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
	self.alpha = .4
	-- isHoldingRegion = true
	table.insert(heldRegions, self)

	-- bring menu up if they are already open
	if self.menu ~= nil then
		RaiseMenu(self)
	end
end

function TapperRegion.DoubleTap(self)
	DPrint("double tapped")
	TapperRegion.CallEvents("OnDoubleTap",self)
end

function TapperRegion:TouchUp()
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
					
					-- initialize bounce back animation, it runs in TapperRegion.Update later
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
	
	TapperRegion.CallEvents("OnTouchUp",self)
end

function TapperRegion:RaiseToTop()
	self.shadow:MoveToTop()
	self.shadow:SetLayer("LOW")
	self:MoveToTop()
	self:SetLayer("LOW")
end
-- ===============================
-- = Visual Links between regions=
-- ===============================

-- methods and appearances and menus for deleting / editing
-- assumes urTapperwareMenu.lua is already processed
linkEventMenu = {}
linkEventMenu.cmdList = {
	{"Touch Up", testLink},
	{"Update Move", testLink}
}

linkEffectMenu = {}
linkEffectMenu.cmdList = {
	{"Normal", testLink},
	{"Counter", testLink},
	{"Move", testLink}
}



linkLayer = {}

function linkLayer:Init()
	self.list = {}
	-- this is actually a dictionary, key = sender, value = {list of receivers}
	self.potentialLinkList = {}
	self.menus = {}
	
	-- one region for drawing formed links
	self.links = Region('region', 'backdrop', UIParent)
	self.links:SetWidth(ScreenWidth())
	self.links:SetHeight(ScreenHeight())
	self.links:SetLayer("TOOLTIP")
	self.links:SetAnchor('BOTTOMLEFT',0,0)
	self.links.t = self.links:Texture()
	self.links.t:Clear(0,0,0,0)
	self.links.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
	self.links.t:SetBlendMode("BLEND")
	self.links:EnableInput(false)
	self.links:EnableMoving(false)
	
	self.links:MoveToTop()
	self.links:Show()
	
	-- set up another region for drawing guides or potential links
	self.linkGuides = Region('region', 'backdrop', UIParent)
	self.linkGuides:SetWidth(ScreenWidth())
	self.linkGuides:SetHeight(ScreenHeight())
	self.linkGuides:SetLayer("TOOLTIP")
	self.linkGuides:SetAnchor('BOTTOMLEFT',0,0)
	self.linkGuides.t = self.linkGuides:Texture()
	self.linkGuides.t:Clear(0,0,0,0)
	self.linkGuides.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
	self.linkGuides.t:SetBlendMode("BLEND")
	self.linkGuides:EnableInput(false)
	self.linkGuides:EnableMoving(false)
	
	self.linkGuides:MoveToTop()
	self.linkGuides:Show()
	
end

-- add links to our list
function linkLayer:Add(r1, r2, event, effect)
	
	if self.list[r1] == nil then
		self.list[r1] = {r2}
	else
		table.insert(self.list[r1], r2)
	end
	
	
	local menu = newLinkMenu(r1, r2)
	table.insert(self.menus, menu)
end

-- remove links
function linkLayer:Remove(r1, r2)	
	if self.list[r1] ~= nil then
		
		tableRemoveObj( self.list[r1], r2 )
		
		--[[for i = 1, #self.list[r1] do
			if self.list[r1][i] == r2 then
				table.remove(	self.list[r1], i)
			end
		end]]--
	end
	
	for i,menu in ipairs(self.menus) do
		if menu.sender == r1 and menu.receiver == r2 then
			table.remove(self.menus, i)
			deleteLinkMenu(menu)
		end
	end
end

-- draw a line between linked regions, also draws menu
function linkLayer:Draw()
	self.links.t:Clear(0,0,0,0)
	self.links.t:SetBrushColor(100,255,240,200)
	self.links.t:SetBrushSize(8)
	
	for sender, receivers in pairs(self.list) do
		X1, Y1 = sender:Center()
		for _, r in ipairs(receivers) do
			
			X2, Y2 = r:Center()
			self.links.t:Line(X1,Y1,X2,Y2)
		end
	end
	
	-- draw the link menu (close button), it will compute centroid using
	-- region locations	
	for _,menu in ipairs(self.menus) do
		OpenLinkMenu(menu)
	end	
end

function linkLayer:DrawPotentialLink(region, draglet)
	self.linkGuides.t:Clear(0,0,0,0)
	self.linkGuides.t:SetBrushColor(100,255,240,100)
	self.linkGuides.t:SetBrushSize(12)
	
	rx, ry = region:Center()
	posx, posy = draglet:Center()
	self.linkGuides.t:Line(rx,ry,posx,posy)
end

function linkLayer:ResetPotentialLink()
	self.linkGuides.t:Clear(0,0,0,0)
end

function linkLayer:SendMessageToReceivers(sender, message)
	if self.list[sender] ~= nil and message == "OnTouchUp" then
		for _, r in pairs(self.list[sender]) do
			--TouchUpWrapper(r)
			r:TouchUp()
		end
	end
end
