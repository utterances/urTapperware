------------- Gesture menu --------------
-- why not use gesture for a menu system, learnable?
------------- Gesture menu --------------

-- geometry constants:
-- MENUITEMHEIGHT = 44
MENUFONTSIZE = 26
MENUWIDTH = 300
MENUHEIGHT = 300

MENUMESSAGEFONTSIZE = 16
MENUFONT = "Helvetica Neue"

-- radial menu layout:
-- 2 3 4
-- 1 X 5

BUTTONOFFSET = 0
local areaLocation = {
	[1]={"LEFT", BUTTONOFFSET, 0},
	[2]={"TOPLEFT", BUTTONOFFSET, -BUTTONOFFSET},
	[3]={"TOP", 0, -BUTTONOFFSET},
	[4]={"TOPRIGHT", -BUTTONOFFSET, -BUTTONOFFSET},
	[5]={"RIGHT", -BUTTONOFFSET, 0}
}

-- example usage: m = loadGestureMenu(cmdlist), m:present(x,y), m:dismiss()

function loadGestureMenu(cmdlist, message)
	-- recycling constructor
	local menu
	if # recycledGMenus > 0 then
		menu = table.remove(recycledGMenus, 1)
		menu:setMessage(message)
		menu:setCommandList(cmdlist)
	else
		menu = GestureMenu:new(nil,cmdlist,message)
	end
	
	return menu
end

-- ======================

GestureMenu = {}	-- class
recycledGMenus = {}

function GestureMenu:new(o, cmdlist, message)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	 
	o.r = Region('region', 'backdrop', UIParent)
	o.r.t = o.r:Texture()
	o.r.t:Clear(255,255,255,200)
	o.r.t:SetBlendMode("BLEND")
	o.r:SetWidth(MENUWIDTH)
	o.r:SetHeight(MENUHEIGHT)
	o.r:SetLayer("TOOLTIP")
	
	o.r:Handle("OnMove", OnGestureMove)
	o.r:Handle("OnTouchUp", GestureMenu.dismiss)
	o.r:EnableInput(true)
	o.r:EnableMoving(false)
	o.r:Hide()
	
	o:setMessage(message)	
	o:setCommandList(cmdlist)
	
	table.insert(menus, o)
	return o
end
	
function GestureMenu:setMessage(messageText)
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetLabel(messageText)
	self.r.tl:SetFont(MENUFONT)
	self.r.tl:SetFontHeight(MENUMESSAGEFONTSIZE)
	self.r.tl:SetColor(20,20,20,255)
	self.r.tl:SetVerticalAlign("CENTER")
	self.r.tl:SetShadowColor(0,0,0,0)
	self.r.tl:SetShadowBlur(2.0)
end

function GestureMenu:setCommandList(cmdlist)
	self.cmdlist = cmdlist
	self.cmdLabels = {}
	
	for i = 1, #self.cmdlist do
		local text = cmdlist[i][1]
		
		local label = Region('region', 'menutext', self.r)
				
		-- label.t:SetBlendMode("BLEND")
		label:SetWidth(150)
		label:SetHeight(150)
		label:SetAnchor("CENTER", self.r, areaLocation[i][1],
												areaLocation[i][2],
												areaLocation[i][3])
		label:SetLayer("TOOLTIP")
		label:Show()
		label:EnableInput(true)
		label:EnableMoving(false)
		label.t = label:Texture()
		label.t:Clear(235,235,235,90)
		label.t:SetBlendMode("BLEND")
		
		label.tl = label:TextLabel()
		label.tl:SetLabel(text)
  	  	label.tl:SetFontHeight(MENUFONTSIZE)
  		label.tl:SetFont(MENUFONT)
		label.tl:SetColor(0,128,255,255)
		label.tl:SetShadowColor(0,0,0,0)
		
		-- hook up function call
		label:Handle("OnTouchUp", CallFunc)
		-- label:Handle("OnTouchDown", MenuDown)
		label:Handle("OnEnter", MenuDown)
		label:Handle("OnLeave", MenuLeave)
		label.func = cmdlist[i][2]
		label.arg = cmdlist[i][3]
		label.parent = self
		
		table.insert(self.cmdLabels, label)
	end
end

function GestureMenu:present(x, y)
	self.r:SetAnchor('CENTER',x,y)
	self.r:Show()
	self.r:MoveToTop()
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:MoveToTop()
	end
end

function GestureMenu:dismiss()
	self.r:Hide()
	self.r:EnableInput(false)
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:Hide()
		self.cmdLabels[i]:EnableInput(false)
	end
	table.insert(recycledGMenus, self)
end


-- ===================
-- = private methods =
-- ===================

function OnGestureMove(self,x,y,dx,dy,n)
	DPrint('gest:'..x..' '..y..' '..dx..' '..dy..' '..n)
   -- self.t:SetBrushColor(255,127,(6-n)*50,30)
	self.t:SetBrushSize(10)
   self.t:SetBrushColor(0,0,0,255)
	-- self.t:Point(x,y)
   self.t:Line(x, y, x+dx, y+dy)
end

-- this actually calls all the menu function on the right region(s)
function CallFunc(self)
	self.t:Clear(235,235,235,0)
	
	if self.func ~= nil then	-- if func is nil always dimiss parent menu
		self.func(self.arg)
	else
		self.parent:dismiss()
	end
end

function MenuDown(self)
	self.t:Clear(215,215,235,255)
	self.tl:SetColor(20,140,255,255)
end

function MenuLeave(self)
	self.t:Clear(235,235,235,0)
	self.tl:SetColor(0,128,255,255)	
end
