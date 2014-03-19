-- ================
-- = Event Bubble =
-- ================
-- event notification bubble, should later be turn into a draggable menu
-- singleton class, or not really a class, just a table, always on top region

STAY_TIME = 1.5
bubbleView = {}
menu = {}
function bubbleView:Init()
	self.r = Region('region', 'event', UIParent)
	self.r:SetLayer("TOOLTIP")
	self.r:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()-25)
	self.r.t = self.r:Texture("texture/tw_bubble.png")
	self.r.t:SetBlendMode("BLEND")
	
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetFontHeight(20)
	self.r.tl:SetFont("Avenir Next Condensed")
	self.r.tl:SetColor(255,255,255,255)
	self.r.tl:SetShadowColor(0,0,0,0)
	self.r.tl:SetHorizontalAlign("CENTER")
	-- self.r.tl:SetVerticalAlign("MIDDLE")
	self.r.timer = 0
	self.r.region=NULL
	self.r.o = self

	self.r.sizeChangeSpeed = 0
	self.r.w = 120
	self.r.h = 120
	
	self.r:Handle("OnTouchDown", bubbleView.OnTouchDown)
	self.r:Handle("OnTouchUp", bubbleView.OnTouchUp)
end

function bubbleView:ShowEvent(text, region, menu)
	self.showMenu = menu
	if self.r:IsVisible() and region == self.r.region then
		self.r.tl:SetLabel(text)
		self.r:SetAlpha(1)
		self.r.timer = STAY_TIME
		return
	end
	
	self.r:SetAnchor('BOTTOM', region,'TOP')
	self.r.region = region
	self.r:SetWidth(10)
	self.r:SetHeight(10)	
	self.r.sizeChangeSpeed = 15

	self.r:Show()
	self.r:SetAlpha(1)
	self.r.tl:SetLabel(text)
	self.r:MoveToTop()
	
	self.r.timer = STAY_TIME
	self.r:Handle("OnUpdate", bubbleUpdate)
	self.r:EnableInput(true)
	
end

function bubbleView:Dismiss()
	if self.r:IsVisible() then
		self.r:EnableInput(false)
		self.r.timer = 0
		self.r:Handle("OnUpdate", bubbleUpdate)
	end
end

function bubbleUpdate(self, e)
	-- FIXME this animation code isn't working yet, add spring physics
	-- 
	
	if self:Height() < self.h then
		local curH = self:Height()
		local curW = self:Width()
		-- DPrint('trying to animate'..self.h..' '..self:Height())
		
		curH = curH + e*(self.h-curH)*self.sizeChangeSpeed
		curW = curW + e*(self.w-curW)*self.sizeChangeSpeed

		self:SetHeight(curH)
		self:SetWidth(curW)
		self.tl:SetHorizontalAlign("JUSTIFY")
		self.tl:SetVerticalAlign("MIDDLE")
	end
	
	
	if self.timer > 0 then
		self.timer = math.max(self.timer - e, 0)
		return
	end
	
	
	if self:Alpha() > 0 then
		if self:Alpha() < EPSILON then -- just set if it's close enough
			self:SetAlpha(0)
			self:Hide()
			self:EnableInput(false)
			self:Handle("OnUpdate", nil)
		else
			self:SetAlpha(self:Alpha() - self:Alpha() * e/FADEINTIME)
			if self:Alpha()< 0.6 then
				self:EnableInput(false)
			end			
		end
	end	
end

function bubbleView:OnTouchDown()
	-- if self:IsVisible() then
	-- 	self:SetAlpha(1)
	-- 	self.timer = STAY_TIME
	-- 
	-- 	cmdlist = {{'Move',nil, nil},
	-- 		{'Touch', nil, nil},
	-- 		{'More...', nil, nil}}
	-- 	menu = loadGestureMenu(cmdlist, 'select events')
	-- 	menu:present(self:Center())
	-- 	
	-- end
end


function bubbleView:OnTouchUp()
	if self:IsVisible() and self.o.showMenu then
		self:SetAlpha(1)
		self.timer = STAY_TIME
	
		if self.region.canBeMoved then
			cmdname = 'Restrict Movement'
		else
			cmdname = 'Free Movement'
		end
		DPrint(self.region:Name())
		cmdlist = {{cmdname, toggleMoveRetriction, self.region},
			{'Cancel', nil, nil}}
					
		menu = loadSimpleMenu(cmdlist, 'Restrict Movement within Container?')
		menu:present(self:Center())
	end
end

function toggleMoveRetriction(r)
	menu:dismiss()
	r:ToggleAnchor()
	r:SetAnchor('CENTER', r.group.r, 'CENTER', 0, 0)	
	
end