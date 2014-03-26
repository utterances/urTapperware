-- ==============
-- = Guide View =
-- ==============
-- shows gesture guides, visual, tutorial

PING_TIME = .7
PING_RATE = 900
PATH_Y_OFFSET = 20
ANIMATED_GUIDE_TIMER = 3.5
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
	self.r.aniGuideTimer = -1
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
	for i=1,3 do
		local r = Region('region', 'gestO', self.r)
		r:SetLayer("TOOLTIP")
		if i==1 then
			r.t = r:Texture("texture/tw_gestCenter.png")
			r:SetWidth(330)
			r:SetHeight(330)
		elseif i == 2 then
			r.t = r:Texture("texture/tw_gestRed.png")
			r:SetWidth(1100)
			r:SetHeight(1100)
		else
			r.t = r:Texture("texture/tw_dropGuideZoneSolid.png")
			r:SetWidth(400)
			r:SetHeight(400)
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


	self.touchGuides = {}
	for i=1,2 do
		local r = Region('region', 'tg', self.r)
		r:SetLayer("TOOLTIP")
		r:SetWidth(90)
		r:SetHeight(90)
		r.t = r:Texture("texture/tw_gestTouch.png")
		r.t:SetBlendMode("BLEND")
		r:SetAlpha(.6)
		r:Hide()
		table.insert(self.touchGuides, r)
	end

	
	-- init focus/spotlight
	-- self.linkGuide = Region('region', 'focus', self.r)
	-- self.linkGuide:SetLayer("TOOLTIP")
	-- self.linkGuide:SetWidth(2000)
	-- self.linkGuide:SetHeight(2000)
	-- self.linkGuide.t = self.linkGuide:Texture("texture/tw_linkGuide.png")
	-- self.linkGuide.t:SetBlendMode("BLEND")
	-- self.linkGuide:Hide()
	-- self.linkGuide:SetAlpha(0)
	-- self.linkGuide:EnableInput(false)
	
	-- init focus/spotlight
	self.dropGuide = Region('region', 'focus', self.r)
	self.dropGuide:SetLayer("TOOLTIP")
	self.dropGuide:SetWidth(300)
	self.dropGuide:SetHeight(300)
	self.dropGuide.t = self.dropGuide:Texture("texture/tw_dropGuideZone.png")
	self.dropGuide.t:SetBlendMode("BLEND")
	self.dropGuide:SetAlpha(.9)
	self.dropGuide:EnableInput(false)
	self.dropGuide:Hide()
	
	self.showDrop = true
	self.showLink = true
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

function guideView:ShowGestureLink(r1, r2, deg)
	local x1,y1 = r1:Center()
	local x2,y2 = r2:Center()	
	
	for i =1,2 do
		local gr = self.gestOverlays[i]

		-- compute alpha 1- center, 2- outter
		if i==1 then
			gr:SetAlpha(-deg*.6+.4) -- little overlap here
		else
			gr:SetAlpha(deg*.6+.4)
		end
		gr:SetAnchor('CENTER',(x1+x2)/2, (y1+y2)/2)
		gr.t:SetRotation(math.atan2(x2-x1, y1-y2))
		
		gr:Show()
	end
end

function guideView:UpdateLinkGuide(deg)
	r=self.gestOverlays[1]
	r:SetAlpha(deg)	
end

function guideView:ShowTwoTouchGestureGuide(r1, r2)
	-- set up animated guides, moving path
	if self.r.aniGuideTimer >=0 then
		return
	end
	
	self.showDrop = true
	self.showLink = true
	
	local x1,y1 = r1:Center()
	local x2,y2 = r2:Center()
	self.r.s_x = {x1,x2}
	self.r.s_y = {y1,y2}
	
	local dx = math.abs(x1-x2)/2.5
	local dy = math.abs(y1-y2)/2.5
	
	if r1:HasLinkTo(r2) or r2:HasLinkTo(r1) then
		-- show disconnect link guide instead
		dx = -dx
		dy = -dy
		self.r.guideText = 'Pull Apart to Disconnect'
	else
		self.r.guideText = 'Push Together to Connect'
	end
	
	if x1 > x2 then
		self.r.e_x = {x1-dx,x2+dx}
	else
		self.r.e_x = {x1+dx,x2-dx}
	end
	
	if y1 > y2 then
		self.r.e_y = {y1-dy,y2+dy}
	else
		self.r.e_y = {y1+dy,y2-dy}
	end
	
	for i=1,2 do
		self.touchGuides[i]:MoveToTop()
	end
	self.r.aniGuideTimer = 0
	self.r:Handle("OnUpdate", guideUpdateAniGuide)
end

function guideUpdateAniGuide(self, e)	
	-- onUpdate handle for touch animated guides
	
	if self.aniGuideTimer < ANIMATED_GUIDE_TIMER/4 and self.parent.showLink then
		-- first half, do pinch/pull
		self.parent.dropGuide:Hide()
		
		for i =1,2 do
			local dPercent = self.aniGuideTimer/ANIMATED_GUIDE_TIMER*4
			local newx = self.s_x[i] + dPercent*(self.e_x[i] - self.s_x[i])
			local newy = self.s_y[i] + dPercent*(self.e_y[i] - self.s_y[i])
			
			self.parent.touchGuides[i]:SetAnchor('CENTER',newx,newy)
			self.parent.touchGuides[i]:Show()
		end
		notifyView:ShowTimedText(self.guideText)
	elseif self.aniGuideTimer > ANIMATED_GUIDE_TIMER/2 and self.aniGuideTimer < ANIMATED_GUIDE_TIMER/4*3 and self.parent.showDrop then
		-- second half, do drop
		self.parent.dropGuide:SetAnchor('CENTER', self.s_x[1], self.s_y[1])
		self.parent.dropGuide:Show()
		
		self.parent.touchGuides[2]:Hide()
		local dPercent = self.aniGuideTimer/ANIMATED_GUIDE_TIMER*4-2
		local newx = self.s_x[2] + dPercent*(self.s_x[1] - self.s_x[2])
		local newy = self.s_y[2] + dPercent*(self.s_y[1] - self.s_y[2])
		
		self.parent.touchGuides[1]:SetAnchor('CENTER',newx,newy)
		self.parent.touchGuides[1]:Show()
		
		notifyView:ShowTimedText('Drop to create Container')
	else
		for i =1,2 do
			self.parent.touchGuides[i]:Hide()
		end
		self.parent.dropGuide:Hide()
	end
	
	self.aniGuideTimer = self.aniGuideTimer + e
	if self.aniGuideTimer > ANIMATED_GUIDE_TIMER then
		self.aniGuideTimer = 0
	end
end

function guideView:ShowMenuDragletGuide(r)
	
	
	
end

function guideView:Disable()
	self.r.needsUpdate = false
	self.isDrawing = false
	self.regions = {}
	-- if self.timer == 0 then
	self.r:Handle("OnUpdate", nil)
	self.r:Hide()
	self.r.aniGuideTimer = -1
	
	-- end
	self.arrows[1]:Hide()
	self.focusOverlay:Hide()
	
	for i =1,2 do
		self.gestOverlays[i]:Hide()
		self.touchGuides[i]:Hide()
	end
	self.dropGuide:Hide()
	
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
			local x1 = self.parent.regions[i].rx
			local y1 = self.parent.regions[i].ry + PATH_Y_OFFSET
			
			for j = 1,#self.parent.regions[i].movepath do
				local x2=x1 + self.parent.regions[i].movepath[j](deltax)
				local y2=y1 + self.parent.regions[i].movepath[j](deltay)

				self.t:SetBrushSize(3)
				self.t:Line(x1,y1,x2,y2)
				
				x1 = x2
				y1 = y2
			end
		end
		self.needsUpdate = false
	end
end