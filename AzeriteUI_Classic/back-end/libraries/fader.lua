local LibFader = CogWheel:Set("LibFader", 16)
if (not LibFader) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibFader requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibFader requires LibFrame to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibFader requires LibEvent to be loaded.")

LibFrame:Embed(LibFader)
LibEvent:Embed(LibFader)
LibClientBuild:Embed(LibFader)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_match = string.match
local table_concat = table.concat
local table_insert = table.insert
local type = type

-- WoW API
local CursorHasItem = _G.CursorHasItem
local CursorHasSpell = _G.CursorHasSpell
local GetCursorInfo = _G.GetCursorInfo
local HasOverrideActionBar = _G.HasOverrideActionBar
local HasTempShapeshiftActionBar = _G.HasTempShapeshiftActionBar
local HasVehicleActionBar = _G.HasVehicleActionBar
local InCombatLockdown = _G.InCombatLockdown
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsPossessBarVisible = _G.IsPossessBarVisible
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local SpellFlyout = _G.SpellFlyout
local UnitDebuff = _G.UnitDebuff
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitInVehicle = _G.UnitInVehicle
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnregisterAttributeDriver = _G.UnregisterAttributeDriver

-- WoW Constants
local DEBUFF_MAX_DISPLAY = _G.DEBUFF_MAX_DISPLAY or 16

-- Library registries
LibFader.embeds = LibFader.embeds or {}
LibFader.objects = LibFader.objects or {} -- all currently registered objects
LibFader.defaultAlphas = LibFader.defaultAlphas or {} -- maximum opacity for registered objects
LibFader.data = LibFader.data or {} -- various global data
LibFader.frame = LibFader.frame or LibFader:CreateFrame("Frame", nil, "UICenter")
LibFader.frame._owner = LibFader
LibFader.FORCED = nil -- we want this disabled from the start

-- Speed!
local Data = LibFader.data
local Objects = LibFader.objects

-- TODO: Use the upcoming aura filter rewrite for this.
-- TODO2: Add in non-peril debuffs from BfA, and possibly Legion.
local safeDebuffs = {
	-- deserters
	[ 26013] = true, -- PvP Deserter 
	[ 71041] = true, -- Dungeon Deserter 
	[144075] = true, -- Dungeon Deserter
	[ 99413] = true, -- Deserter (no idea what type)
	[158263] = true, -- Craven "You left an Arena without entering combat and must wait before entering another one." -- added 6.0.1
	[194958] = true, -- Ashran Deserter

	-- heal cooldowns
	[178857] = true, -- Contender (Gladiator's Sanctum buff)
	[ 11196] = true, -- Recently Bandaged
	[  6788] = true, -- Weakened Soul
	
	-- burst cooldowns
	[ 57723] = true, -- Exhaustion from Heroism
	[264689] = true, -- Fatigued (cannot benefit from Primal Rage or similar) -- added 8.0.1 (?)
	[ 95809] = true, -- Insanity from Ancient Hysteria
	[ 57724] = true, -- Sated from Bloodlust
	[ 80354] = true, -- Temporal Displacement from Time Warp
	
	-- Resources
	[ 36032] = true, -- Arcane Charges
	
	-- Seasonal 
	[ 26680] = true, -- Adored "You have received a gift of adoration!" 
	[ 42146] = true, -- Brewfest Racing Ram Aura
	[ 26898] = true, -- Heartbroken "You have been rejected and can no longer give Love Tokens!"
	[ 71909] = true, -- Heartbroken "Suffering from a broken heart."
	[ 43052] = true, -- Ram Fatigue "Your racing ram is fatigued."
	[ 69438] = true, -- Sample Satisfaction (some love crap)
	
	-- WoD weird debuffs 
	[174958] = true, -- Acid Trail "Riding on the slippery back of a Goren!"  -- added 6.0.1
	[160510] = true, -- Encroaching Darkness "Something is watching you..." -- some zone in WoD
	[156154] = true, -- Might of Ango'rosh -- WoD, Talador zone buff

	-- WoD fish debuffs
	[174524] = true, -- Awesomefish
	[174528] = true, -- Grieferfish
	
	-- WoD Follower deaths 
	[173660] = true, -- Aeda Brightdawn
	[173657] = true, -- Defender Illona 
	[173658] = true, -- Delvar Ironfist
	[173976] = true, -- Leorajh 
	[173659] = true, -- Talonpriest Ishaal
	[173649] = true, -- Tormmok 
	[173661] = true, -- Vivianne 

	-- BfA
	[271571] = true, -- Ready! (when doing the "Shell Game" world quests) -- added 8.0.1
}

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

local InitiateDelay = function(self, elapsed) 
	return self._owner:InitiateDelay(elapsed) 
end

local OnUpdate = function(self, elapsed) 
	return self._owner:OnUpdate(elapsed) 
end

local SetToDefaultAlpha = function(object) 
	object:SetAlpha(Objects[object]) 
end

local SetToZeroAlpha = function(object)
	object:SetAlpha(0)
end 

local SetToProgressAlpha = function(object, progress)
	object:SetAlpha(Objects[object] * progress) 
end

-- Register an object with a fade manager
LibFader.RegisterObjectFade = function(self, object)
	-- Don't re-register existing objects, 
	-- as that will overwrite the default alpha value 
	-- which in turn can lead to max alphas of zero. 
	if Objects[object] then 
		return 
	end 
	Objects[object] = object:GetAlpha()
end

-- Unregister an object from a fade manager, and hard reset its alpha
LibFader.UnregisterObjectFade = function(self, object)
	if (not Objects[object]) then 
		return 
	end

	-- Retrieve original alpha
	local alpha = Objects[object]

	-- Remove the object from the manager
	Objects[object] = nil

	-- Restore the original alpha
	object:SetAlpha(alpha)
end

-- Force all faded objects visible 
LibFader.SetObjectFadeOverride = function(self, force)
	if (force) then 
		LibFader.FORCED = true 
	else 
		LibFader.FORCED = nil 
	end 
end

-- Prevent objects from fading out in instances
LibFader.DisableInstanceFading = function(self, fade)
	if (fade) then 
		Data.disableInstanceFade = true 
	else 
		Data.disableInstanceFade = false 
	end
end

-- Set the default alpha of an opaque object
LibFader.SetObjectAlpha = function(self, object, alpha)
	check(alpha, 2, "number")
	if (not Objects[object]) then 
		return 
	end
	Objects[object] = alpha
end 

LibFader.CheckMouse = function(self)
	if (SpellFlyout and SpellFlyout:IsShown()) then 
		Data.mouseOver = true 
		return true
	end 
	for object in pairs(Objects) do 
		if object.GetExplorerHitRects then 
			local top, bottom, left, right = object:GetExplorerHitRects()
			if (object:IsMouseOver(top, bottom, left, right) and object:IsShown()) then 
				Data.mouseOver = true 
				return true
			end 
		else 
			if (object:IsMouseOver() and object:IsShown()) then 
				Data.mouseOver = true 
				return true
			end 
		end 
	end 
	Data.mouseOver = nil
end

LibFader.CheckCursor = function(self)
	if (CursorHasSpell() or CursorHasItem()) then 
		Data.busyCursor = true 
		return 
	end 

	-- other values: money, merchant
	local cursor = GetCursorInfo()
	if (cursor == "petaction") 
	or (cursor == "spell") 
	or (cursor == "macro") 
	or (cursor == "mount") 
	or (cursor == "item") 
	or (cursor == "battlepet") then 
		Data.busyCursor = true 
		return 
	end 
	Data.busyCursor = nil
end 

-- TODO: Integration with LibAura
LibFader.CheckAuras = function(self)
	for i = 1, DEBUFF_MAX_DISPLAY do
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitDebuff("player", i, filter)

		-- No name means no more debuffs matching the filter
		if (not name) then
			break
		end

		-- Set the flag and return if a non-filtered debuff is encountered
		if (not safeDebuffs[spellId]) then
			Data.badAura = true
			return
		end
	end
	Data.badAura = nil
end

LibFader.CheckHealth = function(self)
	local min = UnitHealth("player") or 0
	local max = UnitHealthMax("player") or 0
	if (max > 0) and (min/max < .9) then 
		Data.lowHealth = true
		return
	end 
	Data.lowHealth = nil
end 

LibFader.CheckPower = function(self)
	local _, type = UnitPowerType("player")
	if (type == "MANA") then 
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < .75) then 
			Data.lowPower = true
			return
		end 
	elseif (type == "ENERGY" or type == "FOCUS") then 
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < .5) then 
			Data.lowPower = true
			return
		end 
	end 
	Data.lowPower = nil
end 

LibFader.CheckVehicle = function(self)
	if (not IS_CLASSIC) and (UnitInVehicle("player") or HasVehicleActionBar()) then 
		Data.inVehicle = true
		return 
	end 
	Data.inVehicle = nil
end 

LibFader.CheckOverride = function(self)
	if (not IS_CLASSIC) and (HasOverrideActionBar() or HasTempShapeshiftActionBar()) then 
		Data.hasOverride = true
		return 
	end 
	Data.hasOverride = nil
end 

LibFader.CheckPossess = function(self)
	if (not IS_CLASSIC) and (sPossessBarVisible()) then 
		Data.hasPossess = true
		return 
	end 
	Data.hasPossess = nil
end 

LibFader.CheckTarget = function(self)
	if UnitExists("target") then 
		Data.hasTarget = true
		return 
	end 
	Data.hasTarget = nil
end 

LibFader.CheckFocus	 = function(self)
	if UnitExists("focus") then 
		Data.hasFocus = true
		return 
	end 
	Data.hasFocus = nil
end 

LibFader.CheckGroup = function(self)
	if IsInGroup() then 
		Data.inGroup = true
		return 
	end 
	Data.inGroup = nil
end

LibFader.CheckInstance = function(self)
	if IsInInstance() then 
		Data.inInstance = true
		return 
	end 
	Data.inInstance = nil
end

LibFader.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 

		Data.inCombat = InCombatLockdown()

		self:CheckInstance()
		self:CheckGroup()
		self:CheckTarget()
		self:CheckFocus()
		self:CheckVehicle()
		self:CheckOverride()
		self:CheckPossess()
		self:CheckHealth()
		self:CheckPower()
		self:CheckAuras()
		self:CheckCursor()

		self:ForAll(SetToDefaultAlpha)

		self.FORCED = nil
		self.elapsed = 0
		self.frame:SetScript("OnUpdate", InitiateDelay)

	elseif (event == "PLAYER_REGEN_DISABLED") then 
		Data.inCombat = true

	elseif (event == "PLAYER_REGEN_ENABLED") then 
		Data.inCombat = false

	elseif (event == "PLAYER_TARGET_CHANGED") then 
		self:CheckTarget()

	elseif (event == "PLAYER_FOCUS_CHANGED") then 
		self:CheckFocus()

	elseif (event == "GROUP_ROSTER_UPDATE") then 
		self:CheckGroup()

	elseif (event == "UPDATE_POSSESS_BAR") then 
		self:CheckPossess()

	elseif (event == "UPDATE_OVERRIDE_ACTIONBAR") then 
		self:CheckOverride()

	elseif (event == "UNIT_ENTERING_VEHICLE") 
		or (event == "UNIT_ENTERED_VEHICLE") 
		or (event == "UNIT_EXITING_VEHICLE") 
		or (event == "UNIT_EXITED_VEHICLE") then 
			self:CheckVehicle()

	elseif (event == "UNIT_POWER_FREQUENT") 
		or (event == "UNIT_DISPLAYPOWER") then
			self:CheckPower()

	elseif (event == "UNIT_HEALTH_FREQUENT") then 
		self:CheckHealth()

	elseif (event == "UNIT_AURA") then 
		self:CheckAuras()

	elseif (event == "ZONE_CHANGED_NEW_AREA") then 
		self:CheckInstance()
	end 
end

LibFader.InitiateDelay = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	-- Enforce a delay at the start
	if (self.elapsed < 15) then 
		return 
	end

	self.elapsed = 0
	self.totalElapsed = 0
	self.totalElapsedIn = 0
	self.totalElapsedOut = 0
	self.totalDurationIn = .15
	self.totalDurationOut = .75
	self.currentPosition = 1
	self.achievedState = "peril"

	self.frame:SetScript("OnUpdate", OnUpdate)
end 

LibFader.OnUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	-- Throttle any and all updates
	if (self.elapsed < 1/60) then 
		return 
	end 

	if self.FORCED
	or Data.inCombat 
	or Data.hasTarget 
	or Data.hasFocus 
	or Data.inGroup 
	or Data.hasOverride 
	or Data.hasPossess 
	or Data.inVehicle 
	or (Data.inInstance and Data.disableInstanceFade)
	or Data.lowHealth 
	or Data.lowPower 
	or Data.busyCursor 
	or Data.badAura 
	or self:CheckMouse() then 
		if (self.currentPosition == 1) and (self.achievedState == "peril") then 
			self.elapsed = 0
			return 
		end 
		local progress = self.elapsed / self.totalDurationIn
		if ((self.currentPosition + progress) < 1) then 
			self.currentPosition = self.currentPosition + progress
			self.achievedState = nil
			self:ForAll(SetToProgressAlpha, self.currentPosition)
		else 
			self.currentPosition = 1
			self.achievedState = "peril"
			self:ForAll(SetToDefaultAlpha)
		end 
	else 
		local progress = self.elapsed / self.totalDurationOut
		if ((self.currentPosition - progress) > 0) then 
			self.currentPosition = self.currentPosition - progress
			self.achievedState = nil
			self:ForAll(SetToProgressAlpha, self.currentPosition)
		else 
			self.currentPosition = 0
			self.achievedState = "safe"
			self:ForAll(SetToZeroAlpha)
		end 
	end 
	self.elapsed = 0
end

LibFader.ForAll = function(self, method, ...)
	for object in pairs(Objects) do 
		if (type(method) == "string") then 
			object[method](object, ...)
		elseif (type(method) == "function") then 
			method(object, ...)
		end 
	end 
end

local embedMethods = {
	SetObjectFadeOverride = true, 
	RegisterObjectFade = true,
	UnregisterObjectFade = true,
	DisableInstanceFading = true, 
}

LibFader.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibFader.embeds) do
	LibFader:Embed(target)
end

LibFader:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
LibFader:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
LibFader:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent") 
LibFader:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent") 
LibFader:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent") 
LibFader:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent") 
LibFader:RegisterUnitEvent("UNIT_AURA", "OnEvent", "player")
LibFader:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "OnEvent", "player") 
LibFader:RegisterUnitEvent("UNIT_POWER_FREQUENT", "OnEvent", "player") 
LibFader:RegisterUnitEvent("UNIT_DISPLAYPOWER", "OnEvent", "player") 

if (not IS_CLASSIC) then 
	LibFader:RegisterEvent("PLAYER_FOCUS_CHANGED", "OnEvent") 
	LibFader:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", "OnEvent") 
	LibFader:RegisterEvent("UPDATE_POSSESS_BAR", "OnEvent") 
	LibFader:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "OnEvent", "player") 
	LibFader:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "OnEvent", "player") 
	LibFader:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "OnEvent", "player") 
	LibFader:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "OnEvent", "player") 
end 
