
-- Lua API
local _G = _G

-- WoW API

-- WoW Constants

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.CrowdControl
	if element.PreUpdate then
		element:PreUpdate(unit)
	end


	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.CrowdControl.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.CrowdControl
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("RAID_TARGET_UPDATE", Proxy)

		return true
	end
end 

local Disable = function(self)
	local element = self.CrowdControl
	if element then
		self:UnregisterEvent("RAID_TARGET_UPDATE", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("CrowdControl", Enable, Disable, Proxy, 1)
end 
