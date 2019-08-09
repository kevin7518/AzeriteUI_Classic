local LibOrb = CogWheel:Set("LibOrb", 19)
if (not LibOrb) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibOrb requires LibFrame to be loaded.")

-- Lua API
local _G = _G
local math_abs = math.abs
local math_max = math.max
local math_sqrt = math.sqrt
local select = select
local setmetatable = setmetatable
local type = type
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame

-- Library registries
LibOrb.orbs = LibOrb.orbs or {}
LibOrb.data = LibOrb.data or {}
LibOrb.embeds = LibOrb.embeds or {}

-- Speed shortcuts
local Orbs = LibOrb.orbs


----------------------------------------------------------------
-- Orb template
----------------------------------------------------------------
local Orb = LibFrame:CreateFrame("Frame")
local Orb_MT = { __index = Orb }

local Update = function(self, elapsed)
	local data = Orbs[self]

	local value = data.disableSmoothing and data.barValue or data.barDisplayValue
	local min, max = data.barMin, data.barMax
	local orientation = data.orbOrientation
	local width, height = data.scaffold:GetSize() 
	local orb = data.orb
	local spark = data.spark
	local glow = data.glow
	
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
		
	local newHeight
	if value > 0 and value > min and max > min then
		newHeight = (value-min)/(max-min) * height
	else
		newHeight = 0
	end
	
	if (value <= min) or (max == min) then
		data.scrollframe:Hide()
	else

		local newSize, mult
		if (max > min) then
			mult = (value-min)/(max-min)
			newSize = mult * width
		else
			newSize = 0.0001
			mult = 0.0001
		end
		local displaySize = math_max(newSize, 0.0001) -- sizes can't be 0 in Legion

		data.scrollframe:SetHeight(displaySize)
		data.scrollframe:SetVerticalScroll(height - newHeight)
		if (not data.scrollframe:IsShown()) then
			data.scrollframe:Show()
		end
	end
	
	if (value == max) or (value == min) or (value/max >= data.sparkMaxPercent) or (value/max <= data.sparkMinPercent) then
		if spark:IsShown() then
			spark:Hide()
			spark:SetAlpha(data.sparkMinAlpha)
			data.sparkDirection = "IN"
			glow:Hide()
			glow:SetAlpha(data.sparkMinAlpha)
		end
	else
		local scrollframe = data.scrollframe
		local sparkOffsetY = data.sparkOffset
		local sparkHeight = data.sparkHeight
		local leftCrop = data.barLeftCrop
		local rightCrop = data.barRightCrop

		local sparkWidth = math_sqrt((height/2)^2 - (math_abs((height/2) - newHeight))^2) * 2
		local sparkOffsetX = (height - sparkWidth)/2
		local sparkOffsetY = data.sparkOffset * sparkHeight
		local freeSpace = height - leftCrop - rightCrop

		if sparkWidth > freeSpace then 
			spark:SetSize(freeSpace, sparkHeight) 
			glow:SetSize(freeSpace, sparkHeight*2) 
			spark:ClearAllPoints()
			glow:ClearAllPoints()

			if (leftCrop > freeSpace/2) then 
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", leftCrop, sparkOffsetY) 
				glow:SetPoint("LEFT", scrollframe, "TOPLEFT", leftCrop, sparkOffsetY*2) 
			else 
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY) 
				glow:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY*2) 
			end 

			if (rightCrop > freeSpace/2) then 
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -rightCrop, sparkOffsetY)
				glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -rightCrop, sparkOffsetY*2)
			else 
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)
				glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY*2)
			end 

		else 
			-- fixing the stupid Legion no zero size problem
			if (sparkWidth == 0) then 
				sparkWidth = 0.0001
			end 
			
			spark:SetSize(sparkWidth, sparkHeight) 
			spark:ClearAllPoints()
			spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY) 
			spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)
			
			glow:SetSize(sparkWidth, sparkHeight*2) 
			glow:ClearAllPoints()
			glow:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY*2) 
			glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY*2)
		end 

		if elapsed then
			local currentAlpha = glow:GetAlpha()
			local targetAlpha = data.sparkDirection == "IN" and data.sparkMaxAlpha or data.sparkMinAlpha
			local range = data.sparkMaxAlpha - data.sparkMinAlpha
			local alphaChange = elapsed/(data.sparkDirection == "IN" and data.sparkDurationIn or data.sparkDurationOut) * range
		
			if data.sparkDirection == "IN" then
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "OUT"
				end
			elseif data.sparkDirection == "OUT" then
				if currentAlpha + alphaChange > targetAlpha then
					currentAlpha = currentAlpha - alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "IN"
				end
			end
			spark:SetAlpha(.6 + currentAlpha/3) -- keep the spark brighter and less animated
			glow:SetAlpha(currentAlpha) -- the glow is where we apply the full alpha range
		end
		if (not spark:IsShown()) then
			spark:Show()
			glow:Show()
		end
	end
end

local smoothingMinValue = 1 -- if a value is lower than this, we won't smoothe
local smoothingFrequency = .5 -- time for the smooth transition to complete
local smoothingLimit = 1/60 -- max updates per second

local OnUpdate = function(self, elapsed)
	local data = Orbs[self]
	data.elapsed = (data.elapsed or 0) + elapsed
	if (data.elapsed < smoothingLimit) then
		return
	end
	
	if (data.disableSmoothing) then
		if (data.barValue <= data.barMin) or (data.barValue >= data.barMax) then
			data.scaffold:SetScript("OnUpdate", nil)
		end
	elseif (data.smoothing) then
		if (math_abs(data.barDisplayValue - data.barValue) < smoothingMinValue) then 
			data.barDisplayValue = data.barValue
			data.smoothing = nil
		else 
			-- The fraction of the total bar this total animation should cover  
			local animsize = (data.barValue - data.smoothingInitialValue)/(data.barMax - data.barMin) 

			-- Points per second on average for the whole bar
			local pps = (data.barMax - data.barMin)/(data.smoothingFrequency or smoothingFrequency)

			-- Position in time relative to the length of the animation, scaled from 0 to 1
			local position = (GetTime() - data.smoothingStart)/(data.smoothingFrequency or smoothingFrequency) 
			if (position < 1) then 
				-- The change needed when using average speed
				local average = pps * animsize * data.elapsed -- can and should be negative

				-- Tha change relative to point in time and distance passed
				local change = 2*(3 * ( 1 - position )^2 * position) * average*2 --  y = 3 * (1 − t)^2 * t  -- quad bezier fast ascend + slow descend
				--local change = 2*(3 * ( 1 - position ) * position^2) * average*2 -- y = 3 * (1 − t) * t^2 -- quad bezier slow ascend + fast descend
				--local change = 2 * average * ((position < .7) and math_abs(position/.7) or math_abs((1-position)/.3)) -- linear slow ascend + fast descend
				
				--print(("time: %.3f pos: %.3f change: %.1f"):format(GetTime() - data.smoothingStart, position, change))

				-- If there's room for a change in the intended direction, apply it, otherwise finish the animation
				if ( (data.barValue > data.barDisplayValue) and (data.barValue > data.barDisplayValue + change) ) 
				or ( (data.barValue < data.barDisplayValue) and (data.barValue < data.barDisplayValue + change) ) then 
					data.barDisplayValue = data.barDisplayValue + change
				else 
					data.barDisplayValue = data.barValue
					data.smoothing = nil
				end 
			else 
				data.barDisplayValue = data.barValue
				data.smoothing = nil
			end 
		end 
	else
		if (data.barDisplayValue <= data.barMin) or (data.barDisplayValue >= data.barMax) or (not data.smoothing) then
			data.scaffold:SetScript("OnUpdate", nil)
		end
	end

	Update(self, elapsed)

	data.elapsed = 0
end

Orb.SetSmoothHZ = function(self, smoothingFrequency)
	Orbs[self].smoothingFrequency = smoothingFrequency
end

Orb.DisableSmoothing = function(self, disableSmoothing)
	Orbs[self].disableSmoothing = disableSmoothing
end

-- sets the value the orb should move towards
Orb.SetValue = function(self, value, overrideSmoothing)
	local data = Orbs[self]
	local min, max = data.barMin, data.barMax
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	data.barValue = value
	if overrideSmoothing then 
		data.barDisplayValue = value
	end 
	if (not data.disableSmoothing) then
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
		data.smoothingInitialValue = data.barDisplayValue
		data.smoothingStart = GetTime()
	end
	if (value ~= data.barDisplayValue) then
		data.smoothing = true
	end
	if (data.smoothing or (data.barDisplayValue > min) or (data.barDisplayValue < max)) then
		if (not data.scaffold:GetScript("OnUpdate")) then
			data.scaffold:SetScript("OnUpdate", OnUpdate)
		end
	end
	Update(self)
end

-- forces a hard reset to zero
Orb.Clear = function(self)
	local data = Orbs[self]
	data.barValue = data.barMin
	data.barDisplayValue = data.barMin
	Update(self)
end

Orb.SetMinMaxValues = function(self, min, max, overrideSmoothing)
	local data = Orbs[self]
	if (data.barMin == min) and (data.barMax == max) then 
		return 
	end 
	if (data.barValue > max) then
		data.barValue = max
	elseif (data.barValue < min) then
		data.barValue = min
	end
	if overrideSmoothing then 
		data.barDisplayValue = data.barValue
	else 
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
	end 
	data.barMin = min
	data.barMax = max
	Update(self)
end

Orb.SetStatusBarColor = function(self, ...)
	local data = Orbs[self]
	local r, g, b = ...	
	data.layer1:SetVertexColor(r, g, b, .5)
	data.layer2:SetVertexColor(r*1/2, g*1/2, b*1/2, .9)
	data.layer3:SetVertexColor(r*1/4, g*1/4, b*1/4, 1)
	data.spark:SetVertexColor(r, g, b)
	data.glow:SetVertexColor(r, g, b)
end

Orb.SetStatusBarTexture = function(self, ...)
	local data = Orbs[self]

	-- set all the layers at once
	local numArgs = select("#", ...)
	for i = 1, numArgs do 
		local layer = data["layer"..i]
		if (not layer) then 
			break
		end
		local path = select(i, ...)
		layer:SetTexture(path)
	end 

	-- We hide layers that aren't set
	for i = numArgs+1, 3 do 
		local layer = data["layer"..i]
		if layer then 
			layer:SetTexture(nil)
		end 
	end 
end

Orb.SetSparkTexture = function(self, path)
	Orbs[self].spark:SetTexture(path)
	Orbs[self].glow:SetTexture(path)
	Update(self)
end

Orb.SetSparkColor = function(self, ...)
	Orbs[self].spark:SetVertexColor(...)
	Orbs[self].glow:SetVertexColor(...)
end 

Orb.SetSparkMinMaxPercent = function(self, min, max)
	local data = Orbs[self]
	data.sparkMinPercent = min
	data.sparkMinPercent = max
end

Orb.SetSparkBlendMode = function(self, blendMode)
	Orbs[self].spark:SetBlendMode(blendMode)
	Orbs[self].glow:SetBlendMode(blendMode)
end 

Orb.SetSparkFlash = function(self, durationIn, durationOut, minAlpha, maxAlpha)
	local data = Orbs[self]
	data.sparkDurationIn = durationIn
	data.sparkDurationOut = durationOut
	data.sparkMinAlpha = minAlpha
	data.sparkMaxAlpha = maxAlpha
	data.sparkDirection = "IN"
	data.spark:SetAlpha(minAlpha)
	data.glow:SetAlpha(minAlpha)
end

Orb.ClearAllPoints = function(self)
	Orbs[self].scaffold:ClearAllPoints()
end

Orb.SetPoint = function(self, ...)
	Orbs[self].scaffold:SetPoint(...)
end

Orb.SetAllPoints = function(self, ...)
	Orbs[self].scaffold:SetAllPoints(...)
end

Orb.GetPoint = function(self, ...)
	return Orbs[self].scaffold:GetPoint(...)
end

Orb.SetSize = function(self, width, height)
	local data = Orbs[self]
	local leftCrop = data.barLeftCrop
	local rightCrop = data.barRightCrop
	data.scaffold:SetSize(width, height)
	data.scrollchild:SetSize(width, height)
	data.scrollframe:SetWidth(width - (leftCrop + rightCrop))
	data.scrollframe:SetHorizontalScroll(leftCrop)
	data.scrollframe:ClearAllPoints()
	data.scrollframe:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	data.sparkHeight = height/4 >= 8 and height/4 or 8
	Update(self)
end

Orb.SetWidth = function(self, width)
	local data = Orbs[self]
	local leftCrop = data.barLeftCrop
	local rightCrop = data.barRightCrop
	data.scaffold:SetWidth(width)
	data.scrollchild:SetWidth(width)
	data.scrollframe:SetWidth(width - (leftCrop + rightCrop))
	data.scrollframe:SetHorizontalScroll(leftCrop)
	data.scrollframe:ClearAllPoints()
	data.scrollframe:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	Update(self)
end

Orb.SetHeight = function(self, height)
	local data = Orbs[self]
	data.scaffold:SetHeight(height)
	data.scrollchild:SetHeight(height)
	data.sparkHeight = height/4 >= 8 and height/4 or 8
	Update(self)
end

Orb.SetParent = function(self, parent)
	Orbs[self].scaffold:SetParent()
end

Orb.GetValue = function(self)
	return Orbs[self].barValue
end

Orb.GetMinMaxValues = function(self)
	local data = Orbs[self]
	return data.barMin, data.barMax
end

Orb.GetStatusBarColor = function(self, id)
	return Orbs[self].bar:GetVertexColor()
end

Orb.GetParent = function(self)
	return Orbs[self].scaffold:GetParent()
end

-- Adding a special function to create textures 
-- parented to the backdrop frame.
Orb.CreateBackdropTexture = function(self, ...)
	return Orbs[self].scaffold:CreateTexture(...)
end

-- Parent newly created textures and fontstrings
-- to the overlay frame, to better mimic normal behavior.
Orb.CreateTexture = function(self, ...)
	return Orbs[self].overlay:CreateTexture(...)
end

Orb.CreateFontString = function(self, ...)
	return Orbs[self].overlay:CreateFontString(...)
end

Orb.SetScript = function(self, ...)
	-- can not allow the scaffold to get its scripts overwritten
	local scriptHandler, func = ... 
	if (scriptHandler == "OnUpdate") then 
		Orbs[self].OnUpdate = func 
	else 
		Orbs[self].scaffold:SetScript(...)
	end 
end

Orb.GetScript = function(self, ...)
	local scriptHandler, func = ... 
	if (scriptHandler == "OnUpdate") then 
		return Orbs[self].OnUpdate
	else 
		return Orbs[self].scaffold:GetScript(...)
	end 
end

Orb.GetObjectType = function(self) return "Orb" end
Orb.IsObjectType = function(self, type) return type == "Orb" or type == "StatusBar" or type == "Frame" end

Orb.Show = function(self) Orbs[self].scaffold:Show() end
Orb.Hide = function(self) Orbs[self].scaffold:Hide() end
Orb.IsShown = function(self) return Orbs[self].scaffold:IsShown() end

Orb.IsForbidden = function(self) return true end

-- Fancy method allowing us to crop the orb's sides
Orb.SetCrop = function(self, leftCrop, rightCrop)
	local data = Orbs[self]
	data.barLeftCrop = leftCrop
	data.barRightCrop = rightCrop
	self:SetSize(data.scrollchild:GetSize()) 
end

Orb.GetCrop = function(self)
	local data = Orbs[self]
	return data.barLeftCrop, data.barRightCrop
end

LibOrb.CreateOrb = function(self, parent, rotateClockwise, speedModifier)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = CreateFrame("Frame", nil, parent or self)
	--scaffold:SetSize(1,1)

	-- The scrollchild is where we put rotating textures that needs to be cropped.
	local scrollchild = CreateFrame("Frame", nil, scaffold) --scaffold:CreateFrame("Frame")
	--scrollchild:SetFrameLevel(scaffold:GetFrameLevel() + 1)
	scrollchild:SetSize(1,1)

	-- The scrollframe defines the height/filling of the orb.
	local scrollframe = CreateFrame("ScrollFrame", nil, scaffold) -- scaffold:CreateFrame("ScrollFrame")
	scrollframe:SetScrollChild(scrollchild)
	--scrollframe:SetFrameLevel(scaffold:GetFrameLevel() + 1)
	scrollframe:SetPoint("BOTTOM")
	scrollframe:SetSize(1,1)

	-- The overlay is meant to hold overlay textures like the spark, glow, etc
	local overlay = CreateFrame("Frame", nil, scaffold) --scaffold:CreateFrame("Frame")
	overlay:SetFrameLevel(scaffold:GetFrameLevel() + 2)
	overlay:SetAllPoints(scaffold)

	-- first rotating layer
	local orbTex1 = scrollchild:CreateTexture()
	orbTex1:SetDrawLayer("BACKGROUND", 0)
	orbTex1:SetAllPoints()

	-- TODO: Get rid of these animation layers, 
	-- we should be able to do it ourselves in BfA
	-- where SetRotation and SetTexCoord can be used together. 
	local orbTex1AnimGroup = orbTex1:CreateAnimationGroup()    
	local orbTex1Anim = orbTex1AnimGroup:CreateAnimation("Rotation")
	orbTex1Anim:SetDegrees(rotateClockwise and -360 or 360)
	orbTex1Anim:SetDuration(30 * 1/(speedModifier or 1))
	orbTex1AnimGroup:SetLooping("REPEAT")
	orbTex1AnimGroup:Play()

	-- second rotating layer, going the opposite way
	local orbTex2 = scrollchild:CreateTexture()
	orbTex2:SetDrawLayer("BACKGROUND", -1)
	orbTex2:SetAllPoints()

	local orbTex2AnimGroup = orbTex2:CreateAnimationGroup()    
	local orbTex2Anim = orbTex2AnimGroup:CreateAnimation("Rotation")
	orbTex2Anim:SetDegrees(rotateClockwise and 360 or -360)
	orbTex2Anim:SetDuration(20 * 1/(speedModifier or 1))
	orbTex2AnimGroup:SetLooping("REPEAT")
	orbTex2AnimGroup:Play()

	-- static bottom textures
	local orbTex3 = scrollchild:CreateTexture()
	orbTex3:SetDrawLayer("BACKGROUND", -2)
	orbTex3:SetAllPoints()

	-- The spark will be cropped, 
	-- and only what's in the filled part of the orb will be visible. 
	local spark = scrollchild:CreateTexture()
	spark:SetDrawLayer("BORDER", 1)
	spark:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
	spark:SetPoint("TOPRIGHT", scrollframe, "TOPRIGHT", 0, 0)
	spark:SetSize(1,1)
	spark:SetAlpha(.6)
	spark:SetBlendMode("ADD")
	spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical spark being 32x9px, from 0,11px to 32,19px
	spark:SetTexCoord(1,11/32,0,11/32,1,19/32,0,19/32)-- ULx,ULy,LLx,LLy,URx,URy,LRx,LRy
	spark:Hide()
	
	-- The glow is in the overlay frame, and always visible
	local glow = overlay:CreateTexture()
	glow:SetDrawLayer("BORDER", 2)
	glow:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
	glow:SetPoint("TOPRIGHT", scrollframe, "TOPRIGHT", 0, 0)
	glow:SetSize(1,1)
	glow:SetAlpha(.25)
	glow:SetBlendMode("ADD")
	glow:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical glow being 32x26px, from 0,3px to 32,28px
	glow:SetTexCoord(1,3/32,0,3/32,1,28/32,0,28/32) -- ULx,ULy,LLx,LLy,URx,URy,LRx,LRy
	glow:Hide()

	-- The orb is the virtual object that we return to the user.
	-- This contains all the methods.
	local orb = CreateFrame("Frame", nil, scaffold)
	orb:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(orb, Orb_MT)

	local data = {}
	data.orb = orb

	-- framework
	data.scaffold = scaffold
	data.scrollchild = scrollchild
	data.scrollframe = scrollframe
	data.overlay = overlay

	-- layers
	data.layer1 = orbTex1
	data.layer2 = orbTex2
	data.layer3 = orbTex3
	data.spark = spark
	data.glow = glow

	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing
	data.barLeftCrop = 0 -- percentage of the orb cropped from the left
	data.barRightCrop = 0 -- percentage of the orb cropped from the right
	data.barSmoothingMode = "bezier-fast-in-slow-out"

	data.sparkHeight = 8
	data.sparkOffset = 1/32
	data.sparkDirection = "IN"
	data.sparkDurationIn = .75 
	data.sparkDurationOut = .55
	data.sparkMinAlpha = .25
	data.sparkMaxAlpha = .95
	data.sparkMinPercent = 1/100
	data.sparkMaxPercent = 99/100

	Orbs[orb] = data
	Orbs[scaffold] = data

	Update(orb)

	return orb
end

-- Embed it in LibFrame
LibFrame:AddMethod("CreateOrb", LibOrb.CreateOrb)

-- Module embedding
local embedMethods = {
	CreateOrb = true
}

LibOrb.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibOrb.embeds) do
	LibOrb:Embed(target)
end
