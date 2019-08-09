local LibPlayerData = CogWheel:Set("LibPlayerData", 6)
if (not LibPlayerData) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetExpansionLevel = _G.GetExpansionLevel
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitClass = _G.UnitClass
local UnitLevel = _G.UnitLevel

-- Library registries
LibPlayerData.embeds = LibPlayerData.embeds or {}
LibPlayerData.frame = LibPlayerData.frame or CreateFrame("Frame")

-- Constant to track current player role
local CURRENT_ROLE

-- Specific per class buffs we wish to see
local _,playerClass = UnitClass("player")

-- List of damage-only classes
local classIsDamage = { 
	HUNTER = true, 
	MAGE = true, 
	ROGUE = true, 
	WARLOCK = true 
}

-- List of classes that can tank
local classCanTank = { 
	DEATHKNIGHT = true, 
	DRUID = true, 
	MONK = true, 
	PALADIN = true, 
	WARRIOR = true 
}

-- Setup our frame for tracking role events
if classIsDamage[playerClass] then
	CURRENT_ROLE = "DAMAGER"
	LibPlayerData.frame:SetScript("OnEvent", nil)
	LibPlayerData.frame:UnregisterAllEvents()
else
	CURRENT_ROLE = classCanTank[playerClass] and "TANK" or "DAMAGER"
end 

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Returns the maximum level the account has access to 
LibPlayerData.GetEffectivePlayerMaxLevel = function() return 60 end

-- Returns the maximum level in the current expansion 
LibPlayerData.GetEffectiveExpansionMaxLevel = function() return 60 end

-- Is the provided level at the account's maximum level?
LibPlayerData.IsUnitLevelAtEffectiveMaxLevel = function() return 60 end

-- Is the provided level at the expansions's maximum level?
LibPlayerData.IsUnitLevelAtEffectiveExpansionMaxLevel = function() return 60 end

-- Is the player at the account's maximum level?
LibPlayerData.IsPlayerAtEffectiveMaxLevel = function() return 60 end

-- Is the player at the expansions's maximum level?
LibPlayerData.IsPlayerAtEffectiveExpansionMaxLevel = function() return 60 end

-- Return whether the player currently can gain XP
LibPlayerData.PlayerHasXP = function() return (UnitLevel("player") < 60) end

-- Returns whether the player is  tracking a reputation
LibPlayerData.PlayerHasRep = function()
	return false 
end

LibPlayerData.PlayerCanTank = function()
	return classCanTank[playerClass]
end

LibPlayerData.PlayerIsDamageOnly = function()
	return classIsDamage[playerClass]
end

LibPlayerData.GetPlayerRole = function()
	return CURRENT_ROLE
end

local embedMethods = {
	GetPlayerRole = true, 
	GetEffectivePlayerMaxLevel = true, 
	GetEffectiveExpansionMaxLevel = true, 
	IsPlayerAtEffectiveMaxLevel = true, 
	IsPlayerAtEffectiveExpansionMaxLevel = true, 
	IsUnitLevelAtEffectiveMaxLevel = true, 
	IsUnitLevelAtEffectiveExpansionMaxLevel = true, 
	PlayerHasXP = true, 
	PlayerHasRep = true, 
	PlayerCanTank = true, 
	PlayerIsDamageOnly = true
}

LibPlayerData.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	LibPlayerData.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibPlayerData.embeds) do
	LibPlayerData:Embed(target)
end
