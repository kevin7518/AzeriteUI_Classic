local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "ClassPower requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

-- Lua API
local _G = _G

-- WoW API
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local ALTERNATE_POWER_INDEX = Enum and Enum.PowerType.Alternate or ALTERNATE_POWER_INDEX or 10

-- Number abbreviations
---------------------------------------------------------------------	
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
		return tostring(value - value%1)
	end	
end

-- Borrow the unitframe tooltip
local GetTooltip = function(element)
	return element.GetTooltip and element:GetTooltip() or element._owner.GetTooltip and element._owner:GetTooltip()
end 

local UpdateTooltip = function(element)
	local tooltip = GetTooltip(element)
	tooltip:SetDefaultAnchor(element)
	tooltip:AddLine(element.powerName, 1, 1, 1)
	tooltip:AddLine(element.powerTooltip, nil, nil, nil, 1)
	tooltip:Show()
end

local OnEnter = function(element)
	element.UpdateTooltip = UpdateTooltip
	element:UpdateTooltip()
end

local OnLeave = function(element)
	local tooltip = GetTooltip(element)
	tooltip:Hide()
	element.UpdateTooltip = nil
end

local UpdateValue = function(element, unit, current, min, max)
	if element.OverrideValue then
		return element:OverrideValue(unit, current, min, max)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value then
		if (current == 0 or max == 0) and (not value.showAtZero) then
			value:SetText("")
		else
			if value.showPercent then
				if value.showMaximum then
					value:SetFormattedText("%s / %s - %.0f%%", short(current), short(max), math_floor(current/max * 100))
				else
					value:SetFormattedText("%s / %.0f%%", short(current), math_floor(current/max * 100))
				end
			else
				if value.showMaximum then
					value:SetFormattedText("%s / %s", short(current), short(max))
				else
					value:SetFormattedText("%s", short(current))
				end
			end
		end
	end
end 

local Update = function(self, event, unit, powerType)
	if (not unit) or ((unit ~= self.unit) and (unit ~= self.realUnit)) then 
		return 
	end 

	-- Could be the player in a vehicle
	unit = self.realUnit or unit

	-- We're only interested in alternate power here
	if ((event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER") and (powerType ~= "ALTERNATE")) then 
		return 
	end 

	local element = self.AltPower
	if element.visibilityFilter then 
		if (not element:visibilityFilter(unit)) then 
			return element:Hide()
		end
	end

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local barType, minPower, startInset, endInset, smooth, hideFromOthers, showOnRaid, opaqueSpark, opaqueFlash, anchorTop, powerName, powerTooltip = UnitAlternatePowerInfo(unit)

	if (not barType) or (event == "UNIT_POWER_BAR_HIDE") then 
		return element:Hide()
	end 

	local currentPower = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local maxPower = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

	element:SetMinMaxValues(minPower, maxPower) 
	element:SetValue(currentPower, (event == "Forced")) 
	element:UpdateValue(unit, currentPower, minPower, maxPower)

	if (not element:IsShown()) then 
		element:Show()
	end 

	if element.PostUpdate then 
		element:PostUpdate(unit, specIndex)
	end 
end 

local Proxy = function(self, ...)
	return (self.AltPower.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.AltPower
	if element then
		if IS_CLASSIC then 
			element:Hide()
			return 
		end 

		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue
		
		if (element:IsMouseEnabled()) then
			if (not element:GetScript("OnEnter")) then
				element:SetScript("OnEnter", OnEnter)
			end
			if (not element:GetScript("OnLeave")) then
				element:SetScript("OnLeave", OnLeave)
			end
		end

		self:RegisterEvent("UNIT_POWER_UPDATE", Proxy) 
		self:RegisterEvent("UNIT_MAXPOWER", Proxy) 
		self:RegisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:RegisterEvent("UNIT_POWER_BAR_HIDE", Proxy)

		return true
	end
end 

local Disable = function(self)
	local element = self.AltPower
	if element then
		element:Hide()
		if IS_CLASSIC then 
			return 
		end 

		self:UnregisterEvent("UNIT_POWER_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_HIDE", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("AltPower", Enable, Disable, Proxy, 9)
end 
