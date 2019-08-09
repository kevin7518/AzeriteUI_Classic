local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("NamePlates", "LibEvent", "LibNamePlate", "LibDB", "LibMenu", "LibFrame")

Module:SetIncompatible("Kui_Nameplates")
Module:SetIncompatible("NeatPlates")
Module:SetIncompatible("SimplePlates")
Module:SetIncompatible("TidyPlates")
Module:SetIncompatible("TidyPlates_ThreatPlates")
Module:SetIncompatible("TidyPlatesContinued")

-- Lua API
local _G = _G

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance 
local SetCVar = _G.SetCVar
local SetNamePlateEnemyClickThrough = _G.C_NamePlate.SetNamePlateEnemyClickThrough
local SetNamePlateFriendlyClickThrough = _G.C_NamePlate.SetNamePlateFriendlyClickThrough
local SetNamePlateSelfClickThrough = _G.C_NamePlate.SetNamePlateSelfClickThrough

-- Local cache of the nameplates, for easy access to some methods
local Plates = {} 

-- Module defaults
local defaults = {
	enableAuras = true,
	clickThroughEnemies = false, 
	clickThroughFriends = false, 
	clickThroughSelf = false
}

-----------------------------------------------------------
-- Callbacks
-----------------------------------------------------------
local PostCreateAuraButton = function(element, button)
	local Layout = element._owner.layout

	button.Icon:SetTexCoord(unpack(Layout.AuraIconTexCoord))
	button.Icon:SetSize(unpack(Layout.AuraIconSize))
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint(unpack(Layout.AuraIconPlace))

	button.Count:SetFontObject(Layout.AuraCountFont)
	button.Count:SetJustifyH("CENTER")
	button.Count:SetJustifyV("MIDDLE")
	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.AuraCountPlace))
	if Layout.AuraCountColor then 
		button.Count:SetTextColor(unpack(Layout.AuraCountColor))
	end 

	button.Time:SetFontObject(Layout.AuraTimeFont)
	button.Time:ClearAllPoints()
	button.Time:SetPoint(unpack(Layout.AuraTimePlace))

	local layer, level = button.Icon:GetDrawLayer()

	button.Darken = button.Darken or button:CreateTexture()
	button.Darken:SetDrawLayer(layer, level + 1)
	button.Darken:SetSize(button.Icon:GetSize())
	button.Darken:SetPoint("CENTER", 0, 0)
	button.Darken:SetColorTexture(0, 0, 0, .25)

	button.Overlay:SetFrameLevel(button:GetFrameLevel() + 10)
	button.Overlay:ClearAllPoints()
	button.Overlay:SetPoint("CENTER", 0, 0)
	button.Overlay:SetSize(button.Icon:GetSize())

	button.Border = button.Border or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
	button.Border:SetFrameLevel(button.Overlay:GetFrameLevel() - 5)
	button.Border:ClearAllPoints()
	button.Border:SetPoint(unpack(Layout.AuraBorderFramePlace))
	button.Border:SetSize(unpack(Layout.AuraBorderFrameSize))
	button.Border:SetBackdrop(Layout.AuraBorderBackdrop)
	button.Border:SetBackdropColor(unpack(Layout.AuraBorderBackdropColor))
	button.Border:SetBackdropBorderColor(unpack(Layout.AuraBorderBackdropBorderColor))
end

local PostUpdateAuraButton = function(element, button)
	local colors = element._owner.colors
	local Layout = element._owner.layout
	if (not button) or (not button:IsVisible()) or (not button.unit) or (not UnitExists(button.unit)) then 
		local color = Layout.AuraBorderBackdropBorderColor
		if color then 
			button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
		end 
		return 
	end 
	if UnitIsFriend("player", button.unit) then 
		if button.isBuff then 
			local color = Layout.AuraBorderBackdropBorderColor
			if color then 
				button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
			end 
		else
			local color = colors.debuff[button.debuffType or "none"] or Layout.AuraBorderBackdropBorderColor
			if color then 
				button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
			end 
		end
	else 
		if button.isStealable then 
			local color = colors.power.ARCANE_CHARGES or Layout.AuraBorderBackdropBorderColor
			if color then 
				button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
			end 
		elseif button.isBuff then 
			local color = colors.quest.green or Layout.AuraBorderBackdropBorderColor
			if color then 
				button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
			end 
		else
			local color = colors.debuff.none or Layout.AuraBorderBackdropBorderColor
			if color then 
				button.Border:SetBackdropBorderColor(color[1], color[2], color[3])
			end 
		end
	end 
end

-- Library Updates
-- *will be called by the library at certain times
-----------------------------------------------------------------
-- Called on PLAYER_ENTERING_WORLD by the library, 
-- but before the library calls its own updates.
Module.PreUpdateNamePlateOptions = function(self)

	local _, instanceType = IsInInstance()
	if (instanceType == "none") then
		SetCVar("nameplateMaxDistance", 30)
	else
		SetCVar("nameplateMaxDistance", 45)
	end

	-- If these are enabled the GameTooltip will become protected, 
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these. 
	SetCVar("nameplateShowDebuffsOnFriendly", 0) 
		
end 

-- Called when certain bindable blizzard settings change, 
-- or when the VARIABLES_LOADED event fires. 
Module.PostUpdateNamePlateOptions = function(self, isInInstace)
	local Layout = self.layout

	-- Make an extra call to the preupdate
	self:PreUpdateNamePlateOptions()

	if Layout.SetConsoleVars then 
		for cVarName, value in pairs(Layout.SetConsoleVars) do 
			SetCVar(cVarName, value)
		end 
	end 

	-- Setting the base size involves changing the size of secure unit buttons, 
	-- but since we're using our out of combat wrapper, we should be safe.
	-- Default size 110, 45
	C_NamePlate.SetNamePlateFriendlySize(unpack(Layout.Size))
	C_NamePlate.SetNamePlateEnemySize(unpack(Layout.Size))
	C_NamePlate.SetNamePlateSelfSize(unpack(Layout.Size))

	NamePlateDriverFrame.UpdateNamePlateOptions = function() end
end

-- Called after a nameplate is created.
-- This is where we create our own custom elements.
Module.PostCreateNamePlate = function(self, plate, baseFrame)
	local db = self.db
	local Layout = self.layout
	
	plate:SetSize(unpack(Layout.Size))
	plate.colors = Layout.Colors or plate.colors
	plate.layout = Layout

	-- Health bar
	if Layout.UseHealth then 
		local health = plate:CreateStatusBar()
		health:Hide()
		health:SetSize(unpack(Layout.HealthSize))
		health:SetPoint(unpack(Layout.HealthPlace))
		health:SetStatusBarTexture(Layout.HealthTexture)
		health:SetOrientation(Layout.HealthBarOrientation)
		health:SetSmoothingFrequency(.1)
		health:SetSparkMap(Layout.HealthSparkMap)
		health:SetTexCoord(unpack(Layout.HealthTexCoord))
		health.absorbThreshold = Layout.AbsorbThreshold
		health.colorTapped = Layout.HealthColorTapped
		health.colorDisconnected = Layout.HealthColorDisconnected
		health.colorClass = Layout.HealthColorClass
		health.colorCivilian = Layout.HealthColorCivilian
		health.colorReaction = Layout.HealthColorReaction
		health.colorThreat = Layout.HealthColorThreat -- color units with threat in threat color
		health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
		health.frequent = Layout.HealthFrequent
		health.threatFeedbackUnit = Layout.HealthThreatFeedbackUnit
		health.threatHideSolo = Layout.HealthThreatHideSolo
		plate.Health = health

		if Layout.UseHealthBackdrop then 
			local healthBg = health:CreateTexture()
			healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
			healthBg:SetSize(unpack(Layout.HealthBackdropSize))
			healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
			healthBg:SetTexture(Layout.HealthBackdropTexture)
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
			plate.Health.Bg = healthBg
		end 
	end 

	if Layout.UseCast then 
		local cast = (plate.Health or plate):CreateStatusBar()
		cast:SetSize(unpack(Layout.CastSize))
		cast:SetPoint(unpack(Layout.CastPlace))
		cast:SetStatusBarTexture(Layout.CastTexture)
		cast:SetOrientation(Layout.CastOrientation)
		cast:SetSmoothingFrequency(.1)
		cast.timeToHold = Layout.CastTimeToHoldFailed
		if Layout.CastSparkMap then 
			cast:SetSparkMap(CastSparkMap)
		end
		if Layout.CastTexCoord then 
			cast:SetTexCoord(unpack(Layout.CastTexCoord))
		end 
		plate.Cast = cast

		if Layout.UseCastBackdrop then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.CastBackdropPlace))
			castBg:SetSize(unpack(Layout.CastBackdropSize))
			castBg:SetDrawLayer(unpack(Layout.CastBackdropDrawLayer))
			castBg:SetTexture(Layout.CastBackdropTexture)
			castBg:SetVertexColor(unpack(Layout.CastBackdropColor))
			plate.Cast.Bg = castBg
		end 

		if Layout.UseCastName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.CastNamePlace))
			castName:SetDrawLayer(unpack(Layout.CastNameDrawLayer))
			castName:SetFontObject(Layout.CastNameFont)
			castName:SetTextColor(unpack(Layout.CastNameColor))
			castName:SetJustifyH(Layout.CastNameJustifyH)
			castName:SetJustifyV(Layout.CastNameJustifyV)
			cast.Name = castName
		end 

		if Layout.UseCastShield then 
			local castShield = cast:CreateTexture()
			castShield:SetPoint(unpack(Layout.CastShieldPlace))
			castShield:SetSize(unpack(Layout.CastShieldSize))
			castShield:SetTexture(Layout.CastShieldTexture) 
			castShield:SetDrawLayer(unpack(Layout.CastShieldDrawLayer))
			castShield:SetVertexColor(unpack(Layout.CastShieldColor))
			
			cast.Shield = castShield
		end 
	
		plate.Cast = cast
		plate.Cast.PostUpdate = Layout.CastPostUpdate
	end 

	if Layout.UseThreat then 
		local threat = (plate.Health or plate):CreateTexture()
		threat:SetPoint(unpack(Layout.ThreatPlace))
		threat:SetSize(unpack(Layout.ThreatSize))
		threat:SetTexture(Layout.ThreatTexture)
		threat:SetDrawLayer(unpack(Layout.ThreatDrawLayer))
		threat:SetVertexColor(unpack(Layout.ThreatColor))
		threat.hideSolo = Layout.ThreatHideSolo
		threat.feedbackUnit = "player"
		plate.Threat = threat
	end 

	if Layout.UseRaidTarget then 
		local raidTarget = baseFrame:CreateTexture()
		raidTarget:SetPoint(unpack(Layout.RaidTargetPlace))
		raidTarget:SetSize(unpack(Layout.RaidTargetSize))
		raidTarget:SetDrawLayer(unpack(Layout.RaidTargetDrawLayer))
		raidTarget:SetTexture(Layout.RaidTargetTexture)
		raidTarget:SetScale(plate:GetScale())
		
		hooksecurefunc(plate, "SetScale", function(plate,scale) raidTarget:SetScale(scale) end)

		plate.RaidTarget = raidTarget
		plate.RaidTarget.PostUpdate = Layout.PostUpdateRaidTarget
	end 

	if Layout.UseAuras then 
		local auras = plate:CreateFrame("Frame")
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		if Layout.AuraPoint then 
			auras.point = Layout.AuraPoint
			auras.anchor = plate[Layout.AuraAnchor] or plate
			auras.relPoint = Layout.AuraRelPoint
			auras.offsetX = Layout.AuraOffsetX
			auras.offsetY = Layout.AuraOffsetY
			auras:ClearAllPoints()
			auras:SetPoint(auras.point, auras.anchor, auras.relPoint, auras.offsetX, auras.offsetY)
		else 
			auras:Place(unpack(Layout.AuraFramePlace))
		end 
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffsFirst -- show debuffs before buffs
		auras.showCooldownSpiral = Layout.ShowAuraCooldownSpirals -- don't show the spiral as a timer
		auras.showCooldownTime = Layout.ShowAuraCooldownTime -- show timer numbers
		auras.auraFilterString = Layout.auraFilterFunc -- general aura filter, only used if the below aren't here
		auras.buffFilterString = Layout.AuraBuffFilter -- buff specific filter passed to blizzard API calls
		auras.debuffFilterString = Layout.AuraDebuffFilter -- debuff specific filter passed to blizzard API calls
		auras.auraFilterFunc = Layout.auraFilterFuncFunc -- general aura filter function, called when the below aren't there
		auras.buffFilterFunc = Layout.buffFilterFuncFunc -- buff specific filter function
		auras.debuffFilterFunc = Layout.debuffFilterFuncFunc -- debuff specific filter function
		auras.tooltipDefaultPosition = Layout.AuraTooltipDefaultPosition
		auras.tooltipPoint = Layout.AuraTooltipPoint
		auras.tooltipAnchor = Layout.AuraTooltipAnchor
		auras.tooltipRelPoint = Layout.AuraTooltipRelPoint
		auras.tooltipOffsetX = Layout.AuraTooltipOffsetX
		auras.tooltipOffsetY = Layout.AuraTooltipOffsetY
		auras.disableMouse = Layout.AuraDisableMouse
			
		plate.Auras = auras
		plate.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		plate.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
		plate.Auras.PostUpdate = Layout.PostUpdateAura

		-- Aura misalignment debugging. 
		-- We proved that it's the entire element, not the aura sorting that's wrong, 
		-- so we're disabling this thing here for now. Don't need 40 invisible backdrops. 
		--[[--
		local owner = self:GetOwner()
		if owner.db and owner.db.loadDebugConsole then 
			local debugFrame = owner:GetDebugFrame()
			if debugFrame then 
				-- Need to figure out if the aura misalignment 
				-- is the aura layout method in the back-end, 
				-- or the aura element itself bein misplaced. 
				local devHelp = auras:CreateTexture()
				devHelp:SetColorTexture(0,0,0,.25)
				devHelp:SetAllPoints()
				devHelp:SetDrawLayer("BACKGROUND")
				devHelp:SetShown(debugFrame:IsShown())

				-- Should make a better system for these hooks, 
				-- because I hate exposing the debugFrame to the outside world. 
				debugFrame:HookScript("OnShow", function() devHelp:Show() end)
				debugFrame:HookScript("OnHide", function() devHelp:Hide() end)
			end 
		end 
		--]]--

		if (not db.enableAuras) then 
			plate:DisableElement("Auras")
		end 
	end 

	-- The library does this too, but isn't exposing it to us.
	Plates[plate] = baseFrame
end

Module.PostUpdateSettings = function(self)
	local db = self.db
	for plate, baseFrame in pairs(Plates) do 
		if db.enableAuras then 
			plate:EnableElement("Auras")
			plate.Auras:ForceUpdate()
			plate.RaidTarget:ForceUpdate()
		else 
			plate:DisableElement("Auras")
			plate.RaidTarget:ForceUpdate()
		end 
	end
end

Module.UpdateCVars = function(self, event, ...)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateCVars")
	end 
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateCVars")
	end 
	local db = self.db
	SetNamePlateEnemyClickThrough(db.clickThroughEnemies)
	SetNamePlateFriendlyClickThrough(db.clickThroughFriends)
	SetNamePlateSelfClickThrough(db.clickThroughSelf)
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateCVars()
	end 
end

Module.OnInit = function(self)
	self.db = self:NewConfig("NamePlates", defaults, "global")
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[NamePlates]")

	local proxy = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	proxy.PostUpdateSettings = function() self:PostUpdateSettings() end
	proxy.UpdateCVars = function() self:UpdateCVars() end
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:SetAttribute("_onattributechanged", [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enableauras") then 
			self:SetAttribute("enableAuras", value); 
			self:CallMethod("PostUpdateSettings"); 

		elseif (name == "change-clickthroughenemies") then
			self:SetAttribute("clickThroughEnemies", value); 
			self:CallMethod("UpdateCVars"); 

		elseif (name == "change-clickthroughfriends") then 
			self:SetAttribute("clickThroughFriends", value); 
			self:CallMethod("UpdateCVars"); 

		elseif (name == "change-clickthroughself") then 
			self:SetAttribute("clickThroughSelf", value); 
			self:CallMethod("UpdateCVars"); 

		end 
	]=])

	self.proxyUpdater = proxy
end 

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end

Module.OnEnable = function(self)
	if self.layout.UseNamePlates then
		self:StartNamePlateEngine()
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end
end 
