
-- Lua API
local _G = _G

-- WoW API

local UpdateValue = function(element, unit, min, max)
	if element.OverrideValue then
		return element:OverrideValue(unit, min, max)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 

end 

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.Honor
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if element.PostUpdate then 
		element:PostUpdate(unit, specIndex)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.Honor.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Honor
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		element.UpdateValue = UpdateValue

		return true
	end
end 

local Disable = function(self)
	local element = self.Honor
	if element then
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Honor", Enable, Disable, Proxy, 2)
end 
