local LibAura = CogWheel:Set("LibAura", 6)
if (not LibAura) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibAura requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibAura requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibAura requires LibFrame to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibAura)
LibEvent:Embed(LibAura)
LibFrame:Embed(LibAura)

-- Lua API
local _G = _G
local assert = assert
local bit_band = bit.band
local bit_bor = bit.bor
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_gsub = string.gsub
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API
local UnitAura = _G.UnitAura

-- WoW Constants
local BUFF_MAX_DISPLAY = _G.BUFF_MAX_DISPLAY
local DEBUFF_MAX_DISPLAY = _G.DEBUFF_MAX_DISPLAY 

-- Library registries
LibAura.embeds = LibAura.embeds or {}
LibAura.auraWatches = LibAura.auraWatches or {} -- currently tracked units
LibAura.auras = LibAura.auras or {} -- static aura flag cache
LibAura.cache = LibAura.cache or {} -- current unit aura cache
LibAura.infoFlags = LibAura.infoFlags or {} -- static info flags about the auras
LibAura.userFlags = LibAura.userFlags or {} -- added user flags about the auras
LibAura.frame = LibAura.frame or LibAura:CreateFrame("Frame") -- frame tracking events and updates

-- Shortcuts
local Units = LibAura.auraWatches
local Auras = LibAura.auras
local Cache = LibAura.cache
local InfoFlags = LibAura.infoFlags
local UserFlags = LibAura.userFlags

-- Utility Functions
--------------------------------------------------------------------------
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

-- Utility function to parse and order a filter, 
-- to make sure we avoid duplicate caches. 
local parseFilter = function(filter)
	
	-- speed it up for default situations
	if ((not filter) or (filter == "")) then 
		return "HELPFUL"
	end

	-- parse the string, ignore separator types and order
	local harmful = string_match(filter, "HARMFUL")
	local helpful = string_match(filter, "HELPFUL")
	local player = string_match(filter, "PLAYER") -- auras that were applied by the player
	local raid = string_match(filter, "RAID") -- auras that can be applied (if HELPFUL) or dispelled (if HARMFUL) by the player
	local cancelable = string_match(filter, "CANCELABLE") -- buffs that can be removed (such as by right-clicking or using the /cancelaura command)
	local not_cancelable = string_match(filter, "NOT_CANCELABLE") -- buffs that cannot be removed

	-- return a nil value for invalid filters. 
	-- *this might cause an error, but that is the intention.
	if (harmful and helpful) or (cancelable and not_cancelable) then 
		return 
	end

	-- always include these, as we're always using UnitAura() to retrieve buffs/debuffs.
	local parsedFilter
	if (harmful) then 
		parsedFilter = "HARMFUL"
	else 
		parsedFilter = "HELPFUL" -- default when no help/harm is mentioned
	end 

	-- return a parsed filter with arguments separated by spaces, and in our preferred order
	return parsedFilter .. (player and " PLAYER" or "") 
						.. (raid and " RAID" or "") 
						.. (cancelable and " CANCELABLE" or "") 
						.. (not_cancelable and " NOT_CANCELABLE" or "") 
end 

-- Aura tracking frame and event handling
--------------------------------------------------------------------------
local Frame = LibAura.frame
local Frame_MT = { __index = Frame }

-- Methods we don't wish to expose to the modules
local IsEventRegistered = Frame_MT.__index.IsEventRegistered
local RegisterEvent = Frame_MT.__index.RegisterEvent
local RegisterUnitEvent = Frame_MT.__index.RegisterUnitEvent
local UnregisterEvent = Frame_MT.__index.UnregisterEvent
local UnregisterAllEvents = Frame_MT.__index.UnregisterAllEvents

Frame.OnEvent = function(self, event, unit, ...)

	-- don't bother caching up anything we haven't got a registered aurawatch or cache for
	if (not Units[unit]) then 
		return 
	end 

	-- retrieve the unit's aura cache, bail out if none has been queried before
	local cache = Cache[unit]
	if (not cache) then 
		return 
	end 

	-- refresh all the registered filters
	for filter in pairs(cache) do 
		LibAura:CacheUnitAurasByFilter(unit, filter)
	end 

	-- Send a message to anybody listening
	LibAura:SendMessage("CG_UNIT_AURA", unit)
end

LibAura.CacheUnitBuffsByFilter = function(self, unit, filter)
	return self:CacheUnitAurasByFilter(unit, "HELPFUL" .. (filter or ""))
end 

LibAura.CacheUnitDebuffsByFilter = function(self, unit, filter)
	return self:CacheUnitAurasByFilter(unit, "HARMFUL" .. (filter or ""))
end 

LibAura.CacheUnitAurasByFilter = function(self, unit, filter)
	-- Parse the provided or create a default filter
	local filter = parseFilter(filter)
	if (not filter) then 
		return -- don't cache invalid filters
	end

	-- Enable the aura watch for this unit and filter if it hasn't been already
	-- This also creates the relevant tables for us. 
	if (not Units[unit]) or (not Cache[unit][filter]) then 
		LibAura:RegisterAuraWatch(unit, filter)
	end 

	-- Retrieve the aura cache for this unit and filter
	local cache = Cache[unit][filter]

	-- Clear info flags from the cache

	local counter, limit = 0, string_match(filter, "HARMFUL") and DEBUFF_MAX_DISPLAY or BUFF_MAX_DISPLAY
	for i = 1,limit do 

		-- Retrieve buff information
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitAura(unit, i, filter)

		-- No name means no more buffs matching the filter
		if (not name) then
			break
		end

		-- Cache up the values for the aura index.
		-- *Only ever replace the whole table on its initial creation, 
		-- always reuse the existing ones at all other times. 
		-- This can fire A LOT in battlegrounds, so this is needed for performance and memory. 
		if (cache[i]) then 
			cache[i][1], 
			cache[i][2], 
			cache[i][3], 
			cache[i][4], 
			cache[i][5], 
			cache[i][6], 
			cache[i][7], 
			cache[i][8], 
			cache[i][9], 
			cache[i][10], 
			cache[i][11], 
			cache[i][12], 
			cache[i][13], 
			cache[i][14], 
			cache[i][15], 
			cache[i][16], 
			cache[i][17], 
			cache[i][18] = name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3
		else 
			cache[i] = { name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 }
		end 

		counter = counter + 1
	end 

	-- Clear out old, if any
	local numAuras = #cache
	if (numAuras > counter) then 
		for i = counter+1,numAuras do 
			for j = 1,#cache[i] do 
				cache[i][j] = nil
			end 
		end
	end
	
	-- return cache and aura count for this filter and unit
	return cache, counter
end

-- retrieve a cached filtered aura list for the given unit
LibAura.GetUnitAuraCacheByFilter = function(self, unit, filter)
	return Cache[unit] and Cache[unit][filter] or LibAura:CacheUnitAurasByFilter(unit, filter)
end

LibAura.GetUnitBuffCacheByFilter = function(self, unit, filter)
	local realFilter = "HELPFUL" .. (filter or "")
	return Cache[unit] and Cache[unit][realFilter] or LibAura:CacheUnitAurasByFilter(unit, realFilter)
end

LibAura.GetUnitDebuffCacheByFilter = function(self, unit, filter)
	local realFilter = "HARMFUL" .. (filter or "")
	return Cache[unit] and Cache[unit][realFilter] or LibAura:CacheUnitAurasByFilter(unit, realFilter)
end

LibAura.GetUnitAura = function(self, unit, auraID, filter)
	local cache = self:GetUnitAuraCacheByFilter(unit, filter)
	local aura = cache and cache[auraID]
	if aura then 
		return aura[1], aura[2], aura[3], aura[4], aura[5], aura[6], aura[7], aura[8], aura[9], aura[10], aura[11], aura[12], aura[13], aura[14], aura[15], aura[16], aura[17], aura[18]
	end 
end

LibAura.GetUnitBuff = function(self, unit, auraID, filter)
	local cache = self:GetUnitBuffCacheByFilter(unit, filter)
	local aura = cache and cache[auraID]
	if aura then 
		return aura[1], aura[2], aura[3], aura[4], aura[5], aura[6], aura[7], aura[8], aura[9], aura[10], aura[11], aura[12], aura[13], aura[14], aura[15], aura[16], aura[17], aura[18]
	end 
end

LibAura.GetUnitDebuff = function(self, unit, auraID, filter)
	local cache = self:GetUnitDebuffCacheByFilter(unit, filter)
	local aura = cache and cache[auraID]
	if aura then 
		return aura[1], aura[2], aura[3], aura[4], aura[5], aura[6], aura[7], aura[8], aura[9], aura[10], aura[11], aura[12], aura[13], aura[14], aura[15], aura[16], aura[17], aura[18]
	end 
end

LibAura.RegisterAuraWatch = function(self, unit, filter)
	check(unit, 1, "string")

	-- set the tracking flag for this unit
	Units[unit] = true

	-- create the relevant tables
	-- this is needed for the event handler to respond 
	-- to blizz events and cache up the relevant auras.
	if (not Cache[unit]) then 
		Cache[unit] = {}
	end 
	if (not Cache[unit][filter]) then 
		Cache[unit][filter] = {}
	end 

	-- register the main event with our event frame, if it hasn't been already
	if (not IsEventRegistered(Frame, "UNIT_AURA")) then
		RegisterEvent(Frame, "UNIT_AURA")
	end
end

LibAura.UnregisterAuraWatch = function(self, unit, filter)
	check(unit, 1, "string")

	-- clear the tracking flag for this unit
	Units[unit] = false

	-- check if anything is still tracked
	for unit,tracked in pairs(Units) do 
		if (tracked) then 
			return 
		end 
	end 

	-- if we made it this far, we're not tracking anything
	UnregisterEvent(Frame, "UNIT_AURA")
end

--------------------------------------------------------------------------
-- InfoFlag queries
--------------------------------------------------------------------------
-- Not a fan of this in the slightest, 
-- but for purposes of speed we need to hand this table out to the modules. 
-- and in case of library updates we need this table to be the same,
LibAura.GetAllAuraInfoFlags = function(self)
	return Auras
end

-- Return the hashed info flag table, 
-- to allow easy usage of keywords in the modules.
-- We will have make sure the keywords remain consistent.  
LibAura.GetAllAuraInfoBitFilters = function(self)
	return InfoFlags
end

-- Check if the provided info flags are set for the aura
LibAura.HasAuraInfoFlags = function(self, spellID, flags)
	-- Not verifying input types as we don't want the extra function calls on 
	-- something that might be called multiple times each second. 
	return Auras[spellID] and (bit_band(Auras[spellID], flags) ~= 0)
end

-- Retrieve the current info flags for the aura, or nil if none are set
LibAura.GetAuraInfoFlags = function(self, spellID)
	-- Not verifying input types as we don't want the extra function calls on 
	-- something that might be called multiple times each second. 
	return Auras[spellID]
end

--------------------------------------------------------------------------
-- UserFlags
-- The flags set here are registered per module, 
-- and are to be used for the front-end's own purposes, 
-- whether that be display preference, blacklists, whitelists, etc. 
-- Nothing here is global, and all is separate from the InfoFlags.
--------------------------------------------------------------------------
-- Adds a custom aura flag
LibAura.AddAuraUserFlags = function(self, spellID, flags)
	check(spellID, 1, "number")
	check(flags, 2, "number")
	if (not UserFlags[self]) then 
		UserFlags[self] = {}
	end 
	if (not UserFlags[self][spellID]) then 
		UserFlags[self][spellID] = flags
		return 
	end 
	UserFlags[self][spellID] = bit_bor(UserFlags[self][spellID], flags)
end 

-- Retrieve the current set flags for the aura, or nil if none are set
LibAura.GetAuraUserFlags = function(self, spellID)
	-- Not verifying input types as we don't want the extra function calls on 
	-- something that might be called multiple times each second. 
	if (not UserFlags[self]) or (not UserFlags[self][spellID]) then 
		return 
	end 
	return UserFlags[self][spellID]
end

-- Return the full user flag table for the module
LibAura.GetAllAuraUserFlags = function(self)
	return UserFlags[self]
end

-- Check if the provided user flags are set for the aura
LibAura.HasAuraUserFlags = function(self, spellID, flags)
	-- Not verifying input types as we don't want the extra function calls on 
	-- something that might be called multiple times each second. 
	if (not UserFlags[self]) or (not UserFlags[self][spellID]) then 
		return 
	end 
	return (bit_band(UserFlags[self][spellID], flags) ~= 0)
end

-- Remove a set of user flags, or all if no removalFlags are provided.
LibAura.RemoveAuraUserFlags = function(self, spellID, removalFlags)
	check(spellID, 1, "number")
	check(removalFlags, 2, "number", "nil")
	if (not UserFlags[self]) or (not UserFlags[self][spellID]) then 
		return 
	end 
	local userFlags = UserFlags[self][spellID]
	if removalFlags  then 
		local changed
		for i = 1,64 do -- bit.bits ? 
			local bit = (i-1)^2 -- create a mask 
			local userFlagsHasBit = bit_band(userFlags, bit) -- see if the user filter has the bit set
			local removalFlagsHasBit = bit_band(removalFlags, bit) -- see if the removal flags has the bit set
			if (userFlagsHasBit and removalFlagsHasBit) then 
				userFlags = userFlags - bit -- just simply deduct the masked bit value if it was set
				changed = true 
			end 
		end 
		if (changed) then 
			UserFlags[self][spellID] = userFlags
		end 
	else 
		UserFlags[self][spellID] = nil
	end 
end 

local embedMethods = {
	CacheUnitAurasByFilter = true,
	CacheUnitBuffsByFilter = true,
	CacheUnitDebuffsByFilter = true,
	GetUnitAura = true,
	GetUnitBuff = true,
	GetUnitDebuff = true,
	GetUnitAuraCacheByFilter = true,
	GetUnitBuffCacheByFilter = true, 
	GetUnitDebuffCacheByFilter = true, 
	RegisterAuraWatch = true,
	UnregisterAuraWatch = true,
	GetAllAuraInfoFlags = true, 
	GetAllAuraUserFlags = true, 
	GetAllAuraInfoBitFilters = true, 
	GetAuraInfoFlags = true, 
	HasAuraInfoFlags = true, 
	AddAuraUserFlags = true,
	GetAuraUserFlags = true,
	HasAuraUserFlags = true, 
	RemoveAuraUserFlags = true
}

LibAura.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibAura.embeds) do
	LibAura:Embed(target)
end

-- Important. Doh. 
Frame:UnregisterAllEvents()
Frame:SetScript("OnEvent", Frame.OnEvent)

--------------------------------------------------------------------------
-- InfoFlags
-- The flags in this DB should only describe factual properties 
-- of the auras like type of spell, what class it belongs to, etc. 
--------------------------------------------------------------------------

local IsPlayerSpell 	= tonumber("0000000000000000000000000000000000000000000000000000000000000001", 2) 
local IsRacialSpell 	= tonumber("0000000000000000000000000000000000000000000000000000000000000010", 2) 

-- 2nd return value from UnitClass(unit)
local DEATHKNIGHT 		= tonumber("0000000000000000000000000000000000000000000000000000000000000100", 2) 
local DEMONHUNTER 		= tonumber("0000000000000000000000000000000000000000000000000000000000001000", 2) 
local DRUID 			= tonumber("0000000000000000000000000000000000000000000000000000000000010000", 2) 
local HUNTER 			= tonumber("0000000000000000000000000000000000000000000000000000000000100000", 2) 
local MAGE 				= tonumber("0000000000000000000000000000000000000000000000000000000001000000", 2) 
local MONK 				= tonumber("0000000000000000000000000000000000000000000000000000000010000000", 2) 
local PALADIN 			= tonumber("0000000000000000000000000000000000000000000000000000000100000000", 2) 
local PRIEST 			= tonumber("0000000000000000000000000000000000000000000000000000001000000000", 2) 
local ROGUE 			= tonumber("0000000000000000000000000000000000000000000000000000010000000000", 2) 
local SHAMAN 			= tonumber("0000000000000000000000000000000000000000000000000000100000000000", 2) 
local WARLOCK 			= tonumber("0000000000000000000000000000000000000000000000000001000000000000", 2) 
local WARRIOR 			= tonumber("0000000000000000000000000000000000000000000000000010000000000000", 2) 

-- 2nd return value from UnitRace(unit)
local BloodElf 			= tonumber("0000000000000000000000000000000000000000000000000100000000000000", 2) 
local Draenei 			= tonumber("0000000000000000000000000000000000000000000000001000000000000000", 2) 
local Dwarf 			= tonumber("0000000000000000000000000000000000000000000000010000000000000000", 2) 
local NightElf 			= tonumber("0000000000000000000000000000000000000000000000100000000000000000", 2) 
local Orc 				= tonumber("0000000000000000000000000000000000000000000001000000000000000000", 2) 
local Pandaren 			= tonumber("0000000000000000000000000000000000000000000010000000000000000000", 2) 
local Scourge 			= tonumber("0000000000000000000000000000000000000000000100000000000000000000", 2) 
local Tauren 			= tonumber("0000000000000000000000000000000000000000001000000000000000000000", 2) 
local Troll 			= tonumber("0000000000000000000000000000000000000000010000000000000000000000", 2) 
local Worgen 			= tonumber("0000000000000000000000000000000000000000100000000000000000000000", 2) 

local IsCrowdControl 	= tonumber("0000000000000000000000000000000000000001000000000000000000000000", 2) 
local IsRoot 			= tonumber("0000000000000000000000000000000000000010000000000000000000000000", 2) 
local IsSnare 			= tonumber("0000000000000000000000000000000000000100000000000000000000000000", 2) 
local IsSilence 		= tonumber("0000000000000000000000000000000000001000000000000000000000000000", 2) 
local IsStun 			= tonumber("0000000000000000000000000000000000010000000000000000000000000000", 2) 
local IsImmune			= tonumber("0000000000000000000000000000000000100000000000000000000000000000", 2) 
local IsImmuneSpell 	= tonumber("0000000000000000000000000000000001000000000000000000000000000000", 2) 
local IsImmunePhysical 	= tonumber("0000000000000000000000000000000010000000000000000000000000000000", 2) 
local IsDisarm 			= tonumber("0000000000000000000000000000000100000000000000000000000000000000", 2) 

local IsFood 			= tonumber("0000000000000000000000000000001000000000000000000000000000000000", 2)
local IsFlask 			= tonumber("0000000000000000000000000000010000000000000000000000000000000000", 2) 
local IsRune 			= tonumber("0000000000000000000000000000100000000000000000000000000000000000", 2) 

InfoFlags.IsPlayerSpell = IsPlayerSpell
InfoFlags.IsRacialSpell = IsRacialSpell

InfoFlags.DEATHKNIGHT = DEATHKNIGHT
InfoFlags.DEMONHUNTER = DEMONHUNTER
InfoFlags.DRUID = DRUID
InfoFlags.HUNTER = HUNTER
InfoFlags.MAGE = MAGE
InfoFlags.MONK = MONK
InfoFlags.PALADIN = PALADIN
InfoFlags.PRIEST = PRIEST
InfoFlags.ROGUE = ROGUE
InfoFlags.SHAMAN = SHAMAN
InfoFlags.WARLOCK = WARLOCK
InfoFlags.WARRIOR = WARRIOR

InfoFlags.BloodElf = BloodElf
InfoFlags.Draenei = Draenei
InfoFlags.Dwarf = Dwarf
InfoFlags.NightElf = NightElf
InfoFlags.Orc = Orc
InfoFlags.Pandaren = Pandaren
InfoFlags.Scourge = Scourge
InfoFlags.Tauren = Tauren
InfoFlags.Troll = Troll
InfoFlags.Worgen = Worgen

InfoFlags.IsCrowdControl = IsCrowdControl
InfoFlags.IsRoot = IsRoot
InfoFlags.IsSnare = IsSnare
InfoFlags.IsSilence = IsSilence
InfoFlags.IsStun = IsStun
InfoFlags.IsImmune = IsImmune
InfoFlags.IsImmuneSpell = IsImmuneSpell
InfoFlags.IsImmunePhysical = IsImmunePhysical
InfoFlags.IsDisarm = IsDisarm
InfoFlags.IsFood = IsFood
InfoFlags.IsFlask = IsFlask
InfoFlags.IsRune = IsRune

-- For convenience farther down the list here
local IsDeathKnight = IsPlayerSpell + DEATHKNIGHT
local IsDemonHunter = IsPlayerSpell + DEMONHUNTER
local IsDruid = IsPlayerSpell + DRUID
local IsHunter = IsPlayerSpell + HUNTER
local IsMage = IsPlayerSpell + MAGE
local IsMonk = IsPlayerSpell + MONK
local IsPaladin = IsPlayerSpell + PALADIN
local IsPriest = IsPlayerSpell + PRIEST
local IsRogue = IsPlayerSpell + ROGUE
local IsShaman = IsPlayerSpell + SHAMAN
local IsWarlock = IsPlayerSpell + WARLOCK
local IsWarrior = IsPlayerSpell + WARRIOR

local IsBloodElf = IsRacialSpell + BloodElf
local IsDraenei = IsRacialSpell + Draenei
local IsDwarf = IsRacialSpell + Dwarf
local IsNightElf = IsRacialSpell + NightElf
local IsOrc = IsRacialSpell + Orc
local IsPandaren = IsRacialSpell + Pandaren
local IsScourge = IsRacialSpell + Scourge
local IsTauren = IsRacialSpell + Tauren
local IsTroll = IsRacialSpell + Troll
local IsWorgen = IsRacialSpell + Worgen

-- RegEx used to convert the database;
-- 	Search: Cache\[([\d\s]+)\](.*?)= (.*?) (\-\-?)(.*?)(\n)
-- 	Replace: AddFlags($1, $3) $4$5$6

-- Add flags to or create the cache entry
-- This is to avoid duplicate entries removing flags
local AddFlags = function(spellID, flags)
	if (not Auras[spellID]) then 
		Auras[spellID] = flags
		return 
	end 
	Auras[spellID] = bit_bor(Auras[spellID], flags)
end

------------------------------------------------------------------------
------------------------------------------------------------------------
---- 					CROWD CONTROL: CLASSES
------------------------------------------------------------------------
------------------------------------------------------------------------

-- Demonhunter
do 
	AddFlags(179057, IsDemonHunter + IsCrowdControl) -- Chaos Nova
	AddFlags(205630, IsDemonHunter + IsCrowdControl) -- Illidan's Grasp
	AddFlags(208618, IsDemonHunter + IsCrowdControl + IsStun) -- Illidan's Grasp (throw stun)
	AddFlags(217832, IsDemonHunter + IsCrowdControl) -- Imprison
	AddFlags(221527, IsDemonHunter + IsCrowdControl) -- Imprison (pvp talent)
	AddFlags(204843, IsDemonHunter + IsCrowdControl + IsSnare) -- Sigil of Chains
	AddFlags(207685, IsDemonHunter + IsCrowdControl) -- Sigil of Misery
	AddFlags(204490, IsDemonHunter + IsCrowdControl + IsSilence) -- Sigil of Silence
	AddFlags(211881, IsDemonHunter + IsCrowdControl) -- Fel Eruption
	AddFlags(200166, IsDemonHunter + IsCrowdControl + IsStun) -- Metamorfosis stun
	AddFlags(247121, IsDemonHunter + IsCrowdControl + IsSnare) -- Metamorfosis snare
	AddFlags(196555, IsDemonHunter + IsCrowdControl + IsImmune) -- Netherwalk
	AddFlags(213491, IsDemonHunter + IsCrowdControl + IsStun) -- Demonic Trample Stun
	AddFlags(206649, IsDemonHunter + IsCrowdControl + IsSilence) -- Eye of Leotheras (no silence, 4% dmg and duration reset for spell casted)
	AddFlags(232538, IsDemonHunter + IsCrowdControl + IsSnare) -- Rain of Chaos
	AddFlags(213405, IsDemonHunter + IsCrowdControl + IsSnare) -- Master of the Glaive
	AddFlags(210003, IsDemonHunter + IsCrowdControl + IsSnare) -- Razor Spikes
	AddFlags(198813, IsDemonHunter + IsCrowdControl + IsSnare) -- Vengeful Retreat
end 

-- Death Knight
do
	AddFlags(108194, IsDeathKnight + IsCrowdControl) -- Asphyxiate
	AddFlags(221562, IsDeathKnight + IsCrowdControl) -- Asphyxiate
	AddFlags( 47476, IsDeathKnight + IsCrowdControl + IsSilence) -- Strangulate
	AddFlags( 96294, IsDeathKnight + IsCrowdControl + IsRoot) -- Chains of Ice (Chilblains)
	AddFlags( 45524, IsDeathKnight + IsCrowdControl + IsSnare) -- Chains of Ice
	AddFlags(115018, IsDeathKnight + IsCrowdControl) -- Desecrated Ground (Immune to CC)
	AddFlags(207319, IsDeathKnight + IsCrowdControl + IsImmune) -- Corpse Shield (not immune, 90% damage redirected to pet)
	AddFlags( 48707, IsDeathKnight + IsCrowdControl + IsImmuneSpell) -- Anti-Magic Shell
	AddFlags( 48792, IsDeathKnight + IsCrowdControl) -- Icebound Fortitude
	AddFlags( 49039, IsDeathKnight + IsCrowdControl) -- Lichborne
	AddFlags( 51271, IsDeathKnight + IsCrowdControl) -- Pillar of Frost
	AddFlags(207167, IsDeathKnight + IsCrowdControl) -- Blinding Sleet
	AddFlags(207165, IsDeathKnight + IsCrowdControl) -- Abomination's Might
	AddFlags(207171, IsDeathKnight + IsCrowdControl + IsRoot) -- Winter is Coming
	AddFlags(210141, IsDeathKnight + IsCrowdControl) -- Zombie Explosion (Reanimation PvP Talent)
	AddFlags(206961, IsDeathKnight + IsCrowdControl) -- Tremble Before Me
	AddFlags(248406, IsDeathKnight + IsCrowdControl) -- Cold Heart (legendary)
	AddFlags(233395, IsDeathKnight + IsCrowdControl + IsRoot) -- Frozen Center (pvp talent)
	AddFlags(204085, IsDeathKnight + IsCrowdControl + IsRoot) -- Deathchill (pvp talent)
	AddFlags(206930, IsDeathKnight + IsCrowdControl + IsSnare) -- Heart Strike
	AddFlags(228645, IsDeathKnight + IsCrowdControl + IsSnare) -- Heart Strike
	AddFlags(211831, IsDeathKnight + IsCrowdControl + IsSnare) -- Abomination's Might (slow)
	AddFlags(200646, IsDeathKnight + IsCrowdControl + IsSnare) -- Unholy Mutation
	AddFlags(143375, IsDeathKnight + IsCrowdControl + IsSnare) -- Tightening Grasp
	AddFlags(211793, IsDeathKnight + IsCrowdControl + IsSnare) -- Remorseless Winter
	AddFlags(208278, IsDeathKnight + IsCrowdControl + IsSnare) -- Debilitating Infestation
	AddFlags(212764, IsDeathKnight + IsCrowdControl + IsSnare) -- White Walker
	AddFlags(190780, IsDeathKnight + IsCrowdControl + IsSnare) -- Frost Breath (Sindragosa's Fury) (artifact trait)
	AddFlags(191719, IsDeathKnight + IsCrowdControl + IsSnare) -- Gravitational Pull (artifact trait)
	AddFlags(204206, IsDeathKnight + IsCrowdControl + IsSnare) -- Chill Streak (pvp honor talent)
end 

-- Death Knight Ghoul
do 
	AddFlags(212332, IsDeathKnight + IsCrowdControl) -- Smash
	AddFlags(212336, IsDeathKnight + IsCrowdControl) -- Smash
	AddFlags(212337, IsDeathKnight + IsCrowdControl) -- Powerful Smash
	AddFlags( 47481, IsDeathKnight + IsCrowdControl) -- Gnaw
	AddFlags( 91800, IsDeathKnight + IsCrowdControl) -- Gnaw
	AddFlags( 91797, IsDeathKnight + IsCrowdControl) -- Monstrous Blow (Dark Transformation)
	AddFlags( 91807, IsDeathKnight + IsCrowdControl + IsRoot) -- Shambling Rush (Dark Transformation)
	AddFlags(212540, IsDeathKnight + IsCrowdControl + IsRoot) -- Flesh Hook (Abomination)
end 

-- Druid
do 
	AddFlags( 33786, IsDruid + IsCrowdControl) -- Cyclone
	AddFlags(209753, IsDruid + IsCrowdControl) -- Cyclone
	AddFlags(    99, IsDruid + IsCrowdControl) -- Incapacitating Roar
	AddFlags(236748, IsDruid + IsCrowdControl) -- Intimidating Roar
	AddFlags(163505, IsDruid + IsCrowdControl) -- Rake
	AddFlags( 22570, IsDruid + IsCrowdControl + IsStun) -- Maim
	AddFlags(203123, IsDruid + IsCrowdControl + IsStun) -- Maim
	AddFlags(203126, IsDruid + IsCrowdControl + IsStun) -- Maim (pvp honor talent)
	AddFlags(236025, IsDruid + IsCrowdControl + IsStun) -- Enraged Maim (pvp honor talent)
	AddFlags(  5211, IsDruid + IsCrowdControl + IsStun) -- Mighty Bash
	AddFlags( 81261, IsDruid + IsCrowdControl + IsSilence) -- Solar Beam
	AddFlags(   339, IsDruid + IsCrowdControl + IsRoot) -- Entangling Roots
	AddFlags(235963, IsDruid + IsCrowdControl + IsRoot) -- Entangling Roots (Earthen Grasp - feral pvp talent, -80% hit chance)
	AddFlags( 45334, IsDruid + IsCrowdControl + IsRoot) -- Immobilized (Wild Charge - Bear)
	AddFlags(102359, IsDruid + IsCrowdControl + IsRoot) -- Mass Entanglement
	AddFlags( 50259, IsDruid + IsCrowdControl + IsSnare) -- Dazed (Wild Charge - Cat)
	AddFlags( 58180, IsDruid + IsCrowdControl + IsSnare) -- Infected Wounds
	AddFlags( 61391, IsDruid + IsCrowdControl + IsSnare) -- Typhoon
	AddFlags(127797, IsDruid + IsCrowdControl + IsSnare) -- Ursol's Vortex
	AddFlags( 50259, IsDruid + IsCrowdControl + IsSnare) -- Wild Charge (Dazed)
	AddFlags(102543, IsDruid + IsCrowdControl) -- Incarnation: King of the Jungle
	AddFlags(106951, IsDruid + IsCrowdControl) -- Berserk
	AddFlags(102558, IsDruid + IsCrowdControl) -- Incarnation: Guardian of Ursoc
	AddFlags(102560, IsDruid + IsCrowdControl) -- Incarnation: Chosen of Elune
	AddFlags(202244, IsDruid + IsCrowdControl) -- Overrun (pvp honor talent)
	AddFlags(209749, IsDruid + IsCrowdControl + IsDisarm) -- Faerie Swarm (pvp honor talent)
end 

-- Hunter
do 
	AddFlags(117526, IsHunter + IsCrowdControl + IsRoot) -- Binding Shot
	AddFlags(  3355, IsHunter + IsCrowdControl) -- Freezing Trap
	AddFlags( 13809, IsHunter + IsCrowdControl) -- Ice Trap 1
	AddFlags(195645, IsHunter + IsCrowdControl + IsSnare) -- Wing Clip
	AddFlags( 19386, IsHunter + IsCrowdControl) -- Wyvern Sting
	AddFlags(128405, IsHunter + IsCrowdControl + IsRoot) -- Narrow Escape
	AddFlags(201158, IsHunter + IsCrowdControl + IsRoot) -- Super Sticky Tar (root)
	AddFlags(111735, IsHunter + IsCrowdControl + IsSnare) -- Tar
	AddFlags(135299, IsHunter + IsCrowdControl + IsSnare) -- Tar Trap
	AddFlags(  5116, IsHunter + IsCrowdControl + IsSnare) -- Concussive Shot
	AddFlags(194279, IsHunter + IsCrowdControl + IsSnare) -- Caltrops
	AddFlags(206755, IsHunter + IsCrowdControl + IsSnare) -- Ranger's Net (snare)
	AddFlags(236699, IsHunter + IsCrowdControl + IsSnare) -- Super Sticky Tar (slow)
	AddFlags(213691, IsHunter + IsCrowdControl) -- Scatter Shot (pvp honor talent)
	AddFlags(186265, IsHunter + IsCrowdControl + IsImmune) -- Deterrence (aspect of the turtle)
	AddFlags( 19574, IsHunter + IsCrowdControl + IsImmuneSpell) -- Bestial Wrath (only if The Beast Within (212704) is active)
	AddFlags(190927, IsHunter + IsCrowdControl + IsRoot) -- Harpoon
	AddFlags(212331, IsHunter + IsCrowdControl + IsRoot) -- Harpoon
	AddFlags(212353, IsHunter + IsCrowdControl + IsRoot) -- Harpoon
	AddFlags(162480, IsHunter + IsCrowdControl + IsRoot) -- Steel Trap
	AddFlags(200108, IsHunter + IsCrowdControl + IsRoot) -- Ranger's Net
	AddFlags(212638, IsHunter + IsCrowdControl + IsRoot) -- Tracker's Net 
	AddFlags(224729, IsHunter + IsCrowdControl + IsSnare) -- Bursting Shot
	AddFlags(238559, IsHunter + IsCrowdControl + IsSnare) -- Bursting Shot
	AddFlags(203337, IsHunter + IsCrowdControl) -- Freezing Trap (Diamond Ice - pvp honor talent)
	AddFlags(202748, IsHunter + IsCrowdControl + IsImmune) -- Survival Tactics (pvp honor talent) (not immune, 99% damage reduction)
	AddFlags(248519, IsHunter + IsCrowdControl + IsImmuneSpell) -- Interlope (pvp honor talent)
	AddFlags(202933, IsHunter + IsCrowdControl + IsSilence) -- Spider Sting	(pvp honor talent) --this its the silence effect
	AddFlags(  5384, IsHunter + IsCrowdControl) -- Feign Death
end 

-- Hunter Pets
do 
	AddFlags( 24394, IsHunter + IsCrowdControl) -- Intimidation
	AddFlags( 50433, IsHunter + IsCrowdControl + IsSnare) -- Ankle Crack (Crocolisk)
	AddFlags( 54644, IsHunter + IsCrowdControl + IsSnare) -- Frost Breath (Chimaera)
	AddFlags( 35346, IsHunter + IsCrowdControl + IsSnare) -- Warp Time (Warp Stalker)
	AddFlags(160067, IsHunter + IsCrowdControl + IsSnare) -- Web Spray (Spider)
	AddFlags(160065, IsHunter + IsCrowdControl + IsSnare) -- Tendon Rip (Silithid)
	AddFlags( 54216, IsHunter + IsCrowdControl) -- Master's Call (root and snare immune only)
	AddFlags( 53148, IsHunter + IsCrowdControl + IsRoot) -- Charge (tenacity ability)
	AddFlags(137798, IsHunter + IsCrowdControl + IsImmuneSpell) -- Reflective Armor Plating (Direhorn)
end 

-- Mage
do 
	AddFlags( 44572, IsMage + IsCrowdControl) -- Deep Freeze
	AddFlags( 31661, IsMage + IsCrowdControl) -- Dragon's Breath
	AddFlags(   118, IsMage + IsCrowdControl) -- Polymorph
	AddFlags( 61305, IsMage + IsCrowdControl) -- Polymorph: Black Cat
	AddFlags( 61308, IsMage + IsCrowdControl) -- Polymorph: Black Cat
	AddFlags(277792, IsMage + IsCrowdControl) -- Polymorph: Bumblebee
	AddFlags(277787, IsMage + IsCrowdControl) -- Polymorph: Direhorn
	AddFlags(161354, IsMage + IsCrowdControl) -- Polymorph: Monkey
	AddFlags(161372, IsMage + IsCrowdControl) -- Polymorph: Peacock
	AddFlags(161355, IsMage + IsCrowdControl) -- Polymorph: Penguin
	AddFlags( 28272, IsMage + IsCrowdControl) -- Polymorph: Pig
	AddFlags(161353, IsMage + IsCrowdControl) -- Polymorph: Polar bear cub
	AddFlags(126819, IsMage + IsCrowdControl) -- Polymorph: Porcupine
	AddFlags( 61721, IsMage + IsCrowdControl) -- Polymorph: Rabbit
	AddFlags( 61025, IsMage + IsCrowdControl) -- Polymorph: Serpent
	AddFlags( 61780, IsMage + IsCrowdControl) -- Polymorph: Turkey
	AddFlags( 28271, IsMage + IsCrowdControl) -- Polymorph: Turtle
	AddFlags( 82691, IsMage + IsCrowdControl) -- Ring of Frost
	AddFlags(140376, IsMage + IsCrowdControl) -- Ring of Frost
	AddFlags(   122, IsMage + IsCrowdControl + IsRoot) -- Frost Nova
	AddFlags(111340, IsMage + IsCrowdControl + IsRoot) -- Ice Ward
	AddFlags(   120, IsMage + IsCrowdControl + IsSnare) -- Cone of Cold
	AddFlags(   116, IsMage + IsCrowdControl + IsSnare) -- Frostbolt
	AddFlags( 44614, IsMage + IsCrowdControl + IsSnare) -- Frostfire Bolt
	AddFlags( 31589, IsMage + IsCrowdControl + IsSnare) -- Slow
	AddFlags(    10, IsMage + IsCrowdControl + IsSnare) -- Blizzard
	AddFlags(205708, IsMage + IsCrowdControl + IsSnare) -- Chilled
	AddFlags(212792, IsMage + IsCrowdControl + IsSnare) -- Cone of Cold
	AddFlags(205021, IsMage + IsCrowdControl + IsSnare) -- Ray of Frost
	AddFlags(135029, IsMage + IsCrowdControl + IsSnare) -- Water Jet
	AddFlags( 59638, IsMage + IsCrowdControl + IsSnare) -- Frostbolt (Mirror Images)
	AddFlags(228354, IsMage + IsCrowdControl + IsSnare) -- Flurry
	AddFlags(157981, IsMage + IsCrowdControl + IsSnare) -- Blast Wave
	AddFlags(  2120, IsMage + IsCrowdControl + IsSnare) -- Flamestrike
	AddFlags(236299, IsMage + IsCrowdControl + IsSnare) -- Chrono Shift
	AddFlags( 45438, IsMage + IsCrowdControl + IsImmune) -- Ice Block
	AddFlags(198121, IsMage + IsCrowdControl + IsRoot) -- Frostbite (pvp talent)
	AddFlags(220107, IsMage + IsCrowdControl + IsRoot) -- Frostbite
	AddFlags(157997, IsMage + IsCrowdControl + IsRoot) -- Ice Nova
	AddFlags(228600, IsMage + IsCrowdControl + IsRoot) -- Glacial Spike
	AddFlags(110959, IsMage + IsCrowdControl) -- Greater Invisibility
	AddFlags(198144, IsMage + IsCrowdControl) -- Ice form (stun/knockback immune)
	AddFlags( 12042, IsMage + IsCrowdControl) -- Arcane Power
	AddFlags(198111, IsMage + IsCrowdControl + IsImmune) -- Temporal Shield (heals all damage taken after 4 sec)
end 

-- Mage Water Elemental
do 
	AddFlags( 33395, IsMage + IsCrowdControl + IsRoot) -- Freeze
end 

-- Monk
do 
	AddFlags(123393, IsMonk + IsCrowdControl) -- Breath of Fire (Glyph of Breath of Fire)
	AddFlags(119392, IsMonk + IsCrowdControl) -- Charging Ox Wave
	AddFlags(119381, IsMonk + IsCrowdControl) -- Leg Sweep
	AddFlags(115078, IsMonk + IsCrowdControl) -- Paralysis
	AddFlags(116706, IsMonk + IsCrowdControl + IsRoot) -- Disable
	AddFlags(116095, IsMonk + IsCrowdControl + IsSnare) -- Disable
	AddFlags(118585, IsMonk + IsCrowdControl + IsSnare) -- Leer of the Ox
	AddFlags(123586, IsMonk + IsCrowdControl + IsSnare) -- Flying Serpent Kick
	AddFlags(121253, IsMonk + IsCrowdControl + IsSnare) -- Keg Smash
	AddFlags(196733, IsMonk + IsCrowdControl + IsSnare) -- Special Delivery
	AddFlags(205320, IsMonk + IsCrowdControl + IsSnare) -- Strike of the Windlord (artifact trait)
	AddFlags(125174, IsMonk + IsCrowdControl + IsImmune) -- Touch of Karma
	AddFlags(198909, IsMonk + IsCrowdControl) -- Song of Chi-Ji
	AddFlags(233759, IsMonk + IsCrowdControl + IsDisarm) -- Grapple Weapon
	AddFlags(202274, IsMonk + IsCrowdControl) -- Incendiary Brew (honor talent)
	AddFlags(202346, IsMonk + IsCrowdControl) -- Double Barrel (honor talent)
	AddFlags(123407, IsMonk + IsCrowdControl + IsRoot) -- Spinning Fire Blossom (honor talent)
	AddFlags(214326, IsMonk + IsCrowdControl) -- Exploding Keg (artifact trait - blind)
	AddFlags(199387, IsMonk + IsCrowdControl + IsSnare) -- Spirit Tether (artifact trait)
end 

-- Paladin
do 
	AddFlags(105421, IsPaladin + IsCrowdControl) -- Blinding Light
	AddFlags(105593, IsPaladin + IsCrowdControl) -- Fist of Justice
	AddFlags(   853, IsPaladin + IsCrowdControl + IsStun) -- Hammer of Justice
	AddFlags( 20066, IsPaladin + IsCrowdControl) -- Repentance
	AddFlags( 31935, IsPaladin + IsCrowdControl + IsSilence) -- Avenger's Shield
	AddFlags(187219, IsPaladin + IsCrowdControl + IsSilence) -- Avenger's Shield (pvp talent)
	AddFlags(199512, IsPaladin + IsCrowdControl + IsSilence) -- Avenger's Shield (unknow use)
	AddFlags(217824, IsPaladin + IsCrowdControl + IsSilence) -- Shield of Virtue (pvp honor talent)
	AddFlags(204242, IsPaladin + IsCrowdControl + IsSnare) -- Consecration (talent Consecrated Ground)
	AddFlags(183218, IsPaladin + IsCrowdControl + IsSnare) -- Hand of Hindrance
	AddFlags(   642, IsPaladin + IsCrowdControl + IsImmune) -- Divine Shield
	AddFlags(184662, IsPaladin + IsCrowdControl) -- Shield of Vengeance
	AddFlags( 31821, IsPaladin + IsCrowdControl) -- Aura Mastery
	AddFlags(  1022, IsPaladin + IsCrowdControl + IsImmunePhysical) -- Hand of Protection
	AddFlags(204018, IsPaladin + IsCrowdControl + IsImmuneSpell) -- Blessing of Spellwarding
	AddFlags(228050, IsPaladin + IsCrowdControl + IsImmune) -- Divine Shield (Guardian of the Forgotten Queen)
	AddFlags(205273, IsPaladin + IsCrowdControl + IsSnare) -- Wake of Ashes (artifact trait) (snare)
	AddFlags(205290, IsPaladin + IsCrowdControl + IsStun) -- Wake of Ashes (artifact trait) (stun)
	AddFlags(199448, IsPaladin + IsCrowdControl + IsImmune) -- Blessing of Sacrifice (pvp talent, 100% damage transfered to paladin)
end 

-- Priest
do 
	AddFlags(   605, IsPriest + IsCrowdControl) -- Dominate Mind
	AddFlags( 64044, IsPriest + IsCrowdControl) -- Psychic Horror
	AddFlags(  8122, IsPriest + IsCrowdControl) -- Psychic Scream
	AddFlags(  9484, IsPriest + IsCrowdControl) -- Shackle Undead
	AddFlags( 87204, IsPriest + IsCrowdControl) -- Sin and Punishment
	AddFlags( 15487, IsPriest + IsCrowdControl + IsSilence) -- Silence
	AddFlags( 64058, IsPriest + IsCrowdControl + IsDisarm) -- Psychic Horror
	AddFlags( 87194, IsPriest + IsCrowdControl + IsRoot) -- Glyph of Mind Blast
	AddFlags(114404, IsPriest + IsCrowdControl + IsRoot) -- Void Tendril's Grasp
	AddFlags( 15407, IsPriest + IsCrowdControl + IsSnare) -- Mind Flay
	AddFlags( 47585, IsPriest + IsCrowdControl + IsImmune) -- Dispersion
	AddFlags( 47788, IsPriest + IsCrowdControl) -- Guardian Spirit (prevent the target from dying)
	AddFlags(213602, IsPriest + IsCrowdControl + IsImmune) -- Greater Fade (pvp honor talent - protects vs spells. melee, ranged attacks + 50% speed)
	AddFlags(232707, IsPriest + IsCrowdControl + IsImmune) -- Ray of Hope (pvp honor talent - not immune, only delay damage and heal)
	AddFlags(213610, IsPriest + IsCrowdControl) -- Holy Ward (pvp honor talent - wards against the next loss of control effect)
	AddFlags(226943, IsPriest + IsCrowdControl) -- Mind Bomb
	AddFlags(200196, IsPriest + IsCrowdControl) -- Holy Word: Chastise
	AddFlags(200200, IsPriest + IsCrowdControl) -- Holy Word: Chastise (talent)
	AddFlags(204263, IsPriest + IsCrowdControl + IsSnare) -- Shining Force
	AddFlags(199845, IsPriest + IsCrowdControl + IsSnare) -- Psyflay (pvp honor talent - Psyfiend)
	AddFlags(210979, IsPriest + IsCrowdControl + IsSnare) -- Focus in the Light (artifact trait)
end 

-- Rogue
do 
	AddFlags(  2094, IsRogue + IsCrowdControl) -- Blind
	AddFlags(  1833, IsRogue + IsCrowdControl) -- Cheap Shot
	AddFlags(  1776, IsRogue + IsCrowdControl) -- Gouge
	AddFlags(   408, IsRogue + IsCrowdControl + IsStun) -- Kidney Shot
	AddFlags(  6770, IsRogue + IsCrowdControl) -- Sap
	AddFlags(196958, IsRogue + IsCrowdControl) -- Strike from the Shadows (stun effect)
	AddFlags(  1330, IsRogue + IsCrowdControl + IsSilence) -- Garrote - Silence
	AddFlags(  3409, IsRogue + IsCrowdControl + IsSnare) -- Crippling Poison
	AddFlags( 26679, IsRogue + IsCrowdControl + IsSnare) -- Deadly Throw
	AddFlags(185763, IsRogue + IsCrowdControl + IsSnare) -- Pistol Shot
	AddFlags(185778, IsRogue + IsCrowdControl + IsSnare) -- Shellshocked
	AddFlags(206760, IsRogue + IsCrowdControl + IsSnare) -- Night Terrors
	AddFlags(222775, IsRogue + IsCrowdControl + IsSnare) -- Strike from the Shadows (daze effect)
	AddFlags(152150, IsRogue + IsCrowdControl + IsImmune) -- Death from Above (in the air you are immune to CC)
	AddFlags( 31224, IsRogue + IsCrowdControl + IsImmuneSpell) -- Cloak of Shadows
	AddFlags( 51690, IsRogue + IsCrowdControl) -- Killing Spree
	AddFlags( 13750, IsRogue + IsCrowdControl) -- Adrenaline Rush
	AddFlags(199754, IsRogue + IsCrowdControl) -- Riposte
	AddFlags(  1966, IsRogue + IsCrowdControl) -- Feint
	AddFlags( 45182, IsRogue + IsCrowdControl) -- Cheating Death
	AddFlags(  5277, IsRogue + IsCrowdControl) -- Evasion
	AddFlags(212183, IsRogue + IsCrowdControl) -- Smoke Bomb
	AddFlags(199804, IsRogue + IsCrowdControl) -- Between the eyes
	AddFlags(199740, IsRogue + IsCrowdControl) -- Bribe
	AddFlags(207777, IsRogue + IsCrowdControl + IsDisarm) -- Dismantle
	AddFlags(185767, IsRogue + IsCrowdControl + IsSnare) -- Cannonball Barrage
	AddFlags(207736, IsRogue + IsCrowdControl) -- Shadowy Duel
	AddFlags(212150, IsRogue + IsCrowdControl) -- Cheap Tricks (pvp honor talent) (-75%  melee & range physical hit chance)
	AddFlags(199743, IsRogue + IsCrowdControl) -- Parley
	AddFlags(198222, IsRogue + IsCrowdControl + IsSnare) -- System Shock (pvp honor talent) (90% slow)
	AddFlags(226364, IsRogue + IsCrowdControl) -- Evasion (Shadow Swiftness, artifact trait)
	AddFlags(209786, IsRogue + IsCrowdControl + IsSnare) -- Goremaw's Bite (artifact trait)
end

-- Shaman
do 
	AddFlags( 77505, IsShaman + IsCrowdControl) -- Earthquake
	AddFlags( 51514, IsShaman + IsCrowdControl) -- Hex
	AddFlags(210873, IsShaman + IsCrowdControl) -- Hex (compy)
	AddFlags(211010, IsShaman + IsCrowdControl) -- Hex (snake)
	AddFlags(211015, IsShaman + IsCrowdControl) -- Hex (cockroach)
	AddFlags(211004, IsShaman + IsCrowdControl) -- Hex (spider)
	AddFlags(196942, IsShaman + IsCrowdControl) -- Hex (Voodoo Totem)
	AddFlags(269352, IsShaman + IsCrowdControl) -- Hex (skeletal hatchling)
	AddFlags(277778, IsShaman + IsCrowdControl) -- Hex (zandalari Tendonripper)
	AddFlags(277784, IsShaman + IsCrowdControl) -- Hex (wicker mongrel)
	AddFlags(118905, IsShaman + IsCrowdControl) -- Static Charge (Capacitor Totem)
	AddFlags( 64695, IsShaman + IsCrowdControl + IsRoot) -- Earthgrab (Earthgrab Totem)
	AddFlags(  3600, IsShaman + IsCrowdControl + IsSnare) -- Earthbind (Earthbind Totem)
	AddFlags(116947, IsShaman + IsCrowdControl + IsSnare) -- Earthbind (Earthgrab Totem)
	AddFlags( 77478, IsShaman + IsCrowdControl + IsSnare) -- Earthquake (Glyph of Unstable Earth)
	AddFlags(  8056, IsShaman + IsCrowdControl + IsSnare) -- Frost Shock
	AddFlags(196840, IsShaman + IsCrowdControl + IsSnare) -- Frost Shock
	AddFlags( 51490, IsShaman + IsCrowdControl + IsSnare) -- Thunderstorm
	AddFlags(147732, IsShaman + IsCrowdControl + IsSnare) -- Frostbrand Attack
	AddFlags(197385, IsShaman + IsCrowdControl + IsSnare) -- Fury of Air
	AddFlags(207498, IsShaman + IsCrowdControl) -- Ancestral Protection (prevent the target from dying)
	AddFlags(  8178, IsShaman + IsCrowdControl + IsImmuneSpell) -- Grounding Totem Effect (Grounding Totem)
	AddFlags(204399, IsShaman + IsCrowdControl) -- Earthfury (PvP Talent)
	AddFlags(192058, IsShaman + IsCrowdControl) -- Lightning Surge totem (capacitor totem)
	AddFlags(210918, IsShaman + IsCrowdControl + IsImmunePhysical) -- Ethereal Form
	AddFlags(204437, IsShaman + IsCrowdControl) -- Lightning Lasso
	AddFlags(197214, IsShaman + IsCrowdControl + IsRoot) -- Sundering
	AddFlags(224126, IsShaman + IsCrowdControl + IsSnare) -- Frozen Bite (Doom Wolves, artifact trait)
	AddFlags(207654, IsShaman + IsCrowdControl + IsImmune) -- Servant of the Queen (not immune, 80% damage reduction - artifact trait)
end 

-- Shaman Pets
do 
	AddFlags(118345, IsShaman + IsCrowdControl) -- Pulverize (Shaman Primal Earth Elemental)
	AddFlags(157375, IsShaman + IsCrowdControl) -- Gale Force (Primal Storm Elemental)
end 

-- Warlock
do 
	AddFlags(   710, IsWarlock + IsCrowdControl) -- Banish
	AddFlags(  5782, IsWarlock + IsCrowdControl) -- Fear
	AddFlags(118699, IsWarlock + IsCrowdControl) -- Fear
	AddFlags(130616, IsWarlock + IsCrowdControl) -- Fear (Glyph of Fear)
	AddFlags(  5484, IsWarlock + IsCrowdControl) -- Howl of Terror
	AddFlags( 22703, IsWarlock + IsCrowdControl) -- Infernal Awakening
	AddFlags(  6789, IsWarlock + IsCrowdControl) -- Mortal Coil
	AddFlags( 30283, IsWarlock + IsCrowdControl) -- Shadowfury
	AddFlags( 31117, IsWarlock + IsCrowdControl + IsSilence) -- Unstable Affliction
	AddFlags(196364, IsWarlock + IsCrowdControl + IsSilence) -- Unstable Affliction
	AddFlags(110913, IsWarlock + IsCrowdControl) -- Dark Bargain
	AddFlags(104773, IsWarlock + IsCrowdControl) -- Unending Resolve
	AddFlags(212295, IsWarlock + IsCrowdControl + IsImmuneSpell) -- Netherward (reflects spells)
	AddFlags(233582, IsWarlock + IsCrowdControl + IsRoot) -- Entrenched in Flame (pvp honor talent)
end 

-- Warlock Pets
do 
	AddFlags( 32752, IsWarlock + IsCrowdControl) -- Summoning Disorientation
	AddFlags( 89766, IsWarlock + IsCrowdControl) -- Axe Toss (Felguard/Wrathguard)
	AddFlags(115268, IsWarlock + IsCrowdControl) -- Mesmerize (Shivarra)
	AddFlags(  6358, IsWarlock + IsCrowdControl) -- Seduction (Succubus)
	AddFlags(171017, IsWarlock + IsCrowdControl) -- Meteor Strike (infernal)
	AddFlags(171018, IsWarlock + IsCrowdControl) -- Meteor Strike (abisal)
	AddFlags(213688, IsWarlock + IsCrowdControl) -- Fel Cleave (Fel Lord - PvP Talent)
	AddFlags(170996, IsWarlock + IsCrowdControl + IsSnare) -- Debilitate (Terrorguard)
	AddFlags(170995, IsWarlock + IsCrowdControl + IsSnare) -- Cripple (Doomguard)
end 

-- Warrior
do 
	AddFlags(118895, IsWarrior + IsCrowdControl) -- Dragon Roar
	AddFlags(  5246, IsWarrior + IsCrowdControl) -- Intimidating Shout (aoe)
	AddFlags(132168, IsWarrior + IsCrowdControl) -- Shockwave
	AddFlags(107570, IsWarrior + IsCrowdControl) -- Storm Bolt
	AddFlags(132169, IsWarrior + IsCrowdControl) -- Storm Bolt
	AddFlags( 46968, IsWarrior + IsCrowdControl) -- Shockwave
	AddFlags(213427, IsWarrior + IsCrowdControl) -- Charge Stun Talent (Warbringer)
	AddFlags(  7922, IsWarrior + IsCrowdControl) -- Charge Stun Talent (Warbringer)
	AddFlags(237744, IsWarrior + IsCrowdControl) -- Charge Stun Talent (Warbringer)
	AddFlags(107566, IsWarrior + IsCrowdControl + IsRoot) -- Staggering Shout
	AddFlags(105771, IsWarrior + IsCrowdControl + IsRoot) -- Charge (root)
	AddFlags(236027, IsWarrior + IsCrowdControl + IsSnare) -- Charge (snare)
	AddFlags(147531, IsWarrior + IsCrowdControl + IsSnare) -- Bloodbath
	AddFlags(  1715, IsWarrior + IsCrowdControl + IsSnare) -- Hamstring
	AddFlags( 12323, IsWarrior + IsCrowdControl + IsSnare) -- Piercing Howl
	AddFlags(  6343, IsWarrior + IsCrowdControl + IsSnare) -- Thunder Clap
	AddFlags( 46924, IsWarrior + IsCrowdControl + IsImmune) -- Bladestorm (not immune to dmg, only to LoC)
	AddFlags(227847, IsWarrior + IsCrowdControl + IsImmune) -- Bladestorm (not immune to dmg, only to LoC)
	AddFlags(199038, IsWarrior + IsCrowdControl + IsImmune) -- Leave No Man Behind (not immune, 90% damage reduction)
	AddFlags(218826, IsWarrior + IsCrowdControl + IsImmune) -- Trial by Combat (warr fury artifact hidden trait) (only immune to death)
	AddFlags( 23920, IsWarrior + IsCrowdControl + IsImmuneSpell) -- Spell Reflection
	AddFlags(216890, IsWarrior + IsCrowdControl + IsImmuneSpell) -- Spell Reflection
	AddFlags(213915, IsWarrior + IsCrowdControl + IsImmuneSpell) -- Mass Spell Reflection
	AddFlags(114028, IsWarrior + IsCrowdControl + IsImmuneSpell) -- Mass Spell Reflection
	AddFlags( 18499, IsWarrior + IsCrowdControl) -- Berserker Rage
	AddFlags(118038, IsWarrior + IsCrowdControl) -- Die by the Sword
	AddFlags(198819, IsWarrior + IsCrowdControl) -- Sharpen Blade (70% heal reduction)
	AddFlags(198760, IsWarrior + IsCrowdControl + IsImmunePhysical) -- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
	AddFlags(176289, IsWarrior + IsCrowdControl) -- Siegebreaker
	AddFlags(199085, IsWarrior + IsCrowdControl) -- Warpath
	AddFlags(199042, IsWarrior + IsCrowdControl + IsRoot) -- Thunderstruck
	AddFlags(236236, IsWarrior + IsCrowdControl + IsDisarm) -- Disarm (pvp honor talent - protection)
	AddFlags(236077, IsWarrior + IsCrowdControl + IsDisarm) -- Disarm (pvp honor talent)
end 

-- Other
do 
	AddFlags(    56, IsCrowdControl) -- Stun (low lvl weapons proc)
	AddFlags(   835, IsCrowdControl) -- Tidal Charm (trinket)
	AddFlags( 30217, IsCrowdControl) -- Adamantite Grenade
	AddFlags( 67769, IsCrowdControl) -- Cobalt Frag Bomb
	AddFlags( 67890, IsCrowdControl) -- Cobalt Frag Bomb (belt)
	AddFlags( 30216, IsCrowdControl) -- Fel Iron Bomb
	AddFlags(224074, IsCrowdControl) -- Devilsaur's Bite (trinket)
	AddFlags(127723, IsCrowdControl + IsRoot) -- Covered In Watermelon (trinket)
	AddFlags(195342, IsCrowdControl + IsSnare) -- Shrink Ray (trinket)
	AddFlags( 13327, IsCrowdControl) -- Reckless Charge
	AddFlags(107079, IsCrowdControl) -- Quaking Palm (pandaren racial)
	AddFlags( 20549, IsCrowdControl) -- War Stomp (tauren racial)
	AddFlags(255723, IsCrowdControl) -- Bull Rush (highmountain tauren racial)
	AddFlags(214459, IsCrowdControl + IsSilence) -- Choking Flames (trinket)
	AddFlags( 19821, IsCrowdControl + IsSilence) -- Arcane Bomb
	AddFlags(  8346, IsCrowdControl + IsRoot) -- Mobility Malfunction (trinket)
	AddFlags( 39965, IsCrowdControl + IsRoot) -- Frost Grenade
	AddFlags( 55536, IsCrowdControl + IsRoot) -- Frostweave Net
	AddFlags( 13099, IsCrowdControl + IsRoot) -- Net-o-Matic (trinket)
	AddFlags( 16566, IsCrowdControl + IsRoot) -- Net-o-Matic (trinket)
	AddFlags( 15752, IsCrowdControl + IsDisarm) -- Linken's Boomerang (trinket)
	AddFlags( 15753, IsCrowdControl) -- Linken's Boomerang (trinket)
	AddFlags(  1604, IsCrowdControl + IsSnare) -- Dazed
	AddFlags(221792, IsCrowdControl) -- Kidney Shot (Vanessa VanCleef (Rogue Bodyguard))
	AddFlags(222897, IsCrowdControl) -- Storm Bolt (Dvalen Ironrune (Warrior Bodyguard))
	AddFlags(222317, IsCrowdControl) -- Mark of Thassarian (Thassarian (Death Knight Bodyguard))
	AddFlags(212435, IsCrowdControl) -- Shado Strike (Thassarian (Monk Bodyguard))
	AddFlags(212246, IsCrowdControl) -- Brittle Statue (The Monkey King (Monk Bodyguard))
	AddFlags(238511, IsCrowdControl) -- March of the Withered
	AddFlags(252717, IsCrowdControl) -- Light's Radiance (Argus powerup)
	AddFlags(148535, IsCrowdControl) -- Ordon Death Chime (trinket)
	AddFlags( 30504, IsCrowdControl) -- Poultryized! (trinket)
	AddFlags( 30501, IsCrowdControl) -- Poultryized! (trinket)
	AddFlags( 30506, IsCrowdControl) -- Poultryized! (trinket)
	AddFlags( 46567, IsCrowdControl) -- Rocket Launch (trinket)
	AddFlags( 24753, IsCrowdControl) -- Trick
	AddFlags(245855, IsCrowdControl) -- Belly Smash
	AddFlags(262177, IsCrowdControl) -- Into the Storm
	AddFlags(255978, IsCrowdControl) -- Pallid Glare
	AddFlags(256050, IsCrowdControl) -- Disoriented (Electroshock Mount Motivator)
	AddFlags(258258, IsCrowdControl) -- Quillbomb
	AddFlags(260149, IsCrowdControl) -- Quillbomb
	AddFlags(258236, IsCrowdControl) -- Sleeping Quill Dart
	AddFlags(269186, IsCrowdControl) -- Holographic Horror Projector
	AddFlags(255228, IsCrowdControl) -- Polymorphed (Organic Discombobulation Grenade)
	AddFlags(268966, IsCrowdControl + IsRoot) -- Hooked Deep Sea Net
	AddFlags(268965, IsCrowdControl + IsSnare) -- Tidespray Linen Net
end 

------------------------------------------------------------------------
------------------------------------------------------------------------
---- 					CROWD CONTROL: PVE BFA
------------------------------------------------------------------------
------------------------------------------------------------------------
do
	------------------------------------------------------------------------
	-- Uldir Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(277498, IsCrowdControl) -- Mind Slave
	AddFlags(277358, IsCrowdControl) -- Mind Flay
	AddFlags(278890, IsCrowdControl) -- Violent Hemorrhage
	AddFlags(278967, IsCrowdControl) -- Winged Charge
	AddFlags(260275, IsCrowdControl) -- Rumbling Stomp
	AddFlags(263321, IsCrowdControl + IsSnare) -- Undulating Mass

	-- Taloc
	AddFlags(271965, IsCrowdControl + IsImmune) -- Powered Down (damage taken reduced 99%)

	-- MOTHER
	-- Fetid Devourer
	AddFlags(277800, IsCrowdControl) -- Swoop

	-- Zek'voz, Herald of N'zoth
	AddFlags(265646, IsCrowdControl) -- Will of the Corruptor
	AddFlags(270589, IsCrowdControl) -- Void Wail
	AddFlags(270620, IsCrowdControl) -- Psionic Blast

	-- Vectis
	AddFlags(265212, IsCrowdControl) -- Gestate

	-- Zul, Reborn
	AddFlags(273434, IsCrowdControl) -- Pit of Despair
	AddFlags(276031, IsCrowdControl) -- Pit of Despair
	AddFlags(269965, IsCrowdControl) -- Pit of Despair
	AddFlags(274271, IsCrowdControl) -- Deathwish

	-- Mythrax the Unraveler
	AddFlags(272407, IsCrowdControl) -- Oblivion Sphere
	AddFlags(274230, IsCrowdControl + IsImmune) -- Oblivion Veil (damage taken reduced 99%)
	AddFlags(276900, IsCrowdControl + IsImmune) -- Critical Mass (damage taken reduced 80%)

	-- G'huun
	AddFlags(269691, IsCrowdControl) -- Mind Thrall
	AddFlags(267700, IsCrowdControl) -- Gaze of G'huun
	AddFlags(268174, IsCrowdControl + IsRoot) -- Tendrils of Corruption

	------------------------------------------------------------------------
	-- BfA Island Expeditions
	------------------------------------------------------------------------
	AddFlags(  8377, IsCrowdControl + IsRoot) -- Earthgrab
	AddFlags(280061, IsCrowdControl) -- Brainsmasher Brew
	AddFlags(280062, IsCrowdControl) -- Unluckydo
	AddFlags(270399, IsCrowdControl + IsRoot) -- Unleashed Roots
	AddFlags(270196, IsCrowdControl + IsRoot) -- Chains of Light
	AddFlags(267024, IsCrowdControl + IsRoot) -- Stranglevines
	AddFlags(245638, IsCrowdControl) -- Thick Shell
	AddFlags(267026, IsCrowdControl) -- Giant Flower
	AddFlags(243576, IsCrowdControl) -- Sticky Starfish
	AddFlags(274794, IsCrowdControl) -- Hex
	AddFlags(275651, IsCrowdControl) -- Charge
	AddFlags(262470, IsCrowdControl) -- Blast-O-Matic Frag Bomb
	AddFlags(274055, IsCrowdControl) -- Sap
	AddFlags(279986, IsCrowdControl) -- Shrink Ray
	AddFlags(278820, IsCrowdControl) -- Netted
	AddFlags(268345, IsCrowdControl) -- Azerite Suppression
	AddFlags(262906, IsCrowdControl) -- Arcane Charge
	AddFlags(270460, IsCrowdControl) -- Stone Eruption
	AddFlags(262500, IsCrowdControl) -- Crushing Charge
	AddFlags(265723, IsCrowdControl + IsRoot) -- Web

	------------------------------------------------------------------------
	-- BfA Mythics
	------------------------------------------------------------------------
	-- Atal'Dazar
	AddFlags(255371, IsCrowdControl) -- Terrifying Visage
	AddFlags(255041, IsCrowdControl) -- Terrifying Screech
	AddFlags(252781, IsCrowdControl) -- Unstable Hex
	AddFlags(279118, IsCrowdControl) -- Unstable Hex
	AddFlags(252692, IsCrowdControl) -- Waylaying Jab
	AddFlags(258653, IsCrowdControl + IsImmune) -- Bulwark of Juju (90% damage reduction)
	AddFlags(253721, IsCrowdControl + IsImmune) -- Bulwark of Juju (90% damage reduction)

	-- Kings' Rest
	AddFlags(268796, IsCrowdControl) -- Impaling Spear
	AddFlags(269369, IsCrowdControl) -- Deathly Roar
	AddFlags(267702, IsCrowdControl) -- Entomb
	AddFlags(271555, IsCrowdControl) -- Entomb
	AddFlags(270920, IsCrowdControl) -- Seduction
	AddFlags(270003, IsCrowdControl) -- Suppression Slam
	AddFlags(270492, IsCrowdControl) -- Hex
	AddFlags(276031, IsCrowdControl) -- Pit of Despair
	AddFlags(270931, IsCrowdControl + IsSnare) -- Darkshot
	AddFlags(270499, IsCrowdControl + IsSnare) -- Frost Shock
	AddFlags(267626, IsCrowdControl + IsSnare) -- Dessication

	-- The MOTHERLODE!!
	AddFlags(257337, IsCrowdControl) -- Shocking Claw
	AddFlags(257371, IsCrowdControl) -- Tear Gas
	AddFlags(275907, IsCrowdControl) -- Tectonic Smash
	AddFlags(280605, IsCrowdControl) -- Brain Freeze
	AddFlags(263637, IsCrowdControl) -- Clothesline
	AddFlags(268797, IsCrowdControl) -- Transmute: Enemy to Goo
	AddFlags(268846, IsCrowdControl + IsSilence) -- Echo Blade
	AddFlags(267367, IsCrowdControl) -- Deactivated
	AddFlags(278673, IsCrowdControl) -- Red Card
	AddFlags(278644, IsCrowdControl) -- Slide Tackle
	AddFlags(257481, IsCrowdControl) -- Fracking Totem
	AddFlags(260189, IsCrowdControl + IsImmune) -- Configuration: Drill (damage taken reduced 99%)
	AddFlags(268704, IsCrowdControl + IsSnare) -- Furious Quake

	-- Shrine of the Storm
	AddFlags(268027, IsCrowdControl) -- Rising Tides
	AddFlags(276268, IsCrowdControl) -- Heaving Blow
	AddFlags(269131, IsCrowdControl) -- Ancient Mindbender
	AddFlags(268059, IsCrowdControl + IsRoot) -- Anchor of Binding
	AddFlags(269419, IsCrowdControl + IsSilence) -- Yawning Gate
	AddFlags(267956, IsCrowdControl) -- Zap
	AddFlags(269104, IsCrowdControl) -- Explosive Void
	AddFlags(268391, IsCrowdControl) -- Mental Assault
	AddFlags(264526, IsCrowdControl + IsRoot) -- Grasp from the Depths
	AddFlags(276767, IsCrowdControl + IsImmuneSpell) -- Consuming Void
	AddFlags(268375, IsCrowdControl + IsImmunePhysical) -- Detect Thoughts
	AddFlags(267982, IsCrowdControl + IsImmune) -- Protective Gaze (damage taken reduced 75%)
	AddFlags(268212, IsCrowdControl + IsImmune) -- Minor Reinforcing Ward (damage taken reduced 75%)
	AddFlags(268186, IsCrowdControl + IsImmune) -- Reinforcing Ward (damage taken reduced 75%)
	AddFlags(267904, IsCrowdControl + IsImmune) -- Reinforcing Ward (damage taken reduced 75%)
	AddFlags(274631, IsCrowdControl + IsSnare) -- Lesser Blessing of Ironsides
	AddFlags(267899, IsCrowdControl + IsSnare) -- Hindering Cleave
	AddFlags(268896, IsCrowdControl + IsSnare) -- Mind Rend

	-- Temple of Sethraliss
	AddFlags(280032, IsCrowdControl) -- Neurotoxin
	AddFlags(268993, IsCrowdControl) -- Cheap Shot
	AddFlags(268008, IsCrowdControl) -- Snake Charm
	AddFlags(263958, IsCrowdControl) -- A Knot of Snakes
	AddFlags(269970, IsCrowdControl) -- Blinding Sand
	AddFlags(256333, IsCrowdControl) -- Dust Cloud (0% chance to hit)
	AddFlags(260792, IsCrowdControl) -- Dust Cloud (0% chance to hit)
	AddFlags(269670, IsCrowdControl + IsImmune) -- Empowerment (90% damage reduction)
	AddFlags(273274, IsCrowdControl + IsSnare) -- Polarized Field
	AddFlags(275566, IsCrowdControl + IsSnare) -- Numb Hands

	-- Waycrest Manor
	AddFlags(265407, IsCrowdControl + IsSilence) -- Dinner Bell
	AddFlags(263891, IsCrowdControl) -- Grasping Thorns
	AddFlags(260900, IsCrowdControl) -- Soul Manipulation
	AddFlags(260926, IsCrowdControl) -- Soul Manipulation
	AddFlags(264390, IsCrowdControl + IsSilence) -- Spellbind
	AddFlags(278468, IsCrowdControl) -- Freezing Trap
	AddFlags(267907, IsCrowdControl) -- Soul Thorns
	AddFlags(265346, IsCrowdControl) -- Pallid Glare
	AddFlags(268202, IsCrowdControl) -- Death Lens
	AddFlags(261265, IsCrowdControl + IsImmune) -- Ironbark Shield (99% damage reduction)
	AddFlags(261266, IsCrowdControl + IsImmune) -- Runic Ward (99% damage reduction)
	AddFlags(261264, IsCrowdControl + IsImmune) -- Soul Armor (99% damage reduction)
	AddFlags(271590, IsCrowdControl + IsImmune) -- Soul Armor (99% damage reduction)
	AddFlags(264027, IsCrowdControl) -- Warding Candles (50% damage reduction)
	AddFlags(264040, IsCrowdControl + IsSnare) -- Uprooted Thorns
	AddFlags(264712, IsCrowdControl + IsSnare) -- Rotten Expulsion
	AddFlags(261440, IsCrowdControl + IsSnare) -- Virulent Pathogen

	-- Tol Dagor
	AddFlags(258058, IsCrowdControl + IsRoot) -- Squeeze
	AddFlags(259711, IsCrowdControl + IsRoot) -- Lockdown
	AddFlags(258313, IsCrowdControl) -- Handcuff (Pacified and Silenced)
	AddFlags(260067, IsCrowdControl) -- Vicious Mauling
	AddFlags(257791, IsCrowdControl) -- Howling Fear
	AddFlags(257793, IsCrowdControl) -- Smoke Powder
	AddFlags(257119, IsCrowdControl) -- Sand Trap
	AddFlags(256474, IsCrowdControl) -- Heartstopper Venom
	AddFlags(265271, IsCrowdControl + IsSnare) -- Sewer Slime
	AddFlags(257777, IsCrowdControl + IsSnare) -- Crippling Shiv

	-- Freehold
	AddFlags(274516, IsCrowdControl) -- Slippery Suds
	AddFlags(257949, IsCrowdControl) -- Slippery
	AddFlags(258875, IsCrowdControl) -- Blackout Barrel
	AddFlags(274400, IsCrowdControl) -- Duelist Dash
	AddFlags(274389, IsCrowdControl + IsRoot) -- Rat Traps
	AddFlags(276061, IsCrowdControl) -- Boulder Throw
	AddFlags(258182, IsCrowdControl) -- Boulder Throw
	AddFlags(268283, IsCrowdControl) -- Obscured Vision (hit chance decreased 75%)
	AddFlags(257274, IsCrowdControl + IsSnare) -- Vile Coating
	AddFlags(257478, IsCrowdControl + IsSnare) -- Crippling Bite
	AddFlags(257747, IsCrowdControl + IsSnare) -- Earth Shaker
	AddFlags(257784, IsCrowdControl + IsSnare) -- Frost Blast
	AddFlags(272554, IsCrowdControl + IsSnare) -- Bloody Mess

	-- Siege of Boralus
	AddFlags(256957, IsCrowdControl + IsImmune) -- Watertight Shell
	AddFlags(257069, IsCrowdControl) -- Watertight Shell
	AddFlags(257292, IsCrowdControl) -- Heavy Slash
	AddFlags(272874, IsCrowdControl) -- Trample
	AddFlags(257169, IsCrowdControl) -- Terrifying Roar
	AddFlags(274942, IsCrowdControl) -- Banana Rampage
	AddFlags(272571, IsCrowdControl + IsSilence) -- Choking Waters
	AddFlags(275826, IsCrowdControl + IsImmune) -- Bolstering Shout (damage taken reduced 75%)
	AddFlags(272834, IsCrowdControl + IsSnare) -- Viscous Slobber

	-- The Underrot
	AddFlags(265377, IsCrowdControl + IsRoot) -- Hooked Snare
	AddFlags(272609, IsCrowdControl) -- Maddening Gaze
	AddFlags(265511, IsCrowdControl) -- Spirit Drain
	AddFlags(278961, IsCrowdControl) -- Decaying Mind
	AddFlags(269185, IsCrowdControl + IsImmune) -- Blood Barrier
	AddFlags(269406, IsCrowdControl) -- Purge Corruption

	------------------------------------------------------------------------
	------------------------------------------------------------------------
	---- PVE LEGION
	------------------------------------------------------------------------
	------------------------------------------------------------------------

	------------------------------------------------------------------------
	-- Emerald Nightmare Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(223914, IsCrowdControl) -- Intimidating Roar
	AddFlags(225249, IsCrowdControl) -- Devastating Stomp
	AddFlags(225073, IsCrowdControl + IsRoot) -- Despoiling Roots
	AddFlags(222719, IsCrowdControl + IsRoot) -- Befoulment

	-- Nythendra
	AddFlags(205043, IsCrowdControl) -- Infested Mind (Nythendra)

	-- Ursoc
	AddFlags(197980, IsCrowdControl) -- Nightmarish Cacophony (Ursoc)

	-- Dragons of Nightmare
	AddFlags(205341, IsCrowdControl) -- Seeping Fog (Dragons of Nightmare)
	AddFlags(225356, IsCrowdControl) -- Seeping Fog (Dragons of Nightmare)
	AddFlags(203110, IsCrowdControl) -- Slumbering Nightmare (Dragons of Nightmare)
	AddFlags(204078, IsCrowdControl) -- Bellowing Roar (Dragons of Nightmare)
	AddFlags(203770, IsCrowdControl + IsRoot) -- Defiled Vines (Dragons of Nightmare)

	-- Il'gynoth
	AddFlags(212886, IsCrowdControl) -- Nightmare Corruption (Il'gynoth)

	-- Cenarius
	AddFlags(210315, IsCrowdControl + IsRoot) -- Nightmare Brambles (Cenarius)
	AddFlags(214505, IsCrowdControl) -- Entangling Nightmares (Cenarius)

	------------------------------------------------------------------------
	-- ToV Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(228609, IsCrowdControl) -- Bone Chilling Scream
	AddFlags(228883, IsCrowdControl) -- Unholy Reckoning
	AddFlags(228869, IsCrowdControl) -- Crashing Waves
	-- Odyn
	AddFlags(228018, IsCrowdControl + IsImmune) -- Valarjar's Bond (Odyn)
	AddFlags(229529, IsCrowdControl + IsImmune) -- Valarjar's Bond (Odyn)
	AddFlags(227781, IsCrowdControl) -- Glowing Fragment (Odyn)
	AddFlags(227594, IsCrowdControl + IsImmune) -- Runic Shield (Odyn)
	AddFlags(227595, IsCrowdControl + IsImmune) -- Runic Shield (Odyn)
	AddFlags(227596, IsCrowdControl + IsImmune) -- Runic Shield (Odyn)
	AddFlags(227597, IsCrowdControl + IsImmune) -- Runic Shield (Odyn)
	AddFlags(227598, IsCrowdControl + IsImmune) -- Runic Shield (Odyn)
	-- Guarm
	AddFlags(228248, IsCrowdControl) -- Frost Lick (Guarm)
	-- Helya
	AddFlags(232350, IsCrowdControl) -- Corrupted (Helya)

	------------------------------------------------------------------------
	-- Nighthold Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(225583, IsCrowdControl) -- Arcanic Release
	AddFlags(225803, IsCrowdControl + IsSilence) -- Sealed Magic
	AddFlags(224483, IsCrowdControl) -- Slam
	AddFlags(224944, IsCrowdControl) -- Will of the Legion
	AddFlags(224568, IsCrowdControl) -- Mass Suppress
	AddFlags(221524, IsCrowdControl + IsImmune) -- Protect (not immune, 90% less dmg)
	AddFlags(226231, IsCrowdControl + IsImmune) -- Faint Hope
	AddFlags(230377, IsCrowdControl) -- Wailing Bolt

	-- Skorpyron
	AddFlags(204483, IsCrowdControl) -- Focused Blast (Skorpyron)

	-- Spellblade Aluriel
	AddFlags(213621, IsCrowdControl) -- Entombed in Ice (Spellblade Aluriel)

	-- Tichondrius
	AddFlags(215988, IsCrowdControl) -- Carrion Nightmare (Tichondrius)

	-- High Botanist Tel'arn
	AddFlags(218304, IsCrowdControl + IsRoot) -- Parasitic Fetter (Botanist)

	-- Star Augur
	AddFlags(206603, IsCrowdControl) -- Frozen Solid (Star Augur)
	AddFlags(216697, IsCrowdControl) -- Frigid Pulse (Star Augur)
	AddFlags(207720, IsCrowdControl) -- Witness the Void (Star Augur)
	AddFlags(207714, IsCrowdControl + IsImmune) -- Void Shift (-99% dmg taken) (Star Augur)

	-- Gul'dan
	AddFlags(206366, IsCrowdControl) -- Empowered Bonds of Fel (Knockback Stun) (Gul'dan)
	AddFlags(206983, IsCrowdControl) -- Shadowy Gaze (Gul'dan)
	AddFlags(208835, IsCrowdControl) -- Distortion Aura (Gul'dan)
	AddFlags(208671, IsCrowdControl) -- Carrion Wave (Gul'dan)
	AddFlags(229951, IsCrowdControl) -- Fel Obelisk (Gul'dan)
	AddFlags(206841, IsCrowdControl) -- Fel Obelisk (Gul'dan)
	AddFlags(227749, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(227750, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(227743, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(227745, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(227427, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(227320, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)
	AddFlags(206516, IsCrowdControl + IsImmune) -- The Eye of Aman'Thul (Gul'dan)

	------------------------------------------------------------------------
	-- ToS Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(243298, IsCrowdControl) -- Lash of Domination
	AddFlags(240706, IsCrowdControl) -- Arcane Ward
	AddFlags(240737, IsCrowdControl) -- Polymorph Bomb
	AddFlags(239810, IsCrowdControl) -- Sever Soul
	AddFlags(240592, IsCrowdControl) -- Serpent Rush
	AddFlags(240169, IsCrowdControl) -- Electric Shock
	AddFlags(241234, IsCrowdControl) -- Darkening Shot
	AddFlags(241009, IsCrowdControl) -- Power Drain (-90% damage)
	AddFlags(241254, IsCrowdControl) -- Frost-Fingered Fear
	AddFlags(241276, IsCrowdControl) -- Icy Tomb
	AddFlags(241348, IsCrowdControl) -- Deafening Wail

	-- Demonic Inquisition
	AddFlags(233430, IsCrowdControl) -- Unbearable Torment (Demonic Inquisition) (no CC, -90% dmg, -25% heal, +90% dmg taken)

	-- Harjatan
	AddFlags(240315, IsCrowdControl + IsImmune) -- Hardened Shell (Harjatan)

	-- Sisters of the Moon
	AddFlags(237351, IsCrowdControl + IsSilence) -- Lunar Barrage (Sisters of the Moon)

	-- Mistress Sassz'ine
	AddFlags(234332, IsCrowdControl) -- Hydra Acid (Mistress Sassz'ine)
	AddFlags(230362, IsCrowdControl) -- Thundering Shock (Mistress Sassz'ine)
	AddFlags(230959, IsCrowdControl) -- Concealing Murk (Mistress Sassz'ine) (no CC, hit chance reduced 75%)

	-- The Desolate Host
	AddFlags(236241, IsCrowdControl) -- Soul Rot (The Desolate Host) (no CC, dmg dealt reduced 75%)
	AddFlags(236011, IsCrowdControl + IsSilence) -- Tormented Cries (The Desolate Host)
	AddFlags(236513, IsCrowdControl + IsImmune) -- Bonecage Armor (The Desolate Host) (75% dmg reduction)

	-- Maiden of Vigilance
	AddFlags(248812, IsCrowdControl) -- Blowback (Maiden of Vigilance)
	AddFlags(233739, IsCrowdControl) -- Malfunction (Maiden of Vigilance

	-- Kil'jaeden
	AddFlags(245332, IsCrowdControl + IsImmune) -- Nether Shift (Kil'jaeden)
	AddFlags(244834, IsCrowdControl + IsImmune) -- Nether Gale (Kil'jaeden)
	AddFlags(236602, IsCrowdControl) -- Soul Anguish (Kil'jaeden)
	AddFlags(236555, IsCrowdControl) -- Deceiver's Veil (Kil'jaeden)

	------------------------------------------------------------------------
	-- Antorus Raid
	------------------------------------------------------------------------
	-- Trash
	AddFlags(246209, IsCrowdControl) -- Punishing Flame
	AddFlags(254502, IsCrowdControl) -- Fearsome Leap
	AddFlags(254125, IsCrowdControl) -- Cloud of Confusion

	-- Garothi Worldbreaker
	AddFlags(246920, IsCrowdControl) -- Haywire Decimation

	-- Hounds of Sargeras
	AddFlags(244086, IsCrowdControl) -- Molten Touch
	AddFlags(244072, IsCrowdControl) -- Molten Touch
	AddFlags(249227, IsCrowdControl) -- Molten Touch
	AddFlags(249241, IsCrowdControl) -- Molten Touch
	AddFlags(244071, IsCrowdControl) -- Weight of Darkness

	-- War Council
	AddFlags(244748, IsCrowdControl) -- Shocked

	-- Portal Keeper Hasabel
	AddFlags(246208, IsCrowdControl + IsRoot) -- Acidic Web
	AddFlags(244949, IsCrowdControl) -- Felsilk Wrap

	-- Imonar the Soulhunter
	AddFlags(247641, IsCrowdControl) -- Stasis Trap
	AddFlags(255029, IsCrowdControl) -- Sleep Canister
	AddFlags(247565, IsCrowdControl) -- Slumber Gas
	AddFlags(250135, IsCrowdControl + IsImmune) -- Conflagration (-99% damage taken)
	AddFlags(248233, IsCrowdControl + IsImmune) -- Conflagration (-99% damage taken)

	-- Kin'garoth
	AddFlags(246516, IsCrowdControl + IsImmune) -- Apocalypse Protocol (-99% damage taken)

	-- The Coven of Shivarra
	AddFlags(253203, IsCrowdControl + IsImmune) -- Shivan Pact (-99% damage taken)
	AddFlags(249863, IsCrowdControl + IsImmune) -- Visage of the Titan
	AddFlags(256356, IsCrowdControl) -- Chilled Blood

	-- Aggramar
	AddFlags(244894, IsCrowdControl + IsImmune) -- Corrupt Aegis
	AddFlags(246014, IsCrowdControl) -- Searing Tempest
	AddFlags(255062, IsCrowdControl) -- Empowered Searing Tempest

	------------------------------------------------------------------------
	-- The Deaths of Chromie Scenario
	------------------------------------------------------------------------
	AddFlags(246941, IsCrowdControl) -- Looming Shadows
	AddFlags(245167, IsCrowdControl) -- Ignite
	AddFlags(248839, IsCrowdControl) -- Charge
	AddFlags(246211, IsCrowdControl) -- Shriek of the Graveborn
	AddFlags(247683, IsCrowdControl + IsRoot) -- Deep Freeze
	AddFlags(247684, IsCrowdControl) -- Deep Freeze
	AddFlags(244959, IsCrowdControl) -- Time Stop
	AddFlags(248516, IsCrowdControl) -- Sleep
	AddFlags(245169, IsCrowdControl + IsImmune) -- Reflective Shield
	AddFlags(248716, IsCrowdControl) -- Infernal Strike
	AddFlags(247730, IsCrowdControl + IsRoot) -- Faith's Fetters
	AddFlags(245822, IsCrowdControl) -- Inescapable Nightmare
	AddFlags(245126, IsCrowdControl + IsSilence) -- Soul Burn

	------------------------------------------------------------------------
	-- Legion Mythics
	------------------------------------------------------------------------
	-- The Arcway
	AddFlags(195804, IsCrowdControl) -- Quarantine
	AddFlags(203649, IsCrowdControl) -- Exterminate
	AddFlags(203957, IsCrowdControl) -- Time Lock
	AddFlags(211543, IsCrowdControl + IsRoot) -- Devour

	-- Black Rook Hold
	AddFlags(194960, IsCrowdControl) -- Soul Echoes
	AddFlags(197974, IsCrowdControl) -- Bonecrushing Strike
	AddFlags(199168, IsCrowdControl) -- Itchy!
	AddFlags(204954, IsCrowdControl) -- Cloud of Hypnosis
	AddFlags(199141, IsCrowdControl) -- Cloud of Hypnosis
	AddFlags(199097, IsCrowdControl) -- Cloud of Hypnosis
	AddFlags(214002, IsCrowdControl) -- Raven's Dive
	AddFlags(200261, IsCrowdControl) -- Bonebreaking Strike
	AddFlags(201070, IsCrowdControl) -- Dizzy
	AddFlags(221117, IsCrowdControl) -- Ghastly Wail
	AddFlags(222417, IsCrowdControl) -- Boulder Crush
	AddFlags(221838, IsCrowdControl) -- Disorienting Gas

	-- Court of Stars
	AddFlags(207278, IsCrowdControl + IsSnare) -- Arcane Lockdown
	AddFlags(207261, IsCrowdControl) -- Resonant Slash
	AddFlags(215204, IsCrowdControl) -- Hinder
	AddFlags(207979, IsCrowdControl) -- Shockwave
	AddFlags(224333, IsCrowdControl) -- Enveloping Winds
	AddFlags(209404, IsCrowdControl + IsSilence) -- Seal Magic
	AddFlags(209413, IsCrowdControl + IsSilence) -- Suppress
	AddFlags(209027, IsCrowdControl) -- Quelling Strike
	AddFlags(212773, IsCrowdControl) -- Subdue
	AddFlags(216000, IsCrowdControl) -- Mighty Stomp
	AddFlags(213233, IsCrowdControl) -- Uninvited Guest

	-- Return to Karazhan
	AddFlags(227567, IsCrowdControl) -- Knocked Down
	AddFlags(228215, IsCrowdControl) -- Severe Dusting
	AddFlags(227508, IsCrowdControl) -- Mass Repentance
	AddFlags(227545, IsCrowdControl) -- Mana Drain
	AddFlags(227909, IsCrowdControl) -- Ghost Trap
	AddFlags(228693, IsCrowdControl) -- Ghost Trap
	AddFlags(228837, IsCrowdControl) -- Bellowing Roar
	AddFlags(227592, IsCrowdControl) -- Frostbite
	AddFlags(228239, IsCrowdControl) -- Terrifying Wail
	AddFlags(241774, IsCrowdControl) -- Shield Smash
	AddFlags(230122, IsCrowdControl + IsSilence) -- Garrote - Silence
	AddFlags( 39331, IsCrowdControl + IsSilence) -- Game In Session
	AddFlags(227977, IsCrowdControl) -- Flashlight
	AddFlags(241799, IsCrowdControl) -- Seduction
	AddFlags(227917, IsCrowdControl) -- Poetry Slam
	AddFlags(230083, IsCrowdControl) -- Nullification
	AddFlags(229489, IsCrowdControl + IsImmune) -- Royalty (90% dmg reduction)

	-- Maw of Souls
	AddFlags(193364, IsCrowdControl) -- Screams of the Dead
	AddFlags(198551, IsCrowdControl) -- Fragment
	AddFlags(197653, IsCrowdControl) -- Knockdown
	AddFlags(198405, IsCrowdControl) -- Bone Chilling Scream
	AddFlags(193215, IsCrowdControl) -- Kvaldir Cage
	AddFlags(204057, IsCrowdControl) -- Kvaldir Cage
	AddFlags(204058, IsCrowdControl) -- Kvaldir Cage
	AddFlags(204059, IsCrowdControl) -- Kvaldir Cage
	AddFlags(204060, IsCrowdControl) -- Kvaldir Cage

	-- Vault of the Wardens
	AddFlags(202455, IsCrowdControl + IsImmune) -- Void Shield
	AddFlags(212565, IsCrowdControl) -- Inquisitive Stare
	AddFlags(225416, IsCrowdControl) -- Intercept
	AddFlags(  6726, IsCrowdControl + IsSilence) -- Silence
	AddFlags(201488, IsCrowdControl) -- Frightening Shout
	AddFlags(203774, IsCrowdControl + IsImmune) -- Focusing
	AddFlags(192517, IsCrowdControl) -- Brittle
	AddFlags(201523, IsCrowdControl) -- Brittle
	AddFlags(194323, IsCrowdControl) -- Petrified
	AddFlags(206387, IsCrowdControl) -- Steal Light
	AddFlags(197422, IsCrowdControl + IsImmune) -- Creeping Doom
	AddFlags(210138, IsCrowdControl) -- Fully Petrified
	AddFlags(202615, IsCrowdControl + IsRoot) -- Torment
	AddFlags(193069, IsCrowdControl) -- Nightmares
	AddFlags(191743, IsCrowdControl + IsSilence) -- Deafening Screech
	AddFlags(202658, IsCrowdControl) -- Drain
	AddFlags(193969, IsCrowdControl + IsRoot) -- Razors
	AddFlags(204282, IsCrowdControl) -- Dark Trap

	-- Eye of Azshara
	AddFlags(191975, IsCrowdControl) -- Impaling Spear
	AddFlags(191977, IsCrowdControl) -- Impaling Spear
	AddFlags(193597, IsCrowdControl) -- Static Nova
	AddFlags(192708, IsCrowdControl) -- Arcane Bomb
	AddFlags(195561, IsCrowdControl) -- Blinding Peck
	AddFlags(195129, IsCrowdControl) -- Thundering Stomp
	AddFlags(195253, IsCrowdControl) -- Imprisoning Bubble
	AddFlags(197144, IsCrowdControl + IsRoot) -- Hooked Net
	AddFlags(197105, IsCrowdControl) -- Polymorph: Fish
	AddFlags(195944, IsCrowdControl) -- Rising Fury

	-- Darkheart Thicket
	AddFlags(200329, IsCrowdControl) -- Overwhelming Terror
	AddFlags(200273, IsCrowdControl) -- Cowardice
	AddFlags(204246, IsCrowdControl) -- Tormenting Fear
	AddFlags(200631, IsCrowdControl) -- Unnerving Screech
	AddFlags(200771, IsCrowdControl) -- Propelling Charge
	AddFlags(199063, IsCrowdControl + IsRoot) -- Strangling Roots

	-- Halls of Valor
	AddFlags(198088, IsCrowdControl) -- Glowing Fragment
	AddFlags(215429, IsCrowdControl) -- Thunderstrike
	AddFlags(199340, IsCrowdControl) -- Bear Trap
	AddFlags(210749, IsCrowdControl) -- Static Storm

	-- Neltharion's Lair
	AddFlags(200672, IsCrowdControl) -- Crystal Cracked
	AddFlags(202181, IsCrowdControl) -- Stone Gaze
	AddFlags(193585, IsCrowdControl) -- Bound
	AddFlags(186616, IsCrowdControl) -- Petrified

	-- Cathedral of Eternal Night
	AddFlags(238678, IsCrowdControl + IsSilence) -- Stifling Satire
	AddFlags(238484, IsCrowdControl) -- Beguiling Biography
	AddFlags(242724, IsCrowdControl) -- Dread Scream
	AddFlags(239217, IsCrowdControl) -- Blinding Glare
	AddFlags(238583, IsCrowdControl + IsSilence) -- Devour Magic
	AddFlags(239156, IsCrowdControl) -- Book of Eternal Winter
	AddFlags(240556, IsCrowdControl + IsSilence) -- Tome of Everlasting Silence
	AddFlags(242792, IsCrowdControl) -- Vile Roots

	-- The Seat of the Triumvirate
	AddFlags(246913, IsCrowdControl + IsImmune) -- Void Phased
	AddFlags(244621, IsCrowdControl) -- Void Tear
	AddFlags(248831, IsCrowdControl) -- Dread Screech
	AddFlags(246026, IsCrowdControl) -- Void Trap
	AddFlags(245278, IsCrowdControl) -- Void Trap
	AddFlags(244751, IsCrowdControl) -- Howling Dark
	AddFlags(248804, IsCrowdControl + IsImmune) -- Dark Bulwark
	AddFlags(247816, IsCrowdControl) -- Backlash
	AddFlags(254020, IsCrowdControl + IsImmune) -- Darkened Shroud
	AddFlags(253952, IsCrowdControl) -- Terrifying Howl
	AddFlags(248298, IsCrowdControl + IsSilence) -- Screech
	AddFlags(245706, IsCrowdControl) -- Ruinous Strike
	AddFlags(248133, IsCrowdControl) -- Stygian Blast
end 

------------------------------------------------------------------------
------------------------------------------------------------------------
-- 						FOOD & FLASKS & RUNES 
------------------------------------------------------------------------
------------------------------------------------------------------------

-- Vantus Runes
------------------------------------------------------------------------
do 
	-- Battle For Azeroth
	AddFlags(285553, IsRune) -- Vantus Rune: Champion of the Light
	AddFlags(285557, IsRune) -- Vantus Rune: Conclave of the Chosen
	AddFlags(269271, IsRune) -- Vantus Rune: Fetid Devourer
	AddFlags(269275, IsRune) -- Vantus Rune: G'huun
	AddFlags(285554, IsRune) -- Vantus Rune: Grong
	AddFlags(289193, IsRune) -- Vantus Rune: Grong the Revenant
	AddFlags(285559, IsRune) -- Vantus Rune: High Tinker Mekkatorque
	AddFlags(285555, IsRune) -- Vantus Rune: Jadefire Masters
	AddFlags(289195, IsRune) -- Vantus Rune: Jadefire Masters
	AddFlags(285558, IsRune) -- Vantus Rune: King Rastakhan
	AddFlags(285561, IsRune) -- Vantus Rune: Lady Jaina Proudmoore
	AddFlags(269269, IsRune) -- Vantus Rune: MOTHER
	AddFlags(269274, IsRune) -- Vantus Rune: Mythrax
	AddFlags(285556, IsRune) -- Vantus Rune: Opulence
	AddFlags(285560, IsRune) -- Vantus Rune: Stormwall Blockade
	AddFlags(269268, IsRune) -- Vantus Rune: Taloc
	AddFlags(269272, IsRune) -- Vantus Rune: Vectis
	AddFlags(269270, IsRune) -- Vantus Rune: Zek'voz
	AddFlags(269273, IsRune) -- Vantus Rune: Zul
end 

-- Flasks
------------------------------------------------------------------------
do 
	-- Battle For Azeroth
	AddFlags(251837, IsFlask) -- Flask of Endless Fathoms
	AddFlags(251839, IsFlask) -- Flask of the Undertow
	AddFlags(251838, IsFlask) -- Flask of the Vast Horizon
	AddFlags(251836, IsFlask) -- Flask of the Currents
end 

-- Well Fed!
------------------------------------------------------------------------
do 
	-- *missing most BfA ones, will add a copout here. 
	Auras[ 19705] = IsFood
	Auras[ 19706] = IsFood
	Auras[ 19708] = IsFood
	Auras[ 19709] = IsFood
	Auras[ 19710] = IsFood
	Auras[ 19711] = IsFood
	Auras[ 24799] = IsFood
	Auras[ 24870] = IsFood
	Auras[ 25694] = IsFood
	Auras[ 25941] = IsFood
	Auras[ 33254] = IsFood
	Auras[ 33256] = IsFood
	Auras[ 33257] = IsFood
	Auras[ 33259] = IsFood
	Auras[ 33261] = IsFood
	Auras[ 33263] = IsFood
	Auras[ 33265] = IsFood
	Auras[ 33268] = IsFood
	Auras[ 33272] = IsFood
	Auras[ 35272] = IsFood
	Auras[ 42293] = IsFood
	Auras[ 43764] = IsFood
	Auras[ 45245] = IsFood
	Auras[ 45619] = IsFood
	Auras[ 46682] = IsFood
	Auras[ 46687] = IsFood
	Auras[ 46899] = IsFood
	Auras[ 53284] = IsFood
	Auras[ 57079] = IsFood
	Auras[ 57097] = IsFood
	Auras[ 57100] = IsFood
	Auras[ 57102] = IsFood
	Auras[ 57107] = IsFood
	Auras[ 57111] = IsFood
	Auras[ 57139] = IsFood
	Auras[ 57286] = IsFood
	Auras[ 57288] = IsFood
	Auras[ 57291] = IsFood
	Auras[ 57294] = IsFood
	Auras[ 57325] = IsFood
	Auras[ 57327] = IsFood
	Auras[ 57329] = IsFood
	Auras[ 57332] = IsFood
	Auras[ 57334] = IsFood
	Auras[ 57356] = IsFood
	Auras[ 57358] = IsFood
	Auras[ 57360] = IsFood
	Auras[ 57363] = IsFood
	Auras[ 57365] = IsFood
	Auras[ 57367] = IsFood
	Auras[ 57371] = IsFood
	Auras[ 57373] = IsFood
	Auras[ 57399] = IsFood
	Auras[ 59230] = IsFood
	Auras[ 62349] = IsFood
	Auras[ 64057] = IsFood
	Auras[ 65410] = IsFood
	Auras[ 65412] = IsFood
	Auras[ 65414] = IsFood
	Auras[ 65415] = IsFood
	Auras[ 65416] = IsFood
	Auras[ 66623] = IsFood
	Auras[ 87545] = IsFood
	Auras[ 87546] = IsFood
	Auras[ 87547] = IsFood
	Auras[ 87548] = IsFood
	Auras[ 87549] = IsFood
	Auras[ 87550] = IsFood
	Auras[ 87551] = IsFood
	Auras[ 87552] = IsFood
	Auras[ 87554] = IsFood
	Auras[ 87555] = IsFood
	Auras[ 87556] = IsFood
	Auras[ 87557] = IsFood
	Auras[ 87558] = IsFood
	Auras[ 87559] = IsFood
	Auras[ 87560] = IsFood
	Auras[ 87561] = IsFood
	Auras[ 87562] = IsFood
	Auras[ 87563] = IsFood
	Auras[ 87564] = IsFood
	Auras[ 87565] = IsFood
	Auras[ 87634] = IsFood
	Auras[ 87635] = IsFood
	Auras[ 87697] = IsFood
	Auras[ 87699] = IsFood
	Auras[ 99305] = IsFood
	Auras[ 99478] = IsFood
	Auras[100368] = IsFood
	Auras[100373] = IsFood
	Auras[100375] = IsFood
	Auras[100377] = IsFood
	Auras[104264] = IsFood
	Auras[104267] = IsFood
	Auras[104271] = IsFood
	Auras[104272] = IsFood
	Auras[104273] = IsFood
	Auras[104274] = IsFood
	Auras[104275] = IsFood
	Auras[104276] = IsFood
	Auras[104277] = IsFood
	Auras[104278] = IsFood
	Auras[104279] = IsFood
	Auras[104280] = IsFood
	Auras[104281] = IsFood
	Auras[104282] = IsFood
	Auras[104283] = IsFood
	Auras[105226] = IsFood
	Auras[108028] = IsFood
	Auras[108031] = IsFood
	Auras[108032] = IsFood
	Auras[110645] = IsFood
	Auras[114733] = IsFood
	Auras[124151] = IsFood
	Auras[124210] = IsFood
	Auras[124211] = IsFood
	Auras[124212] = IsFood
	Auras[124213] = IsFood
	Auras[124214] = IsFood
	Auras[124215] = IsFood
	Auras[124216] = IsFood
	Auras[124217] = IsFood
	Auras[124218] = IsFood
	Auras[124219] = IsFood
	Auras[124220] = IsFood
	Auras[124221] = IsFood
	Auras[125070] = IsFood
	Auras[125071] = IsFood
	Auras[125102] = IsFood
	Auras[125104] = IsFood
	Auras[125106] = IsFood
	Auras[125108] = IsFood
	Auras[125113] = IsFood
	Auras[125115] = IsFood
	Auras[130342] = IsFood
	Auras[130343] = IsFood
	Auras[130344] = IsFood
	Auras[130345] = IsFood
	Auras[130346] = IsFood
	Auras[130347] = IsFood
	Auras[130348] = IsFood
	Auras[130350] = IsFood
	Auras[130351] = IsFood
	Auras[130352] = IsFood
	Auras[130353] = IsFood
	Auras[130354] = IsFood
	Auras[130355] = IsFood
	Auras[130356] = IsFood
	Auras[131828] = IsFood
	Auras[133428] = IsFood
	Auras[133593] = IsFood
	Auras[133594] = IsFood
	Auras[133595] = IsFood
	Auras[133596] = IsFood
	Auras[134094] = IsFood
	Auras[134219] = IsFood
	Auras[134506] = IsFood
	Auras[134712] = IsFood
	Auras[134887] = IsFood
	Auras[135076] = IsFood
	Auras[135440] = IsFood
	Auras[140410] = IsFood
	Auras[145304] = IsFood
	Auras[146804] = IsFood
	Auras[146805] = IsFood
	Auras[146806] = IsFood
	Auras[146807] = IsFood
	Auras[146808] = IsFood
	Auras[146809] = IsFood
	Auras[147312] = IsFood
	Auras[159372] = IsFood
	Auras[160600] = IsFood
	Auras[160722] = IsFood
	Auras[160724] = IsFood
	Auras[160726] = IsFood
	Auras[160778] = IsFood
	Auras[160793] = IsFood
	Auras[160832] = IsFood
	Auras[160839] = IsFood
	Auras[160883] = IsFood
	Auras[160885] = IsFood
	Auras[160889] = IsFood
	Auras[160893] = IsFood
	Auras[160895] = IsFood
	Auras[160897] = IsFood
	Auras[160900] = IsFood
	Auras[160902] = IsFood
	Auras[165802] = IsFood
	Auras[168349] = IsFood
	Auras[168475] = IsFood
	Auras[174062] = IsFood
	Auras[174077] = IsFood
	Auras[174078] = IsFood
	Auras[174079] = IsFood
	Auras[174080] = IsFood
	Auras[175218] = IsFood
	Auras[175219] = IsFood
	Auras[175220] = IsFood
	Auras[175222] = IsFood
	Auras[175223] = IsFood
	Auras[175784] = IsFood
	Auras[175785] = IsFood
	Auras[177931] = IsFood
	Auras[180745] = IsFood
	Auras[180746] = IsFood
	Auras[180747] = IsFood
	Auras[180748] = IsFood
	Auras[180749] = IsFood
	Auras[180750] = IsFood
	Auras[185736] = IsFood
	Auras[185786] = IsFood
	Auras[188534] = IsFood
	Auras[192004] = IsFood
	Auras[201223] = IsFood
	Auras[201330] = IsFood
	Auras[201332] = IsFood
	Auras[201334] = IsFood
	Auras[201336] = IsFood
	Auras[201350] = IsFood
	Auras[201634] = IsFood
	Auras[201635] = IsFood
	Auras[201636] = IsFood
	Auras[201637] = IsFood
	Auras[201638] = IsFood
	Auras[201639] = IsFood
	Auras[201640] = IsFood
	Auras[201641] = IsFood
	Auras[201679] = IsFood
	Auras[201695] = IsFood
	Auras[207076] = IsFood
	Auras[215607] = IsFood
	Auras[216343] = IsFood
	Auras[216353] = IsFood
	Auras[216828] = IsFood
	Auras[225597] = IsFood
	Auras[225598] = IsFood
	Auras[225599] = IsFood
	Auras[225600] = IsFood
	Auras[225601] = IsFood
	Auras[225602] = IsFood
	Auras[225603] = IsFood
	Auras[225604] = IsFood
	Auras[225605] = IsFood
	Auras[225606] = IsFood
	Auras[226805] = IsFood
	Auras[226807] = IsFood
	Auras[230061] = IsFood
	Auras[251234] = IsFood
	Auras[251247] = IsFood
	Auras[251248] = IsFood
	Auras[251261] = IsFood
	Auras[262571] = IsFood
end 

------------------------------------------------------------------------
------------------------------------------------------------------------
-- 							CLASSES
------------------------------------------------------------------------
------------------------------------------------------------------------

-- Death Knight
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags( 48707, IsDeathKnight) -- Anti-Magic Shell
	AddFlags(221562, IsDeathKnight) -- Asphyxiate -- NEEDS CHECK, 108194
	AddFlags(206977, IsDeathKnight) -- Blood Mirror
	AddFlags( 55078, IsDeathKnight) -- Blood Plague
	AddFlags(195181, IsDeathKnight) -- Bone Shield
	AddFlags( 45524, IsDeathKnight) -- Chains of Ice
	AddFlags(111673, IsDeathKnight) -- Control Undead
	AddFlags(207319, IsDeathKnight) -- Corpse Shield
	AddFlags(101568, IsDeathKnight) -- Dark Succor
	AddFlags(194310, IsDeathKnight) -- Festering Wound
	AddFlags(190780, IsDeathKnight) -- Frost Breath
	AddFlags( 55095, IsDeathKnight) -- Frost Fever
	AddFlags(206930, IsDeathKnight) -- Heart Strike
	AddFlags( 48792, IsDeathKnight) -- Icebound Fortitude
	AddFlags(194879, IsDeathKnight) -- Icy Talons
	AddFlags( 51124, IsDeathKnight) -- Killing Machine
	AddFlags(206940, IsDeathKnight) -- Mark of Blood
	AddFlags(216974, IsDeathKnight) -- Necrosis
	AddFlags(207256, IsDeathKnight) -- Obliteration
	AddFlags(219788, IsDeathKnight) -- Ossuary
	AddFlags(  3714, IsDeathKnight) -- Path of Frost -- TODO: show only OOC
	AddFlags( 51271, IsDeathKnight) -- Pillar of Frost
	AddFlags(196770, IsDeathKnight) -- Remorseless Winter (self)
	AddFlags(211793, IsDeathKnight) -- Remorseless Winter (slow)
	AddFlags( 59052, IsDeathKnight) -- Rime
	AddFlags(130736, IsDeathKnight) -- Soul Reaper
	AddFlags( 55233, IsDeathKnight) -- Vampiric Blood
	AddFlags(191587, IsDeathKnight) -- Virulent Plague
	AddFlags(211794, IsDeathKnight) -- Winter is Coming
	AddFlags(212552, IsDeathKnight) -- Wraith Walk

	-- Talents
	AddFlags(116888, IsDeathKnight) -- Shroud of Purgatory (from Purgatory)
end 

-- Demon Hunter
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags(207709, IsDemonHunter) -- Blade Turning
	AddFlags(207690, IsDemonHunter) -- Bloodlet
	AddFlags(212800, IsDemonHunter) -- Blur
	AddFlags(163073, IsDemonHunter) -- Demon Soul (Vengeance)
	AddFlags(208195, IsDemonHunter) -- Demon Soul (Havoc) NEEDS CHECK!
	AddFlags(203819, IsDemonHunter) -- Demon Spikes
	AddFlags(227330, IsDemonHunter) -- Gluttony
	AddFlags(218256, IsDemonHunter) -- Empower Wards
	AddFlags(207744, IsDemonHunter) -- Fiery Brand
	AddFlags(247456, IsDemonHunter) -- Frailty
	AddFlags(162264, IsDemonHunter) -- Metamorphosis
	AddFlags(207810, IsDemonHunter) -- Nether Bond
	AddFlags(196555, IsDemonHunter) -- Netherwalk
	AddFlags(204598, IsDemonHunter) -- Sigil of Flame 
	AddFlags(203981, IsDemonHunter) -- Soul Fragments

	-- Talents
	AddFlags(206491, IsDemonHunter) -- Nemesis (missing caster)
end 

-- Druid
------------------------------------------------------------------------
do 
	-- Buffs
	AddFlags( 29166, IsDruid) -- Innervate
	AddFlags(102342, IsDruid) -- Ironbark
	AddFlags(106898, IsDruid) -- Stampeding Roar

	-- Abilities
	AddFlags(  1850, IsDruid) -- Dash
	AddFlags( 22812, IsDruid) -- Barkskin
	AddFlags(106951, IsDruid) -- Berserk
	AddFlags(202739, IsDruid) -- Blessing of An'she (Blessing of the Ancients)
	AddFlags(202737, IsDruid) -- Blessing of Elune (Blessing of the Ancients)
	AddFlags(145152, IsDruid) -- Bloodtalons
	AddFlags(155835, IsDruid) -- Bristling Fur
	AddFlags(135700, IsDruid) -- Clearcasting (Omen of Clarity) (Feral)
	AddFlags( 16870, IsDruid) -- Clearcasting (Omen of Clarity) (Restoration)
	AddFlags(202060, IsDruid) -- Elune's Guidance
	AddFlags( 22842, IsDruid) -- Frenzied Regeneration
	AddFlags(202770, IsDruid) -- Fury of Elune
	AddFlags(213709, IsDruid) -- Galactic Guardian
	AddFlags(213680, IsDruid) -- Guardian of Elune
	AddFlags(    99, IsDruid) -- Incapacitating Roar
	AddFlags(102560, IsDruid) -- Incarnation: Chosen of Elune
	AddFlags(102558, IsDruid) -- Incarnation: Guardian of Ursoc
	AddFlags(102543, IsDruid) -- Incarnation: King of the Jungle
	AddFlags(192081, IsDruid) -- Ironfur
	AddFlags(164547, IsDruid) -- Lunar Empowerment
	AddFlags(203123, IsDruid) -- Maim
	AddFlags(192083, IsDruid) -- Mark of Ursol
	AddFlags( 33763, IsDruid) -- Lifebloom
	AddFlags(164812, IsDruid) -- Moonfire -- NEEDS CHECK, 8921
	AddFlags(155625, IsDruid) -- Moonfire (Cat Form)
	AddFlags( 69369, IsDruid) -- Predatory Swiftness
	AddFlags(158792, IsDruid) -- Pulverize
	AddFlags(155722, IsDruid) -- Rake
	AddFlags(  8936, IsDruid) -- Regrowth
	AddFlags(   774, IsDruid) -- Rejuvenation
	AddFlags(  1079, IsDruid) -- Rip
	AddFlags( 52610, IsDruid) -- Savage Roar
	AddFlags( 78675, IsDruid) -- Solar Beam
	AddFlags(164545, IsDruid) -- Solar Empowerment
	AddFlags(191034, IsDruid) -- Starfire
	AddFlags(202347, IsDruid) -- Stellar Flare
	AddFlags(164815, IsDruid) -- Sunfire -- NEEDS CHECK, 93402
	AddFlags( 61336, IsDruid) -- Survival Instincts
	AddFlags(192090, IsDruid) -- Thrash (Bear) -- NEEDS CHECK
	AddFlags(106830, IsDruid) -- Thrash (Cat)
	AddFlags(  5217, IsDruid) -- Tiger's Fury
	AddFlags(102793, IsDruid) -- Ursol's Vortex
	AddFlags(202425, IsDruid) -- Warrior of Elune
	AddFlags( 48438, IsDruid) -- Wild Growth

	-- Talents
end 

-- Hunter
------------------------------------------------------------------------
do 
	-- Abilities
	AddFlags(131894, IsHunter) -- A Murder of Crows (Beast Mastery, Marksmanship)
	AddFlags(206505, IsHunter) -- A Murder of Crows (Survival)
	AddFlags(186257, IsHunter) -- Aspect of the Cheetah
	AddFlags(186289, IsHunter) -- Aspect of the Eagle
	AddFlags(186265, IsHunter) -- Aspect of the Turtle
	AddFlags(193530, IsHunter) -- Aspect of the Wild
	AddFlags(217200, IsHunter) -- Barbed Shot (8.0.1, previously Dire Frenzy)
	AddFlags( 19574, IsHunter) -- Bestial Wrath
	AddFlags(117526, IsHunter) -- Binding Shot (stun)
	AddFlags(117405, IsHunter) -- Binding Shot (tether)
	AddFlags(194279, IsHunter) -- Caltrops
	AddFlags(199483, IsHunter) -- Camouflage
	AddFlags(  5116, IsHunter) -- Concussive Shot
	AddFlags( 13812, IsHunter) -- Explosive Trap -- NEEDS CHECK
	AddFlags(  5384, IsHunter) -- Feign Death
	AddFlags(  3355, IsHunter) -- Freezing Trap
	AddFlags(194594, IsHunter) -- Lock and Load
	AddFlags( 34477, IsHunter) -- Misdirection
	AddFlags(201081, IsHunter) -- Mok'Nathal Tactics
	AddFlags(190931, IsHunter) -- Mongoose Fury
	AddFlags(118922, IsHunter) -- Posthaste
	AddFlags(200108, IsHunter) -- Ranger's Net
	AddFlags(118253, IsHunter) -- Serpent Sting
	AddFlags(259491, IsHunter) -- Serpent Sting (8.0.1 version) 
	AddFlags(135299, IsHunter) -- Tar Trap
	AddFlags(193526, IsHunter) -- Trueshot
	AddFlags(187131, IsHunter) -- Vulnerable
	AddFlags(269747, IsHunter) -- Wildfire Bomb (8.0.1)

	-- Talents
end 

-- Mage
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags( 12042, IsMage) -- Arcane Power
	AddFlags(157981, IsMage) -- Blast Wave
	AddFlags(108843, IsMage) -- Blazing Speed
	AddFlags(205766, IsMage) -- Bone Chilling
	AddFlags(263725, IsMage) -- Clearcasting
	AddFlags(190319, IsMage) -- Combustion
	AddFlags(   120, IsMage) -- Cone of Cold
	AddFlags( 31661, IsMage) -- Dragon's Breath
	AddFlags(210134, IsMage) -- Erosion
	AddFlags(126084, IsMage) -- Fingers of Frost -- NEEDS CHECK 44544
	AddFlags(  2120, IsMage) -- Flamestrike
	AddFlags(112948, IsMage) -- Frost Bomb
	AddFlags(   122, IsMage) -- Frost Nova
	AddFlags(228600, IsMage) -- Glacial Spike
	AddFlags(110960, IsMage) -- Greater Invisibility
	AddFlags(195283, IsMage) -- Hot Streak
	AddFlags( 11426, IsMage) -- Ice Barrier
	AddFlags( 45438, IsMage) -- Ice Block
	AddFlags(108839, IsMage) -- Ice Floes
	AddFlags( 12472, IsMage) -- Icy Veins
	AddFlags( 12654, IsMage) -- Ignite
	AddFlags(    66, IsMage) -- Invisibility
	AddFlags( 44457, IsMage) -- Living Bomb
	AddFlags(114923, IsMage) -- Nether Tempest
	AddFlags(205025, IsMage) -- Presence of Mind
	AddFlags(198924, IsMage) -- Quickening
	AddFlags( 82691, IsMage) -- Ring of Frost
	AddFlags( 31589, IsMage) -- Slow
	AddFlags(   130, IsMage) -- Slow Fall

	-- Talents
end 

-- Monk
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags(228563, IsMonk) -- Blackout Combo
	AddFlags(115181, IsMonk) -- Breath of Fire
	AddFlags(119085, IsMonk) -- Chi Torpedo
	AddFlags(122278, IsMonk) -- Dampen Harm
	AddFlags(122783, IsMonk) -- Diffuse Magic
	AddFlags(116095, IsMonk) -- Disable
	AddFlags(196723, IsMonk) -- Dizzying Kicks
	AddFlags(124682, IsMonk) -- Enveloping Mist
	AddFlags(191840, IsMonk) -- Essence Font
	AddFlags(196739, IsMonk) -- Elusive Dance
	AddFlags(196608, IsMonk) -- Eye of the Tiger
	AddFlags(120954, IsMonk) -- Fortifying Brew
	AddFlags(124273, IsMonk) -- Heavy Stagger
	AddFlags(196741, IsMonk) -- Hit Combo
	AddFlags(215479, IsMonk) -- Ironskin Brew
	AddFlags(121253, IsMonk) -- Keg Smash
	AddFlags(119381, IsMonk) -- Leg Sweep
	AddFlags(116849, IsMonk) -- Life Cocoon
	AddFlags(197919, IsMonk) -- Lifecycles (Enveloping Mist)
	AddFlags(197916, IsMonk) -- Lifecycles (Vivify)
	AddFlags(124275, IsMonk) -- Light Stagger
	AddFlags(197908, IsMonk) -- Mana Tea
	AddFlags(124274, IsMonk) -- Moderate Stagger
	AddFlags(115078, IsMonk) -- Paralysis
	AddFlags(129914, IsMonk) -- Power Strikes
	AddFlags(196725, IsMonk) -- Refreshing Jade Wind
	AddFlags(119611, IsMonk) -- Renewing Mist -- NEEDS CHECK 144080
	AddFlags(116844, IsMonk) -- Ring of Peace
	AddFlags(116847, IsMonk) -- Rushing Jade Wind
	AddFlags(152173, IsMonk) -- Serenity
	AddFlags(198909, IsMonk) -- Song of Chi-Ji
	AddFlags(196733, IsMonk) -- Special Delivery -- NEEDS CHECK
	AddFlags(202090, IsMonk) -- Teachings of the Monastery
	AddFlags(116680, IsMonk) -- Thunder Focus Tea
	AddFlags(116841, IsMonk) -- Tiger's Lust
	AddFlags(115080, IsMonk) -- Touch of Death
	AddFlags(122470, IsMonk) -- Touch of Karma
	AddFlags(115176, IsMonk) -- Zen Meditation

	-- Talents
	AddFlags(116768, IsMonk) -- Blackout Kick! (from Combo Breaker)
end 

-- Paladin
------------------------------------------------------------------------
do
	-- Buffs
	AddFlags(257771, IsPaladin) -- Forbearance
	AddFlags( 53563, IsPaladin) -- Beacon of Light
	AddFlags(  1044, IsPaladin) -- Blessing of Freedom
	AddFlags(  1022, IsPaladin) -- Blessing of Protection
	AddFlags(  6940, IsPaladin) -- Blessing of Sacrifice
	AddFlags(204013, IsPaladin) -- Blessing of Salvation
	AddFlags(204018, IsPaladin) -- Blessing of Spellwarding

	-- Abilities
	AddFlags(204150, IsPaladin) -- Aegis of Light
	AddFlags( 31850, IsPaladin) -- Ardent Defender
	AddFlags( 31842, IsPaladin) -- Avenging Wrath (Holy)
	AddFlags( 31884, IsPaladin) -- Avenging Wrath (Protection, Retribution)
	AddFlags(105421, IsPaladin) -- Blinding Light
	AddFlags(224668, IsPaladin) -- Crusade
	AddFlags(216411, IsPaladin) -- Divine Purpose (Holy - Holy Shock)
	AddFlags(216413, IsPaladin) -- Divine Purpose (Holy - Light of Dawn)
	AddFlags(223819, IsPaladin) -- Divine Purpose (Retribution)
	AddFlags(   642, IsPaladin) -- Divine Shield
	AddFlags(220509, IsPaladin) -- Divine Steed
	AddFlags(221883, IsPaladin) -- Divine Steed
	AddFlags(221886, IsPaladin) -- Divine Steed (Blood Elf)
	AddFlags(221887, IsPaladin) -- Divine Steed (Draenei)
	AddFlags(221885, IsPaladin) -- Divine Steed (Tauren)
	AddFlags(205191, IsPaladin) -- Eye for an Eye
	AddFlags(223316, IsPaladin) -- Fervent Light
	AddFlags( 86659, IsPaladin) -- Guardian of Ancient Kings
	AddFlags(   853, IsPaladin) -- Hammer of Justice
	AddFlags(183218, IsPaladin) -- Hand of Hindrance
	AddFlags(105809, IsPaladin) -- Holy Avenger
	AddFlags( 54149, IsPaladin) -- Infusion of Light
	AddFlags(183436, IsPaladin) -- Retribution
	AddFlags(214202, IsPaladin) -- Rule of Law
	AddFlags(202273, IsPaladin) -- Seal of Light
	AddFlags(152262, IsPaladin) -- Seraphim
	AddFlags(132403, IsPaladin) -- Shield of the Righteous
	AddFlags(184662, IsPaladin) -- Shield of Vengeance
	AddFlags(209785, IsPaladin) -- The Fires of Justice

	-- Talents
end 

-- Priest
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags(194384, IsPriest) -- Atonement
	AddFlags( 47585, IsPriest) -- Disperson
	AddFlags(   586, IsPriest) -- Fade
	AddFlags( 47788, IsPriest) -- Guardian Spirit
	AddFlags( 14914, IsPriest) -- Holy Fire
	AddFlags(200196, IsPriest) -- Holy Word: Chastise
	AddFlags(  1706, IsPriest) -- Levitate
	AddFlags(   605, IsPriest) -- Mind Control
	AddFlags( 33206, IsPriest) -- Pain Suppression
	AddFlags( 81782, IsPriest) -- Power Word: Barrier
	AddFlags(    17, IsPriest) -- Power Word: Shield
	AddFlags( 41635, IsPriest) -- Prayer of Mending
	AddFlags(  8122, IsPriest) -- Psychic Scream
	AddFlags( 47536, IsPriest) -- Rapture
	AddFlags(   139, IsPriest) -- Renew
	AddFlags(187464, IsPriest) -- Shadow Mend
	AddFlags(   589, IsPriest) -- Shadow Word: Pain
	AddFlags( 15487, IsPriest) -- Silence
	AddFlags(208772, IsPriest) -- Smite
	AddFlags( 15286, IsPriest) -- Vampiric Embrace
	AddFlags( 34914, IsPriest) -- Vampiric Touch
	AddFlags(227386, IsPriest) -- Voidform -- NEEDS CHECK

	-- Talents
	AddFlags(200183, IsPriest) -- Apotheosis
	AddFlags(214121, IsPriest) -- Body and Mind
	AddFlags(152118, IsPriest) -- Clarity of Will
	AddFlags( 19236, IsPriest) -- Desperate Prayer
	AddFlags(197030, IsPriest) -- Divinity
	AddFlags(205369, IsPriest) -- Mind Bomb
	AddFlags(226943, IsPriest) -- Mind Bomb (stun)
	AddFlags(204213, IsPriest) -- Purge the Wicked
	AddFlags(214621, IsPriest) -- Schism
	AddFlags(219521, IsPriest) -- Shadow Covenant
	AddFlags(124430, IsPriest) -- Shadowy Insight
	AddFlags(204263, IsPriest) -- Shining Force
	AddFlags(114255, IsPriest) -- Surge of Light -- NEEDS CHECK, 128654
	AddFlags(123254, IsPriest) -- Twist of Fate
end 

-- Rogue
------------------------------------------------------------------------
do 
	-- Abilities
	AddFlags( 13750, IsRogue) -- Adrenaline Rush
	AddFlags( 13877, IsRogue) -- Blade Flurry
	AddFlags(199740, IsRogue) -- Bribe
	AddFlags(  1833, IsRogue) -- Cheap Shot
	AddFlags( 31224, IsRogue) -- Cloak of Shadows
	AddFlags(  3409, IsRogue) -- Crippling Poison (debuff)
	AddFlags(  2818, IsRogue) -- Deadly Poison (debuff)
	AddFlags(  5277, IsRogue) -- Evasion
	AddFlags(  1966, IsRogue) -- Feint
	AddFlags(   703, IsRogue) -- Garrote
	AddFlags(  1776, IsRogue) -- Gouge
	AddFlags(   408, IsRogue) -- Kidney Shot
	AddFlags(195452, IsRogue) -- Nightblade
	AddFlags(185763, IsRogue) -- Pistol Shot
	AddFlags(199754, IsRogue) -- Riposte
	AddFlags(193356, IsRogue) -- Roll the Bones - Broadsides
	AddFlags(199600, IsRogue) -- Roll the Bones - Buried Treasure
	AddFlags(193358, IsRogue) -- Roll the Bones - Grand Melee
	AddFlags(199603, IsRogue) -- Roll the Bones - Jolly Roger
	AddFlags(193357, IsRogue) -- Roll the Bones - Shark Infested Waters
	AddFlags(193359, IsRogue) -- Roll the Bones - True Bearing
	AddFlags(  1943, IsRogue) -- Rupture
	AddFlags(121471, IsRogue) -- Shadow Blades
	AddFlags(185422, IsRogue) -- Shadow Dance
	AddFlags( 36554, IsRogue) -- Shadowstep
	AddFlags(  2983, IsRogue) -- Sprint
	AddFlags(  1784, IsRogue) -- Stealth
	AddFlags(212283, IsRogue) -- Symbols of Death
	AddFlags( 57934, IsRogue) -- Tricks of the Trade
	AddFlags(  1856, IsRogue) -- Vanish
	AddFlags( 79140, IsRogue) -- Vendetta
	--AddFlags(  8680, IsRogue) -- Wound Poison -- who cares?

	-- Talents
	AddFlags(200803, IsRogue) -- Agonizing Poison
	AddFlags(196937, IsRogue) -- Ghostly Strike
	AddFlags( 16511, IsRogue) -- Hemorrhage
	AddFlags(135345, IsRogue) -- Internal Bleeding
	AddFlags( 51690, IsRogue) -- Killing Spree
	AddFlags(137619, IsRogue) -- Marked for Death
	AddFlags(  5171, IsRogue) -- Slice and Dice
end 

-- Shaman
------------------------------------------------------------------------
do 
	-- Abilities
	AddFlags(108281, IsShaman) -- Ancestral Guidance
	AddFlags(108271, IsShaman) -- Astral Shift
	AddFlags(187878, IsShaman) -- Crash Lightning
	AddFlags(188089, IsShaman) -- Earthen Spike -- 10s duration on a 20s cooldown
	--AddFlags(118522, IsShaman) -- Elemental Blast: Critical Strike -- 10s duration on a 12s cooldown
	--AddFlags(173183, IsShaman) -- Elemental Blast: Haste -- 10s duration on a 12s cooldown
	--AddFlags(173184, IsShaman) -- Elemental Blast: Mastery -- 10s duration on a 12s cooldown
	AddFlags( 16246, IsShaman) -- Elemental Focus
	AddFlags(188838, IsShaman) -- Flame Shock (restoration)
	AddFlags(188389, IsShaman) -- Flame Shock
	AddFlags(194084, IsShaman) -- Flametongue
	AddFlags(196840, IsShaman) -- Frost Shock
	AddFlags(196834, IsShaman) -- Frostbrand
	AddFlags( 73920, IsShaman) -- Healing Rain
	AddFlags(215785, IsShaman) -- Hot Hand
	AddFlags(210714, IsShaman) -- Icefury
	AddFlags(202004, IsShaman) -- Landslide
	AddFlags( 77756, IsShaman) -- Lava Surge
	AddFlags(197209, IsShaman) -- Lightning Rod -- NEEDS CHECK
	AddFlags( 61295, IsShaman) -- Riptide
	AddFlags(268429, IsShaman) -- Searing Assault
	AddFlags( 98007, IsShaman) -- Spirit Link Totem
	AddFlags( 58875, IsShaman) -- Spirit Walk
	AddFlags( 79206, IsShaman) -- Spiritwalker's Grace
	--AddFlags(201846, IsShaman) -- Stormbringer -- see spell alert overlay, action button proc glow
	AddFlags( 51490, IsShaman) -- Thunderstorm
	AddFlags( 53390, IsShaman) -- Tidal Waves
	--AddFlags(   546, IsShaman) -- Water Walking -- TODO: show only OOC
	--AddFlags(201898, IsShaman) -- Windsong -- 20s duration on a 45s cooldown

	-- Talents
	AddFlags(114050, IsShaman) -- Ascendance (Elemental)
	AddFlags(114051, IsShaman) -- Ascendance (Enhancement)
	AddFlags(114052, IsShaman) -- Ascendance (Restoration)
	AddFlags(218825, IsShaman) -- Boulderfist
	AddFlags( 64695, IsShaman) -- Earthgrab (Totem) -- NEEDS CHECK
	AddFlags(135621, IsShaman) -- Static Charge (Lightning Surge Totem) -- NEEDS CHECK
	AddFlags(192082, IsShaman) -- Wind Rush (Totem)
end 

-- Warlock
------------------------------------------------------------------------
do
	-- Abilities
	AddFlags(   980, IsWarlock) -- Agony
	AddFlags(117828, IsWarlock) -- Backdraft
	AddFlags(111400, IsWarlock) -- Burning Rush
	AddFlags(146739, IsWarlock) -- Corruption
	AddFlags(108416, IsWarlock) -- Dark Pact
	AddFlags(205146, IsWarlock) -- Demonic Calling
	AddFlags( 48018, IsWarlock) -- Demonic Circle -- TODO show on the side as a separate thingy
	AddFlags(193396, IsWarlock) -- Demonic Empowerment
	AddFlags(171982, IsWarlock) -- Demonic Synergy -- too passive?
	AddFlags(   603, IsWarlock) -- Doom
	AddFlags(  1098, IsWarlock) -- Enslave Demon
	AddFlags(196414, IsWarlock) -- Eradication
	AddFlags( 48181, IsWarlock) -- Haunt -- NEEDS CHECK, 171788, 183357
	AddFlags( 80240, IsWarlock) -- Havoc
	AddFlags(228312, IsWarlock) -- Immolate -- NEEDS CHECK
	AddFlags(  6789, IsWarlock) -- Mortal Coil
	AddFlags(205179, IsWarlock) -- Phantom Singularity
	AddFlags(196674, IsWarlock) -- Planeswalker
	AddFlags(  5740, IsWarlock) -- Rain of Fire
	AddFlags( 27243, IsWarlock) -- Seed of Corruption
	AddFlags(205181, IsWarlock) -- Shadowflame
	AddFlags( 30283, IsWarlock) -- Shadowfury
	AddFlags( 63106, IsWarlock) -- Siphon Life
	AddFlags(205178, IsWarlock) -- Soul Effigy
	AddFlags(196098, IsWarlock) -- Soul Harvest
	--AddFlags( 20707, IsWarlock) -- Soulstone -- OOC
	--AddFlags(  5697, IsWarlock) -- Unending Breath -- OOC
	AddFlags(104773, IsWarlock) -- Unending Resolve
	AddFlags( 30108, IsWarlock) -- Unstable Affliction

	-- Talents
end

-- Warrior
------------------------------------------------------------------------
do 
	-- Abilities
	AddFlags(  1719, IsWarrior) -- Battle Cry
	AddFlags( 18499, IsWarrior) -- Berserker Rage
	AddFlags(227847, IsWarrior) -- Bladestorm
	AddFlags(105771, IsWarrior) -- Charge
	AddFlags( 97463, IsWarrior) -- Commanding Shout
	AddFlags(115767, IsWarrior) -- Deep Wounds
	AddFlags(  1160, IsWarrior) -- Demoralizing Shout
	AddFlags(118038, IsWarrior) -- Die by the Sword
	AddFlags(184362, IsWarrior) -- Enrage
	AddFlags(184364, IsWarrior) -- Enraged Regeneration
	AddFlags(204488, IsWarrior) -- Focused Rage
	AddFlags(  1715, IsWarrior) -- Hamstring
	AddFlags(190456, IsWarrior) -- Ignore Pain
	AddFlags(  5246, IsWarrior) -- Intimidating Shout
	AddFlags( 12975, IsWarrior) -- Last Stand
	AddFlags( 85739, IsWarrior) -- Meat Cleaver
	AddFlags( 12323, IsWarrior) -- Piercing Howl
	AddFlags(132404, IsWarrior) -- Shield Block
	AddFlags(   871, IsWarrior) -- Shield Wall
	AddFlags( 23920, IsWarrior) -- Spell Reflection
	AddFlags(206333, IsWarrior) -- Taste for Blood
	AddFlags(  6343, IsWarrior) -- Thunder Clap

	-- Talents
	AddFlags(107574, IsWarrior) -- Avatar
	AddFlags( 46924, IsWarrior) -- Bladestorm
	AddFlags( 12292, IsWarrior) -- Bloodbath
	AddFlags(197690, IsWarrior) -- Defensive Stance
	AddFlags(118000, IsWarrior) -- Dragon Roar
	AddFlags(207982, IsWarrior) -- Focused Rage
	AddFlags(215572, IsWarrior) -- Frothing Berserker
	AddFlags(   772, IsWarrior) -- Rend
	AddFlags( 46968, IsWarrior) -- Shockwave
	AddFlags(107570, IsWarrior) -- Storm Bolt
	AddFlags(215537, IsWarrior) -- Trauma
	--AddFlags(122510, IsWarrior) -- Ultimatum -- action button glow + spell alert overlay
	AddFlags(202573, IsWarrior) -- Vengeance: Focused Rage
	AddFlags(202547, IsWarrior) -- Vengeance: Ignore Pain
	AddFlags(215562, IsWarrior) -- War Machine
	AddFlags(215570, IsWarrior) -- Wrecking Ball
end 

------------------------------------------------------------------------
-- Taunts (tanks only)
------------------------------------------------------------------------
do 
	AddFlags( 36213, IsPlayerSpell) -- Angered Earth (SH Earth Elemental)
	AddFlags( 56222, IsPlayerSpell) -- Dark Command (DK)
	AddFlags( 57604, IsPlayerSpell) -- Death Grip (DK) -- NEEDS CHECK 49560 51399 57603
	AddFlags( 20736, IsPlayerSpell) -- Distracting Shot (HU)
	AddFlags(  6795, IsPlayerSpell) -- Growl (DR)
	AddFlags( 62124, IsPlayerSpell) -- Hand of Reckoning (Paladin)
	AddFlags(118585, IsPlayerSpell) -- Leer of the Ox (MO)
	AddFlags(114198, IsPlayerSpell) -- Mocking Banner (WR)
	AddFlags(116189, IsPlayerSpell) -- Provoke (MO)
	AddFlags(118635, IsPlayerSpell) -- Provoke (MO Black Ox Statue) -- NEEDS CHECK
	AddFlags( 62124, IsPlayerSpell) -- Reckoning (PA)
	AddFlags( 17735, IsPlayerSpell) -- Suffering (WL Voidwalker)
	AddFlags(   355, IsPlayerSpell) -- Taunt (WR)
	AddFlags(185245, IsPlayerSpell) -- Torment (Demon Hunter)
end 

------------------------------------------------------------------------
------------------------------------------------------------------------
-- 							RACIALS
------------------------------------------------------------------------
------------------------------------------------------------------------
do 
	-- BloodElf
	AddFlags( 50613, IsBloodElf) -- Arcane Torrent (DK)
	AddFlags( 80483, IsBloodElf) -- Arcane Torrent (HU)
	AddFlags( 28730, IsBloodElf) -- Arcane Torrent (MA, PA, PR, WL)
	AddFlags(129597, IsBloodElf) -- Arcane Torrent (MO)
	AddFlags( 25046, IsBloodElf) -- Arcane Torrent (RO)
	AddFlags( 69179, IsBloodElf) -- Arcane Torrent (WR)

	-- Draenei
	AddFlags( 59545, IsDraenei) -- Gift of the Naaru (DK)
	AddFlags( 59543, IsDraenei) -- Gift of the Naaru (HU)
	AddFlags( 59548, IsDraenei) -- Gift of the Naaru (MA)
	AddFlags(121093, IsDraenei) -- Gift of the Naaru (MO)
	AddFlags( 59542, IsDraenei) -- Gift of the Naaru (PA)
	AddFlags( 59544, IsDraenei) -- Gift of the Naaru (PR)
	AddFlags( 59547, IsDraenei) -- Gift of the Naaru (SH)
	AddFlags( 28880, IsDraenei) -- Gift of the Naaru (WR)

	-- Dwarf
	AddFlags( 20594, IsDwarf) -- Stoneform

	-- NightElf
	AddFlags( 58984, IsNightElf) -- Shadowmeld

	-- Orc
	AddFlags( 20572, IsOrc) -- Blood Fury (attack power)
	AddFlags( 33702, IsOrc) -- Blood Fury (spell power)
	AddFlags( 33697, IsOrc) -- Blood Fury (attack power and spell damage)

	-- Pandaren
	AddFlags(107079, IsPandaren) -- Quaking Palm

	-- Scourge
	AddFlags(  7744, IsScourge) -- Will of the Forsaken

	-- Tauren 
	AddFlags( 20549, IsTauren) -- War Stomp

	-- Troll
	AddFlags( 26297, IsTroll) -- Berserking

	-- Worgen 
	AddFlags( 68992, IsWorgen) -- Darkflight
end 

-- Sorting (don't comment out this, as it currently grabs all keys)
--[[
local frame = CreateFrame("EditBox", nil, UIParent)
frame:SetSize(400,300)
frame:SetFontObject(_G.GameFontNormal)
frame:SetPoint("CENTER")
frame:HighlightText(true)

local msg = ""
for id = 1,300000 do
	if Cache[id] then 
		msg = msg .. string.format("Cache[%6d] = IsFood|n",id)
	end  
end 

frame:SetText(msg)
]]-- 
