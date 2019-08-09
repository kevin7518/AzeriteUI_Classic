local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardTooltipStyling", "LibEvent", "LibDB", "LibTooltip")
local Layout

Module:SetIncompatible("TipTac")
Module:SetIncompatible("TinyTip")
Module:SetIncompatible("TinyTooltip")

-- Lua API
local _G = _G
local math_floor = math.floor
local table_concat = table.concat
local table_wipe = table.wipe
local type = type
local unpack = unpack

-- WoW API
local UnitExists = _G.UnitExists
local UnitIsUnit = _G.UnitIsUnit

-- Blizzard textures we use 
local BOSS_TEXTURE = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t"
local FFA_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-FFA:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_ALLIANCE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_NEUTRAL_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Neutral:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_HORDE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t"

-- String storing current name data for the unit tooltips
local NAME_STRING = {} 

-- Bar post updates
-- Show health values for tooltip health bars, and hide others.
-- Will expand on this later to tailer all tooltips to our needs.  
local StatusBar_UpdateValue = function(bar, value, max)
	if value then 
		if (value >= 1e8) then 			bar.value:SetFormattedText("%.0fm", value/1e6) 		-- 100m, 1000m, 2300m, etc
		elseif (value >= 1e6) then 		bar.value:SetFormattedText("%.1fm", value/1e6) 		-- 1.0m - 99.9m 
		elseif (value >= 1e5) then 		bar.value:SetFormattedText("%.0fk", value/1e3) 		-- 100k - 999k
		elseif (value >= 1e3) then 		bar.value:SetFormattedText("%.1fk", value/1e3) 		-- 1.0k - 99.9k
		elseif (value > 0) then 		bar.value:SetText(tostring(math_floor(value))) 		-- 1 - 999
		else 							bar.value:SetText(DEAD)
		end 
		if (not bar.value:IsShown()) then 
			bar.value:Show()
		end
	else 
		if (bar.value:IsShown()) then 
			bar.value:Hide()
			bar.value:SetText("")
		end
	end 
end 

local GetTooltipUnit = function(tooltip)
	local _, unit = tooltip:GetUnit()
	if (not unit) and UnitExists("mouseover") then
		unit = "mouseover"
	end
	if unit and UnitIsUnit(unit, "mouseover") then
		unit = "mouseover"
	end
	return UnitExists(unit) and unit	
end

local OnTooltipHide = function(tooltip)
	tooltip.unit = nil
end

local OnTooltipSetUnit = function(tooltip)
	if (tooltip:IsForbidden()) then 
		return
	end

	local unit = GetTooltipUnit(tooltip)
	if (not unit) then
		tooltip:Hide()
		tooltip.unit = nil
		return
	end

	tooltip.unit = unit

	local isplayer = UnitIsPlayer(unit)
	local level = UnitLevel(unit)
	local name, realm = UnitName(unit)
	local faction = UnitFactionGroup(unit)
	local isdead = UnitIsDead(unit) or UnitIsGhost(unit)
	local colors = tooltip.colors or Layout.Colors

	local disconnected, pvp, ffa, pvpname, afk, dnd, class, classname
	local classification, creaturetype, iswildpet, isbattlepet
	local isboss, reaction, istapped
	local color

	if isplayer then
		disconnected = not UnitIsConnected(unit)
		pvp = UnitIsPVP(unit)
		ffa = UnitIsPVPFreeForAll(unit)
		pvpname = UnitPVPName(unit)
		afk = UnitIsAFK(unit)
		dnd = UnitIsDND(unit)
		classname, class = UnitClass(unit)
	else
		classification = UnitClassification(unit)
		creaturetype = UnitCreatureFamily(unit) or UnitCreatureType(unit)
		isboss = classification == "worldboss"
		reaction = UnitReaction(unit, "player")
		istapped = UnitIsTapDenied(unit)
		iswildpet = UnitIsWildBattlePet and UnitIsWildBattlePet(unit)
		isbattlepet = UnitIsBattlePetCompanion and UnitIsBattlePetCompanion(unit)

		if isbattlepet or iswildpet then
			level = UnitBattlePetLevel(unit)
		end
		if (level == -1) then
			classification = "worldboss"
			isboss = true
		end
	end

	-- figure out name coloring based on collected data
	if isdead then 
		color = colors.dead
	elseif isplayer then
		if disconnected then
			color = colors.disconnected
		elseif class then
			color = colors.class[class]
		else
			color = colors.normal
		end
	elseif reaction then
		if istapped then
			color = colors.tapped
		else
			color = colors.reaction[reaction]
		end
	else
		color = colors.normal
	end

	-- this can sometimes happen when hovering over battlepets
	if (not name) or (not color) then
		tooltip:Hide()
		return
	end

	-- clean up the tip
	for i = 2, tooltip:NumLines() do
		local line = _G[tooltip:GetName().."TextLeft"..i]
		if line then
			--line:SetTextColor(unpack(colors.quest.gray)) -- for the time being this will just be confusing
			local text = line:GetText()
			if text then
				if (text == PVP_ENABLED) then
					line:SetText("") -- kill pvp line, we're adding icons instead!
				end
				if (text == FACTION_ALLIANCE) or (text == FACTION_HORDE) then
					line:SetText("") -- kill faction name, the pvp icons will describe this well enough!
				end
				if text == " " then
					local nextLine = _G[tooltip:GetName().."TextLeft"..(i + 1)]
					if nextLine then
						local nextText = nextLine:GetText()
						if (COALESCED_REALM_TOOLTIP and INTERACTIVE_REALM_TOOLTIP) then -- super simple check for connected realms
							if (nextText == COALESCED_REALM_TOOLTIP) or (nextText == INTERACTIVE_REALM_TOOLTIP) then
								line:SetText("")
								nextLine:SetText(nil)
							end
						end
					end
				end
			end
		end
	end

	for i in ipairs(NAME_STRING) do 
		NAME_STRING[i] = nil
	end

	if isplayer then
		if ffa then
			NAME_STRING[#NAME_STRING + 1] = FFA_TEXTURE
		elseif (pvp and faction) then
			if (faction == "Horde") then
				NAME_STRING[#NAME_STRING + 1] = FACTION_HORDE_TEXTURE
			elseif (faction == "Alliance") then
				NAME_STRING[#NAME_STRING + 1] = FACTION_ALLIANCE_TEXTURE
			elseif (faction == "Neutral") then
				-- They changed this to their new atlas garbage in Legion, 
				-- so for the sake of simplicty we'll just use the FFA PvP icon instead. Works.
				NAME_STRING[#NAME_STRING + 1] = FFA_TEXTURE
			end
		end
		NAME_STRING[#NAME_STRING + 1] = name
	else
		if isboss then
			NAME_STRING[#NAME_STRING + 1] = BOSS_TEXTURE
		end
		NAME_STRING[#NAME_STRING + 1] = name
	end

	-- Need color codes for the text to always be correctly colored,
	-- or blizzard will from time to time overwrite it with their own.
	local title = _G[tooltip:GetName().."TextLeft1"]
	local r, g, b = color[1], color[2], color[3]
	title:SetFormattedText("|cff%02X%02X%02X%s|r", math_floor(r*255), math_floor(g*255), math_floor(b*255), table_concat(NAME_STRING, " ")) 

	-- Color the statusbar in the same color as the unit name.
	local statusbar = _G[tooltip:GetName().."StatusBar"]
	if (statusbar and statusbar:IsShown()) then
		if (color == colors.normal) then
			color = colors.quest.green
		end 
		statusbar:SetStatusBarColor(color[1], color[2], color[3], 1)
		statusbar.color = color
	end	
end

local StatusBar_OnValueChanged = function(statusbar)
	local value = statusbar:GetValue()
	local min, max = statusbar:GetMinMaxValues()
	
	-- Hide the bar if values are missing, or if max or min is 0. 
	if (not min) or (not max) or (not value) or (max == 0) or (value == min) then
		statusbar:Hide()
		return
	end
	
	-- Just in case somebody messed up, 
	-- we silently correct out of range values.
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
	
	if statusbar.value then
		StatusBar_UpdateValue(statusbar, value, max)
	end

	-- Because blizzard shrink the textures instead of cropping them.
	statusbar:GetStatusBarTexture():SetTexCoord(0, (value-min)/(max-min), 0, 1)

	-- Add the green if no other color was detected. Like objects that aren't units, but still have health. 
	if (not statusbar.color) or (not statusbar:GetParent().unit) then
		local colors = statusbar:GetParent().colors or Layout.Colors
		if colors then 
			statusbar.color = colors.quest.green
		end 
	end

	-- The color needs to be updated, or it will pop back to green
	statusbar:SetStatusBarColor(unpack(statusbar.color))
end

local StatusBar_OnShow = function(statusbar)
	Module:SetBlizzardTooltipBackdropOffsets(statusbar._owner, 10, 10, 10, 18)
	StatusBar_OnValueChanged(statusbar)
end

-- Do a color and texture reset upon hiding, to make sure it looks right when next shown. 
local StatusBar_OnHide = function(statusbar)
	local colors = statusbar:GetParent().colors or Layout.Colors
	if colors then 
		statusbar.color = colors.quest.green
	end 
	statusbar:GetStatusBarTexture():SetTexCoord(0, 1, 0, 1)
	statusbar:SetStatusBarColor(unpack(statusbar.color))
	Module:SetBlizzardTooltipBackdropOffsets(statusbar._owner, 10, 10, 10, 12)
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[TooltipStyling]")
end 

Module.OnEnable = function(self)
	for tooltip in self:GetAllBlizzardTooltips() do 
		self:KillBlizzardBorderedFrameTextures(tooltip)
		self:KillBlizzardTooltipBackdrop(tooltip)
		self:SetBlizzardTooltipBackdrop(tooltip, Layout.TooltipBackdrop)
		self:SetBlizzardTooltipBackdropColor(tooltip, unpack(Layout.TooltipBackdropColor))
		self:SetBlizzardTooltipBackdropBorderColor(tooltip, unpack(Layout.TooltipBackdropBorderColor))
		self:SetBlizzardTooltipBackdropOffsets(tooltip, 10, 10, 10, 12)

		if tooltip:HasScript("OnTooltipSetUnit") then 
			tooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
		end

		if tooltip:HasScript("OnHide") then 
			tooltip:HookScript("OnHide", OnTooltipHide)
		end

		local bar = _G[tooltip:GetName().."StatusBar"]
		if bar then 
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 3, 1  -2)
			bar:SetPoint("TOPRIGHT", tooltip, "BOTTOMRIGHT", -3, 1  -2)
			bar:SetHeight(3)
			bar._owner = tooltip

			bar.value = bar:CreateFontString()
			bar.value:SetDrawLayer("OVERLAY")
			bar.value:SetFontObject(Game12Font_o1)
			bar.value:SetPoint("CENTER", 0, 0)
			bar.value:SetTextColor(235/250, 235/250, 235/250, .75)

			bar:HookScript("OnShow", StatusBar_OnShow)
			bar:HookScript("OnHide", StatusBar_OnHide)
			bar:HookScript("OnValueChanged", StatusBar_OnValueChanged)

		end 
	end 
end 
