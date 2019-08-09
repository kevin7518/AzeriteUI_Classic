local LibTime = CogWheel("LibTime")
assert(LibTime, "Clock requires LibTime to be loaded.")

-- Lua API
local _G = _G
local date = date
local tonumber = tonumber

-- proxy method bypassing the self
local GetTime = function(...) return LibTime:GetTime(...) end

local UpdateValue = function(element, h, m, suffix)
	if element.OverrideValue then 
		return element:OverrideValue(h, m, suffix)
	end 
	if (element:IsObjectType("FontString")) then 
		if element.useStandardTime then 
			element:SetFormattedText("%.0f:%02d %s", h, m, suffix)
		else 
			element:SetFormattedText("%02d:%02d", h, m)
		end 
	end 
end 

local Update = function(self, event, ...)
	local element = self.Clock
	if element.PreUpdate then
		element:PreUpdate(event, ...)
	end
	local h, m, suffix = GetTime(element.useStandardTime, element.useServerTime)
	element:UpdateValue(h, m, suffix)
	if element.PostUpdate then 
		return element:PostUpdate(h, m, suffix)
	end 
end 

local Proxy = function(self, ...)
	return (self.Clock.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Clock
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue
		self:RegisterUpdate(Proxy, 1)
		return true
	end
end 

local Disable = function(self)
	local element = self.Clock
	if element then
		self:UnregisterUpdate(Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Clock", Enable, Disable, Proxy, 9)
end 
