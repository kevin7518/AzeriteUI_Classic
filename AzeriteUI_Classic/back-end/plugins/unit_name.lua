
-- Lua API
local _G = _G

-- WoW API
local UnitClassification = _G.UnitClassification
local UnitFactionGroup = _G.UnitFactionGroup
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsPVPFreeForAll = _G.UnitIsPVPFreeForAll
local UnitIsPVPSanctuary = _G.UnitIsPVPSanctuary
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName

local ELITE_TEXTURE = "|cffff4444+|r"
local RARE_TEXTURE = "|cff0070dd(" .. ITEM_QUALITY3_DESC .. ") |r"
local BOSS_TEXTURE = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t"
local FFA_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-FFA:16:12:-2:1:64:64:6:34:0:40|t"
local ALLIANCE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:16:12:-2:1:64:64:6:34:0:40|t"
local HORDE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t"
local NEUTRAL_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Neutral:16:12:-2:1:64:64:6:34:0:40|t"

local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Name
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	-- Retrieve data
	local name, realm = UnitName(unit)
	local level = UnitLevel(unit)
	local classification = (level and (level < 1)) and "worldboss" or UnitClassification(unit)

	local isBoss = classification == "boss" or classification == "worldboss"
	local isElite = classification == "elite" or classification == "rareelite"
	local isRare = classification == "rare" or classification == "rareelite"
	local isPvP = UnitIsPVP(unit) or UnitIsPVPFreeForAll(unit)

	-- Truncate name
	if element.maxChars then 
		name = utf8sub(name, element.maxChars, element.useDots)
	end 

	-- Display a fitting PvP icon, but suppress it if the unit is a PvP enabled boss, elite or rare
	if element.showPvP and isPvP and not(element.showBoss and isBoss) and not(element.showElite and isElite) and not(element.showRare and isRare) then 
		local faction = UnitFactionGroup(unit)
		local pvp = (faction == "Alliance") and ALLIANCE_TEXTURE or (faction == "Horde") and HORDE_TEXTURE or FFA_TEXTURE
		name = name .. pvp
	end 

	-- Show a plus sign for elites, but suppress it if the unit is a boss
	if element.showElite and isElite and not(element.showBoss and isBoss) then 
		name = name .. ELITE_TEXTURE
	end

	-- Display a rare indicator
	if element.showRare and isRare then 
		name = RARE_TEXTURE .. name
	end

	-- Show the boss skull
	if element.showBoss and isBoss then 
		name = name .. BOSS_TEXTURE
	end

	element:SetText(name)

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Name.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Name
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_NAME_UPDATE", Proxy)
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Proxy, true)

		return true
	end
end 

local Disable = function(self)
	local element = self.Name
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_NAME_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Name", Enable, Disable, Proxy, 6)
end 
