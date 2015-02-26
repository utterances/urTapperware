-- ==========================
-- = Fitts Testing Platform =
-- ==========================

-- Feb 2015
FreeAllRegions()


-- dofile(DocumentPath("urLog.lua")) --log user input to file
-- dofile(DocumentPath("urTWTools.lua"))	--misc helper func and obj
dofile(DocumentPath("urTWNotify.lua"))	-- text notification view
dofile(DocumentPath("urTWMenu.lua"))	-- new cleaner simple menu

circleLayer = {}
backdrop = {}

logfile = io.open(DocumentPath("logs/"..os.time().."-fitts.log"), "w")

-- experiement parameters

-- AvgFingerWidth = 18
distances = {37.5, 50, 75, 100, 140}
sizes = {6, 12, 24}
-- in mm

DEVICE = 1 -- 1-full, 2-mini
-- pixel per mm: iPad, iPad mini
ScaleMMToPx = {5.1968503937, 6.4173228346}

MID = ScreenWidth()/2
STARTMARGIN = 30
STARTW = 100
STARTH = 50
startingPos = {{MID, STARTMARGIN, STARTW, STARTH,true},
					{MID, ScreenHeight()-STARTMARGIN-STARTH, STARTW, STARTH,true}}

-- direction, distance, sizes
tests = {
	-- {1, 1, 1},
	-- {2, 1, 1},
	-- {1, 1, 2},
	-- {2, 1, 2},
	-- {1, 1, 3},
	-- {2, 1, 3},
	-- {1, 2, 1},
	-- {2, 2, 1},
	-- {1, 2, 2},
	-- {2, 2, 2},
	-- {1, 2, 3},
	-- {2, 2, 3},
	-- {1, 3, 1},
	-- {2, 3, 1},
	-- {1, 3, 2},
	-- {2, 3, 2},
	-- {1, 3, 3},
	-- {2, 3, 3},
	-- {1, 4, 1},
	-- {2, 4, 1},
	-- {1, 4, 2},
	-- {2, 4, 2},
	-- {1, 4, 3},
	-- {2, 4, 3},
	
	{1, 4, 2},
	-- {2, 4, 2},
}
-- x, y, width, height, isStarting
-- tests = {{100,100,startWidth,true},{300, 420, 50,false}}


-- experiment setup:
BATCHSIZE = 12 -- each batch
BATCHCOUNT = 2 -- total number of batch
TOUCHCIRCLEWIDTH = 7*ScaleMMToPx[DEVICE]
RESTTIME = 60
SHOWPOINTER = true

-- bookkeeping:
current = {}
batchTimes = {}
randomSeed = 1
trialNum = 1
batchNum = 1
trialNumTotal = 1

waitTimer = 0
startWidth = 40
startTime = 0
landed = false
startedTrial = false
-- make background a pleasing colour

backdrop = Region('region', 'backdrop', UIParent)
backdrop:SetWidth(ScreenWidth())
backdrop:SetHeight(ScreenHeight())
backdrop:SetLayer("BACKGROUND")
backdrop:SetAnchor('BOTTOMLEFT',0,0)

backdrop:EnableInput(true)
backdrop:SetClipRegion(0,0,ScreenWidth(),ScreenHeight())
backdrop:EnableClipping(true)
backdrop.player = {}
backdrop.t = backdrop:Texture()
backdrop.t:SetSolidColor(100,100,100)
backdrop.tl = backdrop:TextLabel()
backdrop.tl:SetVerticalAlign('TOP')
backdrop.tl:SetFontHeight(28)
backdrop.tl:SetLabel('')

backdrop:Show()

-- setup circle drawing layer

circleLayer = Region('region', 'backdrop', UIParent)
circleLayer:SetWidth(ScreenWidth())
circleLayer:SetHeight(ScreenHeight())
circleLayer:SetLayer("MEDIUM")
circleLayer:SetAnchor('BOTTOMLEFT',0,0)
circleLayer.t = circleLayer:Texture()
circleLayer.t:Clear(0,0,0,0)
circleLayer.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
circleLayer.t:SetBlendMode("BLEND")
circleLayer.t:SetFill(true)
circleLayer:EnableInput(false)
circleLayer:EnableMoving(false)
circleLayer:MoveToTop()
circleLayer:Show()
circleLayer.needsDraw=true
circleLayer.onTarget = false
-- circleLayer:Handle("OnUpdate", circleLayer.Update)
circleLayer.parent = self

overLayer = Region('region', 'backdrop', UIParent)
overLayer.parent = self
overLayer:SetWidth(ScreenWidth())
overLayer:SetHeight(ScreenHeight())
overLayer:SetLayer("DIALOG")
-- overLayer:SetAnchor('CENTER',ScreenWidth()/2,ScreenHeight()/2)
overLayer:SetAnchor('BOTTOMLEFT',0,0)

overLayer.t = overLayer:Texture()
overLayer.t:SetBlendMode("BLEND")
overLayer.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
-- overLayer:EnableInput(false)
-- overLayer:EnableMoving(true)

--draw indicator:	
overLayer.t:SetBrushSize(2)
overLayer.t:SetBrushColor(0,250,255,50)
overLayer.t:Clear(0,0,0,0)
overLayer.t:SetFill(true)
overLayer.t:Ellipse(ScreenWidth()/2,ScreenHeight()/2, TOUCHCIRCLEWIDTH, TOUCHCIRCLEWIDTH)
overLayer.t:SetBrushColor(0,220,255,240)
-- overLayer.t:Line(0, 0, 10, 10)
overLayer.t:Line(ScreenWidth()/2, ScreenHeight()/2-TOUCHCIRCLEWIDTH, ScreenWidth()/2, ScreenHeight()/2+TOUCHCIRCLEWIDTH)
overLayer.t:Line(ScreenWidth()/2-TOUCHCIRCLEWIDTH, ScreenHeight()/2, ScreenWidth()/2+TOUCHCIRCLEWIDTH, ScreenHeight()/2)
overLayer:MoveToTop()
overLayer:Hide()

notifyView:Init()


-- always two points, with size, starting first
curx,cury = -1,-1
ox,oy = 0,0

function circleLayer:SetOnTarget(isOnTarget)
	local originalValue = self.onTarget
	self.onTarget = isOnTarget
	if self.onTarget ~= originalValue then
		self.needsDraw = true
		self:Update()
	end
end

function circleLayer:Update()
	-- draw a line between linked regions, also draws menu
	if self.needsDraw then
		self.needsDraw = false
		self.t:Clear(0,0,0,0)
		
		for _,c in pairs(self.circles) do
			local rx, ry, w, h, starting = unpack(c)
			
			if starting then
				self.t:SetBrushColor(0,255,100)
			else
				if self.onTarget then
					self.t:SetBrushColor(255,250,250)
				else
					self.t:SetBrushColor(250,50,50)
				end
			end
			
			-- self.t:Ellipse(c[1], c[2], c[3], c[3])
			self.t:Rect(rx-w/2, ry, w, h)
		end
	end
end


function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for k, v in pairs(orig) do 
			  copy[k] = v
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function setCurrentTrial(trialNumTotal, device)
	local trial = tests[(trialNumTotal-1) % #tests + 1]
	-- test: direction, distance, size
	-- check directions
	current[1] = startingPos[trial[1]]
	current[2] = shallowcopy(startingPos[trial[1]])
	current[2][5] = false
	
	local dist = distances[trial[2]]*ScaleMMToPx[device]
	local size = sizes[trial[3]]*ScaleMMToPx[device]
	
	if trial[1] == 1 then
		-- y coord: distance
		current[2][2] = current[2][2] + STARTH/2 + dist-size/2
	else
		-- y coord: distance
		current[2][2] = current[2][2] + STARTH/2 - (dist+size/2)
	end
	-- height: target size
	current[2][4] = size
	-- width: target size
	current[2][3] = size
	
	circleLayer.circles = {current[1]}
	circleLayer.needsDraw = true
	circleLayer:SetOnTarget(false)
	startedTrial = false
	landed = false
end

setCurrentTrial(trialNumTotal, DEVICE)

function initBatch(waittime)
	current = {}
	circleLayer.circles = {}
	circleLayer.needsDraw = true
	circleLayer:Update()
	
	waitTimer = waittime or 0
	-- if any previous batch time exist, compute average and print:
	total = 0
	for _,t in ipairs(batchTimes) do 
		total = total + t
	end

	if total > 0 then
		total = total / BATCHSIZE
		local t = string.format("%.3f", os.clock())
		logfile:write(t..' avg:'..total..'\n')
		logfile:flush()
	end
	notifyView:ShowTimedText('Previous avg: '..total)
	
	batchNum = batchNum + 1

	if batchNum > BATCHCOUNT then
		notifyView:ShowTimedText('you are done')
	else
		if waitTimer > 0 then
			backdrop:Handle('OnUpdate',bgUpdateWait)
		else
			startBatch()
		end
	end
end

function startBatch()
	backdrop.tl:SetLabel('batch '..batchNum..'/'..BATCHCOUNT)
	
	trialNum = 1
	batchTimes = {}
	
	setCurrentTrial(trialNumTotal, DEVICE)
	circleLayer:Update()
	
	math.randomseed(randomSeed)
end



circleLayer:Update()

function checkOverlap(x,y,targetRect)
	-- check if x,y is in the target area
	local rx, ry, w, h, _ = unpack(targetRect)
	return math.abs(x-rx)<=w/2 and y <= ry+h and y >= ry
end

function bgTouchDown(self, x, y)
	-- check for starting position
	if #current==0 then
		return
	end
	landed = checkOverlap(x,y, current[1])
	if landed then
		DPrint('drag to red target and release')
		-- adjust distance offset based on landing point:
		current[2][2] = current[2][2] + y - current[1][2]
		
		table.insert(circleLayer.circles, current[2])
		-- startTime = os.clock()
		circleLayer.needsDraw=true
		circleLayer:Update()
		ox, oy = x, y
	else
		DPrint('put your finger on the green rectangle')	
	end
	
	if SHOWPOINTER then
		overLayer:Show()
		overLayer:SetAnchor("CENTER", x,y)
	end
end

function bgTouchUp(self, x, y)
	-- check ending position
	if startedTrial and checkOverlap(curx,cury, current[2]) then
		local dur = os.clock() - startTime
		-- DPrint(dur)
		--write to file:
		local t = string.format("%.3f", os.clock())
		logfile:write(t..' '..dur..'\n')
		logfile:flush()
		table.insert(batchTimes, dur)
		
		trialNum = trialNum + 1
		trialNumTotal = trialNumTotal + 1
		
		if trialNum > BATCHSIZE then
			-- make people wait, finished batch
			initBatch(RESTTIME)
		else
			-- continue with trial
			setCurrentTrial(trialNumTotal, DEVICE)			
		end
	else
		if startedTrial then
			DPrint(curx..','..cury..' missed, try again')
		end
		-- logfile:write('missed\n')
		-- logfile:flush()
		
		circleLayer.circles = {current[1]}
		circleLayer.needsDraw=true
	end
	
	startedTrial = false
	landed = false
	circleLayer:Update()
	overLayer:Hide()
end

function bgMove(self, x,y)
	curx,cury = x,y
	if SHOWPOINTER then
		overLayer:SetAnchor("CENTER", x,y)
	end
	
	if #current==0 then
		return
	end
	
	if landed and not startedTrial then
		if checkOverlap(curx,cury, current[1]) and math.abs(y-oy)<1.5*ScaleMMToPx[DEVICE] then
			startTime = os.clock()
		else
			-- DPrint('GO')
			startedTrial = true
		end
	elseif startedTrial then
		circleLayer:SetOnTarget(checkOverlap(curx,cury, current[2]))
	end
end

function bgUpdateWait(self,e)
	if waitTimer >0 then
		waitTimer = waitTimer - e
		self.tl:SetLabel(string.format("please wait %.1f", waitTimer))
	end
	if waitTimer <=0 then
		waitTimer = 0
		self.tl:SetLabel('')
		
		menu = loadSimpleMenu({{'Start', startBatch, nil}}, 'remain:  '..BATCHCOUNT-batchNum+1)
		menu:present(ScreenWidth()/2, ScreenHeight()/2)		
		self:Handle("OnUpdate", nil)
	end
end

backdrop:Handle("OnTouchDown", bgTouchDown)
backdrop:Handle("OnTouchUp", bgTouchUp)
backdrop:Handle("OnMove", bgMove)

-- function Main()
--
-- 	cmdlist = {
-- 		{'Start', startBatch, nil}
-- 	}
-- 	menu = loadSimpleMenu(cmdlist, 'Test')
-- 	menu:present(ScreenWidth(), 260)
-- end
