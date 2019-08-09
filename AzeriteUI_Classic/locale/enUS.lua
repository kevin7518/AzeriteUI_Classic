local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "enUS", true) -- only enUS must have the 'true' argument!
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = true 
L["Disable"] = true 
L["Enabled"] = "|cff00aa00Enabled|r"
L["Disabled"] = "|cffff0000Disabled|r"
L["<Left-Click>"] = true
L["<Middle-Click>"] = true
L["<Right-Click>"] = true

-- Clock & Time Settings
--------------------------------------------
-- These are shown in tooltips
L["New Event!"] = true
L["New Mail!"] = true
L["%s to toggle calendar."] = true
L["%s to use local computer time."] = true
L["%s to use game server time."] = true
L["%s to use standard (12-hour) time."] = true
L["%s to use military (24-hour) time."] = true
L["Now using local computer time."] = true
L["Now using game server time."] = true
L["Now using standard (12-hour) time."] = true
L["Now using military (24-hour) time."] = true

-- Network & Performance Information
--------------------------------------------
-- These are shown in tooltips
L["Network Stats"] = true
L["World latency:"] = true
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = true 
L["Home latency:"] = true
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = true

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are shown in tooltips
L["Normal"] = true
L["Rested"] = true
L["Resting"] = true
L["Current Artifact Power: "] = true 
L["Current Honor Points: "] = true
L["Current Standing: "] = true
L["Current XP: "] = true
L["Rested Bonus: "] = true
L["%s of normal experience gained from monsters."] = true
L["You must rest for %s additional hours to become fully rested."] = true
L["You must rest for %s additional minutes to become fully rested."] = true
L["You should rest at an Inn."] = true
L["Sticky Minimap bars enabled."] = true
L["Sticky Minimap bars disabled."] = true

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = true 
L["to %s"] = true
L["to next trait"] = true

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = true
L["%s to toggle Honor Talents Window>"] = true
L["%s to disable sticky bars."] = true 
L["%s to enable sticky bars."] = true 

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Click here to get access to the various in-game windows such as the character paperdoll, spellbook, talents and similar, or to change various settings for the actionbars."

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s to toggle Blizzard Micro Menu."
L["%s to toggle Options Menu."] = "%s to toggle "..ADDON.." Options Menu."
L["%s to toggle your Bags."] = true

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = true 
L["Debug Console"] = true 
L["Load Console"] = true
L["Unload Console"] = true
L["Reload UI"] = true
L["ActionBars"] = true
L["Bind Mode"] = true
L["Cast on Down"] = true
L["Button Lock"] = true
L["More Buttons"] = true
L["No Extra Buttons"] = true
L["+%.0f Buttons"] = true
L["Extra Buttons Visibility"] = true
L["MouseOver"] = true
L["MouseOver + Combat"] = true
L["Always Visible"] = true
L["Stance Bar"] = true
L["Pet Bar"] = true
L["UnitFrames"] = true
L["Party Frames"] = true
L["Raid Frames"] = true
L["PvP Frames"] = true
L["HUD"] = true
L["Alerts"] = true
L["TalkingHead"] = true
L["NamePlates"] = true
L["Auras"] = true
L["Player"] = true
L["Enemies"] = true 
L["Friends"] = true
L["Explorer Mode"] = true
L["Player Fading"] = true
L["Tracker Fading"] = true
L["Healer Mode"] = true 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = true
L["Click to disable the Stance Bar."] = true
L["Click to enable the Pet Action Bar."] = true
L["Click to disable the Pet Action Bar."] = true

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = true
L["%s to dismount."] = true

-- Abbreviations
--------------------------------------------
-- This is shown of group frames when the unit 
-- has low or very low mana. Keep it to 3 letters max! 
L["oom"] = true -- out of mana

-- These are shown on the minimap compass when 
-- rotating minimap is enabled. Keep it to single letters!
L["N"] = true -- compass North
L["E"] = true -- compass East
L["S"] = true -- compass South
L["W"] = true -- compass West

-- Keybind mode
--------------------------------------------
-- This is shown in the frame, it is word-wrapped. 
-- Try to keep the length fairly identical to enUS, though, 
-- to make sure it fits properly inside the window. 
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = true

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = true
L["Keybind changes were discarded because you entered combat."] = true
L["Keybind changes were saved."] = true
L["Keybind changes were discarded."] = true
L["No keybinds were changed."] = true
L["No keybinds set."] = true
L["%s is now unbound."] = true
L["%s is now bound to %s"] = true
