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
menus = {}	-- ? maybe not need this one TODO
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
		
		local label = Region('region', 'menutext', self.r)
		
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
		if #text > 13 then
			label.tl:SetFontHeight(MENUFONTSIZE-6)
		else
			label.tl:SetFontHeight(MENUFONTSIZE)
		end
		label.tl:SetFont(MENUFONT)
		label.tl:SetLabel(text)
		label.tl:SetColor(0,128,255,255)
		label.tl:SetShadowColor(0,0,0,0)
		
		-- hook up function call
		label:Handle("OnTouchUp", SimpleMenu.CallFunc)
		label:Handle("OnTouchDown", MenuDown)
		label:Handle("OnLeave", MenuLeave)
		label.func = cmdlist[i][2]
		label.arg = cmdlist[i][3]
		label.parent = self
		
		table.insert(self.cmdLabels, label)
	end
end

function SimpleMenu:present(x, y)
	local lx = x
	local ly = y
	if x~=nil then
		if self.r:Width()/2 + x > ScreenWidth() then
			lx = x - self.r:Width()/2
		elseif x < self.r:Width()/2 then
			lx = x + self.r:Width()/2
		end

		if self.r:Height()/2 + x > ScreenHeight() then
			ly = y - self.r:Height()/2
		elseif y < self.r:Height()/2 then
			ly = y + self.r:Height()/2
		end
	else
		lx = ScreenWidth()/2
		ly = ScreenHeight()/2
	end
	
	self.r:SetAnchor('CENTER',lx,ly)
	self.r:Show()
	self.r:MoveToTop()
	self.r:EnableInput(true)
	self.r:EnableMoving(true)
	self.r:EnableClamping(true)
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:MoveToTop()
	end
	Log:print('present '..self.r.tl:Label())
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
function SimpleMenu.CallFunc(self)
	self.t:Clear(235,235,235,0)
	Log:print('menu cmd '..self.tl:Label())
	
	
	if self.func ~= nil then	-- if func is nil always dimiss parent menu
		self.func(self.arg)
	else
		Log:print('menu dismissed')
		self.parent:dismiss()
	end
end

function MenuDown(self)
	self.t:Clear(235,235,235,255)
	self.tl:SetColor(20,140,255,255)
end

function MenuLeave(self)
	self.t:Clear(235,235,235,0)
	self.tl:SetColor(0,128,255,255)	
end
