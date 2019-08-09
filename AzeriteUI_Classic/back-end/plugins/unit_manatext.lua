
-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType

-- IDs
local ManaID = Enum.PowerType.Mana or 0

-- Number abbreviations
---------------------------------------------------------------------	
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

local UpdateValue = function(element, unit, min, max)
	if element.showDeficit then
		if element.showPercent then
			if element.showMaximum then
				element:SetFormattedText("%s / %s - %.0f%%", short(max - min), short(max), math_floor(min/max * 100))
			else
				element:SetFormattedText("%s / %.0f%%", short(max - min), math_floor(min/max * 100))
			end
		else
			if element.showMaximum then
				element:SetFormattedText("%s / %s", short(max - min), short(max))
			else
				element:SetFormattedText("%s", short(max - min))
			end
		end
	else
		if element.showPercent then
			if element.showMaximum then
				element:SetFormattedText("%s / %s - %.0f%%", short(min), short(max), math_floor(min/max * 100))
			else
				element:SetFormattedText("%s / %.0f%%", short(min), math_floor(min/max * 100))
			end
		else
			if element.showMaximum then
				element:SetFormattedText("%s / %s", short(min), short(max))
			else
				element:SetFormattedText("%s", short(min))
			end
		end
	end
end 

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.ManaText

	if (UnitIsDeadOrGhost(unit) or (not UnitIsPlayer(unit)) or (not UnitIsConnected(unit))) then 
		if (element:IsShown()) then 
			element:Hide()
		end
		return 
	end  

	local currentID, currentType = UnitPowerType(unit)
	if (currentType == "MANA") then 
		if (element:IsShown()) then 
			element:Hide()
		end
		return 
	end  

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local min = UnitPower(unit, ManaID) or 0
	local max = UnitPowerMax(unit, ManaID) or 0

	if (min == 0) or (max == 0) then 
		if (element:IsShown()) then 
			element:Hide()
		end
		return 
	end 

	if element.colorMana then 
		local r, g, b = unpack(self.colors.power.MANA)
		element:SetTextColor(r, g, b)
	end 

	(element.OverrideValue or UpdateValue) (element, unit, min, max)

	if (not element:IsShown()) then 
		element:Show()
	end
	
	if element.PostUpdate then
		return element:PostUpdate(unit, min, max)
	end	
end 

local Proxy = function(self, ...)
	return (self.ManaText.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.ManaText
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		local unit = self.unit
		if element.frequent and ((unit == "player") or (unit == "pet")) then 
			self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		else 
			self:RegisterEvent("UNIT_POWER_UPDATE", Proxy)
		end 

		self:RegisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:RegisterEvent("UNIT_POWER_BAR_HIDE", Proxy)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)
		self:RegisterEvent("UNIT_CONNECTION", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy)

		return true
	end
end 

local Disable = function(self)
	local element = self.ManaText
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_POWER_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_HIDE", Proxy)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Proxy)
		self:UnregisterEvent("UNIT_CONNECTION", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy)

	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("PowerText", Enable, Disable, Proxy, 3)
end 
