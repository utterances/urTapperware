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
		self.receiver = nil
		notifyView:ShowText("Learning: Holding "..region:Name())
	-- elseif self.mode == LEARN_ON then
	-- 	gestureManager:EndHold(region)
	end
end

function gestureManager:Dragged(region, dx, dy, x, y)
	-- recording gesture here if we are enabled:
	if self.mode == LEARN_OFF or region == self.holding then
		return
	elseif self.mode == LEARN_ON then
		self.mode = LEARN_DRAG
		notifyView:ShowText("Learning: Dragging "..region:Name().." to learn movement")
	end
	
	if not tableHasObj(self.receivers, region) then
		table.insert(self.receivers, region)
		region.movepath = {}
		-- self.rx, self.ry = region:Center()
	end
	
	if dx ~= 0 or dy ~= 0 then
		p = Point(dx,dy)
		table.insert(region.movepath, p)
	end
end

function gestureManager:Tapped(region)
	if self.mode == LEARN_OFF then
		return
	end
	if region ~= self.holding then
		gestureManager:EndHold(region)
	end
	DPrint('region IsVisible '..region:IsVisible())
end

function gestureManager:TouchUp(region)
	if self.mode == LEARN_OFF then
		return
	elseif self.mode == LEARN_DRAG and tableHasObj(self.receivers, region) then
		-- stop recording drag now
		tableRemoveObj(self.receivers, region)
		notifyView:Dismiss()		
		
		initialLinkRegion = self.holding
		finishLinkRegion = region
		linkEvent = 'OnTouchUp'
		FinishLink(TWRegion.PlayAnimation, region.movepath)
		region.movepath = {}

		-- cmdlist = {{'Once', self.FinishAnimationLink, {region,false}},
		-- 	{'Loop', self.FinishAnimationLink, {region,true}}}
		-- menu = loadSimpleMenu(cmdlist, 'Choose Animation Type')
		-- menu:present(region:Center())

		
	elseif self.mode ~= LEARN_OFF and region == self.holding then
		-- cancel everything, initial region stops holding
		self.mode = LEARN_OFF
		self:Reset()
		notifyView:Dismiss()
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


-- =======================================
-- = functional tuple for gesture points =
-- =======================================
-- functional tuple design from http://lua-users.org/wiki/FunctionalTuples
-- each point in gesture table is a dx,dy tuple

function Point(_dx, _dy)
  return function(fn) return fn(_dx, _dy) end
end

function dx(_dx, _dy) return _dx end
function dy(_dx, _dy) return _dy end
