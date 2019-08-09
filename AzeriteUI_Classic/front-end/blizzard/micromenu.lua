local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardMicroMenu", "LibEvent", "LibDB", "LibTooltip", "LibFrame")
Module:SetToRetail()

-- Lua API
local _G = _G
local ipairs = ipairs
local math_floor = math.floor
local pairs = pairs
local string_format = string.format

-- WoW API
local GetAvailableBandwidth = _G.GetAvailableBandwidth
local GetBindingKey = _G.GetBindingKey
local GetBindingText = _G.GetBindingText
local GetCVarBool = _G.GetCVarBool
local GetDownloadedPercentage = _G.GetDownloadedPercentage
local GetFramerate = _G.GetFramerate
local GetMovieDownloadProgress = _G.GetMovieDownloadProgress
local GetNetStats = _G.GetNetStats

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300,50,10, .75

local L, Layout, CoreLayout

local getBindingKeyForAction = function(action, useNotBound, useParentheses)
	local key = GetBindingKey(action)
	if key then
		key = GetBindingText(key)
	elseif useNotBound then
		key = NOT_BOUND
	end

	if key and useParentheses then
		return ("(%s)"):format(key)
	end

	return key
end

local formatBindingKeyIntoText = function(text, action, bindingAvailableFormat, keyStringFormat, useNotBound, useParentheses)
	local bindingKey = getBindingKeyForAction(action, useNotBound, useParentheses)

	if bindingKey then
		bindingAvailableFormat = bindingAvailableFormat or "%s %s"
		keyStringFormat = keyStringFormat or "%s"
		local keyString = keyStringFormat:format(bindingKey)
		return bindingAvailableFormat:format(text, keyString)
	end

	return text
end

local getMicroButtonTooltipText = function(text, action)
	return formatBindingKeyIntoText(text, action, "%s %s", NORMAL_FONT_COLOR_CODE.."(%s)"..FONT_COLOR_CODE_CLOSE)
end

local microButtons = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"CollectionsMicroButton",
	"EJMicroButton",
	"StoreMicroButton",
	"MainMenuMicroButton"
}

local microButtonTexts = {
	CharacterMicroButton = CHARACTER_BUTTON,
	SpellbookMicroButton = SPELLBOOK_ABILITIES_BUTTON,
	TalentMicroButton = TALENTS_BUTTON,
	AchievementMicroButton = ACHIEVEMENT_BUTTON,
	QuestLogMicroButton = QUESTLOG_BUTTON,
	GuildMicroButton = LOOKINGFORGUILD,
	LFDMicroButton = DUNGEONS_BUTTON,
	CollectionsMicroButton = COLLECTIONS,
	EJMicroButton = ADVENTURE_JOURNAL or ENCOUNTER_JOURNAL,
	StoreMicroButton = BLIZZARD_STORE,
	MainMenuMicroButton = MAINMENU_BUTTON	
}

local microButtonScripts = {

	CharacterMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0")
		local titleColor, normalColor = Layout.MenuButtonTitleColor, Layout.MenuButtonNormalColor
		local tooltip = Module:GetOptionsMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, titleColor[1], titleColor[2], titleColor[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_CHARACTER, normalColor[1], normalColor[2], normalColor[3], true)
		tooltip:Show()
	end,
	
	SpellbookMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK")
		local titleColor, normalColor = Layout.MenuButtonTitleColor, Layout.MenuButtonNormalColor
		local tooltip = Module:GetOptionsMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, titleColor[1], titleColor[2], titleColor[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_SPELLBOOK, normalColor[1], normalColor[2], normalColor[3], true)
		tooltip:Show()
	end,
	
	CollectionsMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(COLLECTIONS, "TOGGLECOLLECTIONS")
		local titleColor, normalColor = Layout.MenuButtonTitleColor, Layout.MenuButtonNormalColor
		local tooltip = Module:GetOptionsMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, titleColor[1], titleColor[2], titleColor[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_MOUNTS_AND_PETS, normalColor[1], normalColor[2], normalColor[3], true)
		tooltip:Show()
	end,


	MainMenuMicroButton_OnEnter = function(self)
		local titleColor, normalColor = Layout.MenuButtonTitleColor, Layout.MenuButtonNormalColor
		local tooltip = Module:GetOptionsMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, titleColor[1], titleColor[2], titleColor[3], true)
		tooltip:AddLine(self.newbieText, normalColor[1], normalColor[2], normalColor[3], true)
		tooltip:Show()
	end,

	MicroButton_OnEnter = function(self)
		if (self:IsEnabled() or self.minLevel or self.disabledTooltip or self.factionGroup) then
	
			local titleColor, normalColor = Layout.MenuButtonTitleColor, Layout.MenuButtonNormalColor
			local tooltip = Module:GetOptionsMenuTooltip()
			tooltip:Hide()
			tooltip:SetDefaultAnchor(self)

			if self.tooltipText then
				tooltip:AddLine(self.tooltipText, titleColor[1], titleColor[2], titleColor[3], true)
				tooltip:AddLine(self.newbieText, normalColor[1], normalColor[2], normalColor[3], true)
			else
				tooltip:AddLine(self.newbieText, titleColor[1], titleColor[2], titleColor[3], true)
			end
	
			if (not self:IsEnabled()) then
				if (self.factionGroup == "Neutral") then
					tooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, Layout.Colors.quest.red[1], Layout.Colors.quest.red[2], Layout.Colors.quest.red[3], true)
	
				elseif ( self.minLevel ) then
					tooltip:AddLine(string_format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, self.minLevel), Layout.Colors.quest.red[1], Layout.Colors.quest.red[2], Layout.Colors.quest.red[3], true)
	
				elseif ( self.disabledTooltip ) then
					tooltip:AddLine(self.disabledTooltip, Layout.Colors.quest.red[1], Layout.Colors.quest.red[2], Layout.Colors.quest.red[3], true)
				end
			end

			tooltip:Show()
		end
	end, 

	MicroButton_OnLeave = function(button)
		local tooltip = Module:GetOptionsMenuTooltip()
		tooltip:Hide() 
	end
}

local ConfigWindow_OnShow = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetToggleButton()
	if (tooltip:IsShown() and (tooltip:GetOwner() == button)) then 
		tooltip:Hide()
	end 
end

local ConfigWindow_OnHide = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetToggleButton()
	if (button:IsMouseOver(0,0,0,0) and ((not tooltip:IsShown()) or (tooltip:GetOwner() ~= button))) then 
		button:GetScript("OnEnter")(button)
	end 
end

-- Same tooltip as used by the options menu module. 
Module.GetOptionsMenuTooltip = function(self)
	return self:GetTooltip(ADDON.."_OptionsMenuTooltip") or self:CreateTooltip(ADDON.."_OptionsMenuTooltip")
end

-- Avoid direct usage of 'self' here since this 
-- is used as a callback from global methods too! 
Module.UpdateMicroButtons = function()
	if InCombatLockdown() then 
		return Module:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	local buttons = Module:GetConfigButtons()
	local window = Module:GetConfigWindow()

	local numVisible = 0
	for id,microButton in ipairs(buttons) do
		if (microButton and microButton:IsShown()) then
			microButton:SetParent(window) 
			microButton:SetSize(buttonWidth*sizeMod, buttonHeight*sizeMod)
			microButton:ClearAllPoints()
			microButton:SetPoint("BOTTOM", window, "BOTTOM", 0, buttonSpacing + buttonHeight*sizeMod*numVisible + buttonSpacing*numVisible)
			numVisible = numVisible + 1
		end
	end	

	-- Resize window to fit the buttons
	window:SetSize(buttonWidth*sizeMod + buttonSpacing*2, buttonHeight*sizeMod*numVisible + buttonSpacing*(numVisible+1))
end

Module.UpdatePerformanceBar = function(self)
	if MainMenuBarPerformanceBar then 
		MainMenuBarPerformanceBar:SetTexture(nil)
		MainMenuBarPerformanceBar:SetVertexColor(0,0,0,0)
		MainMenuBarPerformanceBar:Hide()
	end 
end

Module.GetConfigWindow = function(self)
	if (not self.ConfigWindow) then 

		local configWindow = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
		configWindow:Hide()
		configWindow:SetFrameStrata("DIALOG")
		configWindow:SetFrameLevel(10)
		configWindow:Place(unpack(CoreLayout.MenuPlace))
		configWindow:EnableMouse(true)
		configWindow:SetScript("OnShow", ConfigWindow_OnShow)
		configWindow:SetScript("OnHide", ConfigWindow_OnHide)

		if Layout.MenuWindow_CreateBorder then 
			Layout.MenuWindow_CreateBorder(configWindow)
		end
		
		self.ConfigWindow = configWindow
	end 
	return self.ConfigWindow
end

Module.GetToggleButton = function(self)
	return Core:GetModule("OptionsMenu"):GetToggleButton()
end

Module.GetConfigButtons = function(self)
	if (not self.ConfigButtons) then 
		self.ConfigButtons = {}
	end 
	return self.ConfigButtons
end

Module.GetAutoHideReferences = function(self)
	if (not self.AutoHideReferences) then 
		self.AutoHideReferences = {}
	end 
	return self.AutoHideReferences
end

Module.AddOptionsToMenuButton = function(self)
	if (not self.addedToMenuButton) then 
		self.addedToMenuButton = true

		local ToggleButton = self:GetToggleButton()
		ToggleButton:SetFrameRef("MicroMenu", self:GetConfigWindow())
		ToggleButton:SetAttribute("leftclick", [[
			local window = self:GetFrameRef("MicroMenu");
			if window:IsShown() then
				window:Hide();
			else
				local window2 = self:GetFrameRef("OptionsMenu"); 
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
		]])
		for reference,frame in pairs(self:GetAutoHideReferences()) do 
			self:GetConfigWindow():SetFrameRef(reference,frame)
		end 
		ToggleButton.leftButtonTooltip = L["%s to toggle Blizzard Menu."]:format(L["<Left-Click>"])
	end 
end 

Module.AddOptionsToMenuWindow = function(self)
	if (not self.addedToMenuWindow) then 
		self.addedToMenuWindow = true

		-- Frame to hide items with
		local UIHider = CreateFrame("Frame")
		UIHider:Hide()

		local buttons = self:GetConfigButtons()
		local window = self:GetConfigWindow()
		local hiders = self:GetAutoHideReferences()

		for id,buttonName in ipairs(microButtons) do 

			local microButton = _G[buttonName]
			if microButton then 

				buttons[#buttons + 1] = microButton

				local normal = microButton:GetNormalTexture()
				if normal then
					microButton:SetNormalTexture("")
					normal:SetAlpha(0)
					normal:SetSize(.0001, .0001)
				end
			
				local pushed = microButton:GetPushedTexture()
				if pushed then
					microButton:SetPushedTexture("")
					pushed:SetTexture(nil)
					pushed:SetAlpha(0)
					pushed:SetSize(.0001, .0001)
				end
			
				local highlight = microButton:GetNormalTexture()
				if highlight then
					microButton:SetHighlightTexture("")
					highlight:SetAlpha(0)
					highlight:SetSize(.0001, .0001)
				end
				
				local disabled = microButton:GetDisabledTexture()
				if disabled then
					microButton:SetNormalTexture("")
					disabled:SetAlpha(0)
					disabled:SetSize(.0001, .0001)
				end
				
				local flash = _G[buttonName.."Flash"]
				if flash then
					flash:SetTexture(nil)
					flash:SetAlpha(0)
					flash:SetSize(.0001, .0001)
				end
		
				microButton:SetScript("OnUpdate", nil)
				microButton:SetScript("OnEnter", microButtonScripts[buttonName.."_OnEnter"] or microButtonScripts.MicroButton_OnEnter)
				microButton:SetScript("OnLeave", microButtonScripts.MicroButton_OnLeave)


				microButton:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod) 

				if Layout.MenuButton_PostCreate then 
					Layout.MenuButton_PostCreate(microButton, microButtonTexts[buttonName])
				end

				if Layout.MenuButton_PostUpdate then 
					local PostUpdate = Layout.MenuButton_PostUpdate
					microButton:HookScript("OnEnter", PostUpdate)
					microButton:HookScript("OnLeave", PostUpdate)
					microButton:HookScript("OnMouseDown", function(self) self.isDown = true; return PostUpdate(self) end)
					microButton:HookScript("OnMouseUp", function(self) self.isDown = false; return PostUpdate(self) end)
					microButton:HookScript("OnShow", function(self) self.isDown = false; return PostUpdate(self) end)
					microButton:HookScript("OnHide", function(self) self.isDown = false; return PostUpdate(self) end)
					PostUpdate(microButton)
				else
					microButton:HookScript("OnMouseDown", function(self) self.isDown = true end)
					microButton:HookScript("OnMouseUp", function(self) self.isDown = false end)
					microButton:HookScript("OnShow", function(self) self.isDown = false end)
					microButton:HookScript("OnHide", function(self) self.isDown = false end)
				end 

				-- Add a frame the secure autohider can track,
				-- and anchor it to the micro button
				local autohideParent = CreateFrame("Frame", nil, window, "SecureHandlerAttributeTemplate")
				autohideParent:SetPoint("TOPLEFT", microButton, "TOPLEFT", -6, 6)
				autohideParent:SetPoint("BOTTOMRIGHT", microButton, "BOTTOMRIGHT", 6, -6)

				-- Add the frame to the list of secure autohiders
				hiders["autohide"..id] = autohideParent
			end 

		end 

		for id,object in ipairs({ 
				MicroButtonPortrait, 
				GuildMicroButtonTabard, 
				PVPMicroButtonTexture, 
				MainMenuBarPerformanceBar, 
				MainMenuBarDownload }) 
			do
			if object then 
				if (object.SetTexture) then 
					object:SetTexture(nil)
					object:SetVertexColor(0,0,0,0)
				end 
				object:SetParent(UIHider)
			end  
		end 
		for id,method in ipairs({ 
				"MoveMicroButtons", 
				"UpdateMicroButtons", 
				"UpdateMicroButtonsParent" }) 
			do 
			if _G[method] then 
				hooksecurefunc(method, Module.UpdateMicroButtons)
			end 
		end 

		self:UpdateMicroButtons()
	end 
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateMicroButtons()
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardMicroMenu]")
	CoreLayout = CogWheel("LibDB"):GetDatabase(PREFIX..":[Core]")
end

Module.OnInit = function(self)
	self:AddOptionsToMenuWindow()
end 

Module.OnEnable = function(self)
	self:AddOptionsToMenuButton()
	self:UpdatePerformanceBar()
end 
	
