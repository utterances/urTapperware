-- =====================
-- = Notification view =
-- =====================
-- generic notification view that drops down on top of the canvas
-- singleton class, or not really a class, just a table, always on top region

-- link action icon, shows briefly when a link is made

FADE_RATE = .8
notifyView = {}

function notifyView:Init()
	self.r = Region('region', 'notify', UIParent)
	self.r:SetLayer("TOOLTIP")
	self.r:SetWidth(768)
	self.r:SetHeight(50)
	self.r:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()-25)
	self.r.t = self.r:Texture()
	self.r.t:SetBlendMode("BLEND")
	self.r.t:Clear(30,30,30,100)
	
	self.r.tl = self.r:TextLabel()
	self.r.tl:SetFontHeight(24)
	self.r.tl:SetFont("Avenir Next Condensed")
	self.r.tl:SetColor(255,255,255,255)
	self.r.tl:SetHorizontalAlign("CENTER")
	self.r.tl:SetVerticalAlign("MIDDLE")
	self.r.timer = 0
end

function notifyView:ShowText(text)
	self.r:Show()
	self.r:SetAlpha(1)
	self.r.tl:SetLabel(text)
	self.r:MoveToTop()
	self.r:Handle("OnUpdate", nil)
end

function notifyView:Dismiss()
	if self.r:IsVisible() then
		self.r.timer = 0
		self.r:Handle("OnUpdate", notifyUpdate)
	end
end

function notifyView:ShowTimedText(text, time)
	self:ShowText(text)

	self.r.timer = time or 2.0
	self.r:Handle("OnUpdate", notifyUpdate)
end

function notifyUpdate(self, e)
	if self.timer > 0 then
		self.timer = math.max(self.timer - e, 0)
		return
	end
	
	if self:Alpha() > 0 then
		self:SetAlpha(self:Alpha() - self:Alpha() * e/FADE_RATE)
	else
		self:Hide()
		self:Handle("OnUpdate", nil)
	end
end