local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "ClassPower requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

-- Lua API
local _G = _G
local ipairs = ipairs

-- WoW API
local GetSpecialization = _G.GetSpecialization
local UnitLevel = _G.UnitLevel

-- WoW Constants
local SHOW_SPEC_LEVEL = _G.SHOW_SPEC_LEVEL or 10

local Update = function(self, event, unit)

	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.Spec

	-- Units can change, like when entering or leaving vehicles
	if (unit ~= "player") then 
		return element:Hide()
	end 

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local specIndex = GetSpecialization() or 0 

	-- No real need to check for number of specializations, 
	-- since we wish to hide all objects not matching the correct ID anyway.
	for id in ipairs(element) do 
		element[id]:SetShown(id == specIndex)
	end 

	-- Make sure the spec element is shown, 
	-- as this could've been called upon reaching SHOW_SPEC_LEVEL
	if (not element:IsShown()) then 
		element:Show()
	end 

	if element.PostUpdate then 
		element:PostUpdate(unit, specIndex)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.Spec.Override or Update)(self, ...)
end 

local SpecUpdate
SpecUpdate = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if ((level or UnitLevel("player")) < SHOW_SPEC_LEVEL) then 
			return 
		end
		
		self:UnregisterEvent("PLAYER_LEVEL_UP", SpecUpdate, true)
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy, true)
		
		return Proxy(self, ...)
	end 
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Spec
	if element then
		if IS_CLASSIC then 
			element:Hide()
			return 
		else
			element._owner = self
			element.ForceUpdate = ForceUpdate

			if (UnitLevel("player") < SHOW_SPEC_LEVEL) then 
				element:Hide()
				self:RegisterEvent("PLAYER_LEVEL_UP", SpecUpdate, true)
			else 
				self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy, true)
			end 

			return true
		end
	end
end 

local Disable = function(self)
	local element = self.Spec
	if element then
		if (not IS_CLASSIC) then 
			self:UnregisterEvent("PLAYER_LEVEL_UP", SpecUpdate)
			self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy)
		end 
		element:Hide()
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Spec", Enable, Disable, Proxy, 3)
end 
