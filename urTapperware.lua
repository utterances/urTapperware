-- urTapperware.lua
-- scratch pad for new stuff to add to urVen2, borrowed heavily from urVen code
-- focus on using touch for programming, avoid menu or buttons

-- A multipurpose non-programming environment aimed towards giving the user the ability
-- To create a increasingly more complex application without any coding on the users side.
-- The basis of the script is contained in this file while most of the features are contained
-- the accompianing scripts, listed below.

-- ==================================
-- = setup Global var and constants =
-- ==================================

CREATION_MARGIN = 40	-- margin for creating via tapping
INITSIZE = 140	-- initial size for regions
MENUHOLDWAIT = 0.4 -- seconds to wait for hold to menu

FADEINTIME = .2 -- seconds for things to fade in, TESTING for now
EPSILON = 0.001	--small number for rounding

-- selection param
LASSOSEPDISTANCE = 25 -- pixels between each point when drawing selection lasso

FreeAllRegions()
DPrint('')
--regions = {}
--recycledregions = {}
initialLinkRegion = nil
finishLinkRegion = nil
linkEvent = nil
linkEffect = nil
startedSelection = false
-- touch event state machine:
-- isHoldingRegion = false
heldRegions = {}
-- selection data structs
selectionPoly = {}
selectedRegions = {}


-- modes = {"EDIT","RELEASE"}
-- current_mode = modes[1]

dofile(DocumentPath("urTWTools.lua"))

dofile(DocumentPath("urTapperwareMenu.lua"))	-- first!
dofile(DocumentPath("urTWMenu.lua"))
dofile(DocumentPath("urTWLink.lua"))	-- needs menu
dofile(DocumentPath("urTWRegion.lua"))

dofile(DocumentPath("urTapperwareLinkLayer.lua"))	-- needs menu
dofile(DocumentPath("urTapperwareGroup.lua"))

-- ============
-- = Backdrop =
-- ============

function TouchDown(self)
	local x,y = InputPosition()
	
	shadow:Show()
	shadow:SetAnchor('CENTER',x,y)
end

function TouchUp(self)
	shadow:Hide()
	if startedSelection then
		startedSelection = false
		local tempSelected = {}
		for i = 1, #regions do
			if regions[i].usable then
				x,y = regions[i]:Center()
				if pointInSelectionPolygon(x,y) then
					table.insert(tempSelected, regions[i])
					ChangeSelectionStateRegion(regions[i], true)
				else
					ChangeSelectionStateRegion(regions[i], false)
				end
			end
		end
		if #tempSelected > 1 then
			selectedRegions = tempSelected
			x,y = InputPosition()
			OpenGroupMenu(lassoGroupMenu, x, y, selectedRegions)
		end
		selectionPoly = {}
		selectionLayer.t:Clear(0,0,0,0)
		return
	end
	
	-- only create if we are not too close to the edge
	local x,y = InputPosition()
	
	if x>CREATION_MARGIN and x<ScreenWidth()-CREATION_MARGIN and 
		y>CREATION_MARGIN and y<ScreenHeight()-CREATION_MARGIN then
		local region = TWRegion:new(nil,updateEnv)		
		region:Show()
		region:SetAnchor("CENTER",x,y)
		-- DPrint(region:Name().." created at "..x..", "..y)
	end
	
	startedSelection = false
end

function Move(self)
	startedSelection = true
	shadow:Hide()
	CloseGroupMenu(lassoGroupMenu)
	
	-- change creation behavior to selection box/lasso
	local x,y = InputPosition()
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

function Leave(self)
	shadow:Hide()
	DPrint("")
end

backdrop = Region('region', 'backdrop', UIParent)
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:SetLayer("BACKGROUND")
backdrop:SetAnchor('BOTTOMLEFT',0,0)
backdrop:Handle("OnTouchDown", TouchDown)
backdrop:Handle("OnTouchUp", TouchUp)
backdrop:Handle("OnDoubleTap", DoubleTap)
backdrop:Handle("OnEnter", Enter)
backdrop:Handle("OnLeave", Leave)
backdrop:Handle("OnMove", Move)
backdrop:Handle("OnPageEntered", visdown)

backdrop:EnableInput(true)
backdrop:SetClipRegion(0,0,ScreenWidth(),ScreenHeight())
backdrop:EnableClipping(true)
backdrop.player = {}
backdrop.t = backdrop:Texture("tw_paperback.jpg")
backdrop.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
backdrop.t:SetBlendMode("BLEND")
backdrop:Show()

-- set up shadow for when tap down and hold, show future region creation location
shadow = Region('region', 'shadow', UIParent)
shadow:SetLayer("BACKGROUND")
shadow.t = shadow:Texture("tw_roundrec_create.png")
shadow.t:SetBlendMode("BLEND")

-- set up layer for drawing selection boxes or lasso:
selectionLayer = Region('region', 'selection', UIParent)
selectionLayer:SetLayer("BACKGROUND")
selectionLayer:SetWidth(ScreenWidth())
selectionLayer:SetHeight(ScreenHeight())
selectionLayer:SetAnchor('BOTTOMLEFT',0,0)
selectionLayer:EnableInput(false)
selectionLayer.t = selectionLayer:Texture()
selectionLayer.t:Clear(0,0,0,0)
selectionLayer.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
selectionLayer.t:SetBlendMode("BLEND")
selectionLayer:Show()

-- tapVisLayer = Region()
-- tapVisLayer:SetLayer("TOOLTIP")
-- tapVisLayer:SetWidth(ScreenWidth())
-- tapVisLayer:SetHeight(ScreenHeight())
-- tapVisLayer:SetAnchor('BOTTOMLEFT',0,0)
-- tapVisLayer:EnableInput(false)
-- tapVisLayer.t = tapVisLayer:Texture()
-- tapVisLayer.t:Clear(0,0,0,0)
-- tapVisLayer.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
-- tapVisLayer.t:SetBlendMode("BLEND")
-- tapVisLayer:Show()

-- tapVisLayer:Handle("OnPageEntered", visdown)

-- function visdown()
-- 	local x,y = InputPosition()
-- 	DPrint('down '..x..' '..y)
-- 	tapVisLayer.t:SetBrushColor(255,100,100,200)
-- 	tapVisLayer.t:Ellipse(x,y,w,h)
-- end
-- 
-- function visup()
-- 	local x,y = InputPosition()
-- 	DPrint('up '..x..' '..y)
-- end

function selectionLayer:DrawSelectionPoly()
	if #selectionPoly < 2 then	-- need at least two points to draw
		return
	end
	
	self.t:Clear(0,0,0,0)
	self.t:SetBrushColor(255,255,255,200)
	self.t:SetBrushSize(3)
	
	local lastPoint = selectionPoly[#selectionPoly]
	for i = 2,#selectionPoly do
		self.t:Line(lastPoint[1], lastPoint[2],
			selectionPoly[i][1], selectionPoly[i][2])
		lastPoint = selectionPoly[i]
	end
	
	-- also draw boxes around *selected* regions
	
	for i = 1, #regions do
		if regions[i].usable then
			x,y = regions[i]:Center()
			if pointInSelectionPolygon(x,y) then
				w = regions[i]:Width()/1.5
				h = regions[i]:Height()/1.5
				self.t:SetBrushColor(255,100,100,200)
				self.t:Ellipse(x,y,w,h)
			end
		end
	end
end

-- function selectionLayer:DrawSelectionRegions()
-- 	self.t:Clear(0,0,0,0)
-- 	self.t:SetBrushColor(255,255,255,200)
-- 	self.t:SetBrushSize(3)
-- 	
-- 	for i = 1, #selectedRegions do
-- 		x,y = selectedRegions[i]:Center()
-- 		w = selectedRegions[i]:Width()/2
-- 		h = selectedRegions[i]:Height()/2
-- 		self.t:Rect(x-w,y-h,x+w,y+h)
-- 	end
-- end

function pointInSelectionPolygon(x, y)
	-- find if a point is in our selection
	-- adapted from C code: http://alienryderflex.com/polygon/
	-- simple ray casting algo
	oddNodes = false
	j=#selectionPoly
	
	for i=1, #selectionPoly do		
		if ((selectionPoly[i][2] < y and selectionPoly[j][2] >=y
					or   selectionPoly[j][2]< y and selectionPoly[i][2]>=y)
				and  (selectionPoly[i][1]<=x or selectionPoly[j][1]<=x)) then
			
			if (selectionPoly[i][1]+(y-selectionPoly[i][2])
					/(selectionPoly[j][2]-selectionPoly[i][2])
					*(selectionPoly[j][1]-selectionPoly[i][1])<x) then
				oddNodes = not oddNodes
			end
		end
		j=i
	end
	return oddNodes
end

-- link action icon, shows briefly when a link is made
linkIcon = Region('region', 'linkicon', UIParent)
linkIcon:SetLayer("TOOLTIP")
linkIcon.t = linkIcon:Texture("tw_link.png")
linkIcon.t:SetBlendMode("BLEND")
linkIcon.t:SetTexCoord(0,160/256,160/256,0)
linkIcon:SetWidth(100)
linkIcon:SetHeight(100)
linkIcon:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()/2)

function linkIcon:ShowLinked(x,y)
	self:Show()
	self:SetAlpha(1)
	self:MoveToTop()
	self:Handle("OnUpdate", IconUpdate)
end

function IconUpdate(self, e)
	if self:Alpha() > 0 then
		self:SetAlpha(self:Alpha() - self:Alpha() * e/.7)
	else
		self:Hide()
		self:Handle("OnUpdate", nil)
	end
end

linkLayer:Init()

--To Be Moved To Region

function ToggleMenu(self)
	if self.menu == nil then
		OpenRegionMenu(self)
	else
		CloseMenu(self)
	end
end

function HoldToTrigger(self, elapsed) -- for long tap
	x,y = self:Center()
	
	if self.holdtime <= 0 then
		self.x = x 
		self.y = y
		DPrint("trying menu")
		if self.menu == nil then
			OpenRegionMenu(self)
		else
			CloseMenu(self)
		end
		self:Handle("OnUpdate",nil)
	else 
		if math.abs(self.x - x) > 10 or math.abs(self.y - y) > 10 then
			self:Handle("OnUpdate", nil)
			self:Handle("OnUpdate", self.Update)
		end
		if self.holdtime < MENUHOLDWAIT/2 then
			DPrint("hold for menu")
		end
		self.holdtime = self.holdtime - elapsed
	end
end

function HoldTrigger(self) -- for long tap
	DPrint("starting hold")
	self.holdtime = MENUHOLDWAIT
	self.x,self.y = self:Center()
	self:Handle("OnUpdate", nil)
	self:Handle("OnUpdate", HoldToTrigger)
	self:Handle("OnLeave", DeTrigger)
end

function DeTrigger(self) -- for long tap
	self.eventlist["OnUpdate"].currentevent = nil
	self:Handle("OnUpdate", nil)
	self:Handle("OnUpdate", self.Update)
end
---------------
function CloseRegionWrapper(self)
	RemoveRegion(self)
end

function AddOneToCounter(self)
	-- DPrint("adding one")
	if self.counter == 1 then
		self.value = self.value + 1
		self.tl:SetLabel(self.value)
	end
end

function ChangeSelectionStateRegion(self, select)
	if select ~= self.isSelected then
		if select then
			self.t:SetTexture("tw_roundrec_s.png")
			self.tl:SetColor(0,0,0,255)
		else
			if self.counter == 1 then
				self.t:SetTexture("tw_roundrec_slate.png")
				self.tl:SetColor(255,255,255,255)
			else
				self.t:SetTexture("tw_roundrec.png")
			end
		end
	end
	
	self.isSelected = select
end

function StartLinkRegion(self, draglet)
	initialLinkRegion = self
	
	if draglet ~= nil then
		-- if we have drag target, try creating a link right away
		tx, ty = draglet:Center()
		for i = 1, #regions do
			if regions[i] ~= self and regions[i].usable then
				DPrint("try link "..self:Name().." "..regions[i]:Name())
				rx, ry = regions[i]:Center()
				if math.abs(tx-rx) < INITSIZE and math.abs(ty-ry) < INITSIZE then
					-- found a match, create a link here
					ChooseEvent(regions[i])
					return
				end
			end
		end
		
		initialLinkRegion = nil
		CloseMenu(self)
		OpenRegionMenu(self)
	else
		-- otherwise ask for a target
		DPrint("Tap another region to link")
	end
end

menu = nil

function ChooseEvent(self)
	if initialLinkRegion ~= nil then		
		finishLinkRegion = self
		cmdlist = {{'Tap', ChooseAction, 'OnTouchUp'},
			{'Tap & Hold', ChooseAction, 'OnTapAndHold'},
			{'Move', ChooseAction, 'OnUpdate_Move'},
			{'Cancel', nil, nil}}
		menu = loadSimpleMenu(cmdlist, 'Choose Event:')
		menu:present(initialLinkRegion:Center())
	end
end

function ChooseAction(message)
	linkEvent = message
	DPrint(linkEvent)
	
	menu:dismiss()
	
	cmdlist = {{'Counter',FinishLink,AddOneToCounter},
		{'Move Left', FinishLink, MoveLeft},
		{'Move Right', FinishLink, MoveRight},
		{'Move', FinishLink, move},
		{'Cancel', nil, nil}}
	menu = loadSimpleMenu(cmdlist, 'Choose Action to respond')
	menu:present(finishLinkRegion:Center())
end

function FinishLink(message)
	-- DPrint("linked from "..initialLinkRegion:Name().." to "..finishLinkRegion:Name())
	
	linkEffect = message
	menu:dismiss()
	
	local link = link:new(initialLinkRegion,finishLinkRegion,linkEvent,linkEffect)
	
	linkLayer:ResetPotentialLink()
	linkLayer:Draw()
	-- add notification
	linkIcon:ShowLinked()
	
	CloseMenu(initialLinkRegion)
	initialLinkRegion = nil
	finishLinkRegion = nil
end

function DuplicateRegion(r, cx, cy)
	x,y = r:Center()
	
	local newRegion = r:Copy(cx, cy)
	
	linkLayer:Draw()
	
	newRegion:RaiseToTop()
	
	CloseMenu(r)
	OpenRegionMenu(r)
end

-- function SwitchRegionType(self)
-- 	self:SwitchRegionType()
-- end

function ShowPotentialLink(region, draglet)
	linkLayer:DrawPotentialLink(region, draglet)
end

function RegionOverLap(r1, r2)
	x1,y1 = r1:Center()
	x2,y2 = r2:Center()
	return (r1:Width() + r2:Width())/1.8 > math.abs(x1-x2) and 
	(r1:Height() + r2:Height())/1.8 > math.abs(y1-y2)
end

function sendEvent(region, event) 
	region:event()
end

function updateEnv()
	linkLayer:Draw()
end

----------------- v11.pagebutton -------------------
local pagebutton=Region('region', 'pagebutton', UIParent)
pagebutton:SetWidth(pagersize)
pagebutton:SetHeight(pagersize)
pagebutton:SetLayer("TOOLTIP")
pagebutton:SetAnchor('BOTTOMLEFT',ScreenWidth()-pagersize-4,ScreenHeight()-pagersize-4)
pagebutton:EnableClamping(true)
pagebutton:Handle("OnTouchDown", FlipPage)
pagebutton.texture = pagebutton:Texture("circlebutton-16.png")
pagebutton.texture:SetGradientColor("TOP",255,255,255,255,255,255,255,255)
pagebutton.texture:SetGradientColor("BOTTOM",255,255,255,255,255,255,255,255)
pagebutton.texture:SetBlendMode("BLEND")
pagebutton.texture:SetTexCoord(0,1.0,0,1.0)
pagebutton:EnableInput(true)
pagebutton:Show()
