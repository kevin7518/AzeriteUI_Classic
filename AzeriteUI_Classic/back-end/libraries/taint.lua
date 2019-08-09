local LibTaint = CogWheel:Set("LibTaint", 6)
if (not LibTaint) then	
	return
end

local LibModule = CogWheel("LibModule")
assert(LibModule, "LibTaint requires LibModule to be loaded.")

-- Library registries
LibTaint.embeds = LibTaint.embeds or {} -- nothing to embed?
LibTaint.fixes = LibTaint.fixes or {} -- tracking applied fixes and version number

-- Version registry for the fixes in this file, 
-- to easier compare to other library versions.
local fixes = {
	dropdownTaint = 1,
	germanOneLetterDay = 1,
	tradeSkillRows = 1,
	namePlateMotionDropdown = 1,
	nonEnglishShipyardMap = 1,
	openToAddonCategory = 2,
	petJournalLinks = 1,
	addonListTooltip = 1,
	addonListInterface = 1,
}

(function(self)

	-- UIDropDown taints
	-- Source: https://www.townlong-yak.com/bugs/afKy4k-HonorFrameLoadTaint
	if (not LibTaint.fixes.dropdownTaint) or (LibTaint.fixes.dropdownTaint < fixes.dropdownTaint) then 
		if UIDropDownMenu_InitializeHelper then 
			if ((UIDROPDOWNMENU_VALUE_PATCH_VERSION or 0) < 2) then 
				UIDROPDOWNMENU_VALUE_PATCH_VERSION = 2 
				hooksecurefunc("UIDropDownMenu_InitializeHelper", function() 
					if UIDROPDOWNMENU_VALUE_PATCH_VERSION ~= 2 then 
						return 
					end 
					for i=1, UIDROPDOWNMENU_MAXLEVELS do 
						for j=1, UIDROPDOWNMENU_MAXBUTTONS do 
							local b = _G["DropDownList" .. i .. "Button" .. j] 
							if not (issecurevariable(b, "value") or b:IsShown()) then 
								b.value = nil 
								repeat 
									j, b["fx" .. j] = j+1 
								until issecurevariable(b, "value") 
							end 
						end 
					end 
				end) 
				LibTaint.fixes.dropdownTaint = fixes.dropdownTaint
			end 
		end
	end 

	-- Various Blizzard Bugs
	-- All credits to the individual authors. 
	-- Source: https://www.wowace.com/projects/blizzbugssuck
	if (not LibModule:IsAddOnEnabled("!BlizzBugsSuck")) then 

		-- Fix incorrect translations in the German localization
		if (not LibTaint.fixes.germanOneLetterDay) or (LibTaint.fixes.germanOneLetterDay < fixes.germanOneLetterDay) then 
			if GetLocale() == "deDE" then
				-- Day one-letter abbreviation is using a whole word instead of one letter.
				-- Confirmed still bugged in 7.0.3.22293
				DAY_ONELETTER_ABBR = "%d d"

				LibTaint.fixes.germanOneLetterDay = fixes.germanOneLetterDay
			end 
		end
	
		-- Fix error when shift-clicking header rows in the tradeskill UI.
		-- This is caused by the TradeSkillRowButtonTemplate's OnClick script
		-- failing to account for some rows being headers. Fix by ignoring
		-- modifiers when clicking header rows.
		-- New in 7.0
		if (not LibTaint.fixes.tradeSkillRows) or (LibTaint.fixes.tradeSkillRows < fixes.tradeSkillRows) then 
			local frame = CreateFrame("Frame")
			frame:RegisterEvent("ADDON_LOADED")
			frame:SetScript("OnEvent", function(self, event, name)
				if name == "Blizzard_TradeSkillUI" then
					local old_OnClick = TradeSkillFrame.RecipeList.buttons[1]:GetScript("OnClick")
					local new_OnClick = function(self, button)
						if IsModifiedClick() and self.isHeader then
							return self:GetParent():GetParent():OnHeaderButtonClicked(self, self.tradeSkillInfo, button)
						end
						old_OnClick(self, button)
					end
					for i = 1, #TradeSkillFrame.RecipeList.buttons do
						TradeSkillFrame.RecipeList.buttons[i]:SetScript("OnClick", new_OnClick)
					end
					self:UnregisterAllEvents()
				end
			end)
			LibTaint.fixes.tradeSkillRows = fixes.tradeSkillRows
		end 

		-- Fix error when mousing over the Nameplate Motion Type dropdown in
		-- Interface Options > Names panel if the current setting isn't listed.
		-- Happens if the user had previously selected the Spreading Nameplates
		-- option, which was removed from the game in 7.0.
		if (not LibTaint.fixes.namePlateMotionDropdown) or (LibTaint.fixes.namePlateMotionDropdown < fixes.namePlateMotionDropdown) then 
			local OnEnter = InterfaceOptionsNamesPanelUnitNameplatesMotionDropDown:GetScript("OnEnter")
			InterfaceOptionsNamesPanelUnitNameplatesMotionDropDown:SetScript("OnEnter", function(self)
				if self.tooltip then
					OnEnter(self)
				end
			end)
			LibTaint.fixes.namePlateMotionDropdown = fixes.namePlateMotionDropdown
		end 

		-- Fix missing bonus effects on shipyard map in non-English locales
		-- Problem is caused by Blizzard checking a localized API value
		-- against a hardcoded English string.
		-- New in 6.2, confirmed still bugged in 7.0.3.22293
		if (not LibTaint.fixes.nonEnglishShipyardMap) or (LibTaint.fixes.nonEnglishShipyardMap < fixes.nonEnglishShipyardMap) then 
			if GetLocale() ~= "enUS" then
				local frame = CreateFrame("Frame")
				frame:RegisterEvent("ADDON_LOADED")
				frame:SetScript("OnEvent", function(self, event, name)
					if name == "Blizzard_GarrisonUI" then
						hooksecurefunc("GarrisonShipyardMap_SetupBonus", function(self, missionFrame, mission)
							if (mission.typePrefix == "ShipMissionIcon-Bonus" and not missionFrame.bonusRewardArea) then
								missionFrame.bonusRewardArea = true
								for id, reward in pairs(mission.rewards) do
									local posX = reward.posX or 0
									local posY = reward.posY or 0
									posY = posY * -1
									missionFrame.BonusAreaEffect:SetAtlas(reward.textureAtlas, true)
									missionFrame.BonusAreaEffect:ClearAllPoints()
									missionFrame.BonusAreaEffect:SetPoint("CENTER", self.MapTexture, "TOPLEFT", posX, posY)
									break
								end
							end
						end)
						self:UnregisterAllEvents()
					end
				end)
				LibTaint.fixes.nonEnglishShipyardMap = fixes.nonEnglishShipyardMap
			end
		end 

		-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
		-- Confirmed still broken in 6.2.2.20490 (6.2.2a)
		if (not LibTaint.fixes.openToAddonCategory) or (LibTaint.fixes.openToAddonCategory < fixes.openToAddonCategory) then 
			local get_panel_name
			get_panel_name = function(panel)
				local tp = type(panel)
				local cat = INTERFACEOPTIONS_ADDONCATEGORIES
				if tp == "string" then
					for i = 1, #cat do
						local p = cat[i]
						if p.name == panel then
							if p.parent then
								return get_panel_name(p.parent)
							else
								return panel
							end
						end
					end
				elseif tp == "table" then
					for i = 1, #cat do
						local p = cat[i]
						if p == panel then
							if p.parent then
								return get_panel_name(p.parent)
							else
								return panel.name
							end
						end
					end
				end
			end
			local InterfaceOptionsFrame_OpenToCategory_Fix = function(panel)
				if (doNotRun or InCombatLockdown()) then 
					return 
				end
				local panelName = get_panel_name(panel)
				if (not panelName) then 
					return 
				end 
				local noncollapsedHeaders = {}
				local shownpanels = 0
				local mypanel
				local t = {}
				local cat = INTERFACEOPTIONS_ADDONCATEGORIES
				for i = 1, #cat do
					local panel = cat[i]
					if not panel.parent or noncollapsedHeaders[panel.parent] then
						if panel.name == panelName then
							panel.collapsed = true
							t.element = panel
							InterfaceOptionsListButton_ToggleSubCategories(t)
							noncollapsedHeaders[panel.name] = true
							mypanel = shownpanels + 1
						end
						if not panel.collapsed then
							noncollapsedHeaders[panel.name] = true
						end
						shownpanels = shownpanels + 1
					end
				end
				local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
				if shownpanels > 15 and Smin < Smax then
					local val = (Smax/(shownpanels-15))*(mypanel-2)
					InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
				end
				doNotRun = true
				InterfaceOptionsFrame_OpenToCategory(panel)
				doNotRun = false
			end
			hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
			LibTaint.fixes.openToAddonCategory = fixes.openToAddonCategory
		end 

		-- Fix an issue where the PetJournal drag buttons (the pet icons in the ACTIVE team on the right
		-- pane of the PetJournal) cannot be clicked to link a pet into chat.
		-- The necessary code is already present, but the buttons are not registered for the correct click.
		-- Confirmed still bugged in 7.0.3.22293
		if (not LibTaint.fixes.petJournalLinks) or (LibTaint.fixes.petJournalLinks < fixes.petJournalLinks) then 
			local frame = CreateFrame("Frame")
			frame:RegisterEvent("ADDON_LOADED")
			frame:SetScript("OnEvent", function(self, event, name)
				if name == "Blizzard_Collections" then
					for i = 1, 3 do
						local button = _G["PetJournalLoadoutPet"..i]
						if button and button.dragButton then
							button.dragButton:RegisterForClicks("LeftButtonUp")
						end
					end
					self:UnregisterAllEvents()
				end
			end)
			LibTaint.fixes.petJournalLinks = fixes.petJournalLinks
		end 
	

		-- Fix a lua error when scrolling the in-game Addon list, where the mouse
		-- passes over a world object that activates GameTooltip.
		-- Caused because the FrameXML code erroneously assumes it exclusively owns the GameTooltip object
		-- Confirmed still bugged in 7.0.3.22293
		if (not LibTaint.fixes.addonListTooltip) or (LibTaint.fixes.addonListTooltip < fixes.addonListTooltip) then 
			local orig = AddonTooltip_Update
			_G.AddonTooltip_Update = function(owner, ...) 
				if AddonList and AddonList:IsMouseOver() then
					local id = owner and owner.GetID and owner:GetID()
					if id and id > 0 and id <= GetNumAddOns() then
						orig(owner, ...) 
						return
					end
				end
			end
			LibTaint.fixes.addonListTooltip = fixes.addonListTooltip
		end 


		-- Fix glitchy-ness of EnableAddOn/DisableAddOn API, which affects the stability of the default 
		-- UI's addon management list (both in-game and glue), as well as any addon-management addons.
		-- The problem is caused by broken defaulting logic used to merge AddOns.txt settings across 
		-- characters to those missing a setting in AddOns.txt, whereby toggling an addon for a single character 
		-- sometimes results in also toggling it for a different character on that realm for no obvious reason.
		-- The code below ensures each character gets an independent enable setting for each installed 
		-- addon in its AddOns.txt file, thereby avoiding the broken defaulting logic.
		-- Note the fix applies to each character the first time it loads there, and a given character 
		-- is not protected from the faulty logic on addon X until after the fix has run with addon X 
		-- installed (regardless of enable setting) and the character has logged out normally.
		-- Confirmed bugged in 6.2.3.20886
		if (not LibTaint.fixes.addonListInterface) or (LibTaint.fixes.addonListInterface < fixes.addonListInterface) then 
			local player = UnitName("player")
			if player and #player > 0 then
				for i=1,GetNumAddOns() do 
					if GetAddOnEnableState(player, i) > 0 then  -- addon is enabled
						EnableAddOn(i, player)
					else
						DisableAddOn(i, player)
					end 
				end
			end
			LibTaint.fixes.addonListInterface = fixes.addonListInterface
		end 
	end 
end) (LibTaint)


-- Could probably remove all the following, 
-- but leaving it for semantic reasons. 
local embedMethods = {
}

LibTaint.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTaint.embeds) do
	LibTaint:Embed(target)
end
