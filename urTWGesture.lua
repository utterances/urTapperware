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

gestureManager = {}

function gestureManager:Init()
	self:Reset()
end

function gestureManager:Reset()
	self.holding = nil
	self.receiver = nil
	self.receivers = {}
	self.rx = -1
	self.ry = -1
	self.mode = LEARN_OFF
	self.recording = {}
end


function gestureManager:StartHold(region)
	if self.mode == LEARN_OFF then
		self.mode = LEARN_ON
		self.holding = region
		self.rx, self.ry = region:Center()
		self.holding.movepath = {}
		self.receiver = nil
		notifyView:ShowText("Holding "..region:Name()..', drag other regions to learn')
		guideView:ShowPing(self.rx, self.ry)
		-- starts learning mode gesture, shake everything that's not held
		for i = 1,#regions do
			regions[i]:AnimateShaking(true)
		end
		self.holding:AnimateShaking(false)
	-- elseif self.mode == LEARN_ON then
	-- 	gestureManager:EndHold(region)
	end
end

function gestureManager:Dragged(region, dx, dy, x, y)
	-- recording gesture here if we are enabled:
	if self.mode == LEARN_OFF then
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
		guideView:ShowArrow(region)
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

function gestureManager:TouchUp(region)
	if self.mode == LEARN_OFF then
		return
	elseif self.mode == LEARN_DRAG and tableHasObj(self.receivers, region) and region ~= self.holding then
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
		
	elseif self.mode ~= LEARN_OFF and region == self.holding then
		-- cancel everything, initial region stops holding
		for i = 1,#regions do
			regions[i]:AnimateShaking(false)
		end
		
		self.mode = LEARN_OFF
		self:Reset()
		notifyView:Dismiss()
		guideView:Disable()
	end
end

function gestureManager:EndHold(region)
	-- Do NOT call this with region == initial holding region
	self.mode = LEARN_OFF
	
	self.receiver = region
	notifyView:ShowTimedText("Learning: Holding "..self.holding:Name().." -> effecting "..region:Name())
	
	initialLinkRegion = self.holding
	if initialLinkRegion == nil then
		DPrint('somethings wrong')
	end
	finishLinkRegion = self.receiver
	linkEvent = 'OnTouchUp'
	
	cmdlist = {{'Counter',FinishLink,AddOneToCounter},
		{'Move Left', FinishLink, MoveLeft},
		{'Move Right', FinishLink, MoveRight},
		{'Cancel', nil, nil}}
	menu = loadSimpleMenu(cmdlist, 'Choose Action to respond')
	menu:present(self.receiver:Center())
	self:Reset()
end

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
