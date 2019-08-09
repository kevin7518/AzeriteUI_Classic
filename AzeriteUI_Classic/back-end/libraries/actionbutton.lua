local LibSecureButton = CogWheel:Set("LibSecureButton", 55)
if (not LibSecureButton) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibSecureButton requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibSecureButton requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibSecureButton requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibSecureButton requires LibSound to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibSecureButton requires LibTooltip to be loaded.")

-- Embed functionality into this
LibEvent:Embed(LibSecureButton)
LibFrame:Embed(LibSecureButton)
LibSound:Embed(LibSecureButton)
LibTooltip:Embed(LibSecureButton)
LibClientBuild:Embed(LibSecureButton)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local tonumber = tonumber
local tostring = tostring
local type = type

-- WoW API
local CursorHasItem = _G.CursorHasItem
local CursorHasSpell = _G.CursorHasSpell
local FlyoutHasSpell = _G.FlyoutHasSpell
local GetActionCharges = _G.GetActionCharges
local GetActionCooldown = _G.GetActionCooldown
local GetActionInfo = _G.GetActionInfo
local GetActionLossOfControlCooldown = _G.GetActionLossOfControlCooldown
local GetActionCount = _G.GetActionCount
local GetActionTexture = _G.GetActionTexture
local GetBindingKey = _G.GetBindingKey 
local GetCursorInfo = _G.GetCursorInfo
local GetMacroSpell = _G.GetMacroSpell
local GetOverrideBarIndex = _G.GetOverrideBarIndex
local GetTempShapeshiftBarIndex = _G.GetTempShapeshiftBarIndex
local GetTime = _G.GetTime
local GetVehicleBarIndex = _G.GetVehicleBarIndex
local HasAction = _G.HasAction
local IsActionInRange = _G.IsActionInRange
local IsAutoCastPetAction = _G.C_ActionBar.IsAutoCastPetAction
local IsConsumableAction = _G.IsConsumableAction
local IsEnabledAutoCastPetAction = _G.C_ActionBar.IsEnabledAutoCastPetAction
local IsStackableAction = _G.IsStackableAction
local IsUsableAction = _G.IsUsableAction
local SetClampedTextureRotation = _G.SetClampedTextureRotation
local UnitClass = _G.UnitClass

-- TODO: remove and fix
if LibClientBuild:IsClassic() then 
	GetOverrideBarIndex = function() return 0 end
	GetVehicleBarIndex = function() return 0 end
	GetTempShapeshiftBarIndex = function() return 0 end
	GetVehicleBarIndex = function() return 0 end
end 

-- Doing it this way to make the transition to library later on easier
LibSecureButton.embeds = LibSecureButton.embeds or {} 
LibSecureButton.buttons = LibSecureButton.buttons or {} 
LibSecureButton.allbuttons = LibSecureButton.allbuttons or {} 
LibSecureButton.callbacks = LibSecureButton.callbacks or {} 
LibSecureButton.controllers = LibSecureButton.controllers or {} -- controllers to return bindings to pet battles, vehicles, etc 
LibSecureButton.numButtons = LibSecureButton.numButtons or 0 -- total number of spawned buttons 

-- Shortcuts
local AllButtons = LibSecureButton.allbuttons
local Buttons = LibSecureButton.buttons
local Callbacks = LibSecureButton.callbacks
local Controllers = LibSecureButton.controllers

-- Blizzard Textures
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]

-- Generic format strings for our button names
local BUTTON_NAME_TEMPLATE_SIMPLE = "%sActionButton"
local BUTTON_NAME_TEMPLATE_FULL = "%sActionButton%.0f"

-- Time constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

local SECURE = {
	Page_OnAttributeChanged = ([=[ 
		if (name == "state-page") then 
			local page; 

			if (value == "overridebar") then 
				page = %.0f; 
			elseif (value == "possessbar") then 
				page = %.0f; 
			elseif (value == "shapeshift") then 
				page = %.0f; 
			elseif (value == "vehicleui") then 
				page = %.0f; 
			elseif (value == "11") then 
				if HasBonusActionBar() and (GetActionBarPage() == 1) then  
					page = GetBonusBarIndex(); 
				else 
					page = 12; 
				end 
			end

			if page then 
				value = page; 
			end 

			self:SetAttribute("state", value);

			local button = self:GetFrameRef("Button"); 
			local buttonPage = button:GetAttribute("actionpage"); 
			local id = button:GetID(); 
			local actionpage = tonumber(value); 
			local slot = actionpage and (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 

			button:SetAttribute("actionpage", actionpage or 0); 
			button:SetAttribute("action", slot); 
			button:CallMethod("UpdateAction"); 
		end 
	]=]):format(GetOverrideBarIndex(), GetVehicleBarIndex(), GetTempShapeshiftBarIndex(), GetVehicleBarIndex()), 
	Page_OnAttributeChanged_Debug = ([=[ 
		if (name == "state-page") then 
			local page; 

			if (value == "overridebar") then 
				page = %.0f; 
			elseif (value == "possessbar") then 
				page = %.0f; 
			elseif (value == "shapeshift") then 
				page = %.0f; 
			elseif (value == "vehicleui") then 
				page = %.0f; 
			elseif (value == "11") then 
				if HasBonusActionBar() and (GetActionBarPage() == 1) then  
					page = GetBonusBarIndex(); 
				else 
					page = 12; 
				end 
			end

			local driverResult; 
			if page then 
				driverResult = value;
				value = page; 
			end 

			self:SetAttribute("state", value);

			local button = self:GetFrameRef("Button"); 
			local buttonPage = button:GetAttribute("actionpage"); 
			local id = button:GetID(); 
			local actionpage = tonumber(value); 
			local slot = actionpage and (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 

			button:SetAttribute("actionpage", actionpage or 0); 
			button:SetAttribute("action", slot); 
			button:CallMethod("UpdateAction"); 

			-- Debugging the weird results
			-- *only showing bar 1, button 1
			if self:GetID() == 1 and id == 1 then
				if driverResult then 
					local page = tonumber(driverResult); 
					if page then 
						self:CallMethod("AddDebugMessage", "ActionButton driver attempted to change page to: " ..driverResult.. " - Page changed by environment to: " .. value); 
					else 
						self:CallMethod("AddDebugMessage", "ActionButton driver reported the state: " ..driverResult.. " - Page changed by environment to: " .. value); 
					end
				elseif value then 
					self:CallMethod("AddDebugMessage", "ActionButton driver changed page to: " ..value); 
				end
			end
		end 
	]=]):format(GetOverrideBarIndex(), GetVehicleBarIndex(), GetTempShapeshiftBarIndex(), GetVehicleBarIndex())

}

-- Utility Functions
----------------------------------------------------
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

local nameHelper = function(self, id)
	local name
	if id then 
		name = string_format(BUTTON_NAME_TEMPLATE_FULL, self:GetOwner():GetName(), id)
	else 
		name = string_format(BUTTON_NAME_TEMPLATE_SIMPLE, self:GetOwner():GetName())
	end 
	return name
end

local sortByID = function(a,b)
	if (a) and (b) then 
		if (a.id) and (b.id) then 
			return (a.id < b.id)
		else
			return a.id and true or false 
		end 
	else 
		return a and true or false
	end 
end 

-- Aimed to be compact and displayed on buttons
local formatCooldownTime = function(time)
	if time > DAY then -- more than a day
		time = time + DAY/2
		return "%.0f%s", time/DAY - time/DAY%1, "d"
	elseif time > HOUR then -- more than an hour
		time = time + HOUR/2
		return "%.0f%s", time/HOUR - time/HOUR%1, "h"
	elseif time > MINUTE then -- more than a minute
		time = time + MINUTE/2
		return "%.0f%s", time/MINUTE - time/MINUTE%1, "m"
	elseif time > 10 then -- more than 10 seconds
		return "%.0f", time - time%1
	elseif time >= 1 then -- more than 5 seconds
		return "|cffff8800%.0f|r", time - time%1
	elseif time > 0 then
		return "|cffff0000%.0f|r", time*10 - time*10%1
	else
		return ""
	end	
end

-- Updates
----------------------------------------------------
local OnUpdate = function(self, elapsed)

	self.flashTime = (self.flashTime or 0) - elapsed
	self.rangeTimer = (self.rangeTimer or -1) - elapsed
	self.cooldownTimer = (self.cooldownTimer or 0) - elapsed

	-- Cooldown count
	if (self.cooldownTimer <= 0) then 
		local Cooldown = self.Cooldown 
		local CooldownCount = self.CooldownCount
		if Cooldown.active then 

			local start, duration
			if (Cooldown.currentCooldownType == COOLDOWN_TYPE_NORMAL) then 
				local action = self.buttonAction
				start, duration = GetActionCooldown(action)

			elseif (Cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL) then
				local action = self.buttonAction
				start, duration = GetActionLossOfControlCooldown(action)

			end 

			if CooldownCount then 
				if ((start > 0) and (duration > 1.5)) then
					CooldownCount:SetFormattedText(formatCooldownTime(duration - GetTime() + start))
					if (not CooldownCount:IsShown()) then 
						CooldownCount:Show()
					end
				else 
					if (CooldownCount:IsShown()) then 
						CooldownCount:SetText("")
						CooldownCount:Hide()
					end
				end  
			end 
		else
			if (CooldownCount and CooldownCount:IsShown()) then 
				CooldownCount:SetText("")
				CooldownCount:Hide()
			end
		end 

		self.cooldownTimer = .1
	end 

	-- Range
	if (self.rangeTimer <= 0) then
		local inRange = self:IsInRange()
		local oldRange = self.outOfRange
		self.outOfRange = (inRange == false)
		if oldRange ~= self.outOfRange then
			self:UpdateUsable()
		end
		self.rangeTimer = TOOLTIP_UPDATE_TIME
	end 

	-- Flashing
	if (self.flashTime <= 0) then
		if (self.flashing == 1) then
			if self.Flash:IsShown() then
				self.Flash:Hide()
			else
				self.Flash:Show()
			end
		end
		self.flashTime = self.flashTime + ATTACK_BUTTON_FLASH_TIME
	end 

end 

local Update = function(self, event, ...)
	local arg1 = ...

	if (event == "PLAYER_ENTERING_WORLD") then 
		self:Update()
		self:UpdateAutoCastMacro()

	elseif (event == "PLAYER_REGEN_ENABLED") then 
		if self.queuedForMacroUpdate then 
			self:UpdateAutoCastMacro()
			self:UnregisterEvent("PLAYER_REGEN_ENABLED", Update)
			self.queuedForMacroUpdate = nil
		end 

	elseif (event == "UPDATE_SHAPESHIFT_FORM") or (event == "UPDATE_VEHICLE_ACTIONBAR") then 
		self:Update()

	elseif (event == "PLAYER_ENTER_COMBAT") or (event == "PLAYER_LEAVE_COMBAT") then
		self:UpdateFlash()

	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		if ((arg1 == 0) or (arg1 == self.buttonAction)) then
			self.SpellHighlight:Hide()
			self:Update()
			self:UpdateAutoCastMacro()
		end

	elseif (event == "ACTIONBAR_UPDATE_COOLDOWN") then
		self:UpdateCooldown()
	
	elseif (event == "ACTIONBAR_UPDATE_USABLE") then
		self:UpdateUsable()

	elseif 	(event == "ACTIONBAR_UPDATE_STATE") or
			((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE") and (arg1 == "player")) or
			((event == "COMPANION_UPDATE") and (arg1 == "MOUNT")) then
		self:UpdateCheckedState()

	elseif (event == "CURSOR_UPDATE") 
		or (event == "ACTIONBAR_SHOWGRID") or (event == "PET_BAR_SHOWGRID") 
		or (event == "ACTIONBAR_HIDEGRID") or (event == "PET_BAR_HIDEGRID") then 
			self:UpdateGrid()

	elseif (event == "PET_BAR_UPDATE") then 
		self:UpdateAutoCast()

	elseif (event == "LOSS_OF_CONTROL_ADDED") then
		self:UpdateCooldown()

	elseif (event == "LOSS_OF_CONTROL_UPDATE") then
		self:UpdateCooldown()

	elseif (event == "PLAYER_MOUNT_DISPLAY_CHANGED") then 
		self:UpdateUsable()

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
		local spellID = self:GetSpellID()
		if (spellID and (spellID == arg1)) then
			self.SpellHighlight:Show()
		else
			local actionType, id = GetActionInfo(self.buttonAction)
			if (actionType == "flyout") and FlyoutHasSpell(id, arg1) then
				self.SpellHighlight:Show()
			end
		end

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE") then
		local spellID = self:GetSpellID()
		if (spellID and (spellID == arg1)) then
			self.SpellHighlight:Hide()
		else
			local actionType, id = GetActionInfo(self.buttonAction)
			if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
				self.SpellHighlight:Hide()
			end
		end

	elseif (event == "SPELL_UPDATE_CHARGES") then
		self:UpdateCount()

	elseif (event == "SPELL_UPDATE_ICON") then
		self:Update() -- really? how often is this called?

	elseif (event == "TRADE_SKILL_SHOW") or (event == "TRADE_SKILL_CLOSE") or (event == "ARCHAEOLOGY_CLOSED") then
		self:UpdateCheckedState()

	elseif (event == "UPDATE_BINDINGS") then
		self:UpdateBinding()

	elseif (event == "UPDATE_SUMMONPETS_ACTION") then 
		local actionType, id = GetActionInfo(self.buttonAction)
		if (actionType == "summonpet") then
			local texture = GetActionTexture(self.buttonAction)
			if texture then
				self.Icon:SetTexture(texture)
			end
		end

	end 
end

local UpdateTooltip = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(280)
	tooltip:SetAction(self.buttonAction)
end 

local OnCooldownDone = function(cooldown)
	cooldown.active = nil
	cooldown:SetScript("OnCooldownDone", nil)
	cooldown:GetParent():UpdateCooldown()
end

local SetCooldown = function(cooldown, start, duration, enable, forceShowDrawEdge, modRate)
	if (enable and (enable ~= 0) and (start > 0) and (duration > 0)) then
		cooldown:SetDrawEdge(forceShowDrawEdge)
		cooldown:SetCooldown(start, duration, modRate)
		cooldown.active = true
	else
		cooldown.active = nil
		cooldown:Clear()
	end
end

-- ActionButton Template
----------------------------------------------------
local ActionButton = LibSecureButton:CreateFrame("CheckButton")
local ActionButton_MT = { __index = ActionButton }

-- Grab some original methods for our own event handlers
local IsEventRegistered = ActionButton_MT.__index.IsEventRegistered
local RegisterEvent = ActionButton_MT.__index.RegisterEvent
local RegisterUnitEvent = ActionButton_MT.__index.RegisterUnitEvent
local UnregisterEvent = ActionButton_MT.__index.UnregisterEvent
local UnregisterAllEvents = ActionButton_MT.__index.UnregisterAllEvents

-- Event Handling
----------------------------------------------------
ActionButton.RegisterEvent = function(self, event, func)
	if (not Callbacks[self]) then
		Callbacks[self] = {}
	end
	if (not Callbacks[self][event]) then
		Callbacks[self][event] = {}
	end

	local events = Callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(self, event)) then
		RegisterEvent(self, event)
	end
end

ActionButton.UnregisterEvent = function(self, event, func)
	if not Callbacks[self] or not Callbacks[self][event] then
		return
	end
	local events = Callbacks[self][event]
	if #events > 0 then
		for i = #events, 1, -1 do
			if events[i] == func then
				table_remove(events, i)
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

ActionButton.UnregisterAllEvents = function(self)
	if not Callbacks[self] then 
		return
	end
	for event, funcs in pairs(Callbacks[self]) do
		for i = #funcs, 1, -1 do
			table_remove(funcs, i)
		end
	end
	UnregisterAllEvents(self)
end

-- Button Updates
----------------------------------------------------
ActionButton.Update = function(self)
	if HasAction(self.buttonAction) then 
		self.hasAction = true
		self.Icon:SetTexture(GetActionTexture(self.buttonAction))
		self:SetAlpha(1)
	else
		self.hasAction = false
		self.Icon:SetTexture(nil) 
	end 

	self:UpdateBinding()
	self:UpdateCount()
	self:UpdateCooldown()
	self:UpdateFlash()
	self:UpdateUsable()
	self:UpdateGrid()
	self:UpdateSpellHighlight()
	self:UpdateAutoCast()
	self:UpdateFlyout()

	if self.PostUpdate then 
		self:PostUpdate()
	end 
end

-- Called when the button action (and thus the texture) has changed
ActionButton.UpdateAction = function(self)
	self.buttonAction = self:GetAction()
	local texture = GetActionTexture(self.buttonAction)
	if texture then 
		self.Icon:SetTexture(texture)
	else
		self.Icon:SetTexture(nil) 
	end 
	self:Update()
end 

ActionButton.UpdateAutoCast = function(self)
	if (HasAction(self.buttonAction) and IsAutoCastPetAction(self.buttonAction)) then 
		if IsEnabledAutoCastPetAction(self.buttonAction) then 
			if (not self.SpellAutoCast.Ants.Anim:IsPlaying()) then
				self.SpellAutoCast.Ants.Anim:Play()
				self.SpellAutoCast.Glow.Anim:Play()
			end
			self.SpellAutoCast:SetAlpha(1)
		else 
			if (self.SpellAutoCast.Ants.Anim:IsPlaying()) then
				self.SpellAutoCast.Ants.Anim:Pause()
				self.SpellAutoCast.Glow.Anim:Pause()
			end
			self.SpellAutoCast:SetAlpha(.5)
		end 
		self.SpellAutoCast:Show()
	else 
		self.SpellAutoCast:Hide()
	end 
end

ActionButton.UpdateAutoCastMacro = function(self)
	if InCombatLockdown() then 
		self.queuedForMacroUpdate = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED", Update)
		return 
	end
	local name = IsAutoCastPetAction(self.buttonAction) and GetSpellInfo(self:GetSpellID())
	if name then 
		self:SetAttribute("macrotext", "/petautocasttoggle "..name)
	else 
		self:SetAttribute("macrotext", nil)
	end 
end

-- Called when the keybinds are loaded or changed
ActionButton.UpdateBinding = function(self) 
	local Keybind = self.Keybind
	if Keybind then 
		Keybind:SetText(self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton"))
	end 
end 

ActionButton.UpdateCheckedState = function(self)
	if IsCurrentAction(self.buttonAction) or IsAutoRepeatAction(self.buttonAction) then
		self:SetChecked(true)
	else
		self:SetChecked(false)
	end
end

ActionButton.UpdateCooldown = function(self)
	local Cooldown = self.Cooldown
	if Cooldown then
		local locStart, locDuration = GetActionLossOfControlCooldown(self.buttonAction)
		local start, duration, enable, modRate = GetActionCooldown(self.buttonAction)
		local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.buttonAction)
		local hasChargeCooldown

		if ((locStart + locDuration) > (start + duration)) then

			if Cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
				Cooldown:SetEdgeTexture(EDGE_LOC_TEXTURE)
				Cooldown:SetSwipeColor(0.17, 0, 0)
				Cooldown:SetHideCountdownNumbers(true)
				Cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
			end
			SetCooldown(Cooldown, locStart, locDuration, true, true, modRate)

		else

			if (Cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL) then
				Cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
				Cooldown:SetSwipeColor(0, 0, 0)
				Cooldown:SetHideCountdownNumbers(true)
				Cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
			end

			if (locStart > 0) then
				Cooldown:SetScript("OnCooldownDone", OnCooldownDone)
			end

			local ChargeCooldown = self.ChargeCooldown
			if ChargeCooldown then 
				if (charges and maxCharges and (charges > 0) and (charges < maxCharges)) and not((not chargeStart) or (chargeStart == 0)) then

					-- Set the spellcharge cooldown
					--cooldown:SetDrawBling(cooldown:GetEffectiveAlpha() > 0.5)
					SetCooldown(ChargeCooldown, chargeStart, chargeDuration, true, true, chargeModRate)
					hasChargeCooldown = true 
				else
					ChargeCooldown.active = nil
					ChargeCooldown:Hide()
				end
			end 

			if (hasChargeCooldown) then 
				SetCooldown(ChargeCooldown, 0, 0, false)
			else 
				SetCooldown(Cooldown, start, duration, enable, false, modRate)
			end 
		end

		if hasChargeCooldown then 
			if self.PostUpdateChargeCooldown then 
				return self:PostUpdateChargeCooldown(self.ChargeCooldown)
			end 
		else 
			if self.PostUpdateCooldown then 
				return self:PostUpdateCooldown(self.Cooldown)
			end 
		end 
	end 
end

ActionButton.UpdateCount = function(self) 
	local Count = self.Count
	if Count then 
		local count
		local action = self.buttonAction
		if HasAction(action) then 
			if IsConsumableAction(action) or IsStackableAction(action) then
				count = GetActionCount(action)
				if (count > (self.maxDisplayCount or 9999)) then
					count = "*"
				end
			else
				local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(action)
				if (charges and maxCharges and (maxCharges > 1) and (charges > 0)) then
					count = charges
				end
			end
	
		end 
		Count:SetText(count or "")
		if self.PostUpdateCount then 
			return self:PostUpdateCount(count)
		end 
	end 
end 

-- Updates the red flashing on attack skills 
ActionButton.UpdateFlash = function(self)
	local Flash = self.Flash
	if Flash then 
		local action = self.buttonAction
		if HasAction(action) then 
			if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
				self.flashing = 1
				self.flashTime = 0
			else
				self.flashing = 0
				self.Flash:Hide()
			end
		end 
	end 
end 

ActionButton.UpdateFlyout = function(self)

	if self.FlyoutBorder then 
		self.FlyoutBorder:Hide()
	end 

	if self.FlyoutBorderShadow then 
		self.FlyoutBorderShadow:Hide()
	end 

	if self.FlyoutArrow then 

		local buttonAction = self:GetAction()
		if HasAction(buttonAction) then

			local actionType = GetActionInfo(buttonAction)
			if (actionType == "flyout") then

				self.FlyoutArrow:Show()
				self.FlyoutArrow:ClearAllPoints()

				local direction = self:GetAttribute("flyoutDirection")
				if (direction == "LEFT") then
					self.FlyoutArrow:SetPoint("LEFT", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 270)

				elseif (direction == "RIGHT") then
					self.FlyoutArrow:SetPoint("RIGHT", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 90)

				elseif (direction == "DOWN") then
					self.FlyoutArrow:SetPoint("BOTTOM", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 180)

				else
					self.FlyoutArrow:SetPoint("TOP", 1, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 0)
				end

				return
			end
		end
		self.FlyoutArrow:Hide()	
	end 
end

ActionButton.UpdateGrid = function(self)
	if self.showGrid then 
		return self:SetAlpha(1)
	elseif (self:IsShown()) then 
		if HasAction(self.buttonAction) and (self:GetSpellID() ~= 0) then 
			return self:SetAlpha(1)
		elseif (CursorHasSpell() or CursorHasItem()) then 
			if IS_CLASSIC then 
				return self:SetAlpha(1)
			else
				if (not UnitHasVehicleUI("player")) and (not HasOverrideActionBar()) and (not HasVehicleActionBar()) and (not HasTempShapeshiftActionBar()) then
					return self:SetAlpha(1)
				end  
			end 
		else 
			local cursor = GetCursorInfo()
			if cursor == "petaction" or cursor == "spell" or cursor == "macro" or cursor == "mount" or cursor == "item" or cursor == "battlepet" then 
				return self:SetAlpha(1)
			end 
		end 
	end 
	self:SetAlpha(0)
end

ActionButton.UpdateSpellHighlight = function(self)
	if IS_CLASSIC then 
		self.SpellHighlight:Hide()
		return
	end
	local spellId = self:GetSpellID()
	if (spellId and IsSpellOverlayed(spellId)) then
		self.SpellHighlight:Show()
	else
		self.SpellHighlight:Hide()
	end
end

-- Called when the usable state of the button changes
ActionButton.UpdateUsable = function(self) 
	if UnitIsDeadOrGhost("player") then 
		self.Icon:SetDesaturated(true)
		self.Icon:SetVertexColor(.4, .4, .4)

	elseif self.outOfRange then
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, .15, .15)

	else
		local isUsable, notEnoughMana = IsUsableAction(self.buttonAction)
		if isUsable then
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(1, 1, 1)

		elseif notEnoughMana then
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(.35, .35, 1)

		else
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(.4, .4, .4)
		end
	end
end 

-- Getters
----------------------------------------------------
ActionButton.GetAction = function(self)
	local actionpage = tonumber(self:GetAttribute("actionpage"))
	local id = self:GetID()
	return actionpage and (actionpage > 1) and ((actionpage - 1) * NUM_ACTIONBAR_BUTTONS + id) or id
end

ActionButton.GetActionTexture = function(self) 
	return GetActionTexture(self.buttonAction)
end

ActionButton.GetBindingText = function(self)
	return self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
end 

ActionButton.GetCooldown = function(self) 
	return GetActionCooldown(self.buttonAction) 
end

ActionButton.GetLossOfControlCooldown = function(self) 
	return GetActionLossOfControlCooldown(self.buttonAction) 
end

ActionButton.GetPageID = function(self)
	return self._pager:GetID()
end 

ActionButton.GetPager = function(self)
	return self._pager
end 

ActionButton.GetSpellID = function(self)
	local actionType, id, subType = GetActionInfo(self.buttonAction)
	if (actionType == "spell") then
		return id
	elseif (actionType == "macro") then
		return (GetMacroSpell(id))
	end
end

ActionButton.GetTooltip = function(self)
	return LibSecureButton:GetActionButtonTooltip()
end

-- Isers
----------------------------------------------------
ActionButton.IsFlyoutShown = function(self)
	local buttonAction = self:GetAction()
	if HasAction(buttonAction) then
		return (GetActionInfo(buttonAction) == "flyout") and (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self)
	end 
end

ActionButton.IsInRange = function(self)
	local unit = self:GetAttribute("unit")
	if (unit == "player") then
		unit = nil
	end

	local val = IsActionInRange(self.buttonAction, unit)
	if (val == 1) then 
		val = true 
	elseif (val == 0) then 
		val = false 
	end

	return val
end

-- Script Handlers
----------------------------------------------------
ActionButton.OnEnable = function(self)
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", Update)
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Update)
	self:RegisterEvent("ACTIONBAR_UPDATE_STATE", Update)
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", Update)
	self:RegisterEvent("ACTIONBAR_HIDEGRID", Update)
	self:RegisterEvent("ACTIONBAR_SHOWGRID", Update)
	--self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", Update)
	self:RegisterEvent("CURSOR_UPDATE", Update)
	self:RegisterEvent("LOSS_OF_CONTROL_ADDED", Update)
	self:RegisterEvent("LOSS_OF_CONTROL_UPDATE", Update)
	self:RegisterEvent("PET_BAR_HIDEGRID", Update)
	self:RegisterEvent("PET_BAR_SHOWGRID", Update)
	self:RegisterEvent("PET_BAR_UPDATE", Update)
	self:RegisterEvent("PLAYER_ENTER_COMBAT", Update)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
	self:RegisterEvent("PLAYER_LEAVE_COMBAT", Update)
	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", Update)
	--self:RegisterEvent("PLAYER_REGEN_ENABLED", Update)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
	self:RegisterEvent("SPELL_UPDATE_CHARGES", Update)
	self:RegisterEvent("SPELL_UPDATE_ICON", Update)
	self:RegisterEvent("TRADE_SKILL_CLOSE", Update)
	self:RegisterEvent("TRADE_SKILL_SHOW", Update)
	--self:RegisterEvent("SPELLS_CHANGED", Update)
	self:RegisterEvent("UPDATE_BINDINGS", Update)
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", Update)

	if (not LibClientBuild:IsClassic()) then 
		self:RegisterEvent("ARCHAEOLOGY_CLOSED", Update)
		self:RegisterEvent("COMPANION_UPDATE", Update)
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", Update)
		self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", Update)
		self:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:RegisterEvent("UPDATE_SUMMONPETS_ACTION", Update)
		self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR", Update)
	end 
end

ActionButton.OnDisable = function(self)
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED", Update)
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Update)
	self:UnregisterEvent("ACTIONBAR_UPDATE_STATE", Update)
	self:UnregisterEvent("ACTIONBAR_UPDATE_USABLE", Update)
	self:UnregisterEvent("ACTIONBAR_HIDEGRID", Update)
	self:UnregisterEvent("ACTIONBAR_SHOWGRID", Update)
	--self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED", Update)
	self:UnregisterEvent("CURSOR_UPDATE", Update)
	self:UnregisterEvent("LOSS_OF_CONTROL_ADDED", Update)
	self:UnregisterEvent("LOSS_OF_CONTROL_UPDATE", Update)
	self:UnregisterEvent("PET_BAR_HIDEGRID", Update)
	self:UnregisterEvent("PET_BAR_SHOWGRID", Update)
	self:UnregisterEvent("PET_BAR_UPDATE", Update)
	self:UnregisterEvent("PLAYER_ENTER_COMBAT", Update)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", Update)
	self:UnregisterEvent("PLAYER_LEAVE_COMBAT", Update)
	self:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", Update)
	--self:UnregisterEvent("PLAYER_REGEN_ENABLED", Update)
	self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
	self:UnregisterEvent("SPELL_UPDATE_CHARGES", Update)
	self:UnregisterEvent("SPELL_UPDATE_ICON", Update)
	self:UnregisterEvent("TRADE_SKILL_CLOSE", Update)
	self:UnregisterEvent("TRADE_SKILL_SHOW", Update)
	--self:UnregisterEvent("SPELLS_CHANGED", Update)
	self:UnregisterEvent("UPDATE_BINDINGS", Update)
	self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", Update)

	if (not LibClientBuild:IsClassic()) then 
		self:UnregisterEvent("ARCHAEOLOGY_CLOSED", Update)
		self:UnregisterEvent("COMPANION_UPDATE", Update)
		self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", Update)
		self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", Update)
		self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
		self:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
		self:UnregisterEvent("UPDATE_SUMMONPETS_ACTION", Update)
		self:UnregisterEvent("UPDATE_VEHICLE_ACTIONBAR", Update)
	end
end

ActionButton.OnEvent = function(button, event, ...)
	if (button:IsVisible() and Callbacks[button] and Callbacks[button][event]) then 
		local events = Callbacks[button][event]
		for i = 1, #events do
			events[i](button, event, ...)
		end
	end 
end

ActionButton.OnEnter = function(self) 
	self.isMouseOver = true

	-- Don't fire off tooltip updates if the button has no content
	if (not HasAction(self.buttonAction)) or (self:GetSpellID() == 0) then 
		self.UpdateTooltip = nil
		self:GetTooltip():Hide()
	else
		self.UpdateTooltip = UpdateTooltip
		self:UpdateTooltip()
	end 

	if self.PostEnter then 
		self:PostEnter()
	end 
end

ActionButton.OnLeave = function(self) 
	self.isMouseOver = nil
	self.UpdateTooltip = nil

	local tooltip = self:GetTooltip()
	tooltip:Hide()

	if self.PostLeave then 
		self:PostLeave()
	end 
end

ActionButton.PreClick = function(self) 
end

ActionButton.PostClick = function(self) 
end

-- Library API
----------------------------------------------------
LibSecureButton.CreateButtonLayers = function(self, button)

	local icon = button:CreateTexture()
	icon:SetDrawLayer("BACKGROUND", 2)
	icon:SetAllPoints()
	button.Icon = icon

	local slot = button:CreateTexture()
	slot:SetDrawLayer("BACKGROUND", 1)
	slot:SetAllPoints()
	button.Slot = slot

	local flash = button:CreateTexture()
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetAllPoints(icon)
	flash:SetColorTexture(1, 0, 0, .25)
	flash:Hide()
	button.Flash = flash

	local pushed = button:CreateTexture(nil, "OVERLAY")
	pushed:SetDrawLayer("ARTWORK", 1)
	pushed:SetAllPoints(icon)
	pushed:SetColorTexture(1, 1, 1, .15)
	button.Pushed = pushed

	-- We're letting blizzard handle this one,
	-- in order to catch both mouse clicks and keybind clicks.
	button:SetPushedTexture(pushed)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("ARTWORK") -- must be updated after pushed texture has been set
end

LibSecureButton.CreateButtonOverlay = function(self, button)
	local overlay = button:CreateFrame("Frame", nil, button)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(button:GetFrameLevel() + 15)
	button.Overlay = overlay
end 

LibSecureButton.CreateButtonKeybind = function(self, button)
	local keybind = (button.Overlay or button):CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(Game12Font_o1)
	keybind:SetJustifyH("CENTER")
	keybind:SetJustifyV("BOTTOM")
	keybind:SetShadowOffset(0, 0)
	keybind:SetShadowColor(0, 0, 0, 0)
	keybind:SetTextColor(230/255, 230/255, 230/255, .75)
	button.Keybind = keybind
end 

LibSecureButton.CreateButtonCount = function(self, button)
	local count = (button.Overlay or button):CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(Game12Font_o1)
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 0)
	count:SetTextColor(250/255, 250/255, 250/255, .85)
	button.Count = count
end 

LibSecureButton.CreateButtonSpellHighlight = function(self, button)
	local spellHighlight = button:CreateFrame("Frame")
	spellHighlight:Hide()
	spellHighlight:SetFrameLevel(button:GetFrameLevel() + 10)

	local texture = spellHighlight:CreateTexture()
	texture:SetDrawLayer("ARTWORK", 2)
	texture:SetAllPoints()
	texture:SetVertexColor(255/255, 225/255, 125/255, 1)

	local model = spellHighlight:CreateFrame("PlayerModel")
	model:Hide()
	model:SetFrameLevel(button:GetFrameLevel()-1)
	model:SetPoint("CENTER", 0, 0)
	model:EnableMouse(false)
	model:ClearModel()
	model:SetDisplayInfo(26501) 
	model:SetCamDistanceScale(3)
	model:SetPortraitZoom(0)
	model:SetPosition(0, 0, 0)

	local sizeFactor = 2 -- 3 is huge
	local updateSize = function()
		local w,h = button:GetSize()
		if (w and h) then 
			model:SetSize(w*sizeFactor,h*sizeFactor)
			if (not model:IsShown()) then 
				model:Show()
			end 
		else 
			model:Hide()
		end 
	end
	updateSize(model)

	hooksecurefunc(button, "SetSize", updateSize)
	hooksecurefunc(button, "SetWidth", updateSize)
	hooksecurefunc(button, "SetHeight", updateSize)

	button.SpellHighlight = spellHighlight
	button.SpellHighlight.Texture = texture
	button.SpellHighlight.Model = model
end

LibSecureButton.CreateButtonAutoCast = function(self, button)
	local autoCast = button:CreateFrame("Frame")
	autoCast:Hide()
	autoCast:SetFrameLevel(button:GetFrameLevel() + 10)

	local ants = autoCast:CreateTexture()
	ants:SetDrawLayer("ARTWORK", 1)
	ants:SetAllPoints()
	ants:SetVertexColor(255/255, 225/255, 125/255, 1)
	
	local animGroup = ants:CreateAnimationGroup()    
	animGroup:SetLooping("REPEAT")

	local anim = animGroup:CreateAnimation("Rotation")
	anim:SetDegrees(-360)
	anim:SetDuration(30)
	ants.Anim = animGroup

	local glow = autoCast:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 0)
	glow:SetAllPoints()
	glow:SetVertexColor(255/255, 225/255, 125/255, .25)

	local animGroup2 = glow:CreateAnimationGroup()
	animGroup2:SetLooping("REPEAT")

	for i = 1,10 do
		local anim2 = animGroup2:CreateAnimation("Rotation")
		anim2:SetOrder(i*2 - 1)
		anim2:SetDegrees(-18)
		anim2:SetDuration(1.5)

		local anim3 = animGroup2:CreateAnimation("Rotation")
		anim3:SetOrder(i*2)
		anim3:SetDegrees(-18)
		anim3:SetDuration(1.5)

		local alpha = animGroup2:CreateAnimation("Alpha")
		alpha:SetOrder(i*2 - 1)
		alpha:SetDuration(1.5)
		alpha:SetFromAlpha(.25)
		alpha:SetToAlpha(.75)

		local alpha2 = animGroup2:CreateAnimation("Alpha")
		alpha2:SetOrder(i*2)
		alpha2:SetDuration(1.5)
		alpha2:SetFromAlpha(.75)
		alpha2:SetToAlpha(.25)
	end 

	glow.Anim = animGroup2

	button.SpellAutoCast = autoCast
	button.SpellAutoCast.Ants = ants
	button.SpellAutoCast.Glow = glow
end

LibSecureButton.CreateButtonCooldowns = function(self, button)
	local cooldown = button:CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:Hide()
	cooldown:SetAllPoints()
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	cooldown:SetReverse(false)
	cooldown:SetSwipeColor(0, 0, 0, .75)
	cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
	cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	cooldown:SetDrawSwipe(true)
	cooldown:SetDrawBling(true)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true) 
	button.Cooldown = cooldown

	local cooldownCount = (button.Overlay or button):CreateFontString()
	cooldownCount:SetDrawLayer("ARTWORK", 1)
	cooldownCount:SetPoint("CENTER", 1, 0)
	cooldownCount:SetFontObject(Game12Font_o1)
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 0)
	cooldownCount:SetTextColor(250/255, 250/255, 250/255, .85)
	button.CooldownCount = cooldownCount

	local chargeCooldown = button:CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	chargeCooldown:Hide()
	chargeCooldown:SetAllPoints()
	chargeCooldown:SetFrameLevel(button:GetFrameLevel() + 2)
	chargeCooldown:SetReverse(false)
	chargeCooldown:SetSwipeColor(0, 0, 0, .75)
	chargeCooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
	chargeCooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	chargeCooldown:SetDrawEdge(true)
	chargeCooldown:SetDrawSwipe(true)
	chargeCooldown:SetDrawBling(false)
	chargeCooldown:SetHideCountdownNumbers(true) 
	button.ChargeCooldown = chargeCooldown
end

LibSecureButton.CreateFlyoutArrow = function(self, button)
	local flyoutArrow = (button.Overlay or button):CreateTexture()
	flyoutArrow:Hide()
	flyoutArrow:SetSize(23,11)
	flyoutArrow:SetDrawLayer("OVERLAY", 1)
	flyoutArrow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
	flyoutArrow:SetTexCoord(.625, .984375, .7421875, .828125)
	flyoutArrow:SetPoint("TOP", 0, 2)
	button.FlyoutArrow = flyoutArrow

	-- blizzard code bugs out without these
	button.FlyoutBorder = button:CreateTexture()
	button.FlyoutBorderShadow = button:CreateTexture()
end 

-- Public API
----------------------------------------------------
LibSecureButton.SpawnActionButton = function(self, buttonType, parent, buttonTemplate, ...)
	check(parent, 1, "string", "table")
	check(buttonType, 2, "string")
	check(buttonTemplate, 3, "table", "nil")

	-- Doing it this way to only include the global arguments 
	-- available in all button types as function arguments. 
	local barID, buttonID = ...

	-- Store the button and its type
	if (not Buttons[self]) then 
		Buttons[self] = {}
	end 

	-- Increase the button count
	LibSecureButton.numButtons = LibSecureButton.numButtons + 1

	-- Count this addon's buttons 
	local count = 0 
	for button in pairs(Buttons[self]) do 
		count = count + 1
	end 

	-- Make up an unique name
	local name = nameHelper(self, count + 1)

	-- Create an additional visibility layer to handle manual toggling
	local visibility = self:CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
	visibility:Hide() -- driver will show it later on
	visibility:SetAttribute("_onattributechanged", [=[
		if (name == "state-vis") then
			if (value == "show") then 
				self:Show(); 
			elseif (value == "hide") then 
				self:Hide(); 
			end 
		end
	]=])

	-- Add a page driver layer, basically a fake bar for the current button
	-- 
	-- *Note that the functions meant to check for the various types of bars
	--  sometimes will return 'false' directly after a page change, when they should be 'true'. 
	--  No idea as to why this randomly happens, but the macro driver at least responds correctly, 
	--  and the bar index can still be retrieved correctly, so for now we just skip the checks. 
	-- 
	-- Affected functions, which we choose to avoid/work around here: 
	-- 		HasVehicleActionBar()
	-- 		HasOverrideActionBar()
	-- 		HasTempShapeshiftActionBar()
	-- 		HasBonusActionBar()

	-- Need to figure these out on button creation, 
	-- as we're not interested in the library owner's name, 
	-- but rather the addon name of the module calling this method. 
	local DEBUG_ENABLED
	if self.GetAddon then 
		local addon = self:GetAddon() 
		if addon then 
			-- We're making the addon naming scheme a rule here?
			-- Seems clunky, but for the time being it'll have to do. 
			-- Eventually we'll find a better way of implementing this. 
			if self:GetOwner():IsDebugModeEnabled() then 
				DEBUG_ENABLED = true 
			end
			--if CogWheel("LibModule"):IsAddOnEnabled((addon or "").."_Debug") then 
			--	DEBUG_ENABLED = true 
			--end
		end
	end

	local page = visibility:CreateFrame("Frame", nil, "SecureHandlerAttributeTemplate")
	page.id = barID
	page.AddDebugMessage = DEBUG_ENABLED and self.AddDebugMessageFormatted or nil
	page:SetID(barID) 
	page:SetAttribute("_onattributechanged", DEBUG_ENABLED and SECURE.Page_OnAttributeChanged_Debug or SECURE.Page_OnAttributeChanged)
	
	local button = setmetatable(page:CreateFrame("CheckButton", name, "SecureActionButtonTemplate"), ActionButton_MT)
	button:SetFrameStrata("LOW")

	LibSecureButton:CreateButtonLayers(button)
	LibSecureButton:CreateButtonOverlay(button)
	LibSecureButton:CreateButtonCooldowns(button)
	LibSecureButton:CreateButtonCount(button)
	LibSecureButton:CreateButtonKeybind(button)
	LibSecureButton:CreateButtonSpellHighlight(button)
	LibSecureButton:CreateButtonAutoCast(button)
	LibSecureButton:CreateFlyoutArrow(button)

	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")

	-- This allows drag functionality, but stops the casting, 
	-- thus allowing us to drag spells even with cast on down, wohoo! 
	-- Doesn't currently appear to be a way to make this work without the modifier, though, 
	-- since the override bindings we use work by sending mouse events to the listeners, 
	-- meaning there's no way to separate keys and mouse buttons. 
	button:SetAttribute("alt-ctrl-shift-type*", "stop")

	button:SetID(buttonID)
	button:SetAttribute("type", "action")
	button:SetAttribute("flyoutDirection", "UP")
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-actionpage", true)
	button:SetAttribute("buttonLock", true)
	button.id = buttonID
	button.action = 0

	button._owner = visibility
	button._pager = page


	button:SetScript("OnEnter", ActionButton.OnEnter)
	button:SetScript("OnLeave", ActionButton.OnLeave)
	button:SetScript("PreClick", ActionButton.PreClick)
	button:SetScript("PostClick", ActionButton.PostClick)
	button:SetScript("OnUpdate", OnUpdate)

	-- A little magic to allow us to toggle autocasting of pet abilities
	page:WrapScript(button, "PreClick", [[
		if (button ~= "RightButton") then 
			if (self:GetAttribute("type2")) then 
				self:SetAttribute("type2", nil); 
			end 
			return 
		end
		local actionpage = self:GetAttribute("actionpage"); 
		if (not actionpage) then
			if (self:GetAttribute("type2")) then 
				self:SetAttribute("type2", nil); 
			end 
			return
		end
		local id = self:GetID(); 
		local action = (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 
		local actionType, id, subType = GetActionInfo(action);
		if (subType == "pet") and (id ~= 0) then 
			self:SetAttribute("type2", "macro"); 
		else 
			if (self:GetAttribute("type2")) then 
				self:SetAttribute("type2", nil); 
			end 
		end 
	]]) 

	page:SetFrameRef("Visibility", visibility)
	page:SetFrameRef("Button", button)
	visibility:SetFrameRef("Page", page)

	button:SetAttribute("OnDragStart", [[
		local actionpage = self:GetAttribute("actionpage"); 
		if (not actionpage) then
			return
		end
		local id = self:GetID(); 
		local buttonLock = self:GetAttribute("buttonLock"); 
		local action = (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 
		if action and ( (not buttonLock) or (IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) ) then
			return "action", action
		end
	]])

	-- When a spell is dragged from a button
	-- *This never fires when cast on down is enabled. ARGH! 
	page:WrapScript(button, "OnDragStart", [[
		return self:RunAttribute("OnDragStart")
	]])
	-- Bartender says: 
	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	page:WrapScript(button, "OnDragStart", [[
		return "message", "update"
	]])

	-- When a spell is dropped onto a button
	page:WrapScript(button, "OnReceiveDrag", [[
		local kind, value, subtype, extra = ...
		if ((not kind) or (not value)) then 
			return false 
		end
		local button = self:GetFrameRef("Button"); 
		local buttonLock = button and button:GetAttribute("buttonLock"); 
		local actionpage = self:GetAttribute("actionpage"); 
		local id = self:GetID(); 
		local action = actionpage and (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 
		if action and ((not buttonLock) or (IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown())) then
			return "action", action
		end 
	]])
	page:WrapScript(button, "OnReceiveDrag", [[
		return "message", "update"
	]])

	local driver 
	if (barID == 1) then 

		-- Moving vehicles farther back in the queue, as some overridebars like the ones 
		-- found in the new 8.1.5 world quest "Cycle of Life" returns positive for both vehicleui and overridebar. 
		driver = ("[overridebar]%.0f; [possessbar]%.0f; [shapeshift]%.0f; [vehicleui]%.0f; [form,noform] 0; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6"):format(GetOverrideBarIndex(), GetVehicleBarIndex(), GetTempShapeshiftBarIndex(), GetVehicleBarIndex())

		local _, playerClass = UnitClass("player")
		if (playerClass == "DRUID") then
			driver = driver .. "; [bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"

		elseif (playerClass == "MONK") then
			driver = driver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"

		elseif (playerClass == "PRIEST") then
			driver = driver .. "; [bonusbar:1] 7"

		elseif (playerClass == "ROGUE") then
			driver = driver .. "; [bonusbar:1] 7"

		elseif (playerClass == "WARRIOR") then
			driver = driver .. "; [bonusbar:1] 7; [bonusbar:2] 8" 
		end
		--driver = driver .. "; [form] 1; 1"
		driver = driver .. "; 1"
	else 
		driver = tostring(barID)
	end 

	local visibilityDriver
	if (barID == 1) then 
		visibilityDriver = "[@player,exists][overridebar][possessbar][shapeshift][vehicleui]show;hide"
	else 
		visibilityDriver = "[overridebar][possessbar][shapeshift][vehicleui][@player,noexists]hide;show"
	end 
	
	-- enable the visibility driver
	RegisterAttributeDriver(visibility, "state-vis", visibilityDriver)
	
	-- reset the page before applying a new page driver
	page:SetAttribute("state-page", "0") 

	-- just in case we're not run by a header, default to state 0
	button:SetAttribute("state", "0")

	-- enable the page driver
	RegisterAttributeDriver(page, "state-page", driver) 

	-- initial action update
	button:UpdateAction()

	Buttons[self][button] = buttonType
	AllButtons[button] = buttonType

	-- Add any methods from the optional template.
	-- *we're now allowing modules to overwrite methods.
	if buttonTemplate then
		for methodName, func in pairs(buttonTemplate) do
			if (type(func) == "function") then
				button[methodName] = func
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if button.PostCreate then
		button:PostCreate(...)
	end

	-- Our own event handler
	button:SetScript("OnEvent", button.OnEvent)

	-- Update all elements when shown
	button:HookScript("OnShow", button.Update)
	
	-- Enable the newly created button
	-- This is where events are registered and set up
	button:OnEnable()

	-- Run a full initial update
	button:Update()

	return button
end

-- Returns an iterator for all buttons registered to the module
-- Buttons are returned as the first return value, and ordered by their IDs.
LibSecureButton.GetAllActionButtonsOrdered = function(self)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		sorted[#sorted + 1] = button
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 

-- Returns an iterator for all buttons of the given type registered to the module.
-- Buttons are returned as the first return value, and ordered by their IDs.
LibSecureButton.GetAllActionButtonsByType = function(self, buttonType)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		if (type == buttonType) then 
			sorted[#sorted + 1] = button
		end 
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 

LibSecureButton.GetActionButtonTooltip = function(self)
	return LibSecureButton:GetTooltip("CG_ActionButtonTooltip") or LibSecureButton:CreateTooltip("CG_ActionButtonTooltip")
end

LibSecureButton.GetActionBarControllerPetBattle = function(self)
	if ((not Controllers[self]) or (not Controllers[self].petBattle)) then 

		-- Get the generic button name without the ID added
		local name = nameHelper(self)

		-- The blizzard petbattle UI gets its keybinds from the primary action bar, 
		-- so in order for the petbattle UI keybinds to function properly, 
		-- we need to temporarily give the primary action bar backs its keybinds.
		local petbattle = self:CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
		petbattle:SetAttribute("_onattributechanged", [[
			if (name == "state-petbattle") then
				if (value == "petbattle") then
					for i = 1,6 do
						local our_button, blizz_button = ("CLICK ]]..name..[[%.0f:LeftButton"):format(i), ("ACTIONBUTTON%.0f"):format(i)

						-- Grab the keybinds from our own primary action bar,
						-- and assign them to the default blizzard bar. 
						-- The pet battle system will in turn get its bindings 
						-- from the default blizzard bar, and the magic works! :)
						
						for k=1,select("#", GetBindingKey(our_button)) do
							local key = select(k, GetBindingKey(our_button)) -- retrieve the binding key from our own primary bar
							self:SetBinding(true, key, blizz_button) -- assign that key to the default bar
						end
						
						-- do the same for the default UIs bindings
						for k=1,select("#", GetBindingKey(blizz_button)) do
							local key = select(k, GetBindingKey(blizz_button))
							self:SetBinding(true, key, blizz_button)
						end	
					end
				else
					-- Return the key bindings to whatever buttons they were
					-- assigned to before we so rudely grabbed them! :o
					self:ClearBindings()
				end
			end
		]])

		-- Do we ever need to update his?
		RegisterAttributeDriver(petbattle, "state-petbattle", "[petbattle]petbattle;nopetbattle")

		if (not Controllers[self]) then 
			Controllers[self] = {}
		end
		Controllers[self].petBattle = petbattle
	end
	return Controllers[self].petBattle
end

LibSecureButton.GetActionBarControllerVehicle = function(self)
end

-- Modules should call this at UPDATE_BINDINGS and the first PLAYER_ENTERING_WORLD
LibSecureButton.UpdateActionButtonBindings = function(self)

	-- "BONUSACTIONBUTTON%.0f" -- pet bar
	-- "SHAPESHIFTBUTTON%.0f" -- stance bar

	local mainBarUsed
	local petBattleUsed, vehicleUsed

	for button in self:GetAllActionButtonsByType("action") do 

		local pager = button:GetPager()

		-- clear current overridebindings
		ClearOverrideBindings(pager) 

		-- retrieve page and button id
		local buttonID = button:GetID()
		local barID = button:GetPageID()

		-- figure out the binding action
		local bindingAction
		if (barID == 1) then 
			bindingAction = ("ACTIONBUTTON%.0f"):format(buttonID)

			-- We've used the main bar, and need to update the controllers
			mainBarUsed = true

		elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR1BUTTON%.0f"):format(buttonID)

		elseif (barID == BOTTOMRIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR2BUTTON%.0f"):format(buttonID)

		elseif (barID == RIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR3BUTTON%.0f"):format(buttonID)

		elseif (barID == LEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR4BUTTON%.0f"):format(buttonID)
		end 

		-- store the binding action name on the button
		button.bindingAction = bindingAction

		-- iterate through the registered keys for the action
		for keyNumber = 1, select("#", GetBindingKey(bindingAction)) do 

			-- get a key for the action
			local key = select(keyNumber, GetBindingKey(bindingAction)) 
			if (key and (key ~= "")) then
				-- this is why we need named buttons
				SetOverrideBindingClick(pager, false, key, button:GetName(), "CLICK: LeftButton") -- assign the key to our own button
			end	
		end
	end 

	if (mainBarUsed and not petBattleUsed) then 
		self:GetActionBarControllerPetBattle()
	end 

	if (mainBarUsed and not vehicleUsed) then 
		self:GetActionBarControllerVehicle()
	end 
end 

-- This will cause multiple updates when library is updated. Hmm....
hooksecurefunc("ActionButton_UpdateFlyout", function(self, ...)
	if AllButtons[self] then
		self:UpdateFlyout()
	end
end)

-- Module embedding
local embedMethods = {
	SpawnActionButton = true,
	GetActionButtonTooltip = true, 
	GetAllActionButtonsOrdered = true,
	GetAllActionButtonsByType = true,
	GetActionBarControllerPetBattle = true,
	GetActionBarControllerVehicle = true,
	UpdateActionButtonBindings = true,
}

LibSecureButton.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibSecureButton.embeds) do
	LibSecureButton:Embed(target)
end
