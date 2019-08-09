
-- Lua API
local _G = _G

-- WoW API
local UnitExists = _G.UnitExists
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsUnit = _G.UnitIsUnit

local targetToObject = { 
	YouByFriend = true, -- friendly targeting you
	YouByEnemy = true, -- hostile targeting you
	PetByEnemy = true -- hostile targeting pet
}

local Update = function(self, event, unit, ...)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.Targeted
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local target = unit .. "target"
	local targetedUnit, targetedConditional
	if UnitExists(target) and (not UnitIsUnit(unit, "player")) then 
		if UnitIsUnit(target, "player") then 
			targetedUnit = "player"
			if UnitCanAttack("player", unit) then 
				targetedConditional = "harm"
				for objectName in pairs(targetToObject) do 
					local object = element[objectName]
					if object then 
						object:SetShown(objectName == "YouByEnemy")
					end 
				end 
			else 
				targetedConditional = "help"
				for objectName in pairs(targetToObject) do 
					local object = element[objectName]
					if object then 
						object:SetShown(objectName == "YouByFriend")
					end 
				end 
			end 

		elseif UnitIsUnit(target, "pet") then 
			targetedUnit = "pet"
			if UnitCanAttack("player", unit) then 
				targetedConditional = "harm"
				for objectName in pairs(targetToObject) do 
					local object = element[objectName]
					if object then 
						object:SetShown(objectName == "PetByEnemy")
					end 
				end 
			end 
		end 
	end 

	if (not targetedUnit and not targetedConditional) then 
		for objectName in pairs(targetToObject) do 
			local object = element[objectName]
			if object then 
				object:Hide()
			end 
		end 
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit, targetedUnit, targetedConditional)
	end
end 

local Proxy = function(self, ...)
	return (self.Targeted.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Targeted
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		-- There are no events we can check for this, 
		-- so we're using frequent updates forecefully. 
		-- The flag does however allow the modules to throttle it. 
		self:EnableFrequentUpdates("Targeted", element.frequent)

		return true 
	end
end 

local Disable = function(self)
	local element = self.Targeted
	if element then
		-- Nothing to do. Frequent updates are cancelled automatically. 
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Targeted", Enable, Disable, Proxy, 3)
end 
