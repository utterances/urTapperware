-- ===================
-- = example project =
-- ===================

local r1 = TWRegion:new(nil,updateEnv)
r1:SetPosition(200,200)
r1:Show()

local r2 = TWRegion:new(nil,updateEnv)
r2:SetPosition(500,700)
r2:Show()

local r3 = TWRegion:new(nil,updateEnv)
r3:SetPosition(600,400)
r3:Show()

link:new(r1,r2,'OnDragging',TWRegion.Move)
link:new(r1,r3,'OnDragging',TWRegion.Move, {1,1})
