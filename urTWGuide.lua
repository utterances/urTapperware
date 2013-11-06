-- ==============
-- = Guide View =
-- ==============
-- shows gesture guides, visual, tutorial

FADE_RATE = .8
PING_TIME = 1
guideView = {}

function guideView:Init()	
	self.r = Region('region', 'guide', UIParent)
	self.r:SetLayer("TOOLTIP")
	self.r:SetWidth(ScreenWidth())
	self.r:SetHeight(ScreenHeight())
	self.r:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()/2)
	self.r.t = self.r:Texture()
	self.r.t:SetBlendMode("BLEND")
	self.r.t:Clear(0,0,0,0)
	self.r.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
	self.r.t:SetBrushColor(255,146,2)
	self.r.t:SetBrushSize(5)
	
	self.r:Hide()

	-- properties for animations
	self.r.timer = 0
	self.r.ping = false
	self.r.pingx = 0
	self.r.pingy = 0
	self.r.pingsize = 0
	
	self.arrows = {}
	for i=1,2 do
		local r = Region('region', 'arrow', self.r)
		r:SetLayer("TOOLTIP")
		r:SetWidth(250)
		r:SetHeight(250)
		r.t = r:Texture("tw_arrow.png")
		r.t:SetBlendMode("BLEND")
		r:Hide()
		table.insert(self.arrows, r)
	end
end

function guideView:ShowPing(x,y)
	self.r.pingx = x
	self.r.pingy = y
	self.r.ping = true
	self.r.pingsize = 200
	self.r.timer = PING_TIME
	self.r.t:Clear(0,0,0,0)
	self.r:Show()
	self.r:MoveToTop()	
	self.r:Handle("OnUpdate", guideUpdate)
end

function guideUpdate(self, e)
	if self.timer > 0 then
		self.timer = math.max(self.timer - e, 0)
		if self.timer == 0 then
			self:Handle("OnUpdate", nil)
			self:Hide()
		end
		
		-- draw the ping circle here, and then compute next size
		self.t:Clear(0,0,0,0)
		self.t:Ellipse(self.pingx, self.pingy, self.pingsize, self.pingsize)
		self.pingsize = self.pingsize + e*300
		
	end
end