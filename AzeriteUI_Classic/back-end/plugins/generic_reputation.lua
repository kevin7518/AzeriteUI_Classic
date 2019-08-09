local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "UnitHealth requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()
if IS_CLASSIC then 
	return 
end 

-- Lua API
local _G = _G
local math_floor = math.floor
local math_min = math.min
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetFactionInfo = _G.GetFactionInfo
local GetFactionParagonInfo = _G.C_Reputation.GetFactionParagonInfo
local GetFriendshipReputation = _G.GetFriendshipReputation
local GetNumFactions = _G.GetNumFactions
local GetWatchedFactionInfo = _G.GetWatchedFactionInfo
local IsFactionParagon = _G.C_Reputation.IsFactionParagon

-- Number abbreviations
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

local UpdateValue = function(element, current, min, max, factionName, standingID, standingLabel, isFriend)
	local value = element.Value or element:IsObjectType("FontString") and element 
	local barMax = max - min 
	local barValue = current - min
	if value.showPercent then 
		if (barMax > 0) then 
			value:SetFormattedText("%.0f%%", barValue/barMax*100)
		else 
			value:SetText(MAXIMUM)
		end 
	elseif value.showDeficit then 
		if (barMax > 0) then 
			value:SetFormattedText(short(barMax - barValue))
		else 
			value:SetText(MAXIMUM)
		end 
	else 
		value:SetFormattedText(short(barValue))
	end
	local percent = value.Percent
	if percent then 
		if (barMax > 0) then 
			percent:SetFormattedText("%.0f%%", barValue/barMax*100)
		else 
			percent:SetText(MAXIMUM)
		end 
	end 
	if element.colorValue then 
		local color
		if restedLeft then 
			local colors = element._owner.colors
			color = colors[isFriend and "friendship" or "reaction"][standingID]
		else 
			local colors = element._owner.colors
			color = colors.xpValue or colors.xp
		end 
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

local Update = function(self, event, unit)
	local element = self.Reputation
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local name, reaction, min, max, current, factionID = GetWatchedFactionInfo()
	if (not name) then
		return element:Hide()
	end 

	if (factionID and IsFactionParagon(factionID)) then
		local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(factionID)
		if (currentValue and threshold) then
			min, max = 0, threshold
			current = currentValue % threshold
			if hasRewardPending then
				current = current + threshold
			end
		end
	end

	local standingID, standingLabel, isFriend, friendText
	for i = 1, GetNumFactions() do
		local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)

		if (factionName == name) then
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)

			if friendID then 
				isFriend = true
				if nextFriendThreshold then 
					min = friendThreshold
					max = nextFriendThreshold
				else
					min = 0
					max = friendMaxRep
					current = friendRep
				end 
				standingLabel = friendTextLevel
			end 
			standingID = standingId
			break
		end
	end

	if (not standingID) then 
		return element:Hide()
	end

	if (not isFriend) then 
		standingLabel = _G["FACTION_STANDING_LABEL"..standingID]
	end

	if element:IsObjectType("StatusBar") then 
		local barMax = max - min 
		local barValue = current - min
		if (barMax == 0) then 
			element:SetMinMaxValues(0,1)
			element:SetValue(1)
		else 
			element:SetMinMaxValues(0, max-min)
			element:SetValue(current-min)
		end 
		if element.colorStanding then 
			local color = self.colors[isFriend and "friendship" or "reaction"][standingID]
			element:SetStatusBarColor(color[1], color[2], color[3])
		end 
	end 
	
	if element.Value then 
		(element.OverrideValue or element.UpdateValue) (element, current, min, max, name, standingID, standingLabel, isFriend)
	end 
	
	if (not element:IsShown()) then 
		element:Show()
	end

	if element.PostUpdate then 
		return element:PostUpdate(current, min, max, name, standingID, standingLabel, isFriend)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.Reputation.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Reputation
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterEvent("UPDATE_FACTION", Proxy, true)

		return true
	end
end 

local Disable = function(self)
	local element = self.Reputation
	if element then
		element:Hide()
		self:UnregisterEvent("UPDATE_FACTION", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Reputation", Enable, Disable, Proxy, 6)
end 
