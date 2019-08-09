local ADDON, Private = ...

-- Lua API
local _G = _G
local bit_band = bit.band
local math_floor = math.floor
local pairs = pairs
local rawget = rawget
local select = select
local setmetatable = setmetatable
local string_gsub = string.gsub
local tonumber = tonumber
local unpack = unpack

-- WoW API
local GetTime = _G.GetTime
local InCombatLockdown = _G.InCombatLockdown
local UnitCanAttack = _G.UnitCanAttack
local UnitIsUnit = _G.UnitIsUnit
local UnitPlayerControlled = _G.UnitPlayerControlled

-- Addon API
local GetPlayerRole = CogWheel("LibPlayerData").GetPlayerRole
local HasAuraInfoFlags = CogWheel("LibAura").HasAuraInfoFlags

-- Databases
local infoFilter = CogWheel("LibAura"):GetAllAuraInfoBitFilters() -- Aura flags by keywords
local auraInfoFlags = CogWheel("LibAura"):GetAllAuraInfoFlags() -- Aura info flags
local auraUserFlags = {} -- Aura filter flags 
local auraFilters = {} -- Aura filter functions
local colorDB = {} -- Addon color schemes
local fontsDB = { normal = {}, outline = {} } -- Addon fonts

-- List of units we all count as the player
local unitIsPlayer = { player = true, 	pet = true, vehicle = true }

-- Utility Functions
-----------------------------------------------------------------
-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local createColor = function(...)
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
		tbl.colorCode = ("|cff%02x%02x%02x"):format(math_floor(tbl[1]*255), math_floor(tbl[2]*255), math_floor(tbl[3]*255))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local createColorGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = createColor(v)
	end 
	return tbl
end 

-- Populate Font Tables
-----------------------------------------------------------------
do 
	local fontPrefix = ADDON 
	fontPrefix = string_gsub(fontPrefix, "UI", "")
	fontPrefix = string_gsub(fontPrefix, "_Classic", "Classic")
	for i = 10,100 do 
		local fontNormal = _G[fontPrefix .. "Font" .. i]
		if fontNormal then 
			fontsDB.normal[i] = fontNormal
		end 
		local fontOutline = _G[fontPrefix .. "Font" .. i .. "_Outline"]
		if fontOutline then 
			fontsDB.outline[i] = fontOutline
		end 
	end 
end 

-- Populate Color Tables
-----------------------------------------------------------------
--colorDB.health = createColor(191/255, 0/255, 38/255)
colorDB.health = createColor(245/255, 0/255, 45/255)
colorDB.cast = createColor(229/255, 204/255, 127/255)
colorDB.disconnected = createColor(120/255, 120/255, 120/255)
colorDB.tapped = createColor(121/255, 101/255, 96/255)
--colorDB.tapped = createColor(161/255, 141/255, 120/255)
colorDB.dead = createColor(121/255, 101/255, 96/255)
--colorDB.dead = createColor(73/255, 25/255, 9/255)

-- Global UI vertex coloring
colorDB.ui = {
	stone = createColor(192/255, 192/255, 192/255),
	wood = createColor(192/255, 192/255, 192/255)
}

-- quest difficulty coloring 
colorDB.quest = {}
colorDB.quest.red = createColor(204/255, 26/255, 26/255)
colorDB.quest.orange = createColor(255/255, 128/255, 64/255)
colorDB.quest.yellow = createColor(229/255, 178/255, 38/255)
colorDB.quest.green = createColor(89/255, 201/255, 89/255)
colorDB.quest.gray = createColor(120/255, 120/255, 120/255)

-- some basic ui colors used by all text
colorDB.normal = createColor(229/255, 178/255, 38/255)
colorDB.highlight = createColor(250/255, 250/255, 250/255)
colorDB.title = createColor(255/255, 234/255, 137/255)
colorDB.offwhite = createColor(196/255, 196/255, 196/255)

colorDB.xp = createColor(116/255, 23/255, 229/255) -- xp bar 
colorDB.xpValue = createColor(145/255, 77/255, 229/255) -- xp bar text
colorDB.rested = createColor(163/255, 23/255, 229/255) -- xp bar while being rested
colorDB.restedValue = createColor(203/255, 77/255, 229/255) -- xp bar text while being rested
colorDB.restedBonus = createColor(69/255, 17/255, 134/255) -- rested bonus bar
colorDB.artifact = createColor(229/255, 204/255, 127/255) -- artifact or azerite power bar

-- Unit Class Coloring
-- Original colors at https://wow.gamepedia.com/Class#Class_colors
colorDB.class = {}
colorDB.class.DEATHKNIGHT = createColor(176/255, 31/255, 79/255)
colorDB.class.DEMONHUNTER = createColor(163/255, 48/255, 201/255)
colorDB.class.DRUID = createColor(255/255, 125/255, 10/255)
--colorDB.class.DRUID = createColor(191/255, 93/255, 7/255)
colorDB.class.HUNTER = createColor(191/255, 232/255, 115/255) 
colorDB.class.MAGE = createColor(105/255, 204/255, 240/255)
colorDB.class.MONK = createColor(0/255, 255/255, 150/255)
colorDB.class.PALADIN = createColor(225/255, 160/255, 226/255)
--colorDB.class.PALADIN = createColor(245/255, 140/255, 186/255)
colorDB.class.PRIEST = createColor(176/255, 200/255, 225/255)
colorDB.class.ROGUE = createColor(255/255, 225/255, 95/255) 
colorDB.class.SHAMAN = createColor(32/255, 122/255, 222/255) 
colorDB.class.WARLOCK = createColor(148/255, 130/255, 201/255) 
colorDB.class.WARRIOR = createColor(229/255, 156/255, 110/255) 
colorDB.class.UNKNOWN = createColor(195/255, 202/255, 217/255)

-- debuffs
colorDB.debuff = {}
colorDB.debuff.none = createColor(204/255, 0/255, 0/255)
colorDB.debuff.Magic = createColor(51/255, 153/255, 255/255)
colorDB.debuff.Curse = createColor(204/255, 0/255, 255/255)
colorDB.debuff.Disease = createColor(153/255, 102/255, 0/255)
colorDB.debuff.Poison = createColor(0/255, 153/255, 0/255)
colorDB.debuff[""] = createColor(0/255, 0/255, 0/255)

-- faction 
colorDB.faction = {}
colorDB.faction.Alliance = createColor(74/255, 84/255, 232/255)
colorDB.faction.Horde = createColor(229/255, 13/255, 18/255)
colorDB.faction.Neutral = createColor(249/255, 158/255, 35/255) 

-- power
colorDB.power = {}

local Fast = createColor(0/255, 208/255, 176/255) 
local Slow = createColor(116/255, 156/255, 255/255)
local Angry = createColor(156/255, 116/255, 255/255)

-- Crystal Power Colors
colorDB.power.ENERGY_CRYSTAL = Fast -- Rogues, Druids, Monks
colorDB.power.FOCUS_CRYSTAL = Slow -- Hunters and Hunter Pets
colorDB.power.RAGE_CRYSTAL = Angry -- Druids, Warriors

-- Orb Power Colors
colorDB.power.MANA_ORB = createColor(135/255, 125/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock

-- Standard Power Colors
colorDB.power.ENERGY = createColor(254/255, 245/255, 145/255) -- Rogues, Druids, Monks
colorDB.power.FOCUS = createColor(125/255, 168/255, 195/255) -- Hunters and Hunter Pets
colorDB.power.MANA = createColor(80/255, 116/255, 255/255) -- Druid, Mage, Paladin, Priest, Shaman, Warlock
colorDB.power.RAGE = createColor(215/255, 7/255, 7/255) -- Druids, Warriors

-- Secondary Resource Colors
colorDB.power.COMBO_POINTS = createColor(255/255, 0/255, 30/255) -- Rogues, Druids
colorDB.power.SOUL_SHARDS = createColor(148/255, 130/255, 201/255) -- Warlock 

-- Fallback for the rare cases where an unknown type is requested.
colorDB.power.UNUSED = createColor(195/255, 202/255, 217/255) 

-- Allow us to use power type index to get the color
-- FrameXML/UnitFrame.lua
colorDB.power[0] = colorDB.power.MANA
colorDB.power[1] = colorDB.power.RAGE
colorDB.power[2] = colorDB.power.FOCUS
colorDB.power[3] = colorDB.power.ENERGY
colorDB.power[7] = colorDB.power.SOUL_SHARDS

-- reactions
colorDB.reaction = {}
colorDB.reaction[1] = createColor(205/255, 46/255, 36/255) -- hated
colorDB.reaction[2] = createColor(205/255, 46/255, 36/255) -- hostile
colorDB.reaction[3] = createColor(192/255, 68/255, 0/255) -- unfriendly
colorDB.reaction[4] = createColor(249/255, 188/255, 65/255) -- neutral 
--colorDB.reaction[4] = createColor(249/255, 158/255, 35/255) -- neutral 
colorDB.reaction[5] = createColor(64/255, 131/255, 38/255) -- friendly
colorDB.reaction[6] = createColor(64/255, 131/255, 69/255) -- honored
colorDB.reaction[7] = createColor(64/255, 131/255, 104/255) -- revered
colorDB.reaction[8] = createColor(64/255, 131/255, 131/255) -- exalted
colorDB.reaction.civilian = createColor(64/255, 131/255, 38/255) -- used for friendly player nameplates

-- friendship
-- just using this as pointers to the reaction colors, 
-- so there won't be a need to ever edit these.
colorDB.friendship = {}
colorDB.friendship[1] = colorDB.reaction[3] -- Stranger
colorDB.friendship[2] = colorDB.reaction[4] -- Acquaintance 
colorDB.friendship[3] = colorDB.reaction[5] -- Buddy
colorDB.friendship[4] = colorDB.reaction[6] -- Friend (honored color)
colorDB.friendship[5] = colorDB.reaction[7] -- Good Friend (revered color)
colorDB.friendship[6] = colorDB.reaction[8] -- Best Friend (exalted color)
colorDB.friendship[7] = colorDB.reaction[8] -- Best Friend (exalted color) - brawler's stuff
colorDB.friendship[8] = colorDB.reaction[8] -- Best Friend (exalted color) - brawler's stuff

-- player specializations
colorDB.specialization = {}
colorDB.specialization[1] = createColor(0/255, 215/255, 59/255)
colorDB.specialization[2] = createColor(217/255, 33/255, 0/255)
colorDB.specialization[3] = createColor(218/255, 30/255, 255/255)
colorDB.specialization[4] = createColor(48/255, 156/255, 255/255)

-- timers (breath, fatigue, etc)
colorDB.timer = {}
colorDB.timer.UNKNOWN = createColor(179/255, 77/255, 0/255) -- fallback for timers and unknowns
colorDB.timer.EXHAUSTION = createColor(179/255, 77/255, 0/255)
colorDB.timer.BREATH = createColor(0/255, 128/255, 255/255)
colorDB.timer.DEATH = createColor(217/255, 90/255, 0/255) 
colorDB.timer.FEIGNDEATH = createColor(217/255, 90/255, 0/255) 

-- threat
colorDB.threat = {}
colorDB.threat[0] = colorDB.reaction[4] -- not really on the threat table
colorDB.threat[1] = createColor(249/255, 158/255, 35/255) -- tanks having lost threat, dps overnuking 
colorDB.threat[2] = createColor(255/255, 96/255, 12/255) -- tanks about to lose threat, dps getting aggro
colorDB.threat[3] = createColor(255/255, 0/255, 0/255) -- securely tanking, or totally fucked :) 
--colorDB.threat[0] = createColor(175/255, 165/255, 155/255) 
--colorDB.threat[1] = createColor(255/255, 128/255, 64/255)  
--colorDB.threat[2] = createColor(255/255, 64/255, 12/255) 
--colorDB.threat[3] = createColor(255/255, 0/255, 0/255)  
--colorDB.reaction[8] = colorDB.threat[1] -- just testing

-- zone names
colorDB.zone = {}
colorDB.zone.arena = createColor(175/255, 76/255, 56/255)
colorDB.zone.combat = createColor(175/255, 76/255, 56/255) 
colorDB.zone.contested = createColor(229/255, 159/255, 28/255)
colorDB.zone.friendly = createColor(64/255, 175/255, 38/255) 
colorDB.zone.hostile = createColor(175/255, 76/255, 56/255) 
colorDB.zone.sanctuary = createColor(104/255, 204/255, 239/255)
colorDB.zone.unknown = createColor(255/255, 234/255, 137/255) -- instances, bgs, contested zones on pve realms 

-- Item rarity coloring
colorDB.quality = createColorGroup(ITEM_QUALITY_COLORS)

-- world quest quality coloring
-- using item rarities for these colors
colorDB.worldquestquality = {}
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_COMMON] = colorDB.quality[ITEM_QUALITY_COMMON]
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_RARE] = colorDB.quality[ITEM_QUALITY_RARE]
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_EPIC] = colorDB.quality[ITEM_QUALITY_EPIC]

-- Aura Filter Bitflags
-----------------------------------------------------------------
-- These are front-end filters and describe display preference, 
-- they are unrelated to the factual, purely descriptive back-end filters. 
local ByPlayer 			= tonumber("000000000000000000000000000000001", 2) -- Show when cast by player

-- Unit visibility
local OnPlayer 			= tonumber("000000000000000000000000000000010", 2) -- Show on player frame
local OnTarget 			= tonumber("000000000000000000000000000000100", 2) -- Show on target frame 
local OnPet 			= tonumber("000000000000000000000000000001000", 2) -- Show on pet frame
local OnToT 			= tonumber("000000000000000000000000000010000", 2) -- Shown on tot frame
local OnFocus 			= tonumber("000000000000000000000000000100000", 2) -- Show on focus frame 
local OnParty 			= tonumber("000000000000000000000000001000000", 2) -- Show on party members
local OnBoss 			= tonumber("000000000000000000000000010000000", 2) -- Show on boss frames
local OnArena			= tonumber("000000000000000000000000100000000", 2) -- Show on arena enemy frames
local OnFriend 			= tonumber("000000000000000000000001000000000", 2) -- Show on friendly units, regardless of frame
local OnEnemy 			= tonumber("000000000000000000000010000000000", 2) -- Show on enemy units, regardless of frame

-- Player role visibility
local PlayerIsDPS 		= tonumber("000000000000000000000100000000000", 2) -- Show when player is a damager
local PlayerIsHealer 	= tonumber("000000000000000000001000000000000", 2) -- Show when player is a healer
local PlayerIsTank 		= tonumber("000000000000000000010000000000000", 2) -- Show when player is a tank 

-- Aura visibility priority
local Never 			= tonumber("000000100000000000000000000000000", 2) -- Never show (Blacklist)
local PrioLow 			= tonumber("000001000000000000000000000000000", 2) -- Low priority, will only be displayed if room
local PrioMedium 		= tonumber("000010000000000000000000000000000", 2) -- Normal priority, same as not setting any
local PrioHigh 			= tonumber("000100000000000000000000000000000", 2) -- High priority, shown first after boss
local PrioBoss 			= tonumber("001000000000000000000000000000000", 2) -- Same priority as boss debuffs
local Always 			= tonumber("010000000000000000000000000000000", 2) -- Always show (Whitelist)

local NeverOnPlate 		= tonumber("100000000000000000000000000000000", 2) -- Never show on plates (Blacklist)

-- Aura Filter Functions
-----------------------------------------------------------------
auraFilters.default = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isBossDebuff or (unitCaster == "vehicle")) then
		return true
	elseif (count and (count > 1)) then 
		return true
	elseif InCombatLockdown() then 
		if (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)) then
			return true
		end 
	else 
		if isBuff then 
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		else
			if (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)) then
				return true
			end
		end 
	end 
end

auraFilters.player = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- Retrieve filter flags
	local infoFlags = auraInfoFlags[spellID]
	local userFlags = auraUserFlags[spellID]

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isBossDebuff or isBossDebuff or (userFlags and (bit_band(userFlags, PrioBoss) ~= 0)) or (unitCaster == "vehicle")) then
		return true

	elseif InCombatLockdown() then 
		if userFlags then 
			if unitIsPlayer[unit] and (bit_band(userFlags, OnPlayer) ~= 0) then 
				return true  
			end

		elseif infoFlags then 
			if (unitCaster and isOwnedByPlayer) and (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
				return true  
			end
		end

		-- Auras from hostile npc's
		if (not unitCaster) or (UnitCanAttack("player", unitCaster) and (not UnitPlayerControlled(unitCaster))) then 
			return ((not isBuff) and (duration and duration < 180))
		end

	else 
		if userFlags then 
			if unitIsPlayer[unit] and (bit_band(userFlags, OnPlayer) ~= 0) then 
				return true  
			end
		elseif isBuff then 
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		else
			return true
		end 
	end 
end 

auraFilters.target = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- Retrieve filter flags
	local infoFlags = auraInfoFlags[spellID]
	local userFlags = auraUserFlags[spellID]
	
	-- Figure out time currently left
	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	-- Stealable and boss auras
	if (isStealable or isBossDebuff or (userFlags and (bit_band(userFlags, PrioBoss) ~= 0))) then 
		return true 

	-- Auras on enemies
	elseif UnitCanAttack("player", unit) then 
		if InCombatLockdown() then 

			-- Show filtered auras on hostiles
			if infoFlags then 
				if (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
					return isOwnedByPlayer 
				elseif (bit_band(infoFlags, PlayerIsTank) ~= 0) then 
					return (GetPlayerRole() == "TANK")
				else
					return (bit_band(infoFlags, OnEnemy) ~= 0)
				end 
			end 

			-- Show short self-buffs on enemies 
			if isBuff then 
				if unitCaster and UnitIsUnit(unit, unitCaster) and UnitCanAttack("player", unit) then 
					return ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)))
				end
			end 
		else 

			-- Show long/no duration auras out of combat
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		end 

	-- Auras on friends
	else 
		if InCombatLockdown() then 

			-- Show filtered auras
			if infoFlags then 
				if (userFlags and (bit_band(userFlags, OnFriend) ~= 0)) then 
					return true
				elseif (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
					return isOwnedByPlayer 
				end
			end 

		else 

			-- Show long/no duration auras out of combat
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		end 
	end 
end

auraFilters.nameplate = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	local infoFlags = auraInfoFlags[spellID]
	local userFlags = auraUserFlags[spellID]

	if infoFlags then 
		if (unitCaster and isOwnedByPlayer) and (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
			if (userFlags and (bit_band(userFlags, NeverOnPlate) ~= 0)) then 
				return
			else
				return ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)))
			end
		end 
	end 
end 

auraFilters.focus = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return auraFilters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

auraFilters.targettarget = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return auraFilters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

auraFilters.party = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local userFlags = auraUserFlags[spellID]

	if userFlags then
		return (bit_band(userFlags, OnFriend) ~= 0)
	else
		return isBossDebuff or (userFlags and (bit_band(userFlags, PrioBoss) ~= 0))
	end
end

auraFilters.boss = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local infoFlags = auraInfoFlags[spellID]
	local userFlags = auraUserFlags[spellID]

	if infoFlags then
		if (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
			return isOwnedByPlayer 
		else 
			return userFlags and (bit_band(userFlags, OnEnemy) ~= 0)
		end 
	else
		return isBossDebuff or (userFlags and (bit_band(userFlags, PrioBoss) ~= 0))
	end
end

auraFilters.arena = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local infoFlags = auraInfoFlags[spellID]
	local userFlags = auraUserFlags[spellID]

	if infoFlags then
		if (bit_band(infoFlags, infoFilter.IsPlayerSpell) ~= 0) then 
			return isOwnedByPlayer 
		else 
			return userFlags and (bit_band(userFlags, OnEnemy) ~= 0)
		end 
	end
end

-- Add a fallback system
-- *needed in case non-existing unit filters are requested 
local filterFuncs = setmetatable(auraFilters, { __index = function(t,k) return rawget(t,k) or rawget(t, "default") end})

-- Private API
-----------------------------------------------------------------
Private.Colors = colorDB
Private.GetAuraFilterFunc = function(unit) return filterFuncs[unit or "default"] end
Private.GetFont = function(size, outline) return fontsDB[outline and "outline" or "normal"][size] end
Private.GetMedia = function(name, type) return ([[Interface\AddOns\%s\media\%s.%s]]):format(ADDON, name, type or "tga") end

-----------------------------------------------------------------
-- Aura Filter Flag Database
-- *Placing these at the end for tidyness 
-----------------------------------------------------------------

-- For testing
------------------------------------------------------------------------
--auraUserFlags[  8936] = OnPlayer -- Regrowth

-- Musts that are game-breaking to not have there
------------------------------------------------------------------------
auraUserFlags[304696] = OnPlayer -- Alpha Fin (constantly moving mount)
auraUserFlags[295858] = OnPlayer -- Molted Shell (constantly moving mount)
auraUserFlags[304037] = OnPlayer -- Fermented Deviate Fish (transform)

-- Spammy stuff that is implicit and not really needed
--auraUserFlags[155722] = NeverOnPlate -- Rake (just for my own testing purposes)
auraUserFlags[204242] = NeverOnPlate -- Consecration (talent Consecrated Ground)

-- NPC buffs that are completely useless
------------------------------------------------------------------------
auraUserFlags[ 63501] = Never -- Argent Crusade Champion's Pennant
auraUserFlags[ 60023] = Never -- Scourge Banner Aura (Boneguard Commander in Icecrown)
auraUserFlags[ 63406] = Never -- Darnassus Champion's Pennant
auraUserFlags[ 63405] = Never -- Darnassus Valiant's Pennant
auraUserFlags[ 63423] = Never -- Exodar Champion's Pennant
auraUserFlags[ 63422] = Never -- Exodar Valiant's Pennant
auraUserFlags[ 63396] = Never -- Gnomeregan Champion's Pennant
auraUserFlags[ 63395] = Never -- Gnomeregan Valiant's Pennant
auraUserFlags[ 63427] = Never -- Ironforge Champion's Pennant
auraUserFlags[ 63426] = Never -- Ironforge Valiant's Pennant
auraUserFlags[ 63433] = Never -- Orgrimmar Champion's Pennant
auraUserFlags[ 63432] = Never -- Orgrimmar Valiant's Pennant
auraUserFlags[ 63399] = Never -- Sen'jin Champion's Pennant
auraUserFlags[ 63398] = Never -- Sen'jin Valiant's Pennant
auraUserFlags[ 63403] = Never -- Silvermoon Champion's Pennant
auraUserFlags[ 63402] = Never -- Silvermoon Valiant's Pennant
auraUserFlags[ 62594] = Never -- Stormwind Champion's Pennant
auraUserFlags[ 62596] = Never -- Stormwind Valiant's Pennant
auraUserFlags[ 63436] = Never -- Thunder Bluff Champion's Pennant
auraUserFlags[ 63435] = Never -- Thunder Bluff Valiant's Pennant
auraUserFlags[ 63430] = Never -- Undercity Champion's Pennant
auraUserFlags[ 63429] = Never -- Undercity Valiant's Pennant

-- Legion Consumables
------------------------------------------------------------------------
auraUserFlags[188030] = ByPlayer -- Leytorrent Potion (channeled)
auraUserFlags[188027] = ByPlayer -- Potion of Deadly Grace
auraUserFlags[188028] = ByPlayer -- Potion of the Old War
auraUserFlags[188029] = ByPlayer -- Unbending Potion

-- Quest related auras
------------------------------------------------------------------------
auraUserFlags[127372] = OnPlayer -- Unstable Serum (Klaxxi Enhancement: Raining Blood)
auraUserFlags[240640] = OnPlayer -- The Shadow of the Sentinax (Mark of the Sentinax)

-- Heroism
------------------------------------------------------------------------
auraUserFlags[ 90355] = OnPlayer + PrioHigh -- Ancient Hysteria
auraUserFlags[  2825] = OnPlayer + PrioHigh -- Bloodlust
auraUserFlags[ 32182] = OnPlayer + PrioHigh -- Heroism
auraUserFlags[160452] = OnPlayer + PrioHigh -- Netherwinds
auraUserFlags[ 80353] = OnPlayer + PrioHigh -- Time Warp

-- Deserters
------------------------------------------------------------------------
auraUserFlags[ 26013] = OnPlayer + PrioHigh -- Deserter
auraUserFlags[ 99413] = OnPlayer + PrioHigh -- Deserter
auraUserFlags[ 71041] = OnPlayer + PrioHigh -- Dungeon Deserter
auraUserFlags[144075] = OnPlayer + PrioHigh -- Dungeon Deserter
auraUserFlags[170616] = OnPlayer + PrioHigh -- Pet Deserter

-- Other big ones
------------------------------------------------------------------------
auraUserFlags[ 67556] = OnPlayer -- Cooking Speed
auraUserFlags[ 29166] = OnPlayer -- Innervate
auraUserFlags[102342] = OnPlayer -- Ironbark
auraUserFlags[ 33206] = OnPlayer -- Pain Suppression
auraUserFlags[ 10060] = OnPlayer -- Power Infusion
auraUserFlags[ 64901] = OnPlayer -- Symbol of Hope

auraUserFlags[ 57723] = OnPlayer -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
auraUserFlags[160455] = OnPlayer -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
auraUserFlags[243138] = OnPlayer -- Happy Feet event 
auraUserFlags[246050] = OnPlayer -- Happy Feet buff gained restoring health
auraUserFlags[ 95809] = OnPlayer -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
auraUserFlags[ 15007] = OnPlayer -- Resurrection Sickness
auraUserFlags[ 57724] = OnPlayer -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
auraUserFlags[ 80354] = OnPlayer -- Temporal Displacement

------------------------------------------------------------------------
-- BfA Dungeons
-- *some auras might be under the wrong dungeon, 
--  this is because wowhead doesn't always tell what casts this.
------------------------------------------------------------------------
-- Atal'Dazar
------------------------------------------------------------------------
auraUserFlags[253721] = PrioBoss -- Bulwark of Juju
auraUserFlags[253548] = PrioBoss -- Bwonsamdi's Mantle
auraUserFlags[256201] = PrioBoss -- Incendiary Rounds
auraUserFlags[250372] = PrioBoss -- Lingering Nausea
auraUserFlags[257407] = PrioBoss -- Pursuit
auraUserFlags[255434] = PrioBoss -- Serrated Teeth
auraUserFlags[254959] = PrioBoss -- Soulburn
auraUserFlags[256577] = PrioBoss -- Soulfeast
auraUserFlags[254958] = PrioBoss -- Soulforged Construct
auraUserFlags[259187] = PrioBoss -- Soulrend
auraUserFlags[255558] = PrioBoss -- Tainted Blood
auraUserFlags[255577] = PrioBoss -- Transfusion
auraUserFlags[260667] = PrioBoss -- Transfusion
auraUserFlags[260668] = PrioBoss -- Transfusion
auraUserFlags[255371] = PrioBoss -- Terrifying Visage
auraUserFlags[252781] = PrioBoss -- Unstable Hex
auraUserFlags[250096] = PrioBoss -- Wracking Pain

-- Tol Dagor
------------------------------------------------------------------------
auraUserFlags[256199] = PrioBoss -- Azerite Rounds: Blast
auraUserFlags[256955] = PrioBoss -- Cinderflame
auraUserFlags[256083] = PrioBoss -- Cross Ignition
auraUserFlags[256038] = PrioBoss -- Deadeye
auraUserFlags[256044] = PrioBoss -- Deadeye
auraUserFlags[258128] = PrioBoss -- Debilitating Shout
auraUserFlags[256105] = PrioBoss -- Explosive Burst
auraUserFlags[257785] = PrioBoss -- Flashing Daggers
auraUserFlags[258075] = PrioBoss -- Itchy Bite
auraUserFlags[260016] = PrioBoss -- Itchy Bite  NEEDS CHECK!
auraUserFlags[258079] = PrioBoss -- Massive Chomp
auraUserFlags[258317] = PrioBoss -- Riot Shield
auraUserFlags[257495] = PrioBoss -- Sandstorm
auraUserFlags[258153] = PrioBoss -- Watery Dome

-- The MOTHERLODE!!
------------------------------------------------------------------------
auraUserFlags[262510] = PrioBoss -- Azerite Heartseeker
auraUserFlags[262513] = PrioBoss -- Azerite Heartseeker
auraUserFlags[262515] = PrioBoss -- Azerite Heartseeker
auraUserFlags[262516] = PrioBoss -- Azerite Heartseeker
auraUserFlags[281534] = PrioBoss -- Azerite Heartseeker
auraUserFlags[270276] = PrioBoss -- Big Red Rocket
auraUserFlags[270277] = PrioBoss -- Big Red Rocket
auraUserFlags[270278] = PrioBoss -- Big Red Rocket
auraUserFlags[270279] = PrioBoss -- Big Red Rocket
auraUserFlags[270281] = PrioBoss -- Big Red Rocket
auraUserFlags[270282] = PrioBoss -- Big Red Rocket
auraUserFlags[256163] = PrioBoss -- Blazing Azerite
auraUserFlags[256493] = PrioBoss -- Blazing Azerite
auraUserFlags[270882] = PrioBoss -- Blazing Azerite
auraUserFlags[259853] = PrioBoss -- Chemical Burn
auraUserFlags[280604] = PrioBoss -- Iced Spritzer
auraUserFlags[260811] = PrioBoss -- Homing Missile
auraUserFlags[260813] = PrioBoss -- Homing Missile
auraUserFlags[260815] = PrioBoss -- Homing Missile
auraUserFlags[260829] = PrioBoss -- Homing Missile
auraUserFlags[260835] = PrioBoss -- Homing Missile
auraUserFlags[260836] = PrioBoss -- Homing Missile
auraUserFlags[260837] = PrioBoss -- Homing Missile
auraUserFlags[260838] = PrioBoss -- Homing Missile
auraUserFlags[257582] = PrioBoss -- Raging Gaze
auraUserFlags[258622] = PrioBoss -- Resonant Pulse
auraUserFlags[271579] = PrioBoss -- Rock Lance
auraUserFlags[263202] = PrioBoss -- Rock Lance
auraUserFlags[257337] = PrioBoss -- Shocking Claw
auraUserFlags[262347] = PrioBoss -- Static Pulse
auraUserFlags[275905] = PrioBoss -- Tectonic Smash
auraUserFlags[275907] = PrioBoss -- Tectonic Smash
auraUserFlags[269298] = PrioBoss -- Widowmaker Toxin

-- Temple of Sethraliss
------------------------------------------------------------------------
auraUserFlags[263371] = PrioBoss -- Conduction
auraUserFlags[263573] = PrioBoss -- Cyclone Strike
auraUserFlags[263914] = PrioBoss -- Blinding Sand
auraUserFlags[256333] = PrioBoss -- Dust Cloud
auraUserFlags[260792] = PrioBoss -- Dust Cloud
auraUserFlags[272659] = PrioBoss -- Electrified Scales
auraUserFlags[269670] = PrioBoss -- Empowerment
auraUserFlags[266923] = PrioBoss -- Galvanize
auraUserFlags[268007] = PrioBoss -- Heart Attack
auraUserFlags[263246] = PrioBoss -- Lightning Shield
auraUserFlags[273563] = PrioBoss -- Neurotoxin
auraUserFlags[272657] = PrioBoss -- Noxious Breath
auraUserFlags[275566] = PrioBoss -- Numb Hands
auraUserFlags[269686] = PrioBoss -- Plague
auraUserFlags[263257] = PrioBoss -- Static Shock
auraUserFlags[272699] = PrioBoss -- Venomous Spit

-- Underrot
------------------------------------------------------------------------
auraUserFlags[272592] = PrioBoss -- Abyssal Reach
auraUserFlags[264603] = PrioBoss -- Blood Mirror
auraUserFlags[260292] = PrioBoss -- Charge
auraUserFlags[265568] = PrioBoss -- Dark Omen
auraUserFlags[272180] = PrioBoss -- Death Bolt
auraUserFlags[273226] = PrioBoss -- Decaying Spores
auraUserFlags[265377] = PrioBoss -- Hooked Snare
auraUserFlags[260793] = PrioBoss -- Indigestion
auraUserFlags[257437] = PrioBoss -- Poisoning Strike
auraUserFlags[269301] = PrioBoss -- Putrid Blood
auraUserFlags[264757] = PrioBoss -- Sanguine Feast
auraUserFlags[265019] = PrioBoss -- Savage Cleave
auraUserFlags[260455] = PrioBoss -- Serrated Fangs
auraUserFlags[260685] = PrioBoss -- Taint of G'huun
auraUserFlags[266107] = PrioBoss -- Thirst For Blood
auraUserFlags[259718] = PrioBoss -- Upheaval
auraUserFlags[269843] = PrioBoss -- Vile Expulsion
auraUserFlags[273285] = PrioBoss -- Volatile Pods
auraUserFlags[265468] = PrioBoss -- Withering Curse

-- Freehold
------------------------------------------------------------------------
auraUserFlags[258323] = PrioBoss -- Infected Wound
auraUserFlags[257908] = PrioBoss -- Oiled Blade
auraUserFlags[274555] = PrioBoss -- Scabrous Bite
auraUserFlags[274507] = PrioBoss -- Slippery Suds
auraUserFlags[265168] = PrioBoss -- Caustic Freehold Brew
auraUserFlags[278467] = PrioBoss -- Caustic Freehold Brew
auraUserFlags[265085] = PrioBoss -- Confidence-Boosting Freehold Brew
auraUserFlags[265088] = PrioBoss -- Confidence-Boosting Freehold Brew
auraUserFlags[264608] = PrioBoss -- Invigorating Freehold Brew
auraUserFlags[265056] = PrioBoss -- Invigorating Freehold Brew
auraUserFlags[257739] = PrioBoss -- Blind Rage
auraUserFlags[258777] = PrioBoss -- Sea Spout
auraUserFlags[257732] = PrioBoss -- Shattering Bellow
auraUserFlags[274383] = PrioBoss -- Rat Traps
auraUserFlags[268717] = PrioBoss -- Dive Bomb
auraUserFlags[257305] = PrioBoss -- Cannon Barrage

-- Shrine of the Storm
------------------------------------------------------------------------
auraUserFlags[269131] = PrioBoss -- Ancient Mindbender
auraUserFlags[268086] = PrioBoss -- Aura of Dread
auraUserFlags[268214] = PrioBoss -- Carve Flesh
auraUserFlags[264560] = PrioBoss -- Choking Brine
auraUserFlags[267899] = PrioBoss -- Hindering Cleave
auraUserFlags[268391] = PrioBoss -- Mental Assault
auraUserFlags[268212] = PrioBoss -- Minor Reinforcing Ward
auraUserFlags[268183] = PrioBoss -- Minor Swiftness Ward
auraUserFlags[268184] = PrioBoss -- Minor Swiftness Ward
auraUserFlags[267905] = PrioBoss -- Reinforcing Ward
auraUserFlags[268186] = PrioBoss -- Reinforcing Ward
auraUserFlags[268239] = PrioBoss -- Shipbreaker Storm
auraUserFlags[267818] = PrioBoss -- Slicing Blast
auraUserFlags[276286] = PrioBoss -- Slicing Hurricane
auraUserFlags[264101] = PrioBoss -- Surging Rush
auraUserFlags[274633] = PrioBoss -- Sundering Blow
auraUserFlags[267890] = PrioBoss -- Swiftness Ward
auraUserFlags[267891] = PrioBoss -- Swiftness Ward
auraUserFlags[268322] = PrioBoss -- Touch of the Drowned
auraUserFlags[264166] = PrioBoss -- Undertow
auraUserFlags[268309] = PrioBoss -- Unending Darkness
auraUserFlags[276297] = PrioBoss -- Void Seed
auraUserFlags[267034] = PrioBoss -- Whispers of Power
auraUserFlags[267037] = PrioBoss -- Whispers of Power
auraUserFlags[269399] = PrioBoss -- Yawning Gate

-- Waycrest Manor
------------------------------------------------------------------------
auraUserFlags[268080] = PrioBoss -- Aura of Apathy
auraUserFlags[260541] = PrioBoss -- Burning Brush
auraUserFlags[268202] = PrioBoss -- Death Lens
auraUserFlags[265881] = PrioBoss -- Decaying Touch
auraUserFlags[268306] = PrioBoss -- Discordant Cadenza
auraUserFlags[265880] = PrioBoss -- Dread Mark
auraUserFlags[263943] = PrioBoss -- Etch
auraUserFlags[278444] = PrioBoss -- Infest
auraUserFlags[278456] = PrioBoss -- Infest
auraUserFlags[260741] = PrioBoss -- Jagged Nettles
auraUserFlags[261265] = PrioBoss -- Ironbark Shield
auraUserFlags[265882] = PrioBoss -- Lingering Dread
auraUserFlags[271178] = PrioBoss -- Ravaging Leap
auraUserFlags[264694] = PrioBoss -- Rotten Expulsion
auraUserFlags[264105] = PrioBoss -- Runic Mark
auraUserFlags[261266] = PrioBoss -- Runic Ward
auraUserFlags[261264] = PrioBoss -- Soul Armor
auraUserFlags[260512] = PrioBoss -- Soul Harvest
auraUserFlags[264923] = PrioBoss -- Tenderize
auraUserFlags[265761] = PrioBoss -- Thorned Barrage
auraUserFlags[260703] = PrioBoss -- Unstable Runic Mark
auraUserFlags[261440] = PrioBoss -- Virulent Pathogen
auraUserFlags[263961] = PrioBoss -- Warding Candles

-- King's Rest
------------------------------------------------------------------------
auraUserFlags[274387] = PrioBoss -- Absorbed in Darkness 
auraUserFlags[266951] = PrioBoss -- Barrel Through
auraUserFlags[268586] = PrioBoss -- Blade Combo
auraUserFlags[267639] = PrioBoss -- Burn Corruption
auraUserFlags[270889] = PrioBoss -- Channel Lightning
auraUserFlags[271640] = PrioBoss -- Dark Revelation
auraUserFlags[267626] = PrioBoss -- Dessication
auraUserFlags[267618] = PrioBoss -- Drain Fluids
auraUserFlags[271564] = PrioBoss -- Embalming Fluid
auraUserFlags[269936] = PrioBoss -- Fixate
auraUserFlags[268419] = PrioBoss -- Gale Slash
auraUserFlags[270514] = PrioBoss -- Ground Crush
auraUserFlags[265923] = PrioBoss -- Lucre's Call
auraUserFlags[270284] = PrioBoss -- Purification Beam
auraUserFlags[270289] = PrioBoss -- Purification Beam
auraUserFlags[270507] = PrioBoss -- Poison Barrage
auraUserFlags[265781] = PrioBoss -- Serpentine Gust
auraUserFlags[266231] = PrioBoss -- Severing Axe
auraUserFlags[270487] = PrioBoss -- Severing Blade
auraUserFlags[266238] = PrioBoss -- Shattered Defenses
auraUserFlags[265773] = PrioBoss -- Spit Gold
auraUserFlags[270003] = PrioBoss -- Suppression Slam

-- Siege of Boralus
------------------------------------------------------------------------
auraUserFlags[269029] = PrioBoss -- Clear the Deck
auraUserFlags[272144] = PrioBoss -- Cover
auraUserFlags[257168] = PrioBoss -- Cursed Slash
auraUserFlags[260954] = PrioBoss -- Iron Gaze
auraUserFlags[261428] = PrioBoss -- Hangman's Noose
auraUserFlags[273930] = PrioBoss -- Hindering Cut
auraUserFlags[275014] = PrioBoss -- Putrid Waters
auraUserFlags[272588] = PrioBoss -- Rotting Wounds
auraUserFlags[257170] = PrioBoss -- Savage Tempest
auraUserFlags[272421] = PrioBoss -- Sighted Artillery
auraUserFlags[269266] = PrioBoss -- Slam
auraUserFlags[275836] = PrioBoss -- Stinging Venom
auraUserFlags[257169] = PrioBoss -- Terrifying Roar
auraUserFlags[276068] = PrioBoss -- Tidal Surge
auraUserFlags[272874] = PrioBoss -- Trample
auraUserFlags[260569] = PrioBoss -- Wildfire (?) Waycrest Manor? CHECK!
