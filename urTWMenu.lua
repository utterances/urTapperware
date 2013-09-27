------------- Simple menu --------------

-- simple list menu used as a last resort to pick from a few options

------------- Simple menu --------------

-- geometry constants:
MENUITEMHEIGHT = 44
MENUFONTSIZE = 26
MENUWIDTH = 200
MENUMESSAGEFONTSIZE = 16
MENUFONT = "Helvetica Neue"
-- make a simple menu

-- example usage: m = loadSimpleMenu(cmdlist), m:present(x,y), m:dismiss()

function loadSimpleMenu(cmdlist, message)
	-- recycling constructor
	local menu
	if # recycledMenus > 0 then
		menu = table.remove(recycledMenus, 1)
		menu:setMessage(message)
		menu:setCommandList(cmdlist)
	else
		menu = SimpleMenu:new(nil,cmdlist,message)
	end
	
	return menu
end

-- ======================

SimpleMenu = {}	-- class
menus = {}		-- ? maybe not need this one TODO
recycledMenus = {}

function SimpleMenu:new(o, cmdlist, message)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	 
	o.r = Region('region', 'backdrop', UIParent)
	o.r.t = o.r:Texture()
	o.r.t:Clear(255,255,255,200)
	o.r.t:SetBlendMode("BLEND")
	o.r:SetWidth(MENUWIDTH)
	
	o.r:EnableInput(true)
	o.r:EnableMoving(false)
	o.r:Hide()
	
	o:setMessage(message)	
	o:setCommandList(cmdlist)
	
	table.insert(menus, o)
	return o
end

function SimpleMenu:setMessage(messageText)
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetLabel(messageText)
	self.r.tl:SetFont(MENUFONT)
	self.r.tl:SetFontHeight(MENUMESSAGEFONTSIZE)
	self.r.tl:SetColor(20,20,20,255)
	self.r.tl:SetVerticalAlign("TOP")
	self.r.tl:SetShadowColor(0,0,0,0)
	self.r.tl:SetShadowBlur(2.0)
end

function SimpleMenu:setCommandList(cmdlist)
	self.cmdlist = cmdlist
	self.cmdLabels = {}
	
	self.r:SetHeight((#self.cmdlist+1) * MENUITEMHEIGHT)
	-- create a list now, use labels and 
	for i = 1, #self.cmdlist do
		local text = cmdlist[i][1]
		
		local label = Region('region', 'menutext', UIParent)
				
		-- label.t:SetBlendMode("BLEND")
		label:SetWidth(200)
		label:SetHeight(MENUITEMHEIGHT)
		label:SetAnchor("TOP",self.r,"TOP",0,-MENUITEMHEIGHT*(i))
		label:SetLayer("TOOLTIP")
		label:Show()
		label:EnableInput(true)
		label:EnableMoving(false)
		label.t = label:Texture()
		label.t:Clear(235,235,235,0)
		label.t:SetBlendMode("BLEND")
		
		label.tl = label:TextLabel()
		label.tl:SetLabel(text)
  	  	label.tl:SetFontHeight(MENUFONTSIZE)
  		label.tl:SetFont(MENUFONT)
		label.tl:SetColor(0,128,255,255)
		label.tl:SetShadowColor(0,0,0,0)
		
		-- hook up function call
		label:Handle("OnTouchUp", CallFunc)
		label:Handle("OnTouchDown", MenuDown)
		label:Handle("OnLeave", MenuLeave)
		label.func = cmdlist[i][2]
		label.arg = cmdlist[i][3]
		
		table.insert(self.cmdLabels, label)
	end
end

function SimpleMenu:present(x, y)
	self.r:SetAnchor('CENTER',x,y)
	self.r:Show()
	self.r:MoveToTop()
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:MoveToTop()
	end
end

function SimpleMenu:dismiss()
	self.r:Hide()
	self.r:EnableInput(false)
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:Hide()
		self.cmdLabels[i]:EnableInput(false)
	end
	table.insert(recycledMenus, self)
end


-- ===================
-- = private methods =
-- ===================

-- this actually calls all the menu function on the right region(s)
function CallFunc(self)
	self.t:Clear(235,235,235,0)
	self.func(self.arg)
end

function MenuDown(self)
	self.t:Clear(235,235,235,255)
	self.tl:SetColor(20,140,255,255)
end

function MenuLeave(self)
	self.t:Clear(235,235,235,0)
	self.tl:SetColor(0,128,255,255)	
end
