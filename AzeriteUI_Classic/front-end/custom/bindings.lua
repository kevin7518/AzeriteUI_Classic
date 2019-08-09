local ADDON, Private = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local L, Layout
local Module = Core:NewModule("Bindings", "PLUGIN", "LibEvent", "LibMessage", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibFader", "LibSlash")
Module:SetIncompatible("ConsolePort")

-- Lua API
local _G = _G
local pairs = pairs
local print = print
local setmetatable = setmetatable
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub

-- WoW API
local GetCurrentBindingSet = _G.GetCurrentBindingSet
local InCombatLockdown = _G.InCombatLockdown
local IsAltKeyDown = _G.IsAltKeyDown
local IsControlKeyDown = _G.IsControlKeyDown
local IsShiftKeyDown = _G.IsShiftKeyDown
local LoadBindings = _G.LoadBindings
local SaveBindings = _G.SaveBindings
local SetBinding = _G.SetBinding

-- Copies of WoW constants (the originals are loaded through an addon, so not reliable as globals)
local ACCOUNT_BINDINGS = 1
local CHARACTER_BINDINGS = 2

-- BindFrame Template
----------------------------------------------------
local BindFrame = Module:CreateFrame("Frame")
local BindFrame_MT = { __index = BindFrame }

BindFrame.GetActionName = function(self)
	local actionName 
	local bindingAction = self.button.bindingAction
	if bindingAction then 
		actionName = _G["BINDING_NAME_"..bindingAction]
	end 
	return actionName
end

BindFrame.OnMouseUp = function(self, key) 
	self.module:ProcessInput(key) 
end

BindFrame.OnMouseWheel = function(self, delta) 
	self.module:ProcessInput((delta > 0) and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") 
end

BindFrame.OnEnter = function(self) 

	-- Start listening for keybind input
	local bindingFrame = self.module:GetBindingFrame()
	bindingFrame:EnableKeyboard(true)

	-- Tell the module that we have a current button
	bindingFrame.bindButton = self.button

	-- Retrieve the action
	local bindingAction = self.button.bindingAction
	local binds = { GetBindingKey(bindingAction) } 
	
	-- Show the tooltip
	local tooltip = self.module:GetBindingsTooltip()
	tooltip:SetDefaultAnchor(self)
	tooltip:AddLine(self:GetActionName(), 1, .82, .1)

	if (#binds == 0) then 
		tooltip:AddLine(L["No keybinds set."], 1, 0, 0)
	else 
		tooltip:AddDoubleLine("Binding", "Key", .6, .6, .6, .6, .6, .6)
		for i = 1,#binds do
			tooltip:AddDoubleLine(i .. ":", self.module:GetBindingName(binds[i]), 1, .82, 0, 0, 1, 0)
		end
	end 
	tooltip:Show()

	-- Let the layout do its graphical post updates
	if Layout.BindButton_PostEnter then 
		Layout.BindButton_PostEnter(self)
	end
end

BindFrame.OnLeave = function(self) 

	-- Stop lisetning for keyboard input
	local bindingFrame = self.module:GetBindingFrame()
	bindingFrame:EnableKeyboard(false)

	-- Tell the module we're no longer above this button
	bindingFrame.bindButton = nil

	-- Hide the tooltip
	self.module:GetBindingsTooltip():Hide()

	-- Let the layout do its graphical post updates
	if Layout.BindButton_PostLeave then 
		Layout.BindButton_PostLeave(self)
	end
end

BindFrame.UpdateBinding = function(self)
	-- Update main bind text
	self.msg:SetText(self.button.GetBindingTextAbbreviated and self.button:GetBindingTextAbbreviated() or self.button:GetBindingText())
end

-- Utility Methods
----------------------------------------------------
-- Utility function for easy colored output messages
Module.Print = function(self, r, g, b, msg)
	if (type(r) == "string") then 
		print(r)
		return 
	end
	print(string_format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, msg))
end

-- BindButton Handling
----------------------------------------------------
-- Register a button with the bind system
Module.RegisterButton = function(self, button, ...)
	if (not self.binds) then 
		self.binds = {}
	end

	-- create overlay frame parented to our parent bind frame
	local bindFrame = setmetatable(self:CreateFrame("Frame", nil, self:GetBindingFrame()), BindFrame_MT)
	bindFrame:Hide()
	bindFrame:SetFrameStrata("DIALOG")
	bindFrame:SetFrameLevel(1)
	bindFrame:SetAllPoints(button)
	bindFrame:EnableKeyboard(false)
	bindFrame:EnableMouse(true)
	bindFrame:EnableMouseWheel(true)
	bindFrame.button = button
	bindFrame.module = self

	-- Mouse input is connected to the frame the cursor is currently over, 
	-- so we prefer to register these for every single button. 
	bindFrame:SetScript("OnMouseUp", BindFrame.OnMouseUp)
	bindFrame:SetScript("OnMouseWheel", BindFrame.OnMouseWheel)

	-- Let our master binding frame know what buton we're currently over.
	bindFrame:SetScript("OnEnter", BindFrame.OnEnter)
	bindFrame:SetScript("OnLeave", BindFrame.OnLeave)

	-- create overlay texture
	local bg = bindFrame:CreateTexture()
	bg:SetDrawLayer("BACKGROUND", 1)
	bg:SetAllPoints()
	bindFrame.bg = bg

	-- create overlay text for key input
	local msg = bindFrame:CreateFontString()
	msg:SetDrawLayer("OVERLAY", 1)
	msg:SetPoint("CENTER", 0, 0)
	msg:SetFontObject(GameFontNormal)
	bindFrame.msg = msg

	-- Run layout post creation updates
	if Layout.BindButton_PostCreate then 
		Layout.BindButton_PostCreate(bindFrame)
	end 

	self.binds[button] = bindFrame
end

Module.GetBindingName = function(self, binding)
	local bindingName = ""
	if string_find(binding, "ALT%-") then
		binding = string_gsub(binding, "(ALT%-)", "") 
		bindingName = bindingName .. ALT_KEY_TEXT .. "+"
	end 
	if string_find(binding, "CTRL%-") then 
		binding = string_gsub(binding, "(CTRL%-)", "") 
		bindingName = bindingName .. CTRL_KEY_TEXT .. "+"
	end 
	if string_find(binding, "SHIFT%-") then 
		binding = string_gsub(binding, "(SHIFT%-)", "") 
		bindingName = bindingName .. SHIFT_KEY_TEXT .. "+"
	end 
	return bindingName .. (_G[binding.."_KEY_TEXT"] or _G["KEY_"..binding] or binding)
end

-- Figure out the correct binding key combination and its display name
Module.GetBinding = function(self, key)

	-- Mousebutton translations
	if (key == "LeftButton") then key = "BUTTON1" end
	if (key == "RightButton") then key = "BUTTON2" end
	if (key == "MiddleButton") then key = "BUTTON3" end
	if (key:find("Button%d")) then
		key = key:upper()
	end
	
	local alt = IsAltKeyDown() and "ALT-" or ""
	local ctrl = IsControlKeyDown() and "CTRL-" or ""
	local shift = IsShiftKeyDown() and "SHIFT-" or ""

	return alt..ctrl..shift..key
end

Module.ProcessInput = function(self, key)
	-- Pause the processing if we currently 
	-- have a dialog open awaiting a user choice, 
	local bindingFrame = self:GetBindingFrame()
	if bindingFrame.lockdown then 
		return 
	end 

	-- Bail out if the mouse isn't above a registered button.
	local button = bindingFrame.bindButton
	if (not button) or (not self.binds[button]) then 
		return 
	end

	-- Retrieve the action
	local bindFrame = self.binds[button]
	local bindingAction = button.bindingAction
	local binds = { GetBindingKey(bindingAction) } 

	-- Clear the button's bindings
	if (key == "ESCAPE") and (#binds > 0) then
		for i = 1, #binds do 
			SetBinding(binds[i], nil)
		end

		self:Print(1, 0, 0, L["%s is now unbound."]:format(bindFrame:GetActionName()))

		-- Post update tooltips with changes
		if self:GetBindingsTooltip():IsShown() then 
			bindFrame:OnEnter()
		end
		return 
	end

	-- Ignore modifiers until an actual key or mousebutton is pressed
	if (key == "LSHIFT") or (key == "RSHIFT")
	or (key == "LCTRL") or (key == "RCTRL")
	or (key == "LALT") or (key == "RALT")
	or (key == "UNKNOWN")
	then
		return 
	end

	-- Get the binding key and its display name
	local keybind = self:GetBinding(key)
	local keybindName = self:GetBindingName(keybind)

	-- Hidden defaults that some addons and UIs allow the user to change. 
	-- Leaving it here for my own reference. 
	--SetBinding("BUTTON1", "CAMERAORSELECTORMOVE")
	--SetBinding("BUTTON2", "TURNORACTION")
	--SaveBindings(GetCurrentBindingSet())

	-- Don't allow people to bind these, let's follow blizz standards here. 
	if (keybind == "BUTTON1") or (keybind == "BUTTON2") then 
		return 
	end 

	-- If binds exist, we re-order it to be the last one. 
	if (#binds > 0) then 
		for i = 1,#binds do 
			
			-- We've found a match
			if (keybind == binds[i]) then 
				
				-- if the match is the first and only bind, or the last one registered, we change nothing 
				if (#binds == 1) or (i == #binds) then
					return 
				end  

				-- Clear all existing binds to be able to re-order
				for j = 1,#binds do
					SetBinding(binds[j], nil)
				end
		
				-- Re-apply all other existing binds, except the one we just pressed. 
				for j = 1,#binds do
					if (keybind ~= binds[j]) then 
						SetBinding(binds[j], bindingAction)
					end
				end
			end
		end
	end

	-- Changes were made
	self.bindingsChanged = true

	-- Bind the keys we pressed to the button's action
	SetBinding(keybind, bindingAction)

	-- Display a message about the new bind
	self:Print(0, 1, 0, L["%s is now bound to %s"]:format(self.binds[button]:GetActionName(), keybindName))

	-- Post update tooltips with changes
	if self:GetBindingsTooltip():IsShown() then 
		bindFrame:OnEnter()
	end
end

Module.UpdateBindings = function(self)
	for button, bindFrame in pairs(self.binds) do 
		bindFrame:UpdateBinding()
	end 
end

Module.UpdateButtons = function(self)
	for button, bindFrame in pairs(self.binds) do 
		bindFrame:SetShown(button:IsVisible())
	end 
end 

-- Mode Toggling
----------------------------------------------------
Module.EnableBindMode = function(self)
	if InCombatLockdown() then 
		self:Print(1, 0, 0, L["Keybinds cannot be changed while engaged in combat."])
		return 
	end 

	self.bindActive = true
	self:SetObjectFadeOverride(true)

	local ActionBars = Core:GetModule("ActionBarMain", true)
	if (ActionBars) then 
		ActionBars:SetForcedVisibility(true)
	end 

	self:GetBindingFrame():Show()
	self:UpdateButtons()
	self:SendMessage("CG_BIND_MODE_ENABLED")
end 

Module.DisableBindMode = function(self)
	self.bindActive = false
	self:SetObjectFadeOverride(false)

	local ActionBars = Core:GetModule("ActionBarMain", true)
	if (ActionBars) then 
		ActionBars:SetForcedVisibility(false)
	end 

	self.bindingsChanged = nil
	self:GetBindingFrame():Hide()
	self:SendMessage("CG_BIND_MODE_DISABLED")
end

Module.ApplyBindings = function(self)
	SaveBindings(GetCurrentBindingSet())
	if self.bindingsChanged then 
		self:Print(.1, 1, .1, L["Keybind changes were saved."])
	else 
		self:Print(1, .82, 0, L["No keybinds were changed."])
	end 
	self:DisableBindMode()
end

Module.CancelBindings = function(self)
	-- Re-load the stored bindings to cancel any changes
	LoadBindings(GetCurrentBindingSet())

	-- Output a message depending on whether or not any changes were cancelled
	if self.bindingsChanged then 
		self:Print(1, 0, 0, L["Keybind changes were discarded."])
	else 
		self:Print(1, .82, 0, L["No keybinds were changed."])
	end 

	-- Close the windows and disable the bind mode
	self:DisableBindMode()

	-- Update the local bindings cache
	self:UpdateBindingsCache()
end 

-- Will be called when switching between general and character specific keybinds
Module.ChangeBindingSet = function(self)

	-- Check if current bindings have changed, show a warning dialog if so. 
	if self.bindingsChanged or (self.lockdown and (not self.acceptDiscard)) then 

		-- We don't get farther than this unless the 
		-- user clicks 'Accept' in the dialog below.
		local discardFrame = self:GetDiscardFrame()
		if (not discardFrame:IsShown()) then 
			discardFrame:Show()
		end
	else
		self.acceptDiscard = nil
		self.bindingsChanged = nil 

		-- Load the appropriate binding set
		if (self:GetBindingFrame().perCharacter:GetChecked()) then
			LoadBindings(CHARACTER_BINDINGS)
			SaveBindings(CHARACTER_BINDINGS)
		else
			LoadBindings(ACCOUNT_BINDINGS)
			SaveBindings(ACCOUNT_BINDINGS)
		end

		-- Update the local bindings cache
		self:UpdateBindingsCache()
	end 
end 

-- Update and reset the local cache of keybinds
Module.UpdateBindingsCache = function(self)

end

-- Module Frame Creation & Retrieval
----------------------------------------------------
Module.CreateWindow = function(self)
	local frame = self:CreateFrame("Frame", nil, "UICenter")
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(99)
	frame:EnableMouse(false)
	frame:EnableKeyboard(false)
	frame:EnableMouseWheel(false)
	frame:SetSize(unpack(Layout.Size))
	frame:Place(unpack(Layout.Place))
	frame.border = Layout.MenuWindow_CreateBorder(frame)

	local msg = frame:CreateFontString()
	msg:SetFontObject(Private.GetFont(14, true))
	msg:SetPoint("TOPLEFT", 40, -40)
	msg:SetSize(Layout.Size[1] - 80, Layout.Size[2] - 80 - 30)
	msg:SetJustifyH("LEFT")
	msg:SetJustifyV("TOP")
	msg:SetIndentedWordWrap(false)
	msg:SetWordWrap(true)
	msg:SetNonSpaceWrap(false)
	frame.msg = msg

	local cancel = Layout.MenuButton_PostCreate(frame:CreateFrame("Button"), CANCEL)
	cancel:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod)
	cancel:SetPoint("BOTTOMLEFT", 20, 10)
	frame.cancel = cancel

	local apply = Layout.MenuButton_PostCreate(frame:CreateFrame("Button"), APPLY)
	apply:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod)
	apply:SetPoint("BOTTOMRIGHT", -20, 10)
	frame.apply = apply

	if Layout.MenuButton_PostUpdate then 
		local PostUpdate = Layout.MenuButton_PostUpdate

		frame.apply:HookScript("OnEnter", PostUpdate)
		frame.apply:HookScript("OnLeave", PostUpdate)
		frame.apply:HookScript("OnMouseDown", function(self) self.isDown = true; return PostUpdate(self) end)
		frame.apply:HookScript("OnMouseUp", function(self) self.isDown = false; return PostUpdate(self) end)
		frame.apply:HookScript("OnShow", function(self) self.isDown = false; return PostUpdate(self) end)
		frame.apply:HookScript("OnHide", function(self) self.isDown = false; return PostUpdate(self) end)
		PostUpdate(frame.apply)

		frame.cancel:HookScript("OnEnter", PostUpdate)
		frame.cancel:HookScript("OnLeave", PostUpdate)
		frame.cancel:HookScript("OnMouseDown", function(self) self.isDown = true; return PostUpdate(self) end)
		frame.cancel:HookScript("OnMouseUp", function(self) self.isDown = false; return PostUpdate(self) end)
		frame.cancel:HookScript("OnShow", function(self) self.isDown = false; return PostUpdate(self) end)
		frame.cancel:HookScript("OnHide", function(self) self.isDown = false; return PostUpdate(self) end)
		PostUpdate(frame.cancel)
	else
		frame.apply:HookScript("OnMouseDown", function(self) self.isDown = true end)
		frame.apply:HookScript("OnMouseUp", function(self) self.isDown = false end)
		frame.apply:HookScript("OnShow", function(self) self.isDown = false end)
		frame.apply:HookScript("OnHide", function(self) self.isDown = false end)

		frame.cancel:HookScript("OnMouseDown", function(self) self.isDown = true end)
		frame.cancel:HookScript("OnMouseUp", function(self) self.isDown = false end)
		frame.cancel:HookScript("OnShow", function(self) self.isDown = false end)
		frame.cancel:HookScript("OnHide", function(self) self.isDown = false end)
	end 

	return frame
end 

Module.GetBindingFrame = function(self)
	if (not self.frame) then 
		local frame = self:CreateWindow() 
		frame:SetFrameLevel(96)
		frame:EnableKeyboard(false)
		frame:EnableMouse(false)
		frame:EnableMouseWheel(false)

		frame.msg:ClearAllPoints()
		frame.msg:SetPoint("TOPLEFT", 40, -60)
		frame.msg:SetSize(Layout.Size[1] - 80, Layout.Size[2] - 80 - 50)
		frame.msg:SetText(L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."])

		local perCharacter = frame:CreateFrame("CheckButton", nil, "OptionsCheckButtonTemplate")
		perCharacter:SetSize(32,32)
		perCharacter:SetHitRectInsets(-10, -(10 + Layout.Size[1] - 80 - 32 -10), -10, -10)
		perCharacter:SetPoint("TOPLEFT", 34, -16)
		
		perCharacter:SetScript("OnShow", function(self) 
			self:SetChecked(GetCurrentBindingSet() == 2) 
		end)
		
		perCharacter:SetScript("OnClick", function() 
			-- Update the discard confirm frame's text when the checkbox is toggled.
			-- The frame will however only be shown if changes were made prior to toggling it.
			local discardFrame = self:GetDiscardFrame()
			if perCharacter:GetChecked() then 
				discardFrame.msg:SetText(CONFIRM_LOSE_BINDING_CHANGES)
			else 
				discardFrame.msg:SetText(CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS)
			end 
			self:ChangeBindingSet() 
		end) 
		
		perCharacter:SetScript("OnEnter", function(self)
			local tooltip = Module:GetBindingsTooltip()
			tooltip:SetDefaultAnchor(self)
			tooltip:AddLine(CHARACTER_SPECIFIC_KEYBINDINGS, Private.Colors.title[1], Private.Colors.title[2], Private.Colors.title[3])
			tooltip:AddLine(CHARACTER_SPECIFIC_KEYBINDING_TOOLTIP, Private.Colors.offwhite[1], Private.Colors.offwhite[2], Private.Colors.offwhite[3], true)
			tooltip:Show()
		end)

		perCharacter:SetScript("OnLeave", function(self)
			local tooltip = Module:GetBindingsTooltip()
			tooltip:Hide() 
		end)
		
		local perCharacterMsg = perCharacter:CreateFontString()
		perCharacterMsg:SetFontObject(Private.GetFont(14, true))
		perCharacterMsg:SetPoint("LEFT", perCharacter, "RIGHT", 10, 0)
		perCharacterMsg:SetJustifyH("CENTER")
		perCharacterMsg:SetJustifyV("TOP")
		perCharacterMsg:SetIndentedWordWrap(false)
		perCharacterMsg:SetWordWrap(true)
		perCharacterMsg:SetNonSpaceWrap(false)
		perCharacterMsg:SetText(CHARACTER_SPECIFIC_KEYBINDINGS)

		frame.perCharacter = perCharacter
		frame.perCharacter.msg = perCharacterMsg

		frame.cancel:SetScript("OnClick", function() self:CancelBindings() end)
		frame.apply:SetScript("OnClick", function() self:ApplyBindings() end)

		frame:SetScript("OnKeyUp", function(_, key) self:ProcessInput(key) end)

		self.frame = frame
	end 
	return self.frame	
end

Module.GetDiscardFrame = function(self)
	if (not self.discardFrame) then
		local frame = self:CreateWindow()
		frame:SetFrameLevel(99)
		frame:EnableMouse(true)
		frame:ClearAllPoints()
		frame:SetPoint("TOP", self:GetBindingFrame(), "BOTTOM", 0, -20)

		frame.msg:ClearAllPoints()
		frame.msg:SetPoint("TOPLEFT", 40 + 70, -40)
		frame.msg:SetSize(Layout.Size[1] - 80 - 70, Layout.Size[2] - 80 - 50)

		local texture = frame:CreateTexture()
		texture:SetSize(60, 60)
		texture:SetPoint("TOPLEFT", 40, -40)
		texture:SetTexture(STATICPOPUP_TEXTURE_ALERT)

		local mouseBlocker = frame:CreateFrame("Frame")
		mouseBlocker:SetAllPoints(self:GetBindingFrame())
		mouseBlocker:EnableMouse(true)
		frame.mouseBlocker = mouseBlocker

		local blockTexture = mouseBlocker:CreateTexture()
		blockTexture:SetDrawLayer("OVERLAY", 1)
		blockTexture:SetAllPoints()
		blockTexture:SetColorTexture(0, 0, 0, .5)
		mouseBlocker.texture = blockTexture

		frame:HookScript("OnShow", function() 
			self.lockdown = true 
		end)

		frame:HookScript("OnHide", function() 
			self.lockdown = nil 
		end)

		frame.cancel:SetScript("OnClick", function() 
			self.acceptDiscard = nil

			-- Revert the checkbox click on cancel
			local bindingFrame = self:GetBindingFrame()
			bindingFrame.perCharacter:SetChecked(not bindingFrame.perCharacter:GetChecked())

			-- Hide this
			frame:Hide() 
		end)

		frame.apply.Msg:SetText(ACCEPT)
		frame.apply:SetScript("OnClick", function() 
			self.acceptDiscard = true

			-- Continue changing the binding set
			self:ChangeBindingSet() 

			-- Hide this
			frame:Hide() 
		end)


		self.discardFrame = frame
	end 
	return self.discardFrame
end 

Module.GetBindingsTooltip = function(self)
	return self:GetTooltip(ADDON.."_KeyBindingsTooltip") or self:CreateTooltip(ADDON.."_KeyBindingsTooltip")
end

-- Menu Integration
----------------------------------------------------
-- Check if the bind mode is enabled
Module.IsBindModeEnabled = function(self)
	return self:GetBindingFrame():IsShown()
end

-- Callback needed by the menu system to decide 
-- whether a given mode toggle button is active or not. 
Module.IsModeEnabled = function(self, modeName)
	if (modeName == "bindMode") then 
		return self:IsBindModeEnabled()
	end
end

-- Callback needed by the menu system 
-- to switch between modes. 
Module.OnModeToggle = function(self, modeName)
	if (modeName == "bindMode") then 
		if (self:IsBindModeEnabled()) then 
			self:DisableBindMode()
		else
			self:EnableBindMode() 
		end
	end 
end

-- Module Event & Chat Command Handling
----------------------------------------------------
Module.OnChatCommand = function(self, editBox, ...)
	if (self:GetBindingFrame():IsShown()) then 
		self:CancelBindings()
	else 
		self:EnableBindMode()
	end
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		if self.bindActive then 
			self:Print(1, 0, 0, L["Keybind changes were discarded because you entered combat."])
			return self:CancelBindings()
		end	
	elseif (event == "UPDATE_BINDINGS") or (event == "PLAYER_ENTERING_WORLD") then 
		-- Binds aren't fully loaded directly after login, 
		-- so we need to track the event for updated bindings as well.
		self:UpdateBindings()
	elseif (event == "CG_UPDATE_ACTIONBUTTON_COUNT") then 
		self:UpdateButtons()
	end
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[Bindings]")
end

Module.OnInit = function(self)
	self:RegisterChatCommand("bind", "OnChatCommand") 

	local ActionBarMain = Core:GetModule("ActionBarMain", true)
	if ActionBarMain then 
		for id,button in ActionBarMain:GetButtons() do 
			self:RegisterButton(button)
		end
	end 
end 

Module.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterMessage("CG_UPDATE_ACTIONBUTTON_COUNT", "OnEvent")
end
