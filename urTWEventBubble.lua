-- ================
-- = Event Bubble =
-- ================
-- event notification bubble, should later be turn into a draggable menu
-- singleton class, or not really a class, just a table, always on top region

FADE_RATE = .8
STAY_TIME = 3.0
bubbleView = {}

function bubbleView:Init()
	self.r = Region('region', 'event', UIParent)
	self.r:SetLayer("TOOLTIP")
	self.r:SetWidth(120)
	self.r:SetHeight(120)
	self.r:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()-25)
	self.r.t = self.r:Texture("texture/tw_bubble.png")
	self.r.t:SetBlendMode("BLEND")
	
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetFontHeight(20)
	self.r.tl:SetFont("Avenir Next Condensed")
	self.r.tl:SetColor(255,255,255,255)
	self.r.tl:SetHorizontalAlign("CENTER")
	-- self.r.tl:SetVerticalAlign("MIDDLE")
	self.r.timer = 0
	self.r.region=NULL
	
	self.r:Handle("OnTouchDown", bubbleView.OnTouchDown)
	self.r:Handle("OnTouchUp", bubbleView.OnTouchUp)

end

function bubbleView:ShowEvent(text, region)
	if self.r:IsVisible() and region == self.r.region then
		self.r.tl:SetLabel('event:\n'..text..'\n')
		self.r:SetAlpha(1)
		self.r.timer = STAY_TIME
		return
	end
	
	self.r:SetAnchor('BOTTOM', region,'TOP')
	self.r.region = region
-- region:SetAnchor("anchorLocation", relativeRegion, "relativeAnchorLocation", offsetX, offsetY)
	self.r:Show()
	self.r:SetAlpha(1)
	self.r.tl:SetLabel('event:\n'..text..'\n')
	self.r:MoveToTop()
	
	self.r.timer = STAY_TIME
	self.r:Handle("OnUpdate", notifyUpdate)
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
	if self.timer > 0 then
		self.timer = math.max(self.timer - e, 0)
		return
	end
	
	if self:Alpha() > 0 then
		self:SetAlpha(self:Alpha() - self:Alpha() * e/FADE_RATE)
	else
		self:Hide()
		self:EnableInput(false)
		
		self:Handle("OnUpdate", nil)
	end
end

function bubbleView:OnTouchDown()
	if self:IsVisible() then
		self:SetAlpha(1)
		self.timer = STAY_TIME

		cmdlist = {{'Move',nil, nil},
			{'Touch', nil, nil},
			{'More...', nil, nil},
			{'Cancel', nil, nil}}
		menu = loadSimpleMenu(cmdlist, 'select events')
		menu:present(self:Center())
		
	end
end


function bubbleView:OnTouchUp()

end