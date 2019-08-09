local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardGameMenu", "LibEvent", "LibDB", "LibTooltip", "LibFrame")
local Layout, L

Module:SetIncompatible("ConsolePort")

-- Lua API
local _G = _G
local ipairs = ipairs
local table_remove = table.remove
local type = type 

-- WoW API
local InCombatLockdown = _G.InCombatLockdown
local IsMacClient = _G.IsMacClient

local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300, 50, 10, 3/4

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateButtonLayout()
	end 
end 

Module.UpdateButtonLayout = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	local UICenter = self:GetFrame("UICenter")

	local previous, bottom_previous
	local first, last
	for i,v in ipairs(self.buttons) do
		local button = v.button
		if button and button:IsShown() then
			button:ClearAllPoints()
			if previous then
				button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -buttonSpacing)
			else
				button:SetPoint("TOP", UICenter, "TOP", 0, -300) -- we'll change this later
				first = button
			end
			previous = button
			last = button
		end
	end	

	-- re-align first button so that the menu will be vertically centered
	local top = first:GetTop()
	local bottom = last:GetBottom()
	local screen_height = UICenter:GetHeight()
	local height = top - bottom
	local y_position = (screen_height - height) *2/5

	first:ClearAllPoints()
	first:SetPoint("TOP", UICenter, "TOP", 0, -y_position)
end

Module.StyleButtons = function(self)
	local UICenter = self:GetFrame("UICenter")

	local need_addon_watch
	for i,v in ipairs(self.buttons) do

		-- figure out the real frame handle of the button
		local button
		if type(v.content) == "string" then
			button = _G[v.content]
		else
			button = v.content
		end
		
		-- style it unless we've already done it
		if not v.styled then
			
			if button then
				-- Ignore hidden buttons, because that means Blizzard aren't using them.
				-- An example of this is the mac options button which is hidden on windows/linux.

				local label
				if type(v.label) == "function" then
					label = v.label()
				else
					label = v.label
				end
				local anchor = v.anchor
				
				-- run custom scripts on the button, if any
				if v.run then
					v.run(button)
				end

				-- Hide some textures added in Legion that cause flickering
				if button.Left then
					button.Left:SetAlpha(0)
				end
				if button.Right then
					button.Right:SetAlpha(0)
				end
				if button.Middle then
					button.Middle:SetAlpha(0)
				end

				-- Clear away blizzard artwork
				button:SetNormalTexture("")
				button:SetHighlightTexture("")
				button:SetPushedTexture("")

				--button:SetText(" ") -- this is not enough, blizzard adds it back in some cases
				
				local fontstring = button:GetFontString()
				if fontstring then
					fontstring:SetAlpha(0) -- this is compatible with the Shop button
				end
				
				button:SetSize(Layout.MenuButtonSize[1]*Layout.MenuButtonSizeMod, Layout.MenuButtonSize[2]*Layout.MenuButtonSizeMod) 

				if Layout.MenuButton_PostCreate then 
					Layout.MenuButton_PostCreate(button, label)
				end

				if Layout.MenuButton_PostUpdate then 
					local PostUpdate = Layout.MenuButton_PostUpdate
					button:HookScript("OnEnter", PostUpdate)
					button:HookScript("OnLeave", PostUpdate)
					button:HookScript("OnMouseDown", function(self) self.isDown = true; return PostUpdate(self) end)
					button:HookScript("OnMouseUp", function(self) self.isDown = false; return PostUpdate(self) end)
					button:HookScript("OnShow", function(self) self.isDown = false; return PostUpdate(self) end)
					button:HookScript("OnHide", function(self) self.isDown = false; return PostUpdate(self) end)
					PostUpdate(button)
				else
					button:HookScript("OnMouseDown", function(self) self.isDown = true end)
					button:HookScript("OnMouseUp", function(self) self.isDown = false end)
					button:HookScript("OnShow", function(self) self.isDown = false end)
					button:HookScript("OnHide", function(self) self.isDown = false end)
				end 
			
				v.button = button -- add a reference to the frame handle for the layout function
				v.styled = true -- avoid double styling
					
			else
				-- If the button doesn't exist, it could be something added by an addon later.
				if v.addon then
					need_addon_watch = true
				end
			end

		end
	end
	
	-- Add this as a callback if a button from an addon wasn't loaded.
	-- *Could add in specific addons to look for here, but I'm not going to bother with it.
	if need_addon_watch then
		if not self.looking_for_addons then
			self:RegisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = true
		end
	else
		if self.looking_for_addons then
			self:UnregisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = nil
		end
	end
	
	self:UpdateButtonLayout()
end

Module.StyleWindow = function(self, frame)

	self.frame:EnableMouse(false) -- only need the mouse on the actual buttons
	self.frame:SetBackdrop(nil) 
	
	self.frame:SetFrameStrata("DIALOG")
	self.frame:SetFrameLevel(120)

	-- registry of objects we won't strip (not actually used yet)
	if (not self.objects) then
		self.objects = {} 
	end
	
	for i = 1, self.frame:GetNumRegions() do
		local region = select(i, self.frame:GetRegions())
		if region and not self.objects[region] then
			local object_type = region.GetObjectType and region:GetObjectType()
			local hide
			if object_type == "Texture" then
				region:SetTexture(nil)
				region:SetAlpha(0)
			elseif object_type == "FontString" then
				region:SetText("")
			end
		end
	end

	-- 8.2.0 weirdness
	if self.frame.Border then 
		self.frame.Border:SetParent(self.UIHider)
	end

end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardGameMenu]")
end

Module.OnInit = function(self)
	self.frame = GameMenuFrame

	-- does this taint? :/
	local UICenter = self:GetFrame("UICenter")
	self.frame:SetParent(UICenter)

	self.buttons = {
		{ content = GameMenuButtonHelp, label = GAMEMENU_HELP },
		{ content = GameMenuButtonStore, label = BLIZZARD_STORE },
		{ content = GameMenuButtonWhatsNew, label = GAMEMENU_NEW_BUTTON },
		{ content = GameMenuButtonOptions, label = SYSTEMOPTIONS_MENU },
		{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
		{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
		{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, 
		{ content = GameMenuButtonMacros, label = MACROS },
		{ content = GameMenuButtonAddons, label = ADDONS },
		{ content = GameMenuButtonRatings, label = RATINGS_MENU },
		{ content = GameMenuButtonLogout, label = LOGOUT },
		{ content = GameMenuButtonQuit, label = EXIT_GAME },
		{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
	}
	
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	self.UIHider = UIHider
	
	-- kill mac options button if not a mac client
	if GameMenuButtonMacOptions and (not IsMacClient()) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonMacOptions then
				GameMenuButtonMacOptions:UnregisterAllEvents()
				GameMenuButtonMacOptions:SetParent(UIHider)
				GameMenuButtonMacOptions.SetParent = function() end
				table_remove(self.buttons, i)
				break
			end
		end
	end
	
	-- Remove store button if there's no store available,
	-- if we're currently using a trial account,
	-- or if the account is in limited (no paid gametime) mode.
	-- TODO: Hook a callback post-styling and post-showing this 
	-- when the store becomes available mid-session. 
	if GameMenuButtonStore 
	and ((C_StorePublic and not C_StorePublic.IsEnabled())
	or (IsTrialAccount and IsTrialAccount()) 
	or (GameLimitedMode_IsActive and GameLimitedMode_IsActive())) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonStore then
				GameMenuButtonStore:UnregisterAllEvents()
				GameMenuButtonStore:SetParent(UIHider)
				GameMenuButtonStore.SetParent = function() end
				table_remove(self.buttons, i)
				break
			end
		end
	end

	-- add a hook to blizzard's button visibility function to properly re-align the buttons when needed
	if GameMenuFrame_UpdateVisibleButtons then
		hooksecurefunc("GameMenuFrame_UpdateVisibleButtons", function() self:UpdateButtonLayout() end)
	end

	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateButtonLayout")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateButtonLayout")

	if VideoOptionsFrameApply then
		VideoOptionsFrameApply:HookScript("OnClick", function() self:UpdateButtonLayout() end)
	end

	if VideoOptionsFrameOkay then
		VideoOptionsFrameOkay:HookScript("OnClick", function() self:UpdateButtonLayout() end)
	end

end

Module.OnEnable = function(self)
	self:StyleWindow()
	self:StyleButtons()
end
