local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "UnitHealth requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()
if IS_CLASSIC then 
	return 
end 

local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardInterfaceStyling", "LibEvent", "LibDB", "LibTooltip")
local Layout, L

-- Lua API
local _G = _G
local setmetatable = setmetatable
local string_format = string.format

-- WoW API
local CraftRecipe = _G.C_TradeSkillUI.CraftRecipe
local CreateFrame = _G.CreateFrame
local GetItemCount = _G.GetItemCount
local GetLocale = _G.GetLocale
local GetProfessionInfo = _G.GetProfessionInfo
local GetProfessions = _G.GetProfessions
local GetRecipeInfo = _G.C_TradeSkillUI.GetRecipeInfo
local GetSpellBookItemName = _G.GetSpellBookItemName
local GetSpellBookItemTexture = _G.GetSpellBookItemTexture
local GetSpellInfo = _G.GetSpellInfo
local GetTradeSkillLine = _G.C_TradeSkillUI.GetTradeSkillLine
local hooksecurefunc = _G.hooksecurefunc
local InCombatLockdown = _G.InCombatLockdown
local IsCurrentSpell = _G.IsCurrentSpell
local IsNPCCrafting = _G.C_TradeSkillUI.IsNPCCrafting
local IsSpellKnown = _G.IsSpellKnown
local IsTradeSkillGuild = _G.C_TradeSkillUI.IsTradeSkillGuild
local IsTradeSkillLinked = _G.C_TradeSkillUI.IsTradeSkillLinked
local PlayerHasToy = _G.PlayerHasToy
local UseItemByName = _G.UseItemByName
 
-- Current player level
local LEVEL = UnitLevel("player") 

local playerClass = UnitClass("player")
if (playerClass == "DEATHKNIGHT") then
	spells[#spells + 1] = 53428 -- Runeforging
elseif (playerClass == "ROGUE") then
	spells[#spells + 1] = 1804 -- Pick Lock
end

-- ItemID of enchanter vellums
local ENCHANTING_TEXT = GetSpellInfo(7411)
local SCROLL_ID = 38682
local SCROLL_TEXT = (setmetatable({
	deDE = "Rolle",
	frFR = "Parchemin",
	itIT = "Pergamene",
	esES = "Pergamino",
	esMX = "Pergamino",
	ptBR = "Pergaminho",
	ptPT = "Pergaminho",
	ruRU = "Свиток",
	koKR = "두루마리",
	zhCN = "卷轴",
	zhTW = "卷軸"
}, { __index = function(t,v) return "Scroll" end}))[(GetLocale())]

local ranks = PROFESSION_RANKS
local tabs, spells = {}, {}

local defaults = {
	-- Primary Professions
	[164] = {true, false},  -- Blacksmithing
	[165] = {true, false},  -- Leatherworking
	[171] = {true, false},  -- Alchemy
	[182] = {false, false}, -- Herbalism
	[186] = {true, false},  -- Mining
	[197] = {true, false},  -- Tailoring
	[202] = {true, false},  -- Engineering
	[333] = {true, true},   -- Enchanting
	[393] = {false, false}, -- Skinning
	[755] = {true, true},   -- Jewelcrafting
	[773] = {true, true},   -- Inscription
 
	-- Secondary Professions
	[129] = {true, false},  -- First Aid
	[185] = {true, true},   -- Cooking
	[356] = {false, false}, -- Fishing
	[794] = {false, false}, -- Archaeology
}

Module.EnableScrollButton = function(self)
	local TradeSkillFrame = _G.TradeSkillFrame

	local enchantScrollButton = CreateFrame("Button", "CG_TradeSkillCreateScrollButton", TradeSkillFrame, "MagicButtonTemplate")
	enchantScrollButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPLEFT")
	enchantScrollButton:SetPoint("LEFT", TradeSkillFrame.DetailsFrame, "LEFT") -- make the button as big as we can
	enchantScrollButton:SetScript("OnClick", function()
		CraftRecipe(TradeSkillFrame.DetailsFrame.selectedRecipeID)
		UseItemByName(SCROLL_ID)
	end)
	enchantScrollButton:SetMotionScriptsWhileDisabled(true)
	enchantScrollButton:Hide()

	hooksecurefunc(TradeSkillFrame.DetailsFrame, "RefreshButtons", function(self)
		if (IsTradeSkillGuild() or IsNPCCrafting() or IsTradeSkillLinked()) then
			enchantScrollButton:Hide()
		else
			local recipeInfo = self.selectedRecipeID and GetRecipeInfo(self.selectedRecipeID)
			if (recipeInfo and recipeInfo.learned) then

				local tradeSkillID, tradeSkillName, skillLineRank, skillLineMaxRank, skillLineModifier, parentSkillLineID, parentSkillLineName = GetTradeSkillLine()
				if (parentSkillLineName == ENCHANTING_TEXT) then
					enchantScrollButton:Show()
					
					local numCreateable = recipeInfo.numAvailable
					local numScrollsAvailable = GetItemCount(SCROLL_ID)
					
					enchantScrollButton:SetFormattedText("%s (%.0f)", SCROLL_TEXT, numScrollsAvailable)
					
					if (numScrollsAvailable == 0) then
						numCreateable = 0
					end
					
					if (numCreateable > 0) then
						enchantScrollButton:Enable()
					else
						enchantScrollButton:Disable()
					end
				else
					enchantScrollButton:Hide()
				end
			else
				enchantScrollButton:Hide()
			end
		end
	end)
end

Module.UpdateSelectedTabs = function(self, object)
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", "OnEvent")
	for index = 1, #tabs[object] do
		local tab = tabs[object][index]
		tab:SetChecked(IsCurrentSpell(tab.name))
	end
end
 
Module.ResetTabs = function(self, object, noHide)
	if (not noHide) then 
		for index = 1, #tabs[object] do
			tabs[object][index]:Hide()
		end
	end
 	tabs[object].index = 0
end

Module.UpdateTab = function(self, object, name, rank, texture, hat)
	local index = tabs[object].index + 1
	local tab = tabs[object][index] or CreateFrame("CheckButton", "ProTabs"..tabs[object].index, object, "SpellBookSkillLineTabTemplate SecureActionButtonTemplate")
 
	tab:ClearAllPoints()
	tab:SetPoint("TOPLEFT", object, "TOPRIGHT", 0, (-44 * index) + 18)
	tab:SetNormalTexture(texture)
 
	if hat then
		tab:SetAttribute("type", "toy")
		tab:SetAttribute("toy", 134020)
	else
		tab:SetAttribute("type", "spell")
		tab:SetAttribute("spell", name)
	end
 
	tab:Show()
 
	tab.name = name
	tab.tooltip = rank and rank ~= "" and string_format("%s (%s)", name, rank) or name
 
	tabs[object][index] = tabs[object][index] or tab
	tabs[object].index = tabs[object].index + 1
end

Module.GetProfessionRank = function(self, currentSkill)
	if (currentSkill <= 74) then
		return APPRENTICE
	end
 
	for index = #ranks, 1, -1 do
		local requiredSkill, title = ranks[index][1], ranks[index][2]
 
		if (currentSkill >= requiredSkill) then
			return title
		end
	end
end

Module.HandleProfession = function(self, object, professionID, hat)
	if professionID then
		local _, _, currentSkill, _, numAbilities, offset, skillID = GetProfessionInfo(professionID)
 
		if defaults[skillID] then
			for index = 1, numAbilities do
				if defaults[skillID][index] then
					local name = GetSpellBookItemName(offset + index, "profession")
					local rank = self:GetProfessionRank(currentSkill)
					local texture = GetSpellBookItemTexture(offset + index, "profession")
 
					if name and rank and texture then
						self:UpdateTab(object, name, rank, texture)
					end
				end
			end
		end
 
		if (hat and PlayerHasToy(134020)) then
			self:UpdateTab(object, GetSpellInfo(67556), nil, 236571, true)
		end
	end
end

Module.HandleTabs = function(self, object)
	tabs[object] = tabs[object] or {}
 
	if InCombatLockdown() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	else
		local firstProfession, secondProfession, archaeology, fishing, cooking, firstAid = GetProfessions()

		self:ResetTabs(object, true)
 
		self:HandleProfession(object, firstProfession)
		self:HandleProfession(object, secondProfession)
		self:HandleProfession(object, archaeology)
		self:HandleProfession(object, fishing)
		self:HandleProfession(object, cooking, true)
		self:HandleProfession(object, firstAid)
 
		for index = 1, #spells do
			if IsSpellKnown(spells[index]) then
				local name, rank, texture = GetSpellInfo(spells[index])
				self:UpdateTab(object, name, rank, texture)
			end
		end
	end
 
	self:UpdateSelectedTabs(object)
end

Module.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then 
		local arg = ... 
		if (arg == "Blizzard_TradeSkillUI") then 
			self:StartUp()
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
		end 
	elseif (event == "CURRENT_SPELL_CAST_CHANGED") then 
		local numShown = 0
		for object in pairs(tabs) do
			if object:IsShown() then
				numShown = numShown + 1
				self:UpdateSelectedTabs(object)
			end
		end
		if (numShown == 0) then
			self:UnregisterEvent(event, "OnEvent")
		end
	elseif (event == "SKILL_LINES_CHANGED") then
		for object in pairs(tabs) do
			self:HandleTabs(object)
		end
	elseif (event == "TRADE_SHOW") then 
		local owner = TradeFrame
		if (self.handledTradeFrame) then 
			self:UpdateSelectedTabs(owner)
		else 
			self.handledTradeFrame = true
			self:HandleTabs(TradeFrame)
		end 
	elseif (event == "TRADE_SKILL_SHOW") then 
		local owner = ATSWFrame or MRTSkillFrame or SkilletFrame or TradeSkillFrame
 
		if self:IsAddOnEnabled("TradeSkillDW") and (owner == TradeSkillFrame) then
			self:UnregisterEvent(event, "OnEvent")
		else
			self:HandleTabs(owner)
			self[event] = function()
				for object in pairs(tabs) do
					self:UpdateSelectedTabs(object)
				end
			end
		end
	elseif (event == "TRADE_SKILL_CLOSE") then 
		for object in pairs(tabs) do
			if object:IsShown() then
				self:UpdateSelectedTabs(object)
			end
		end
	elseif (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent(event, "OnEvent")
		for object in pairs(tabs) do
			self:HandleTabs(object)
		end
	end 
end

Module.StartUp = function(self)
	self:EnableScrollButton()
	self:HandleTabs(TradeSkillFrame)

	self:RegisterEvent("TRADE_SKILL_SHOW", "OnEvent")
	self:RegisterEvent("TRADE_SKILL_CLOSE", "OnEvent")
	self:RegisterEvent("TRADE_SHOW", "OnEvent")
	self:RegisterEvent("SKILL_LINES_CHANGED", "OnEvent")
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", "OnEvent")
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[ActionBarMain]")
end

Module.OnInit = function(self)
	if IsAddOnLoaded("Blizzard_TradeSkillUI") then 
		self:StartUp()
	else 
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end 
end 

