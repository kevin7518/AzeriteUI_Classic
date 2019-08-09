local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "ClassPower requires LibFrame to be loaded.")

-- Lua API
local _G = _G
local setmetatable = setmetatable
local table_sort = table.sort

-- WoW API
local Enum = _G.Enum
local GetComboPoints = _G.GetComboPoints
local IsPlayerSpell = _G.IsPlayerSpell
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerDisplayMod = _G.UnitPowerDisplayMod
local UnitPowerType = _G.UnitPowerType

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local SPELL_POWER_COMBO_POINTS = Enum and Enum.PowerType.ComboPoints or SPELL_POWER_COMBO_POINTS or 4 

-- Sourced from FrameXML/TargetFrame.lua
local MAX_COMBO_POINTS = _G.MAX_COMBO_POINTS or 5

-- Class specific info
local _, PLAYERCLASS = UnitClass("player")

-- Declare core function names so we don't 
-- have to worry about the order we put them in.
local Proxy, ForceUpdate, Update

-- Generic methods used by multiple powerTypes
local Generic = setmetatable({
	EnablePower = function(self)
		local element = self.ClassPower
		--element.maxDisplayed = MAX_COMBO_POINTS

		for i = 1, #element do 
			element[i]:SetMinMaxValues(0,1)
			element[i]:SetValue(0)
			element[i]:Hide()
		end 

		if (element.alphaNoCombat) or (element.alphaNoCombatRunes) then 
			self:RegisterEvent("PLAYER_REGEN_DISABLED", Proxy, true)
			self:RegisterEvent("PLAYER_REGEN_ENABLED", Proxy, true)
		end 

		if (element.hideWhenNoTarget) then 
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Proxy, true)
		end 
		
	end,
	DisablePower = function(self)
		local element = self.ClassPower
		element.powerID = nil
		element.isEnabled = false
		element.max = 0
		element.maxDisplayed = nil
		element:Hide()

		for i = 1, #element do 
			element[i]:Hide()
			element[i]:SetMinMaxValues(0,1)
			element[i]:SetValue(0)
			element[i]:SetScript("OnUpdate", nil)
		end 

		self:UnregisterEvent("PLAYER_REGEN_DISABLED", Proxy)
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", Proxy)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Proxy)
	end, 
	UpdatePower = function(self, event, unit, ...)
		local element = self.ClassPower
		if (not element.isEnabled) then 
			element:Hide()
			return 
		end 

		local powerType = element.powerType
		local powerID = element.powerID 

		local min = UnitPower("player", powerID) or 0
		local max = UnitPowerMax("player", powerID) or 0

		local maxDisplayed = element.maxDisplayed or element.max or max


		for i = 1, maxDisplayed do 
			local point = element[i]
			if (not point:IsShown()) then 
				point:Show()
			end 
			point:SetValue(min >= i and 1 or 0)
		end 

		for i = maxDisplayed+1, #element do 
			element[i]:SetValue(0)
			if element[i]:IsShown() then 
				element[i]:Hide()
			end 
		end 

		return min, max, powerType
	end, 
	UpdateColor = function(element, unit, min, max, powerType)
		local self = element._owner
		local color = self.colors.power[powerType] 
		local r, g, b = color[1], color[2], color[3]
		local maxDisplayed = element.maxDisplayed or element.max or max

		-- Class Color Overrides
		if (element.colorClass and UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			color = class and self.colors.class[class]
			r, g, b = color[1], color[2], color[3]
		end 

		-- Has the module chosen to only show this with an active target,
		-- or has the module chosen to hide all when empty?
		if (element.hideWhenNoTarget and (not UnitExists("target"))) 
		or (element.hideWhenUnattackable and (not UnitCanAttack("player", "target"))) 
		or (element.hideWhenEmpty and (min == 0)) then 
			for i = 1, maxDisplayed do
				local point = element[i]
				if point then
					point:SetAlpha(0)
				end 
			end 
		else 
			-- In case there are more points active 
			-- then the currently allowed maximum. 
			-- Meant to give an easy system to handle 
			-- the Rogue Anticipation talent without 
			-- the need for the module to write extra code. 
			local overflow
			if min > maxDisplayed then 
				overflow = min % maxDisplayed
			end 
			for i = 1, maxDisplayed do

				-- upvalue to preserve the original colors for the next point
				local r, g, b = r, g, b 

				-- Handle overflow coloring
				if overflow then
					if (i > overflow) then
						-- tone down "old" points
						r, g, b = r*1/3, g*1/3, b*1/3 
					else 
						-- brighten the overflow points
						r = (1-r)*1/3 + r
						g = (1-g)*1/4 + g -- always brighten the green slightly less
						b = (1-b)*1/3 + b
					end 
				end 

				local point = element[i]
				if element.alphaNoCombat then 
					point:SetStatusBarColor(r, g, b)
					if point.bg then 
						point.bg:SetVertexColor(r*1/3, g*1/3, b*1/3)
					end 
					local alpha = UnitAffectingCombat(unit) and 1 or element.alphaNoCombat
					if (i > min) and (element.alphaEmpty) then
						point:SetAlpha(element.alphaEmpty * alpha)
					else 
						point:SetAlpha(alpha)
					end 
				else 
					point:SetStatusBarColor(r, g, b, 1)
					if element.alphaEmpty then 
						point:SetAlpha(min > i and element.alphaEmpty or 1)
					else 
						point:SetAlpha(1)
					end 
				end 
			end
		end 
	end
}, { __index = LibFrame:CreateFrame("Frame") })
local Generic_MT = { __index = Generic }

-- Specific powerTypes
local ClassPower = {}
ClassPower.None = {
	EnablePower = function(self) 
		local element = self.ClassPower
		for i = 1, #element do 
			element[i]:SetMinMaxValues(0,1)
			element[i]:SetValue(0)
			element[i]:Hide()
		end 
	end, 
	DisablePower = function() end, 
	UpdatePower = function() end, 
	UpdateColor = function() end, 
}

ClassPower.ComboPoints = setmetatable({ 
	ShouldEnable = function(self)
		local element = self.ClassPower
		if (PLAYERCLASS == "DRUID") then 
			local powerType = UnitPowerType("player")
			if (IsPlayerSpell(5221) and (powerType == SPELL_POWER_ENERGY)) then 
				return true
			end 
		else 
			return true
		end 
	end,
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_COMBO_POINTS
		element.powerType = "COMBO_POINTS"
		element.maxDisplayed = element.maxComboPoints or MAX_COMBO_POINTS or 5

		if (PLAYERCLASS == "DRUID") then 
			element.isEnabled = element.ShouldEnable(self)
			self:RegisterEvent("SPELLS_CHANGED", Proxy, true)
		else 
			if (PLAYERCLASS == "ROGUE") then 
				self:RegisterEvent("PLAYER_TALENT_UPDATE", Proxy, true)
			end 
			element.isEnabled = true
		end 

		self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)
	
		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("SPELLS_CHANGED", Proxy)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.DisablePower(self)
	end, 
	UpdatePower = function(self, event, unit, ...)
		local element = self.ClassPower
		local min, max

		-- Vehicles first
		if (not IS_CLASSIC) then 
			element.isEnabled = true
			element.max = MAX_COMBO_POINTS

			-- BUG: UnitPower always returns 0 combo points for vehicles
			min = GetComboPoints(unit) or 0
			max = MAX_COMBO_POINTS
		else
			if (PLAYERCLASS == "DRUID") then
				if (event == "SPELLS_CHANGED") or (event == "UNIT_DISPLAYPOWER") then 
					element.isEnabled = element.ShouldEnable(self)
				end 
			end
			min = UnitPower("player", element.powerID) or 0
			max = UnitPowerMax("player", element.powerID) or 0
		end 
		if (not element.isEnabled) then 
			element:Hide()
			return 
		end 

		local maxDisplayed = element.maxDisplayed or element.max or max

		for i = 1, maxDisplayed do 
			local point = element[i]
			if not point:IsShown() then 
				point:Show()
			end 

			local value = min >= i and 1 or 0
			point:SetValue(value)
		end 

		for i = maxDisplayed+1, #element do 
			element[i]:SetValue(0)
			if element[i]:IsShown() then 
				element[i]:Hide()
			end 
		end 

		return min, max, element.powerType
	end
}, Generic_MT)

-- The general update method for all powerTypes
Update = function(self, event, unit, ...)
	local element = self.ClassPower

	-- Run the general preupdate
	if element.PreUpdate then 
		element:PreUpdate(unit)
	end 

	-- Store the old maximum value, if any
	local oldMax = element.max

	-- Run the current powerType's Update function
	local min, max, powerType = element.UpdatePower(self, event, unit, ...)

	-- Stop execution if element was disabled 
	-- during its own update cycle.
	if (not element.isEnabled) then 
		return 
	end 

	-- Post update element colors, allow modules to override
	local updateColor = element.OverrideColor or element.UpdateColor
	if updateColor then 
		updateColor(element, unit, min, max, powerType)
	end 

	if (not element:IsShown()) then 
		element:Show()
	end 

	-- Run the general postupdate
	if element.PostUpdate then 
		return element:PostUpdate(unit, min, max, oldMax ~= max, powerType)
	end 
end 

-- This is where the current powerType is decided, 
-- where we check for and unregister conditional events
-- related to player specialization, talents or level.
-- This is also where we toggle the current element,
-- disable the old and enable the new. 
local UpdatePowerType = function(self, event, unit, ...)
	local element = self.ClassPower

	-- Should be safe to always check for unit even here, 
	-- our unitframe library should provide it if unitless events are registered properly.
	if (not unit) or (unit ~= self.unit) or (event == "UNIT_POWER_FREQUENT" and (...) ~= element.powerType) then 
		return 
	end 

	local newType 
	if ((PLAYERCLASS == "DRUID") or (PLAYERCLASS == "ROGUE")) and (not element.ignoreComboPoints) then 
		newType = "ComboPoints"
	else 
		newType = "None"
	end 

	local currentType = element._currentType

	-- Disable previous type if present and different
	if (currentType) and (currentType ~= newType) then 
		element.DisablePower(self)
	end 

	-- Set or change the powerType if there is a new or initial one
	if (not currentType) or (currentType ~= newType) then 

		-- Update type
		element._currentType = newType

		-- Change the meta
		setmetatable(element, { __index = ClassPower[newType] })

		-- Enable using new type
		element.EnablePower(self)
	end 

	-- Continue to the regular update method
	return Update(self, event, unit, ...)
end 

Proxy = function(self, ...)
	return (self.ClassPower.Override or UpdatePowerType)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.ClassPower
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		-- Give points access to their owner element, 
		-- regardless of whether that element is their direct parent or not. 
		for i = 1,#element do
			element[i]._owner = element
		end

		self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)

		--if element.hideWhenNoTarget then 
		--	self:RegisterEvent("PLAYER_TARGET_CHANGED", Proxy, true)
		--end 

		return true
	end
end 

local Disable = function(self)
	local element = self.ClassPower
	if element then

		-- Disable the current powerType, if any
		if element._currentType then 
			element.DisablePower(self)
			element._currentType = nil
			element.powerType = nil
		end 

		-- Remove generic events
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Proxy)
		--self:UnregisterEvent("PLAYER_TARGET_CHANGED", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("ClassPower", Enable, Disable, Proxy, 31)
end 
