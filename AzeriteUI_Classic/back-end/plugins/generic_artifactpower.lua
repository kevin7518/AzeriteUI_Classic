local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "UnitHealth requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()
if IS_CLASSIC then 
	return 
end 

-- WoW Client Constants
if (not LibClientBuild:IsBuild("8.0.1")) then 
	return 
end 

-- Lua API
local _G = _G
local math_floor = math.floor
local math_min = math.min
local tonumber = tonumber
local tostring = tostring

-- WoW API
local Item = _G.Item
local FindActiveAzeriteItem = _G.C_AzeriteItem and _G.C_AzeriteItem.FindActiveAzeriteItem
local GetAzeriteItemXPInfo = _G.C_AzeriteItem and _G.C_AzeriteItem.GetAzeriteItemXPInfo
local GetPowerLevel = _G.C_AzeriteItem and _G.C_AzeriteItem.GetPowerLevel

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

local UpdateValue = function(element, min, max, level)
	if element.OverrideValue then
		return element:OverrideValue(min, max, level)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value.showPercent then 
		if (max > 0) then 
			local perc = math_floor(min/max*100)
			if (perc == 100) and (min < max) then 
				perc = 99
			end
			if (perc >= 1) then 
				value:SetFormattedText("%.0f%%", perc)
			else 
				value:SetText(_G.ARTIFACT_POWER)
			end
		else 
			value:SetText("")
		end 
	elseif value.showDeficit then 
		value:SetFormattedText(short(max - min))
	else 
		value:SetFormattedText(short(min))
	end
	local percent = value.Percent
	if percent then 
		if (max > 0) then 
			local perc = math_floor(min/max*100)
			if (perc == 100) and (min < max) then 
				perc = 99
			end
			if (perc >= 1) then 
				percent:SetFormattedText("%.0f%%", perc)
			else 
				percent:SetText(_G.ARTIFACT_POWER)
			end
			percent:SetFormattedText("%.0f%%", perc)
		else 
			percent:SetText("")
		end 
	end 
	if element.colorValue then 
		local color = element._owner.colors.artifact
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

local Update = function(self, event, ...)
	local element = self.ArtifactPower
	if element.PreUpdate then
		element:PreUpdate()
	end

	local azeriteItemLocation = FindActiveAzeriteItem()
	if (not azeriteItemLocation) then 
		if (element.showEmpty) then 
			element:SetMinMaxValues(0, 100)
			element:SetValue(0)
			if element.Value then 
				element:UpdateValue(0, 100, 1)
			end 
			if (not element:IsShown()) then 
				element:Show()
			end
			return 
		else
			return element:Hide()
		end 
	end
	
	local min, max, level 
	local min, max = GetAzeriteItemXPInfo(azeriteItemLocation)
	local level = GetPowerLevel(azeriteItemLocation) 

	if element:IsObjectType("StatusBar") then 
		element:SetMinMaxValues(0, max)
		element:SetValue(min)

		if element.colorPower then 
			local color = self.colors.artifact 
			element:SetStatusBarColor(color[1], color[2], color[3])
		end 
	end 

	if element.Value then 
		element:UpdateValue(min, max, level)
	end 

	if (not element:IsShown()) then 
		element:Show()
	end

	if element.PostUpdate then 
		element:PostUpdate(min, max, level)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.ArtifactPower.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.ArtifactPower
	if element then
		if IS_CLASSIC then 
			element:Hide()
			return 
		else 
		end 
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", Proxy, true)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy, true)
		self:RegisterEvent("PLAYER_LOGIN", Proxy, true)
		self:RegisterEvent("PLAYER_ALIVE", Proxy, true)
		self:RegisterEvent("CVAR_UPDATE", Proxy, true)

		return true
	end
end 

local Disable = function(self)
	local element = self.ArtifactPower
	if element then
		if (not IS_CLASSIC) then 
			self:UnregisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", Proxy)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
			self:UnregisterEvent("PLAYER_LOGIN", Proxy)
			self:UnregisterEvent("PLAYER_ALIVE", Proxy)
			self:UnregisterEvent("CVAR_UPDATE", Proxy)
		end 
		element:Hide()
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("ArtifactPower", Enable, Disable, Proxy, 14)
end 
