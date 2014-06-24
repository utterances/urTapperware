-- ============================
-- = Menus, contextual mostly hugs hugs hugs and kisses=
-- ============================
-- we need region specific menu for hooking up signals(sender and receiver), and then creation menu and qi is my hero i <3 him

BUTTONSIZE = 54	-- on screen size in points/pixels
SMALLBUTTONSIZE = 40 -- small size
BUTTONOFFSET = 3
BUTTONIMAGESIZE = 80	-- size of the square icon image

DRAGLET_ANI_DELAY = 2	-- delay between draglet animation
DRAGLET_ANI_DUR = 1	-- duration of draglet animation
DRAGLET_ANI_DIST = 6

recycledLinkMenu = {}
inspectedRegion = nil

-- function Menu:new (o)
--    o = o or {}   -- create object if user does not provide one
--    setmetatable(o, self)
--    self.__index = self
--    return o
-- end

function testMenu(self)
	DPrint("touched menu on"..self:Name())
end

-- TODO refactor, move this into its own class, loading file and inspector?
function LoadInspector(self)
	cmdlist = {}
	
	for file in lfs.dir(DocumentPath("sprites")) do
		if string.sub(file,1,1) ~= "." then
			table.insert(cmdlist, {file, LoadTexture, "sprites/"..file})
		end
	end
	
	table.insert(cmdlist,{'Cancel', nil, nil})
	menu = loadSimpleMenu(cmdlist, 'Choose Texture File:')
	menu:present(self:Center())
	inspectedRegion = self
end

function LoadTexture(filename)
	menu:dismiss()
	-- menu=nil
	inspectedRegion:LoadTexture(filename)
	inspectedRegion = nil
end

function CloseRegion(self)
	RemoveRegion(self)
	CloseMenu(self)
	-- CloseRegionWrapper(self)
end

function MiscMenu(self)
	local groupCmd
	if self.group~= nil then
		 groupCmd = {'Remove from group', self.RemoveFromGroup, self}
	else
		 groupCmd = {'Add to group', addGroupPicker, self}
	end
	
	if InputMode == 1 then
		cmdlist = {{'Add link', StartLinkRegion, self},
			groupCmd,
			-- {'Lock Movement', LockPos, self},
			{'Duplicate', DuplicateAction, self},
			{'Cancel', nil, nil}}
	elseif InputMode == 2 then
		cmdlist = {
			-- {'Add link', StartLinkRegion, self},
			groupCmd,
			-- {'Lock Movement', LockPos, self},
			-- {'Duplicate', testMenu, self},
			{'Cancel', nil, nil}}
	end
		
	menu = loadSimpleMenu(cmdlist, 'Command Menu')
	menu:present(self:Center())
end

function StartLinkRegionAction(r, draglet)
	draglet.isDragging = false
	StartLinkRegion(r, draglet)
end

function StartGroupSel(self)
	-- selection lasso for grouping, refactor this from bg selection gesture

	-- self is the menu button/draglet
	-- target is the parent region
	self.isDragging = true
	notifyView:ShowTimedText("select regions to group")
	local target = self.parent.v
	-- draw the potential link line here:
	Log:print(target:Name()..' rmenu drag_select')
	local x,y = self:Center()

	-- bgMove(self, x, y) old code moved here:
	Log:print('bg move '..x..' '..y)
	startedSelection = true
	shadow:Hide()
	CloseGroupMenu(lassoGroupMenu)
	
	-- change creation behavior to selection box/lasso
	if #selectionPoly > 0 then
		last = selectionPoly[#selectionPoly]
		if math.sqrt((x - last[1])^2 + (y - last[2])^2) > LASSOSEPDISTANCE then
			--more than the lasso point distance, add a new point to selection poly
			table.insert(selectionPoly, {x,y})
			selectionLayer:DrawSelectionPoly()
		end
	else
		table.insert(selectionPoly, {x,y})
		selectionLayer:DrawSelectionPoly()
	end

end

function GroupSelection(r, draglet)
	-- up on selection draglet, group selections
	CloseMenu(r)
	draglet.isDragging = false
	-- TODO group check selection
	local x,y = draglet:Center()
	bgDragletUp(r, x, y)
end

function StartLinkOnDrag(self)
	-- self is the menu button/draglet
	-- target is the parent region
	self.isDragging = true
	notifyView:ShowTimedText("drop on region to link")
	local target = self.parent.v
	-- draw the potential link line here:
	Log:print(target:Name()..' rmenu dragging')
	ShowPotentialLink(target, self)
end

function SwitchRegionTypeAction(r)
	-- SwitchRegionType(r)
	r:SwitchRegionType()
end

function DuplicateAction(r, draglet)
	if draglet ~= nil then
		draglet.isDragging=false
		x,y = draglet:Center()
		DuplicateRegion(r, x, y)
	else
		DuplicateRegion(r, ScreenWidth()/2, ScreenHeight()/2)
	end
end

function LockPos(r)
	r:ToggleMovement()
	CloseMenu(r)
	OpenRegionMenu(r)
end

function DupOnDrag(self)
	self.isDragging = true
	notifyView:ShowTimedText("drop to duplicate")
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

function DragGuideAnimationHandler(self, elapsed)
	-- handles animation guide for draglets
	
	if not self.isDragging then
		if not self.isWaiting then
			-- do animation
			local target = self.parent.v
			local pos = self.anchorpos
			
			if self.timer > DRAGLET_ANI_DUR then
				self.timer = 0
				self.isWaiting = true
				-- reset location
				self:SetAnchor("CENTER", target, buttonLocation[pos][1],
															buttonLocation[pos][2],
															buttonLocation[pos][3])
			else
				-- compute new position of draglet
				local delta = 1 - math.abs(self.timer - DRAGLET_ANI_DUR/2)
									/DRAGLET_ANI_DUR*2
				delta = -delta*DRAGLET_ANI_DIST + 1
				self:SetAnchor("CENTER", target,
															buttonLocation[pos][1],
															buttonLocation[pos][2]*delta,
															buttonLocation[pos][3]*delta)
			end
		else
			if self.timer > DRAGLET_ANI_DELAY then
				self.timer = 0
				self.isWaiting = false
			end
		end 
		self.timer = self.timer + elapsed
	end
end

local regionMenu = {}
-- label, func, anchor relative to region, image file, draggable or not

if InputMode == 1 then
	
	regionMenu.cmdList = {
		{"", CloseRegion, 1, "tw_closebox.png"},
		-- {"Link", StartLinkRegionAction, 3, "tw_socket1.png", StartLinkOnDrag, DragGuideAnimationHandler},
		-- {"", SwitchRegionTypeAction, 4, "tw_varswitcher.png"},
		-- {"", DuplicateAction, 5, "tw_dup.png", DupOnDrag, DragGuideAnimationHandler},
		{"", LoadInspector, 7, "tw_paint.png"},
		{"", MiscMenu, 5, "tw_more.png"},
		{"", LockPos, 6, "tw_unlock.png"}
		-- {"", CloseMenu, 8, "tw_socket1.png"}
	}
elseif InputMode == 2 then
	regionMenu.cmdList = {
		{"", CloseRegion, 1, "tw_closebox.png"},
		{"Link", StartLinkRegionAction, 3, "tw_socket1.png", StartLinkOnDrag, DragGuideAnimationHandler},
		-- {"", SwitchRegionTypeAction, 4, "tw_varswitcher.png"},
		{"", GroupSelection, 4, "texture/tw_group_sel.png", StartGroupSel, DragGuideAnimationHandler},
		{"", LockPos, 6, "tw_unlock.png"},
		{"", DuplicateAction, 5, "tw_dup.png", DupOnDrag, DragGuideAnimationHandler},
		{"", LoadInspector, 7, "tw_paint.png"},
		{"", MiscMenu, 8, "tw_more.png"}
	}
elseif InputMode == 3 then
	regionMenu.cmdList = {
		{"", CloseRegion, 1, "tw_closebox.png"},
		-- {"Link", StartLinkRegionAction, 3, "tw_socket1.png", StartLinkOnDrag, DragGuideAnimationHandler},
		-- {"", SwitchRegionTypeAction, 4, 	"tw_varswitcher.png"},
		{"", DuplicateAction, 5, "tw_dup.png", DupOnDrag, DragGuideAnimationHandler},
		{"", LoadInspector, 7, "tw_paint.png"},
		{"", LockPos, 6, "tw_unlock.png"}
		-- {"", MiscMenu, 8, "tw_more.png"}
	}
end

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
	menuObj.items = {}

	for _,item in pairs(menuObj.cmdList) do
		label = item[1]
		func = item[2]
		anchor = item[3]
		image = item[4]
		
		local r = Region('region','menu',UIParent)
		-- r.tl = r:TextLabel()
		-- r.tl:SetLabel("\n"..label)
		-- r.tl:SetVerticalAlign("TOP")
		-- r.tl:SetHorizontalAlign("CENTER")
		-- r.tl:SetFontHeight(13)
		-- r.tl:SetFont("Avenir Next")
		-- r.tl:SetColor(0,0,0,255) 	
		r.t = r:Texture(image)
		r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
		r.t:SetBlendMode("BLEND")
		r:SetLayer("TOOLTIP")
		r:SetHeight(BUTTONSIZE)
		r:SetWidth(BUTTONSIZE)
		r:MoveToTop()
		r:Hide()

		r.func = func
		r.anchorpos = anchor
		r.parent = menuObj
		r.draglet = item[5]
		r.aniHandler = item[6]
		r.isDragging = false
		r.timer = 0
		r.isWaiting = true
		r.downState = false
		
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
-- initMenus(linkMenu)
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
	for i = 1,#regions do
		regions[i].menu = nil
	end
	
	regionMenu.v = self
	
	-- modify menu based on context
	-- group?
	if InputMode == 2 then
		--only for icon based mode
		if self.group~=nil then
			-- don't show
			local r = regionMenu.items[3]
			r.t = r:Texture("texture/tw_group_remove.png")
			r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
			r.t:SetBlendMode("BLEND")
			r.func = self.RemoveFromGroup
			r.draglet = nil
			r.aniHandler = nil
		else
			local r = regionMenu.items[3]
			r.t = r:Texture("texture/tw_group_sel.png")
			r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
			r.t:SetBlendMode("BLEND")
			r.func = GroupSelection
			r.draglet = StartGroupSel
			r.aniHandler = DragGuideAnimationHandler
		end
	end
	
	if self.canBeMoved then
		local r = regionMenu.items[4]
		r.t = r:Texture("texture/tw_pin_inactive.png")
		r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
		r.t:SetBlendMode("BLEND")
	else
		local r = regionMenu.items[4]
		r.t = r:Texture("texture/tw_pin_active.png")
		r.t:SetTexCoord(0,BUTTONIMAGESIZE/128,BUTTONIMAGESIZE/128,0)
		r.t:SetBlendMode("BLEND")
	end
	
	for i = 1,#regionMenu.items do
		if regionMenu.items[i].draglet ~= nil then
			regionMenu.items[i]:EnableMoving(true)
			regionMenu.items[i]:Handle("OnDragging", regionMenu.items[i].draglet)
			regionMenu.items[i]:Handle("OnUpdate", regionMenu.items[i].aniHandler)
			-- need to stop animation when user interact
			-- regionMenu.items[i]:Handle("OnTouchDown", nil)
			regionMenu.items[i].isDragging = false
		end
				
		regionMenu.items[i]:Handle("OnTouchDown", MenuDown)
		regionMenu.items[i]:Handle("OnTouchUp", OptEventFunc)
		local pos = regionMenu.items[i].anchorpos
		regionMenu.items[i]:SetAnchor("CENTER", self,
													buttonLocation[pos][1],
													buttonLocation[pos][2],
													buttonLocation[pos][3])
		regionMenu.items[i]:MoveToTop()
		regionMenu.items[i]:EnableInput(true)
		regionMenu.items[i]:Show()
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
	Log:print(self:Name()..' rmenu opened')
	OpenMenu(self)
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
	for i = 1,#regionMenu.items do
		regionMenu.items[i]:Hide()
		regionMenu.items[i]:EnableInput(false)
		regionMenu.items[i]:Handle("OnTouchUp", nil)
		regionMenu.items[i]:Handle("OnUpdate", nil)
		regionMenu.items[i]:Handle("OnTouchDown", nil)
	end
	regionMenu.show = 0
	regionMenu.v = nil
	self.menu = nil
	
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
	Log:print(self:Name()..' rmenu closed')
end

-- function SwitchToLinkMenu()
-- 	for i = 1,#regionMenu.items do
-- 		regionMenu.items[i]:Hide()
-- 		regionMenu.items[i]:EnableInput(false)
-- 		regionMenu.items[i]:Handle("OnTouchUp", nil)
-- 		regionMenu.items[i]:Handle("OnUpdate", nil)
--     end
-- end

function MenuDown(self)
	self.downState = true
end

-- this actually calls all the menu function on the right region(s)
function OptEventFunc(self)
	if self:ReadHandle("OnUpdate") ~= nil then
		self:Handle("OnUpdate", nil)
	end
	
	Log:print(self.parent.v:Name()..' rmenu cmd_activated')
	
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
	linkMenu.link = l
	
	return linkMenu
end

function HideLinkMenu(menu)
	if menu then
		menu.r:Hide()
		menu.r:EnableInput(false)
		menu.r:Handle("OnTouchUp", CallLinkFunc)
	end
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
	
function DeleteLinkMenu(menu)
	CloseLinkMenu(menu)
	-- menu = self.parent
	table.insert(recycledLinkMenu, menu)
end

-- =============================
-- = private link menu methods =
-- =============================

function CallLinkFunc(self)
	-- use this to call function on the link menu button
	-- because we have reference to the link, not just one region
	-- CloseLinkMenu(self)	
	self.func(self.parent.link)
end

function CloseLinkMenu(self)
	self.r:Hide()
	self.r:EnableInput(false)
end