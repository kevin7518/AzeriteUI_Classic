
-- Lua API
local _G = _G
local math_floor = math.floor

-- WoW API
local GetFramerate = _G.GetFramerate

local UpdateValue = function(element, fps)
	if element.OverrideValue then
		return element:OverrideValue(fps)
	end
	if element:IsObjectType("FontString") then 
		element:SetFormattedText("%.0f%s", math_floor(fps), FPS_ABBR)
	end 
end 

local Update = function(self)
	local element = self.FrameRate
	if element.PreUpdate then 
		element:PreUpdate()
	end 

	local fps = GetFramerate()
	element:UpdateValue(fps)

	if element.PostUpdate then 
		return element:PostUpdate(fps)
	end 
end 

local Proxy = function(self, ...)
	return (self.FrameRate.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.FrameRate
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterUpdate(Proxy, 1)

		return true
	end
end 

local Disable = function(self)
	local element = self.Performance
	if element then
		self:UnregisterUpdate(Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("FrameRate", Enable, Disable, Proxy, 3)
end 
