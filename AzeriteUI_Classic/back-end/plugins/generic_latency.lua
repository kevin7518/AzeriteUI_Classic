
-- Lua API
local _G = _G
local math_floor = math.floor

-- WoW API
local GetNetStats = _G.GetNetStats

local UpdateValue = function(element, home, world)
	if element.OverrideValue then
		return element:OverrideValue(home, world)
	end
	if element:IsObjectType("FontString") then 
		element:SetFormattedText("%.0f%s - %.0f%s", math_floor(home), MILLISECONDS_ABBR, math_floor(world), MILLISECONDS_ABBR)
	end 
end 

local Update = function(self, event, ...)
	local element = self.Latency
	if element.PreUpdate then 
		element:PreUpdate()
	end 

	-- http://eu.battle.net/wow/en/forum/topic/1710231176
	-- latencyHome: chat, auction house, some addon data
	-- latencyWorld: combat, data from the people around you (specs, gear, enchants, etc.), NPCs, mobs, casting, professions
	local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
	element:UpdateValue(latencyHome or 0, latencyWorld or 0) -- adding 0 fallbacks to avoid post checks 

	if element.PostUpdate then 
		return element:PostUpdate(latencyHome, latencyWorld)
	end 
end 

local Proxy = function(self, ...)
	return (self.Latency.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Latency
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterUpdate(Proxy, 30)

		return true
	end
end 

local Disable = function(self)
	local element = self.Latency
	if element then
		self:UnregisterUpdate(Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Latency", Enable, Disable, Proxy, 3)
end 
