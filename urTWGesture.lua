-- ===================
-- = gesture manager =
-- ===================
-- receive hold events and do learning/recording of causal links for regions

FADE_RATE = .8

-- Modes:
LEARN_OFF = 0
LEARN_ON = 1
LEARN_DRAG = 2
LEARN_LINK = 3
LEARN_GROUP = 4

DROP_EXPAND_SIZE = 70
GESTURE_ACTIVE_DIST = 1
-- GESTURE_THRES_DIST = 10

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
	self.gestureMode = LEARN_OFF
	self.recording = {}
	self.sender = nil
	self.gestMenu = nil
	-- self.isGestMenuOpen = false
	
	self.pinchGestDeg = nil
	guideView:Disable()
end

function gestureManager:BeginGestureOnRegion(region)
	if not tableHasObj(self.allRegions, region) then
		table.insert(self.allRegions, region)
		-- DPrint(#self.allRegions..'+')
	end
	
	if #self.allRegions ~= 2 then
		guideView:Disable()
	end
end

function gestureManager:EndGestureOnRegion(region)
	tableRemoveObj(self.allRegions, region)
	-- DPrint(#self.allRegions..'-')
	if self.mode == LEARN_GROUP then
		self.mode = LEARN_OFF
		self.gestureMode = LEARN_OFF
		-- two things here, turn last region into a group, then add the current region into this group
		
		local groupRegion = nil
		local insideRegion = nil
		
		--actually, lets always use the bigger region as group
		if self.allRegions[1]:Width() + self.allRegions[1]:Height() > 
				region:Width() + region:Height() then
			groupRegion = self.allRegions[1]
			insideRegion = region
		else
			groupRegion = region
			insideRegion = self.allRegions[1]
		end
		
		self:Reset()
		
		if groupRegion==nil or insideRegion.regionType==RTYPE_GROUP then
			return
		end
		
		if groupRegion.regionType ~= RTYPE_GROUP then
			-- create new group, set sizes
			newGroup = ToggleLockGroup({insideRegion})
			
			if newGroup.r.h < groupRegion.h then
				newGroup.r.h = groupRegion.h
			end
			if newGroup.r.w < groupRegion.w then
				newGroup.r.w = groupRegion.w
			end
			-- newGroup.r:SetAnchor("CENTER", groupRegion.rx, groupRegion.ry)
			newGroup.r.x = groupRegion.rx
			newGroup.r.y = groupRegion.ry

			
			if groupRegion.textureFile~=nil then
				newGroup.r:LoadTexture(groupRegion.textureFile)
			end
			Log:print('finished grouping, based on '..groupRegion:Name())
			RemoveRegion(groupRegion)
		else
			groupRegion.h = groupRegion.oldh
			groupRegion.w = groupRegion.oldw
			groupRegion.groupObj:AddRegion(insideRegion)
			-- put group back for consecutive add
			table.insert(self.allRegions, groupRegion)
			-- DPrint(#self.allRegions..'+g')
		end
	elseif self.mode == NESTED_GROUP then
		self.mode = LEARN_OFF
		self.gestureMode = LEARN_OFF
		guideView:Disable()
		
		local r1 = region
		local r2 = self.allRegions[1]
		self:Reset()
		
		if r2==nil or 
		(region.regionType~=RTYPE_GROUP and r2.regionType~= RTYPE_GROUP) then
			if r2~=nil then
				DPrint(r2:Name())
			end
			return
		end
		if region.group==nil then
			-- if region is actually the group, switch r1 and r2
			assert(region.groupObj == r2.group)
			r1 = r2
			r2 = region
		end
		-- sanity check
		-- assert(region.group == r2.groupObj, 'nest group is wrong')
		-- check if not overlaping, if yes remove from group:
		-- increase the margin here to reduce accidental removals
		local MARGIN = 10
		if r1.x-r1.w/2 >= r2.x+r2.w/2 + MARGIN or r1.x+r1.w/2 >= r2.x-r2.w/2 + MARGIN or
				r1.y-r1.h/2 >= r2.y+r2.h/2 + MARGIN or r1.y+r1.h/2 >= r2.y-r2.h/2 + MARGIN then
			-- remove r1 from r2:
			r1:RemoveFromGroup()
			-- r2:SetPosition(r2.rx, r2.ry)
		else
			r1:SetPosition(r1.rx, r1.ry)
		end
		r2:SetPosition(r2.rx, r2.ry)
		
	elseif #self.allRegions ~= 2 then
		local r1 = self.sender
		local r2 = self.receiver
		if self.gestureMode == LEARN_LINK then
			self.gestureMode = LEARN_OFF
			self.mode = LEARN_OFF
			-- DPrint(r1:Name()..'<->'..r2:Name())
			-- check if we are breaking or making links:
			-- local oldD = (r1.rx - r2.rx)^2 + (r1.ry - r2.ry)^2
			-- local newD = (r1.x - r2.x)^2 + (r1.y - r2.y)^2
			-- local deg = 2.0*(newD - oldD)/oldD
			local didSomething = false
			if self.pinchGestAbs > 100 or self.pinchGestDeg > 1 then
				for _,link in ipairs(r1.outlinks) do
					if link.receiver == r2 then
						link:destroy()
						didSomething = true
					end
				end
				for _,link in ipairs(r2.outlinks) do
					if link.receiver == r1 then
						link:destroy()
						didSomething = true
					end
				end
				if didSomething then
					notifyView:ShowTimedText("remove links")
				end
			elseif self.pinchGestDeg < -.6 and self.pinchGestDeg > -.9 then
				notifyView:Dismiss()
				
				if r1.regionType~=RTYPE_VAR and r2.regionType~=RTYPE_VAR then
					linkEvent = 'OnDragging'
					if not r2:HasLinkTo(r1, linkEvent) then
						initialLinkRegion = r2
						finishLinkRegion = r1
						didSomething = true
						
					elseif not r1:HasLinkTo(r2, linkEvent) then
						initialLinkRegion = r1
						finishLinkRegion = r2
						didSomething = true
						
					end
					-- TODO clean this up later!
					if didSomething then
						FinishLink(TWRegion.Move)
					end
				else
					-- linkEvent = 'OnDragging'
					if r1.regionType==RTYPE_VAR then
						initialLinkRegion = r2
						finishLinkRegion = r1
					else
						initialLinkRegion = r1
						finishLinkRegion = r2
					end
					
					if not initialLinkRegion:HasLinkTo(finishLinkRegion, linkEvent) then
					
					-- finishLinkRegion:SetPosition(finishLinkRegion.rx, finishLinkRegion.ry)
					-- ChooseAction('OnDragging')					
						linkEvent = 'OnDragging'
						FinishLink(TWRegion.UpdateX)
						didSomething = true
					end
				end
			end
			
			if didSomething then
				r1:SetPosition(r1.rx, r1.ry)
				r2:SetPosition(r2.rx, r2.ry)
			end
			self:Reset()
		end
		
		if #self.allRegions == 0 then
			if self:IsGestMenuOpen() then
				-- if ScreenWidth() - region.x - region.w/2  < 2 and
				-- 	region.y - region.h/2 < 2 then
				-- 	RemoveRegion(region)
				-- 	-- DPrint('delete!')
				-- elseif ScreenWidth() - region.x - region.w/2  < 2 and
				-- 	ScreenHeight() - region.y - region.h/2 < 2 then
				-- 	-- DPrint('paint')
				-- 	LoadInspector(region)
				-- -- else
				-- -- 	DPrint('nothing')
				-- end
				
				self.gestMenu:ExecuteCmd()
				self:CloseGestMenu()				
				region:SetPosition(region.rx, region.ry)
			end
			
		end
		self.sender = nil
		self.receiver = nil
		
		-- don't cancel if it's group mode, we want the drop behaviour to persist
		guideView:Disable()
	end	
end

function gestureManager:StartHold(region)
	if self.mode == LEARN_OFF and #self.allRegions<2 then
		-- animation learning and movement learning mode
	-- 	self.mode = LEARN_ON
	-- 	self.holding = region
	-- 	self.rx, self.ry = region:Center()
	-- 	self.holding.movepath = {}
	-- 	self.receiver = nil
	-- 	notifyView:ShowText("Holding "..region:Name()..', drag other regions to learn')
	-- 	guideView:ShowSpotlight(region)
	-- 	-- starts learning mode gesture, shake everything that's not held
	-- 	for i = 1,#regions do
	-- 		regions[i]:AnimateShaking(true)
	-- 	end
	-- 	self.holding:AnimateShaking(false)
	-- -- elseif self.mode == LEARN_ON then
	-- -- 	gestureManager:EndHold(region)
		
		-- open gest menu if holding single one:
		if #self.allRegions == 1 then
			if not self.gestMenu and InputMode == 3 then
				-- guideView:ShowGestMenu()
				self.gestMenu = loadGestureMenu()
				-- find out where is the actual touch down event				
				x, y = InputPosition()
				self.gestMenu:Present(x,y, self.allRegions[1])
			end
		end
	elseif self.mode == LEARN_OFF and #self.allRegions == 2 then
		-- exactly two holds, let's do linking gesture instead
		r1 = self.allRegions[1]
		r2 = self.allRegions[2]
		guideView:ShowTwoTouchGestureGuide(r1, r2)
	end
end

function gestureManager:Dragged(region, dx, dy, x, y)
	-- recording gesture here if we are enabled:
	if self.mode == LEARN_OFF and InputMode == 3 then
		-- only show event notification here if we are not doing learning
		
		-- if math.abs(dx) > HOLD_SHIFT_TOR*20 or math.abs(dy) > HOLD_SHIFT_TOR*20 then
			-- bubbleView:ShowEvent(round(region.relativeX,3)..' '..round(region.relativeY,3), region)
		-- end
		
		if #self.allRegions == 2 then
			self:CloseGestMenu()
			-- check for overlap, if exist check movement speed
			local r1 = self.allRegions[1]
			local r2 = self.allRegions[2]
-- http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
			if r1.x-r1.w/2 < r2.x+r2.w/2 and r1.x+r1.w/2 > r2.x-r2.w/2 and
				r1.y-r1.h/2 < r2.y+r2.h/2 and r1.y+r1.h/2 > r2.y-r2.h/2 then
				-- DPrint('overlap!')
				if math.abs(r1.dx)+math.abs(r1.dy)
				+math.abs(r2.dx)+math.abs(r2.dy)>2 then
					self.mode = LEARN_GROUP
					guideView:Disable()
					
					local groupR, otherR
					if r1.regionType==RTYPE_GROUP and 
						r2.regionType~=RTYPE_GROUP then
						groupR = r1
						otherR = r2
					elseif r2.regionType==RTYPE_GROUP and
						r1.regionType~=RTYPE_GROUP then
						groupR = r2
						otherR = r1
					elseif r1.regionType~=RTYPE_GROUP and
						r2.regionType~=RTYPE_GROUP then
						-- if math.abs(r1.dx)+math.abs(r1.dy) >
						-- math.abs(r2.dx)+math.abs(r2.dy) then
						if r2:Width() + r2:Height() > r1:Width() + r1:Height() then
							groupR = r2
							otherR = r1
						else
							groupR = r1
							otherR = r2
						end
					end
					
					otherR:RaiseToTop()
					if not groupR.groupObj or otherR.group~=groupR.groupObj then
						-- not already nested
						groupR.oldh = groupR.h
						groupR.h = groupR.h + DROP_EXPAND_SIZE
						groupR.oldw = groupR.w
						groupR.w = groupR.w + DROP_EXPAND_SIZE
					elseif groupR.groupObj and otherR.group==groupR.groupObj then
						-- DPrint('nested')
						self.mode = NESTED_GROUP
						guideView:ShowRemoveFromGroup(groupR)
						-- two region already nested, showing removal guide
					end
				end
			else
				-- if regions are not overlapping
				-- show guide here, when user move
				-- also detect which gesture user is performing based on offsets
				-- compute offsets first
				if self.gestureMode == LEARN_GROUP then
					DPrint('dont show guide, already in group')
					return -- don't do nothing if we already know the mode
				end

				local ox1 = r1.x - r1.rx
				local oy1 = r1.y - r1.ry
				local ox2 = r2.x - r2.rx
				local oy2 = r2.y - r2.ry
				if (math.abs(ox1)+math.abs(oy1) > GESTURE_ACTIVE_DIST and
					math.abs(ox2)+math.abs(oy2) > GESTURE_ACTIVE_DIST) or
					self.gestureMode == LEARN_LINK then
					-- show link guide, lock into link mode
					self.gestureMode = LEARN_LINK
					-- draw the guide overlay
					local oldD = math.sqrt((r1.rx - r2.rx)^2 + (r1.ry - r2.ry)^2)
					local newD = math.sqrt((r1.x - r2.x)^2 + (r1.y - r2.y)^2)
					
					self.pinchGestDeg = 1.75*(newD - oldD)/oldD
					self.pinchGestAbs = newD - oldD
					guideView:ShowGestureLink(r1, r2, self.pinchGestDeg, self.pinchGestAbs)
					if self.sender == nil then
						self.sender = r1
						self.receiver = r2
					end
				end
			end
		elseif #self.allRegions == 1 then
			if self.gestMenu then
				x,y = InputPosition()
				self.gestMenu:UpdateGest(x,y)
				
				-- gesture menu is on, send coordinates to update 

			end

			-- old deprecated gest overlay menu
			-- dragging only one region, show trash overlay in corner
			-- if region.group == nil then
			-- 	guideView:ShowGestMenu()
			-- 	self.isGestMenuOpen = true
			-- end
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
		return
	end
	
	
	if not tableHasObj(self.receivers, region) and region ~= self.holding then
		table.insert(self.receivers, region)
		region.rx, region.ry = region:Center()
		region.movepath = {}
		region:AnimateShaking(false)
	end
	
	-- record the actual path here:
	-- if dx ~= 0 or dy ~= 0 then
	-- 	p = Point(dx,dy)
	-- 	table.insert(region.movepath, p)
	-- 	-- update the guide to show this path
	-- 	guideView:ShowPath(self.receivers)
	-- 	if region ~= self.holding then
	-- 		linkLayer:DrawPotentialLink(self.holding, region)
	-- 	end
	-- end
end

function gestureManager:Tapped(region)
	if self.mode == LEARN_OFF then
		-- do selector stuff if selector is active
		if self.selector~=nil then
			self.selector(region)
			self.selector=nil
		end
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
	tableRemoveObj(self.allRegions, region)
	-- DPrint(#self.allregions..'-h')
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
		self.isGestMenuOpen = false
		
	elseif region == self.holding then
		-- DPrint('stop hold')
		-- cancel everything, initial region stops holding
		for i = 1,#regions do
			regions[i]:AnimateShaking(false)
		end
		
		self:Reset()
		notifyView:Dismiss()
		guideView:Disable()
		self.isGestMenuOpen = false
		
	end
end

function gestureManager:Leave(region)
	tableRemoveObj(self.allRegions, region)
	self:EndHold(region)
	self:CloseGestMenu()
end

function gestureManager:SetSelector(selectorFunc)
	self.selector=selectorFunc
end

function gestureManager:IsMultiTouch(region)
	-- DPrint('check multi '..region:Name())
	return #self.allRegions>1 and tableHasObj(self.allRegions, region)
end

function gestureManager:IsGestMenuOpen()
	return self.gestMenu
end

function gestureManager:CloseGestMenu()
	if self.gestMenu then
		self.gestMenu:Dismiss()
		self.gestMenu = nil
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
