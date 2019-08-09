
-- Lua API
local _G = _G
local math_floor = math.floor
local select = select
local unpack = unpack

-- WoW API
local GetMinimapZoneText = _G.GetMinimapZoneText
local SetMapToCurrentZone = _G.SetMapToCurrentZone

-- WoW Frames
local WorldMapFrame = _G.WorldMapFrame


-- RGB to Hex Color Code
local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local prepare = function(...)
	local tbl
	if (select("#", ...) == 1) then
		local old = ...
		if (old.r) then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if (#tbl == 3) then
		tbl.colorCode = hex(unpack(tbl))
	end
	return tbl
end

local Colors = {}
Colors.normal = prepare( 229/255, 178/255, 38/255 )
Colors.highlight = prepare( 250/255, 250/255, 250/255 )
Colors.title = prepare( 255/255, 234/255, 137/255 )

Colors.zone = {}
Colors.zone.arena = prepare( 175/255, 76/255, 56/255 )
Colors.zone.combat = prepare( 175/255, 76/255, 56/255 ) 
Colors.zone.contested = prepare( 229/255, 159/255, 28/255 )
Colors.zone.friendly = prepare( 64/255, 175/255, 38/255 ) 
Colors.zone.hostile = prepare( 175/255, 76/255, 56/255 ) 
Colors.zone.sanctuary = prepare( 104/255, 204/255, 239/255 )
Colors.zone.unknown = prepare( 255/255, 234/255, 137/255 ) -- instances, bgs, contested zones on pve realms 


local UpdateValue = function(element, minimapZoneName, pvpType)
	if element.OverrideValue then
		return element:OverrideValue()
	end
	if (element:IsObjectType("FontString")) then 
		local r, g, b
		local a = element:GetAlpha() or 1
		if (element.colorPvP and pvpType) then 
			local color = (element.colors or Colors).zone[pvpType]
			if color then 
				r, g, b = unpack(color)
			end 
		elseif element.colorDifficulty then 
		end 
		if (r and g and b) then 
			element:SetTextColor(r, g, b, a)
		else 
			r, g, b = unpack((element.colors or Colors).normal)
			element:SetTextColor(r, g, b, a)
		end 
		element:SetText(minimapZoneName)
	end 
end 

local Update = function(self, event, unit)
	local element = self.Zone
	if element.PreUpdate then
		element:PreUpdate()
	end

	local minimapZoneName = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()

	element:UpdateValue(minimapZoneName, pvpType)

	if element.PostUpdate then 
		return element:PostUpdate()
	end 
end 

local Proxy = function(self, ...)
	return (self.Zone.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Zone
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy, true)
		self:RegisterEvent("ZONE_CHANGED", Proxy, true)
		self:RegisterEvent("ZONE_CHANGED_INDOORS", Proxy, true)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Proxy, true)
	
		return true
	end
end 

local Disable = function(self)
	local element = self.Zone
	if element then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		self:UnregisterEvent("ZONE_CHANGED", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_INDOORS", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Zone", Enable, Disable, Proxy, 5)
end 
