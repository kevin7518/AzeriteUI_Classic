
-- Lua API
local _G = _G

-- WoW API
local UnitHasIncomingResurrection = _G.UnitHasIncomingResurrection

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.ResurrectIndicator
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local incomingResurrect = UnitHasIncomingResurrection(unit)
	if (incomingResurrect) then
		element:Show()
	else
		element:Hide()
	end

	element.status = incomingResurrect

	if element.PostUpdate then 
		return element:PostUpdate(unit, incomingResurrect)
	end 
end 

local Proxy = function(self, ...)
	return (self.ResurrectIndicator.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.ResurrectIndicator
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("INCOMING_RESURRECT_CHANGED", Proxy)

		if (element:IsObjectType("Texture") and (not element:GetTexture())) then
			element:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
		end

		return true
	end
end 

local Disable = function(self)
	local element = self.ResurrectIndicator
	if element then
		self:UnregisterEvent("INCOMING_RESURRECT_CHANGED", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("ResurrectIndicator", Enable, Disable, Proxy, 2)
end 
