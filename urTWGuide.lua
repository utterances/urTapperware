-- ==============
-- = Guide View =
-- ==============
-- shows gesture guides, visual, tutorial

PING_TIME = .7
PING_RATE = 900
PATH_Y_OFFSET = 20
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
	-- self.r.t:SetBrushSize(7)
	self.r:Hide()

	self.r.parent = self
	
	-- properties for animations
	self.r.timer = 0
	self.r.ping = false
	self.r.pingx = 0
	self.r.pingy = 0
	self.r.pingsize = 0
	
	self.r.needsUpdate = false
	self.isDrawing = false
	
	self.regions = {}
	
	-- init focus/spotlight
	self.focusOverlay = Region('region', 'focus', self.r)
	self.focusOverlay:SetLayer("TOOLTIP")
	self.focusOverlay:SetWidth(2000)
	self.focusOverlay:SetHeight(2000)
	self.focusOverlay.t = self.focusOverlay:Texture("texture/tw_focuslight.png")
	self.focusOverlay.t:SetBlendMode("BLEND")
	self.focusOverlay:Hide()
	self.focusOverlay:EnableInput(false)
	
	-- init gesture overlays, these fade out or in depends
	self.gestOverlays = {}
	for i=1,2 do
		local r = Region('region', 'gestO', self.r)
		r:SetLayer("TOOLTIP")
		if i==1 then
			r.t = r:Texture("texture/tw_gestCenter.png")
		else
			r.t = r:Texture("texture/tw_gestRed.png")
			r:SetWidth(1100)
			r:SetHeight(1100)
		end
		r.t:SetBlendMode("BLEND")
		r:SetAlpha(.7)
		r:Hide()
		table.insert(self.gestOverlays, r)
	end
	
	self.arrows = {}
	for i=1,2 do
		local r = Region('region', 'arrow', self.r)
		r:SetLayer("TOOLTIP")
		r:SetWidth(512)
		r:SetHeight(512)
		r.t = r:Texture("tw_arrow.png")
		r.t:SetBlendMode("BLEND")
		r:Hide()
		table.insert(self.arrows, r)
	end
end

function guideView:ShowPing(x,y)
	-- DPrint('show ping')
	self.r.pingx = x
	self.r.pingy = y
	self.r.ping = true
	self.r.pingsize = 150
	self.r.timer = PING_TIME
	self.r:MoveToTop()
	self.r.t:Clear(0,0,0,0)
	self.r:Show()
	self.r.needsUpdate = false
	self.r:Handle("OnUpdate", guideUpdate)
end

function guideView:ShowPath(regions)
	self.regions = regions
	self.r.needsUpdate = true
	
	-- if not self.isDrawing then
		self.isDrawing = true
		self.r:Show()
		self.r:Handle("OnUpdate", guideUpdate)
	-- end
end

function guideView:ShowArrow(region)	
	self.arrows[1]:SetAnchor("CENTER",region,'CENTER',0,0)
	self.arrows[1]:Show()
end

function guideView:ShowSpotlight(region)
	self.focusOverlay:SetAnchor("CENTER", region, "CENTER", 0, 0)
	self.focusOverlay:Show()
end

function guideView:ShowGesturePull(r1, r2)
	local gr = self.gestOverlays[2] --this is the pull one
	x1,y1 = r1:Center()
	x2,y2 = r2:Center()

	gr:SetAnchor('CENTER',(x1+x2)/2, (y1+y2)/2)
	gr.t:SetRotation(math.atan2(x2-x1, y1-y2))
	
	gr:Show()
end

function guideView:UpdatePull(deg)
	r=self.gestOverlays[2]

	r:SetAlpha(deg)
end

function guideView:UpdateCenter(deg)
	r=self.gestOverlays[1]

	r:SetAlpha(deg)	
end

function guideView:ShowGestureCenter(r1, r2)
	local gr = self.gestOverlays[1] --this is the pull one
	x1,y1 = r1:Center()
	x2,y2 = r2:Center()

	gr:SetAnchor('CENTER',(x1+x2)/2, (y1+y2)/2)
	gr.t:SetRotation(math.atan2(x2-x1, y1-y2))
	gr:MoveToTop()
	
	gr:Show()
end

function guideView:Disable()
	self.r.needsUpdate = false
	self.isDrawing = false
	self.regions = {}
	-- if self.timer == 0 then
	self.r:Handle("OnUpdate", nil)
	self.r:Hide()
	-- end
	self.arrows[1]:Hide()
	self.focusOverlay:Hide()
	
	for i =1,2 do
		self.gestOverlays[i]:Hide()
	end
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
		self.t:SetBrushSize(12)
		self.t:Ellipse(self.pingx, self.pingy, self.pingsize, self.pingsize)
		self.pingsize = self.pingsize + e*PING_RATE
	end
	
	if self.needsUpdate then
		-- draw guide path here, vector possibly too
		self.t:Clear(0,0,0,0)
		for i = 1,#self.parent.regions do
			x1 = self.parent.regions[i].rx
			y1 = self.parent.regions[i].ry + PATH_Y_OFFSET
			
			for j = 1,#self.parent.regions[i].movepath do
				x2=x1 + self.parent.regions[i].movepath[j](deltax)
				y2=y1 + self.parent.regions[i].movepath[j](deltay)

				self.t:SetBrushSize(3)
				self.t:Line(x1,y1,x2,y2)
				
				x1 = x2
				y1 = y2
			end
		end
		self.needsUpdate = false
	end
end