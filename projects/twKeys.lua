-- ===============================================
-- = example music controller, done through code =
-- ===============================================
-- keyboard test
-- metrics:
WK_W = 405
WK_H = 80

BK_W = 230
BK_H = 60
B_PAT = {1,1,0,1,1,1,0,1,1}

for i = 1,11 do
	local whiteKey = TWRegion:new(nil, updateEnv)
	whiteKey:LoadTexture('sprites/sp_key_white.png')
	whiteKey.h = WK_H
	whiteKey.w = WK_W
	whiteKey:SetPosition(-100,i*WK_H)
	whiteKey:Show()
	whiteKey:ToggleMovement()
end

for i = 1,9 do
	if B_PAT[i] == 1 then
		local blackKey = TWRegion:new(nil, updateEnv)
		blackKey:LoadTexture('sprites/sp_key_black.png')
		blackKey.h = BK_H
		blackKey.w = BK_W
		blackKey:SetPosition(0,(i*WK_H)+BK_H/2)
		blackKey:Show()
		blackKey:ToggleMovement()
	end
end

