-- Lua API
local _G = _G
local pairs = pairs

-- WoW API
local GetPVPTimer = _G.GetPVPTimer
local UnitClassification = _G.UnitClassification
local UnitFactionGroup = _G.UnitFactionGroup
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsPVPFreeForAll = _G.UnitIsPVPFreeForAll
local UnitIsPVPSanctuary = _G.UnitIsPVPSanctuary
local UnitLevel = _G.UnitLevel

-- Objects that we'll be looking for in the element
local objects = {
	boss = "Boss",
	elite = "Elite", 
	minus = "Minus",
	rare = "Rare", 
	rareelite = "RareElite",
	worldboss = "WorldBoss",
	horde = "Horde",
	alliance = "Alliance"
}

-- Replacement classifications in case the element 
-- doesn't use worldboss or rareelite. Which mine doesn't!
local proxies = {
	rareelite = "rare",
	worldboss = "boss"
}

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Classification
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	-- classification to be used in post updates
	local classification

	-- PvP always takes priority
	if UnitIsPVP(unit) then
		local faction = UnitFactionGroup(unit)
		if faction then 
			classification = (faction == "Alliance") and "alliance" or (faction == "Horde") and "horde"
		end 

	-- Hide for non-pvp enabled players
	elseif UnitIsPlayer(unit) then 
		return element:Hide()
	else

		-- Show classification for boss/rare/elite npcs.
		local level = UnitLevel(unit)
		classification = (level and (level < 1)) and "worldboss" or UnitClassification(unit)
	end 

	-- Return and hide if nothing usable was found
	local key = classification and objects[classification]
	if (not key) then 
		return element:Hide()
	end 

	-- Add a little system to allow 'boss' to be used instead of 'worldboss' and 'rare' instead of 'rareelite'
	local object = element[key]
	if (not object) then 
		local proxyClassification = proxies[classification]
		if proxyClassification then 
			local proxyKey = objects[proxyClassification] 
			if proxyKey then 
				local proxy = element[proxyKey] 
				if proxy then 
					object = proxy 
					classification = proxyClassification
				end 
			end 
		end 
	end 

	-- return and hide if nothing was found
	if (not classification) then 
		return element:Hide()
	end

	local shown
	for id,key in pairs(objects) do 
		local object = element[key] 
		if object then
			local show = id == classification
			object:SetShown(show)
			shown = shown or show 
		end 
	end 

	if shown then 
		if (not element:IsShown()) then 
			element:Show()
		end
	else 
		return element:Hide()
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit, classification)
	end
end 

local Proxy = function(self, ...)
	return (self.Classification.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Classification
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Proxy, true)
		
		return true 
	end
end 

local Disable = function(self)
	local element = self.Classification
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Classification", Enable, Disable, Proxy, 4)
end 
