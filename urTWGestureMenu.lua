------------- Gesture menu --------------
-- why not use gesture for a menu system, learnable?
------------- Gesture menu --------------

-- geometry constants:
-- MENUITEMHEIGHT = 44
-- MENUFONTSIZE = 26
-- MENUWIDTH = 300
-- MENUHEIGHT = 300

-- MENUMESSAGEFONTSIZE = 16
-- MENUFONT = "Helvetica Neue"
GESTACCELFACTOR = 2

-- radial menu layout:
-- 2 3 4
-- 1 X 5

-- example usage: m = loadGestureMenu(cmdlist), m:present(x,y), m:dismiss()

function loadGestureMenu(cmdlist)
	-- recycling constructor
	local menu
	if # recycledGMenus > 0 then
		menu = table.remove(recycledGMenus, 1)
		-- menu:setCommandList(cmdlist)
	else
		menu = GestureMenu:new(nil,cmdlist)
	end
	
	return menu
end

-- ======================

GestureMenu = {} -- class
recycledGMenus = {}

function GestureMenu:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	
	o.r = Region('region', 'backdrop', UIParent)
	o.r.t = o.r:Texture("texture/tw_gestMenu.png")
	o.r.t:SetBlendMode("BLEND")
	o.r.t:SetTexCoord(0,240/256.0,160/256.0,0.0)
	o.r:SetWidth(240)
	o.r:SetHeight(160)
	o.r:SetLayer("TOOLTIP")
	
	o.r:Handle("OnMove", OnGestureMove)
	-- o.r:Handle("OnTouchUp", GestureMenu.dismiss)
	o.r:EnableInput(false)
	o.r:EnableMoving(false)
	o.r:Hide()
	
	local r = Region('region','gmenu', o.r)
	r:SetLayer("TOOLTIP")
	r.t = r:Texture("texture/tw_gestTouch.png")
	r.t:SetBlendMode("BLEND")
	-- r.t:SetTexCoord(0,80/128.0,80/128.0,0.0)
	r:SetWidth(80)
	r:SetHeight(80)
	-- r:SetAlpha(.9)
	r:Show()
	r:SetAnchor("TOPLEFT", o.r, "TOPLEFT", 80, -80)
	r:EnableInput(false)
	
	o.dragCircle = r

	local cmdlist = {
		{'Delete', RemoveRegion, 'texture/tw_gestMenu_trash.png'},
		{'Change Texture', LoadInspector, 'texture/tw_gestMenu_edit.png'}
	}
	o:setCommandList(cmdlist)
	
	-- table.insert(menus, o)
	
	o.old_x = 0
	o.old_y = 0
	return o
end

function GestureMenu:setCommandList(cmdlist)
	self.cmdlist = cmdlist
	self.cmdLabels = {}
	
	for i = 1, #self.cmdlist do
		local text = cmdlist[i][1]
		
		local label = Region('region', 'gmenu', self.r)
				
		-- label.t:SetBlendMode("BLEND")
		label:SetWidth(80)
		label:SetHeight(80)
		if i==1 then
			label:SetAnchor("TOPLEFT", self.r, "TOPLEFT", 0, 0)
		else
			label:SetAnchor("TOPLEFT", self.r, "TOPLEFT", 160, 0)
		end
		label:SetLayer("TOOLTIP")
		label:Show()
		label:EnableMoving(false)
		label:EnableInput(false)
		label.t = label:Texture(cmdlist[i][3])
		label.t:SetBlendMode("BLEND")
		label.t:SetTexCoord(0,80/128.0,80/128.0,0.0)
		
				
		-- hook up function call
		-- label:Handle("OnTouchUp", CallFunc)
		-- label:Handle("OnTouchDown", MenuDown)
		-- label:Handle("OnEnter", MenuDown)
		-- label:Handle("OnLeave", MenuLeave)
		label.func = cmdlist[i][2]
		label.parent = self
		
		table.insert(self.cmdLabels, label)
	end
end

function GestureMenu:Present(x, y, region)
	self.old_x = x
	self.old_y = y
	self.region = region
	
	self.r:SetAnchor('CENTER',x,y+40)
	self.r:SetAlpha(1)
	self.r:MoveToTop()
	self.r:Show()
	self.dragCircle:SetAnchor("TOPLEFT", self.r, "TOPLEFT", 80, -80)
	self.dragCircle:MoveToTop()
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:SetAlpha(.5)
		self.cmdLabels[i]:MoveToTop()
	end
end

function GestureMenu:Dismiss()
	self.region = nil
	self.r:Hide()
	self.r:EnableInput(false)
	for i = 1, #self.cmdLabels do
		-- self.cmdLabels[i]:Hide()
		self.cmdLabels[i]:EnableInput(false)
	end
	table.insert(recycledGMenus, self)
end

function GestureMenu:UpdateGest(x,y)
	-- use new drag coordinates to update visual and also states
	-- first need to check which path we are on, and act accordingly
	local dx = x - self.old_x
	local dy = y - self.old_y
	-- DPrint('gest drag '..dx..' '..dy)
		
	-- clamp position to the gesture menu guide 
	local absx = math.abs(dx)
	local absy = math.max(dy,0)
	local cx,cy
	cx = math.min(math.min(absx, absy)*GESTACCELFACTOR, 80)* absx/dx
	cy = math.abs(cx)
	
	self.dragCircle:SetAnchor("TOPLEFT", self.r, "TOPLEFT", cx+80, cy-80)
	
	-- set alpha value accordingly
	self.r:SetAlpha(1 - cy/80*.6)
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:SetAlpha(.5 + .5*math.max((i-1.5)*2*cx/80,0))
		-- 2:
		-- self.cmdLabels[i]:SetAlpha(.7 + .3*math.max(cx/80,0))
	end
end

function GestureMenu:ExecuteCmd()
	-- actually run the command that's selected
	-- should call dismiss right after this call usually
	local dx, _ = self.dragCircle:Center()
	dx = dx - self.old_x
	-- DPrint('exec '..dx)
	
	if 80-dx < 2 then
		--execute cmd 2
		self.cmdLabels[2].func(self.region)
	elseif dx + 80 < 2 then
		self.cmdLabels[1].func(self.region)
	end
end

-- ===================
-- = private methods =
-- ===================

function OnGestureMove(self,x,y,dx,dy,n)
	-- DPrint('gest:'..x..' '..y..' '..dx..' '..dy..' '..n)
   -- self.t:SetBrushColor(255,127,(6-n)*50,30)
	self.t:SetBrushSize(10)
   self.t:SetBrushColor(0,0,0,255)
	-- self.t:Point(x,y)
   self.t:Line(x, y, x+dx, y+dy)
end

-- this actually calls all the menu function on the right region(s)
-- function CallFunc(self)
-- 	self.t:Clear(235,235,235,0)
--
-- 	if self.func ~= nil then	-- if func is nil always dimiss parent menu
-- 		self.func(self.arg)
-- 	else
-- 		self.parent:dismiss()
-- 	end
-- end

-- function MenuDown(self)
-- 	self.t:Clear(215,215,235,255)
-- 	self.tl:SetColor(20,140,255,255)
-- end
--
-- function MenuLeave(self)
-- 	self.t:Clear(235,235,235,0)
-- 	self.tl:SetColor(0,128,255,255)
-- end
