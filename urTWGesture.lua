-- ===================
-- = gesture manager =
-- ===================
-- 
-- receive hold events and do learning/recording of causal links for regions


FADE_RATE = .8

-- Modes:
LEARN_OFF = 0
LEARN_ON = 1
LEARN_DRAG = 2
LEARN_LINK = 3
LEARN_GROUP = 4

DROP_EXPAND_SIZE = 80

gestureManager = {}

function gestureManager:Init()
	self:Reset()
end

function gestureManager:Reset()
	self.holding = nil
	self.receiver = nil
	self.receivers = {}
	self.allRegions = {}
	self.rx = -1
	self.ry = -1
	self.mode = LEARN_OFF
	self.recording = {}
	guideView:Disable()
end

function gestureManager:BeginGestureOnRegion(region)
	table.insert(self.allRegions, region)
end

function gestureManager:EndGestureOnRegion(region)
	tableRemoveObj(self.allRegions, region)
	
	if self.mode == LEARN_GROUP then
		
		groupRegion = self.allRegions[1]
		if groupRegion==nil then
			return
		end
				
		if groupRegion.regionType ~= RTYPE_GROUP then
			-- create new group, set sizes
			newGroup = ToggleLockGroup({region})
			newGroup.h = groupRegion.h
			newGroup.w = groupRegion.w
			newGroup.r:SetAnchor("CENTER", groupRegion.x, groupRegion.y)
			RemoveRegion(groupRegion)
			
		else
			groupRegion.h = groupRegion.oldh
			groupRegion.w = groupRegion.oldw
			groupRegion.groupObj:AddRegion(region)
		end	
		
		-- two things here, turn last region into a group, then add the current region into this group
		
		self.mode = LEARN_OFF
		guideView:Disable()
		-- self:Reset()
	end
end

function gestureManager:StartHold(region)
	if self.mode == LEARN_OFF and #self.allRegions<2 then
		-- animation learning and movement learning mode
		self.mode = LEARN_ON
		self.holding = region
		self.rx, self.ry = region:Center()
		self.holding.movepath = {}
		self.receiver = nil
		notifyView:ShowText("Holding "..region:Name()..', drag other regions to learn')
		guideView:ShowSpotlight(region)
		-- starts learning mode gesture, shake everything that's not held
		for i = 1,#regions do
			regions[i]:AnimateShaking(true)
		end
		self.holding:AnimateShaking(false)
	-- elseif self.mode == LEARN_ON then
	-- 	gestureManager:EndHold(region)
	elseif self.mode == LEARN_OFF and #self.allRegions == 2 then
		-- TODO disabled for now, do this later
		-- exactly two holds, let's do linking gesture instead
		-- self.mode = LEARN_LINK
		-- -- first store their locations
		-- for i = 1,2 do
		-- 	self.allRegions[i].rx, self.allRegions[i].ry = self.allRegions[i]:Center()
		-- end
		-- r1 = self.allRegions[1]
		-- r2 = self.allRegions[2]
		-- 
		-- -- draw the guide overlay
		-- guideView:ShowGesturePull(r1, r2)
		-- guideView:ShowGestureCenter(r1, r2)
		-- 
	end
end

function gestureManager:Dragged(region, dx, dy, x, y)
	-- recording gesture here if we are enabled:
	if self.mode == LEARN_OFF then
		-- only show event notification here if we are not doing learning
		
		-- if math.abs(dx) > HOLD_SHIFT_TOR*10 or math.abs(dy) > HOLD_SHIFT_TOR*10 then
		-- 	bubbleView:ShowEvent(round(region.relativeX,3)..' '..round(region.relativeY,3), region)
		-- end
		
		if #self.allRegions == 2 then
			-- check for overlap, if exist check movement speed
			local r1 = self.allRegions[1]
			local r2 = self.allRegions[2]
			
-- http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
			if r1.x-r1.w/2 < r2.x+r2.w/2 and r1.x+r1.w/2 > r2.x-r2.w/2 and
			    r1.y-r1.h/2 < r2.y+r2.h/2 and r1.y+r1.h/2 > r2.y-r2.h/2 then
				-- DPrint('overlap!')
				self.mode = LEARN_GROUP
				local groupR, otherR
				if r1.regionType==RTYPE_GROUP and r2.regionType~=RTYPE_GROUP then
					groupR = r1
					otherR = r2
				elseif r2.regionType==RTYPE_GROUP and r1.regionType~=RTYPE_GROUP
					then
					groupR = r2
					otherR = r1
				elseif r1.regionType~=RTYPE_GROUP and r2.regionType~=RTYPE_GROUP
					then
					if math.abs(r1.dx)+math.abs(r1.dy) >
					math.abs(r2.dx)+math.abs(r2.dy) then
						groupR = r2
						otherR = r1
					else
						groupR = r1
						otherR = r2
					end
				end
				
				otherR:RaiseToTop()
				groupR.oldh = groupR.h
				groupR.h = groupR.h + DROP_EXPAND_SIZE
				groupR.oldw = groupR.w
				groupR.w = groupR.w + DROP_EXPAND_SIZE
			end
		end
		
		return
		
	elseif self.mode == LEARN_GROUP and #self.allRegions == 2 then
		local r1 = self.allRegions[1]
		local r2 = self.allRegions[2]
		if r1.x-r1.w/2 > r2.x+r2.w/2 or r1.x+r1.w/2 < r2.x-r2.w/2 or
		    r1.y-r1.h/2 > r2.y+r2.h/2 or r1.y+r1.h/2 < r2.y-r2.h/2 then
			self.mode = LEARN_OFF
			
			if r2.oldh < r2.h then
				r2.h = r2.oldh
				r2.w = r2.oldw
			else
				r1.h = r1.oldh
				r1.w = r1.oldw
			end
		end
		return
	elseif self.mode == LEARN_ON and region ~= self.holding then
		self.mode = LEARN_DRAG
		notifyView:ShowText("Learning movement of "..region:Name())		
	elseif self.mode == LEARN_DRAG and region == self.holding then
		-- special case when parent region starts to move too, learn
		-- pinch/reverse pinch, convert to movement event->action pair
		
		if #self.receivers > 0 then
			notifyView:ShowText("Learning move interaction between "..region:Name()..' and '..self.receivers[1]:Name())			
		end
		
		-- not use for now:
		-- if dx ~= 0 or dy ~= 0 then
		-- 	p = Point(dx,dy)
		-- 	table.insert(region.movepath, p)
		-- end
	elseif self.mode == LEARN_LINK and #self.allRegions == 2 then
		-- compute how much are we off into each gesture and update vis guide
		local r1 = self.allRegions[1]
		local r2 = self.allRegions[2]
		local x1,y1 = r1:Center()
		local x2,y2 = r2:Center()
		-- cx = (r1.rx + r2.rx)/2
		-- cy = (r1.ry + r2.ry)/2
		local olddist = math.abs(r1.rx - r2.rx) + math.abs(r1.ry - r2.ry)
		local newdist = math.abs(x1 - x2) + math.abs(y1 - y2)
		local gestDeg = newdist - olddist -- positive if pulling, negative if pinching
		
		-- update gesture guide here:
		guideView:UpdatePull(-(olddist/3 - gestDeg)/(olddist/3))
		guideView:UpdateCenter(-(gestDeg - olddist/3)/(olddist/3))
		
		return
	end	
	
	
	if not tableHasObj(self.receivers, region) and region ~= self.holding then
		table.insert(self.receivers, region)
		region.rx, region.ry = region:Center()
		region.movepath = {}
		region:AnimateShaking(false)
	end
	
	-- record the actual path here:
	if dx ~= 0 or dy ~= 0 then
		p = Point(dx,dy)
		table.insert(region.movepath, p)
		-- update the guide to show this path
		guideView:ShowPath(self.receivers)
		if region ~= self.holding then
			linkLayer:DrawPotentialLink(self.holding, region)
		end
	end
end

function gestureManager:Tapped(region)
	if self.mode == LEARN_OFF then
		return
	end
	if region ~= self.holding then
		gestureManager:EndHold(region)
	end
end

function gestureManager:TouchDown(region)
	if self.mode == LEARN_OFF then
		-- different linking gesture mode
		
	end
end

function gestureManager:EndHold(region)
	if self.mode == LEARN_OFF then
		return
	elseif self.mode == LEARN_DRAG and tableHasObj(self.receivers, region) then
		-- stop recording drag now
		tableRemoveObj(self.receivers, region)
		notifyView:Dismiss()
		initialLinkRegion = self.holding
		finishLinkRegion = region
		
		x,y = self.holding:Center()
		dx = x-self.rx
		dy = y-self.ry
		if math.abs(dx) > 10 or math.abs(dy) > 10 then
			-- do pair interaction instead of recording path
			-- first compute the movement transformation
			-- holding movement is x-self.rx, y-self.ry
			mx = 0
			my = 0
			for i = 1,#region.movepath do
				mx = mx + region.movepath[i](deltax)
				my = my + region.movepath[i](deltay)
			end
			-- DPrint(mx..' '..my..' vs '..x-self.rx..' '..y-self.ry)
			-- DPrint('move '..self.holding:Name()..' with '..region:Name())
			linkEvent = 'OnDragging'
			
			normsquare = dx^2 + dy^2
			cosT = (mx*dx + my*dy)/normsquare
			sinT = (my*dx - mx*dy)/normsquare
			
			FinishLink(TWRegion.Move, {cosT, sinT})
		else
			-- set up path based animation
			linkEvent = 'OnTouchUp'
			-- DPrint('path '..self.holding:Name()..' with '..region:Name())
			FinishLink(TWRegion.PlayAnimation, region.movepath)
			
			-- cmdlist = {{'Once', self.FinishAnimationLink, {region,false}},
			-- 	{'Loop', self.FinishAnimationLink, {region,true}}}
			-- menu = loadSimpleMenu(cmdlist, 'Choose Animation Type')
			-- menu:present(region:Center())
			region:SetAnchor("CENTER", region.rx, region.ry)
		end
		
		region.movepath = {}
		guideView:Disable()
		
	elseif region == self.holding then
		-- cancel everything, initial region stops holding
		for i = 1,#regions do
			regions[i]:AnimateShaking(false)
		end
		
		self:Reset()
		notifyView:Dismiss()
	end
end

-- function gestureManager:EndHold(region)
-- 	-- Do NOT call this with region == initial holding region
-- 	self.mode = LEARN_OFF
-- 	
-- 	self.receiver = region
-- 	notifyView:ShowTimedText("Learning: Holding "..self.holding:Name().." -> effecting "..region:Name())
-- 	
-- 	initialLinkRegion = self.holding
-- 	if initialLinkRegion == nil then
-- 		DPrint('somethings wrong')
-- 	end
-- 	finishLinkRegion = self.receiver
-- 	linkEvent = 'OnTouchUp'
-- 	
-- 	cmdlist = {{'Counter',FinishLink, TWRegion.UpdateVal},
-- 		{'Move Left', FinishLink, MoveLeft},
-- 		{'Move Right', FinishLink, MoveRight},
-- 		{'Cancel', nil, nil}}
-- 	menu = loadSimpleMenu(cmdlist, 'Choose Action to respond')
-- 	menu:present(self.receiver:Center())
-- 	self:Reset()
-- end

-- ==========================
-- = set up animation types =
-- ==========================

-- function gestureManager:FinishAnimationLink(input)
-- 	r = input[1]
-- 	loop = input[2]
-- 	DPrint(r:Name()..' '..)
-- 	initialLinkRegion = self.holding
-- 	finishLinkRegion = r
-- 	r.loopmove = loop
-- 	linkEvent = 'OnTouchUp'
-- 	FinishLink(TWRegion.PlayAnimation)
-- end
