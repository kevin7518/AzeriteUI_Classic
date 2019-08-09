local LibTooltipScanner = CogWheel:Set("LibTooltipScanner", 29)
if (not LibTooltipScanner) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_lower = string.lower
local string_join = string.join
local string_match = string.match
local string_sub = string.sub
local tonumber = tonumber
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame
local GetAchievementInfo = _G.GetAchievementInfo
local GetActionCharges = _G.GetActionCharges
local GetActionCooldown = _G.GetActionCooldown
local GetActionCount = _G.GetActionCount
local GetActionLossOfControlCooldown = _G.GetActionLossOfControlCooldown
local GetActionText = _G.GetActionText
local GetActionTexture = _G.GetActionTexture
local GetDetailedItemLevelInfo = _G.GetDetailedItemLevelInfo 
local GetGuildBankItemInfo = _G.GetSpecializationRole
local GetGuildInfo = _G.GetGuildInfo
local GetItemInfo = _G.GetItemInfo
local GetItemQualityColor = _G.GetItemQualityColor
local GetItemStats = _G.GetItemStats
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetSpecializationRole = _G.GetSpecializationRole
local GetSpellInfo = _G.GetSpellInfo
local HasAction = _G.HasAction
local IsActionInRange = _G.IsActionInRange
local UnitBattlePetLevel = _G.UnitBattlePetLevel
local UnitClass = _G.UnitClass 
local UnitClassification = _G.UnitClassification
local UnitCreatureFamily = _G.UnitCreatureFamily
local UnitCreatureType = _G.UnitCreatureType
local UnitExists = _G.UnitExists
local UnitEffectiveLevel = _G.UnitEffectiveLevel
local UnitFactionGroup = _G.UnitFactionGroup
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitIsDead = _G.UnitIsDead
local UnitIsGhost = _G.UnitIsGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UnitRace = _G.UnitRace
local UnitReaction = _G.UnitReaction
local DoesSpellExist = _G.C_Spell.DoesSpellExist 

LibTooltipScanner.embeds = LibTooltipScanner.embeds or {}

-- Tooltip used for scanning
LibTooltipScanner.scannerName = LibTooltipScanner.scannerName or "CG_TooltipScanner"
LibTooltipScanner.scannerTooltip = LibTooltipScanner.scannerTooltip 
								or CreateFrame("GameTooltip", LibTooltipScanner.scannerName, WorldFrame, "GameTooltipTemplate")

-- Shortcuts
local Scanner = LibTooltipScanner.scannerTooltip
local ScannerName = LibTooltipScanner.scannerName

-- Scanning Constants & Patterns
---------------------------------------------------------
-- Localized Constants
local Constants = {
	CastChanneled = _G.SPELL_CAST_CHANNELED, 
	CastInstant = _G.SPELL_RECAST_TIME_CHARGEUP_INSTANT,
	CastTimeMin = _G.SPELL_CAST_TIME_MIN,
	CastTimeSec = _G.SPELL_CAST_TIME_SEC, 
	ContainerSlots = _G.CONTAINER_SLOTS, 

	CooldownRemaining = _G.COOLDOWN_REMAINING,
	CooldownTimeRemaining1 = _G.ITEM_COOLDOWN_TIME,
	CooldownTimeRemaining2 = _G.ITEM_COOLDOWN_TIME_MIN,
	CooldownTimeRemaining3 = _G.ITEM_COOLDOWN_TIME_SEC,

	RechargeTimeRemaining1 = _G.SPELL_RECHARGE_TIME,
	RechargeTimeRemaining2 = _G.SPELL_RECHARGE_TIME_MIN,
	RechargeTimeRemaining3 = _G.SPELL_RECHARGE_TIME_SEC,

	ItemBoundAccount = _G.ITEM_ACCOUNTBOUND,
	ItemBoundBnet = _G.ITEM_BNETACCOUNTBOUND,
	ItemBoundSoul = _G.ITEM_SOULBOUND,
	ItemBlock = _G.SHIELD_BLOCK_TEMPLATE,
	ItemDamage = _G.DAMAGE_TEMPLATE,
	ItemDurability = _G.DURABILITY_TEMPLATE,
	ItemLevel = _G.ITEM_LEVEL,
	ItemReqLevel = _G.ITEM_MIN_LEVEL, 
	ItemSellPrice = _G.SELL_PRICE, 
	ItemUnique = _G.ITEM_UNIQUE, -- "Unique"
	ItemUniqueEquip = _G.ITEM_UNIQUE_EQUIPPABLE, -- "Unique-Equipped"
	ItemUniqueMultiple = _G.ITEM_UNIQUE_MULTIPLE, -- "Unique (%d)"
	ItemEquipEffect = _G.ITEM_SPELL_TRIGGER_ONEQUIP, -- "Equip:"
	ItemUseEffect = _G.ITEM_SPELL_TRIGGER_ONUSE, -- "Use:"
	Level = _G.LEVEL,

	RangeCaster = _G.SPELL_RANGE_AREA,
	RangeMelee = _G.MELEE_RANGE,
	RangeSpell = _G.SPELL_RANGE, -- SPELL_RANGE_DUAL = "%1$s: %2$s yd range"
	RangeUnlimited = _G.SPELL_RANGE_UNLIMITED, 

	SpellRequiresForm = _G.SPELL_REQUIRED_FORM, 
}

-- Listing them for personal reference
--FRIENDS_LEVEL_TEMPLATE = "Level %d %s"
--UNIT_LETHAL_LEVEL_DEAD_TEMPLATE = "Level ?? Corpse"
--UNIT_LETHAL_LEVEL_TEMPLATE = "Level ??"
--UNIT_LEVEL_DEAD_TEMPLATE = "Level %d Corpse"
--UNIT_LEVEL_TEMPLATE = "Level %d"
--UNIT_PLUS_LEVEL_TEMPLATE = "Level %d Elite"
--UNIT_TYPE_LETHAL_LEVEL_TEMPLATE = "Level ?? %s"
--UNIT_TYPE_LEVEL_TEMPLATE = "Level %d %s"
--UNIT_TYPE_PLUS_LEVEL_TEMPLATE = "Level %d Elite %s"

	--[[

	[CastTime]
	SPELL_RECAST_TIME_CHARGEUP_INSTANT = "Instant"
	SPELL_CAST_TIME_INSTANT = "Instant"
	SPELL_CAST_TIME_INSTANT_NO_MANA = "Instant"
	SPELL_CAST_TIME_MIN = "%.3g min cast"
	SPELL_CAST_TIME_SEC = "%.3g sec cast"

	[CooldownTime]
	SPELL_RECAST_TIME_INSTANT = "Instant cooldown"
	SPELL_RECAST_TIME_DAYS = "%.3g day cooldown"
	SPELL_RECAST_TIME_HOURS = "%.3g hour cooldown"
	SPELL_RECAST_TIME_MIN = "%.3g min cooldown"
	SPELL_RECAST_TIME_SEC = "%.3g sec cooldown"
	SPELL_RECAST_TIME_CHARGES_DAYS = "%.3g day recharge"
	SPELL_RECAST_TIME_CHARGES_HOURS = "%.3g hour recharge"
	SPELL_RECAST_TIME_CHARGES_INSTANT = "Instant recharge"
	SPELL_RECAST_TIME_CHARGES_MIN = "%.3g min recharge"
	SPELL_RECAST_TIME_CHARGES_SEC = "%.3g sec recharge"

	[Cooldown/Chargetime remaining]

	SPELL_RECAST_TIME_CHARGEUP_DAYS = "%.3g |4day:days; required"
	SPELL_RECAST_TIME_CHARGEUP_HOURS = "%.3g |4hour:hours; required"
	SPELL_RECAST_TIME_CHARGEUP_MIN = "%.3g min required"
	SPELL_RECAST_TIME_CHARGEUP_SEC = "%.3g sec required"

	SPELL_RECHARGE_TIME = "Recharging: %s"
	SPELL_RECHARGE_TIME_DAYS = "Recharging: %d |4day:days;"
	SPELL_RECHARGE_TIME_HOURS = "Recharging: %d |4hour:hours;"
	SPELL_RECHARGE_TIME_MIN = "Recharging: %d min"
	SPELL_RECHARGE_TIME_SEC = "Recharging: %d sec"

	COOLDOWN_REMAINING = "Cooldown remaining:"
	ITEM_COOLDOWN_TIME = "Cooldown remaining: %s"
	ITEM_COOLDOWN_TIME_DAYS = "Cooldown remaining: %d |4day:days;"
	ITEM_COOLDOWN_TIME_HOURS = "Cooldown remaining: %d |4hour:hours;"
	ITEM_COOLDOWN_TIME_MIN = "Cooldown remaining: %d min"
	ITEM_COOLDOWN_TIME_SEC = "Cooldown remaining: %d sec"
	]]

local singlePattern = function(msg, plain)
	msg = msg:gsub("%%%d?$?c", ".+")
	msg = msg:gsub("%%%d?$?d", "%%d+")
	msg = msg:gsub("%%%d?$?s", ".+")
	msg = msg:gsub("([%(%)])", "%%%1")
	msg = msg:gsub("|4(.+):.+;", "%1")
	return plain and msg or ("^" .. msg)
end

local pluralPattern = function(msg, plain)
	msg = msg:gsub("%%%d?$?c", ".+")
	msg = msg:gsub("%%%d?$?d", "%%d+")
	msg = msg:gsub("%%%d?$?s", ".+")
	msg = msg:gsub("([%(%)])", "%%%1")
	msg = msg:gsub("|4.+:(.+);", "%1")
	return plain and msg or ("^" .. msg)
end
	
-- Will come up with a better system as this expands, 
-- just doing it fast and simple for now.
local Patterns = {

	ContainerSlots = 			"^" .. string_gsub(string_gsub(Constants.ContainerSlots, "%%d", "(%%d+)"), "%%s", "(%.+)"),
	ItemBlock = 				"^" .. string_gsub(string_gsub(Constants.ItemBlock, "%%d", "(%%d+)"), "%%s", "(%%w)"),
	ItemDamage = 				"^" .. string_gsub(string_gsub(Constants.ItemDamage, "%%s", "(%%d+)"), "%-", "%%-"),
	ItemDurability = 			"^" .. string_gsub(Constants.ItemDurability, "%%d", "(%%d+)"),
	ItemLevel = 				"^" .. string_gsub(Constants.ItemLevel, "%%d", "(%%d+)"),
	Level = 						   Constants.Level,

	-- For aura scanning
	AuraTimeRemaining1 =  			   singlePattern(_G.SPELL_TIME_REMAINING_DAYS),
	AuraTimeRemaining2 = 			   singlePattern(_G.SPELL_TIME_REMAINING_HOURS),
	AuraTimeRemaining3 = 			   singlePattern(_G.SPELL_TIME_REMAINING_MIN),
	AuraTimeRemaining4 = 			   singlePattern(_G.SPELL_TIME_REMAINING_SEC),
	AuraTimeRemaining5 = 			   pluralPattern(_G.SPELL_TIME_REMAINING_DAYS),
	AuraTimeRemaining6 = 			   pluralPattern(_G.SPELL_TIME_REMAINING_HOURS),
	AuraTimeRemaining7 = 			   pluralPattern(_G.SPELL_TIME_REMAINING_MIN),
	AuraTimeRemaining8 = 			   pluralPattern(_G.SPELL_TIME_REMAINING_SEC),

	-- Total Cast Time
	CastTime1 = 				"^" .. Constants.CastInstant, 
	CastTime2 = 				"^" .. string_gsub(Constants.CastTimeSec, "%%%.%dg", "(%.+)"),
	CastTime3 = 				"^" .. string_gsub(Constants.CastTimeMin, "%%%.%dg", "(%.+)"),
	CastTime4 = 				"^" .. Constants.CastChanneled, 

	-- CooldownRemaining
	CooldownTimeRemaining1 = 		   string_gsub(Constants.CooldownTimeRemaining1, "%%d", "(%%d+)"), 
	CooldownTimeRemaining2 = 		   string_gsub(Constants.CooldownTimeRemaining2, "%%d", "(%%d+)"), 
	CooldownTimeRemaining3 = 		   string_gsub(Constants.CooldownTimeRemaining3, "%%d", "(%%d+)"), 

	-- Item binds 
	ItemBind1 = 				"^" .. Constants.ItemBoundSoul, 
	ItemBind2 = 				"^" .. Constants.ItemBoundAccount, 
	ItemBind3 = 				"^" .. Constants.ItemBoundBnet, 

	-- Item required level 
	ItemReqLevel = 				"^" .. Constants.ItemReqLevel, 

	-- Item sell price
	ItemSellPrice = 			"^" .. Constants.ItemSellPrice,

	-- Item unique status
	ItemUnique1 = 				"^" .. Constants.ItemUnique,
	ItemUnique2 = 				"^" .. Constants.ItemUniqueEquip,
	ItemUnique3 = 				"^" .. string_gsub(Constants.ItemUniqueMultiple, "%%d", "(%%d+)"),

	-- Item effects
	ItemEquipEffect = 			"^" .. Constants.ItemEquipEffect, 
	ItemUseEffect = 			"^" .. Constants.ItemUseEffect, 

	-- Recharge Remaining
	RechargeTimeRemaining1 = 	"^" .. string_gsub(Constants.RechargeTimeRemaining1, "%%d", "(%%d+)"), 
	RechargeTimeRemaining2 = 	"^" .. string_gsub(Constants.RechargeTimeRemaining2, "%%d", "(%%d+)"), 
	RechargeTimeRemaining3 = 	"^" .. string_gsub(Constants.RechargeTimeRemaining3, "%%d", "(%%d+)"), 
	
	-- Spell Range
	Range1 = 					"^" .. Constants.RangeMelee,
	Range2 = 					"^" .. Constants.RangeUnlimited,
	Range3 = 					"^" .. Constants.RangeCaster, 
	Range4 = 					"^" .. string_gsub(Constants.RangeSpell, "%%s", "(%.+)"),

	-- Spell Requirements
	SpellRequiresForm = 			   "(" .. (string_gsub(Constants.SpellRequiresForm, "%%s", "(.+)")) .. ")", 

}

local isPrimaryStat = {
	ITEM_MOD_STRENGTH_SHORT = true,
	ITEM_MOD_AGILITY_SHORT = true,
	ITEM_MOD_INTELLECT_SHORT = true,
}

local isSecondaryStat = {
	ITEM_MOD_CRIT_RATING_SHORT = true, 
	ITEM_MOD_HASTE_RATING_SHORT = true, 
	ITEM_MOD_MASTERY_RATING_SHORT = true, 
	ITEM_MOD_VERSATILITY = true, 

	ITEM_MOD_CR_LIFESTEAL_SHORT = true, 
	ITEM_MOD_CR_AVOIDANCE_SHORT = true, 
	ITEM_MOD_CR_SPEED_SHORT = true, 

	ITEM_MOD_DODGE_RATING_SHORT = true, 
	ITEM_MOD_PARRY_RATING_SHORT = true, 

	ITEM_MOD_BLOCK_VALUE_SHORT = true, 
	ITEM_MOD_BLOCK_RATING_SHORT = true, 
}

local sorted2ndStats = {
	"ITEM_MOD_CRIT_RATING_SHORT", 
	"ITEM_MOD_HASTE_RATING_SHORT", 
	"ITEM_MOD_MASTERY_RATING_SHORT", 
	"ITEM_MOD_VERSATILITY", 

	"ITEM_MOD_CR_LIFESTEAL_SHORT", 
	"ITEM_MOD_CR_AVOIDANCE_SHORT", 
	"ITEM_MOD_CR_SPEED_SHORT", 

	"ITEM_MOD_DODGE_RATING_SHORT", 
	"ITEM_MOD_PARRY_RATING_SHORT", 

	"ITEM_MOD_BLOCK_VALUE_SHORT", 
	"ITEM_MOD_BLOCK_RATING_SHORT",
}

-- Utility Functions
---------------------------------------------------------
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

-- Check if a given itemLink is a caged battle pet
local GetBattlePetInfo = function(itemLink)
	if (not string_find(itemLink, "battlepet")) then
		return
	end
	local data, name = string_match(itemLink, "|H(.-)|h(.-)|h")
	local  _, _, level, rarity = string_match(data, "(%w+):(%d+):(%d+):(%d+)")
	return true, level or 1, tonumber(rarity) or 0
end

-- Library API
---------------------------------------------------------
-- *Methods will return nil if no data was found, 
--  or a table populated with data if something was found.
-- *Methods can provide an optional table
--  to be populated by the retrieved data.

LibTooltipScanner.GetTooltipDataForAction = function(self, actionSlot, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	--  Blizz Action Tooltip Structure: 
	--  *the order is consistent, bracketed elements optional
	--  
	--------------------------------------------
	--	Name                    [School/Type] --
	--	[Cost][Range]                 [Range] --
	--	[CastTime]             [CooldownTime] --
	--	[Cooldown/Chargetime remaining      ] -- 
	--	[                                   ] --
	--	[            Description            ] --
	--	[                                   ] --
	--	[Resource awarded / Max charges     ] --
	--------------------------------------------

	if HasAction(actionSlot) then 

		-- Switch to action item function if the action contains an item
		local actionType, id = GetActionInfo(actionSlot)
		if (actionType == "item") then 
			return self:GetTooltipDataForActionItem(actionSlot)
		end 

		Scanner:SetAction(actionSlot)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		-- Retrieve generic data
		local macroName = GetActionText(actionSlot)
		local texture = GetActionTexture(actionSlot)
		local count = GetActionCount(actionSlot)
		local cooldownStart, cooldownDuration, cooldownEnable, cooldownModRate = GetActionCooldown(actionSlot)
		local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(actionSlot)
		local locStart, locDuration = GetActionLossOfControlCooldown(actionSlot)
		local outOfRange = IsActionInRange(actionSlot) == 0

		-- Generic stuff
		tbl.macroName = name
		tbl.texture = texture
		tbl.count = count
		tbl.charges = charges
		tbl.maxCharges = maxCharges
		tbl.chargeStart = chargeStart
		tbl.chargeDuration = chargeDuration
		tbl.chargeModRate = chargeModRate
		tbl.cooldownStart = cooldownStart
		tbl.cooldownDuration = cooldownDuration
		tbl.cooldownEnable = cooldownEnable
		tbl.cooldownModRate = cooldownModRate
		tbl.locStart = locStart
		tbl.locDuration = locDuration
		tbl.outOfRange = outOfRange

		local left, right

		-- Action Name
		left = _G[ScannerName.."TextLeft1"]
		if left:IsShown() then 
			local msg = left:GetText()
			if msg and (msg ~= "") then 
				tbl.name = msg
			else 
				-- if the name isn't there, no point going on
				return nil
			end 
		end


		-- Spell school / Spell Type (could be "Racial")
		right = _G[ScannerName.."TextRight1"]
		if right:IsShown() then 
			local msg = right:GetText()
			if msg and (msg ~= "") then 
				tbl.schoolType = msg
			end 
		end 
		
		local foundCost, foundRange
		local foundCastTime, foundCooldownTime
		local foundRemainingCooldown, foundRemainingRecharge
		local foundDescription
		local foundResourceMod
		local foundRequirement, foundUnmetRequirement
		
		local numLines = Scanner:NumLines() -- total number of lines
		local lastInfoLine = 1 -- The last line where information exists

		-- Iterate available lines for action information
		for lineIndex = 2, (numLines < 4) and numLines or 4  do 

			left, right = _G[ScannerName.."TextLeft"..lineIndex],  _G[ScannerName.."TextRight"..lineIndex]
			if (left and right) then 

				local leftMsg, rightMsg = left:GetText(), right:GetText()

				-- Left side iterations
				if (leftMsg and (leftMsg ~= "")) then 

					-- search for range
					if (not foundRange) then 
						local id = 1
						while Patterns["Range"..id] do 
							if (string_find(leftMsg, Patterns["Range"..id])) then 
							
								-- found the range line
								foundRange = lineIndex
								tbl.spellRange = leftMsg
								tbl.spellCost = nil

								-- it has no cost if the range is on this side
								foundCost = true

								if (lastInfoLine < foundRange) then 
									lastInfoLine = foundRange
								end 
	
								break
							end 
							id = id + 1
						end 
					end 

					-- search for cast time
					if (not foundCastTime) then 
						local id = 1
						while Patterns["CastTime"..id] do 
							if (string_find(leftMsg, Patterns["CastTime"..id])) then 

								-- found the range line
								foundCastTime = lineIndex
								tbl.castTime = leftMsg

								if (lastInfoLine < foundCastTime) then 
									lastInfoLine = foundCastTime
								end 

								-- if there is something on the right side, it's the total cooldown
								if (rightMsg and (rightMsg ~= "")) then 
									foundCooldownTime = foundCooldownTime
									tbl.cooldownTime = rightMsg
								end  

								break
							end 
							id = id + 1
						end 
					end 

					--if (string_find(msg, Patterns.CooldownRemaining)) then 
					--end 

					--if (string_find(msg, SPELL_RECHARGE_TIME)) then 
					--end 

					if not(foundUnmetRequirement or foundRequirement) and string_find(leftMsg, Patterns.SpellRequiresForm) then 
						local r, g, b = left:GetTextColor()
						if (r + g + b < 2) then 
							foundUnmetRequirement = lineIndex
							tbl.unmetRequirement = leftMsg
						else 
							foundRequirement = lineIndex
							tbl.requirement = leftMsg
						end 
					end 

					-- Search for remaining cooldown, if one is active (?)
					if (not foundRemainingCooldown) then 
						local id = 1
						while Patterns["CooldownTimeRemaining"..id] do 
							if (string_find(leftMsg, Patterns["CooldownTimeRemaining"..id])) then 

								-- Need this to figure out how far down the description starts!
								foundRemainingCooldown = lineIndex

								if (lastInfoLine < foundRemainingCooldown) then 
									lastInfoLine = foundRemainingCooldown
								end 

								-- *not needed, we're getting that from API calls above!
								--tbl.cooldownTimeRemaining = leftMsg

								break
							end 
							id = id + 1
						end 
					end  

					-- Search for remaining cooldown, if one is active (?)
					if (not foundRemainingRecharge) then 
						local id = 1
						while Patterns["RechargeTimeRemaining"..id] do 
							if (string_find(leftMsg, Patterns["RechargeTimeRemaining"..id])) then 

								-- Need this to figure out how far down the description starts!
								foundRemainingRecharge = lineIndex

								if (lastInfoLine < foundRemainingRecharge) then 
									lastInfoLine = foundRemainingRecharge
								end 

								-- *not needed, we're getting that from API calls above!
								--tbl.rechargeTimeRemaining = leftMsg

								break
							end 
							id = id + 1
						end 
					end  
					
				end 

				-- Right side iterations
				if (rightMsg and (rightMsg ~= "")) then 

					-- search for range
					if (not foundRange) then 
						local id = 1
						while Patterns["Range"..id] do 
							if (string_find(rightMsg, Patterns["Range"..id])) then 
							
								-- found the range line
								foundRange = lineIndex
								tbl.spellRange = rightMsg

								if (lastInfoLine < foundRange) then 
									lastInfoLine = foundRange
								end 
	
								-- if there is something on the left side, it's the cost
								if (leftMsg and (leftMsg ~= "")) then 
									foundCost = lineIndex
									tbl.spellCost = leftMsg
								end  

								break
							end 
							id = id + 1
						end 
					end 

				end 

			end 
		end

		-- Just assume all remaining lines are description, 
		-- and bunch them together to a single line. 
		if (numLines > lastInfoLine) then 
			for lineIndex = lastInfoLine+1, numLines do 
				left = _G[ScannerName.."TextLeft"..lineIndex]
				if left and (lineIndex ~= foundRequirement) and (lineIndex ~= foundUnmetRequirement) then 
					local msg = left:GetText()
					if msg then
						if tbl.description then 
							if (msg == "") then 
								tbl.description = tbl.description .. "|n|n" -- empty line/space
							else 
								tbl.description = tbl.description .. "|n" .. msg -- normal line break
							end 
						else 
							tbl.description = msg -- first line
						end 
					end 
				end 
			end 
		end 

		return tbl
	end 

end

-- Special combo variant that returns item info from an action slot
LibTooltipScanner.GetTooltipDataForActionItem = function(self, actionSlot, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	--  Blizz Action Tooltip Structure: 
	--  *the order is consistent, bracketed elements optional
	--  
	--------------------------------------------
	--	Name                    [School/Type] --
	--	[Cost]                        [Range] --
	--	[CastTime]             [CooldownTime] --
	--	[Cooldown/Chargetime remaining      ] -- 
	--	[                                   ] --
	--	[            Description            ] --
	--	[                                   ] --
	--	[Resource awarded / Max charges     ] --
	--------------------------------------------

	if HasAction(actionSlot) then 
		Scanner:SetAction(actionSlot)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		local itemName, itemLink = Scanner:GetItem()
		if (not itemName) then 
			return 
		end 

		-- Get some blizzard info about the current item
		local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)

		local effectiveLevel, previewLevel, origLevel = GetDetailedItemLevelInfo(itemLink)
		local isBattlePet, battlePetLevel, battlePetRarity = GetBattlePetInfo and GetBattlePetInfo(itemLink)

		local itemStats = GetItemStats(itemLink)

		local spec = GetSpecialization and GetSpecialization()
		local role = GetSpecializationRole and GetSpecializationRole(spec)
		local primaryStat = GetSpecializationInfo and select(6, GetSpecializationInfo(spec, nil, nil, nil, UnitSex("player")))

		tbl.itemName = itemName -- localized
		tbl.itemID = tonumber(string_match(itemLink, "item:(%d+)"))
		tbl.itemString = string_match(itemLink, "item[%-?%d:]+")

		tbl.itemRarity = itemRarity
		tbl.itemMinLevel = itemMinLevel
		tbl.itemType = itemType -- localized
		tbl.itemSubType = itemSubType -- localized
		tbl.itemStackCount = itemStackCount
		tbl.itemEquipLoc = itemEquipLoc
		tbl.itemClassID = itemClassID
		tbl.itemSubClassID = itemSubClassID
		tbl.itemBindType = bindType 
		tbl.itemSetID = itemSetID
		tbl.isBattlePet = isBattlePet
		tbl.isCraftingReagent = isCraftingReagent
		tbl.itemArmor = itemStats and tonumber(itemStats.RESISTANCE0_NAME)
		tbl.itemStamina = itemStats and tonumber(itemStats.ITEM_MOD_STRENGTH_SHORT)
		tbl.itemDPS = itemStats and tonumber(itemStats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT)
		tbl.uselessStats = {}
		tbl.secondaryStats = {}	

		local primaryKey
		if (primaryStat == LE_UNIT_STAT_STRENGTH) then 
			primaryKey = "ITEM_MOD_STRENGTH_SHORT"
			tbl.primaryStat = ITEM_MOD_STRENGTH_SHORT
			tbl.primaryStatValue = itemStats and tonumber(itemStats.ITEM_MOD_STRENGTH_SHORT)
		elseif (primaryStat == LE_UNIT_STAT_AGILITY) then 
			primaryKey = "ITEM_MOD_AGILITY_SHORT"
			tbl.primaryStat = ITEM_MOD_AGILITY_SHORT
			tbl.primaryStatValue = itemStats and tonumber(itemStats.ITEM_MOD_AGILITY_SHORT)
		elseif (primaryStat == LE_UNIT_STAT_INTELLECT) then 
			primaryKey = "ITEM_MOD_INTELLECT_SHORT"
			tbl.primaryStat = ITEM_MOD_INTELLECT_SHORT
			tbl.primaryStatValue = itemStats and tonumber(itemStats.ITEM_MOD_INTELLECT_SHORT)
		end 

		local has2ndStats
		if itemStats then
			for key,value in pairs(itemStats) do 
				if (isPrimaryStat[key] and (key ~= primaryKey)) then 
					tbl.uselessStats[key] = value
				end 
				if (isSecondaryStat[key]) then 
					tbl.secondaryStats[key] = value
					has2ndStats = true
				end 
			end 
		end 

		-- make a sort table of secondary stats
		if has2ndStats then 
			tbl.sorted2ndStats = {}
			for i,key in pairs(sorted2ndStats) do 
				local value = tbl.secondaryStats[key]
				if value then 
					tbl.sorted2ndStats[#tbl.sorted2ndStats + 1] = string_format("%s %s", (value > 0) and ("+"..tostring(value)) or tostring(value), _G[key])
				end 
			end 
		end 

		-- Get the item level
		local line = _G[ScannerName.."TextLeft2"]
		if line then
			local msg = line:GetText()
			if msg and string_find(msg, Patterns.ItemLevel) then
				local itemLevel = tonumber(string_match(msg, Patterns.ItemLevel))
				if (itemLevel and (itemLevel > 0)) then
					tbl.itemLevel = itemLevel
				end
			else
				-- Check line 3, some artifacts have the ilevel there
				line = _G[ScannerName.."TextLeft3"]
				if line then
					local msg = line:GetText()
					if msg and string_find(msg, Patterns.ItemLevel) then
						local itemLevel = tonumber(string_match(msg, Patterns.ItemLevel))
						if (itemLevel and (itemLevel > 0)) then
							tbl.itemLevel = itemLevel
						end
					end
				end
			end
		end

		local foundItemBlock, foundItemBind, foundItemUnique, foundItemDurability, foundItemDamage, foundItemSpeed, foundItemSellPrice, foundItemReqLevel, foundUseEffect, foundEquipEffect
					
		local numLines = Scanner:NumLines()
		local firstLine, lastLine = 2, numLines

		for lineIndex = 2,numLines do 
			local line = _G[ScannerName.."TextLeft"..lineIndex]
			if line then 
				local msg = line:GetText()
				if msg then 

					-- item damage 
					if ((not foundItemDamage) and (string_find(msg, Patterns.ItemDamage))) then 
						local min,max = string_match(msg, Patterns.ItemDamage)
						if (max) then 
							foundItemDamage = lineIndex
							tbl.itemDamageMin = tonumber(min)
							tbl.itemDamageMax = tonumber(max)
							if (not foundItemSpeed) then 
								local line = _G[ScannerName.."TextRight"..lineIndex]
								if line then 
									local msg = line:GetText()
									if msg then 
										local int,float = string_match(msg, "(%d+)%.(%d+)")
										if (int or float) then 
											if (lineIndex >= firstLine) then 
												firstLine = lineIndex + 1
											end 
											foundItemSpeed = lineIndex
											tbl.itemSpeed = int .. "." .. (float or 00)
										end 
									end 
								end 
							end 
						end 
					end 

					-- item durability
					if ((not foundItemDurability) and (string_find(msg, Patterns.ItemDurability))) then 
						local min,max = string_match(msg, Patterns.ItemDurability)
						if (max) then 
							if (lineIndex <= lastLine) then 
								lastLine = lineIndex - 1
							end 
							foundItemDurability = lineIndex
							tbl.itemDurability = tonumber(min)
							tbl.itemDurabilityMax = tonumber(max)
						end 
					end 

					-- shield block isn't included in the itemstats table for some reason
					if ((not foundItemBlock) and (string_find(msg, Patterns.ItemBlock))) then 
						local itemBlock = tonumber(string_match(msg, Patterns.ItemBlock))
						if (itemBlock and (itemBlock ~= 0)) then 
							if (lineIndex >= firstLine) then 
								firstLine = lineIndex + 1
							end 
							foundItemBlock = lineIndex
							tbl.itemBlock = itemBlock
						end 
					end 

					-- item binds
					if ((not foundItemBind) and ((bindType == 1) or (bindType == 2) or (bindType == 3))) then 
						local id = 1
						while Patterns["ItemBind"..id] do 
							if (string_find(msg, Patterns["ItemBind"..id])) then 
								if (lineIndex >= firstLine) then 
									firstLine = lineIndex + 1
								end 
								
								-- found the bind line
								foundItemBind = lineIndex
								tbl.itemBind = msg
								tbl.itemIsBound = true
	
								break
							end 
							id = id + 1
						end 
					end 

					-- item unique stats
					if (not foundItemUnique) then 
						local id = 1
						while Patterns["ItemUnique"..id] do 
							if (string_find(msg, Patterns["ItemUnique"..id])) then 
								if (lineIndex >= firstLine) then 
									firstLine = lineIndex + 1 
								end 
								
								-- found the unique line
								foundItemUnique = lineIndex
								tbl.itemUnique = msg
								tbl.itemIsUnique = true
	
								break
							end 
							id = id + 1
						end 
					end 

					-- item Use effect. Can only be one. I think. 
					if ((not foundUseEffect) and (string_find(msg, Patterns.ItemUseEffect))) then 
						foundUseEffect = lineIndex
						tbl.itemUseEffect = msg
						tbl.itemHasUseEffect = true
					end 

					-- Items can have multiple Equip effects
					--if ((not foundEquipEffect) and (string_find(msg, Patterns.ItemEquipEffect))) then 
					if (string_find(msg, Patterns.ItemEquipEffect)) then 
						if (not tbl.itemEquipEffects) then 
							tbl.itemEquipEffects = {}
						end 
						if (not foundEquipEffect) then
							foundEquipEffect = {}
						end  
						foundEquipEffect[#foundEquipEffect + 1] = lineIndex
						tbl.itemEquipEffects[#tbl.itemEquipEffects + 1] = msg
						tbl.itemHasEquipEffect = true
					end 

					-- item sell price
					-- *we don't retrieve this from here, but need to know the line number
					if ((not foundItemSellPrice) and (string_find(msg, Patterns.ItemSellPrice))) then 
						if (lineIndex <= lastLine) then 
							lastLine = lineIndex - 1
						end 
						foundItemSellPrice = lineIndex
					end 

					-- item required level
					-- *we don't retrieve this from here, but need to know the line number
					if ((not foundItemReqLevel) and (string_find(msg, Patterns.ItemReqLevel))) then 
						if (lineIndex <= lastLine) then 
							lastLine = lineIndex - 1
						end 
						foundItemReqLevel = lineIndex
					end 

				end 
			end 
		end 

		-- Figure out a description for select items
		if (itemClassID == LE_ITEM_CLASS_MISCELLANEOUS) or (itemClassID == LE_ITEM_CLASS_CONSUMABLE) then 
			for lineIndex = firstLine, lastLine do 
				if (lineIndex ~= foundItemBlock)
					and (lineIndex ~= foundItemBind)
					and (lineIndex ~= foundItemUnique)
					and (lineIndex ~= foundItemDamage)
					and (lineIndex ~= foundItemDurability)
					and (lineIndex ~= foundItemSpeed)
					and (lineIndex ~= foundItemSellPrice)
					and (lineIndex ~= foundItemReqLevel)
					and (lineIndex ~= foundUseEffect)
				then 
					local skip
					if foundEquipEffect then 
						for lineID in pairs(foundEquipEffect) do 
							if (lineID == lineIndex) then 
								skip = true 
								break 
							end
						end
					end 
					if (not skip) then 
						local line = _G[ScannerName.."TextLeft"..lineIndex]
						if line then 
							local msg = line:GetText()
							if (msg and (msg ~= "") and (msg ~= " ")) then 
								if (not tbl.itemDescription) then 
									tbl.itemDescription = {}
								end 
								tbl.itemDescription[#tbl.itemDescription + 1] = msg
							end 
						end 
					end 
				end
			end 
		end 

		return tbl
	end 
end 

LibTooltipScanner.GetTooltipDataForPetAction = function(self, actionSlot, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")


	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(actionSlot)
	if name then 
		
		Scanner:SetPetAction(actionSlot)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		tbl.name = name
		tbl.texture = texture
		tbl.isToken = isToken
		tbl.isActive = isActive
		tbl.autoCastAllowed = autoCastAllowed
		tbl.autoCastEnabled = autoCastEnabled
		tbl.spellID = spellID

		local left, right
	
		-- Action Name
		left = _G[ScannerName.."TextLeft1"]
		if left:IsShown() then 
			local msg = left:GetText()
			if msg and (msg ~= "") then 
				tbl.name = msg
			else 
				-- if the name isn't there, no point going on
				return nil
			end 
		end

		local foundCost, foundRange
		local foundCastTime, foundCooldownTime
		local foundRemainingCooldown, foundRemainingRecharge
		local foundDescription
		local foundResourceMod
		
		local numLines = Scanner:NumLines() -- total number of lines
		local lastInfoLine = 1 -- The last line where information exists

		-- Iterate available lines for action information
		for lineIndex = 2, (numLines < 4) and numLines or 4  do 

			left, right = _G[ScannerName.."TextLeft"..lineIndex],  _G[ScannerName.."TextRight"..lineIndex]
			if (left and right) then 

				local leftMsg, rightMsg = left:GetText(), right:GetText()

				-- Left side iterations
				if (leftMsg and (leftMsg ~= "")) then 

					-- search for range
					if (not foundRange) then 
						local id = 1
						while Patterns["Range"..id] do 
							if (string_find(leftMsg, Patterns["Range"..id])) then 
							
								-- found the range line
								foundRange = lineIndex
								tbl.spellRange = leftMsg
								tbl.spellCost = nil

								-- it has no cost if the range is on this side
								foundCost = true

								if (lastInfoLine < foundRange) then 
									lastInfoLine = foundRange
								end 
	
								break
							end 
							id = id + 1
						end 
					end 

					-- search for cast time
					if (not foundCastTime) then 
						local id = 1
						while Patterns["CastTime"..id] do 
							if (string_find(leftMsg, Patterns["CastTime"..id])) then 

								-- found the range line
								foundCastTime = lineIndex
								tbl.castTime = leftMsg

								if (lastInfoLine < foundCastTime) then 
									lastInfoLine = foundCastTime
								end 

								-- if there is something on the right side, it's the total cooldown
								if (rightMsg and (rightMsg ~= "")) then 
									foundCooldownTime = foundCooldownTime
									tbl.cooldownTime = rightMsg
								end  

								break
							end 
							id = id + 1
						end 
					end 

					--if (string_find(msg, Patterns.CooldownRemaining)) then 
					--end 

					--if (string_find(msg, SPELL_RECHARGE_TIME)) then 
					--end 

					-- Search for remaining cooldown, if one is active (?)
					if (not foundRemainingCooldown) then 
						local id = 1
						while Patterns["CooldownTimeRemaining"..id] do 
							if (string_find(leftMsg, Patterns["CooldownTimeRemaining"..id])) then 

								-- Need this to figure out how far down the description starts!
								foundRemainingCooldown = lineIndex

								if (lastInfoLine < foundRemainingCooldown) then 
									lastInfoLine = foundRemainingCooldown
								end 

								-- *not needed, we're getting that from API calls above!
								--tbl.cooldownTimeRemaining = leftMsg

								break
							end 
							id = id + 1
						end 
					end  

					-- Search for remaining cooldown, if one is active (?)
					if (not foundRemainingRecharge) then 
						local id = 1
						while Patterns["RechargeTimeRemaining"..id] do 
							if (string_find(leftMsg, Patterns["RechargeTimeRemaining"..id])) then 

								-- Need this to figure out how far down the description starts!
								foundRemainingRecharge = lineIndex

								if (lastInfoLine < foundRemainingRecharge) then 
									lastInfoLine = foundRemainingRecharge
								end 

								-- *not needed, we're getting that from API calls above!
								--tbl.rechargeTimeRemaining = leftMsg

								break
							end 
							id = id + 1
						end 
					end  
					
				end 

				-- Right side iterations
				if (rightMsg and (rightMsg ~= "")) then 

					-- search for range
					if (not foundRange) then 
						local id = 1
						while Patterns["Range"..id] do 
							if (string_find(rightMsg, Patterns["Range"..id])) then 
							
								-- found the range line
								foundRange = lineIndex
								tbl.spellRange = rightMsg

								if (lastInfoLine < foundRange) then 
									lastInfoLine = foundRange
								end 
	
								-- if there is something on the left side, it's the cost
								if (leftMsg and (leftMsg ~= "")) then 
									foundCost = lineIndex
									tbl.spellCost = leftMsg
								end  

								break
							end 
							id = id + 1
						end 
					end 

				end 

			end 
		end

		-- Just assume all remaining lines are description, 
		-- and bunch them together to a single line. 
		if (numLines > lastInfoLine) then 
			for lineIndex = lastInfoLine+1, numLines do 
				left = _G[ScannerName.."TextLeft"..lineIndex]
				if left then 
					local msg = left:GetText()
					if msg then
						if tbl.description then 
							if (msg == "") then 
								tbl.description = tbl.description .. "|n|n" -- empty line/space
							else 
								tbl.description = tbl.description .. "|n" .. msg -- normal line break
							end 
						else 
							tbl.description = msg -- first line
						end 
					end 
				end 
			end 
		end 

		return tbl
	end
end

LibTooltipScanner.GetTooltipDataForSpellID = function(self, spellID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	if (spellID and DoesSpellExist(spellID)) then 
		Scanner:SetSpellByID(spellID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		local name, _, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(spellID)
		if name then 
			tbl.name = name
			tbl.icon = icon 
			tbl.castTime = castTime 
			tbl.minRange = minRange
			tbl.maxRange = maxRange
			tbl.spellID = spellID

			local left, right

			-- Action Name
			left = _G[ScannerName.."TextLeft1"]
			if left:IsShown() then 
				local msg = left:GetText()
				if msg and (msg ~= "") then 
					tbl.name = msg
				else 
					-- if the name isn't there, no point going on
					return nil
				end 
			end

			-- Spell school / Spell Type (could be "Racial")
			right = _G[ScannerName.."TextRight1"]
			if right:IsShown() then 
				local msg = right:GetText()
				if msg and (msg ~= "") then 
					tbl.schoolType = msg
				end 
			end 
			
			local foundCost, foundRange
			local foundCastTime, foundCooldownTime
			local foundRemainingCooldown, foundRemainingRecharge
			local foundDescription
			local foundResourceMod
			
			local numLines = Scanner:NumLines() -- total number of lines
			local lastInfoLine = 1 -- The last line where information exists

			-- Iterate available lines for action information
			for lineIndex = 2, (numLines < 4) and numLines or 4  do 

				left, right = _G[ScannerName.."TextLeft"..lineIndex],  _G[ScannerName.."TextRight"..lineIndex]
				if (left and right) then 

					local leftMsg, rightMsg = left:GetText(), right:GetText()

					-- Left side iterations
					if (leftMsg and (leftMsg ~= "")) then 

						-- search for range
						if (not foundRange) then 
							local id = 1
							while Patterns["Range"..id] do 
								if (string_find(leftMsg, Patterns["Range"..id])) then 
								
									-- found the range line
									foundRange = lineIndex
									tbl.spellRange = leftMsg
									tbl.spellCost = nil

									-- it has no cost if the range is on this side
									foundCost = true

									if (lastInfoLine < foundRange) then 
										lastInfoLine = foundRange
									end 
		
									break
								end 
								id = id + 1
							end 
						end 

						-- search for cast time
						if (not foundCastTime) then 
							local id = 1
							while Patterns["CastTime"..id] do 
								if (string_find(leftMsg, Patterns["CastTime"..id])) then 

									-- found the range line
									foundCastTime = lineIndex
									tbl.castTime = leftMsg

									if (lastInfoLine < foundCastTime) then 
										lastInfoLine = foundCastTime
									end 

									-- if there is something on the right side, it's the total cooldown
									if (rightMsg and (rightMsg ~= "")) then 
										foundCooldownTime = foundCooldownTime
										tbl.cooldownTime = rightMsg
									end  

									break
								end 
								id = id + 1
							end 
						end 

						--if (string_find(msg, Patterns.CooldownRemaining)) then 
						--end 

						--if (string_find(msg, SPELL_RECHARGE_TIME)) then 
						--end 

						-- Search for remaining cooldown, if one is active (?)
						if (not foundRemainingCooldown) then 
							local id = 1
							while Patterns["CooldownTimeRemaining"..id] do 
								if (string_find(leftMsg, Patterns["CooldownTimeRemaining"..id])) then 

									-- Need this to figure out how far down the description starts!
									foundRemainingCooldown = lineIndex

									if (lastInfoLine < foundRemainingCooldown) then 
										lastInfoLine = foundRemainingCooldown
									end 

									-- *not needed, we're getting that from API calls above!
									--tbl.cooldownTimeRemaining = leftMsg

									break
								end 
								id = id + 1
							end 
						end  

						-- Search for remaining cooldown, if one is active (?)
						if (not foundRemainingRecharge) then 
							local id = 1
							while Patterns["RechargeTimeRemaining"..id] do 
								if (string_find(leftMsg, Patterns["RechargeTimeRemaining"..id])) then 

									-- Need this to figure out how far down the description starts!
									foundRemainingRecharge = lineIndex

									if (lastInfoLine < foundRemainingRecharge) then 
										lastInfoLine = foundRemainingRecharge
									end 

									-- *not needed, we're getting that from API calls above!
									--tbl.rechargeTimeRemaining = leftMsg

									break
								end 
								id = id + 1
							end 
						end  
						
					end 

					-- Right side iterations
					if (rightMsg and (rightMsg ~= "")) then 

						-- search for range
						if (not foundRange) then 
							local id = 1
							while Patterns["Range"..id] do 
								if (string_find(rightMsg, Patterns["Range"..id])) then 
								
									-- found the range line
									foundRange = lineIndex
									tbl.spellRange = rightMsg

									if (lastInfoLine < foundRange) then 
										lastInfoLine = foundRange
									end 
		
									-- if there is something on the left side, it's the cost
									if (leftMsg and (leftMsg ~= "")) then 
										foundCost = lineIndex
										tbl.spellCost = leftMsg
									end  

									break
								end 
								id = id + 1
							end 
						end 

					end 

				end 
			end

			-- Just assume all remaining lines are description, 
			-- and bunch them together to a single line. 
			if (numLines > lastInfoLine) then 
				for lineIndex = lastInfoLine+1, numLines do 
					left = _G[ScannerName.."TextLeft"..lineIndex]
					if left then 
						local msg = left:GetText()
						if msg then
							if tbl.description then 
								if (msg == "") then 
									tbl.description = tbl.description .. "|n|n" -- empty line/space
								else 
									tbl.description = tbl.description .. "|n" .. msg -- normal line break
								end 
							else 
								tbl.description = msg -- first line
							end 
						end 
					end 
				end 
			end 

		end 

		return tbl
	end 

end

LibTooltipScanner.GetTooltipDataForUnit = function(self, unit, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	if UnitExists(unit) then 
		Scanner:SetUnit(unit)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		-- Retrieve generic data
		local isPlayer = UnitIsPlayer(unit)
		local isBattlePet = UnitIsBattlePetCompanion and UnitIsBattlePetCompanion(unit)
		local isWildPet = UnitIsWildBattlePet and UnitIsWildBattlePet(unit)
		local unitLevel = UnitLevel(unit)
		local unitEffectiveLevel = UnitEffectiveLevel and UnitEffectiveLevel(unit) or unitLevel
		local unitName, unitRealm = UnitName(unit)
		local isDead = UnitIsDead(unit) or UnitIsGhost(unit)

		-- Generic stuff
		tbl.name = unitName

		-- Retrieve special data from the tooltip

		-- Players
		if isPlayer then 


			local classDisplayName, class, classID = UnitClass(unit)
			local englishFaction, localizedFaction = UnitFactionGroup(unit)
			local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(unit)
			local raceDisplayName, raceID = UnitRace(unit)
			local isAFK = UnitIsAFK(unit)
			local isDND = UnitIsDND(unit)
			local isDisconnected = not UnitIsConnected(unit)
			local isPVP = UnitIsPVP(unit)
			local isFFA = UnitIsPVPFreeForAll(unit)
			local pvpName = UnitPVPName(unit)

			tbl.isPlayer = isPlayer
			tbl.playerFaction = englishFaction
			tbl.englishFaction = englishFaction
			tbl.localizedFaction = localizedFaction
			tbl.level = unitLevel
			tbl.effectiveLevel = unitEffectiveLevel or unitLevel
			tbl.guild = guildName
			tbl.classDisplayName = classDisplayName
			tbl.class = class
			tbl.classID = classID
			tbl.raceDisplayName = raceDisplayName
			tbl.race = raceID
			tbl.raceID = raceID
			tbl.realm = unitRealm
			tbl.isAFK = isAFK
			tbl.isDND = isDND
			tbl.isDisconnected = isDisconnected
			tbl.isPVP = isPVP
			tbl.isFFA = isFFA
			tbl.pvpName = pvpName
	
		-- Vanity-, wild- and battle pets
		elseif (isWildPet or isBattlePet) then 

			local battlePetLevel = UnitBattlePetLevel(unit)
			local reaction = UnitReaction(unit, "player")

			tbl.isPet = true
			tbl.level = battlePetLevel
			tbl.effectiveLevel = battlePetLevel

			local line = _G[ScannerName.."TextLeft1"]
			if line then 
				msg = line:GetText()
				if msg then 
					msg = string_lower(msg)
					if string_find(msg, "^|cff") then 
						local color = string_sub(msg, 3, 10)
						if color then 
							for i,colors in ipairs(ITEM_QUALITY_COLORS) do 
								if (colors.color:GenerateHexColor() == color) then 
									tbl.petRarity = i + 1
									tbl.rarity = i
									break
								end 
							end 
						end 
					end 
				end 
			end 

		-- NPCs
		else 

			local reaction = UnitReaction(unit, "player")
			local classification = UnitClassification(unit)
			if (unitLevel < 0) or (unitEffectiveLevel < 0) then
				classification = "worldboss"
			end
	
			tbl.level = unitLevel
			tbl.effectiveLevel = unitEffectiveLevel or unitLevel
			tbl.classification = classification
			tbl.creatureFamily = UnitCreatureFamily(unit)
			tbl.creatureType = UnitCreatureType(unit)
			tbl.isBoss = classification == "worldboss"

			-- Flags to track what has been found, 
			-- since things are always placed in a certain order. 
			-- We'll be able to guesstimate what the content means by this. 
			local foundTitle, foundLevel, foundCity, foundPvP, foundLeader

			local numLines = Scanner:NumLines()
			for lineIndex = 2,numLines do 
				local line = _G[ScannerName.."TextLeft"..lineIndex]
				if line then 
					local msg = line:GetText()
					if msg then 
						if (string_find(msg, Patterns.Level) and (not string_find(msg, Patterns.ItemLevel))) then 

							foundLevel = lineIndex

							-- We found the level, let's backtrack to figure out the title!
							if (not foundTitle) and (lineIndex > 2) then 
								foundTitle = lineIndex - 1
								tbl.title = _G[ScannerName.."TextLeft"..foundTitle]:GetText()
							end 
						end 
			
						if (msg == PVP_ENABLED) then
							tbl.isPvPEnabled = true
							foundPvP = lineIndex

							-- We found PvP, is there a city line between this and level?
							if (not foundCity) and (foundLevel) and (lineIndex > foundLevel + 1) then 
								foundCity = lineIndex - 1
								tbl.city = _G[ScannerName.."TextLeft"..foundCity]:GetText()
							end 
						end

						if (msg == FACTION_ALLIANCE) or (msg == FACTION_HORDE) then
							tbl.localizedFaction = msg
						end
					end 
				end 
			end 
		end 

		return tbl
	end 
end

-- Will only return generic data based on mere itemID, no special instances of the item.
-- This is basically just a proxy for GetTooltipDataForItemLink. 
LibTooltipScanner.GetTooltipDataForItemID = function(self, itemID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemID)

	if itemName then 
		return self:GetTooltipDataForItemLink(_itemLink, tbl)
	end
end

-- Returns specific data for the specific itemLink
LibTooltipScanner.GetTooltipDataForItemLink = function(self, itemLink, tbl)

	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)

	if itemName then 
		Scanner:SetHyperlink(itemLink)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		-- Get some blizzard info about the current item
		local effectiveLevel, previewLevel, origLevel = GetDetailedItemLevelInfo(itemLink)
		local isBattlePet, battlePetLevel, battlePetRarity = GetBattlePetInfo(itemLink)

		tbl.itemID = tonumber(string_match(itemLink, "item:(%d+)"))
		tbl.itemString = string_match(itemLink, "item[%-?%d:]+")
		tbl.itemName = itemName
		tbl.itemRarity = itemRarity
		tbl.isBattlePet = isBattlePet
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx

		return tbl
	end 
end

-- Returns data about the exact bag- or bank slot. Will return all current mofidications.
LibTooltipScanner.GetTooltipDataForContainerSlot = function(self, bagID, slotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemID = GetContainerItemID(bagID, slotID)
	if itemID then 
		local hasCooldown, repairCost = Scanner:SetBagItem(bagID, slotID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end 

end

-- Returns data about the exact guild bank slot. Will return all current mofidications.
LibTooltipScanner.GetTooltipDataForGuildBankSlot = function(self, tabID, slotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemLink = GetGuildBankItemInfo(tabID, slotID)
	if itemLink then 
		local texturePath, itemCount, locked, isFiltered = GetGuildBankItemInfo(tabID, slotID)

		Scanner:SetGuildBankItem(tabID, slotID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end 
end

-- Returns data about equipped items
LibTooltipScanner.GetTooltipDataForInventorySlot = function(self, unit, inventorySlotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	-- https://wow.gamepedia.com/InventorySlotId
	local hasItem, hasCooldown, repairCost = Scanner:SetInventoryItem(unit, inventorySlotID)

	if hasItem then 

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		return tbl
	end
end

-- Returns data about mail inbox items
LibTooltipScanner.GetTooltipDataForInboxItem = function(self, inboxID, attachIndex, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	-- https://wow.gamepedia.com/API_GameTooltip_SetInboxItem
	-- attachIndex is in the range of [1,ATTACHMENTS_MAX_RECEIVE(16)]
	Scanner:SetInboxItem(inboxID, attachIndex)


		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


	return tbl
end

-- Returns data about unit auras 
LibTooltipScanner.GetTooltipDataForUnitAura = function(self, unit, auraID, filter, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitAura(unit, auraID, filter)

	if name then 
		Scanner:SetUnitAura(unit, auraID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		tbl.name = name
		tbl.icon = icon
		tbl.count = count
		tbl.debuffType = debuffType
		tbl.duration = duration
		tbl.expirationTime = expirationTime
		tbl.unitCaster = unitCaster
		tbl.isStealable = isStealable
		tbl.nameplateShowPersonal = nameplateShowPersonal
		tbl.spellId = spellId
		tbl.canApplyAura = canApplyAura
		tbl.isBossDebuff = isBossDebuff
		tbl.isCastByPlayer = isCastByPlayer
		tbl.nameplateShowAll = nameplateShowAll
		tbl.timeMod = timeMod
		tbl.value1 = value1
		tbl.value2 = value2
		tbl.value3 = value3

		local foundTimeRemaining
		local numLines = Scanner:NumLines()
		
		for lineIndex = 2,numLines do
			local line = _G[ScannerName.."TextLeft"..lineIndex]
			if line then
				local msg = line:GetText()
				if msg then
					local isTime

					local id = 1
					while Patterns["AuraTimeRemaining"..id] do 
						if (string_find(msg, Patterns["AuraTimeRemaining"..id])) then 
						
							-- found the range line
							foundTimeRemaining = lineIndex
							tbl.timeRemaining = msg

							break
						end 
						id = id + 1
					end 
				end
			end
		end

		-- Just assume all remaining lines are description, 
		-- and bunch them together to a single line. 
		if (numLines > 1) then 
			for lineIndex = 2, numLines do 
				if (lineIndex ~= foundTimeRemaining) then 
					local line = _G[ScannerName.."TextLeft"..lineIndex]
					if line then 
						local msg = line:GetText()
						if msg then
							if tbl.description then 
								if (msg == "") then 
									tbl.description = tbl.description .. "|n|n" -- empty line/space
								else 
									tbl.description = tbl.description .. "|n" .. msg -- normal line break
								end 
							else 
								tbl.description = msg -- first line
							end 
						end 
					end 
				end 
			end 
		end 

		return tbl
	end 
end 

-- Returns data about unit buffs
LibTooltipScanner.GetTooltipDataForUnitBuff = function(self, unit, buffID, filter, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitBuff(unit, buffID, filter)

	if name then 
		Scanner:SetUnitBuff(unit, buffID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		tbl.name = name
		tbl.icon = icon
		tbl.count = count
		tbl.debuffType = debuffType
		tbl.duration = duration
		tbl.expirationTime = expirationTime
		tbl.unitCaster = unitCaster
		tbl.isStealable = isStealable
		tbl.nameplateShowPersonal = nameplateShowPersonal
		tbl.spellId = spellId
		tbl.canApplyAura = canApplyAura
		tbl.isBossDebuff = isBossDebuff
		tbl.isCastByPlayer = isCastByPlayer
		tbl.nameplateShowAll = nameplateShowAll
		tbl.timeMod = timeMod
		tbl.value1 = value1
		tbl.value2 = value2
		tbl.value3 = value3

		local foundTimeRemaining
		local numLines = Scanner:NumLines()
		
		for lineIndex = 2,numLines do
			local line = _G[ScannerName.."TextLeft"..lineIndex]
			if line then
				local msg = line:GetText()
				if msg then
					local isTime

					local id = 1
					while Patterns["AuraTimeRemaining"..id] do 
						if (string_find(msg, Patterns["AuraTimeRemaining"..id])) then 
						
							-- found the range line
							foundTimeRemaining = lineIndex
							tbl.timeRemaining = msg

							break
						end 
						id = id + 1
					end 
				end
			end
		end


		-- Just assume all remaining lines are description, 
		-- and bunch them together to a single line. 
		if (numLines > 1) then 
			for lineIndex = 2, numLines do 
				if (lineIndex ~= foundTimeRemaining) then 
					local line = _G[ScannerName.."TextLeft"..lineIndex]
					if line then 
						local msg = line:GetText()
						if msg then
							if tbl.description then 
								if (msg == "") then 
									tbl.description = tbl.description .. "|n|n" -- empty line/space
								else 
									tbl.description = tbl.description .. "|n" .. msg -- normal line break
								end 
							else 
								tbl.description = msg -- first line
							end 
						end 
					end 
				end 
			end 
		end 

		return tbl
	end 
end

-- Returns data about unit buffs
LibTooltipScanner.GetTooltipDataForUnitDebuff = function(self, unit, debuffID, filter, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitDebuff(unit, debuffID, filter)

	if name then 
		Scanner:SetUnitDebuff(unit, debuffID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		tbl.name = name
		tbl.icon = icon
		tbl.count = count
		tbl.debuffType = debuffType
		tbl.duration = duration
		tbl.expirationTime = expirationTime
		tbl.unitCaster = unitCaster
		tbl.isStealable = isStealable
		tbl.nameplateShowPersonal = nameplateShowPersonal
		tbl.spellId = spellId
		tbl.canApplyAura = canApplyAura
		tbl.isBossDebuff = isBossDebuff
		tbl.isCastByPlayer = isCastByPlayer
		tbl.nameplateShowAll = nameplateShowAll
		tbl.timeMod = timeMod
		tbl.value1 = value1
		tbl.value2 = value2
		tbl.value3 = value3

		local foundTimeRemaining
		local numLines = Scanner:NumLines()
		
		for lineIndex = 2,numLines do
			local line = _G[ScannerName.."TextLeft"..lineIndex]
			if line then
				local msg = line:GetText()
				if msg then
					local isTime

					local id = 1
					while Patterns["AuraTimeRemaining"..id] do 
						if (string_find(msg, Patterns["AuraTimeRemaining"..id])) then 
						
							-- found the range line
							foundTimeRemaining = lineIndex
							tbl.timeRemaining = msg

							break
						end 
						id = id + 1
					end 
				end
			end
		end

		-- Just assume all remaining lines are description, 
		-- and bunch them together to a single line. 
		if (numLines > 1) then 
			for lineIndex = 2, numLines do 
				if (lineIndex ~= foundTimeRemaining) then 
					local line = _G[ScannerName.."TextLeft"..lineIndex]
					if line then 
						local msg = line:GetText()
						if msg then
							if tbl.description then 
								if (msg == "") then 
									tbl.description = tbl.description .. "|n|n" -- empty line/space
								else 
									tbl.description = tbl.description .. "|n" .. msg -- normal line break
								end 
							else 
								tbl.description = msg -- first line
							end 
						end 
					end 
				end 
			end 
		end 

		return tbl
	end
end

-- Module embedding
local embedMethods = {
	GetTooltipDataForAction = true,
	GetTooltipDataForActionItem = true, 
	GetTooltipDataForPetAction = true,
	GetTooltipDataForUnit = true,
	GetTooltipDataForUnitAura = true, 
	GetTooltipDataForUnitBuff = true, 
	GetTooltipDataForUnitDebuff = true,
	GetTooltipDataForItemID = true,
	GetTooltipDataForItemLink = true,
	GetTooltipDataForContainerSlot = true,
	GetTooltipDataForInventorySlot = true, 
	GetTooltipDataForInboxItem = true,
	GetTooltipDataForSpellID = true,
}

LibTooltipScanner.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTooltipScanner.embeds) do
	LibTooltipScanner:Embed(target)
end