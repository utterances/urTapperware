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
	
	if self.receiver == nil then
		self.receiver = region
	end
	
	if dx ~= 0 or dy ~= 0 then
		p = Point(dx,dy)
		table.insert(self.recording, p)
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
	elseif self.mode == LEARN_DRAG and region == self.receiver then
		self.mode = LEARN_OFF
		notifyView:Dismiss()
		
		-- stop recording drag now, debug print?
		table.foreach(self.recording, DPrint)
		
		
	elseif self.mode ~= LEARN_OFF and region == self.holding then
		-- cancel everything, initial region stops holding
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
	finishLinkRegion = self.receiver
	linkEvent = 'OnTapAndHold'
	-- linkAction = nil
	
	cmdlist = {{'Counter',FinishLink,AddOneToCounter},
		{'Move Left', FinishLink, MoveLeft},
		{'Move Right', FinishLink, MoveRight},
		{'Move', FinishLink, move},
		{'Cancel', nil, nil}}
	menu = loadSimpleMenu(cmdlist, 'Choose Event to respond:')
	menu:present(self.receiver:Center())
	self:Reset()
end


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
