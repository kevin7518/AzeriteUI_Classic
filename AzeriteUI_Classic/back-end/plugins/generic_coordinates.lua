
-- Lua API
local _G = _G

-- WoW API
local C_Map = _G.C_Map
local GetBestMapForUnit = C_Map and C_Map.GetBestMapForUnit
local GetPlayerMapPosition = C_Map and C_Map.GetPlayerMapPosition

-- WoW Frames
local WorldMapFrame = _G.WorldMapFrame

local UpdateValue = function(element, x, y)
	if element.OverrideValue then 
		return element:OverrideValue(x, y)
	end 
	element:SetFormattedText("%.1f %.1f", x*100, y*100) 
end 

local Update = function(self, elapsed)
	local element = self.Coordinates
	if element.PreUpdate then
		element:PreUpdate()
	end

	local x, y
	local mapID = GetBestMapForUnit("player")
	if mapID then 
		local mapPosObject = GetPlayerMapPosition(mapID, "player")
		if mapPosObject then 
			x, y = mapPosObject:GetXY()
		end 
	end 

	x = x or 0
	y = y or 0

	element:SetShown(x + y > 0)
	element:UpdateValue(x, y)

	if element.PostUpdate then 
		element:PostUpdate(x,y)
	end 

end 

local Proxy = function(self, ...)
	return (self.Coordinates.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Coordinates
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue
		self:RegisterUpdate(Proxy, 1/10)
		return true
	end
end 

local Disable = function(self)
	local element = self.Coordinates
	if element then
		self:UnregisterUpdate(Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Coordinates", Enable, Disable, Proxy, 7)
end 
