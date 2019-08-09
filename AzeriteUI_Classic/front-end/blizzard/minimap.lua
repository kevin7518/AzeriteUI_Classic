local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "UnitHealth requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("Minimap", "LibEvent", "LibDB", "LibMinimap", "LibTooltip", "LibTime", "LibPlayerData")
local Layout, L

-- Don't grab buttons if these are active
local MBB = Module:IsAddOnEnabled("MBB") 
local MBF = Module:IsAddOnEnabled("MinimapButtonFrame")

-- Lua API
local _G = _G
local math_floor = math.floor
local math_pi = math.pi
local select = select
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_upper = string.upper
local tonumber = tonumber
local unpack = unpack

-- WoW API
local FindActiveAzeriteItem = C_AzeriteItem and C_AzeriteItem.FindActiveAzeriteItem
local GetAzeriteItemXPInfo = C_AzeriteItem and C_AzeriteItem.GetAzeriteItemXPInfo
local GetFactionInfo = _G.GetFactionInfo
local GetFactionParagonInfo = C_Reputation and C_Reputation.GetFactionParagonInfo
local GetFramerate = _G.GetFramerate
local GetFriendshipReputation = _G.GetFriendshipReputation
local GetNetStats = _G.GetNetStats
local GetNumFactions = _G.GetNumFactions
local GetPowerLevel = C_AzeriteItem and C_AzeriteItem.GetPowerLevel
local GetWatchedFactionInfo = _G.GetWatchedFactionInfo
local IsFactionParagon = C_Reputation and C_Reputation.IsFactionParagon
local IsXPUserDisabled = _G.IsXPUserDisabled
local SetCursor = _G.SetCursor
local ToggleCalendar = _G.ToggleCalendar
local UnitExists = _G.UnitExists
local UnitLevel = _G.UnitLevel
local UnitRace = _G.UnitRace

-- WoW Strings
local REPUTATION = _G.REPUTATION 
local STANDING = _G.STANDING 
local UNKNOWN = _G.UNKNOWN

local Spinner = {}
local NEW = [[|TInterface\OptionsFrame\UI-OptionsFrame-NewFeatureIcon:0:0:0:0|t]]
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s (%s)"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %.0f"
local LEVEL = UnitLevel("player")
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

local defaults = {
	useStandardTime = true, -- as opposed to military/24-hour time
	useServerTime = false, -- as opposed to your local computer time
	stickyBars = false
}

local degreesToRadians = function(degrees)
	return degrees * (2*math_pi)/180
end 

local getTimeStrings = function(h, m, suffix, useStandardTime, abbreviateSuffix)
	if useStandardTime then 
		return "%.0f:%02.0f |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
	else 
		return "%02.0f:%02.0f", h, m
	end 
end 

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
		return tostring(math_floor(value))
	end	
end

-- zhCN exceptions
local gameLocale = GetLocale()
if (gameLocale == "zhCN") then 
	short = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(math_floor(value))
		end 
	end
end 

local MouseIsOver = function(frame)
	return (frame == GetMouseFocus())
end

-- Callbacks
----------------------------------------------------
local Coordinates_OverrideValue = function(element, x, y)
	local xval = string_gsub(string_format("%.1f", x*100), "%.(.+)", "|cff888888.%1|r")
	local yval = string_gsub(string_format("%.1f", y*100), "%.(.+)", "|cff888888.%1|r")
	element:SetFormattedText("%s %s", xval, yval) 
end 

local Clock_OverrideValue = function(element, h, m, suffix)
	element:SetFormattedText(getTimeStrings(h, m, suffix, element.useStandardTime, true))
end 

local FrameRate_OverrideValue = function(element, fps)
	element:SetFormattedText("|cff888888%.0f %s|r", math_floor(fps), string_upper(string_match(FPS_ABBR, "^.")))
end 

local Latency_OverrideValue = function(element, home, world)
	element:SetFormattedText("|cff888888%s|r %.0f - |cff888888%s|r %.0f", string_upper(string_match(HOME, "^.")), math_floor(home), string_upper(string_match(WORLD, "^.")), math_floor(world))
end 

local Performance_UpdateTooltip = function(self)
	local tooltip = Module:GetMinimapTooltip()

	local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
	local fps = GetFramerate()

	local colors = self._owner.colors 
	local rt, gt, bt = unpack(colors.title)
	local r, g, b = unpack(colors.normal)
	local rh, gh, bh = unpack(colors.highlight)
	local rg, gg, bg = unpack(colors.quest.green)

	tooltip:SetDefaultAnchor(self)
	tooltip:SetMaximumWidth(360)
	tooltip:AddLine(L["Network Stats"], rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["World latency:"], ("%.0f|cff888888%s|r"):format(math_floor(latencyWorld), MILLISECONDS_ABBR), rh, gh, bh, r, g, b)
	tooltip:AddLine(L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."], rg, gg, bg, true)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["Home latency:"], ("%.0f|cff888888%s|r"):format(math_floor(latencyHome), MILLISECONDS_ABBR), rh, gh, bh, r, g, b)
	tooltip:AddLine(L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."], rg, gg, bg, true)
	tooltip:Show()
end 

local Performance_OnEnter = function(self)
	self.UpdateTooltip = Performance_UpdateTooltip
	self:UpdateTooltip()
end 

local Performance_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

-- This is the XP and AP tooltip (and rep/honor later on) 
local Toggle_UpdateTooltip = function(toggle)

	local tooltip = Module:GetMinimapTooltip()

	local hasXP = Module.PlayerHasXP()
	local hasRep = Module.PlayerHasRep()
	local hasAP = (not IS_CLASSIC) and FindActiveAzeriteItem()

	local NC = "|r"
	local colors = toggle._owner.colors 
	local rt, gt, bt = unpack(colors.title)
	local r, g, b = unpack(colors.normal)
	local rh, gh, bh = unpack(colors.highlight)
	local rgg, ggg, bgg = unpack(colors.quest.gray)
	local rg, gg, bg = unpack(colors.quest.green)
	local rr, gr, br = unpack(colors.quest.red)
	local green = colors.quest.green.colorCode
	local normal = colors.normal.colorCode
	local highlight = colors.highlight.colorCode

	local resting, restState, restedName, mult
	local restedLeft, restedTimeLeft

	if hasXP or hasAP or hasRep then 
		tooltip:SetDefaultAnchor(toggle)
		tooltip:SetMaximumWidth(360)
	end

	-- XP tooltip
	-- Currently more or less a clone of the blizzard tip, we should improve!
	if hasXP then 
		resting = IsResting()
		restState, restedName, mult = GetRestState()
		restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
		
		local min, max = UnitXP("player"), UnitXPMax("player")

		tooltip:AddDoubleLine(POWER_TYPE_EXPERIENCE, LEVEL or UnitLevel("player"), rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current XP: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)

		-- add rested bonus if it exists
		if (restedLeft and (restedLeft > 0)) then
			tooltip:AddDoubleLine(L["Rested Bonus: "], fullXPString:format(normal..short(restedLeft)..NC, normal..short(max * maxRested)..NC, highlight..math_floor(restedLeft/(max * maxRested)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
		end
		
	end 

	-- Rep tooltip
	if hasRep then 

		local name, reaction, min, max, current, factionID = GetWatchedFactionInfo()
		if (factionID and IsFactionParagon(factionID)) then
			local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(factionID)
			if (currentValue and threshold) then
				min, max = 0, threshold
				current = currentValue % threshold
				if hasRewardPending then
					current = current + threshold
				end
			end
		end
	
		local standingID, isFriend, friendText
		local standingLabel, standingDescription
		for i = 1, GetNumFactions() do
			local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
			
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
			
			if (factionName == name) then
				if friendID then
					isFriend = true
					if nextFriendThreshold then 
						min = friendThreshold
						max = nextFriendThreshold
					else
						min = 0
						max = friendMaxRep
						current = friendRep
					end 
					standingLabel = friendTextLevel
					standingDescription = friendText
				end
				standingID = standingId
				break
			end
		end

		if standingID then 
			if hasXP then 
				tooltip:AddLine(" ")
			end 
			if (not isFriend) then 
				standingLabel = _G["FACTION_STANDING_LABEL"..standingID]
			end 

			tooltip:AddDoubleLine(name, standingLabel, rt, gt, bt, rt, gt, bt)

			local barMax = max - min 
			local barValue = current - min
			if (barMax > 0) then 
				tooltip:AddDoubleLine(L["Current Standing: "], fullXPString:format(normal..short(current-min)..NC, normal..short(max-min)..NC, highlight..math_floor((current-min)/(max-min)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
			else 
				tooltip:AddDoubleLine(L["Current Standing: "], "100%", rh, gh, bh, r, g, b)
			end 
		else 
			-- Don't add additional spaces if we can't display the information
			hasRep = nil
		end
	end

	-- New BfA Artifact Power tooltip!
	if hasAP then 
		if hasXP or hasRep then 
			tooltip:AddLine(" ")
		end 

		local min, max = GetAzeriteItemXPInfo(hasAP)
		local level = GetPowerLevel(hasAP) 

		tooltip:AddDoubleLine(ARTIFACT_POWER, level, rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current Artifact Power: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
	end 

	if hasXP then 
		if (restState == 1) then
			if resting and restedTimeLeft and restedTimeLeft > 0 then
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Resting"], rh, gh, bh)
				if restedTimeLeft > hour*2 then
					tooltip:AddLine(L["You must rest for %s additional hours to become fully rested."]:format(highlight..math_floor(restedTimeLeft/hour)..NC), r, g, b, true)
				else
					tooltip:AddLine(L["You must rest for %s additional minutes to become fully rested."]:format(highlight..math_floor(restedTimeLeft/minute)..NC), r, g, b, true)
				end
			else
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Rested"], rh, gh, bh)
				tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		elseif (restState >= 2) then
			if not(restedTimeLeft and restedTimeLeft > 0) then 
				tooltip:AddLine(" ")
				tooltip:AddLine(L["You should rest at an Inn."], rr, gr, br)
			else
				-- No point telling people there's nothing to tell them, is there?
				--tooltip:AddLine(" ")
				--tooltip:AddLine(L["Normal"], rh, gh, bh)
				--tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		end
	end 

	-- Only adding the sticky toggle to the toggle button for now, not the frame.
	if MouseIsOver(toggle) then 
		tooltip:AddLine(" ")
		if Module.db.stickyBars then 
			tooltip:AddLine(L["%s to disable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
		else 
			tooltip:AddLine(L["%s to enable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
		end 
	end 

	tooltip:Show()
end 

local Toggle_OnUpdate = function(toggle, elapsed)

	if toggle.fadeDelay > 0 then 
		local fadeDelay = toggle.fadeDelay - elapsed
		if fadeDelay > 0 then 
			toggle.fadeDelay = fadeDelay
			return 
		else 
			toggle.fadeDelay = 0
			toggle.timeFading = 0
		end 
	end 

	toggle.timeFading = toggle.timeFading + elapsed

	if toggle.fadeDirection == "OUT" then 
		local alpha = 1 - (toggle.timeFading / toggle.fadeDuration)
		if alpha > 0 then 
			toggle.Frame:SetAlpha(alpha)
		else 
			toggle:SetScript("OnUpdate", nil)
			toggle.Frame:Hide()
			toggle.Frame:SetAlpha(0)
			toggle.fading = nil 
			toggle.fadeDirection = nil
			toggle.fadeDuration = 0
			toggle.timeFading = 0
		end 

	elseif toggle.fadeDirection == "IN" then 
		local alpha = toggle.timeFading / toggle.fadeDuration
		if alpha < 1 then 
			toggle.Frame:SetAlpha(alpha)
		else 
			toggle:SetScript("OnUpdate", nil)
			toggle.Frame:SetAlpha(1)
			toggle.fading = nil
			toggle.fadeDirection = nil
			toggle.fadeDuration = 0
			toggle.timeFading = 0
		end 
	end 

end 

-- This method is called upon entering or leaving 
-- either the toggle button, the visible ring frame, 
-- or by clicking the toggle button. 
-- Its purpose should be to decide ring frame visibility. 
local Toggle_UpdateFrame = function(toggle)
	local db = Module.db
	local frame = toggle.Frame
	local frameIsShown = frame:IsShown()

	-- If sticky bars is enabled, we should only fade in, and keep it there, 
	-- and then just remove the whole update handler until the sticky setting is changed. 
	if db.stickyBars then 

		-- if the frame isn't shown, 
		-- reset the alpha and initiate fade-in
		if (not frameIsShown) then 
			frame:SetAlpha(0)
			frame:Show()

			toggle.fadeDirection = "IN"
			toggle.fadeDelay = 0
			toggle.fadeDuration = .25
			toggle.timeFading = 0
			toggle.fading = true

			if not toggle:GetScript("OnUpdate") then 
				toggle:SetScript("OnUpdate", Toggle_OnUpdate)
			end
	
		-- If it is shown, we should probably just keep going. 
		-- This is probably just called because the user moved 
		-- between the toggle button and the frame. 
		else 


		end

	-- Move towards full visibility if we're over the toggle or the visible frame
	elseif toggle.isMouseOver or frame.isMouseOver then 

		-- If we entered while fading, it's most likely a fade-out that needs to be reversed.
		if toggle.fading then 
			if toggle.fadeDirection == "OUT" then 
				toggle.fadeDirection = "IN"
				toggle.fadeDuration = .25
				toggle.fadeDelay = 0
				toggle.timeFading = 0

				if not toggle:GetScript("OnUpdate") then 
					toggle:SetScript("OnUpdate", Toggle_OnUpdate)
				end
			else 
				-- Can't see this happening?
			end 

		-- If it's not fading it's either because it's hidden, at full alpha,  
		-- or because sticky bars just got disabled and it's still fully visible. 
		else 
			if frameIsShown then 
				-- Sticky bars? 
			else 
				frame:SetAlpha(0)
				frame:Show()
				toggle.fadeDirection = "IN"
				toggle.fadeDuration = .25
				toggle.fadeDelay = 0
				toggle.timeFading = 0
				toggle.fading = true

				if not toggle:GetScript("OnUpdate") then 
					toggle:SetScript("OnUpdate", Toggle_OnUpdate)
				end
			end 
		end  


	-- We're not above the toggle or a visible frame, 
	-- so we should initiate a fade-out. 
	else 

		-- if the frame is visible, this should be a fade-out.
		if frameIsShown then 

			toggle.fadeDirection = "OUT"

			-- Only initiate the fade delay if the frame previously was fully shown,
			-- do not start a delay if we moved back into a fading frame then out again 
			-- before it could reach its full alpha, or the frame will appear to be "stuck"
			-- in a semi-transparent state for a few seconds. Ewwww. 
			if toggle.fading then 
				toggle.fadeDelay = 0
				toggle.fadeDuration = (.25 - (toggle.timeFading or 0))
				toggle.timeFading = toggle.timeFading or 0
			else 
				toggle.fadeDelay = .5
				toggle.fadeDuration = .25
				toggle.timeFading = 0
				toggle.fading = true
			end 

			if not toggle:GetScript("OnUpdate") then 
				toggle:SetScript("OnUpdate", Toggle_OnUpdate)
			end
	
		end
	end
end

local Toggle_OnMouseUp = function(toggle, button)
	local db = Module.db
	db.stickyBars = not db.stickyBars

	Toggle_UpdateFrame(toggle)

	if toggle.UpdateTooltip then 
		toggle:UpdateTooltip()
	end 

	if Module.db.stickyBars then 
		print(toggle._owner.colors.title.colorCode..L["Sticky Minimap bars enabled."].."|r")
	else
		print(toggle._owner.colors.title.colorCode..L["Sticky Minimap bars disabled."].."|r")
	end 	
end

local Toggle_OnEnter = function(toggle)
	toggle.UpdateTooltip = Toggle_UpdateTooltip
	toggle.isMouseOver = true

	Toggle_UpdateFrame(toggle)

	toggle:UpdateTooltip()
end

local Toggle_OnLeave = function(toggle)
	local db = Module.db

	toggle.isMouseOver = nil
	toggle.UpdateTooltip = nil

	-- Update this to avoid a flicker or delay 
	-- when moving directly from the toggle button to the ringframe.  
	toggle.Frame.isMouseOver = MouseIsOver(toggle.Frame)

	Toggle_UpdateFrame(toggle)
	
	if (not toggle.Frame.isMouseOver) then 
		Module:GetMinimapTooltip():Hide()
	end 
end

local RingFrame_UpdateTooltip = function(frame)
	local toggle = frame._owner

	Toggle_UpdateTooltip(toggle)
end 

local RingFrame_OnEnter = function(frame)
	local toggle = frame._owner

	frame.UpdateTooltip = RingFrame_UpdateTooltip
	frame.isMouseOver = true

	Toggle_UpdateFrame(toggle)

	frame:UpdateTooltip()
end

local RingFrame_OnLeave = function(frame)
	local db = Module.db
	local toggle = frame._owner

	frame.isMouseOver = nil
	frame.UpdateTooltip = nil

	-- Update this to avoid a flicker or delay 
	-- when moving directly from the ringframe to the toggle button.  
	toggle.isMouseOver = MouseIsOver(toggle)

	Toggle_UpdateFrame(toggle)
	
	if (not toggle.isMouseOver) then 
		Module:GetMinimapTooltip():Hide()
	end 
end

local Time_UpdateTooltip = function(self)
	local tooltip = Module:GetMinimapTooltip()

	local colors = self._owner.colors 
	local rt, gt, bt = unpack(colors.title)
	local r, g, b = unpack(colors.normal)
	local rh, gh, bh = unpack(colors.highlight)
	local rg, gg, bg = unpack(colors.quest.green)
	local green = colors.quest.green.colorCode
	local NC = "|r"

	local useStandardTime = Module.db.useStandardTime
	local useServerTime = Module.db.useServerTime

	-- client time
	local lh, lm, lsuffix = Module:GetLocalTime(useStandardTime)

	-- server time
	local sh, sm, ssuffix = Module:GetServerTime(useStandardTime)

	tooltip:SetDefaultAnchor(self)
	tooltip:SetMaximumWidth(360)
	tooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, lsuffix, useStandardTime)), rh, gh, bh, r, g, b)
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ssuffix, useStandardTime)), rh, gh, bh, r, g, b)
	tooltip:AddLine(" ")

	if (not IS_CLASSIC) then 
		tooltip:AddLine(L["%s to toggle calendar."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
	end

	if useServerTime then 
		tooltip:AddLine(L["%s to use local computer time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to use game server time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	end 

	if useStandardTime then 
		tooltip:AddLine(L["%s to use military (24-hour) time."]:format(green..L["<Right-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to use standard (12-hour) time."]:format(green..L["<Right-Click>"]..NC), rh, gh, bh)
	end 

	tooltip:Show()
end 

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end 

local Time_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

local Time_OnClick = function(self, mouseButton)
	if (mouseButton == "LeftButton") then
		if (ToggleCalendar) then 
			ToggleCalendar()
		end 

	elseif (mouseButton == "MiddleButton") then 
		Module.db.useServerTime = not Module.db.useServerTime

		self.clock.useServerTime = Module.db.useServerTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Module.db.useServerTime then 
			print(self._owner.colors.title.colorCode..L["Now using game server time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using local computer time."].."|r")
		end 

	elseif (mouseButton == "RightButton") then 
		Module.db.useStandardTime = not Module.db.useStandardTime

		self.clock.useStandardTime = Module.db.useStandardTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Module.db.useStandardTime then 
			print(self._owner.colors.title.colorCode..L["Now using standard (12-hour) time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using military (24-hour) time."].."|r")
		end 
	end
end

local Zone_OnEnter = function(self)
	local tooltip = Module:GetMinimapTooltip()

end 

local Zone_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
end 

local PostUpdate_XP = function(element, min, max, restedLeft, restedTimeLeft)
	local description = element.Value and element.Value.Description
	if description then 
		local level = LEVEL or UnitLevel("player")
		if (level and (level > 0)) then 
			description:SetFormattedText(L["to level %s"], level + 1)
		else 
			description:SetText("")
		end 
	end 
end

local PostUpdate_Rep = function(element, current, min, max, factionName, standingID, standingLabel, isFriend)
	local description = element.Value and element.Value.Description
	if description then 
		if (standingID == MAX_REPUTATION_REACTION) then
			description:SetText(standingLabel)
		else
			if isFriend then 
				if standingLabel then 
					description:SetFormattedText(L["%s"], standingLabel)
				else
					description:SetText("")
				end 
			else 
				local nextStanding = standingID and _G["FACTION_STANDING_LABEL"..(standingID + 1)]
				if nextStanding then 
					description:SetFormattedText(L["to %s"], nextStanding)
				else
					description:SetText("")
				end 
			end 
		end 
	end 
end

local PostUpdate_AP = function(element, min, max, level)
	local description = element.Value and element.Value.Description
	if description then 
		description:SetText(L["to next trait"])
	end 
end

local XP_OverrideValue = function(element, min, max, restedLeft, restedTimeLeft)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value.showDeficit then 
		value:SetFormattedText(short(max - min))
	else 
		value:SetFormattedText(short(min))
	end
	local percent = value.Percent
	if percent then 
		if (max > 0) then 
			local percValue = math_floor(min/max*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%.0f", percValue)
			else 
				percent:SetText("xp") -- no localization for this
			end 
		else 
			percent:SetText(NEW) 
		end 
	end 
	if element.colorValue then 
		local color
		if restedLeft then 
			local colors = element._owner.colors
			color = colors.restedValue or colors.rested or colors.xpValue or colors.xp
		else 
			local colors = element._owner.colors
			color = colors.xpValue or colors.xp
		end 
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

local Rep_OverrideValue = function(element, current, min, max, factionName, standingID, standingLabel, isFriend)
	local value = element.Value or element:IsObjectType("FontString") and element 
	local barMax = max - min 
	local barValue = current - min
	if value.showDeficit then 
		if (barMax - barValue > 0) then 
			value:SetFormattedText(short(barMax - barValue))
		else 
			value:SetText("100%")
		end 
	else 
		value:SetFormattedText(short(current - min))
	end
	local percent = value.Percent
	if percent then 
		if (max - min > 0) then 
			local percValue = math_floor((current - min)/(max - min)*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%.0f", percValue)
			else 
				percent:SetText("rp") 
			end 
		else 
			percent:SetText(NEW) 
		end 
	end 
	if element.colorValue then 
		local color = element._owner.colors[isFriend and "friendship" or "reaction"][standingID]
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end

local AP_OverrideValue = function(element, min, max, level)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value.showDeficit then 
		value:SetFormattedText(short(max - min))
	else 
		value:SetFormattedText(short(min))
	end
	local percent = value.Percent
	if percent then 
		if (max > 0) then 
			local percValue = math_floor(min/max*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%.0f", percValue)
			else 
				percent:SetText(NEW) 
			end 
		else 
			percent:SetText("ap") 
		end 
	end 
	if element.colorValue then 
		local color = element._owner.colors.artifact
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

Module.SetUpMinimap = function(self)

	local db = self.db


	-- Frame
	----------------------------------------------------
	-- This is needed to initialize the map to 
	-- the most recent version of the library.
	-- All other calls will fail without it.
	self:SyncMinimap() 

	-- Retrieve an unique element handler for our module
	local Handler = self:GetMinimapHandler()
	Handler.colors = Layout.Colors
	
	-- Reposition minimap tooltip 
	local tooltip = self:GetMinimapTooltip()

	-- Blob & Ring Textures
	----------------------------------------------------
	-- Set the alpha values of the various map blob and ring textures. Values range from 0-255. 
	-- Using tested versions from DiabolicUI, which makes the map IMO much more readable. 
	self:SetMinimapBlobAlpha(unpack(Layout.BlobAlpha)) 

	if Layout.UseBlipTextures then 
		for patch,path in pairs(Layout.BlipTextures) do 
			self:SetMinimapBlips(path, patch)
		end
	end

	if Layout.BlipScale then 
		self:SetMinimapScale(Layout.BlipScale)
	end

	-- Minimap Buttons
	----------------------------------------------------
	-- Only allow these when MBB is loaded. 
	self:SetMinimapAllowAddonButtons(self.MBB)

	-- Minimap Compass
	if Layout.UseCompass then 
		self:SetMinimapCompassEnabled(true)
		self:SetMinimapCompassText(unpack(Layout.CompassTexts)) 
		self:SetMinimapCompassTextFontObject(Layout.CompassFont) 
		self:SetMinimapCompassTextColor(unpack(Layout.CompassColor)) 
		self:SetMinimapCompassRadiusInset(Layout.CompassRadiusInset) 
	end 
	
	-- Background
	if Layout.UseMapBackdrop then 
		local mapBackdrop = Handler:CreateBackdropTexture()
		mapBackdrop:SetDrawLayer("BACKGROUND")
		mapBackdrop:SetAllPoints()
		mapBackdrop:SetTexture(Layout.MapBackdropTexture)
		mapBackdrop:SetVertexColor(unpack(Layout.MapBackdropColor))
	end 

	-- Overlay
	if Layout.UseMapOverlay then 
		local mapOverlay = Handler:CreateContentTexture()
		mapOverlay:SetDrawLayer("BORDER")
		mapOverlay:SetAllPoints()
		mapOverlay:SetTexture(Layout.MapOverlayTexture)
		mapOverlay:SetVertexColor(unpack(Layout.MapOverlayColor))
	end 
	
	-- Border
	if Layout.UseMapBorder then 
		local border = Handler:CreateOverlayTexture()
		border:SetDrawLayer("BACKGROUND")
		border:SetTexture(Layout.MapBorderTexture)
		border:SetSize(unpack(Layout.MapBorderSize))
		border:SetVertexColor(unpack(Layout.MapBorderColor))
		border:SetPoint(unpack(Layout.MapBorderPlace))
		Handler.Border = border
	end 

	-- Mail
	if Layout.UseMail then 
		local mail = Handler:CreateOverlayFrame()
		mail:SetSize(unpack(Layout.MailSize)) 
		mail:Place(unpack(Layout.MailPlace)) 

		local icon = mail:CreateTexture()
		icon:SetTexture(Layout.MailTexture)
		icon:SetDrawLayer(unpack(Layout.MailTextureDrawLayer))
		icon:SetPoint(unpack(Layout.MailTexturePlace))
		icon:SetSize(unpack(Layout.MailTextureSize)) 

		if Layout.MailTextureRotation then 
			icon:SetRotation(Layout.MailTextureRotation)
		end 

		Handler.Mail = mail 
	end 

	-- Clock 
	if Layout.UseClock then 
		local clockFrame 
		if Layout.ClockFrameInOverlay then 
			clockFrame = Handler:CreateOverlayFrame("Button")
		else 
			clockFrame = Handler:CreateBorderFrame("Button")
		end 
		Handler.ClockFrame = clockFrame

		local clock = Handler:CreateFontString()
		clock:SetPoint(unpack(Layout.ClockPlace)) 
		clock:SetDrawLayer("OVERLAY")
		clock:SetJustifyH("RIGHT")
		clock:SetJustifyV("BOTTOM")
		clock:SetFontObject(Layout.ClockFont)
		clock:SetTextColor(unpack(Layout.ClockColor))
		clock.useStandardTime = self.db.useStandardTime -- standard (12-hour) or military (24-hour) time
		clock.useServerTime = self.db.useServerTime -- realm time or local time
		clock.showSeconds = false -- show seconds in the clock
		clock.OverrideValue = Clock_OverrideValue

		-- Make the clock clickable to change time settings 
		clockFrame:SetAllPoints(clock)
		clockFrame:SetScript("OnEnter", Time_OnEnter)
		clockFrame:SetScript("OnLeave", Time_OnLeave)
		clockFrame:SetScript("OnClick", Time_OnClick)

		-- Register all buttons separately, as "AnyUp" doesn't include the middle button!
		clockFrame:RegisterForClicks("RightButtonUp", "LeftButtonUp", "MiddleButtonUp")
		
		clockFrame.clock = clock
		clockFrame._owner = Handler

		clock:SetParent(clockFrame)

		Handler.Clock = clock		
	end 

	-- Zone Information
	if Layout.UseZone then 
		local zoneFrame = Handler:CreateBorderFrame()
		Handler.ZoneFrame = zoneFrame
	
		local zone = zoneFrame:CreateFontString()
		if Layout.ZonePlaceFunc then 
			zone:SetPoint(Layout.ZonePlaceFunc(Handler)) 
		else 
			zone:SetPoint(unpack(Layout.ZonePlace)) 
		end
	
		zone:SetDrawLayer("OVERLAY")
		zone:SetJustifyH("RIGHT")
		zone:SetJustifyV("BOTTOM")
		zone:SetFontObject(Layout.ZoneFont)
		zone:SetAlpha(Layout.ZoneAlpha or 1)
		zone.colorPvP = true -- color zone names according to their PvP type 
		zone.colorcolorDifficulty = true -- color instance names according to their difficulty
	
		-- Strap the frame to the text
		zoneFrame:SetAllPoints(zone)
		zoneFrame:SetScript("OnEnter", Zone_OnEnter)
		zoneFrame:SetScript("OnLeave", Zone_OnLeave)
	
		Handler.Zone = zone	
	end 

	-- Coordinates
	if Layout.UseCoordinates then 
		local coordinates = Handler:CreateBorderText()

		if Layout.CoordinatePlaceFunc then 
			coordinates:SetPoint(Layout.CoordinatePlaceFunc(Handler)) 
		else
			coordinates:SetPoint(unpack(Layout.CoordinatePlace)) 
		end 

		coordinates:SetDrawLayer("OVERLAY")
		coordinates:SetJustifyH("CENTER")
		coordinates:SetJustifyV("BOTTOM")
		coordinates:SetFontObject(Layout.CoordinateFont)
		coordinates:SetTextColor(unpack(Layout.CoordinateColor)) 
		coordinates.OverrideValue = Coordinates_OverrideValue

		Handler.Coordinates = coordinates
	end 
		
	-- Performance Information
	if Layout.UsePerformance then 
		local performanceFrame = Handler:CreateBorderFrame()
		performanceFrame._owner = Handler
		Handler.PerformanceFrame = performanceFrame
	
		local framerate = performanceFrame:CreateFontString()
		framerate:SetDrawLayer("OVERLAY")
		framerate:SetJustifyH("RIGHT")
		framerate:SetJustifyV("BOTTOM")
		framerate:SetFontObject(Layout.FrameRateFont)
		framerate:SetTextColor(unpack(Layout.FrameRateColor))
		framerate.OverrideValue = FrameRate_OverrideValue
	
		Handler.FrameRate = framerate
	
		local latency = performanceFrame:CreateFontString()
		latency:SetDrawLayer("OVERLAY")
		latency:SetJustifyH("CENTER")
		latency:SetJustifyV("BOTTOM")
		latency:SetFontObject(Layout.LatencyFont)
		latency:SetTextColor(unpack(Layout.LatencyColor))
		latency.OverrideValue = Latency_OverrideValue
	
		Handler.Latency = latency
	
		-- Strap the frame to the text
		performanceFrame:SetScript("OnEnter", Performance_OnEnter)
		performanceFrame:SetScript("OnLeave", Performance_OnLeave)
	
		if Layout.FrameRatePlaceFunc then
			framerate:Place(Layout.FrameRatePlaceFunc(Handler)) 
		else 
			framerate:Place(unpack(Layout.FrameRatePlace)) 
		end 

		if Layout.LatencyPlaceFunc then
			latency:Place(Layout.LatencyPlaceFunc(Handler)) 
		else 
			latency:Place(unpack(Layout.LatencyPlace)) 
		end 

		if Layout.PerformanceFramePlaceAdvancedFunc then 
			Layout.PerformanceFramePlaceAdvancedFunc(performanceFrame, Handler)
		end 
	end 

	if Layout.UseStatusRings then 

		-- Ring frame
		local ringFrame = Handler:CreateOverlayFrame()
		ringFrame:Hide()
		ringFrame:SetAllPoints() -- set it to cover the map
		ringFrame:EnableMouse(true) -- make sure minimap blips and their tooltips don't punch through
		ringFrame:SetScript("OnEnter", RingFrame_OnEnter)
		ringFrame:SetScript("OnLeave", RingFrame_OnLeave)

		ringFrame:HookScript("OnShow", function() 
			local compassFrame = CogWheel("LibMinimap"):GetCompassFrame()
			if compassFrame then 
				compassFrame.supressCompass = true
			end 
		end)

		ringFrame:HookScript("OnHide", function() 
			local compassFrame = CogWheel("LibMinimap"):GetCompassFrame()
			if compassFrame then 
				compassFrame.supressCompass = nil
			end 
		end)

		-- Wait with this until now to trigger compass visibility changes
		ringFrame:SetShown(db.stickyBars) 

		-- ring frame backdrops
		local ringFrameBg = ringFrame:CreateTexture()
		ringFrameBg:SetPoint(unpack(Layout.RingFrameBackdropPlace))
		ringFrameBg:SetSize(unpack(Layout.RingFrameBackdropSize))  
		ringFrameBg:SetDrawLayer(unpack(Layout.RingFrameBackdropDrawLayer))
		ringFrameBg:SetTexture(Layout.RingFrameBackdropTexture)
		ringFrameBg:SetVertexColor(unpack(Layout.RingFrameBackdropColor))
		ringFrame.Bg = ringFrameBg

		-- Toggle button for ring frame
		local toggle = Handler:CreateOverlayFrame()
		toggle:SetFrameLevel(toggle:GetFrameLevel() + 10) -- need this above the ring frame and the rings
		toggle:SetPoint("CENTER", Handler, "BOTTOM", 2, -6)
		toggle:SetSize(unpack(Layout.ToggleSize))
		toggle:EnableMouse(true)
		toggle:SetScript("OnEnter", Toggle_OnEnter)
		toggle:SetScript("OnLeave", Toggle_OnLeave)
		toggle:SetScript("OnMouseUp", Toggle_OnMouseUp)
		toggle._owner = Handler
		ringFrame._owner = toggle
		toggle.Frame = ringFrame

		local toggleBackdrop = toggle:CreateTexture()
		toggleBackdrop:SetDrawLayer("BACKGROUND")
		toggleBackdrop:SetSize(unpack(Layout.ToggleBackdropSize))
		toggleBackdrop:SetPoint("CENTER", 0, 0)
		toggleBackdrop:SetTexture(Layout.ToggleBackdropTexture)
		toggleBackdrop:SetVertexColor(unpack(Layout.ToggleBackdropColor))

		Handler.Toggle = toggle
		
		-- outer ring
		local ring1 = ringFrame:CreateSpinBar()
		ring1:SetPoint(unpack(Layout.OuterRingPlace))
		ring1:SetSize(unpack(Layout.OuterRingSize)) 
		ring1:SetSparkOffset(Layout.OuterRingSparkOffset)
		ring1:SetSparkFlash(unpack(Layout.OuterRingSparkFlash))
		ring1:SetSparkBlendMode(Layout.OuterRingSparkBlendMode)
		ring1:SetClockwise(Layout.OuterRingClockwise) 
		ring1:SetDegreeOffset(Layout.OuterRingDegreeOffset) 
		ring1:SetDegreeSpan(Layout.OuterRingDegreeSpan)
		ring1.showSpark = Layout.OuterRingShowSpark 
		ring1.colorXP = Layout.OuterRingColorXP
		ring1.colorPower = Layout.OuterRingColorPower 
		ring1.colorStanding = Layout.OuterRingColorStanding 
		ring1.colorValue = Layout.OuterRingColorValue 
		ring1.backdropMultiplier = Layout.OuterRingBackdropMultiplier 
		ring1.sparkMultiplier = Layout.OuterRingSparkMultiplier

		-- outer ring value text
		local ring1Value = ring1:CreateFontString()
		ring1Value:SetPoint(unpack(Layout.OuterRingValuePlace))
		ring1Value:SetJustifyH(Layout.OuterRingValueJustifyH)
		ring1Value:SetJustifyV(Layout.OuterRingValueJustifyV)
		ring1Value:SetFontObject(Layout.OuterRingValueFont)
		ring1Value.showDeficit = Layout.OuterRingValueShowDeficit 
		ring1.Value = ring1Value

		-- outer ring value description text
		local ring1ValueDescription = ring1:CreateFontString()
		ring1ValueDescription:SetPoint(unpack(Layout.OuterRingValueDescriptionPlace))
		ring1ValueDescription:SetWidth(Layout.OuterRingValueDescriptionWidth)
		ring1ValueDescription:SetTextColor(unpack(Layout.OuterRingValueDescriptionColor))
		ring1ValueDescription:SetJustifyH(Layout.OuterRingValueDescriptionJustifyH)
		ring1ValueDescription:SetJustifyV(Layout.OuterRingValueDescriptionJustifyV)
		ring1ValueDescription:SetFontObject(Layout.OuterRingValueDescriptionFont)
		ring1ValueDescription:SetIndentedWordWrap(false)
		ring1ValueDescription:SetWordWrap(true)
		ring1ValueDescription:SetNonSpaceWrap(false)
		ring1.Value.Description = ring1ValueDescription

		local outerPercent = toggle:CreateFontString()
		outerPercent:SetDrawLayer("OVERLAY")
		outerPercent:SetJustifyH("CENTER")
		outerPercent:SetJustifyV("MIDDLE")
		outerPercent:SetFontObject(Layout.OuterRingValuePercentFont)
		outerPercent:SetShadowOffset(0, 0)
		outerPercent:SetShadowColor(0, 0, 0, 0)
		outerPercent:SetPoint("CENTER", 1, -1)
		ring1.Value.Percent = outerPercent

		-- inner ring 
		local ring2 = ringFrame:CreateSpinBar()
		ring2:SetPoint(unpack(Layout.InnerRingPlace))
		ring2:SetSize(unpack(Layout.InnerRingSize)) 
		ring2:SetSparkSize(unpack(Layout.InnerRingSparkSize))
		ring2:SetSparkInset(Layout.InnerRingSparkInset)
		ring2:SetSparkOffset(Layout.InnerRingSparkOffset)
		ring2:SetSparkFlash(unpack(Layout.InnerRingSparkFlash))
		ring2:SetSparkBlendMode(Layout.InnerRingSparkBlendMode)
		ring2:SetClockwise(Layout.InnerRingClockwise) 
		ring2:SetDegreeOffset(Layout.InnerRingDegreeOffset) 
		ring2:SetDegreeSpan(Layout.InnerRingDegreeSpan)
		ring2:SetStatusBarTexture(Layout.InnerRingBarTexture)
		ring2.showSpark = Layout.InnerRingShowSpark 
		ring2.colorXP = Layout.InnerRingColorXP
		ring2.colorPower = Layout.InnerRingColorPower 
		ring2.colorStanding = Layout.InnerRingColorStanding 
		ring2.colorValue = Layout.InnerRingColorValue 
		ring2.backdropMultiplier = Layout.InnerRingBackdropMultiplier 
		ring2.sparkMultiplier = Layout.InnerRingSparkMultiplier

		-- inner ring value text
		local ring2Value = ring2:CreateFontString()
		ring2Value:SetPoint("BOTTOM", ringFrameBg, "CENTER", 0, 2)
		ring2Value:SetJustifyH("CENTER")
		ring2Value:SetJustifyV("TOP")
		ring2Value:SetFontObject(Layout.InnerRingValueFont)
		ring2Value.showDeficit = true  
		ring2.Value = ring2Value

		local innerPercent = ringFrame:CreateFontString()
		innerPercent:SetDrawLayer("OVERLAY")
		innerPercent:SetJustifyH("CENTER")
		innerPercent:SetJustifyV("MIDDLE")
		innerPercent:SetFontObject(Layout.InnerRingValuePercentFont)
		innerPercent:SetShadowOffset(0, 0)
		innerPercent:SetShadowColor(0, 0, 0, 0)
		innerPercent:SetPoint("CENTER", ringFrameBg, "CENTER", 2, -64)
		ring2.Value.Percent = innerPercent

		-- Store the bars locally
		Spinner[1] = ring1
		Spinner[2] = ring2
		
	end 

	if Layout.UseGroupFinderEye then 
		local queueButton = QueueStatusMinimapButton
		if queueButton then 
			local button = Handler:CreateOverlayFrame()
			button:SetFrameLevel(button:GetFrameLevel() + 10) 
			button:Place(unpack(Layout.GroupFinderEyePlace))
			button:SetSize(unpack(Layout.GroupFinderEyeSize))

			queueButton:SetParent(button)
			queueButton:ClearAllPoints()
			queueButton:SetPoint("CENTER", 0, 0)
			queueButton:SetSize(unpack(Layout.GroupFinderEyeSize))

			if Layout.UseGroupFinderEyeBackdrop then 
				local backdrop = queueButton:CreateTexture()
				backdrop:SetDrawLayer("BACKGROUND", -6)
				backdrop:SetPoint("CENTER", 0, 0)
				backdrop:SetSize(unpack(Layout.GroupFinderEyeBackdropSize))
				backdrop:SetTexture(Layout.GroupFinderEyeBackdropTexture)
				backdrop:SetVertexColor(unpack(Layout.GroupFinderEyeBackdropColor))
			end 

			if Layout.GroupFinderEyeTexture then 
				local UIHider = CreateFrame("Frame")
				UIHider:Hide()
				queueButton.Eye.texture:SetParent(UIHider)
				queueButton.Eye.texture:SetAlpha(0)

				--local iconTexture = button:CreateTexture()
				local iconTexture = queueButton:CreateTexture()
				iconTexture:SetDrawLayer("ARTWORK", 1)
				iconTexture:SetPoint("CENTER", 0, 0)
				iconTexture:SetSize(unpack(Layout.GroupFinderEyeSize))
				iconTexture:SetTexture(Layout.GroupFinderEyeTexture)
				iconTexture:SetVertexColor(unpack(Layout.GroupFinderEyeColor))
			else
				queueButton.Eye:SetSize(unpack(Layout.GroupFinderEyeSize)) 
				queueButton.Eye.texture:SetSize(unpack(Layout.GroupFinderEyeSize))
			end 

			if Layout.GroupFinderQueueStatusPlace then 
				QueueStatusFrame:ClearAllPoints()
				QueueStatusFrame:SetPoint(unpack(Layout.GroupFinderQueueStatusPlace))
			end 
		end 
	end 

end 

-- Set up the MBB (MinimapButtonBag) integration
Module.SetUpMBB = function(self)

	local Handler = self:GetMinimapHandler()
	local button = Handler:CreateOverlayFrame()
	button:SetFrameLevel(button:GetFrameLevel() + 10) 
	button:Place(unpack(Layout.MBBPlace))
	button:SetSize(unpack(Layout.MBBSize))
	button:SetFrameStrata("MEDIUM") 

	local mbbFrame = _G.MBB_MinimapButtonFrame
	mbbFrame:SetParent(button)
	mbbFrame:RegisterForDrag()
	mbbFrame:SetSize(unpack(Layout.MBBSize)) 
	mbbFrame:ClearAllPoints()
	mbbFrame:SetFrameStrata("MEDIUM") 
	mbbFrame:SetPoint("CENTER", 0, 0)
	mbbFrame:SetHighlightTexture("") 
	mbbFrame:DisableDrawLayer("OVERLAY") 

	mbbFrame.ClearAllPoints = function() end
	mbbFrame.SetPoint = function() end
	mbbFrame.SetAllPoints = function() end

	local mbbIcon = _G.MBB_MinimapButtonFrame_Texture
	mbbIcon:ClearAllPoints()
	mbbIcon:SetPoint("CENTER", 0, 0)
	mbbIcon:SetSize(unpack(Layout.MBBSize))
	mbbIcon:SetTexture(Layout.MBBTexture)
	mbbIcon:SetTexCoord(0,1,0,1)
	mbbIcon:SetAlpha(.85)
	
	local down, over
	local setalpha = function()
		if (down and over) then
			mbbIcon:SetAlpha(1)
		elseif (down or over) then
			mbbIcon:SetAlpha(.95)
		else
			mbbIcon:SetAlpha(.85)
		end
	end

	mbbFrame:SetScript("OnMouseDown", function(self) 
		down = true
		setalpha()
	end)

	mbbFrame:SetScript("OnMouseUp", function(self) 
		down = false
		setalpha()
	end)

	mbbFrame:SetScript("OnEnter", function(self) 
		over = true
		_G.MBB_ShowTimeout = -1

		local tooltip = Module:GetMinimapTooltip()
		tooltip:SetDefaultAnchor(self)
		tooltip:SetMaximumWidth(320)
		tooltip:AddLine("MinimapButtonBag v" .. MBB_Version)
		tooltip:AddLine(MBB_TOOLTIP1, 0, 1, 0, true)
		tooltip:Show()

		setalpha()
	end)

	mbbFrame:SetScript("OnLeave", function(self) 
		over = false
		_G.MBB_ShowTimeout = 0

		local tooltip = Module:GetMinimapTooltip()
		tooltip:Hide()

		setalpha()
	end)
end

-- Perform and initial update of all elements, 
-- as this is not done automatically by the back-end.
Module.EnableAllElements = function(self)
	local Handler = self:GetMinimapHandler()
	Handler:EnableAllElements()
end 

-- Set the mask texture
Module.UpdateMinimapMask = function(self)
	-- Transparency in these textures also affect the indoors opacity 
	-- of the minimap, something changing the map alpha directly does not. 
	self:SetMinimapMaskTexture(Layout.MaskTexture)
end 

-- Set the size and position 
-- Can't change this in combat, will cause taint!
Module.UpdateMinimapSize = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	self:SetMinimapSize(unpack(Layout.Size)) 
	self:SetMinimapPosition(unpack(Layout.Place)) 
end 

Module.UpdateBars = function(self, event, ...)
	if (not Layout.UseStatusRings) then 
		return 
	end 

	local Handler = self:GetMinimapHandler()

	-- Figure out what should be shown. 
	-- Priority us currently xp > rep > ap
	local hasRep = Module.PlayerHasRep()
	local hasXP = Module.PlayerHasXP()
	local hasAP = (not IS_CLASSIC) and FindActiveAzeriteItem()

	-- Will include choices later on
	local first, second 
	if hasXP then 
		first = "XP"
	elseif hasRep then 
		first = "Reputation"
	elseif hasAP then 
		first = "ArtifactPower"
	end 
	if first then 
		if hasRep and (first ~= "Reputation") then 
			second = "Reputation"
		elseif hasAP and (first ~= "ArtifactPower") then 
			second = "ArtifactPower"
		end
	end 

	if (first or second) then
		if (not Handler.Toggle:IsShown()) then  
			Handler.Toggle:Show()
		end

		-- Dual bars
		if (first and second) then

			-- Setup the bars and backdrops for dual bar mode
			if self.spinnerMode ~= "Dual" then 

				-- Set the backdrop to the two bar backdrop
				Handler.Toggle.Frame.Bg:SetTexture(Layout.RingFrameBackdropDoubleTexture)

				-- Update the look of the outer spinner
				Spinner[1]:SetStatusBarTexture(Layout.RingFrameOuterRingTexture)
				Spinner[1]:SetSparkSize(unpack(Layout.RingFrameOuterRingSparkSize))
				Spinner[1]:SetSparkInset(unpack(Layout.RingFrameOuterRingSparkInset))

				if Layout.RingFrameOuterRingValueFunc then 
					Layout.RingFrameOuterRingValueFunc(Spinner[1].Value, Handler)
				end 

				Spinner[1].PostUpdate = nil
			end

			-- Assign the spinners to the elements
			if (self.spinner1 ~= first) then 

				-- Disable the old element 
				self:DisableMinimapElement(first)

				-- Link the correct spinner
				Handler[first] = Spinner[1]

				-- Assign the correct post updates
				if (first == "XP") then 
					Handler[first].OverrideValue = XP_OverrideValue
	
				elseif (first == "Reputation") then 
					Handler[first].OverrideValue = Rep_OverrideValue
	
				elseif (first == "ArtifactPower") then 
					Handler[first].OverrideValue = AP_OverrideValue
				end 

				-- Enable the updated element 
				self:EnableMinimapElement(first)

				-- Run an update
				Handler[first]:ForceUpdate()
			end

			if (self.spinner2 ~= second) then 

				-- Disable the old element 
				self:DisableMinimapElement(second)

				-- Link the correct spinner
				Handler[second] = Spinner[2]

				-- Assign the correct post updates
				if (second == "XP") then 
					Handler[second].OverrideValue = XP_OverrideValue
	
				elseif (second == "Reputation") then 
					Handler[second].OverrideValue = Rep_OverrideValue
	
				elseif (second == "ArtifactPower") then 
					Handler[second].OverrideValue = AP_OverrideValue
				end 

				-- Enable the updated element 
				self:EnableMinimapElement(second)

				-- Run an update
				Handler[second]:ForceUpdate()
			end

			-- Store the current modes
			self.spinnerMode = "Dual"
			self.spinner1 = first
			self.spinner2 = second

		-- Single bar
		else

			-- Setup the bars and backdrops for single bar mode
			if (self.spinnerMode ~= "Single") then 

				-- Set the backdrop to the single thick bar backdrop
				Handler.Toggle.Frame.Bg:SetTexture(Layout.RingFrameBackdropTexture)

				-- Update the look of the outer spinner to the big single bar look
				Spinner[1]:SetStatusBarTexture(Layout.RingFrameSingleRingTexture)
				Spinner[1]:SetSparkSize(unpack(Layout.RingFrameSingleRingSparkSize))
				Spinner[1]:SetSparkInset(unpack(Layout.RingFrameSingleRingSparkInset))

				if Layout.RingFrameSingleRingValueFunc then 
					Layout.RingFrameSingleRingValueFunc(Spinner[1].Value, Handler)
				end 

				-- Hide 2nd spinner values
				Spinner[2].Value:SetText("")
				Spinner[2].Value.Percent:SetText("")
			end 		

			-- Disable any previously active secondary element
			if self.spinner2 and Handler[self.spinner2] then 
				self:DisableMinimapElement(self.spinner2)
				Handler[self.spinner2] = nil
			end 

			-- Update the element if needed
			if (self.spinner1 ~= first) then 

				-- Update pointers and callbacks to the active element
				Handler[first] = Spinner[1]
				Handler[first].OverrideValue = hasXP and XP_OverrideValue or hasRep and Rep_OverrideValue or AP_OverrideValue
				Handler[first].PostUpdate = hasXP and PostUpdate_XP or hasRep and PostUpdate_Rep or PostUpdate_AP

				-- Enable the active element
				self:EnableMinimapElement(first)

				-- Make sure descriptions are updated
				Handler[first].Value.Description:Show()

				-- Update the visible element
				Handler[first]:ForceUpdate()
			end 

			-- If the second spinner is still shown, hide it!
			if (Spinner[2]:IsShown()) then 
				Spinner[2]:Hide()
			end 

			-- Store the current modes
			self.spinnerMode = "Single"
			self.spinner1 = first
			self.spinner2 = nil
		end 

		-- Post update the frame, could be sticky
		Toggle_UpdateFrame(Handler.Toggle)

	else 
		Handler.Toggle:Hide()
		Handler.Toggle.Frame:Hide()
	end 

end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= LEVEL)) then
			LEVEL = level
		else
			local level = UnitLevel("player")
			if (not LEVEL) or (LEVEL < level) then
				LEVEL = level
			end
		end
	end

	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateMinimapSize()
		return 
	end

	if (event == "PLAYER_ENTERING_WORLD") or (event == "VARIABLES_LOADED") then 
		self:UpdateMinimapSize()
		self:UpdateMinimapMask()
	end

	if (event == "ADDON_LOADED") then 
		local addon = ...
		if (addon == "MBB") then 
			self:SetUpMBB()
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			return 
		end 
	end 

	if Layout.UseStatusRings then 
		self:UpdateBars()
	end 
end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[Minimap]")
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
end 

Module.OnInit = function(self)
	self.db = self:NewConfig("Minimap", defaults, "global")
	self.MBB = Layout.UseMBB and self:IsAddOnEnabled("MBB")

	self:SetUpMinimap()

	if self.MBB then 
		if IsAddOnLoaded("MBB") then 
			self:SetUpMBB()
		else 
			self:RegisterEvent("ADDON_LOADED", "OnEvent")
		end 
	end 

	if Layout.UseStatusRings then 
		self:UpdateBars()
	end
end 

Module.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent") -- size and mask must be updated after this

	if Layout.UseStatusRings then 
		if (not IS_CLASSIC) then 
			self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "OnEvent") -- Bar count updates
			self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
			self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
		end 
		self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnEvent")
		self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
		self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
		self:RegisterEvent("UPDATE_FACTION", "OnEvent")
	end 

	-- Enable all minimap elements
	self:EnableAllElements()
end 
