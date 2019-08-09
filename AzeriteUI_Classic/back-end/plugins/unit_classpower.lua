--[[

	Class Powers available in Battel for Azeroth:
	* Combo Points: 	Fast generated points. 5 cap, 6 if talented, 0 baseline.


	Class Powers available in Legion: 
	* Arcane Charge: 	Generated points. 4 cap. 0 baseline.
	* Chi: 				Generated points. 4 cap, 5 if talented, 0 baseline.
	* Combo Points: 	Fast generated points. 5 cap, 6 if talented, 0 baseline.
	* Holy Power: 		Fast generated points. 3 cap, 0 baseline.
	* Runes: 			Fast refilling points. 6 cap, 6 baseline.
	* Soul Shards: 		Slowly generated points. 5 cap, 1 point baseline.
	* Stagger: 			Generated points. 3 cap. 3 baseline. 

]]--

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "ClassPower requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "ClassPower requires LibFrame to be loaded.")

-- Lua API
local _G = _G
local setmetatable = setmetatable
local table_sort = table.sort

-- WoW API
local Enum = _G.Enum
local GetComboPoints = _G.GetComboPoints
local GetRuneCooldown = _G.GetRuneCooldown
local GetSpecialization = _G.GetSpecialization
--local InCombatLockdown = _G.InCombatLockdown
local IsPlayerSpell = _G.IsPlayerSpell
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitHasVehiclePlayerFrameUI = _G.UnitHasVehiclePlayerFrameUI
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerDisplayMod = _G.UnitPowerDisplayMod
local UnitPowerType = _G.UnitPowerType
local UnitStagger = _G.UnitStagger

-- WoW Constants
-- Sourced from BlizzardInterfaceCode/Interface/FrameXML/Constants.lua
local SHOW_SPEC_LEVEL = _G.SHOW_SPEC_LEVEL or 10
local SPEC_WARLOCK_AFFLICTION = _G.SPEC_WARLOCK_AFFLICTION or 1	--These are spec indices
local SPEC_WARLOCK_DEMONOLOGY = _G.SPEC_WARLOCK_DEMONOLOGY or 2
local SPEC_WARLOCK_DESTRUCTION = _G.SPEC_WARLOCK_DESTRUCTION or 3
local SPEC_PRIEST_SHADOW = _G.SPEC_PRIEST_SHADOW or 3
local SPEC_MONK_MISTWEAVER = _G.SPEC_MONK_MISTWEAVER or 2
local SPEC_MONK_BREWMASTER = _G.SPEC_MONK_BREWMASTER or 1
local SPEC_MONK_WINDWALKER = _G.SPEC_MONK_WINDWALKER or 3
local SPEC_PALADIN_RETRIBUTION = _G.SPEC_PALADIN_RETRIBUTION or 3
local SPEC_MAGE_ARCANE = _G.SPEC_MAGE_ARCANE or 1
local SPEC_SHAMAN_RESTORATION = _G.SPEC_SHAMAN_RESTORATION or 3

-- Sourced from BlizzardInterfaceResources/Resources/EnumerationTables.lua
local SPELL_POWER_ARCANE_CHARGES = Enum and Enum.PowerType.ArcaneCharges or SPELL_POWER_ARCANE_CHARGES or 16
local SPELL_POWER_CHI = Enum and Enum.PowerType.Chi or SPELL_POWER_CHI or 12
local SPELL_POWER_COMBO_POINTS = Enum and Enum.PowerType.ComboPoints or SPELL_POWER_COMBO_POINTS or 4 
local SPELL_POWER_ENERGY = Enum and Enum.PowerType.Energy or SPELL_POWER_ENERGY or 3 
local SPELL_POWER_HOLY_POWER = Enum and Enum.PowerType.HolyPower or SPELL_POWER_HOLY_POWER or 9
local SPELL_POWER_RUNES = Enum and Enum.PowerType.Runes or SPELL_POWER_RUNES or 5
local SPELL_POWER_SOUL_SHARDS = Enum and Enum.PowerType.SoulShards or SPELL_POWER_SOUL_SHARDS or 7

-- Sourced from BlizzardInterfaceCode/Interface/FrameXML/MonkStaggerBar.lua
-- percentages at which bar should change color
local STAGGER_YELLOW_TRANSITION = _G.STAGGER_YELLOW_TRANSITION or .3
local STAGGER_RED_TRANSITION = _G.STAGGER_RED_TRANSITION or .6

-- table indices of bar colors
local STAGGER_GREEN_INDEX = _G.STAGGER_GREEN_INDEX or 1
local STAGGER_YELLOW_INDEX = _G.STAGGER_YELLOW_INDEX or 2
local STAGGER_RED_INDEX = _G.STAGGER_RED_INDEX or 3

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

ClassPower.ArcaneCharges = setmetatable({ 
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_ARCANE_CHARGES
		element.powerType = "ARCANE_CHARGES"
		element.isEnabled = true
		element.maxDisplayed = element.maxComboPoints or 5

		self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.DisablePower(self)
	end
}, Generic_MT)

ClassPower.Chi = setmetatable({ 
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_CHI
		element.powerType = "CHI"
		element.isEnabled = true
		element.maxDisplayed = element.maxComboPoints or 5

		self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.DisablePower(self)
	end
}, Generic_MT)

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
		if (not IS_CLASSIC) and UnitHasVehiclePlayerFrameUI("player") then 
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

ClassPower.HolyPower = setmetatable({ 
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_HOLY_POWER
		element.powerType = "HOLY_POWER"
		element.isEnabled = true
		element.maxDisplayed = element.maxComboPoints or 5

		self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.DisablePower(self)
	end
}, Generic_MT)

ClassPower.Runes = setmetatable({ 

	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_RUNES
		element.powerType = "RUNES"
		element.max = 6 -- no global value exists for this
		element.maxDisplayed = nil -- don't limit this by default
		element.runeOrder = { 1, 2, 3, 4, 5, 6 } -- starting with a numeric order
		element.isEnabled = true

		self:RegisterEvent("RUNE_POWER_UPDATE", Proxy, true)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		local element = self.ClassPower
		element.runeOrder = nil
		for i = 1, #element do 
			element[i]:SetScript("OnUpdate", nil)
		end 
		Generic.DisablePower(self)
	end, 
	SortByTimeAsc = function(runeAID, runeBID)
		local runeAStart, _, runeARuneReady = GetRuneCooldown(runeAID)
		local runeBStart, _, runeBRuneReady = GetRuneCooldown(runeBID)
		if (runeARuneReady ~= runeBRuneReady) then
			return runeARuneReady
		elseif (runeAStart ~= runeBStart) then
			return runeAStart < runeBStart
		else
			return runeAID < runeBID
		end
	end,
	SortByTimeDesc = function(runeAID, runeBID)
		local runeAStart, _, runeARuneReady = GetRuneCooldown(runeAID)
		local runeBStart, _, runeBRuneReady = GetRuneCooldown(runeBID)
		if (runeARuneReady ~= runeBRuneReady) then
			return runeBRuneReady
		elseif (runeAStart ~= runeBStart) then
			return runeAStart > runeBStart
		else
			return runeAID > runeBID
		end
	end,
	OnUpdateRune = function(rune, elapsed)
		rune.duration = rune.duration + elapsed
		rune:SetValue(rune.duration, true)
	end,
	UpdatePower = function(self, event, unit, ...)
		local element = self.ClassPower
		if (not element.isEnabled) then 
			element:Hide()
			return 
		end 

		if (element.runeSortOrder == "ASC") then
			table_sort(element.runeOrder, element.SortByTimeAsc)
			element.hasSortOrder = true

		elseif (element.runeSortOrder == "DESC") then
			table_sort(element.runeOrder, element.SortByTimeDesc)
			element.hasSortOrder = true

		elseif (element.hasSortOrder) then
			table_sort(element.runeOrder)
			element.hasSortOrder = false
		end

		local min = 0 -- available runes
		local max = UnitPowerMax("player", element.powerID) or 0 -- maximum available runes
		local maxDisplayed = element.max or max -- maximum displayed runes

		-- Update runes
		local runeID, rune, start, duration, runeReady
		for id = 1,#element.runeOrder do
			runeID = element.runeOrder[id]
			rune = element[id]

			if (not rune) then 
				break 
			end
			
			start, duration, runeReady = GetRuneCooldown(runeID)
			if (runeReady) then
				rune:SetScript("OnUpdate", nil)
				rune:SetMinMaxValues(0, 1)
				rune:SetValue(1, true)

				-- update count of available runes
				min = min + 1

			elseif (start) then
				rune.duration = GetTime() - start
				rune:SetMinMaxValues(0, duration, true)
				rune:SetValue(0, true)
				rune:SetScript("OnUpdate", element.OnUpdateRune)

			end
		end

		-- Make sure the runes are shown
		for i = 1, maxDisplayed do 
			local rune = element[i]
			if not rune:IsShown() then 
				rune:Show()
			end 
		end 

		-- Hide additional points in the classpower element, if any
		for i = maxDisplayed + 1, #element do 
			local rune = element[i]
			rune:SetValue(0)
			if rune:IsShown() then 
				rune:Hide()
			end 
		end 

		return min, max, element.powerType
	end, 
	UpdateColor = function(element, unit, min, max, powerType)
		local self = element._owner
		local color = self.colors.power[powerType]
		local r, g, b = color[1], color[2], color[3]
		local maxDisplayed = element.max or max

		-- Class Color Overrides
		if (element.colorClass and UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			color = class and self.colors.class[class]
			r, g, b = color[1], color[2], color[3]
		end 
		
		-- Ready ones fully opaque, charging ones toned down, everything even more without a hostile target
		if (UnitAffectingCombat("player") or UnitAffectingCombat("pet")) then 
			local chargingAlpha = element.alphaEmpty or .5
			local fullAlpha = 1
			for i = 1, maxDisplayed do
				local point = element[i]
				point:SetStatusBarColor(r, g, b)
				point:SetAlpha(i > min and chargingAlpha or fullAlpha)
				if point.bg then 
					point.bg:SetVertexColor(r*1/3, g*1/3, b*1/3)
				end 
			end

		-- All are toned down, charging/empty ones even more
		elseif (min < maxDisplayed) or (UnitExists("target") and not UnitIsFriend("player", "target")) then 
			local chargingAlpha = (element.alphaEmpty or .5)*(element.alphaNoCombatRunes or element.alphaNoCombat or .5)
			local fullAlpha = element.alphaNoCombatRunes or element.alphaNoCombat or .5
			for i = 1, maxDisplayed do
				local point = element[i]
				if point then 
					point:SetStatusBarColor(r, g, b)
					point:SetAlpha(i > min and chargingAlpha or fullAlpha)
					if point.bg then 
						point.bg:SetVertexColor(r*1/3, g*1/3, b*1/3)
					end 
				end
			end

		-- Hidden
		else
			for i = 1, maxDisplayed do
				local point = element[i]
				if point then
					point:SetStatusBarColor(r, g, b)
					point:SetAlpha(0)
				end 
			end 
		end
	end
}, Generic_MT)

ClassPower.SoulShards = setmetatable({ 
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerID = SPELL_POWER_SOUL_SHARDS
		element.powerType = "SOUL_SHARDS"
		element.maxDisplayed = element.maxComboPoints or 5
		element.isEnabled = true

		self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)

		Generic.DisablePower(self)
	end,
	UpdatePower = function(self, event, unit, ...)
		local element = self.ClassPower
		if (not element.isEnabled) then 
			element:Hide()
			return 
		end 

		local powerType = element.powerType
		local powerID = element.powerID 

		local min = UnitPower("player", powerID, true) or 0
		local max = UnitPowerMax("player", powerID) or 0
		local mod = UnitPowerDisplayMod(powerID)

		-- mod should never be 0, but according to Blizz code it can actually happen
		min = mod == 0 and 0 or min / mod

		-- BUG: Destruction is supposed to show partial soulshards, but Affliction and Demonology should only show full ones
		if (not IS_CLASSIC) and (GetSpecialization() ~= SPEC_WARLOCK_DESTRUCTION) then
			min = min - min % 1 -- because math operators are faster than functions
		end

		local numActive = min + 0.9
		local maxDisplayed = element.maxDisplayed or element.max or max
		
		for i = 1, maxDisplayed do 
			local point = element[i]
			if not point:IsShown() then 
				point:Show()
			end 
			local value = (i > numActive) and 0 or (min - i + 1)
			point:SetValue(value)
		end 

		for i = maxDisplayed+1, #element do 
			element[i]:SetValue(0)
			if element[i]:IsShown() then 
				element[i]:Hide()
			end 
		end 

		return min, max, powerType
	end
}, Generic_MT)

ClassPower.Stagger = setmetatable({ 
	EnablePower = function(self)
		local element = self.ClassPower
		element.powerType = "STAGGER"
		element.maxDisplayed = 3
		element.isEnabled = true

		self:RegisterEvent("UNIT_AURA", Proxy)

		Generic.EnablePower(self)
	end,
	DisablePower = function(self)
		self:UnregisterEvent("UNIT_AURA", Proxy)

		Generic.DisablePower(self)
	end, 
	UpdatePower = function(self, event, unit, ...)
		local element = self.ClassPower
		if (not element.isEnabled) then 
			element:Hide()
			return 
		end 

		local powerType = element.powerType
		local powerID = element.powerID 

		-- Blizzard code has nil checks for UnitStagger return
		local min = UnitStagger("player") or 0
		local max = UnitHealthMax("player") or 1
		local numPoints

		local perc = min / max
		if (perc >= STAGGER_RED_TRANSITION) then
			numPoints = 3
		elseif (perc > STAGGER_YELLOW_TRANSITION) then
			numPoints = 2
		elseif (perc > 0) then
			numPoints = 1
		else 
			numPoints = 0
		end

		local maxDisplayed = element.maxDisplayed or element.max or max

		for i = 1, maxDisplayed do 
			local point = element[i]
			if not point:IsShown() then 
				point:Show()
			end 
			point:SetValue(numPoints >= i and 1 or 0)
		end 

		for i = maxDisplayed + 1, #element do 
			element[i]:SetValue(0)
			if element[i]:IsShown() then 
				element[i]:Hide()
			end 
		end 		

		return min, max, powerType
	end,
	UpdateColor = function(element, unit, min, max, powerType)
		local self = element._owner

		local perc = min / max
		local color
		if (perc >= STAGGER_RED_TRANSITION) then
			color = self.colors.power[powerType][STAGGER_RED_INDEX]
		elseif (perc > STAGGER_YELLOW_TRANSITION) then
			color = self.colors.power[powerType][STAGGER_YELLOW_INDEX]
		else
			color = self.colors.power[powerType][STAGGER_GREEN_INDEX]
		end

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

	local spec = (not IS_CLASSIC) and GetSpecialization()
	local level = UnitLevel("player")

	if (event == "PLAYER_LEVEL_UP") then 
		level = ...
		if ((PLAYERCLASS == "PALADIN") and (level >= PALADINPOWERBAR_SHOW_LEVEL)) or (PLAYERCLASS == "WARLOCK") and (level >= SHARDBAR_SHOW_LEVEL) then
			self:UnregisterEvent("PLAYER_LEVEL_UP", Proxy)
		end 

	elseif (event == "UPDATE_POSSESS_BAR") then 
		element.hasPossessBar = IsPossessBarVisible()

	elseif (event == "UPDATE_OVERRIDE_ACTIONBAR") then 
		element.hasOverrideBar = HasOverrideActionBar() or HasTempShapeshiftActionBar() 

	elseif (event == "UNIT_ENTERING_VEHICLE") 
	or (event == "UNIT_ENTERED_VEHICLE") 
	or (event == "UNIT_EXITING_VEHICLE") 
	or (event == "UNIT_EXITED_VEHICLE") then 
		element.inVehicle = UnitInVehicle("player")
		element.hasVehicleUI = UnitHasVehiclePlayerFrameUI("player")
	end 

	local newType 
	if (element.hasPossessBar or element.hasOverrideBar) or (element.inVehicle and (not element.hasVehicleUI)) then 
		newType = "None"
	elseif (element.hasVehicleUI) and (not element.ignoreComboPoints) then 
		newType = "ComboPoints"
	elseif (PLAYERCLASS == "DEATHKNIGHT") and (not element.ignoreRunes) then 
		newType = "Runes"
	elseif (PLAYERCLASS == "DRUID") and (not element.ignoreComboPoints) then 
		newType = "ComboPoints"
	elseif (PLAYERCLASS == "MAGE") and (spec == SPEC_MAGE_ARCANE) and (not element.ignoreArcaneCharges) then 
		newType = "ArcaneCharges"
	elseif (PLAYERCLASS == "MONK") and (spec == SPEC_MONK_WINDWALKER) and (not element.ignoreChi)then 
		newType = "Chi"
	elseif (PLAYERCLASS == "MONK") and (spec == SPEC_MONK_BREWMASTER) and (not element.ignoreStagger)then 
		newType = "Stagger"
	elseif ((PLAYERCLASS == "PALADIN") and (spec == SPEC_PALADIN_RETRIBUTION) and (level >= PALADINPOWERBAR_SHOW_LEVEL)) and (not element.ignoreHolyPower)then
		newType = "HolyPower"
	elseif (PLAYERCLASS == "ROGUE") and (not element.ignoreComboPoints) then 
		newType = "ComboPoints"
	elseif ((PLAYERCLASS == "WARLOCK") and (level >= SHARDBAR_SHOW_LEVEL)) and (not element.ignoreSoulShards) then 
		newType = "SoulShards"
	elseif (not element.ignoreComboPoints) then 
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

		local level = UnitLevel("player")
		if ((PLAYERCLASS == "PALADIN") and (level < PALADINPOWERBAR_SHOW_LEVEL)) or (PLAYERCLASS == "WARLOCK") and (level < SHARDBAR_SHOW_LEVEL) then
			self:RegisterEvent("PLAYER_LEVEL_UP", Proxy, true)
		end  

		if (not IS_CLASSIC) then 

			-- We'll handle spec specific powers from here, 
			-- but will leave level checking to the sub-elements.
			if (PLAYERCLASS == "MONK") or (PLAYERCLASS == "MAGE") or (PLAYERCLASS == "PALADIN") then 
				self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy, true) 
			end 

			self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", Proxy, true)
			self:RegisterEvent("UPDATE_POSSESS_BAR", Proxy, true)

			-- All must check for vehicles
			-- *Also of importance that none 
			-- of the powerTypes remove this event.
			self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)
			self:RegisterEvent("UNIT_ENTERING_VEHICLE", Proxy)
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", Proxy)
			self:RegisterEvent("UNIT_EXITING_VEHICLE", Proxy)
			self:RegisterEvent("UNIT_EXITED_VEHICLE", Proxy)
		end 

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
		self:UnregisterEvent("PLAYER_LEVEL_UP", Proxy)
		--self:UnregisterEvent("PLAYER_TARGET_CHANGED", Proxy)

		if (not IS_CLASSIC) then 
			self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy)
			self:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR", Proxy)
			self:UnregisterEvent("UPDATE_POSSESS_BAR", Proxy)
			self:UnregisterEvent("UNIT_ENTERING_VEHICLE", Proxy)
			self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Proxy)
			self:UnregisterEvent("UNIT_EXITING_VEHICLE", Proxy)
			self:UnregisterEvent("UNIT_EXITED_VEHICLE", Proxy)
		end 
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("ClassPower", Enable, Disable, Proxy, 29)
end 
