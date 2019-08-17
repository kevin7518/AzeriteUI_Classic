local LibPlayerData = CogWheel("LibPlayerData")
assert(LibPlayerData, "UnitHealth requires LibPlayerData to be loaded.")

-- Lua API
local _G = _G
local math_floor = math.floor
local math_modf = math.modf
local pairs = pairs
local string_find = string.find
local string_format = string.format
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitIsFriend = _G.UnitIsFriend
local UnitGUID = _G.UnitGUID
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitIsTapDenied = _G.UnitIsTapDenied 
local UnitLevel = _G.UnitLevel
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitReaction = _G.UnitReaction

-- WoW Strings
local S_AFK = _G.AFK
local S_DEAD = _G.DEAD
local S_PLAYER_OFFLINE = _G.PLAYER_OFFLINE

-- Constants
local _,CLASS = UnitClass("player")

-- Utility Functions
---------------------------------------------------------------------	
-- Calculate a RGB gradient from a minimum of 2 sets of RGB values
local colorsAndPercent = function(currentValue, maxValue, ...)
	if (currentValue <= 0 or maxValue == 0) then
		return nil, ...
	elseif (currentValue >= maxValue) then
		return nil, select(-3, ...)
	end
	local num = select("#", ...) / 3
	local segment, relperc = math_modf((currentValue / maxValue) * (num - 1))
	return relperc, select((segment * 3) + 1, ...)
end

-- RGB color gradient calculation from a minimum of 2 sets of RGB values
-- local r, g, b = gradient(currentValue, maxValue, r1, g1, b1, r2, g2, b2[, r3, g3, b3, ...])
local gradient = function(currentValue, maxValue, ...)
	local relperc, r1, g1, b1, r2, g2, b2 = colorsAndPercent(currentValue, maxValue, ...)
	if (relperc) then
		return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
	else
		return r1, g1, b1
	end
end

-- Number abbreviations
local large = function(value)
	if (value >= 1e8) then 		return string_format("%.0fm", value/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (value >= 1e6) then 	return string_format("%.1fm", value/1e6) 	-- 1.0m - 99.9m 
	elseif (value >= 1e5) then 	return string_format("%.0fk", value/1e3) 	-- 100k - 999k
	elseif (value >= 1e3) then 	return string_format("%.1fk", value/1e3) 	-- 1.0k - 99.9k
	elseif (value > 0) then 	return value 								-- 1 - 999
	else 						return ""
	end 
end 

local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(math_floor(value))
	end	
end

-- zhCN exceptions
local gameLocale = GetLocale()
if (gameLocale == "zhCN") then 
	short = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(math_floor(value))
		end 
	end
end 

local UpdateValues = function(health, unit, min, max)
	local healthValue = health.Value
	if healthValue then 
		if healthValue.Override then 
			healthValue:Override(unit, min, max)
		else
			if (health.disconnected) then 
				healthValue:SetText(S_PLAYER_OFFLINE)
			elseif (health.dead) then 
				healthValue:SetText(S_DEAD)
			else 
				if (min == 0 or max == 0) and (not healthValue.showAtZero) then
					healthValue:SetText("")
				else
					healthValue:SetFormattedText("%s", large(min))
				end
			end
			if healthValue.PostUpdate then 
				healthValue:PostUpdate(unit, min, max)
			end 
		end 
	end
	local healthPercent = health.ValuePercent
	if healthPercent then 
		if healthPercent.Override then 
			healthPercent:Override(unit, min, max)
		else
			if (health.disconnected or health.dead) then 
				healthPercent:SetText("")
			else 
				healthPercent:SetFormattedText("%.0f", min/max*100 - (min/max*100)%1)
			end 
			if healthPercent.PostUpdate then 
				healthPercent:PostUpdate(unit, min, max)
			end 
		end 
	end
end 

local UpdateColors = function(health, unit, min, max)
	if health.OverrideColor then
		return health:OverrideColor(unit, min, max)
	end

	local self = health._owner
	local color, r, g, b
	if (health.colorPlayer and UnitIsUnit(unit, "player")) then 
		color = self.colors.class[CLASS]
	elseif (health.colorTapped and health.tapped) then
		color = self.colors.tapped
	elseif (health.colorDisconnected and health.disconnected) then
		color = self.colors.disconnected
	elseif (health.colorDead and health.dead) then
		color = self.colors.dead
	elseif (health.colorCivilian and UnitIsPlayer(unit) and UnitIsFriend("player", unit)) then 
		color = self.colors.reaction.civilian
	elseif (health.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		color = class and self.colors.class[class]
	elseif (health.colorPetAsPlayer and UnitIsUnit(unit, "pet")) then 
		local _, class = UnitClass("player")
		color = class and self.colors.class[class]
	elseif (health.colorReaction and UnitReaction(unit, "player")) then
		color = self.colors.reaction[UnitReaction(unit, "player")]
	elseif (health.colorHealth) then 
		color = self.colors.health
	end

	if color then 
		if (health.colorSmooth) then 
			r, g, b = gradient(min, max, 1,0,0, color[1], color[2], color[3], color[1], color[2], color[3])
		else 
			r, g, b = color[1], color[2], color[3]
		end 
		health:SetStatusBarColor(r, g, b)
		health.Preview:SetStatusBarColor(r, g, b)
	end 
	
	if health.PostUpdateColor then 
		health:PostUpdateColor(unit, min, max, r, g, b)
	end 
end

local UpdateOrientations = function(health)
	local orientation = health:GetOrientation() or "RIGHT"
	local orientationFlippedH = health:IsFlippedHorizontally()
	local orientationFlippedV = health:IsFlippedVertically()

	local preview = health.Preview
	preview:SetOrientation(orientation) 
	preview:SetFlippedHorizontally(orientationFlippedH)
	preview:SetFlippedVertically(orientationFlippedV)
end 

local UpdateSizes = function(health)
	local width, height = health:GetSize()
	health.Preview:SetSize(math_floor(width + .5), math_floor(height + .5))
end

local UpdateStatusBarTextures = function(health)
	local texture = health:GetStatusBarTexture():GetTexture()
	health.Preview:SetStatusBarTexture(texture)
end

local UpdateTexCoords = function(health)
	local left, right, top, bottom = health:GetTexCoord()
	health.Preview:SetTexCoord(left, right, top, bottom)
	--health:ForceUpdate() -- not needed now that prediction is gone?
end

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	-- Allow modules to run their pre-updates
	local health = self.Health
	if health.PreUpdate then
		health:PreUpdate(unit)
	end

	-- Different GUID means a different player or NPC,
	-- so we want updates to be instant, not smoothed. 
	local guid = UnitGUID(unit)
	local forced = guid ~= health.guid

	-- Store some basic values on the health element
	health.guid = guid
	health.disconnected = not UnitIsConnected(unit)
	health.dead = UnitIsDeadOrGhost(unit)
	health.tapped = (not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)

	-- If the unit is dead or offline, we can skip a lot of stuff, 
	-- so we're making an exception for this early on. 
	if (health.disconnected or health.dead) then 
		-- Forcing all values to zero for dead or disconnected units. 
		-- Never thought it made sense to "know" the health of something dead, 
		-- since health is life, and you don't have it while dead. Doh. 
		health:SetMinMaxValues(0, 0, true)
		health:SetValue(0, true)
		health:UpdateValues(unit, 0, 0)

		-- Hide all extra elements, they have no meaning when dead or disconnected. 
		health.Preview:Hide()

		-- Allow modules to run their post-updates
		if health.PostUpdate then 
			health:PostUpdate(unit, 0, 0)
		end 
		return 
	end 

	-- Retrieve element pointers
	local preview = health.Preview

	-- Retrieve values for our bars
	local curHealth = UnitHealth(unit) -- The unit's current health
	local maxHealth = UnitHealthMax(unit) -- The unit's maximum health

	health:SetMinMaxValues(0, maxHealth, forced)
	health:SetValue(curHealth, forced)
	health:UpdateValues(unit, curHealth, maxHealth)
	health:UpdateColors(unit, curHealth, maxHealth)

	-- Always force this to be instant regardless of bar settings. 
	preview:SetMinMaxValues(0, maxHealth, true)
	preview:SetValue(curHealth, true)

	if (not health:IsShown()) then 
		health:Show()
	end

	if (not preview:IsShown()) then 
		preview:Show()
	end 

	if health.PostUpdate then
		return health:PostUpdate(unit, curHealth, maxHealth)
	end	
end

local Proxy = function(self, ...)
	return (self.Health.Override or Update)(self, ...)
end 

local ForceUpdate = function(health)
	return Proxy(health._owner, "Forced", health._owner.unit)
end

local Enable = function(self)
	local unit = self.unit
	local health = self.Health

	if health then
		health._owner = self
		health.unit = unit
		health.guid = nil
		health.ForceUpdate = ForceUpdate
		health.UpdateColors = UpdateColors
		health.UpdateValues = UpdateValues
		health.PostUpdateSize = UpdateSizes
		health.PostUpdateWidth = UpdateSizes
		health.PostUpdateHeight = UpdateSizes
		health.PostUpdateOrientation = UpdateOrientations
		health.PostUpdateStatusBarTexture = UpdateStatusBarTextures
		health.PostUpdateTexCoord = UpdateTexCoords

		-- Health events
		if health.frequent then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
		end
		self:RegisterEvent("UNIT_MAXHEALTH", Proxy)

		-- Color events
		self:RegisterEvent("UNIT_CONNECTION", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy) 

		if (not health.Preview) then 
			local preview = health:CreateStatusBar()
			preview._owner = self
			preview:SetAllPoints(health)
			preview:SetFrameLevel(health:GetFrameLevel() - 1)
			preview:DisableSmoothing(true)
			preview:SetSparkTexture("")
			preview:SetAlpha(.5)
			health.Preview = preview
		end 
		health:PostUpdateSize()
		health:PostUpdateOrientation()
		health:PostUpdateStatusBarTexture()
		health:PostUpdateTexCoord()

		return true
	end
end

local Disable = function(self)
	local health = self.Health
	if health then 
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_HEALTH", Proxy)
		self:UnregisterEvent("UNIT_MAXHEALTH", Proxy)
		self:UnregisterEvent("UNIT_CONNECTION", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy) 
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_HEAL_PREDICTION", Proxy)
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Proxy)

		health:Hide()
		health.guid = nil

		if health.Preview then 
			health.Preview:Hide()
		end
		if health.Value then 
			health.Value:SetText("")
		end
		if health.ValuePercent then 
			health.ValuePercent:SetText("")
		end
	end
end

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Health", Enable, Disable, Proxy, 36)
end 
