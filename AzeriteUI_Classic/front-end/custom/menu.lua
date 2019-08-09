--[[--

*Note that this file is currently in a slow transition
towards becoming a cleaner generic library, so we advice 
against manually manipulating it as it'll change frequently.
-Lars

--]]--

local ADDON, Private = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("OptionsMenu", "HIGH", "LibMessage", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip")
Module:SetToRetail()

local Layout, L, MenuTable

-- Registries
Module.buttons = Module.buttons or {}
Module.menus = Module.menus or {}
Module.toggles = Module.toggles or {}
Module.siblings =  Module.siblings or {}
Module.windows = Module.windows or {}

-- Shortcuts
local Buttons = Module.buttons
local Menus = Module.menus
local Toggles = Module.toggles
local Siblings = Module.siblings
local Windows = Module.windows

-- Lua API
local _G = _G
local math_min = math.min
local table_insert = table.insert

-- Secure script snippets
local secureSnippets = {
	menuToggle = [=[
		local window = self:GetFrameRef("OptionsMenu");
		if window:IsShown() then
			window:Hide();
		else
			local window2 = self:GetFrameRef("MicroMenu"); 
			if (window2 and window2:IsShown()) then 
				window2:Hide(); 
			end 
			window:Show();
			window:RegisterAutoHide(.75);
			window:AddToAutoHide(self);
			local autohideCounter = 1
			local autohideFrame = window:GetFrameRef("autohide"..autohideCounter);
			while autohideFrame do 
				window:AddToAutoHide(autohideFrame);
				autohideCounter = autohideCounter + 1;
				autohideFrame = window:GetFrameRef("autohide"..autohideCounter);
			end 
		end
	]=],
	bagToggle = [=[ 
		self:CallMethod("ToggleAllBags"); 
	]=],
	windowToggle = [=[
		local window = self:GetFrameRef("Window"); 
		if window:IsShown() then 
			window:Hide(); 
			window:CallMethod("OnHide");
		else 
			window:Show(); 
			window:CallMethod("OnShow");
			local counter = 1
			local sibling = window:GetFrameRef("Sibling"..counter);
			while sibling do 
				if sibling:IsShown() then 
					sibling:Hide(); 
					sibling:CallMethod("OnHide");
				end 
				counter = counter + 1;
				sibling = window:GetFrameRef("Sibling"..counter);
			end 
		end 
	]=],
	buttonClick = [=[
		local updateType = self:GetAttribute("updateType"); 
		if (updateType == "SET_VALUE") then 

			-- Figure out the window's attribute name for this button's attached setting
			local optionDB = self:GetAttribute("optionDB"); 
			local optionName = self:GetAttribute("optionName"); 
			local attributeName = "DB_"..optionDB.."_"..optionName; 

			-- retrieve the new value of the setting
			local window = self:GetFrameRef("Window"); 
			local value = self:GetAttribute("optionArg1"); 

			-- store the new setting on the button
			self:SetAttribute("optionValue", value); 

			-- store the new setting on the window
			window:SetAttribute(attributeName, value); 

			-- Feed the new values into the lua db
			self:CallMethod("FeedToDB"); 

			-- Fire a secure settings update on whatever this setting is attached to
			local proxyUpdater = self:GetFrameRef("proxyUpdater"); 
			if proxyUpdater then 
				proxyUpdater:SetAttribute("change-"..optionName, value); 
			end 

			-- Fire lua post updates to menu buttons
			self:CallMethod("Update"); 

			-- Fire lua post updates to siblings, if any, 
			-- as this could be a multi-option.			
			local counter = 1
			local sibling = self:GetFrameRef("Sibling"..counter);
			while sibling do 
				--if sibling:IsShown() then 
					sibling:CallMethod("Update");
				--end 
				counter = counter + 1;
				sibling = self:GetFrameRef("Sibling"..counter);
			end 


		elseif (updateType == "GET_VALUE") then 

		elseif (updateType == "TOGGLE_VALUE") then 
			-- Figure out the window's attribute name for this button's attached setting
			local optionDB = self:GetAttribute("optionDB"); 
			local optionName = self:GetAttribute("optionName"); 
			local attributeName = "DB_"..optionDB.."_"..optionName; 

			-- retrieve the old value of the setting
			local window = self:GetFrameRef("Window"); 
			local value = not window:GetAttribute(attributeName); 

			-- store the new setting on the button
			self:SetAttribute("optionValue", not self:GetAttribute("optionValue")); 

			-- store the new setting on the window
			window:SetAttribute(attributeName, value); 

			-- Feed the new values into the lua db
			self:CallMethod("FeedToDB"); 

			-- Fire a secure settings update on whatever this setting is attached to
			local proxyUpdater = self:GetFrameRef("proxyUpdater"); 
			if proxyUpdater then 
				proxyUpdater:SetAttribute("change-"..optionName, self:GetAttribute("optionValue")); 
			end 

			-- Fire lua post updates to menu buttons
			self:CallMethod("Update"); 

			do 
				return 
			end

			-- Enable/Disable other menu buttons as needed 
			-- 8.2.0: This bugs out now. 
			--for i=1,select("#", window:GetChildren()) do 

			local numChildren = window:GetNumChildren()
			for i = 1,numChildren do 

				-- Find the child menu buttons that have a slave setting
				local child = select(i, window:GetChildren()); 
				if (child and child:GetAttribute("isSlave")) then 

					-- figure out the window attribute name for the current menu button's attached setting
					local childAttributeName = "DB_"..child:GetAttribute("slaveDB").."_"..child:GetAttribute("slaveKey"); 

					-- if the menu button is slave to the window's attribute, enable/disable the menu button as needed
					if (childAttributeName == attributeName) then 
						if value then 
							child:Enable(); 
						else 
							child:Disable(); 

							-- Hide any open menu windows belonging to this child button.
							-- This also fires a callback to update the button texture.
							local window = child:GetFrameRef("Window");
							if window and window:IsShown() then
								window:Hide(); 
								window:CallMethod("OnHide");
							end 
						end
					end
				end 
			end 

		elseif (updateType == "TOGGLE_MODE") then 

			-- Bypass all secure menthods and run it in pure lua
			self:CallMethod("ToggleMode"); 

			-- Fire lua post updates to menu buttons
			self:CallMethod("Update"); 
		end 
	]=]
}

-- Menu Template
local Menu = {}
local Menu_MT = { __index = Menu }

-- Toggle Button template
local Toggle = Module:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
local Toggle_MT = { __index = Toggle }

-- Container template
local Window = Module:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
local Window_MT = { __index = Window }

-- Entry template
local Button = Module:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
local Button_MT = { __index = Button }

local MenuWindow_OnShow = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetToggleButton()
	if (tooltip:IsShown() and (tooltip:GetOwner() == button)) then 
		tooltip:Hide()
	end 
end

local MenuWindow_OnHide = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local toggle = Module:GetToggleButton()
	if (toggle:IsMouseOver(0,0,0,0) and ((not tooltip:IsShown()) or (tooltip:GetOwner() ~= toggle))) then 
		toggle:OnEnter()
	end 
end

Toggle.OnEnter = function(self)
	if (not self.leftButtonTooltip) and (not self.rightButtonTooltip) then 
		return 
	end 
	local tooltip = Module:GetOptionsMenuTooltip()
	local window = Module:GetConfigWindow()
	if window:IsShown() then 
		if (tooltip:IsShown() and (tooltip:GetOwner() == self)) then 
			tooltip:Hide()
		end 
		return 
	end 
	local Colors = Layout.Colors
	tooltip:SetDefaultAnchor(self)
	tooltip:AddLine(L["Main Menu"], Colors.title[1], Colors.title[2], Colors.title[3])
	tooltip:AddLine(L["Click here to get access to game panels."], Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
	if self.leftButtonTooltip then 
		tooltip:AddLine(self.leftButtonTooltip, Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3], true)
	end 
	if self.rightButtonTooltip then 
		tooltip:AddLine(self.rightButtonTooltip, Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3], true)
	end 
	if self.middleButtonTooltip then 
		tooltip:AddLine(self.middleButtonTooltip, Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3], true)
	end 
	tooltip:Show()
end

Toggle.OnLeave = function(self)
	local tooltip = Module:GetOptionsMenuTooltip()
	tooltip:Hide() 
end

do
	local buttonCount = 0
	Window.AddButton = function(self, text, updateType, optionDB, optionName, ...)
		buttonCount = buttonCount + 1
		-- print(buttonCount); 34
		local option = setmetatable(self:CreateFrame("CheckButton", ADDON.."_ConfigMenu_OptionsButton"..buttonCount, "SecureHandlerClickTemplate"), Button_MT)
		option:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod)
		option:ClearAllPoints()
		option:SetPoint("BOTTOMRIGHT", -Layout.MenuButtonSpacing, Layout.MenuButtonSpacing + (Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod + Layout.MenuButtonSpacing)*(self.numButtons))

		option:HookScript("OnEnable", Button.OnEnable)
		option:HookScript("OnDisable", Button.OnDisable)
		option:HookScript("OnShow", Button.OnShow)
		option:HookScript("OnHide", Button.OnHide)
		option:HookScript("OnMouseDown", Button.OnMouseDown)
		option:HookScript("OnMouseUp", Button.OnMouseUp)
		option:HookScript("OnEnter", Button.Update)
		option:HookScript("OnLeave", Button.Update)

		option:SetAttribute("updateType", updateType)
		option:SetAttribute("optionDB", optionDB)
		option:SetAttribute("optionName", optionName)

		option:SetFrameRef("Window", self)

		for i = 1, select("#", ...) do 
			local value = select(i, ...)
			option:SetAttribute("optionArg"..i, value)
			option["optionArg"..i] = value
		end 

		option.updateType = updateType
		option.optionDB = optionDB
		option.optionName = optionName

		if (updateType == "SET_VALUE") or (updateType == "GET_VALUE") or (updateType == "TOGGLE_VALUE") or (updateType == "TOGGLE_MODE") then 
			option:SetAttribute("_onclick", secureSnippets.buttonClick)
		end

		if (not Module.optionCallbacks) then 
			Module.optionCallbacks = {}
		end 

		Module.optionCallbacks[option] = self

		if Layout.MenuButton_PostCreate then 
			Layout.MenuButton_PostCreate(option, text, updateType, optionDB, optionName, ...)
		end

		self.numButtons = self.numButtons + 1
		self.buttons[self.numButtons] = option

		self:PostUpdateSize()
		self:UpdateSiblings()

		return option
	end 
end

Window.ParseOptionsTable = function(self, tbl, parentLevel)
	local level = (parentLevel or 1) + 1
	for id,data in ipairs(tbl) do
		local button = self:AddButton(data.title, data.type, data.configDB, data.configKey, data.optionArgs and unpack(data.optionArgs))
		button.enabledTitle = data.enabledTitle
		button.disabledTitle = data.disabledTitle
		button.proxyModule = data.proxyModule
		button.useCore = data.useCore
		button.modeName = data.modeName
		button.hasWindow = data.hasWindow
		if data.isSlave then 
			button:SetAsSlave(data.slaveDB, data.slaveKey)
		end 
		if data.hasWindow then 
			local window = button:CreateWindow(level)
			if data.buttons then 
				window:ParseOptionsTable(data.buttons)
			end 
		end
	end
end

Window.UpdateSiblings = function(self)
	for id,button in ipairs(self.buttons) do 
		local siblingCount = 0
		for i = 1, self.numButtons do 
			if (i ~= id) then 
				siblingCount = siblingCount + 1
				button:SetFrameRef("Sibling"..siblingCount, self.buttons[i])
			end 
		end 
	end
	if self.windows then 
		for id,button in ipairs(self.windows) do 
			local siblingCount = 0
			for i = 1, self.numWindows do 
				if (i ~= id) then 
					siblingCount = siblingCount + 1
					button:SetFrameRef("Sibling"..siblingCount, self.windows[i])
				end 
			end 
		end
	end 
end

Window.OnHide = function(self)
	self:GetParent().windowIsShown = nil
	if Layout.MenuWindow_OnHide then 
		return Layout.MenuWindow_OnHide(self)
	end 
end

Window.OnShow = function(self)
	self:GetParent().windowIsShown = true
	if Layout.MenuWindow_OnShow then 
		return Layout.MenuWindow_OnShow(self)
	end 
end

Window.PostUpdateSize = function(self)
	local numButtons = self.numButtons
	self:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod + Layout.MenuButtonSpacing*2, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod*numButtons + Layout.MenuButtonSpacing*(numButtons+1))
end

Button.OnEnable = function(self)
	self:SetAlpha(1)
	self:Update()
end 

Button.OnDisable = function(self)
	self:SetAlpha(.5)
	self:Update()
end 

Button.OnShow = function(self)
	self.isDown = false
	self:Update()
end 

Button.OnHide = function(self)
	self.isDown = false
	self:Update()
end 

Button.OnMouseDown = function(self)
	self.isDown = true
	self:Update()
end 

Button.OnMouseUp = function(self)
	self.isDown = false
	self:Update()
end 

Button.ToggleMode = function(self)
	local Module = self.proxyModule and Core:GetModule(self.proxyModule, true) or self.useCore and Core
	if Module and Module.OnModeToggle then 
		Module:OnModeToggle(self.modeName)
		self:Update()
	end
end

Button.Update = function(self)
	if Layout.MenuButton_PostUpdate then 
		if (self.updateType == "GET_VALUE") then 
			return Layout.MenuButton_PostUpdate(self)

		elseif (self.updateType == "SET_VALUE") then 
			local db = Module:GetConfig(self.optionDB, defaults, "global")
			local option = db[self.optionName]
			return Layout.MenuButton_PostUpdate(self, self.updateType, db, option, option == self.optionArg1)

		elseif (self.updateType == "TOGGLE_VALUE") then 
			local db = Module:GetConfig(self.optionDB, defaults, "global")
			local option = db[self.optionName]
			return Layout.MenuButton_PostUpdate(self, self.updateType, db, option)

		elseif (self.updateType == "TOGGLE_MODE") then
			local Module = self.proxyModule and Core:GetModule(self.proxyModule, true) or self.useCore and Core
			if Module then 
				return Layout.MenuButton_PostUpdate(self, self.updateType, nil, Module:IsModeEnabled(self.modeName))
			end 
		else
			return Layout.MenuButton_PostUpdate(self)
		end 
	end 
end

Button.FeedToDB = function(self)
	if (self.updateType == "SET_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")

	elseif (self.updateType == "TOGGLE_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")
	end 
end 

Button.CreateWindow = function(self, level)
	local window = Module:CreateConfigWindowLevel(level, self)
	--window:SetPoint("BOTTOM", Module:GetConfigWindow(), "BOTTOM", 0, 0) -- relative to parent button's window
	window:ClearAllPoints()
	window:SetPoint("BOTTOM", self, "BOTTOM", 0, -Layout.MenuButtonSpacing) -- relative to parent button
	window:SetPoint("RIGHT", self, "LEFT", -Layout.MenuButtonSpacing*2, 0)

	if Layout.MenuWindow_CreateBorder then 
		window.Border = Layout.MenuWindow_CreateBorder(window)
	end 

	window.OnHide = Window.OnHide
	window.OnShow = Window.OnShow

	self:SetAttribute("_onclick", secureSnippets.windowToggle)
	self:SetFrameRef("Window", window)

	Module:AddFrameToAutoHide(window)

	local owner = self:GetParent()
	if (not owner.windows) then 
		owner.numWindows = 0
		owner.windows = {}
	end 

	owner.numWindows = owner.numWindows + 1
	owner.windows[owner.numWindows] = window
	owner:UpdateSiblings()
	
	return window
end

Button.SetAsSlave = function(self, slaveDB, slaveKey)
	self.slaveDB = slaveDB
	self.slaveKey = slaveKey
	self.isSlave = true
	self:SetAttribute("slaveDB", slaveDB)
	self:SetAttribute("slaveKey", slaveKey)
	self:SetAttribute("isSlave", true)
end

Module.CreateConfigWindowLevel = function(self, level, parent)
	local frameLevel = 10 + (level-1)*5
	local name = level == 1 and ADDON.."_ConfigMenu"
	local window = setmetatable(self:CreateFrame("Frame", name, parent or "UICenter", "SecureHandlerAttributeTemplate"), Window_MT)
	window:Hide()
	window:EnableMouse(true)
	window:SetFrameStrata("DIALOG")
	window:SetFrameLevel(frameLevel)

	window.numButtons = 0
	window.buttons = {}

	if (level > 1) then 
		self:AddFrameToAutoHide(window)
	end 

	return window, name
end

Module.GetOptionsMenuTooltip = function(self)
	return self:GetTooltip(ADDON.."_OptionsMenuTooltip") or self:CreateTooltip(ADDON.."_OptionsMenuTooltip")
end

Module.GetToggleButton = function(self)
	if (not self.ToggleButton) then 
		local toggleButton = setmetatable(self:CreateFrame("CheckButton", ADDON.."_ConfigMenu_ToggleButton", "UICenter", "SecureHandlerClickTemplate"), Toggle_MT)
		toggleButton:SetFrameStrata("DIALOG")
		toggleButton:SetFrameLevel(50)
		toggleButton:SetSize(unpack(Layout.MenuToggleButtonSize))
		toggleButton:Place(unpack(Layout.MenuToggleButtonPlace))
		toggleButton:RegisterForClicks("AnyUp")
		toggleButton:SetScript("OnEnter", Toggle.OnEnter)
		toggleButton:SetScript("OnLeave", Toggle.OnLeave) 
		toggleButton:SetAttribute("_onclick", [[
			if (button == "LeftButton") then
				local leftclick = self:GetAttribute("leftclick");
				if leftclick then
					self:RunAttribute("leftclick", button);
				end
			elseif (button == "RightButton") then 
				-- 8.2.0: this isn't working as of now. 
				local rightclick = self:GetAttribute("rightclick");
				if rightclick then
					self:RunAttribute("rightclick", button);
				end
			elseif (button == "MiddleButton") then
				local middleclick = self:GetAttribute("middleclick");
				if middleclick then
					self:RunAttribute("middleclick", button);
				end
			end
		]])

		toggleButton.Icon = toggleButton:CreateTexture()
		toggleButton.Icon:SetTexture(Layout.MenuToggleButtonIcon)
		toggleButton.Icon:SetSize(unpack(Layout.MenuToggleButtonIconSize))
		toggleButton.Icon:ClearAllPoints()
		toggleButton.Icon:SetPoint(unpack(Layout.MenuToggleButtonIconPlace))
		toggleButton.Icon:SetVertexColor(unpack(Layout.MenuToggleButtonIconColor))

		self.ToggleButton = toggleButton
	end 
	return self.ToggleButton
end

Module.GetConfigWindow = function(self)
	if (not self.ConfigWindow) then 

		-- create main window 
		local window = self:CreateConfigWindowLevel(1)
		window:Place(unpack(Layout.MenuPlace))
		window:SetSize(unpack(Layout.MenuSize))
		window:EnableMouse(true)
		window:SetScript("OnShow", MenuWindow_OnShow)
		window:SetScript("OnHide", MenuWindow_OnHide)

		if Layout.MenuWindow_CreateBorder then 
			window.Border = Layout.MenuWindow_CreateBorder(window)
		end 

		self.ConfigWindow = window
	end 
	return self.ConfigWindow
end

Module.GetAutoHideReferences = function(self)
	if (not self.AutoHideReferences) then 
		self.AutoHideReferences = {}
	end 
	return self.AutoHideReferences
end

Module.AddFrameToAutoHide = function(self, frame)
	local window = self:GetConfigWindow()
	local hiders = self:GetAutoHideReferences()

	local id = 1 -- targeted id for this autohider
	for frameRef,parent in pairs(hiders) do 
		id = id + 1 -- increase id by 1 for every other frame found
	end 

	-- create a new autohide frame
	local autohideParent = CreateFrame("Frame", nil, window, "SecureHandlerStateTemplate")
	autohideParent:ClearAllPoints()
	autohideParent:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6)
	autohideParent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)

	-- Add it to our registry
	hiders["autohide"..id] = autohideParent
end

Module.AddOptionsToMenuButton = function(self)
	if (not self.addedToMenuButton) then 
		self.addedToMenuButton = true

		local menuWindow = self:GetConfigWindow()
		local toggleButton = self:GetToggleButton()
		toggleButton:SetFrameRef("OptionsMenu", menuWindow)
		toggleButton:SetAttribute("rightclick", secureSnippets.menuToggle)
		toggleButton:SetAttribute("middleclick", secureSnippets.bagToggle)
		toggleButton.ToggleAllBags = function(self)
			ToggleAllBags()
		end
		for reference,frame in pairs(self:GetAutoHideReferences()) do 
			menuWindow:SetFrameRef(reference,frame)
		end 
		toggleButton.middleButtonTooltip = L["%s to toggle your Bags."]:format(L["<Middle-Click>"])
		toggleButton.rightButtonTooltip = L["%s to toggle Options Menu."]:format(L["<Right-Click>"])
	end
end 

Module.AddOptionsToMenuWindow = function(self)
	if (self.addedToMenuWindow) then 
		return 
	end 
	self:GetConfigWindow():ParseOptionsTable(MenuTable, 1)
	self.addedToMenuWindow = true
end

Module.PostUpdateOptions = function(self, event, ...)
	if (event) then 
		self:UnregisterEvent(event, "PostUpdateOptions")
	end
	if self.optionCallbacks then 
		for option,window in pairs(self.optionCallbacks) do 
			if (option.updateType == "SET_VALUE") then
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				if option.proxyModule then 
					option:SetFrameRef("proxyUpdater", Core:GetModule(option.proxyModule):GetSecureUpdater())
				elseif option.useCore then 
					option:SetFrameRef("proxyUpdater", Core:GetSecureUpdater())
				end 

				option:SetAttribute("optionValue", value)
				option:Update()

			elseif (option.updateType == "TOGGLE_VALUE") then
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				if option.proxyModule then 
					option:SetFrameRef("proxyUpdater", Core:GetModule(option.proxyModule):GetSecureUpdater())
				elseif option.useCore then 
					option:SetFrameRef("proxyUpdater", Core:GetSecureUpdater())
				end 

				option:SetAttribute("optionValue", value)
				option:Update()
			elseif (option.updateType == "TOGGLE_MODE") then
				local proxyUpdater
				if option.proxyModule then 
					local Module = Core:GetModule(option.proxyModule)
					if Module and Module.GetSecureUpdater then 
						proxyUpdater = Core:GetModule(option.proxyModule):GetSecureUpdater()
					else 
					end 
				elseif option.useCore then 
					proxyUpdater = Core:GetSecureUpdater()
				end 
				if proxyUpdater then 
					option:SetFrameRef("proxyUpdater", proxyUpdater)
				end
			end 
			if (option.isSlave) then 
				local attributeName = "DB_"..option.slaveDB.."_"..option.slaveKey
				local db = self:GetConfig(option.slaveDB, defaults, "global")
				local value = db[option.slaveKey]

				window:SetAttribute(attributeName, value)

				if (value) then 
					option:Enable()
				else
					option:Disable()
				end 

				option:Update()
			end 
		end 
	end 
end 

Module.CreateMenuTable = function(self)
	MenuTable = {}

	-- Let's color enabled/disabled entries entirely, 
	-- instead of making them longer by adding the text.
	local L_ENABLED = "|cff007700%s|r"
	local L_DISABLED = "|cffaa0000%s|r"

	-- Debug Mode
	local DebugMenu = {
		title = L["Debug Mode"], type = nil, hasWindow = true, 
		buttons = {}
	}
	if self:GetOwner():IsDebugModeEnabled() then 
		table_insert(DebugMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Debug Console"]),
			disabledTitle = L_DISABLED:format(L["Debug Console"]),
			--type = "TOGGLE_VALUE", 
			--configDB = "Core", configKey = "enableDebugConsole", 
			--proxyModule = nil, useCore = true
			type = "TOGGLE_MODE", hasWindow = false, 
			configDB = "Core", modeName = "enableDebugConsole", 
			proxyModule = nil, useCore = true
		})
		table_insert(DebugMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Unload Console"]),
			disabledTitle = L_DISABLED:format(L["Unload Console"]),
			type = "TOGGLE_MODE", hasWindow = false, 
			configDB = "Core", modeName = "unloadConsole", 
			proxyModule = nil, useCore = true
		})
	else
		table_insert(DebugMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Load Console"]),
			disabledTitle = L_DISABLED:format(L["Load Console"]),
			type = "TOGGLE_MODE", hasWindow = false, 
			configDB = "Core", modeName = "loadConsole", 
			proxyModule = nil, useCore = true
		})
	end
	table_insert(DebugMenu.buttons, {
		enabledTitle = L_ENABLED:format(L["Reload UI"]),
		disabledTitle = L_DISABLED:format(L["Reload UI"]),
		type = "TOGGLE_MODE", hasWindow = false, 
		configDB = "Core", modeName = "reloadUI", 
		proxyModule = nil, useCore = true
	})
	table_insert(MenuTable, DebugMenu)
	
	-- Actionbars 
	local ActionBarMain = Core:GetModule("ActionBarMain", true)
	if ActionBarMain and not (ActionBarMain:IsIncompatible() or ActionBarMain:DependencyFailed()) then 
		local ActionBarMenu =  {
			title = L["ActionBars"], type = nil, hasWindow = true, 
			buttons = {
				{
					title = L["More Buttons"], type = nil, hasWindow = true, 
					buttons = {
						{
							title = L["No Extra Buttons"], type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsCount", optionArgs = { 0 }, 
							proxyModule = "ActionBarMain"
						},
						{
							title = L["+%.0f Buttons"]:format(5), type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsCount", optionArgs = { 5 }, 
							proxyModule = "ActionBarMain"
						},
						{
							title = L["+%.0f Buttons"]:format(11), type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsCount", optionArgs = { 11 }, 
							proxyModule = "ActionBarMain"
						},
						{
							title = L["+%.0f Buttons"]:format(17), type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsCount", optionArgs = { 17 }, 
							proxyModule = "ActionBarMain"
						}
					}
				}, 
				{
					title = L["Extra Buttons Visibility"], type = nil, hasWindow = true, 
					buttons = {
						{
							title = L["MouseOver"], 
							type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsVisibility", optionArgs = { "hover" }, 
							proxyModule = "ActionBarMain"
						},
						{
							title = L["MouseOver + Combat"], 
							type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsVisibility", optionArgs = { "combat" }, 
							proxyModule = "ActionBarMain"
						},
						{
							title = L["Always Visible"], 
							type = "SET_VALUE", 
							configDB = "ActionBars", configKey = "extraButtonsVisibility", optionArgs = { "always" }, 
							proxyModule = "ActionBarMain"
						}
					}
				},
				{
					enabledTitle = L_ENABLED:format(L["Cast on Down"]),
					disabledTitle = L_DISABLED:format(L["Cast on Down"]),
					type = "TOGGLE_VALUE", hasWindow = false, 
					configDB = "ActionBars", configKey = "castOnDown", 
					proxyModule = "ActionBarMain"
				}
			}
		}
		local Bindings = Core:GetModule("Bindings", true)
		if Bindings and not (Bindings:IsIncompatible() or Bindings:DependencyFailed()) then 
			if Bindings then 
				table_insert(ActionBarMenu.buttons, {
					enabledTitle = L_ENABLED:format(L["Bind Mode"]),
					disabledTitle = L_DISABLED:format(L["Bind Mode"]),
					type = "TOGGLE_MODE", hasWindow = false, 
					proxyModule = "Bindings", modeName = "bindMode"
				})
			end 
		end 
		table_insert(ActionBarMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Button Lock"]),
			disabledTitle = L_DISABLED:format(L["Button Lock"]),
			type = "TOGGLE_VALUE", hasWindow = false, 
			configDB = "ActionBars", configKey = "buttonLock", 
			proxyModule = "ActionBarMain"
		})
		table_insert(MenuTable, ActionBarMenu)
	end

	-- Unitframes
	local UnitFrameMenu = {
		title = L["UnitFrames"], type = nil, hasWindow = true, 
		buttons = {
			-- Player options
		}
	}

	local UnitFrameParty = Core:GetModule("UnitFrameParty", true)
	if UnitFrameParty and not (UnitFrameParty:IsIncompatible() or UnitFrameParty:DependencyFailed()) then 
		table_insert(UnitFrameMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Party Frames"]),
			disabledTitle = L_DISABLED:format(L["Party Frames"]),
			type = "TOGGLE_VALUE", 
			configDB = "UnitFrameParty", configKey = "enablePartyFrames", 
			proxyModule = "UnitFrameParty"
		})
	end

	local UnitFrameRaid = Core:GetModule("UnitFrameRaid", true)
	if UnitFrameRaid and not (UnitFrameRaid:IsIncompatible() or UnitFrameRaid:DependencyFailed()) then 
		table_insert(UnitFrameMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["Raid Frames"]),
			disabledTitle = L_DISABLED:format(L["Raid Frames"]),
			type = "TOGGLE_VALUE", 
			configDB = "UnitFrameRaid", configKey = "enableRaidFrames", 
			proxyModule = "UnitFrameRaid"
		})
	end

	local UnitFrameArena = Core:GetModule("UnitFrameArena", true)
	if UnitFrameArena and not (UnitFrameArena:IsIncompatible() or UnitFrameArena:DependencyFailed()) then 
		table_insert(UnitFrameMenu.buttons, {
			enabledTitle = L_ENABLED:format(L["PvP Frames"]),
			disabledTitle = L_DISABLED:format(L["PvP Frames"]),
			type = "TOGGLE_VALUE", 
			configDB = "UnitFrameArena", configKey = "enableArenaFrames", 
			proxyModule = "UnitFrameArena"
		})
	end
	table_insert(MenuTable, UnitFrameMenu)
		

	-- Nameplates
	local NamePlates = Core:GetModule("NamePlates", true)
	if NamePlates and not (NamePlates:IsIncompatible() or NamePlates:DependencyFailed()) then 
		table_insert(MenuTable, {
			title = L["NamePlates"], type = nil, hasWindow = true, 
			buttons = {
				-- Disable player auras
				{
					enabledTitle = L_ENABLED:format(L["Auras"]),
					disabledTitle = L_DISABLED:format(L["Auras"]),
					type = "TOGGLE_VALUE", 
					configDB = "NamePlates", configKey = "enableAuras", 
					proxyModule = "NamePlates"
				},
				-- Click-through settings
				{
					title = MAKE_UNINTERACTABLE, type = nil, hasWindow = true, 
					buttons = {
						{
							enabledTitle = L_ENABLED:format(L["Player"]),
							disabledTitle = L_DISABLED:format(L["Player"]),
							type = "TOGGLE_VALUE", 
							configDB = "NamePlates", configKey = "clickThroughSelf", 
							proxyModule = "NamePlates"
						},
						{
							enabledTitle = L_ENABLED:format(L["Enemies"]),
							disabledTitle = L_DISABLED:format(L["Enemies"]),
							type = "TOGGLE_VALUE", 
							configDB = "NamePlates", configKey = "clickThroughEnemies", 
							proxyModule = "NamePlates"
						},
						{
							enabledTitle = L_ENABLED:format(L["Friends"]),
							disabledTitle = L_DISABLED:format(L["Friends"]),
							type = "TOGGLE_VALUE", 
							configDB = "NamePlates", configKey = "clickThroughFriends", 
							proxyModule = "NamePlates"
						}
					}
				}
			}
		})
	end 

	-- Blizzard HUD elements
	table_insert(MenuTable,	{
		title = L["HUD"], type = nil, hasWindow = true, 
		buttons = {
			-- Talking Head
			{
				enabledTitle = L_ENABLED:format(L["TalkingHead"]),
				disabledTitle = L_DISABLED:format(L["TalkingHead"]),
				type = "TOGGLE_VALUE", 
				configDB = "FloaterHUD", configKey = "enableTalkingHead", 
				proxyModule = "BlizzardFloaterHUD"
			},

			-- Alerts 
			{
				enabledTitle = L_ENABLED:format(L["Alerts"]),
				disabledTitle = L_DISABLED:format(L["Alerts"]),
				type = "TOGGLE_VALUE", 
				configDB = "FloaterHUD", configKey = "enableAlerts", 
				proxyModule = "BlizzardFloaterHUD"
			}

			
		}
	})
	
	-- Explorer Mode
	local ExplorerMode = Core:GetModule("ExplorerMode", true)
	if ExplorerMode and not (ExplorerMode:IsIncompatible() or ExplorerMode:DependencyFailed()) then 
		table_insert(MenuTable, {
			title = L["Explorer Mode"], type = nil, hasWindow = true, 
			buttons = {
				-- Enable explorer mode
				{
					enabledTitle = L_ENABLED:format(L["Player Fading"]),
					disabledTitle = L_DISABLED:format(L["Player Fading"]),
					type = "TOGGLE_VALUE", 
					configDB = "ExplorerMode", configKey = "enableExplorer", 
					proxyModule = "ExplorerMode"
				},
				{
					enabledTitle = L_ENABLED:format(L["Tracker Fading"]),
					disabledTitle = L_DISABLED:format(L["Tracker Fading"]),
					type = "TOGGLE_VALUE", 
					configDB = "ExplorerMode", configKey = "enableTrackerFading", 
					proxyModule = "ExplorerMode"
				}		
			}
		})
	end 

	-- Healer Mode
	table_insert(MenuTable, {
		enabledTitle = L_ENABLED:format(L["Healer Mode"]),
		disabledTitle = L_DISABLED:format(L["Healer Mode"]),
		type = "TOGGLE_VALUE", 
		configDB = "Core", configKey = "enableHealerMode", 
		proxyModule = nil, useCore = true, modeName = "healerMode"
	})

end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[Core]")
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
end

Module.OnInit = function(self)
	self:CreateMenuTable() -- can we do it here?
	self:AddOptionsToMenuWindow()
end 

Module.OnEnable = function(self)
	self:AddOptionsToMenuButton()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "PostUpdateOptions")
end 
