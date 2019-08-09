-- Lua API
local _G = _G

-- WoW API
local UnitAffectingCombat = _G.UnitAffectingCombat

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Combat
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local inCombat = UnitAffectingCombat("player")
	if (inCombat) then
		element:Show()
		if element.Glow then 
			element.Glow:Show()
		end
	else
		element:Hide()
		if element.Glow then 
			element.Glow:Hide()
		end
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Combat.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Combat
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		local inCombat = UnitAffectingCombat("player")
		if (inCombat) then
			element:Show()
			if element.Glow then 
				element.Glow:Show()
			end
		else
			element:Hide()
			if element.Glow then 
				element.Glow:Hide()
			end
		end

		self:RegisterEvent("PLAYER_REGEN_DISABLED", Proxy, true)
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Proxy, true)

		return true
	end
end 

local Disable = function(self)
	local element = self.Combat
	if element then
		element:Hide()

		if element.Glow then 
			element.Glow:Hide()
		end

		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Proxy)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Combat", Enable, Disable, Proxy, 3)
end 
