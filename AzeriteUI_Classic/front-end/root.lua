local ADDON, Private = ...

-- Wooh! 
local Core = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibMessage", "LibEvent", "LibBlizzard", "LibFrame", "LibSlash", "LibAura")

-- Tell the back-end what addon to look for before 
-- initializing this module and all its submodules. 
Core:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any module configs are created.
Core:RegisterSavedVariablesGlobal(ADDON.."_DB")

-- Can't have both us and these
Core:SetIncompatible("DiabolicUI")
Core:SetIncompatible("DiabolicTwo")
Core:SetIncompatible("GoldieSix")
Core:SetIncompatible("GoldpawUI")
Core:SetIncompatible("KkthnxUI")
Core:SetIncompatible("Tukui")
Core:SetIncompatible("ElvUI")

-- Lua API
local _G = _G
local ipairs = ipairs
local string_find = string.find

-- WoW API
local DisableAddOn = _G.DisableAddOn
local EnableAddOn = _G.EnableAddOn
local LoadAddOn = _G.LoadAddOn
local ReloadUI = _G.ReloadUI
local SetActionBarToggles = _G.SetActionBarToggles

-- Addon localization
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Addon defaults
local defaults = {
	-- Enables a layout switch targeted towards healers
	enableHealerMode = false,

	-- Loads all child modules with debug functionality, 
	-- doesn't actually load any consoles. 
	loadDebugConsole = true, 	

	-- Enable console visibility. 
	-- Requires the above to be true. 
	enableDebugConsole = false  
}

local SECURE = {
	HealerMode_SecureCallback = [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enablehealermode") then 
			self:SetAttribute("enableHealerMode", value); 

			-- secure callbacks 
			local extraProxy; 
			local id = 0; 
			repeat
				id = id + 1
				extraProxy = self:GetFrameRef("ExtraProxy"..id)
				if extraProxy then 
					extraProxy:SetAttribute(name, value); 
				end
			until (not extraProxy) 

			-- Lua callbacks
			-- *Note that we're not actually listing is as a mode in the menu. 
			self:CallMethod("OnModeToggle", "healerMode"); 

		elseif (name == "change-enabledebugconsole") then 
			--self:SetAttribute("enableDebugConsole", value); 
			self:CallMethod("UpdateDebugConsole"); 
		end 
	]=]
}

local Minimap_ZoomInClick = function()
	if MinimapZoomIn:IsEnabled() then 
		MinimapZoomOut:Enable()
		Minimap:SetZoom(Minimap:GetZoom() + 1)
		if (Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
			MinimapZoomIn:Disable()
		end
	end 
end

local Minimap_ZoomOutClick = function()
	if MinimapZoomOut:IsEnabled() then 
		MinimapZoomIn:Enable()
		Minimap:SetZoom(Minimap:GetZoom() - 1)
		if (Minimap:GetZoom() == 0) then
			MinimapZoomOut:Disable()
		end
	end 
end

local fixMinimap = function()
	local currentZoom = Minimap:GetZoom()
	local maxLevels = Minimap:GetZoomLevels()
	if currentZoom and maxLevels then 
		if maxLevels > currentZoom then 
			Minimap_ZoomInClick()
			Minimap_ZoomOutClick()
		else
			Minimap_ZoomOutClick()
			Minimap_ZoomInClick()
		end 
	end 
end

Core.SwitchTo = function(self, editBox, ...)
	local addon = ...
	if (addon and (addon ~= "") and self.EasySwitch.Cmd[addon]) then
		DisableAddOn(ADDON, true)
		EnableAddOn(self.EasySwitch.Cmd[addon], true)
		ReloadUI()
	end  
end 

Core.IsModeEnabled = function(self, modeName)
	-- Not actually called by the menu, since we're not
	-- listing our healerMode as a mode, just a toggleValue. 
	-- We do however use our standard mode API so for other modules 
	-- to be able to easily query if this fake mode is enabled. 
	if (modeName == "healerMode") then 
		return self.db.enableHealerMode 

	-- This one IS a mode. 
	elseif (modeName == "enableDebugConsole") then
		return self.db.enableDebugConsole -- self:GetDebugFrame():IsShown()
	end
end

Core.OnModeToggle = function(self, modeName)
	if (modeName == "healerMode") then 
		-- Gratz, we did nothing! 
		-- This fake mode isn't changed by Lua, as it needs to move secure frames. 
		-- We might add in Lua callbacks later though, and those will be called from here. 

	elseif (modeName == "loadConsole") then 
		self:LoadDebugConsole()

	elseif (modeName == "unloadConsole") then 
		self:UnloadDebugConsole()

	elseif (modeName == "enableDebugConsole") then 
		self.db.enableDebugConsole = not self.db.enableDebugConsole
		self:UpdateDebugConsole()

	elseif (modeName == "reloadUI") then 
		ReloadUI()
	end
end

Core.GetPrefix = function(self)
	return ADDON
end

Core.GetSecureUpdater = function(self)
	if (not self.proxyUpdater) then 

		-- Create a secure proxy frame for the menu system. 
		local callbackFrame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")

		-- Lua callback to proxy the setting to the chat window module. 
		callbackFrame.OnModeToggle = function(callbackFrame)
			for i,moduleName in ipairs({ "ChatWindows" }) do 
				local module = self:GetModule(moduleName, true)
				if module and not (module:IsIncompatible() or module:DependencyFailed()) then 
					if (module.OnModeToggle) then 
						module:OnModeToggle("healerMode")
					end
				end
			end 
		end

		callbackFrame.UpdateDebugConsole = function(callbackFrame)
			self:UpdateDebugConsole()
		end

		-- Register module db with the secure proxy.
		if db then 
			for key,value in pairs(db) do 
				callbackFrame:SetAttribute(key,value)
			end 
		end

		-- Now that attributes have been defined, attach the onattribute script.
		callbackFrame:SetAttribute("_onattributechanged", SECURE.HealerMode_SecureCallback)

		self.proxyUpdater = callbackFrame
	end

	-- Return the proxy updater to the module
	return self.proxyUpdater
end

Core.UpdateSecureUpdater = function(self)
	local proxyUpdater = self:GetSecureUpdater()

	local count = 0
	for i,moduleName in ipairs({ "UnitFrameParty", "UnitFrameRaid", "GroupTools" }) do 
		local module = self:GetModule(moduleName, true)
		if module then 
			count = count + 1
			local secureUpdater = module.GetSecureUpdater and module:GetSecureUpdater()
			if secureUpdater then 
				proxyUpdater:SetFrameRef("ExtraProxy"..count, secureUpdater)
			end
		end
	end
end

Core.UpdateDebugConsole = function(self)
	if self.db.enableDebugConsole then 
		self:ShowDebugFrame()
	else
		self:HideDebugFrame()
	end
end

Core.LoadDebugConsole = function(self)
	--EnableAddOn(ADDON .. "_Debug", true)
	self.db.loadDebugConsole = true
	ReloadUI()
end

Core.UnloadDebugConsole = function(self)
	--DisableAddOn(ADDON .. "_Debug", true)
	self.db.loadDebugConsole = false
	ReloadUI()
end

Core.ApplyExperimentalFeatures = function(self)

	-- Attempt to hook the bag bar to the bags
	-- Retrieve the first slot button and the backpack
	local firstSlot = _G.CharacterBag0Slot
	local backpack = _G.ContainerFrame1

	-- These should always exist, but Blizz do have a way of changing things,
	-- and I prefer having functionality not be applied in a future update 
	-- rather than having the UI break from nil bugs. 
	if firstSlot and backpack then 
		firstSlot:ClearAllPoints()
		firstSlot:SetPoint("TOPRIGHT", backpack, "BOTTOMRIGHT", -6, 0)

		local strata = backpack:GetFrameStrata()
		local level = backpack:GetFrameLevel()

		for i = 0,3 do 
			-- Always check for existence, 
			-- because nothing is ever guaranteed. 
			local slot = _G["CharacterBag"..i.."Slot"]
			if slot then 
				slot:SetParent(backpack)
				slot:SetFrameStrata(strata)
				slot:SetFrameLevel(level)
			end 
		end 
	end 

	-- Register addon specific aura filters.
	-- These can be accessed by the other modules by calling 
	-- the relevant methods on the 'Core' module object. 
	local auraFlags = Private.AuraFlags
	if auraFlags then 
		for spellID,flags in pairs(auraFlags) do 
			self:AddAuraUserFlags(spellID,flags)
		end 
	end

end

-- We could add this into the back-end, leaving it here for now, though. 
-- It's not like this addon actually serves any other purpose. 
Core.OnChatCommand = function(self, editBox, msg)
	if (msg == "enable") or (msg == "on") then 
		self.db.enableDebugConsole = true
	elseif (msg == "disable") or (msg == "off") then 
		self.db.enableDebugConsole = false
	else
		self.db.enableDebugConsole = not self.db.enableDebugConsole
	end
	self:UpdateDebugConsole()
end

Core.OnInit = function(self)
	self.db = self:NewConfig("Core", defaults, "global")
	self.layout = CogWheel("LibDB"):GetDatabase(self:GetPrefix()..":[Core]")

	-- Hide the entire UI from the start
	if self.layout.FadeInUI then 
		self:GetFrame("UICenter"):SetAlpha(0)
	end

	-- In case some other jokers have disabled these, we add them back to avoid a World of Bugs.
	-- RothUI used to remove the two first, and a lot of people missed his documentation on how to get them back. 
	-- I personally removed the objective's tracker for a while in DiabolicUI, which led to pain. Lots of pain.
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end

	-- Force-initialize the secure callback system for the menu
	self:GetSecureUpdater()

	-- Fire a startup message into the console, if the debug addon is enabled.
	if self.db.loadDebugConsole then 

		-- Set the flag to tell the back-end we're in debug mode
		self:EnableDebugMode()

		-- Register a chat command for those that want to macro this
		self:RegisterChatCommand("debug", "OnChatCommand")
	
		-- Update initial console visibility
		self:UpdateDebugConsole()
		self:AddDebugMessageFormatted("Debug Mode is active.")
		self:AddDebugMessageFormatted("Type /debug to toggle console visibility!")

		-- Add in a chat command to quickly unload the console
		self:RegisterChatCommand("disableconsole", "UnloadDebugConsole")

	else
		-- Set the flag to tell the back-end we're in normal mode. 
		-- This isn't actually needed, since the back-end don't store settings. 
		-- Just leaving it here for weird semantic reasons that really don't make sense. 
		self:DisableDebugMode()

		-- Add in a chat command to quickly load the console
		self:RegisterChatCommand("enableconsole", "LoadDebugConsole")
	end
end 

Core.OnEnable = function(self)

	-- Disable most of the BlizzardUI, to give room for our own!
	------------------------------------------------------------------------------------
	for widget, state in pairs(self.layout.DisableUIWidgets) do 
		if state then 
			self:DisableUIWidget(widget)
		end 
	end 

	-- Disable complete interface options menu pages we don't need
	------------------------------------------------------------------------------------
	local updateBarToggles
	for id,page in pairs(self.layout.DisableUIMenuPages) do 
		if (page.ID == 5) or (page.Name == "InterfaceOptionsActionBarsPanel") then 
			updateBarToggles = true 
		end 
		self:DisableUIMenuPage(page.ID, page.Name)
	end 

	-- Working around Blizzard bugs and issues I've discovered
	------------------------------------------------------------------------------------
	-- In theory this shouldn't have any effect since we're not using the Blizzard bars. 
	-- But by removing the menu panels above we're preventing the blizzard UI from calling it, 
	-- and for some reason it is required to be called at least once, 
	-- or the game won't fire off the events that tell the UI that the player has an active pet out. 
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	if updateBarToggles then 
		SetActionBarToggles(nil, nil, nil, nil, nil)
	end

	-- Experimental stuff we move to relevant modules once done
	------------------------------------------------------------------------------------
	self:ApplyExperimentalFeatures()

	-- Add chat command to fast switch to other UIs 
	------------------------------------------------------------------------------------
	if self.layout.UseEasySwitch then 
		local counter = 0
		local easySwitch = { Addons = {}, Cmd = {} }
		for addon,list in pairs(self.layout.EasySwitch) do 
			if self:IsAddOnAvailable(addon) then 
				counter = counter + 1
				easySwitch.Addons[addon] = list

				for cmd in pairs(list) do 
					easySwitch.Cmd[cmd] = addon
				end 
			end 
		end 
		if (counter > 0) then 
			self:RegisterChatCommand("goto", "SwitchTo")
			self:RegisterChatCommand("go", "SwitchTo")
			self.EasySwitch = easySwitch
		end 
	end 

	-- Apply startup smoothness and sweetness
	------------------------------------------------------------------------------------
	if self.layout.FadeInUI or self.layout.ShowWelcomeMessage then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		if self.layout.FadeInUI then 
			self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
		end
	end 

	-- Make sure frame references to secure frames are in place for the menu
	------------------------------------------------------------------------------------
	self:UpdateSecureUpdater()

	-- Listen for when the user closes the debugframe directly
	------------------------------------------------------------------------------------
	self:RegisterMessage("CG_DEBUG_FRAME_CLOSED", "OnEvent")
end 

Core.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 
		if self.layout.FadeInUI then 
			self.frame = self.frame or CreateFrame("Frame")
			self.frame.alpha = 0
			self.frame.elapsed = 0
			self.frame.totalDelay = 0
			self.frame.totalElapsed = 0
			self.frame.fadeDuration = self.layout.FadeInSpeed or 1.5
			self.frame.delayDuration = self.layout.FadeInDelay or 1.5
			self.frame:SetScript("OnUpdate", function(self, elapsed) 
				self.elapsed = self.elapsed + elapsed
				if (self.elapsed < 1/60) then 
					return 
				end 
				if self.fading then 
					self.totalElapsed = self.totalElapsed + self.elapsed
					self.alpha = self.totalElapsed / self.fadeDuration
					if (self.alpha >= 1) then 
						Core:GetFrame("UICenter"):SetAlpha(1)
						self.alpha = 0
						self.elapsed = 0
						self.totalDelay = 0
						self.totalElapsed = 0
						self.fading = nil
						self:SetScript("OnUpdate", nil)
						fixMinimap()
						return 
					else 
						Core:GetFrame("UICenter"):SetAlpha(self.alpha)
					end 
				else
					self.totalDelay = self.totalDelay + self.elapsed
					if self.totalDelay >= self.delayDuration then 
						self.fading = true 
					end
				end 
				self.elapsed = 0
			end)
		end
	elseif (event == "PLAYER_LEAVING_WORLD") then
		if self.layout.FadeInUI then 
			if self.frame then 
				self.frame:SetScript("OnUpdate", nil)
				self.alpha = 0
				self.elapsed = 0
				self.totalDelay = 0
				self.totalElapsed = 0
				self.fading = nil
			end
			self:GetFrame("UICenter"):SetAlpha(0)
		end
	elseif (event == "CG_DEBUG_FRAME_CLOSED") then 
		-- This fires from the module back-end when 
		-- the debug console was manually closed by the user.
		-- We need to update our saved setting here.
		self.db.enableDebugConsole = false
	end 
end 

