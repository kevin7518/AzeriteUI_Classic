
-- Lua API
local _G = _G

-- WoW API
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.RaidTarget
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local index = GetRaidTargetIndex(unit)
	if (index) then
		SetRaidTargetIconTexture(element, index)
		element:Show()
	else
		element:Hide()
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.RaidTarget.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.RaidTarget
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("RAID_TARGET_UPDATE", Proxy, true)

		if (element:IsObjectType("Texture") and (not element:GetTexture())) then
			element:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		end

		return true
	end
end 

local Disable = function(self)
	local element = self.RaidTarget
	if element then
		self:UnregisterEvent("RAID_TARGET_UPDATE", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("RaidTarget", Enable, Disable, Proxy, 3)
end 
