-- ==============================================
-- = Group Regions and menus for group commands =
-- ==============================================

BUTTONSIZE = 54	-- on screen size in points/pixels
BUTTONOFFSET = 3
BUTTONIMAGESIZE = 80		-- size of the square icon image

GROUPMARGIN = 40

recycledGroupMenu = {}

function ToggleLockGroup(regions)
	newGroup = Group:new()
	newGroup:SetRegions(regions)
	newGroup:Draw()
	Log:print('created group with '..regions[1]:Name())
	return newGroup
end

function initGroupMenu()
	local groupMenu = {}
	-- label, func, anchor relative to region, image file, draggable or not
	-- groupMenu.cmdList = {
	-- 	{"", ToggleLockGroup, "tw_unlock.png"}
	-- }

	local r = Region('region','menu',UIParent)
	r.t = r:Texture("tw_unlock.png")	--TODO change this later
	r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
	r.t:SetBlendMode("BLEND")
	r:SetLayer("TOOLTIP")
	r:SetHeight(BUTTONSIZE)
	r:SetWidth(BUTTONSIZE)
	r:MoveToTop()
	r:Hide()
	r.parent = groupMenu
	r.func = ToggleLockGroup
	
	groupMenu.item = r
	groupMenu.selectedRegions = {}
	
	return groupMenu
end

function CallGroupFunc(self)
	-- use this to call function on the link menu button
	-- because we have reference to the link, not just one region
	CloseGroupMenu(self.parent)
	selectionLayer.t:Clear(0,0,0,0) --FIXME: clunky way to disable selection vis
	self.func(self.parent.selectedRegions)
end


-- ============================
-- = public link menu methods =
-- ============================
function newGroupMenu()
	-- recycling constructor
	local groupMenu
	if # recycledGroupMenu > 0 then
		groupMenu = table.remove(recycledGroupMenu, 1)
	else
		groupMenu = initGroupMenu()
	end
	
	return groupMenu
end
	
function OpenGroupMenu(menu, x, y, selectedRegions)
	-- shows the actual menu
	menu.item:Show()
	menu.item:EnableInput(true)
	menu.item:Handle("OnTouchUp", CallGroupFunc)
	menu.item:MoveToTop()
	menu.selectedRegions = selectedRegions
	menu.item:SetAnchor("CENTER", x, y)	   
end
	
function deleteGroupMenu(menu)
	menu.selectedRegions = nil
	CloseGroupMenu(menu)
	table.insert(recycledLinkMenu, menu)
end

-- ==============================
-- = private group menu methods =
-- ==============================

function CloseGroupMenu(self)
	self.item:Hide()
	self.item:EnableInput(false)
end


-- ======================
-- = Grouping code here =
-- ======================

Group = {}	-- the class
groups = {}	-- the list of groups

function Group:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	
	o.menu = newGroupMenu()
	o.r = TWRegion:new(nil,updateEnv)
	o.r.regionType = RTYPE_GROUP
	o.r.t = o.r:Texture()
	o.r.t:Clear(0,0,0,100)
	o.r.t:SetBlendMode("BLEND")
	o.r.tl:SetLabel("")
	o.r.shadow:Hide()
	o.r.groupObj = o
	
	-- o.r:Handle("OnDoubleTap", nil)
	-- o.r:Handle("OnTouchDown", nil)
	-- o.r:Handle("OnTouchUp", nil)
	o.r:Handle("OnLeave", nil)
	o.r:Handle("OnSizeChanged", Group.OnSizeChanged)
	
	o.r:EnableInput(true)
	o.r:EnableMoving(true)
	o.r:EnableResizing(true)
	o.r:Hide()
	o.regions = {}
	
	table.insert(groups, o)
	return o
end

function Group:SetRegions(listOfRegions)
	self.regions = listOfRegions
	
	-- assign groups to each region in the list
	for i = 1, #self.regions do
		self.regions[i].group = self
	end
end

function Group:AddRegion(region)
	table.insert(self.regions, region)
	region.group = self
	
	local x,y = region:Center()
	region:SetPosition(x,y)
	-- region:SetAnchor('CENTER', self.r, 'BOTTOMLEFT', 
	-- 	x - self.r.x + self.r.w/2, y - self.r.y + self.r.h/2)
	region:RaiseToTop()
	CloseMenu(region)
	Log:print('added '..region:Name()..' to group')
end

function Group:RemoveRegion(region)
	if region.group == self then
		region.group = nil
		tableRemoveObj(self.regions, region)
		local x,y = region:Center()
		region:SetPosition(x,y)
	else
		DPrint('removing region: not my region!')
	end
end

function Group:NestRegionInto(r1, r2)
	-- nest r1 into r2, change r2 into a group if not already one
	if r2.regionType ~= RTYPE_GROUP then
		-- create new group, set sizes
		newGroup = ToggleLockGroup({r1})
		if r2.h > newGroup.h or r2.w > newGroup.w then
			newGroup.h = r2.h
			newGroup.w = r2.w
		end
		-- newGroup.r:SetAnchor("CENTER", groupRegion.rx, groupRegion.ry)
		-- newGroup.r.x = r2.rx
		-- newGroup.r.y = r2.ry

		if r2.textureFile~=nil then
			newGroup.r:LoadTexture(r2.textureFile)
		end

		RemoveRegion(r2)
	else
		r2.groupObj:AddRegion(r1)
	end
end


-- find out how big the group region needs to be, then resize and draw
-- anchor the regions to the group to enforce spatial unity
function Group:Draw()
	minX = -1
	minY = -1
	maxX = -1
	maxY = -1
	
	for i = 1, #self.regions do
		x,y = self.regions[i]:Center()
		w = self.regions[i]:Width()
		h = self.regions[i]:Height()
		
		if minX < 0 or minX > x - w/2 then
			minX = x - w/2
		end
		if minY < 0 or minY > y - h/2 then
			minY = y - h/2
		end
		maxX = math.max(maxX, x + w/2)
		maxY = math.max(maxY, y + h/2)
	end
	maxX = maxX + GROUPMARGIN
	maxY = maxY + GROUPMARGIN
	minX = minX - GROUPMARGIN
	minY = minY - GROUPMARGIN
	
	-- TODO: make this proper OO style overriding the SetWidth() methods
	self.r.w = maxX - minX
	self.r.h = maxY - minY
	self.r:SetWidth(maxX - minX)
	self.r:SetHeight(maxY - minY)
	
	self.r:SetAnchor('CENTER', (maxX+minX)/2, (maxY+minY)/2)
	self.r.x, self.r.y = self.r:Center()
	self.r:SetLayer("LOW")
	self.r:MoveToTop()
	for i = 1, #self.regions do
		r = self.regions[i]
		x,y = r:Center()
		r:SetAnchor('CENTER', self.r, 'BOTTOMLEFT', x - minX, y - minY)
		r:RaiseToTop()
	end
	
	-- now show everything
	self.r:Show()
	-- OpenGroupMenu(self.menu, minX, minY, nil) -- TODO: self.regions functionality
	self.menu.item:SetAnchor('CENTER', self.r, 'BOTTOMLEFT', 0, 0)
	self.menu.item:EnableInput(false)
end

function Group:OnSizeChanged()
	-- the user changed the size, make sure it's not too small:
	-- here, self is group.r, not group
	
	minX = -1
	minY = -1
	maxX = -1
	maxY = -1
	
	for i = 1, #self.groupObj.regions do
		x,y = self.groupObj.regions[i]:Center()
		w = self.groupObj.regions[i]:Width()
		h = self.groupObj.regions[i]:Height()
		
		if minX < 0 or minX > x - w/2 then
			minX = x - w/2
		end
		if minY < 0 or minY > y - h/2 then
			minY = y - h/2
		end
		maxX = math.max(maxX, x + w/2)
		maxY = math.max(maxY, y + h/2)
	end
	
	restricted = false
	if self:Width() < maxX - minX then
		self.w = maxX - minX
		self:SetWidth(self.w)
		restricted = true
	end
	
	if self:Height() < maxY - minY then
		self.h = maxY - minY
		self:SetHeight(self.h)	
		restricted = true
	end
	
	-- if restricted then
	-- 	self:SetAnchor('CENTER', (maxX+minX)/2, (maxY+minY)/2)
	-- end	
	
	self.w = self:Width()
	self.h = self:Height()
end

function Group:Destroy()
	--// not sure if this is needed or actually works yet //--
	
	for i = 1, #self.regions do
		Group:RemoveRegion(self.regions[i])
	end
	self.r:Hide()
	-- self region is removed somewhere else in region:RemoveRegion
	self.regions = nil
	self = nil
end

lassoGroupMenu = newGroupMenu()
