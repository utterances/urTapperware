-- ===============================================
-- = example music controller, done through code =
-- ===============================================
-- base file for mixer

local r5 = TWRegion:new(nil, updateEnv)
r5:SwitchRegionType()
r5:SetPosition(10,10)
r5.h = 100
r5.w = 100
r5:ToggleMovement()
r5:Show()

local r6 = TWRegion:new(nil, updateEnv)
r6:SwitchRegionType()
r6:SetPosition(120,10)
r6.h = 100
r6.w = 100
r6:ToggleMovement()
r6:Show()
