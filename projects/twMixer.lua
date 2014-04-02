-- ===============================================
-- = example music controller, done through code =
-- ===============================================

local r2 = TWRegion:new(nil, updateEnv)
r2:LoadTexture('sprites/tw_button.png')
r2:SetPosition(100,ScreenHeight()/2)
r2.h = 100
r2.w = 100
r2:Show()

local rgroup = ToggleLockGroup({r2})
rgroup.r:SetPosition(100,ScreenHeight()/2)
rgroup.r.h = 400
rgroup.r.w = 100
rgroup.r:LoadTexture('sprites/tw_barback_v.png')

r2:ToggleMovement()
r2:SetAnchor('CENTER', rgroup.r, 'CENTER', 0, 0)

local r3 = TWRegion:new(nil, updateEnv)
r3:LoadTexture('sprites/tw_button.png')
r3:SetPosition(ScreenWidth()/2,800)
r3.h = 100
r3.w = 100
r3:Show()

rgroup = nil
rgroup = ToggleLockGroup({r3})
rgroup.r:SetPosition(ScreenWidth()/2,800)
rgroup.r.h = 100
rgroup.r.w = 400
rgroup.r:LoadTexture('sprites/tw_barback_h.png')

r3:ToggleMovement()
r3:SetAnchor('CENTER', rgroup.r, 'CENTER', 0, 0)

local r4 = TWRegion:new(nil, updateEnv)
r4:LoadTexture('sprites/sp_redball.png')
r4:SetPosition(ScreenWidth()/2,ScreenHeight()/2)
r4.h = 100
r4.w = 100
r4:Show()

rgroup = ToggleLockGroup({r4})
rgroup.r:SetPosition(ScreenWidth()/2,ScreenHeight()/2)
rgroup.r.h = 400
rgroup.r.w = 400

r4:ToggleMovement()
r4:SetAnchor('CENTER', rgroup.r, 'CENTER', 0, 0)

-- link:new(r2,r4,'OnDragging',TWRegion.Move)
-- link:new(r4,r2,'OnDragging',TWRegion.Move)
-- 
-- link:new(r3,r4,'OnDragging',TWRegion.Move)
-- link:new(r4,r3,'OnDragging',TWRegion.Move)
