-- ============================
-- = Menus, contextual mostly =
-- ============================
-- we need region specific menu for hooking up signals(sender and receiver), and then creation menu

BUTTONSIZE = 54	-- on screen size in points/pixels
SMALLBUTTONSIZE = 40 -- small size
BUTTONOFFSET = 3
BUTTONIMAGESIZE = 80		-- size of the square icon image

recycledLinkMenu = {}

-- function Menu:new (o)
--    o = o or {}   -- create object if user does not provide one
--    setmetatable(o, self)
--    self.__index = self
--    return o	 
-- end

function testMenu(self)
	DPrint("touched menu on"..self:Name())
end

function CloseRegion(self)
	CloseRegionWrapper(self)
end

function StartLinkRegionAction(r, draglet)
	StartLinkRegion(r, draglet)
end

-- TODO this is not working yet since ondragstart is not implemented
function StartLinkOnDrag(self)
	-- self is the menu button/draglet
	-- target is the parent region
	local target = self.parent.v
	-- draw the potential link line here:
	ShowPotentialLink(target, self)
end

function SwitchRegionTypeAction(r)
	DPrint("switch type")
	SwitchRegionType(r)
end

function DuplicateAction(r, draglet)
	-- DPrint("copy action")
	if draglet ~= nil then
		x,y = draglet:Center()
		DuplicateRegion(r, x, y)
	else
		DuplicateRegion(r)
	end
end

function DupOnDrag(r)
	-- DPrint("drag dup")
end

function DeleteLinkAction(link)
	link:destroy()
--	RemoveLinkBetween(r1, r2)
end

-- radial menu layout:
-- 1 2 3
-- 4 9 5
-- 6 7 8

local buttonLocation = {
	[1]={"TOPLEFT", BUTTONOFFSET, -BUTTONOFFSET},
	[2]={"TOP", 0, -BUTTONOFFSET},
	[3]={"TOPRIGHT", -BUTTONOFFSET, -BUTTONOFFSET},
	[4]={"LEFT", BUTTONOFFSET, 0},
	[5]={"RIGHT", -BUTTONOFFSET, 0},
	[6]={"BOTTOMLEFT", BUTTONOFFSET, BUTTONOFFSET},
	[7]={"BOTTOM", 0, BUTTONOFFSET},
	[8]={"BOTTOMRIGHT", -BUTTONOFFSET, BUTTONOFFSET},
	[9]={"CENTER", 0, 0}
}

local regionMenu = {}
-- label, func, anchor relative to region, image file, draggable or not
regionMenu.cmdList = {
	{"", CloseRegion, 1, "tw_closebox.png"},
	{"Link", StartLinkRegionAction, 3, "tw_socket1.png", StartLinkOnDrag},
	{"", SwitchRegionTypeAction, 4, "tw_varswitcher.png"},
	{"", DuplicateAction, 5, "tw_dup.png", DupOnDrag},
	{"", testMenu, 6, "tw_timer.png"},
	-- {"", testMenu, 7, "tw_paint.png"}
	--{"", testMenu, 8, "tw_run.png"}
	{"", CloseMenu, 8, "tw_socket1.png"}
}

local linkMenu = {}
linkMenu.cmdList = {
	{"",testMenu, 3, "tw_socket1.png"}
}



local linkReceiverMenu = {}
-- label, func, anchor relative to region, image file
linkReceiverMenu.cmdList = {
	{"", CloseRegion, 1, "tw_closebox.png"},
	{"+", ReceiveLinkRegion, 4, "tw_socket2.png"},
	{"-", ReceiveLinkRegion, 6, "tw_socket2.png"},
	{"", testMenu, 3, "tw_unlock.png"},
	{"", testMenu, 5, "tw_sound.png"},
	{"", testMenu, 8, "tw_more.png"}
}

function initMenus(menuObj)
	DPrint("Made Menu")
	menuObj.items = {}

	for _,item in pairs(menuObj.cmdList) do
		label = item[1]
		func = item[2]
		anchor = item[3]
		image = item[4]
		
		local r = Region('region','menu',UIParent)
		r.tl = r:TextLabel()
		r.tl:SetLabel("\n"..label)
		r.tl:SetVerticalAlign("TOP")
		r.tl:SetHorizontalAlign("CENTER")
		-- r.tl:SetSpacing(40)
		r.tl:SetFontHeight(13)
		r.tl:SetFont("Avenir Next")
		r.tl:SetColor(0,0,0,255) 	
		r.t = r:Texture(image)
		r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
		r.t:SetBlendMode("BLEND")
		-- r:SetAnchor(anchor, UIParent)
		r:SetLayer("TOOLTIP")
		r:SetHeight(BUTTONSIZE)
		r:SetWidth(BUTTONSIZE)
		r:MoveToTop()
		-- r:Show()
		r:Hide()
		-- r:Handle("OnTouchDown",OptEventFunc)

		r.func = func
		r.anchorpos = anchor
		r.parent = menuObj
		r.draglet = item[5]

		table.insert(menuObj.items, r)
	end
	menuObj.show = 0
	menuObj.v = nil
end


function initLinkMenus()
	linkMenu = {}

	local r = Region('region','menu',UIParent)
	r.t = r:Texture("tw_closebox.png")
	r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
	r.t:SetBlendMode("BLEND")
	-- r:SetAnchor(anchor, UIParent)
	r:SetLayer("TOOLTIP")
	r:SetHeight(SMALLBUTTONSIZE)
	r:SetWidth(SMALLBUTTONSIZE)
	r:MoveToTop()
	r:Hide()
	r.parent = linkMenu
	r.func = DeleteLinkAction
	
	linkMenu.r = r
	linkMenu.link = nil
	
	return linkMenu
end

-- initialize regionMenu graphics
initMenus(regionMenu)
initMenus(linkMenu)
-- initialize connection receiver menu graphics
linkReceiverMenu.items = {}

for k,item in pairs(linkReceiverMenu.cmdList) do
	label = item[1]
	func = item[2]
	anchor = item[3]
	image = item[4]
	
	local r = Region('region','menu',UIParent)
	r.tl = r:TextLabel()
	r.tl:SetLabel(label)
	r.tl:SetFontHeight(13)
	r.tl:SetColor(0,0,0,255) 	
	r.t = r:Texture(image)
	r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
	r.t:SetBlendMode("BLEND")
	-- r:SetAnchor(anchor, UIParent)
	r:SetLayer("TOOLTIP")
	r:SetHeight(BUTTONSIZE)
	r:SetWidth(BUTTONSIZE)
	r:MoveToTop()
	-- r:Show()
	r:Hide()
	r:Handle("OnTouchUp",OptEventFunc)
	r.parent = linkReceiverMenu

	r.func = func
	r.anchorpos = anchor
	table.insert(linkReceiverMenu.items, r)
end
linkReceiverMenu.show = 0

function OpenMenu(self)

  -- if regionMenu.show == 0 then
		DPrint("opens menu!")
		
    regionMenu.v = self
		
    for i = 1,#regionMenu.items do
        regionMenu.items[i]:Show()
        regionMenu.items[i]:EnableInput(true)
				if regionMenu.items[i].draglet ~= nil then
					regionMenu.items[i]:EnableMoving(true)
					regionMenu.items[i]:Handle("OnUpdate", regionMenu.items[i].draglet)
				end
				
				-- regionMenu.items[i]:Handle("OnTouchDown", testMenu)
        regionMenu.items[i]:Handle("OnTouchUp", OptEventFunc)
        regionMenu.items[i]:MoveToTop()
				pos = regionMenu.items[i].anchorpos
				regionMenu.items[i]:SetAnchor("CENTER", self,
															buttonLocation[pos][1],
															buttonLocation[pos][2],
															buttonLocation[pos][3])
    end
      
		self.menu = regionMenu
    -- regionMenu.show = 1
  -- end
	
	-- TODO change this later
	-- open receiver menu for all another region(s)
	-- for i = 1, #regions do
	-- 	if regions[i] ~= self then
	-- 		for j = 1, #linkReceiverMenu.items do
	--       linkReceiverMenu.items[j]:Show()
	--       linkReceiverMenu.items[j]:EnableInput(true)
	--       -- linkReceiverMenu.items[i]:Handle("OnTouchUp", OptEventFunc)
	--       linkReceiverMenu.items[j]:MoveToTop()
	-- 			pos = linkReceiverMenu.items[j].anchorpos
	-- 			linkReceiverMenu.items[j]:SetAnchor("CENTER", regions[i],
	-- 																	buttonLocation[pos][1],
	-- 																	buttonLocation[pos][2],
	-- 																	buttonLocation[pos][3])
	-- 			regions[i].menu = linkReceiverMenu
	-- 			linkReceiverMenu.v = regions[i]
	-- 		end
	-- 		
	-- 		break															
	-- 	end
	-- end
end

function OpenRegionMenu(self)
	-- OpenMenu(self, regionMenu)
	OpenMenu(self)
	DPrint(self:Name())
end

-- keep menu on top of pesky things, like regions
function RaiseMenu(self)
  -- if regionMenu.show == 1 then
    for i = 1,#regionMenu.items do
        regionMenu.items[i]:MoveToTop()
    end
		
    for i = 1,#linkReceiverMenu.items do
        linkReceiverMenu.items[i]:MoveToTop()
    end
		
	-- end
end

function CloseMenu(self)
  -- if regionMenu.show == 1 then
    for i = 1,#regionMenu.items do
        regionMenu.items[i]:Hide()
        regionMenu.items[i]:EnableInput(false)
				regionMenu.items[i]:Handle("OnTouchUp", nil)
				regionMenu.items[i]:Handle("OnUpdate", nil)
    end
		regionMenu.show = 0
		regionMenu.v = nil
		self.menu = nil
	-- end
	
	--   for i = 1,#linkReceiverMenu.items do
	--       linkReceiverMenu.items[i]:Hide()
	--       linkReceiverMenu.items[i]:EnableInput(false)
	--       -- regionMenu.items[i]:MoveToTop()
	-- 		-- regionMenu.items[i]:SetAnchor(regionMenu.items[i].anchorpos, self, "CENTER")
	--   end
	-- linkReceiverMenu.show = 0
	-- linkReceiverMenu.v = nil
	linkLayer:ResetPotentialLink()
	for i = 1,#regions do
		regions[i].menu = nil
	end	
end

function SwitchToLinkMenu()
	for i = 1,#regionMenu.items do
        regionMenu.items[i]:Hide()
        regionMenu.items[i]:EnableInput(false)
		regionMenu.items[i]:Handle("OnTouchUp", nil)
		regionMenu.items[i]:Handle("OnUpdate", nil)
    end
end


function CallLinkFunc(self)
	-- use this to call function on the link menu button
	-- because we have reference to the link, not just one region
	CloseLinkMenu(self)
	self.func(self.parent.link)
--	self.func(self.parent.sender, self.parent.receiver)
end

-- this actually calls all the menu function on the right region(s)
function OptEventFunc(self)
	-- DPrint("optevent func")
	local target = self.parent.v
	self.func(target, self)
end

-- ============================
-- = public link menu methods =
-- ============================
function newLinkMenu(l)
	-- recycling constructor
	local linkMenu
	if # recycledLinkMenu > 0 then
		linkMenu = table.remove(recycledLinkMenu, 1)
	else
		linkMenu = initLinkMenus()
	end
	linkMenu.link  = l
	
	return linkMenu
end
	
function OpenLinkMenu(menu)

	if menu then
		-- shows the actual menu
		menu.r:Show()
		menu.r:EnableInput(true)
		menu.r:Handle("OnTouchUp", CallLinkFunc)
		menu.r:MoveToTop()
	
		X1,Y1 = menu.link.sender:Center()
		X2,Y2 = menu.link.receiver:Center()
		menu.r:SetAnchor("CENTER", (X1+X2)/2, (Y1+Y2)/2)
	end
end
	
function deleteLinkMenu(menu)
	--CloseLinkMenu(menu)
	-- menu = self.parent
	table.insert(recycledLinkMenu, menu)
end

-- =============================
-- = private link menu methods =
-- =============================

function CloseLinkMenu(self)
	-- DPrint("close link menu")
	self:Hide()
	self:EnableInput(false)
end