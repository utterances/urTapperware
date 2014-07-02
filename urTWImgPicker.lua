------------- Image Picker Menu --------------

-- expand this later into scrollable texture inspector


-- geometry constants:
-- MENUITEMHEIGHT = 44
-- MENUFONTSIZE = 26
-- MENUWIDTH = 200
-- MENUMESSAGEFONTSIZE = 16
-- MENUFONT = "Helvetica Neue"

-- example usage: m = loadImgPicker(cmdlist), m:present(x,y), m:dismiss()

function loadImgPicker()
	-- recycling constructor
	local picker
	if # recycledPicker > 0 then
		picker = table.remove(recycledPicker, 1)
	else
		picker = ImgPicker:new(nil)
	end
	
	return picker
end

-- ======================

ImgPicker = {}	-- class
recycledPicker = {}

function ImgPicker:new(o)
	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	 
	o.r = Region('region', 'backdrop', UIParent)
	o.r.t = o.r:Texture()
	o.r.t:Clear(255,255,255,200)
	o.r.t:SetBlendMode("BLEND")
	
	o.r:EnableInput(true)
	o.r:EnableMoving(false)
	o.r:Hide()
	
	o:setMessage('Pick an image:')
	
	o.imglist = {}
	
	for file in lfs.dir(DocumentPath("sprites")) do
		if string.sub(file,1,1) ~= "." then
			table.insert(o.imglist, file)
		end
	end
	o:initButtons()
	
	return o
end
	
function ImgPicker:setMessage(messageText)
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetLabel(messageText)
	self.r.tl:SetFont(MENUFONT)
	self.r.tl:SetFontHeight(MENUMESSAGEFONTSIZE)
	self.r.tl:SetColor(20,20,20,255)
	self.r.tl:SetVerticalAlign("TOP")
	self.r.tl:SetShadowColor(0,0,0,0)
	self.r.tl:SetShadowBlur(2.0)
end

function ImgPicker:initButtons()
	self.cmdLabels = {}

	local ButtonSize = ScreenWidth()/5
	self.r:SetWidth(ScreenWidth())
	self.r:SetHeight( ButtonSize * math.ceil(#self.imglist / 5)  + 84)
	-- create a grid now, use labels and 
	for i = 1, #self.imglist do
		-- local text = self.imglist[i][1]

		local label = Region('region', 'imgbtn', self.r)

		label:SetWidth(ButtonSize)
		label:SetHeight(ButtonSize)
		label:SetAnchor("TOPLEFT",self.r,"TOPLEFT",ButtonSize*(i%5), 
				-ButtonSize*math.floor((i-1)/5) - 30)
		label:SetLayer("TOOLTIP")
		label:EnableInput(true)
		label:EnableMoving(false)
		
		label.t = label:Texture("sprites/"..self.imglist[i])
		label.t:SetBlendMode("BLEND")

		label.tl = label:TextLabel()
		label.tl:SetFontHeight(10)
		label.tl:SetFont(MENUFONT)
		label.tl:SetLabel(self.imglist[i])
		label.tl:SetColor(0,128,255,255)
		label.tl:SetShadowColor(255,255,255,0)
		-- hook up function call
		label:Handle("OnTouchUp", PickerLoadTex)
		label:Handle("OnTouchDown", PickerDown)
		label:Handle("OnLeave", PickerLeave)
		-- label.func = cmdlist[i][2]
		-- label.arg = cmdlist[i][3]
		label.parent = self
		label.imgfile = self.imglist[i]
		label:Show()

		table.insert(self.cmdLabels, label)
	end
end

function ImgPicker:present()
	self.r:MoveToTop()
	self.r:EnableInput(true)
	self.r:EnableClamping(true)
	self.r:SetAnchor("TOPLEFT",0,ScreenHeight())
	self.r:Show()
	
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:MoveToTop()
	end
end

function ImgPicker:dismiss()
	self.r:Hide()
	self.r:EnableInput(false)
	for i = 1, #self.cmdLabels do
		self.cmdLabels[i]:Hide()
		self.cmdLabels[i]:EnableInput(false)
	end
	table.insert(recycledPicker, self)
end


-- ===================
-- = private methods =
-- ===================

-- this actually calls all the menu function on the right region(s)
function PickerLoadTex(self)
	-- self.t:Clear(235,235,235,0)
	LoadTexture("sprites/"..self.imgfile)
	self.parent:dismiss()
	-- if self.func ~= nil then	-- if func is nil always dimiss parent menu
	-- 	self.func(self.arg)
	-- else
	-- 	self.parent:dismiss()
	-- end
end

function PickerDown(self)
	-- self.t:Clear(235,235,235,255)
	self.tl:SetColor(20,140,255,255)
end

function PickerLeave(self)
	-- self.t:Clear(235,235,235,0)
	self.tl:SetColor(0,128,255,255)
end
