--[[--

The purpose of this file is to create general but
addon specific styling methods for all the unitframes.

This file is loaded after other general user databases, 
but prior to loading any of the module config files.
Meaning we can reference the general databases with certainty, 
but any layout data will have to be passed as function arguments.

--]]--

local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

-- Primary Units
local UnitFramePlayer = Core:NewModule("UnitFramePlayer", "LibEvent", "LibUnitFrame", "LibFrame")
local UnitFramePlayerHUD = Core:NewModule("UnitFramePlayerHUD", "LibEvent", "LibUnitFrame")
local UnitFrameTarget = Core:NewModule("UnitFrameTarget", "LibEvent", "LibUnitFrame", "LibSound")

-- Secondary Units
local UnitFrameFocus = Core:NewModule("UnitFrameFocus", "LibUnitFrame")
local UnitFramePet = Core:NewModule("UnitFramePet", "LibUnitFrame", "LibFrame")
local UnitFrameToT = Core:NewModule("UnitFrameToT", "LibUnitFrame")

-- Grouped Units
local UnitFrameArena = Core:NewModule("UnitFrameArena", "LibDB", "LibUnitFrame", "LibFrame")
local UnitFrameBoss = Core:NewModule("UnitFrameBoss", "LibUnitFrame")
local UnitFrameParty = Core:NewModule("UnitFrameParty", "LibDB", "LibFrame", "LibUnitFrame")
local UnitFrameRaid = Core:NewModule("UnitFrameRaid", "LibDB", "LibFrame", "LibUnitFrame", "LibBlizzard")

-- Incompatibilities
-- *Note that Arena frames can also be manually disabled from our menu!
--  The same is true for party- and raid frames, which is 
--  part of why we haven't included any auto-disabling of them. 
--  Other reason is that some like to combine, have our party frames, 
--  but use Grid for raids, or have our raid frames but another addon 
--  to rack specific groups like tanks and so on. 
UnitFrameArena:SetIncompatible("sArena")
UnitFrameArena:SetIncompatible("Gladius")
UnitFrameArena:SetIncompatible("GladiusEx")
--UnitFramePlayerHUD:SetIncompatible("SimpleClassPower")

-- Classic incompatibilities
UnitFrameArena:SetToRetail()

-- Keep these local
local UnitStyles = {} 

-- Lua API
local _G = _G
local date = date
local math_floor = math.floor
local math_pi = math.pi
local select = select
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_split = string.split
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetCVarBool = _G.GetCVarBool
local GetExpansionLevel = _G.GetExpansionLevel
local IsXPUserDisabled = _G.IsXPUserDisabled
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTrivial = _G.UnitIsTrivial
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel

-- Addon API
local GetEffectiveExpansionMaxLevel = CogWheel("LibPlayerData").GetEffectiveExpansionMaxLevel
local PlayerHasXP = CogWheel("LibPlayerData").PlayerHasXP

-- WoW Strings
local S_AFK = _G.AFK
local S_DEAD = _G.DEAD
local S_PLAYER_OFFLINE = _G.PLAYER_OFFLINE

-- WoW Textures
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]

-- Player data
local _,PlayerClass = UnitClass("player")
local _,PlayerLevel = UnitLevel("player")

-----------------------------------------------------------
-- Secure Snippets
-----------------------------------------------------------
local SECURE = {

	-- Called on the group headers
	FrameTable_Create = [=[ 
		Frames = table.new(); 
	]=],
	FrameTable_InsertCurrentFrame = [=[ 
		local frame = self:GetFrameRef("CurrentFrame"); 
		table.insert(Frames, frame); 
	]=],

	Arena_OnAttribute = [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=],
	Arena_SecureCallback = [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enablearenaframes") then 
			self:SetAttribute("enableArenaFrames", value); 
			local visibilityFrame = self:GetFrameRef("GroupHeader");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "[@arena1,exists]show;hide"); 
			else 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "hide"); 
			end 
		end 
	]=],

	-- Called on the party group header
	Party_OnAttribute = [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=], 

	-- Called on the party callback frame
	Party_SecureCallback = [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enablepartyframes") then 
			self:SetAttribute("enablePartyFrames", value); 
			local visibilityFrame = self:GetFrameRef("GroupHeader");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "%s"); 
			else 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "hide"); 
			end 
		elseif (name == "change-enablehealermode") then 

			local GroupHeader = self:GetFrameRef("GroupHeader"); 

			-- set flag for healer mode 
			GroupHeader:SetAttribute("inHealerMode", value); 

			-- Update the layout 
			GroupHeader:RunAttribute("sortFrames"); 
		end 
	]=],

	-- Called on the party frame group header
	Party_SortFrames = [=[
		local inHealerMode = self:GetAttribute("inHealerMode"); 

		local anchorPoint; 
		local anchorFrame; 
		local growthX; 
		local growthY; 

		if (not inHealerMode) then 
			anchorPoint = "%s"; 
			anchorFrame = self; 
			growthX = %.0f;
			growthY = %.0f; 
		else
			anchorPoint = "%s"; 
			anchorFrame = self:GetFrameRef("HealerModeAnchor"); 
			growthX = %.0f;
			growthY = %.0f; 
		end

		-- Iterate the frames
		for id,frame in ipairs(Frames) do 
			frame:ClearAllPoints(); 
			frame:SetPoint(anchorPoint, anchorFrame, anchorPoint, growthX*(id-1), growthY*(id-1)); 
		end 

	]=],

	-- Called on the raid frame group header
	Raid_OnAttribute = [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 

		elseif (name == "state-layout") then
			local groupLayout = self:GetAttribute("groupLayout"); 
			if (groupLayout ~= value) then 

				-- Store the new layout setting
				self:SetAttribute("groupLayout", value);

				-- Update the layout 
				self:RunAttribute("sortFrames"); 
			end 
		end
	]=],

	-- Called on the secure updater 
	Raid_SecureCallback = [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enableraidframes") then 
			self:SetAttribute("enableRaidFrames", value); 
			local visibilityFrame = self:GetFrameRef("GroupHeader");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "%s"); 
			else 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "hide"); 
			end 
		elseif (name == "change-enablehealermode") then 

			local GroupHeader = self:GetFrameRef("GroupHeader"); 

			-- set flag for healer mode 
			GroupHeader:SetAttribute("inHealerMode", value); 

			-- Update the layout 
			GroupHeader:RunAttribute("sortFrames"); 
		end 
	]=], 

	-- Called on the raid frame group header
	Raid_SortFrames = [=[
		local groupLayout = self:GetAttribute("groupLayout"); 
		local inHealerMode = self:GetAttribute("inHealerMode"); 

		local anchor; 
		local colSize; 
		local growthX;
		local growthY;
		local growthYHealerMode;
		local groupGrowthX;
		local groupGrowthY; 
		local groupGrowthYHealerMode; 
		local groupCols;
		local groupRows;
		local groupAnchor; 
		local groupAnchorHealerMode; 

		if (groupLayout == "normal") then 
			colSize = %.0f;
			growthX = %.0f;
			growthY = %.0f;
			growthYHealerMode = %.0f;
			groupGrowthX = %.0f;
			groupGrowthY = %.0f;
			groupGrowthYHealerMode = %.0f;
			groupCols = %.0f;
			groupRows = %.0f;
			groupAnchor = "%s";
			groupAnchorHealerMode = "%s"; 

		elseif (groupLayout == "epic") then 
			colSize = %.0f;
			growthX = %.0f;
			growthY = %.0f;
			growthYHealerMode = %.0f;
			groupGrowthX = %.0f;
			groupGrowthY = %.0f;
			groupGrowthYHealerMode = %.0f;
			groupCols = %.0f;
			groupRows = %.0f;
			groupAnchor = "%s";
			groupAnchorHealerMode = "%s"; 
		end

		-- This should never happen: it does!
		if (not colSize) then 
			return 
		end 

		if inHealerMode then 
			anchor = self:GetFrameRef("HealerModeAnchor"); 
			growthY = growthYHealerMode; 
			groupAnchor = groupAnchorHealerMode; 
			groupGrowthY = groupGrowthYHealerMode;
		else
			anchor = self; 
		end

		-- Iterate the frames
		for id,frame in ipairs(Frames) do 

			local groupID = floor((id-1)/colSize) + 1; 
			local groupX = mod(groupID-1,groupCols) * groupGrowthX; 
			local groupY = floor((groupID-1)/groupCols) * groupGrowthY; 

			local modID = mod(id-1,colSize) + 1;
			local unitX = growthX*(modID-1) + groupX;
			local unitY = growthY*(modID-1) + groupY;

			frame:ClearAllPoints(); 
			frame:SetPoint(groupAnchor, anchor, groupAnchor, unitX, unitY); 
		end 

	]=]
}

-----------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------
local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(value - value%1)
	end	
end

local CreateSecureCallbackFrame = function(module, header, db, script)

	-- Create a secure proxy frame for the menu system
	local callbackFrame = module:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")

	-- Attach the module's visibility frame to the proxy
	callbackFrame:SetFrameRef("GroupHeader", header)

	-- Register module db with the secure proxy
	if db then 
		for key,value in pairs(db) do 
			callbackFrame:SetAttribute(key,value)
		end 
	end

	-- Now that attributes have been defined, attach the onattribute script
	callbackFrame:SetAttribute("_onattributechanged", script)

	-- Attach a getter method for the menu to the module
	module.GetSecureUpdater = function(self) 
		return callbackFrame 
	end

	-- Return the proxy updater to the module
	return callbackFrame
end

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

local SmallFrame_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%.0fm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%.0fk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local SmallFrame_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if disconnected then 
		if element.Value then 
			element.Value:SetText(S_PLAYER_OFFLINE)
		end 
	elseif dead then 
		if element.Value then 
			return element.Value:SetText(S_DEAD)
		end
	else 
		if element.Value then 
			if element.Value.showPercent and (min < max) then 
				return element.Value:SetFormattedText("%.0f%%", min/max*100 - (min/max*100)%1)
			else 
				return SmallFrame_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
			end 
		end 
	end 
end 

local SmallFrame_PostUpdateAlpha = function(self)
	local unit = self.unit
	if (not unit) then 
		return 
	end 

	local targetStyle

	-- Hide it when tot is the same as the target
	if self.hideWhenUnitIsPlayer and (UnitIsUnit(unit, "player")) then 
		targetStyle = "Hidden"

	elseif self.hideWhenUnitIsTarget and (UnitIsUnit(unit, "target")) then 
		targetStyle = "Hidden"

	elseif self.hideWhenTargetIsCritter then 
		local level = UnitLevel("target")
		if ((level and level == 1) and (not UnitIsPlayer("target"))) then 
			targetStyle = "Hidden"
		else 
			targetStyle = "Shown"
		end 
	else 
		targetStyle = "Shown"
	end 

	-- Silently return if there was no change
	if (targetStyle == self.alphaStyle) then 
		return 
	end 

	-- Store the new style
	self.alphaStyle = targetStyle

	-- Apply the new style
	if (targetStyle == "Shown") then 
		self:SetAlpha(1)
	elseif (targetStyle == "Hidden") then 
		self:SetAlpha(0)
	end

	if self.TargetHighlight then 
		self.TargetHighlight:ForceUpdate()
	end
end

local TinyFrame_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%.0fm", min/1e6)  -- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6)  -- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%.0fk", min/1e3)  -- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3)  -- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 						  -- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local TinyFrame_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if dead then 
		if element.Value then 
			return element.Value:SetText(S_DEAD)
		end
	elseif (UnitIsAFK(unit)) then 
		if element.Value then 
			return element.Value:SetText(S_AFK)
		end
	else 
		if element.Value then 
			if element.Value.showPercent and (min < max) then 
				return element.Value:SetFormattedText("%.0f%%", min/max*100 - (min/max*100)%1)
			else 
				return TinyFrame_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
			end 
		end 
	end 
end 

local TinyFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_FLAGS_CHANGED") then 
		-- Do some trickery to instantly update the afk status, 
		-- without having to add additional events or methods to the widget. 
		if UnitIsAFK(unit) then 
			self.Health:OverrideValue(unit)
		else 
			self.Health:ForceUpdate(event, unit)
		end 
	end 
end 

local PlayerHUD_AltPower_OverrideValue = function(element, unit, current, min, max)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value then
		if (current == 0 or max == 0) then
			value:SetText(EMPTY)
		else
			if value.showPercent then
				if value.showMaximum then
					value:SetFormattedText("%s / %s - %.0f%%", short(current), short(max), math_floor(current/max * 100))
				else
					value:SetFormattedText("%s / %.0f%%", short(current), math_floor(current/max * 100))
				end
			else
				if value.showMaximum then
					value:SetFormattedText("%s / %s", short(current), short(max))
				else
					value:SetFormattedText("%s", short(current))
				end
			end
		end
	end
end 

local Player_OverridePowerColor = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
	local self = element._owner
	local Layout = self.layout
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		if Layout.PowerColorSuffix then 
			r, g, b = unpack(powerType and self.colors.power[powerType .. Layout.PowerColorSuffix] or self.colors.power[powerType] or self.colors.power.UNUSED)
		else 
			r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
		end 
	end
	element:SetStatusBarColor(r, g, b)
end 

local Player_OverrideExtraPowerColor = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
	local self = element._owner
	local Layout = self.layout
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		if Layout.ManaColorSuffix then 
			r, g, b = unpack(powerType and self.colors.power[powerType .. Layout.ManaColorSuffix] or self.colors.power[powerType] or self.colors.power.UNUSED)
		else 
			r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
		end 
	end
	element:SetStatusBarColor(r, g, b)
end 

local Player_Threat_UpdateColor = function(element, unit, status, r, g, b)
	if (element:IsObjectType("Texture")) then 
		element:SetVertexColor(r, g, b)
	elseif (element:IsObjectType("FontString")) then 
		element:SetTextColor(r, g, b)
	else 
		if element.health then 
			element.health:SetVertexColor(r, g, b)
		end
		if element.power then 
			element.power:SetVertexColor(r, g, b)
		end
		if element.powerBg then 
			element.powerBg:SetVertexColor(r, g, b)
		end
		if element.mana then 
			element.mana:SetVertexColor(r, g, b)
		end 
		if element.portrait then 
			element.portrait:SetVertexColor(r, g, b)
		end 
	end 
end

local Player_Threat_IsShown = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		return element:IsShown()
	else 
		return element.health and element.health:IsShown()
	end 
end

local Player_Threat_Show = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		element:Show()
	else 
		if element.health then 
			element.health:Show()
		end
		if element.power then 
			element.power:Show()
		end
		if element.powerBg then 
			element.powerBg:Show()
		end
		if element.mana then 
			element.mana:Show()
		end 
		if element.portrait then 
			element.portrait:Show()
		end 
	end 
end 

local Player_Threat_Hide = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		element:Hide()
	else 
		if element.health then 
			element.health:Hide()
		end 
		if element.power then 
			element.power:Hide()
		end
		if element.powerBg then 
			element.powerBg:Hide()
		end
		if element.mana then 
			element.mana:Hide()
		end
		if element.portrait then 
			element.portrait:Hide()
		end
	end 
end 

local Player_PostUpdateTextures = function(self, playerLevel)
	local Layout = self.layout
	if (not Layout.UseProgressiveFrames) then 
		return
	end 
	if (not PlayerHasXP()) then 
		self.Health:SetSize(unpack(Layout.SeasonedHealthSize))
		self.Health:SetStatusBarTexture(Layout.SeasonedHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.SeasonedHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.SeasonedHealthBackdropColor))
		end 

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.SeasonedHealthThreatTexture)
			end 
		end

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.SeasonedPowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.SeasonedPowerForegroundColor))
			end
		end

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.SeasonedCastSize))
			self.Cast:SetStatusBarTexture(Layout.SeasonedCastTexture)
		end

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then
				self.ExtraPower.Fg:SetTexture(Layout.SeasonedManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.SeasonedManaOrbColor)) 
			end 
		end 

	elseif ((playerLevel or UnitLevel("player")) >= Layout.HardenedLevel) then 
		self.Health:SetSize(unpack(Layout.HardenedHealthSize))
		self.Health:SetStatusBarTexture(Layout.HardenedHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.HardenedHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.HardenedHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.HardenedHealthThreatTexture)
			end 
		end 

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.HardenedPowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.HardenedPowerForegroundColor))
			end
		end

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.HardenedCastSize))
			self.Cast:SetStatusBarTexture(Layout.HardenedCastTexture)
		end

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then 
				self.ExtraPower.Fg:SetTexture(Layout.HardenedManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.HardenedManaOrbColor)) 
			end 
		end 

	else 
		self.Health:SetSize(unpack(Layout.NoviceHealthSize))
		self.Health:SetStatusBarTexture(Layout.NoviceHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.NoviceHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.NoviceHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.NoviceHealthThreatTexture)
			end 
		end 

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.NovicePowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.NovicePowerForegroundColor))
			end
		end

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.NoviceCastSize))
			self.Cast:SetStatusBarTexture(Layout.NoviceCastTexture)
		end 

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then 
				self.ExtraPower.Fg:SetTexture(Layout.NoviceManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.NoviceManaOrbColor)) 
			end
		end 

	end 
end 

local Target_Threat_UpdateColor = function(element, unit, status, r, g, b)
	if element.health then 
		element.health:SetVertexColor(r, g, b)
	end
	if element.power then 
		element.power:SetVertexColor(r, g, b)
	end
	if element.portrait then 
		element.portrait:SetVertexColor(r, g, b)
	end 
end

local Target_Threat_IsShown = function(element)
	return element.health and element.health:IsShown()
end 

local Target_Threat_Show = function(element)
	if 	element.health then 
		element.health:Show()
	end
	if 	element.power then 
		element.power:Show()
	end
	if element.portrait then 
		element.portrait:Show()
	end 
end 

local Target_Threat_Hide = function(element)
	if 	element.health then 
		element.health:Hide()
	end 
	if element.power then 
		element.power:Hide()
	end
	if element.portrait then 
		element.portrait:Hide()
	end
end 

local Target_PostUpdateTextures = function(self)
	local Layout = self.layout
	if (not Layout.UseProgressiveFrames) or (not UnitExists("target")) then 
		return
	end 

	local targetStyle

	-- Figure out if the various artwork and bar textures need to be updated
	-- We could put this into element post updates, 
	-- but to avoid needless checks we limit this to actual target updates. 
	local targetLevel = UnitLevel("target") or 0
	local maxLevel = GetEffectiveExpansionMaxLevel()
	local classification = UnitClassification("target")

	if UnitIsPlayer("target") then 
		if ((targetLevel >= maxLevel) or (UnitIsUnit("target", "player") and (not PlayerHasXP()))) then 
			targetStyle = "Seasoned"
		elseif (targetLevel >= Layout.HardenedLevel) then 
			targetStyle = "Hardened"
		else
			targetStyle = "Novice" 
		end 
	elseif ((classification == "worldboss") or (targetLevel < 1)) then 
		targetStyle = "Boss"
	elseif (targetLevel >= maxLevel) then 
		targetStyle = "Seasoned"
	elseif (targetLevel >= Layout.HardenedLevel) then 
		targetStyle = "Hardened"
	elseif (targetLevel == 1) then 
		targetStyle = "Critter"
	else
		targetStyle = "Novice" 
	end 

	-- Silently return if there was no change
	if (targetStyle == self.currentStyle) or (not targetStyle) then 
		return 
	end 

	-- Store the new style
	self.currentStyle = targetStyle

	-- Do this?
	self.progressiveFrameStyle = targetStyle

	if Layout.UseProgressiveHealth then 
		self.Health:Place(unpack(Layout[self.currentStyle.."HealthPlace"]))
		self.Health:SetSize(unpack(Layout[self.currentStyle.."HealthSize"]))
		self.Health:SetStatusBarTexture(Layout[self.currentStyle.."HealthTexture"])
		self.Health:SetSparkMap(Layout[self.currentStyle.."HealthSparkMap"])

		if Layout.UseHealthBackdrop and Layout.UseProgressiveHealthBackdrop then 
			self.Health.Bg:ClearAllPoints()
			self.Health.Bg:SetPoint(unpack(Layout[self.currentStyle.."HealthBackdropPlace"]))
			self.Health.Bg:SetSize(unpack(Layout[self.currentStyle.."HealthBackdropSize"]))
			self.Health.Bg:SetTexture(Layout[self.currentStyle.."HealthBackdropTexture"])
			self.Health.Bg:SetVertexColor(unpack(Layout[self.currentStyle.."HealthBackdropColor"]))
		end

		if Layout.UseHealthValue and Layout[self.currentStyle.."HealthValueVisible"]  then 
			self.Health.Value:Show()
		elseif Layout.UseHealthValue then 
			self.Health.Value:Hide()
		end 

		if Layout.UseHealthPercent and Layout[self.currentStyle.."HealthPercentVisible"]  then 
			self.Health.ValuePercent:Show()
		elseif Layout.UseHealthPercent then 
			self.Health.ValuePercent:Hide()
		end 
	end 

	if Layout.UsePowerBar and Layout.UseProgressivePowerBar then 
		if Layout.UsePowerForeground then 
			self.Power.Fg:SetTexture(Layout[self.currentStyle.."PowerForegroundTexture"])
			self.Power.Fg:SetVertexColor(unpack(Layout[self.currentStyle.."PowerForegroundColor"]))
		end
	end

	if Layout.UseMana and Layout.UseProgressiveMana then 
		self.ExtraPower.Border:SetTexture(Layout[self.currentStyle.."ManaOrbTexture"])
		self.ExtraPower.Border:SetVertexColor(unpack(Layout[self.currentStyle.."ManaOrbColor"])) 
	end 

	if Layout.UseThreat and Layout.UseProgressiveThreat then
		if self.Threat.health then 
			self.Threat.health:SetTexture(Layout[self.currentStyle.."HealthThreatTexture"])
			if Layout[self.currentStyle.."HealthThreatPlace"] then 
				self.Threat.health:ClearAllPoints()
				self.Threat.health:SetPoint(unpack(Layout[self.currentStyle.."HealthThreatPlace"]))
			end 
			if Layout[self.currentStyle.."HealthThreatSize"] then 
				self.Threat.health:SetSize(unpack(Layout[self.currentStyle.."HealthThreatSize"]))
			end 
		end 
	end

	if Layout.UseCastBar and Layout.UseProgressiveCastBar then 
		self.Cast:Place(unpack(Layout[self.currentStyle.."CastPlace"]))
		self.Cast:SetSize(unpack(Layout[self.currentStyle.."CastSize"]))
		self.Cast:SetStatusBarTexture(Layout[self.currentStyle.."CastTexture"])
		self.Cast:SetSparkMap(Layout[self.currentStyle.."CastSparkMap"])
	end 

	if Layout.UsePortrait and Layout.UseProgressivePortrait then 


		if Layout.UsePortraitBackground then 
		end 

		if Layout.UsePortraitShade then 
		end 

		if Layout.UsePortraitForeground then 
			self.Portrait.Fg:SetTexture(Layout[self.currentStyle.."PortraitForegroundTexture"])
			self.Portrait.Fg:SetVertexColor(unpack(Layout[self.currentStyle.."PortraitForegroundColor"]))
		end 
	end 
	
end 

-----------------------------------------------------------
-- Templates
-----------------------------------------------------------
-- Boss, Arena
local positionHeaderFrame = function(self, unit, id, Layout)
	-- Todo: iterate on this for a grid layout
	local id = tonumber(id)
	if id then 
		local place = { unpack(Layout.Place) }
		local growthX = Layout.GrowthX
		local growthY = Layout.GrowthY

		if (growthX and growthY) then 
			if (type(place[#place]) == "number") then 
				place[#place - 1] = place[#place - 1] + growthX*(id-1)
				place[#place] = place[#place] + growthY*(id-1)
			else 
				place[#place + 1] = growthX
				place[#place + 1] = growthY
			end 
		end 
		self:Place(unpack(place))
	else 
		self:Place(unpack(Layout.Place)) 
	end
end

-- Boss, Arena, Pet, Focus, ToT
local StyleSmallFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 

	if (unit:match("^arena(%d+)")) or (unit:match("^boss(%d+)")) then 
		positionHeaderFrame(self, unit, id, Layout)
	else
		self:Place(unpack(Layout.Place)) 
	end 

	if Layout.FrameLevel then 
		self:SetFrameLevel(self:GetFrameLevel() + Layout.FrameLevel)
	end 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	self.colors = Layout.Colors or self.colors
	self.layout = Layout

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)

	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:Place(unpack(Layout.HealthPlace))
	health:SetSmoothingMode(Layout.HealthSmoothingMode or "bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(Layout.HealthSmoothingFrequency or .5) -- set the duration of the smoothing.
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorPetAsPlayer = Layout.HealthColorPetAsPlayer -- color your pet as you
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropColor then 
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
		end
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Power 
	-----------------------------------------------------------
	if Layout.UsePowerBar then 
		local power = backdrop:CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		power.ignoredResource = Layout.PowerIgnoredResource -- make the bar hide when MANA is the primary resource. 

		self.Power = power
		self.Power.OverrideColor = OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the right.
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) -- set the smoothing mode.
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) -- the alpha won't be overwritten. 

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 

	-- Target Highlighting
	-----------------------------------------------------------
	if Layout.UseTargetHighlight then

		-- Add an extra frame to break away from alpha changes
		local owner = (Layout.TargetHighlightParent and self[Layout.TargetHighlightParent] or self)
		local targetHighlightFrame = CreateFrame("Frame", nil, owner)
		targetHighlightFrame:SetAllPoints()
		targetHighlightFrame:SetIgnoreParentAlpha(true)

		local targetHighlight = targetHighlightFrame:CreateTexture()
		targetHighlight:SetDrawLayer(unpack(Layout.TargetHighlightDrawLayer))
		targetHighlight:SetSize(unpack(Layout.TargetHighlightSize))
		targetHighlight:SetPoint(unpack(Layout.TargetHighlightPlace))
		targetHighlight:SetTexture(Layout.TargetHighlightTexture)
		targetHighlight.showFocus = Layout.TargetHighlightShowFocus
		targetHighlight.colorFocus = Layout.TargetHighlightFocusColor
		targetHighlight.showTarget = Layout.TargetHighlightShowTarget
		targetHighlight.colorTarget = Layout.TargetHighlightTargetColor

		self.TargetHighlight = targetHighlight
	end

	-- Unit Status
	-----------------------------------------------------------
	if Layout.UseUnitStatus then 
		local unitStatus = overlay:CreateFontString()
		unitStatus:SetPoint(unpack(Layout.UnitStatusPlace))
		unitStatus:SetDrawLayer(unpack(Layout.UnitStatusDrawLayer))
		unitStatus:SetJustifyH(Layout.UnitStatusJustifyH)
		unitStatus:SetJustifyV(Layout.UnitStatusJustifyV)
		unitStatus:SetFontObject(Layout.UnitStatusFont)
		unitStatus:SetTextColor(unpack(Layout.UnitStatusColor))
		unitStatus.hideAFK = Layout.UnitStatusHideAFK
		unitStatus.hideDead = Layout.UnitStatusHideDead
		unitStatus.hideOffline = Layout.UnitStatusHideOffline
		unitStatus.afkMsg = Layout.UseUnitStatusMessageAFK
		unitStatus.deadMsg = Layout.UseUnitStatusMessageDead
		unitStatus.offlineMsg = Layout.UseUnitStatusMessageDC
		unitStatus.oomMsg = Layout.UseUnitStatusMessageOOM
		if Layout.UnitStatusSize then 
			unitStatus:SetSize(unpack(Layout.UnitStatusSize))
		end 
		self.UnitStatus = unitStatus
		self.UnitStatus.PostUpdate = Layout.UnitStatusPostUpdate
	end 
		
	-- Auras
	-----------------------------------------------------------
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
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
			
		self.Auras = auras
		self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.buffFilterString = Layout.buffFilterFunc -- buff specific filter passed to blizzard API calls
		buffs.buffFilterFunc = Layout.buffFilterFuncFunc -- buff specific filter function
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		self.Buffs = buffs
		self.Buffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilterString = Layout.debuffFilterFunc -- debuff specific filter passed to blizzard API calls
		debuffs.debuffFilterFunc = Layout.debuffFilterFuncFunc -- debuff specific filter function
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
			
		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameJustifyH)
		name:SetJustifyV(Layout.NameJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		healthVal.showPercent = Layout.HealthShowPercent

		if Layout.UseHealthPercent then 
			local healthPerc = health:CreateFontString()
			healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
			healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
			healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
			healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
			healthPerc:SetFontObject(Layout.HealthPercentFont)
			healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
			self.Health.ValuePercent = healthPerc
		end 
		
		self.Health.Value = healthVal
		self.Health.ValuePercent = healthPerc
		self.Health.OverrideValue = Layout.HealthValueOverride or SmallFrame_OverrideHealthValue
	end 

	-- Cast Name
	if Layout.UseCastBar then
		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			self.Cast.Name = name
		end 
	end

	-- Absorb Value
	if Layout.UseAbsorbValue then 
		local absorbVal = overlay:CreateFontString()
		if Layout.AbsorbValuePlaceFunction then 
			absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
		else 
			absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
		end 
		absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
		absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
		absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
		absorbVal:SetFontObject(Layout.AbsorbValueFont)
		absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
		self.Health.ValueAbsorb = absorbVal 
		self.Health.ValueAbsorb.Override = SmallFrame_OverrideValue
	end 

	if (Layout.HideWhenUnitIsPlayer or Layout.HideWhenTargetIsCritter or Layout.HideWhenUnitIsTarget) then 
		self.hideWhenUnitIsPlayer = Layout.HideWhenUnitIsPlayer
		self.hideWhenUnitIsTarget = Layout.HideWhenUnitIsTarget
		self.hideWhenTargetIsCritter = Layout.HideWhenTargetIsCritter
		self.PostUpdate = SmallFrame_PostUpdateAlpha
		self:RegisterEvent("PLAYER_TARGET_CHANGED", SmallFrame_PostUpdateAlpha, true)
	end 

end

-- Party
local StylePartyFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 

	if Layout.FrameLevel then 
		self:SetFrameLevel(self:GetFrameLevel() + Layout.FrameLevel)
	end 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Layout.Colors or self.colors
	self.layout = Layout

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)


	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:Place(unpack(Layout.HealthPlace))
	health:SetSmartSmoothing(true)
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorPetAsPlayer = Layout.HealthColorPetAsPlayer -- color your pet as you
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate

	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropColor then 
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
		end
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Portrait
	-----------------------------------------------------------
	if Layout.UsePortrait then 
		local portrait = backdrop:CreateFrame("PlayerModel")
		portrait:SetPoint(unpack(Layout.PortraitPlace))
		portrait:SetSize(unpack(Layout.PortraitSize)) 
		portrait:SetAlpha(Layout.PortraitAlpha)
		portrait.distanceScale = Layout.PortraitDistanceScale
		portrait.positionX = Layout.PortraitPositionX
		portrait.positionY = Layout.PortraitPositionY
		portrait.positionZ = Layout.PortraitPositionZ
		portrait.rotation = Layout.PortraitRotation -- in degrees
		portrait.showFallback2D = Layout.PortraitShowFallback2D -- display 2D portraits when unit is out of range of 3D models
		self.Portrait = portrait
		
		-- To allow the backdrop and overlay to remain 
		-- visible even with no visible player model, 
		-- we add them to our backdrop and overlay frames, 
		-- not to the portrait frame itself.  
		if Layout.UsePortraitBackground then 
			local portraitBg = backdrop:CreateTexture()
			portraitBg:SetPoint(unpack(Layout.PortraitBackgroundPlace))
			portraitBg:SetSize(unpack(Layout.PortraitBackgroundSize))
			portraitBg:SetTexture(Layout.PortraitBackgroundTexture)
			portraitBg:SetDrawLayer(unpack(Layout.PortraitBackgroundDrawLayer))
			portraitBg:SetVertexColor(unpack(Layout.PortraitBackgroundColor))
			self.Portrait.Bg = portraitBg
		end 

		if Layout.UsePortraitShade then 
			local portraitShade = content:CreateTexture()
			portraitShade:SetPoint(unpack(Layout.PortraitShadePlace))
			portraitShade:SetSize(unpack(Layout.PortraitShadeSize)) 
			portraitShade:SetTexture(Layout.PortraitShadeTexture)
			portraitShade:SetDrawLayer(unpack(Layout.PortraitShadeDrawLayer))
			self.Portrait.Shade = portraitShade
		end 

		if Layout.UsePortraitForeground then 
			local portraitFg = content:CreateTexture()
			portraitFg:SetPoint(unpack(Layout.PortraitForegroundPlace))
			portraitFg:SetSize(unpack(Layout.PortraitForegroundSize))
			portraitFg:SetTexture(Layout.PortraitForegroundTexture)
			portraitFg:SetDrawLayer(unpack(Layout.PortraitForegroundDrawLayer))
			portraitFg:SetVertexColor(unpack(Layout.PortraitForegroundColor))
			self.Portrait.Fg = portraitFg
		end 
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the right.
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) -- set the smoothing mode.
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) -- the alpha won't be overwritten. 

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 

	-- Group Debuff
	-----------------------------------------------------------
	if Layout.UseGroupAura then 
		local groupAura = overlay:CreateFrame("Button")
		groupAura:SetFrameLevel(overlay:GetFrameLevel() - 4)
		groupAura:SetPoint(unpack(Layout.GroupAuraPlace))
		groupAura:SetSize(unpack(Layout.GroupAuraSize))
		groupAura.disableMouse = Layout.GroupAuraButtonDisableMouse
		groupAura.tooltipDefaultPosition = Layout.GroupAuraTooltipDefaultPosition
		groupAura.tooltipPoint = Layout.GroupAuraTooltipPoint
		groupAura.tooltipAnchor = Layout.GroupAuraTooltipAnchor
		groupAura.tooltipRelPoint = Layout.GroupAuraTooltipRelPoint
		groupAura.tooltipOffsetX = Layout.GroupAuraTooltipOffsetX
		groupAura.tooltipOffsetY = Layout.GroupAuraTooltipOffsetY

		local icon = groupAura:CreateTexture()
		icon:SetPoint(unpack(Layout.GroupAuraButtonIconPlace))
		icon:SetSize(unpack(Layout.GroupAuraButtonIconSize))
		icon:SetTexCoord(unpack(Layout.GroupAuraButtonIconTexCoord))
		icon:SetDrawLayer("ARTWORK", 1)
		groupAura.Icon = icon

		-- Frame to contain art overlays, texts, etc
		local overlay = groupAura:CreateFrame("Frame")
		overlay:SetFrameLevel(groupAura:GetFrameLevel() + 3)
		overlay:SetAllPoints(groupAura)
		groupAura.Overlay = overlay

		-- Cooldown frame
		local cooldown = groupAura:CreateFrame("Cooldown", nil, groupAura, "CooldownFrameTemplate")
		cooldown:Hide()
		cooldown:SetAllPoints(groupAura)
		cooldown:SetFrameLevel(groupAura:GetFrameLevel() + 1)
		cooldown:SetReverse(false)
		cooldown:SetSwipeColor(0, 0, 0, .75)
		cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
		cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
		cooldown:SetDrawSwipe(true)
		cooldown:SetDrawBling(true)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(true) 
		groupAura.Cooldown = cooldown

		local time = overlay:CreateFontString()
		time:SetDrawLayer("ARTWORK", 1)
		time:SetPoint(unpack(Layout.GroupAuraButtonTimePlace))
		time:SetFontObject(Layout.GroupAuraButtonTimeFont)
		time:SetJustifyH("CENTER")
		time:SetJustifyV("MIDDLE")
		time:SetTextColor(unpack(Layout.GroupAuraButtonTimeColor))
		groupAura.Time = time
	
		local count = overlay:CreateFontString()
		count:SetDrawLayer("OVERLAY", 1)
		count:SetPoint(unpack(Layout.GroupAuraButtonCountPlace))
		count:SetFontObject(Layout.GroupAuraButtonCountFont)
		count:SetJustifyH("CENTER")
		count:SetJustifyV("MIDDLE")
		count:SetTextColor(unpack(Layout.GroupAuraButtonCountColor))
		groupAura.Count = count
	
		local border = groupAura:CreateFrame("Frame")
		border:SetFrameLevel(groupAura:GetFrameLevel() + 2)
		border:SetPoint(unpack(Layout.GroupAuraButtonBorderFramePlace))
		border:SetSize(unpack(Layout.GroupAuraButtonBorderFrameSize))
		border:SetBackdrop(Layout.GroupAuraButtonBorderBackdrop)
		border:SetBackdropColor(unpack(Layout.GroupAuraButtonBorderBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.GroupAuraButtonBorderBackdropBorderColor))
		groupAura.Border = border 

		self.GroupAura = groupAura
		self.GroupAura.PostUpdate = Layout.GroupAuraPostUpdate
	end 

	-- Group Role
	-----------------------------------------------------------
	if Layout.UseGroupRole then 
		local groupRole = overlay:CreateFrame()
		groupRole:SetPoint(unpack(Layout.GroupRolePlace))
		groupRole:SetSize(unpack(Layout.GroupRoleSize))
		self.GroupRole = groupRole

		if Layout.UseGroupRoleBackground then 
			local groupRoleBg = groupRole:CreateTexture()
			groupRoleBg:SetDrawLayer(unpack(Layout.GroupRoleBackgroundDrawLayer))
			groupRoleBg:SetTexture(Layout.GroupRoleBackgroundTexture)
			groupRoleBg:SetVertexColor(unpack(Layout.GroupRoleBackgroundColor))
			groupRoleBg:SetSize(unpack(Layout.GroupRoleBackgroundSize))
			groupRoleBg:SetPoint(unpack(Layout.GroupRoleBackgroundPlace))
			self.GroupRole.Bg = groupRoleBg
		end 

		if Layout.UseGroupRoleHealer then 
			local roleHealer = groupRole:CreateTexture()
			roleHealer:SetPoint(unpack(Layout.GroupRoleHealerPlace))
			roleHealer:SetSize(unpack(Layout.GroupRoleHealerSize))
			roleHealer:SetDrawLayer(unpack(Layout.GroupRoleHealerDrawLayer))
			roleHealer:SetTexture(Layout.GroupRoleHealerTexture)
			self.GroupRole.Healer = roleHealer 
		end 

		if Layout.UseGroupRoleTank then 
			local roleTank = groupRole:CreateTexture()
			roleTank:SetPoint(unpack(Layout.GroupRoleTankPlace))
			roleTank:SetSize(unpack(Layout.GroupRoleTankSize))
			roleTank:SetDrawLayer(unpack(Layout.GroupRoleTankDrawLayer))
			roleTank:SetTexture(Layout.GroupRoleTankTexture)
			self.GroupRole.Tank = roleTank 
		end 

		if Layout.UseGroupRoleDPS then 
			local roleDPS = groupRole:CreateTexture()
			roleDPS:SetPoint(unpack(Layout.GroupRoleDPSPlace))
			roleDPS:SetSize(unpack(Layout.GroupRoleDPSSize))
			roleDPS:SetDrawLayer(unpack(Layout.GroupRoleDPSDrawLayer))
			roleDPS:SetTexture(Layout.GroupRoleDPSTexture)
			self.GroupRole.Damager = roleDPS 
		end 
	end

	-- Range
	-----------------------------------------------------------
	if Layout.UseRange then 
		self.Range = { outsideAlpha = Layout.RangeOutsideAlpha }
	end 

		-- Resurrection Indicator
	-----------------------------------------------------------
	if Layout.UseResurrectIndicator then 
		local rezIndicator = overlay:CreateTexture()
		rezIndicator:SetPoint(unpack(Layout.ResurrectIndicatorPlace))
		rezIndicator:SetSize(unpack(Layout.ResurrectIndicatorSize))
		rezIndicator:SetDrawLayer(unpack(Layout.ResurrectIndicatorDrawLayer))
		self.ResurrectIndicator = rezIndicator
		self.ResurrectIndicator.PostUpdate = Layout.ResurrectIndicatorPostUpdate
	end

	-- Ready Check
	-----------------------------------------------------------
	if Layout.UseReadyCheck then 
		local readyCheck = overlay:CreateTexture()
		readyCheck:SetPoint(unpack(Layout.ReadyCheckPlace))
		readyCheck:SetSize(unpack(Layout.ReadyCheckSize))
		readyCheck:SetDrawLayer(unpack(Layout.ReadyCheckDrawLayer))
		self.ReadyCheck = readyCheck
		self.ReadyCheck.PostUpdate = Layout.ReadyCheckPostUpdate
	end 

	-- Unit Status
	-----------------------------------------------------------
	if Layout.UseUnitStatus then 
		local unitStatus = overlay:CreateFontString()
		unitStatus:SetPoint(unpack(Layout.UnitStatusPlace))
		unitStatus:SetDrawLayer(unpack(Layout.UnitStatusDrawLayer))
		unitStatus:SetJustifyH(Layout.UnitStatusJustifyH)
		unitStatus:SetJustifyV(Layout.UnitStatusJustifyV)
		unitStatus:SetFontObject(Layout.UnitStatusFont)
		unitStatus:SetTextColor(unpack(Layout.UnitStatusColor))
		unitStatus.hideAFK = Layout.UnitStatusHideAFK
		unitStatus.hideDead = Layout.UnitStatusHideDead
		unitStatus.hideOffline = Layout.UnitStatusHideOffline
		unitStatus.afkMsg = Layout.UseUnitStatusMessageAFK
		unitStatus.deadMsg = Layout.UseUnitStatusMessageDead
		unitStatus.offlineMsg = Layout.UseUnitStatusMessageDC
		unitStatus.oomMsg = Layout.UseUnitStatusMessageOOM
		if Layout.UnitStatusSize then 
			unitStatus:SetSize(unpack(Layout.UnitStatusSize))
		end 
		self.UnitStatus = unitStatus
		self.UnitStatus.PostUpdate = Layout.UnitStatusPostUpdate
	end 

	-- Auras
	-----------------------------------------------------------
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
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
			
		self.Auras = auras
		self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.buffFilterString = Layout.buffFilterFunc -- buff specific filter passed to blizzard API calls
		buffs.buffFilterFunc = Layout.buffFilterFuncFunc -- buff specific filter function
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		self.Buffs = buffs
		self.Buffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilterString = Layout.debuffFilterFunc -- debuff specific filter passed to blizzard API calls
		debuffs.debuffFilterFunc = Layout.debuffFilterFuncFunc -- debuff specific filter function
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
			
		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 	

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameJustifyH)
		name:SetJustifyV(Layout.NameJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		healthVal.showPercent = Layout.HealthShowPercent

		if Layout.UseHealthPercent then 
			local healthPerc = health:CreateFontString()
			healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
			healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
			healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
			healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
			healthPerc:SetFontObject(Layout.HealthPercentFont)
			healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
			self.Health.ValuePercent = healthPerc
		end 
		
		self.Health.Value = healthVal
		self.Health.ValuePercent = healthPerc
		self.Health.OverrideValue = Layout.HealthValueOverride or TinyFrame_OverrideHealthValue

		-- Health Value Callback
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", TinyFrame_OnEvent)
	end 

	-- Cast Name
	if Layout.UseCastBar then
		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			self.Cast.Name = name
		end 
	end

	-- Absorb Value
	if Layout.UseAbsorbValue then 
		local absorbVal = overlay:CreateFontString()
		if Layout.AbsorbValuePlaceFunction then 
			absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
		else 
			absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
		end 
		absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
		absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
		absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
		absorbVal:SetFontObject(Layout.AbsorbValueFont)
		absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
		self.Health.ValueAbsorb = absorbVal 
		self.Health.ValueAbsorb.Override = TinyFrame_OverrideValue
	end 

	-- Target Highlighting
	-----------------------------------------------------------
	if Layout.UseTargetHighlight then

		-- Add an extra frame to break away from alpha changes
		local owner = (Layout.TargetHighlightParent and self[Layout.TargetHighlightParent] or self)
		local targetHighlightFrame = CreateFrame("Frame", nil, owner)
		targetHighlightFrame:SetAllPoints()
		targetHighlightFrame:SetIgnoreParentAlpha(true)
	
		local targetHighlight = targetHighlightFrame:CreateTexture()
		targetHighlight:SetDrawLayer(unpack(Layout.TargetHighlightDrawLayer))
		targetHighlight:SetSize(unpack(Layout.TargetHighlightSize))
		targetHighlight:SetPoint(unpack(Layout.TargetHighlightPlace))
		targetHighlight:SetTexture(Layout.TargetHighlightTexture)
		targetHighlight.showFocus = Layout.TargetHighlightShowFocus
		targetHighlight.colorFocus = Layout.TargetHighlightFocusColor
		targetHighlight.showTarget = Layout.TargetHighlightShowTarget
		targetHighlight.colorTarget = Layout.TargetHighlightTargetColor

		self.TargetHighlight = targetHighlight
	end


end

-- Raid
local StyleRaidFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 

	if Layout.FrameLevel then 
		self:SetFrameLevel(self:GetFrameLevel() + Layout.FrameLevel)
	end 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Layout.Colors or self.colors
	self.layout = Layout


	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)


	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:Place(unpack(Layout.HealthPlace))
	health:SetSmartSmoothing(true)
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorPetAsPlayer = Layout.HealthColorPetAsPlayer -- color your pet as you
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropColor then 
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
		end
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Portrait
	-----------------------------------------------------------
	if Layout.UsePortrait then 
		local portrait = backdrop:CreateFrame("PlayerModel")
		portrait:SetPoint(unpack(Layout.PortraitPlace))
		portrait:SetSize(unpack(Layout.PortraitSize)) 
		portrait:SetAlpha(Layout.PortraitAlpha)
		portrait.distanceScale = Layout.PortraitDistanceScale
		portrait.positionX = Layout.PortraitPositionX
		portrait.positionY = Layout.PortraitPositionY
		portrait.positionZ = Layout.PortraitPositionZ
		portrait.rotation = Layout.PortraitRotation -- in degrees
		portrait.showFallback2D = Layout.PortraitShowFallback2D -- display 2D portraits when unit is out of range of 3D models
		self.Portrait = portrait
		
		-- To allow the backdrop and overlay to remain 
		-- visible even with no visible player model, 
		-- we add them to our backdrop and overlay frames, 
		-- not to the portrait frame itself.  
		if Layout.UsePortraitBackground then 
			local portraitBg = backdrop:CreateTexture()
			portraitBg:SetPoint(unpack(Layout.PortraitBackgroundPlace))
			portraitBg:SetSize(unpack(Layout.PortraitBackgroundSize))
			portraitBg:SetTexture(Layout.PortraitBackgroundTexture)
			portraitBg:SetDrawLayer(unpack(Layout.PortraitBackgroundDrawLayer))
			portraitBg:SetVertexColor(unpack(Layout.PortraitBackgroundColor))
			self.Portrait.Bg = portraitBg
		end 

		if Layout.UsePortraitShade then 
			local portraitShade = content:CreateTexture()
			portraitShade:SetPoint(unpack(Layout.PortraitShadePlace))
			portraitShade:SetSize(unpack(Layout.PortraitShadeSize)) 
			portraitShade:SetTexture(Layout.PortraitShadeTexture)
			portraitShade:SetDrawLayer(unpack(Layout.PortraitShadeDrawLayer))
			self.Portrait.Shade = portraitShade
		end 

		if Layout.UsePortraitForeground then 
			local portraitFg = content:CreateTexture()
			portraitFg:SetPoint(unpack(Layout.PortraitForegroundPlace))
			portraitFg:SetSize(unpack(Layout.PortraitForegroundSize))
			portraitFg:SetTexture(Layout.PortraitForegroundTexture)
			portraitFg:SetDrawLayer(unpack(Layout.PortraitForegroundDrawLayer))
			portraitFg:SetVertexColor(unpack(Layout.PortraitForegroundColor))
			self.Portrait.Fg = portraitFg
		end 
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the right.
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) -- set the smoothing mode.
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) -- the alpha won't be overwritten. 

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 

	-- Group Debuff
	-----------------------------------------------------------
	if Layout.UseGroupAura then 
		local groupAura = overlay:CreateFrame("Button")
		groupAura:SetFrameLevel(overlay:GetFrameLevel() - 4)
		groupAura:SetPoint(unpack(Layout.GroupAuraPlace))
		groupAura:SetSize(unpack(Layout.GroupAuraSize))
		groupAura.disableMouse = Layout.GroupAuraButtonDisableMouse
		groupAura.tooltipDefaultPosition = Layout.GroupAuraTooltipDefaultPosition
		groupAura.tooltipPoint = Layout.GroupAuraTooltipPoint
		groupAura.tooltipAnchor = Layout.GroupAuraTooltipAnchor
		groupAura.tooltipRelPoint = Layout.GroupAuraTooltipRelPoint
		groupAura.tooltipOffsetX = Layout.GroupAuraTooltipOffsetX
		groupAura.tooltipOffsetY = Layout.GroupAuraTooltipOffsetY

		local icon = groupAura:CreateTexture()
		icon:SetPoint(unpack(Layout.GroupAuraButtonIconPlace))
		icon:SetSize(unpack(Layout.GroupAuraButtonIconSize))
		icon:SetTexCoord(unpack(Layout.GroupAuraButtonIconTexCoord))
		icon:SetDrawLayer("ARTWORK", 1)
		groupAura.Icon = icon

		-- Frame to contain art overlays, texts, etc
		local overlay = groupAura:CreateFrame("Frame")
		overlay:SetFrameLevel(groupAura:GetFrameLevel() + 3)
		overlay:SetAllPoints(groupAura)
		groupAura.Overlay = overlay

		-- Cooldown frame
		local cooldown = groupAura:CreateFrame("Cooldown", nil, groupAura, "CooldownFrameTemplate")
		cooldown:Hide()
		cooldown:SetAllPoints(groupAura)
		cooldown:SetFrameLevel(groupAura:GetFrameLevel() + 1)
		cooldown:SetReverse(false)
		cooldown:SetSwipeColor(0, 0, 0, .75)
		cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
		cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
		cooldown:SetDrawSwipe(true)
		cooldown:SetDrawBling(true)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(true) 
		groupAura.Cooldown = cooldown
		
		local time = overlay:CreateFontString()
		time:SetDrawLayer("ARTWORK", 1)
		time:SetPoint(unpack(Layout.GroupAuraButtonTimePlace))
		time:SetFontObject(Layout.GroupAuraButtonTimeFont)
		time:SetJustifyH("CENTER")
		time:SetJustifyV("MIDDLE")
		time:SetTextColor(unpack(Layout.GroupAuraButtonTimeColor))
		groupAura.Time = time
	
		local count = overlay:CreateFontString()
		count:SetDrawLayer("OVERLAY", 1)
		count:SetPoint(unpack(Layout.GroupAuraButtonCountPlace))
		count:SetFontObject(Layout.GroupAuraButtonCountFont)
		count:SetJustifyH("CENTER")
		count:SetJustifyV("MIDDLE")
		count:SetTextColor(unpack(Layout.GroupAuraButtonCountColor))
		groupAura.Count = count
	
		local border = groupAura:CreateFrame("Frame")
		border:SetFrameLevel(groupAura:GetFrameLevel() + 2)
		border:SetPoint(unpack(Layout.GroupAuraButtonBorderFramePlace))
		border:SetSize(unpack(Layout.GroupAuraButtonBorderFrameSize))
		border:SetBackdrop(Layout.GroupAuraButtonBorderBackdrop)
		border:SetBackdropColor(unpack(Layout.GroupAuraButtonBorderBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.GroupAuraButtonBorderBackdropBorderColor))
		groupAura.Border = border 

		self.GroupAura = groupAura
		self.GroupAura.PostUpdate = Layout.GroupAuraPostUpdate
	end 

	-- Group Role
	-----------------------------------------------------------
	if Layout.UseGroupRole then 
		local groupRole = overlay:CreateFrame()
		groupRole:SetPoint(unpack(Layout.GroupRolePlace))
		groupRole:SetSize(unpack(Layout.GroupRoleSize))
		self.GroupRole = groupRole
		self.GroupRole.PostUpdate = Layout.GroupRolePostUpdate

		if Layout.UseGroupRoleBackground then 
			local groupRoleBg = groupRole:CreateTexture()
			groupRoleBg:SetDrawLayer(unpack(Layout.GroupRoleBackgroundDrawLayer))
			groupRoleBg:SetTexture(Layout.GroupRoleBackgroundTexture)
			groupRoleBg:SetVertexColor(unpack(Layout.GroupRoleBackgroundColor))
			groupRoleBg:SetSize(unpack(Layout.GroupRoleBackgroundSize))
			groupRoleBg:SetPoint(unpack(Layout.GroupRoleBackgroundPlace))
			self.GroupRole.Bg = groupRoleBg
		end 

		if Layout.UseGroupRoleHealer then 
			local roleHealer = groupRole:CreateTexture()
			roleHealer:SetPoint(unpack(Layout.GroupRoleHealerPlace))
			roleHealer:SetSize(unpack(Layout.GroupRoleHealerSize))
			roleHealer:SetDrawLayer(unpack(Layout.GroupRoleHealerDrawLayer))
			roleHealer:SetTexture(Layout.GroupRoleHealerTexture)
			self.GroupRole.Healer = roleHealer 
		end 

		if Layout.UseGroupRoleTank then 
			local roleTank = groupRole:CreateTexture()
			roleTank:SetPoint(unpack(Layout.GroupRoleTankPlace))
			roleTank:SetSize(unpack(Layout.GroupRoleTankSize))
			roleTank:SetDrawLayer(unpack(Layout.GroupRoleTankDrawLayer))
			roleTank:SetTexture(Layout.GroupRoleTankTexture)
			self.GroupRole.Tank = roleTank 
		end 

		if Layout.UseGroupRoleDPS then 
			local roleDPS = groupRole:CreateTexture()
			roleDPS:SetPoint(unpack(Layout.GroupRoleDPSPlace))
			roleDPS:SetSize(unpack(Layout.GroupRoleDPSSize))
			roleDPS:SetDrawLayer(unpack(Layout.GroupRoleDPSDrawLayer))
			roleDPS:SetTexture(Layout.GroupRoleDPSTexture)
			self.GroupRole.Damager = roleDPS 
		end 
	end

	-- Resurrection Indicator
	-----------------------------------------------------------
	if Layout.UseResurrectIndicator then 
		local rezIndicator = overlay:CreateTexture()
		rezIndicator:SetPoint(unpack(Layout.ResurrectIndicatorPlace))
		rezIndicator:SetSize(unpack(Layout.ResurrectIndicatorSize))
		rezIndicator:SetDrawLayer(unpack(Layout.ResurrectIndicatorDrawLayer))
		self.ResurrectIndicator = rezIndicator
		self.ResurrectIndicator.PostUpdate = Layout.ResurrectIndicatorPostUpdate
	end

	-- Ready Check
	-----------------------------------------------------------
	if Layout.UseReadyCheck then 
		local readyCheck = overlay:CreateTexture()
		readyCheck:SetPoint(unpack(Layout.ReadyCheckPlace))
		readyCheck:SetSize(unpack(Layout.ReadyCheckSize))
		readyCheck:SetDrawLayer(unpack(Layout.ReadyCheckDrawLayer))
		self.ReadyCheck = readyCheck
		self.ReadyCheck.PostUpdate = Layout.ReadyCheckPostUpdate
	end 

	-- Range
	-----------------------------------------------------------
	if Layout.UseRange then 
		self.Range = { outsideAlpha = Layout.RangeOutsideAlpha }
	end 

	-- Target Highlighting
	-----------------------------------------------------------
	if Layout.UseTargetHighlight then

		-- Add an extra frame to break away from alpha changes
		local owner = (Layout.TargetHighlightParent and self[Layout.TargetHighlightParent] or self)
		local targetHighlightFrame = CreateFrame("Frame", nil, owner)
		targetHighlightFrame:SetAllPoints()
		targetHighlightFrame:SetIgnoreParentAlpha(true)

		local targetHighlight = targetHighlightFrame:CreateTexture()
		targetHighlight:SetDrawLayer(unpack(Layout.TargetHighlightDrawLayer))
		targetHighlight:SetSize(unpack(Layout.TargetHighlightSize))
		targetHighlight:SetPoint(unpack(Layout.TargetHighlightPlace))
		targetHighlight:SetTexture(Layout.TargetHighlightTexture)
		targetHighlight.showFocus = Layout.TargetHighlightShowFocus
		targetHighlight.colorFocus = Layout.TargetHighlightFocusColor
		targetHighlight.showTarget = Layout.TargetHighlightShowTarget
		targetHighlight.colorTarget = Layout.TargetHighlightTargetColor

		self.TargetHighlight = targetHighlight
	end

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameJustifyH)
		name:SetJustifyV(Layout.NameJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		name.maxChars = Layout.NameMaxChars
		name.useDots = Layout.NameUseDots
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Unit Status
	if Layout.UseUnitStatus then 
		local unitStatus = overlay:CreateFontString()
		unitStatus:SetPoint(unpack(Layout.UnitStatusPlace))
		unitStatus:SetDrawLayer(unpack(Layout.UnitStatusDrawLayer))
		unitStatus:SetJustifyH(Layout.UnitStatusJustifyH)
		unitStatus:SetJustifyV(Layout.UnitStatusJustifyV)
		unitStatus:SetFontObject(Layout.UnitStatusFont)
		unitStatus:SetTextColor(unpack(Layout.UnitStatusColor))
		unitStatus.hideAFK = Layout.UnitStatusHideAFK
		unitStatus.hideDead = Layout.UnitStatusHideDead
		unitStatus.hideOffline = Layout.UnitStatusHideOffline
		unitStatus.afkMsg = Layout.UseUnitStatusMessageAFK
		unitStatus.deadMsg = Layout.UseUnitStatusMessageDead
		unitStatus.offlineMsg = Layout.UseUnitStatusMessageDC
		unitStatus.oomMsg = Layout.UseUnitStatusMessageOOM
		if Layout.UnitStatusSize then 
			unitStatus:SetSize(unpack(Layout.UnitStatusSize))
		end 
		self.UnitStatus = unitStatus
		self.UnitStatus.PostUpdate = Layout.UnitStatusPostUpdate
	end 
	
	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		healthVal.showPercent = Layout.HealthShowPercent

		if Layout.UseHealthPercent then 
			local healthPerc = health:CreateFontString()
			healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
			healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
			healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
			healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
			healthPerc:SetFontObject(Layout.HealthPercentFont)
			healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
			self.Health.ValuePercent = healthPerc
		end 
		
		self.Health.Value = healthVal
		self.Health.ValuePercent = healthPerc
		self.Health.OverrideValue = Layout.HealthValueOverride or TinyFrame_OverrideHealthValue
	end 

	-- Cast Name
	if Layout.UseCastBar then
		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			self.Cast.Name = name
		end 
	end

	-- Absorb Value
	if Layout.UseAbsorbValue then 
		local absorbVal = overlay:CreateFontString()
		if Layout.AbsorbValuePlaceFunction then 
			absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
		else 
			absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
		end 
		absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
		absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
		absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
		absorbVal:SetFontObject(Layout.AbsorbValueFont)
		absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
		self.Health.ValueAbsorb = absorbVal 
		self.Health.ValueAbsorb.Override = TinyFrame_OverrideValue
	end 

	if Layout.UseHealthValue then 
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", TinyFrame_OnEvent)
	end

	-- Raid Role
	if Layout.UseRaidRole then 
		local raidRole = overlay:CreateTexture()
		if Layout.RaidRoleAnchor and Layout.RaidRolePoint then 
			raidRole:SetPoint(Layout.RaidRolePoint, self[Layout.RaidRoleAnchor], unpack(Layout.RaidRolePlace))
		else 
			raidRole:SetPoint(unpack(Layout.RaidRolePlace))
		end 
		raidRole:SetSize(unpack(Layout.RaidRoleSize))
		raidRole:SetDrawLayer(unpack(Layout.RaidRoleDrawLayer))
		raidRole.roleTextures = { RAIDTARGET = Layout.RaidRoleRaidTargetTexture }
		self.RaidRole = raidRole
	end 

	-- Raid Target
	if Layout.UseRaidTarget then 
		local raidTarget = overlay:CreateTexture()
		raidTarget:SetPoint(unpack(Layout.RaidTargetPlace))
		raidTarget:SetSize(unpack(Layout.RaidTargetSize))
		raidTarget:SetDrawLayer(unpack(Layout.RaidTargetDrawLayer))
		raidTarget:SetTexture(Layout.RaidTargetTexture)
		
		self.RaidTarget = raidTarget
		self.RaidTarget.PostUpdate = Layout.PostUpdateRaidTarget
	end 

end

-----------------------------------------------------------
-- Singular Unit Styling
-----------------------------------------------------------
UnitStyles.StylePlayerFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 
	if Layout.ExplorerHitRects then 
		local topOffset, bottomOffset, leftOffset, rightOffset = unpack(Layout.ExplorerHitRects)
		self.GetExplorerHitRects = function(self)
			return topOffset, bottomOffset, leftOffset, rightOffset
		end 
	end 

	self.colors = Layout.Colors or self.colors
	self.layout = Layout

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)

	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:Place(unpack(Layout.HealthPlace))
	health:SetSmartSmoothing(true)
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates
	health.predictThreshold = .01
	self.Health = health
	self.Health.PostUpdate = Layout.CastBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBgHolder = health:CreateFrame("Frame")
		healthBgHolder:SetAllPoints()
		healthBgHolder:SetFrameLevel(health:GetFrameLevel()-2)

		local healthBg = healthBgHolder:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Power 
	-----------------------------------------------------------
	if Layout.UsePowerBar then 
		local power = backdrop:CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.
		power.frequent = true

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		power.ignoredResource = Layout.PowerIgnoredResource -- make the bar hide when MANA is the primary resource. 

		self.Power = power
		self.Power.OverrideColor = Player_OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end

		if Layout.UseWinterVeilPower then 
			local day = tonumber(date("%d"))
			local month = tonumber(date("%m"))
			if ((month >= 12) and (day >=16 )) or ((month <= 1) and (day <= 2)) then 
				local winterVeilPower = power:CreateTexture()
				winterVeilPower:SetSize(unpack(Layout.WinterVeilPowerSize))
				winterVeilPower:SetPoint(unpack(Layout.WinterVeilPowerPlace))
				winterVeilPower:SetDrawLayer(unpack(Layout.WinterVeilPowerDrawLayer))
				winterVeilPower:SetTexture(Layout.WinterVeilPowerTexture)
				winterVeilPower:SetVertexColor(unpack(Layout.WinterVeilPowerColor))
				self.Power.WinterVeil = winterVeilPower
			end
		end 
	end 

	-- Mana Orb
	-----------------------------------------------------------
	-- Only create this for actual mana classes
	local hasMana = (PlayerClass == "DRUID") or (PlayerClass == "MONK")  or (PlayerClass == "PALADIN")
				 or (PlayerClass == "SHAMAN") or (PlayerClass == "PRIEST")
				 or (PlayerClass == "MAGE") or (PlayerClass == "WARLOCK") 

	if Layout.UseMana then 
		if hasMana then 

			local extraPower 
			if (Layout.ManaType == "Orb") then 
				extraPower = backdrop:CreateOrb()
				extraPower:SetStatusBarTexture(unpack(Layout.ManaOrbTextures)) 

			elseif (Layout.ManaType == "SpinBar") then 
				extraPower = backdrop:CreateSpinBar()
				extraPower:SetStatusBarTexture(Layout.ManaSpinBarTexture)
			else
				extraPower = backdrop:CreateStatusBar()
				extraPower:SetStatusBarTexture(Layout.ManaTexture)
			end

			extraPower:Place(unpack(Layout.ManaPlace))  
			extraPower:SetSize(unpack(Layout.ManaSize)) 
			extraPower.frequent = true
			extraPower.exclusiveResource = Layout.ManaExclusiveResource or "MANA" 
			self.ExtraPower = extraPower
			self.ExtraPower.OverrideColor = Player_OverrideExtraPowerColor
		
			if Layout.UseManaBackground then 
				local extraPowerBg = extraPower:CreateBackdropTexture()
				extraPowerBg:SetPoint(unpack(Layout.ManaBackgroundPlace))
				extraPowerBg:SetSize(unpack(Layout.ManaBackgroundSize))
				extraPowerBg:SetTexture(Layout.ManaBackgroundTexture)
				extraPowerBg:SetDrawLayer(unpack(Layout.ManaBackgroundDrawLayer))
				extraPowerBg:SetVertexColor(unpack(Layout.ManaBackgroundColor)) 
				self.ExtraPower.bg = extraPowerBg
			end 

			if Layout.UseManaShade then 
				local extraPowerShade = extraPower:CreateTexture()
				extraPowerShade:SetPoint(unpack(Layout.ManaShadePlace))
				extraPowerShade:SetSize(unpack(Layout.ManaShadeSize)) 
				extraPowerShade:SetTexture(Layout.ManaShadeTexture)
				extraPowerShade:SetDrawLayer(unpack(Layout.ManaShadeDrawLayer))
				extraPowerShade:SetVertexColor(unpack(Layout.ManaShadeColor)) 
				self.ExtraPower.Shade = extraPowerShade
			end 

			if Layout.UseManaForeground then 
				local extraPowerFg = extraPower:CreateTexture()
				extraPowerFg:SetPoint(unpack(Layout.ManaForegroundPlace))
				extraPowerFg:SetSize(unpack(Layout.ManaForegroundSize))
				extraPowerFg:SetDrawLayer(unpack(Layout.ManaForegroundDrawLayer))

				if (not Layout.UseProgressiveManaForeground) then 
					extraPowerFg:SetTexture(Layout.ManaForegroundTexture)
				end 

				self.ExtraPower.Fg = extraPowerFg
			end 

			if Layout.UseWinterVeilMana then 
				local day = tonumber(date("%d"))
				local month = tonumber(date("%m"))
				if ((month >= 12) and (day >=16 )) or ((month <= 1) and (day <= 2)) then 
					local winterVeilMana = extraPower:CreateTexture()
					winterVeilMana:SetSize(unpack(Layout.WinterVeilManaSize))
					winterVeilMana:SetPoint(unpack(Layout.WinterVeilManaPlace))
					winterVeilMana:SetDrawLayer(unpack(Layout.WinterVeilManaDrawLayer))
					winterVeilMana:SetTexture(Layout.WinterVeilManaTexture)
					winterVeilMana:SetVertexColor(unpack(Layout.WinterVeilManaColor))
					self.ExtraPower.WinterVeil = winterVeilMana
				end 
			end 
	
		end 

	end 

	-- Threat
	-----------------------------------------------------------	
	if Layout.UseThreat then 
		
		local threat 
		if Layout.UseSingleThreat then 
			threat = backdrop:CreateTexture()
		else 
			threat = {}
			threat.IsShown = Player_Threat_IsShown
			threat.Show = Player_Threat_Show
			threat.Hide = Player_Threat_Hide 
			threat.IsObjectType = function() end

			if Layout.UseHealthThreat then 

				local threatHealth = backdrop:CreateTexture()
				threatHealth:SetPoint(unpack(Layout.ThreatHealthPlace))
				threatHealth:SetSize(unpack(Layout.ThreatHealthSize))
				threatHealth:SetDrawLayer(unpack(Layout.ThreatHealthDrawLayer))
				threatHealth:SetAlpha(Layout.ThreatHealthAlpha)

				if (not Layout.UseProgressiveHealthThreat) then 
					threatHealth:SetTexture(Layout.ThreatHealthTexture)
				end 

				threatHealth._owner = self.Health
				threat.health = threatHealth

			end 
		
			if Layout.UsePowerBar and (Layout.UsePowerThreat or Layout.UsePowerBgThreat) then 

				local threatPowerFrame = backdrop:CreateFrame("Frame")
				threatPowerFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPowerFrame:SetAllPoints(self.Power)
		
				-- Hook the power visibility to the power crystal
				self.Power:HookScript("OnShow", function() threatPowerFrame:Show() end)
				self.Power:HookScript("OnHide", function() threatPowerFrame:Hide() end)

				if Layout.UsePowerThreat then
					local threatPower = threatPowerFrame:CreateTexture()
					threatPower:SetPoint(unpack(Layout.ThreatPowerPlace))
					threatPower:SetDrawLayer(unpack(Layout.ThreatPowerDrawLayer))
					threatPower:SetSize(unpack(Layout.ThreatPowerSize))
					threatPower:SetAlpha(Layout.ThreatPowerAlpha)

					if (not Layout.UseProgressivePowerThreat) then 
						threatPower:SetTexture(Layout.ThreatPowerTexture)
					end

					threatPower._owner = self.Power
					threat.power = threatPower
				end 

				if Layout.UsePowerBgThreat then 
					local threatPowerBg = threatPowerFrame:CreateTexture()
					threatPowerBg:SetPoint(unpack(Layout.ThreatPowerBgPlace))
					threatPowerBg:SetDrawLayer(unpack(Layout.ThreatPowerBgDrawLayer))
					threatPowerBg:SetSize(unpack(Layout.ThreatPowerBgSize))
					threatPowerBg:SetAlpha(Layout.ThreatPowerBgAlpha)

					if (not Layout.UseProgressivePowerBgThreat) then 
						threatPowerBg:SetTexture(Layout.ThreatPowerBgTexture)
					end

					threatPowerBg._owner = self.Power
					threat.powerBg = threatPowerBg
				end 
	
			end 
		
			if Layout.UseMana and Layout.UseManaThreat and hasMana then 
		
				local threatManaFrame = backdrop:CreateFrame("Frame")
				threatManaFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatManaFrame:SetAllPoints(self.ExtraPower)
	
				self.ExtraPower:HookScript("OnShow", function() threatManaFrame:Show() end)
				self.ExtraPower:HookScript("OnHide", function() threatManaFrame:Hide() end)

				local threatMana = threatManaFrame:CreateTexture()
				threatMana:SetDrawLayer(unpack(Layout.ThreatManaDrawLayer))
				threatMana:SetPoint(unpack(Layout.ThreatManaPlace))
				threatMana:SetSize(unpack(Layout.ThreatManaSize))
				threatMana:SetAlpha(Layout.ThreatManaAlpha)

				if (not Layout.UseProgressiveManaThreat) then 
					threatMana:SetTexture(Layout.ThreatManaTexture)
				end 

				threatMana._owner = self.ExtraPower
				threat.mana = threatMana
			end 
		end 

		threat.hideSolo = Layout.ThreatHideSolo
		threat.fadeOut = Layout.ThreatFadeOut
	
		self.Threat = threat
		self.Threat.OverrideColor = Player_Threat_UpdateColor
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation)
		if Layout.CastBarDisableSmoothing then 
			cast:DisableSmoothing()
		else 
			cast:SetSmoothingMode(Layout.CastBarSmoothingMode) .
			cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		end
		cast:SetStatusBarColor(unpack(Layout.CastBarColor))  

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			cast.Name = name
		end 

		if Layout.UseCastBarValue then 
			local value, parent 
			if Layout.CastBarValueParent then 
				parent = self[Layout.CastBarValueParent]
			end 
			local value = (parent or overlay):CreateFontString()
			value:SetPoint(unpack(Layout.CastBarValuePlace))
			value:SetFontObject(Layout.CastBarValueFont)
			value:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			value:SetJustifyH(Layout.CastBarValueJustifyH)
			value:SetJustifyV(Layout.CastBarValueJustifyV)
			value:SetTextColor(unpack(Layout.CastBarValueColor))
			if Layout.CastBarValueSize then 
				value:SetSize(unpack(Layout.CastBarValueSize))
			end 
			cast.Value = value
		end 

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 

	-- Combat Indicator
	-----------------------------------------------------------
	if Layout.UseCombatIndicator then 
		local combat = overlay:CreateTexture()

		local prefix = "CombatIndicator"
		if Layout.UseLoveCombatIndicator then 
			local day = tonumber(date("%d"))
			local month = tonumber(date("%m"))
			if ((month == 2) and (day >= 12) and (day <= 26)) then 
				prefix = "Love"..prefix
			end
		end
		combat:SetSize(unpack(Layout[prefix.."Size"]))
		combat:SetPoint(unpack(Layout[prefix.."Place"])) 
		combat:SetTexture(Layout[prefix.."Texture"])
		combat:SetDrawLayer(unpack(Layout[prefix.."DrawLayer"]))
		self.Combat = combat
		
		if Layout.UseCombatIndicatorGlow then 
			local combatGlow = overlay:CreateTexture()
			combatGlow:SetSize(unpack(Layout.CombatIndicatorGlowSize))
			combatGlow:SetPoint(unpack(Layout.CombatIndicatorGlowPlace)) 
			combatGlow:SetTexture(Layout.CombatIndicatorGlowTexture)
			combatGlow:SetDrawLayer(unpack(Layout.CombatIndicatorGlowDrawLayer))
			combatGlow:SetVertexColor(unpack(Layout.CombatIndicatorGlowColor))
			self.Combat.Glow = combatGlow
		end
	end 

	-- Auras
	-----------------------------------------------------------
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffs -- show debuffs before buffs
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

		self.Auras = auras
		self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.buffFilterString = Layout.buffFilterFunc -- buff specific filter passed to blizzard API calls
		buffs.buffFilterFunc = Layout.buffFilterFuncFunc -- buff specific filter function
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		--local test = debuffs:CreateTexture()
		--test:SetColorTexture(.7, 0, 0, .5)
		--test:SetAllPoints()

		self.Buffs = buffs
		self.Buffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilterString = Layout.debuffFilterFunc -- debuff specific filter passed to blizzard API calls
		debuffs.debuffFilterFunc = Layout.debuffFilterFuncFunc -- debuff specific filter function
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
		
		--local test = debuffs:CreateTexture()
		--test:SetColorTexture(.7, 0, 0, .5)
		--test:SetAllPoints()

		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameJustifyH)
		name:SetJustifyV(Layout.NameJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthValHolder = overlay:CreateFrame("Frame")
		healthValHolder:SetAllPoints(health)

		local healthVal = healthValHolder:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		self.Health.Value = healthVal
	end 

	-- Absorb Value
	if Layout.UseAbsorbValue then 
		local absorbVal = overlay:CreateFontString()
		if Layout.AbsorbValuePlaceFunction then 
			absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
		else 
			absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
		end 
		absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
		absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
		absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
		absorbVal:SetFontObject(Layout.AbsorbValueFont)
		absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
		self.Health.ValueAbsorb = absorbVal 
	end 

	-- Power Value
	if Layout.UsePowerBar then 
		if Layout.UsePowerValue then 
			local powerVal = self.Power:CreateFontString()
			powerVal:SetPoint(unpack(Layout.PowerValuePlace))
			powerVal:SetDrawLayer(unpack(Layout.PowerValueDrawLayer))
			powerVal:SetJustifyH(Layout.PowerValueJustifyH)
			powerVal:SetJustifyV(Layout.PowerValueJustifyV)
			powerVal:SetFontObject(Layout.PowerValueFont)
			powerVal:SetTextColor(unpack(Layout.PowerValueColor))
			self.Power.Value = powerVal
		end 
	end

	-- Mana Value
	if Layout.UseMana then 
		if hasMana and Layout.UseManaValue then 
			local extraPowerVal = self.ExtraPower:CreateFontString()
			extraPowerVal:SetPoint(unpack(Layout.ManaValuePlace))
			extraPowerVal:SetDrawLayer(unpack(Layout.ManaValueDrawLayer))
			extraPowerVal:SetJustifyH(Layout.ManaValueJustifyH)
			extraPowerVal:SetJustifyV(Layout.ManaValueJustifyV)
			extraPowerVal:SetFontObject(Layout.ManaValueFont)
			extraPowerVal:SetTextColor(unpack(Layout.ManaValueColor))
			self.ExtraPower.Value = extraPowerVal
		end 
	end 

	-- Mana Value when Mana isn't visible  
	if Layout.UseManaText then 
		local parent = self[Layout.ManaTextParent or self.Power and "Power" or "Health"]
		local manaText = parent:CreateFontString()
		manaText:SetPoint(unpack(Layout.ManaTextPlace))
		manaText:SetDrawLayer(unpack(Layout.ManaTextDrawLayer))
		manaText:SetJustifyH(Layout.ManaTextJustifyH)
		manaText:SetJustifyV(Layout.ManaTextJustifyV)
		manaText:SetFontObject(Layout.ManaTextFont)
		manaText:SetTextColor(unpack(Layout.ManaTextColor))
		manaText.frequent = true
		self.ManaText = manaText
		self.ManaText.OverrideValue = Layout.ManaTextOverride
	end

	-- Update textures according to player level
	if Layout.UseProgressiveFrames then 
		self.PostUpdateTextures = Player_PostUpdateTextures
		Player_PostUpdateTextures(self)
	end 
end

UnitStyles.StylePlayerHUDFrame = function(self, unit, id, Layout, ...)

	-- Frame
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 


	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self.ignoreMouseOver = Layout.IgnoreMouseOver

	-- Assign our own global custom colors
	self.colors = Layout.Colors or self.colors
	self.layout = Layout


	-- Scaffolds
	-----------------------------------------------------------

	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)


	-- Cast Bar
	if Layout.UseCastBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetStatusBarTexture(Layout.CastBarTexture)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) 
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the top.
		cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		cast.timeToHold = Layout.CastTimeToHoldFailed
		self.Cast = cast
		
		if Layout.UseCastBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.CastBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.CastBarBackgroundSize))
			castBg:SetTexture(Layout.CastBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.CastBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.CastBarBackgroundColor))
			self.Cast.Bg = castBg
		end 

		if Layout.UseCastBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.CastBarValuePlace))
			castValue:SetFontObject(Layout.CastBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			castValue:SetJustifyH(Layout.CastBarValueJustifyH)
			castValue:SetJustifyV(Layout.CastBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.CastBarValueColor))
			self.Cast.Value = castValue
		end 

		if Layout.UseCastBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.CastBarNamePlace))
			castName:SetFontObject(Layout.CastBarNameFont)
			castName:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			castName:SetJustifyH(Layout.CastBarNameJustifyH)
			castName:SetJustifyV(Layout.CastBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.CastBarNameColor))
			self.Cast.Name = castName
		end 

		if Layout.UseCastBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.CastBarBorderFramePlace))
			border:SetSize(unpack(Layout.CastBarBorderFrameSize))
			border:SetBackdrop(Layout.CastBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.CastBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.CastBarBorderFrameBackdropBorderColor))
			self.Cast.Border = border
		end 

		if Layout.UseCastBarShield then 
			local castShield = cast:CreateTexture()
			castShield:SetPoint(unpack(Layout.CastBarShieldPlace))
			castShield:SetSize(unpack(Layout.CastBarShieldSize))
			castShield:SetTexture(Layout.CastBarShieldTexture)
			castShield:SetDrawLayer(unpack(Layout.CastBarShieldDrawLayer))
			castShield:SetVertexColor(unpack(Layout.CastBarShieldColor))
			self.Cast.Shield = castShield

			-- Not going to work this into the plugin, so we just hook it here.
			if Layout.CastShieldHideBgWhenShielded and Layout.UseCastBarBackground then 
				hooksecurefunc(self.Cast.Shield, "Show", function() self.Cast.Bg:Hide() end)
				hooksecurefunc(self.Cast.Shield, "Hide", function() self.Cast.Bg:Show() end)
			end 
		end 

		if Layout.UseCastBarSpellQueue then 
			local spellQueue = content:CreateStatusBar()
			spellQueue:SetFrameLevel(self.Cast:GetFrameLevel() + 1)
			spellQueue:Place(unpack(Layout.CastBarSpellQueuePlace))
			spellQueue:SetSize(unpack(Layout.CastBarSpellQueueSize))
			spellQueue:SetOrientation(Layout.CastBarSpellQueueOrientation) 
			spellQueue:SetStatusBarTexture(Layout.CastBarSpellQueueTexture) 
			spellQueue:SetStatusBarColor(unpack(Layout.CastBarSpellQueueColor)) 
			spellQueue:DisableSmoothing(true)
			spellQueue.threshold = CastBarSpellQueueThreshold
			self.Cast.SpellQueue = spellQueue
		end 

	end 

	-- Class Power
	if Layout.UseClassPower then 
		local classPower = backdrop:CreateFrame("Frame")
		classPower:Place(unpack(Layout.ClassPowerPlace)) -- center it smack in the middle of the screen
		classPower:SetSize(unpack(Layout.ClassPowerSize)) -- minimum size, this is really just an anchor
		--classPower:Hide() -- for now
	
		-- Only show it on hostile targets
		classPower.hideWhenUnattackable = Layout.ClassPowerHideWhenUnattackable

		-- Maximum points displayed regardless 
		-- of max value and available point frames.
		-- This does not affect runes, which still require 6 frames.
		classPower.maxComboPoints = Layout.ClassPowerMaxComboPoints
	
		-- Set the point alpha to 0 when no target is selected
		-- This does not affect runes 
		classPower.hideWhenNoTarget = Layout.ClassPowerHideWhenNoTarget 
	
		-- Set all point alpha to 0 when we have no active points
		-- This does not affect runes 
		classPower.hideWhenEmpty = Layout.ClassPowerHideWhenNoTarget
	
		-- Alpha modifier of inactive/not ready points
		classPower.alphaEmpty = Layout.ClassPowerAlphaWhenEmpty 
	
		-- Alpha modifier when not engaged in combat
		-- This is applied on top of the inactive modifier above
		classPower.alphaNoCombat = Layout.ClassPowerAlphaWhenOutOfCombat
		classPower.alphaNoCombatRunes = Layout.ClassPowerAlphaWhenOutOfCombatRunes

		-- Set to true to flip the classPower horizontally
		-- Intended to be used alongside actioncam
		classPower.flipSide = Layout.ClassPowerReverseSides 

		-- Sort order of the runes
		classPower.runeSortOrder = Layout.ClassPowerRuneSortOrder 

	
		-- Creating 6 frames since runes require it
		for i = 1,6 do 
	
			-- Main point object
			local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
			point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
			point:SetMinMaxValues(0, 1)
			point:SetValue(1)
	
			-- Empty slot texture
			-- Make it slightly larger than the point textures, 
			-- to give a nice darker edge around the points. 
			point.slotTexture = point:CreateTexture()
			point.slotTexture:SetDrawLayer("BACKGROUND", -1)
			point.slotTexture:SetAllPoints(point)

			-- Overlay glow, aligned to the bar texture
			point.glow = point:CreateTexture()
			point.glow:SetDrawLayer("ARTWORK")
			point.glow:SetAllPoints(point:GetStatusBarTexture())

			if Layout.ClassPowerPostCreatePoint then 
				Layout.ClassPowerPostCreatePoint(classPower, i, point)
			end 

			classPower[i] = point
		end
	
		self.ClassPower = classPower
		self.ClassPower.PostUpdate = Layout.ClassPowerPostUpdate

		if self.ClassPower.PostUpdate then 
			self.ClassPower:PostUpdate()
		end 
	end 

	-- PlayerAltPower Bar
	if Layout.UsePlayerAltPowerBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.PlayerAltPowerBarPlace))
		cast:SetSize(unpack(Layout.PlayerAltPowerBarSize))
		cast:SetStatusBarTexture(Layout.PlayerAltPowerBarTexture)
		cast:SetStatusBarColor(unpack(Layout.PlayerAltPowerBarColor)) 
		cast:SetOrientation(Layout.PlayerAltPowerBarOrientation) -- set the bar to grow towards the top.
		--cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		cast:EnableMouse(true)
		self.AltPower = cast
		self.AltPower.OverrideValue = PlayerHUD_AltPower_OverrideValue
		
		if Layout.UsePlayerAltPowerBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.PlayerAltPowerBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.PlayerAltPowerBarBackgroundSize))
			castBg:SetTexture(Layout.PlayerAltPowerBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.PlayerAltPowerBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.PlayerAltPowerBarBackgroundColor))
			self.AltPower.Bg = castBg
		end 

		if Layout.UsePlayerAltPowerBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.PlayerAltPowerBarValuePlace))
			castValue:SetFontObject(Layout.PlayerAltPowerBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.PlayerAltPowerBarValueDrawLayer))
			castValue:SetJustifyH(Layout.PlayerAltPowerBarValueJustifyH)
			castValue:SetJustifyV(Layout.PlayerAltPowerBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.PlayerAltPowerBarValueColor))
			self.AltPower.Value = castValue
		end 

		if Layout.UsePlayerAltPowerBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.PlayerAltPowerBarNamePlace))
			castName:SetFontObject(Layout.PlayerAltPowerBarNameFont)
			castName:SetDrawLayer(unpack(Layout.PlayerAltPowerBarNameDrawLayer))
			castName:SetJustifyH(Layout.PlayerAltPowerBarNameJustifyH)
			castName:SetJustifyV(Layout.PlayerAltPowerBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.PlayerAltPowerBarNameColor))
			self.AltPower.Name = castName
		end 

		if Layout.UsePlayerAltPowerBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.PlayerAltPowerBarBorderFramePlace))
			border:SetSize(unpack(Layout.PlayerAltPowerBarBorderFrameSize))
			border:SetBackdrop(Layout.PlayerAltPowerBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropBorderColor))
			self.AltPower.Border = border
		end 
	end 
	
end

UnitStyles.StyleTargetFrame = function(self, unit, id, Layout, ...)
	-- Frame
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Layout.Colors or self.colors
	self.layout = Layout

	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 10)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 20)

	-- Border
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health 
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:SetFrameLevel(health:GetFrameLevel() + 2)
	health:Place(unpack(Layout.HealthPlace))
	health:SetSmartSmoothing(true)
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorThreat = Layout.HealthColorThreat -- color units with threat in threat color
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates
	health.threatFeedbackUnit = Layout.HealthThreatFeedbackUnit
	health.threatHideSolo = Layout.HealthThreatHideSolo
	
	self.Health = health
	self.Health.PostUpdate = Layout.CastBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBgHolder = health:CreateFrame("Frame")
		healthBgHolder:SetAllPoints()
		healthBgHolder:SetFrameLevel(health:GetFrameLevel()-2)

		local healthBg = healthBgHolder:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropTexCoord then 
			healthBg:SetTexCoord(unpack(Layout.HealthBackdropTexCoord))
		end 
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		self.Health.Fg = healthFg
	end 

	-- Power 
	if Layout.UsePowerBar then 
		local power = (Layout.PowerInOverlay and overlay or backdrop):CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.

		if Layout.PowerBarSetFlippedHorizontally then 
			power:SetFlippedHorizontally(Layout.PowerBarSetFlippedHorizontally)
		end

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		if Layout.PowerBarSparkTexture then 
			power:SetSparkTexture(Layout.PowerBarSparkTexture)
		end

		-- make the bar hide when MANA is the primary resource. 
		power.ignoredResource = Layout.PowerIgnoredResource 

		-- use this bar for alt power as well
		power.showAlternate = Layout.PowerShowAlternate

		-- hide the bar when it's empty
		power.hideWhenEmpty = Layout.PowerHideWhenEmpty

		-- hide the bar when the unit is dead
		power.hideWhenDead = Layout.PowerHideWhenDead

		-- Use filters to decide what units to show for 
		power.visibilityFilter = Layout.PowerVisibilityFilter

		self.Power = power
		self.Power.OverrideColor = OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			if Layout.PowerBackgroundTexCoord then 
				powerBg:SetTexCoord(unpack(Layout.PowerBackgroundTexCoord))
			end 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end

		-- Power Value
		if Layout.UsePowerBar then 
			if Layout.UsePowerValue then 
				local powerVal = self.Power:CreateFontString()
				powerVal:SetPoint(unpack(Layout.PowerValuePlace))
				powerVal:SetDrawLayer(unpack(Layout.PowerValueDrawLayer))
				powerVal:SetJustifyH(Layout.PowerValueJustifyH)
				powerVal:SetJustifyV(Layout.PowerValueJustifyV)
				powerVal:SetFontObject(Layout.PowerValueFont)
				powerVal:SetTextColor(unpack(Layout.PowerValueColor))
				self.Power.Value = powerVal
				self.Power.OverrideValue = Layout.PowerValueOverride
			end 
		end		
	end 

	-- Cast Bar
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) 
		cast:SetFlippedHorizontally(Layout.CastBarSetFlippedHorizontally)
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) 
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) 
		
		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			cast.Name = name
		end 

		if Layout.UseCastBarValue then 
			local value, parent 
			if Layout.CastBarValueParent then 
				parent = self[Layout.CastBarValueParent]
			end 
			local value = (parent or overlay):CreateFontString()
			value:SetPoint(unpack(Layout.CastBarValuePlace))
			value:SetFontObject(Layout.CastBarValueFont)
			value:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			value:SetJustifyH(Layout.CastBarValueJustifyH)
			value:SetJustifyV(Layout.CastBarValueJustifyV)
			value:SetTextColor(unpack(Layout.CastBarValueColor))
			if Layout.CastBarValueSize then 
				value:SetSize(unpack(Layout.CastBarValueSize))
			end 
			cast.Value = value
		end 

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
		
	end 

	-- Portrait
	if Layout.UsePortrait then 
		local portrait = backdrop:CreateFrame("PlayerModel")
		portrait:SetPoint(unpack(Layout.PortraitPlace))
		portrait:SetSize(unpack(Layout.PortraitSize)) 
		portrait:SetAlpha(Layout.PortraitAlpha)
		portrait.distanceScale = Layout.PortraitDistanceScale
		portrait.positionX = Layout.PortraitPositionX
		portrait.positionY = Layout.PortraitPositionY
		portrait.positionZ = Layout.PortraitPositionZ
		portrait.rotation = Layout.PortraitRotation -- in degrees
		portrait.showFallback2D = Layout.PortraitShowFallback2D -- display 2D portraits when unit is out of range of 3D models
		self.Portrait = portrait
		
		-- To allow the backdrop and overlay to remain 
		-- visible even with no visible player model, 
		-- we add them to our backdrop and overlay frames, 
		-- not to the portrait frame itself.  
		if Layout.UsePortraitBackground then 
			local portraitBg = backdrop:CreateTexture()
			portraitBg:SetPoint(unpack(Layout.PortraitBackgroundPlace))
			portraitBg:SetSize(unpack(Layout.PortraitBackgroundSize))
			portraitBg:SetTexture(Layout.PortraitBackgroundTexture)
			portraitBg:SetDrawLayer(unpack(Layout.PortraitBackgroundDrawLayer))
			portraitBg:SetVertexColor(unpack(Layout.PortraitBackgroundColor)) -- keep this dark
			self.Portrait.Bg = portraitBg
		end 

		if Layout.UsePortraitShade then 
			local portraitShade = content:CreateTexture()
			portraitShade:SetPoint(unpack(Layout.PortraitShadePlace))
			portraitShade:SetSize(unpack(Layout.PortraitShadeSize)) 
			portraitShade:SetTexture(Layout.PortraitShadeTexture)
			portraitShade:SetDrawLayer(unpack(Layout.PortraitShadeDrawLayer))
			self.Portrait.Shade = portraitShade
		end 

		if Layout.UsePortraitForeground then 
			local portraitFg = content:CreateTexture()
			portraitFg:SetPoint(unpack(Layout.PortraitForegroundPlace))
			portraitFg:SetSize(unpack(Layout.PortraitForegroundSize))
			portraitFg:SetDrawLayer(unpack(Layout.PortraitForegroundDrawLayer))
			self.Portrait.Fg = portraitFg
		end 
	end 

	-- Threat
	if Layout.UseThreat then 
		
		local threat 
		if Layout.UseSingleThreat then 
			threat = backdrop:CreateTexture()
		else 
			threat = {}
			threat.IsShown = Target_Threat_IsShown
			threat.Show = Target_Threat_Show
			threat.Hide = Target_Threat_Hide 
			threat.IsObjectType = function() end

			if Layout.UseHealthThreat then 

				local healthThreatHolder = backdrop:CreateFrame("Frame")
				healthThreatHolder:SetAllPoints(health)

				local threatHealth = healthThreatHolder:CreateTexture()
				if Layout.ThreatHealthPlace then 
					threatHealth:SetPoint(unpack(Layout.ThreatHealthPlace))
				end 
				if Layout.ThreatHealthSize then 
					threatHealth:SetSize(unpack(Layout.ThreatHealthSize))
				end 
				if Layout.ThreatHealthTexCoord then 
					threatHealth:SetTexCoord(unpack(Layout.ThreatHealthTexCoord))
				end 
				if (not Layout.UseProgressiveHealthThreat) then 
					threatHealth:SetTexture(Layout.ThreatHealthTexture)
				end 
				threatHealth:SetDrawLayer(unpack(Layout.ThreatHealthDrawLayer))
				threatHealth:SetAlpha(Layout.ThreatHealthAlpha)

				threatHealth._owner = self.Health
				threat.health = threatHealth
			end 
		
			if Layout.UsePowerBar and (Layout.UsePowerThreat or Layout.UsePowerBgThreat) then 

				local threatPowerFrame = backdrop:CreateFrame("Frame")
				threatPowerFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPowerFrame:SetAllPoints(self.Power)
		
				-- Hook the power visibility to the power crystal
				self.Power:HookScript("OnShow", function() threatPowerFrame:Show() end)
				self.Power:HookScript("OnHide", function() threatPowerFrame:Hide() end)

				if Layout.UsePowerThreat then
					local threatPower = threatPowerFrame:CreateTexture()
					threatPower:SetPoint(unpack(Layout.ThreatPowerPlace))
					threatPower:SetDrawLayer(unpack(Layout.ThreatPowerDrawLayer))
					threatPower:SetSize(unpack(Layout.ThreatPowerSize))
					threatPower:SetAlpha(Layout.ThreatPowerAlpha)

					if (not Layout.UseProgressivePowerThreat) then 
						threatPower:SetTexture(Layout.ThreatPowerTexture)
					end

					threatPower._owner = self.Power
					threat.power = threatPower
				end 

				if Layout.UsePowerBgThreat then 
					local threatPowerBg = threatPowerFrame:CreateTexture()
					threatPowerBg:SetPoint(unpack(Layout.ThreatPowerBgPlace))
					threatPowerBg:SetDrawLayer(unpack(Layout.ThreatPowerBgDrawLayer))
					threatPowerBg:SetSize(unpack(Layout.ThreatPowerBgSize))
					threatPowerBg:SetAlpha(Layout.ThreatPowerBgAlpha)

					if (not Layout.UseProgressivePowerBgThreat) then 
						threatPowerBg:SetTexture(Layout.ThreatPowerBgTexture)
					end

					threatPowerBg._owner = self.Power
					threat.powerBg = threatPowerBg
				end 
	
			end 
		
			if Layout.UsePortrait and Layout.UsePortraitThreat then 
				local threatPortraitFrame = backdrop:CreateFrame("Frame")
				threatPortraitFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPortraitFrame:SetAllPoints(self.Portrait)
		
				-- Hook the power visibility to the power crystal
				self.Portrait:HookScript("OnShow", function() threatPortraitFrame:Show() end)
				self.Portrait:HookScript("OnHide", function() threatPortraitFrame:Hide() end)

				local threatPortrait = threatPortraitFrame:CreateTexture()
				threatPortrait:SetPoint(unpack(Layout.ThreatPortraitPlace))
				threatPortrait:SetSize(unpack(Layout.ThreatPortraitSize))
				threatPortrait:SetTexture(Layout.ThreatPortraitTexture)
				threatPortrait:SetDrawLayer(unpack(Layout.ThreatPortraitDrawLayer))
				threatPortrait:SetAlpha(Layout.ThreatPortraitAlpha)

				threatPortrait._owner = self.Power
				threat.portrait = threatPortrait
			end 
		end 

		threat.hideSolo = Layout.ThreatHideSolo
		threat.fadeOut = Layout.ThreatFadeOut
		threat.feedbackUnit = "player"
	
		self.Threat = threat
		self.Threat.OverrideColor = Target_Threat_UpdateColor
	end 

	-- Unit Level
	if Layout.UseLevel then 

		-- level text
		local level = overlay:CreateFontString()
		level:SetPoint(unpack(Layout.LevelPlace))
		level:SetDrawLayer(unpack(Layout.LevelDrawLayer))
		level:SetJustifyH(Layout.LevelJustifyH)
		level:SetJustifyV(Layout.LevelJustifyV)
		level:SetFontObject(Layout.LevelFont)

		-- Hide the level of capped (or higher) players and NPcs 
		-- Doesn't affect high/unreadable level (??) creatures, as they will still get a skull.
		level.hideCapped = Layout.LevelHideCapped 

		-- Hide the level of level 1's
		level.hideFloored = Layout.LevelHideFloored

		-- Set the default level coloring when nothing special is happening
		level.defaultColor = Layout.LevelColor
		level.alpha = Layout.LevelAlpha

		-- Use a custom method to decide visibility
		level.visibilityFilter = Layout.LevelVisibilityFilter

		-- Badge backdrop
		if Layout.UseLevelBadge then 
			local levelBadge = overlay:CreateTexture()
			levelBadge:SetPoint("CENTER", level, "CENTER", 0, 1)
			levelBadge:SetSize(unpack(Layout.LevelBadgeSize))
			levelBadge:SetDrawLayer(unpack(Layout.LevelBadgeDrawLayer))
			levelBadge:SetTexture(Layout.LevelBadgeTexture)
			levelBadge:SetVertexColor(unpack(Layout.LevelBadgeColor))
			level.Badge = levelBadge
		end 

		-- Skull texture for bosses, high level (and dead units if the below isn't provided)
		if Layout.UseLevelSkull then 
			local skull = overlay:CreateTexture()
			skull:Hide()
			skull:SetPoint("CENTER", level, "CENTER", 0, 0)
			skull:SetSize(unpack(Layout.LevelSkullSize))
			skull:SetDrawLayer(unpack(Layout.LevelSkullDrawLayer))
			skull:SetTexture(Layout.LevelSkullTexture)
			skull:SetVertexColor(unpack(Layout.LevelSkullColor))
			level.Skull = skull
		end 

		-- Skull texture for dead units only
		if Layout.UseLevelDeadSkull then 
			local dead = overlay:CreateTexture()
			dead:Hide()
			dead:SetPoint("CENTER", level, "CENTER", 0, 0)
			dead:SetSize(unpack(Layout.LevelDeadSkullSize))
			dead:SetDrawLayer(unpack(Layout.LevelDeadSkullDrawLayer))
			dead:SetTexture(Layout.LevelDeadSkullTexture)
			dead:SetVertexColor(unpack(Layout.LevelDeadSkullColor))
			level.Dead = dead
		end 
		
		self.Level = level	
	end 

	-- Unit Classification (boss, elite, rare)
	if Layout.UseClassificationIndicator then 

		local classification = overlay:CreateFrame("Frame")
		classification:SetPoint(unpack(Layout.ClassificationPlace))
		classification:SetSize(unpack(Layout.ClassificationSize))
		self.Classification = classification

		local boss = classification:CreateTexture()
		boss:SetPoint("CENTER", 0, 0)
		boss:SetSize(unpack(Layout.ClassificationSize))
		boss:SetTexture(Layout.ClassificationIndicatorBossTexture)
		boss:SetVertexColor(unpack(Layout.ClassificationColor))
		self.Classification.Boss = boss

		local elite = classification:CreateTexture()
		elite:SetPoint("CENTER", 0, 0)
		elite:SetSize(unpack(Layout.ClassificationSize))
		elite:SetTexture(Layout.ClassificationIndicatorEliteTexture)
		elite:SetVertexColor(unpack(Layout.ClassificationColor))
		self.Classification.Elite = elite

		local rare = classification:CreateTexture()
		rare:SetPoint("CENTER", 0, 0)
		rare:SetSize(unpack(Layout.ClassificationSize))
		rare:SetTexture(Layout.ClassificationIndicatorRareTexture)
		rare:SetVertexColor(unpack(Layout.ClassificationColor))
		self.Classification.Rare = rare

		local alliance = classification:CreateTexture()
		alliance:SetPoint("CENTER", 0, 0)
		alliance:SetSize(unpack(Layout.ClassificationSize))
		alliance:SetTexture(Layout.ClassificationIndicatorAllianceTexture)
		alliance:SetVertexColor(unpack(Layout.ClassificationColor))
		self.Classification.Alliance = alliance

		local horde = classification:CreateTexture()
		horde:SetPoint("CENTER", 0, 0)
		horde:SetSize(unpack(Layout.ClassificationSize))
		horde:SetTexture(Layout.ClassificationIndicatorHordeTexture)
		horde:SetVertexColor(unpack(Layout.ClassificationColor))
		self.Classification.Horde = horde

	end

	-- Targeting
	-- Indicates who your target is targeting
	if Layout.UseTargetIndicator then 
		self.Targeted = {}

		local prefix = "TargetIndicator"
		if Layout.UseLoveTargetIndicator then 
			local day = tonumber(date("%d"))
			local month = tonumber(date("%m"))
			if ((month == 2) and (day >= 12) and (day <= 26)) then 
				prefix = "Love"..prefix
			end
		end

		local friend = overlay:CreateTexture()
		friend:SetPoint(unpack(Layout[prefix.."YouByFriendPlace"]))
		friend:SetSize(unpack(Layout[prefix.."YouByFriendSize"]))
		friend:SetTexture(Layout[prefix.."YouByFriendTexture"])
		friend:SetVertexColor(unpack(Layout[prefix.."YouByFriendColor"]))
		self.Targeted.YouByFriend = friend

		local enemy = overlay:CreateTexture()
		enemy:SetPoint(unpack(Layout[prefix.."YouByEnemyPlace"]))
		enemy:SetSize(unpack(Layout[prefix.."YouByEnemySize"]))
		enemy:SetTexture(Layout[prefix.."YouByEnemyTexture"])
		enemy:SetVertexColor(unpack(Layout[prefix.."YouByEnemyColor"]))
		self.Targeted.YouByEnemy = enemy

		local pet = overlay:CreateTexture()
		pet:SetPoint(unpack(Layout[prefix.."PetByEnemyPlace"]))
		pet:SetSize(unpack(Layout[prefix.."PetByEnemySize"]))
		pet:SetTexture(Layout[prefix.."PetByEnemyTexture"])
		pet:SetVertexColor(unpack(Layout[prefix.."PetByEnemyColor"]))
		self.Targeted.PetByEnemy = pet
	end 

	-- Auras
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffs -- show debuffs before buffs
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
			
		self.Auras = auras
		self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Buffs
	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.buffFilterString = Layout.buffFilterFunc -- buff specific filter passed to blizzard API calls
		buffs.buffFilterFunc = Layout.buffFilterFuncFunc -- buff specific filter function
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		self.Buffs = buffs
		self.Buffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Debuffs
	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilterString = Layout.debuffFilterFunc -- debuff specific filter passed to blizzard API calls
		debuffs.debuffFilterFunc = Layout.debuffFilterFuncFunc -- debuff specific filter function
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
			
		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameJustifyH)
		name:SetJustifyV(Layout.NameJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthValHolder = overlay:CreateFrame("Frame")
		healthValHolder:SetAllPoints(health)

		local healthVal = healthValHolder:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		self.Health.Value = healthVal
	end 

	-- Health Percentage 
	if Layout.UseHealthPercent then 
		local healthPerc = health:CreateFontString()
		healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
		healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
		healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
		healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
		healthPerc:SetFontObject(Layout.HealthPercentFont)
		healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
		self.Health.ValuePercent = healthPerc
	end 

	-- Absorb Value
	if Layout.UseAbsorbValue then 
		local absorbVal = overlay:CreateFontString()
		if Layout.AbsorbValuePlaceFunction then 
			absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
		else 
			absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
		end 
		absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
		absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
		absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
		absorbVal:SetFontObject(Layout.AbsorbValueFont)
		absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
		self.Health.ValueAbsorb = absorbVal 
	end 

	-- Update textures according to player level
	if Layout.UseProgressiveFrames then 
		self.PostUpdateTextures = Target_PostUpdateTextures
		self:PostUpdateTextures()
	end 
end

UnitStyles.StyleToTFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitStyles.StyleFocusFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitStyles.StylePetFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

-----------------------------------------------------------
-- Grouped Unit Styling
-----------------------------------------------------------
-- Dummy counters for testing purposes only
local fakeArenaId, fakeBossId, fakePartyId, fakeRaidId = 0, 0, 0, 0

UnitStyles.StyleArenaFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeArenaId = fakeArenaId + 1
		id = fakeArenaId
	end 
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitStyles.StyleBossFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeBossId = fakeBossId + 1
		id = fakeBossId
	end 
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitStyles.StylePartyFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakePartyId = fakePartyId + 1
		id = fakePartyId
	end 
	return StylePartyFrame(self, unit, id, Layout, ...)
end

UnitStyles.StyleRaidFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeRaidId = fakeRaidId + 1
		id = fakeRaidId
	end 
	return StyleRaidFrame(self, unit, id, Layout, ...)
end

-----------------------------------------------------------
-----------------------------------------------------------
-- 				UnitFrame Modules
-----------------------------------------------------------
-----------------------------------------------------------

-----------------------------------------------------------
-- Player
-----------------------------------------------------------
UnitFramePlayer.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFramePlayer]", true)
	self.frame = self:SpawnUnitFrame("player", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StylePlayerFrame(frame, unit, id, self.layout, ...)
	end)
end 

UnitFramePlayer.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
end

UnitFramePlayer.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= PlayerLevel)) then
			PlayerLevel = level
		else
			local level = UnitLevel("player")
			if (level ~= PlayerLevel) then
				PlayerLevel = level
			end
		end
	end
	self.frame:PostUpdateTextures(PlayerLevel)
end

UnitFramePlayerHUD.OnEvent = function(self, event, ...)
	local arg1, arg2 = ...
	if ((event == "CVAR_UPDATE") and (arg1 == "DISPLAY_PERSONAL_RESOURCE")) then 

		-- Disable cast element if personal resource display is enabled. 
		-- We follow the event returns here instead of querying the cvar.
		if (arg2 == "0") then 
			self.frame:EnableElement("Cast")
		elseif (arg2 == "1") then 
			self.frame:DisableElement("Cast")
		end
	elseif (event == "VARIABLES_LOADED") then 

		-- Disable cast element if personal resource display is enabled
		if (GetCVarBool("nameplateShowSelf")) then 
			self.frame:DisableElement("Cast")
		else
			self.frame:EnableElement("Cast")
		end
	end 
end

UnitFramePlayerHUD.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFramePlayerHUD]", true)
	self.frame = self:SpawnUnitFrame("player", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StylePlayerHUDFrame(frame, unit, id, self.layout, ...)
	end)

	-- Disable cast element if personal resource display is enabled
	if (GetCVarBool("nameplateShowSelf")) then 
		self.frame:DisableElement("Cast")
	else 
		self.frame:EnableElement("Cast")
	end
end 

UnitFramePlayerHUD.OnEnable = function(self)
	self:RegisterEvent("CVAR_UPDATE", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
end

-----------------------------------------------------------
-- Target
-----------------------------------------------------------
UnitFrameTarget.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameTarget]", true)
	self.frame = self:SpawnUnitFrame("target", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StyleTargetFrame(frame, unit, id, self.layout, ...)
	end)
end 

UnitFrameTarget.OnEnable = function(self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
end

UnitFrameTarget.OnEvent = function(self, event, ...)
	if (event == "PLAYER_TARGET_CHANGED") then
		if UnitExists("target") then
			-- Play a fitting sound depending on what kind of target we gained
			if UnitIsEnemy("target", "player") then
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_AGGRO_SELECT, "SFX")
			elseif UnitIsFriend("player", "target") then
				self:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_NPC_SELECT, "SFX")
			else
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT, "SFX")
			end
			self.frame:PostUpdateTextures()
		else
			-- Play a sound indicating we lost our target
			self:PlaySoundKitID(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT, "SFX")
		end
	end
end

-----------------------------------------------------------
-- Focus
-----------------------------------------------------------
UnitFrameFocus.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameFocus]", true)
	self.frame = self:SpawnUnitFrame("focus", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StyleFocusFrame(frame, unit, id, self.layout, ...)
	end)
end 

-----------------------------------------------------------
-- Pet
-----------------------------------------------------------
UnitFramePet.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFramePet]", true)
	self.frame = self:SpawnUnitFrame("pet", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StylePetFrame(frame, unit, id, self.layout, ...)
	end)
end 

-----------------------------------------------------------
-- Target of Target
-----------------------------------------------------------
UnitFrameToT.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameToT]", true)
	self.frame = self:SpawnUnitFrame("targettarget", "UICenter", function(frame, unit, id, _, ...)
		return UnitStyles.StyleToTFrame(frame, unit, id, self.layout, ...)
	end)
end 

-----------------------------------------------------------
-- Arena Enemy Frames
-----------------------------------------------------------
UnitFrameArena.OnInit = function(self)

	-- Default settings
	local defaults = {
		enableArenaFrames = true
	}

	self.db = self:NewConfig("UnitFrameArena", defaults, "global")
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameArena]", true)

	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:SetAttribute("_onattributechanged", SECURE.Arena_OnAttribute)
	if self.db.enableArenaFrames then 
		RegisterAttributeDriver(self.frame, "state-vis", "[@arena1,exists]show;hide")
	else 
		RegisterAttributeDriver(self.frame, "state-vis", "hide")
	end 

	local style = function(frame, unit, id, _, ...)
		return UnitStyles.StyleArenaFrames(frame, unit, id, self.layout, ...)
	end
	for i = 1,5 do 
		self.frame[tostring(i)] = self:SpawnUnitFrame("arena"..i, self.frame, style)
	end 

	-- Create a secure proxy updater for the menu system
	CreateSecureCallbackFrame(self, self.frame, self.db, SECURE.Arena_SecureCallback:format(visDriver))
end 

-----------------------------------------------------------
-- Boss
-----------------------------------------------------------
UnitFrameBoss.OnInit = function(self)
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameBoss]", true)
	self.frame = {}

	local style = function(frame, unit, id, _, ...)
		return UnitStyles.StyleBossFrames(frame, unit, id, self.layout, ...)
	end
	for i = 1,5 do 
		self.frame[tostring(i)] = self:SpawnUnitFrame("boss"..i, "UICenter", style)
	end 
end 

-----------------------------------------------------------
-- Party
-----------------------------------------------------------
UnitFrameParty.OnInit = function(self)
	local dev --= true

	-- Default settings
	local defaults = {
		enablePartyFrames = true
	}

	self.db = self:NewConfig("UnitFrameParty", defaults, "global")
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameParty]")

	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:SetSize(unpack(self.layout.Size))
	self.frame:Place(unpack(self.layout.Place))
	
	self.frame.healerAnchor = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame.healerAnchor:SetSize(unpack(self.layout.Size))
	self.frame.healerAnchor:Place(unpack(self.layout.AlternatePlace)) 
	self.frame:SetFrameRef("HealerModeAnchor", self.frame.healerAnchor)

	self.frame:Execute(SECURE.FrameTable_Create)
	self.frame:SetAttribute("inHealerMode", self:GetConfig("Core").enableHealerMode)
	self.frame:SetAttribute("sortFrames", SECURE.Party_SortFrames:format(
		self.layout.GroupAnchor, 
		self.layout.GrowthX, 
		self.layout.GrowthY, 
		self.layout.AlternateGroupAnchor, 
		self.layout.AlternateGrowthX, 
		self.layout.AlternateGrowthY 
	))
	self.frame:SetAttribute("_onattributechanged", SECURE.Party_OnAttribute)

	-- Hide it in raids of 6 or more players 
	-- Use an attribute driver to do it so the normal unitframe visibility handler can remain unchanged
	local visDriver = dev and "[@player,exists]show;hide" or "[@raid6,exists]hide;[group]show;hide"
	if self.db.enablePartyFrames then 
		RegisterAttributeDriver(self.frame, "state-vis", visDriver)
	else 
		RegisterAttributeDriver(self.frame, "state-vis", "hide")
	end 

	local style = function(frame, unit, id, _, ...)
		return UnitStyles.StylePartyFrames(frame, unit, id, self.layout, ...)
	end

	for i = 1,4 do 
		local frame = self:SpawnUnitFrame(dev and "player" or "party"..i, self.frame, style)

		-- Reference the frame in Lua
		self.frame[tostring(i)] = frame

		-- Reference the frame in the secure environment
		self.frame:SetFrameRef("CurrentFrame", frame)
		self.frame:Execute(SECURE.FrameTable_InsertCurrentFrame)
	end 

	self.frame:Execute(self.frame:GetAttribute("sortFrames"))

	-- Create a secure proxy updater for the menu system
	CreateSecureCallbackFrame(self, self.frame, self.db, SECURE.Party_SecureCallback:format(visDriver))

	-- Reference the group header with the sorting method
	--self:GetSecureUpdater():SetFrameRef("GroupHeader", self.frame)
end 

-----------------------------------------------------------
-- Raid
-----------------------------------------------------------
UnitFrameRaid.OnInit = function(self)
	local dev --= true
	local defaults = {
		enableRaidFrames = true
	}

	self.db = self:NewConfig("UnitFrameRaid", defaults, "global")
	self.layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[UnitFrameRaid]")

	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:SetSize(1,1)
	self.frame:Place(unpack(self.layout.Place)) 
	self.frame.healerAnchor = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame.healerAnchor:SetSize(1,1)
	self.frame.healerAnchor:Place(unpack(self.layout.AlternatePlace)) 
	self.frame:SetFrameRef("HealerModeAnchor", self.frame.healerAnchor)
	self.frame:Execute(SECURE.FrameTable_Create)
	self.frame:SetAttribute("inHealerMode", self:GetConfig("Core").enableHealerMode)
	self.frame:SetAttribute("sortFrames", SECURE.Raid_SortFrames:format(
		self.layout.GroupSizeNormal, 
		self.layout.GrowthXNormal,
		self.layout.GrowthYNormal,
		self.layout.GrowthYNormalHealerMode,
		self.layout.GroupGrowthXNormal,
		self.layout.GroupGrowthYNormal,
		self.layout.GroupGrowthYNormalHealerMode,
		self.layout.GroupColsNormal,
		self.layout.GroupRowsNormal,
		self.layout.GroupAnchorNormal, 
		self.layout.GroupAnchorNormalHealerMode, 

		self.layout.GroupSizeEpic,
		self.layout.GrowthXEpic,
		self.layout.GrowthYEpic,
		self.layout.GrowthYEpicHealerMode,
		self.layout.GroupGrowthXEpic,
		self.layout.GroupGrowthYEpic,
		self.layout.GroupGrowthYEpicHealerMode,
		self.layout.GroupColsEpic,
		self.layout.GroupRowsEpic,
		self.layout.GroupAnchorEpic,
		self.layout.GroupAnchorEpicHealerMode
	))
	self.frame:SetAttribute("_onattributechanged", SECURE.Raid_OnAttribute)

	if (not self.db.allowBlizzard) then 
		self:DisableUIWidget("UnitFrameRaid") 
	end

	-- Only show it in raids of 6 or more players 
	-- Use an attribute driver to do it so the normal unitframe visibility handler can remain unchanged
	local visDriver = dev and "[@player,exists]show;hide" or "[@raid6,exists]show;hide"
	RegisterAttributeDriver(self.frame, "state-vis", self.db.enableRaidFrames and visDriver or "hide")

	local style = function(frame, unit, id, _, ...)
		return UnitStyles.StyleRaidFrames(frame, unit, id, self.layout, ...)
	end
	for i = 1,40 do 
		local frame = self:SpawnUnitFrame(dev and "player" or "raid"..i, self.frame, style)
		self.frame[tostring(i)] = frame
		self.frame:SetFrameRef("CurrentFrame", frame)
		self.frame:Execute(SECURE.FrameTable_InsertCurrentFrame)
	end 

	-- Register the layout driver
	RegisterAttributeDriver(self.frame, "state-layout", dev and "[@target,exists]epic;normal" or "[@raid26,exists]epic;normal")

	-- Create a secure proxy updater for the menu system
	CreateSecureCallbackFrame(self, self.frame, self.db, SECURE.Raid_SecureCallback:format(visDriver))
end 

