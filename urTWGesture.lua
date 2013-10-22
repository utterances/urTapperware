-- ===================
-- = gesture manager =
-- ===================
-- 
-- receive hold events and do learning/recording of causal links for regions

FADE_RATE = .8
gestureManager = {}

function gestureManager:Init()
	self.holding = nil
	self.receiver = nil
	self.mode = 0
end


function gestureManager:StartHold(region)
	self.mode = 1
	self.holding = region
	self.receiver = nil
	notifyView:ShowText("Learning: Holding "..region:Name())
	
end

function gestureManager:Tapped(region)
	if self.mode == 0 then
		return
	end
	
	gestureManager:EndHold(region)
	
end

function gestureManager:EndHold(region)
	self.mode = 0
	self.receiver = region
	notifyView:ShowTimedText("Learning: Holding "..self.holding:Name().." -> effecting "..region:Name())
end