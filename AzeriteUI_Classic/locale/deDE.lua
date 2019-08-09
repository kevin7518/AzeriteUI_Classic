-- deDE locale written by Maoe#5728@ our Discord!
local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "deDE")
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "Aktivieren" 
L["Disable"] = "Deaktivieren" 
L["Enabled"] = "|cff00aa00Aktiviert|r"
L["Disabled"] = "|cffff0000Deaktiviert|r"
L["<Left-Click>"] = "Links-Klick"
L["<Middle-Click>"] = "Mittlere Maustaste"
L["<Right-Click>"] = "Rechts-Klick"

-- Clock & Time Settings
--------------------------------------------
-- These are shown in tooltips
L["New Event!"] = "Neues Ereignis!"
L["New Mail!"] = "Neue Post!"
L["%s to toggle calendar."] = "%s um den Kalender zu zeigen."
L["%s to use local computer time."] = "%s um die lokale Zeit zu verwenden."
L["%s to use game server time."] = "%s um die Server-Zeit zu verwenden."
L["%s to use standard (12-hour) time."] = "%s für den 12h-Modus."
L["%s to use military (24-hour) time."] = "%s für den 24h-Modus."
L["Now using local computer time."] = "Lokale Zeit wird verwendet."
L["Now using game server time."] = "Server-Zeit wird verwendet."
L["Now using standard (12-hour) time."] = "12h-Modus wird verwendet."
L["Now using military (24-hour) time."] = "24h-Modus wird verwendet."

-- Network & Performance Information
--------------------------------------------
-- These are shown in tooltips
L["Network Stats"] = "Netzwerk Statistik"
L["World latency:"] = "Welt Latenz"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "Dies ist die Latenz der Welt und betrifft Zaubern, Herstellen und Interagieren mit anderen Spielern und NPCs. Dieser Wert sagt aus, wie sehr deine Aktionen verzögert werden."
L["Home latency:"] = "Heim Latenz"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "Dies ist die Latenz des Heim-Servers, welcher Dinge wie Chat, Gilde, Auktionshaus und ein paar andere, nicht kampfbezogene Dinge beeinflusst."

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are shown in tooltips
L["Normal"] = true
L["Rested"] = "Ausgeruht"
L["Resting"] = "Ruhend"
L["Current Artifact Power: "] = "Aktuelle Artefaktmacht"
L["Current Honor Points: "] = "Aktuelle Ehre-Punkte"
L["Current Standing: "] = "Aktueller Stand"
L["Current XP: "] = "Aktuelle Erfahrung"
L["Rested Bonus: "] = "Ausgeruht Bonus"
L["%s of normal experience gained from monsters."] = "%s der von Monstern erhaltenen normalen Erfahrung"
L["You must rest for %s additional hours to become fully rested."] = "Du musst noch %s Stunden ruhen, um vollkommen ausgeruht zu sein."
L["You must rest for %s additional minutes to become fully rested."] = "Du musst noch %s Minuetn ruhen, um vollkommen ausgeruht zu sein."
L["You should rest at an Inn."] = "Du solltest in einem Gasthaus ruhen."
L["Sticky Minimap bars enabled."] = "Minimap-Symbole festgestellt." 
L["Sticky Minimap bars disabled."] = "Minimap-Symbole gelöst."

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "bis Level %s"
L["to %s"] = "bis %s"
L["to next trait"] = "bis zum nächsten Trait"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "%s für das Artefakt-Fenster"
L["%s to toggle Honor Talents Window>"] = "%s für das Ehre-Talent-Fenster." 
L["%s to disable sticky bars."] = "%s um Minimap-Symbole zu lösen."
L["%s to enable sticky bars."] = "%s um Minimap-Symbole festzustellen." 

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Klicke hier, um die die Menüfenster, wie Talente und das Zauberbuch aufrufen zu können. Außerdem können hier Einstellungen für die Actionbars getätigt werden."

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s für das Blizzard Micro Menü."
L["%s to toggle Options Menu."] = "%s für das "..ADDON.." Options Menü."
L["%s to toggle your Bags."] = "%s um die Taschen zu zeigen."

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "Debug-Modus" 
L["Debug Console"] = "Debug Konsole"
L["Load Console"] = "Konsole laden"
L["Unload Console"] = "Konsole nicht laden"
L["Reload UI"] = "UI neu laden"
L["ActionBars"] = "Zauberleisten"
L["Bind Mode"] = "Tastenbelegung"
L["Cast on Down"] = "Beim drücken Zauben"
L["Button Lock"] = "Tasten sperren"
L["More Buttons"] = "Mehr Tasten"
L["No Extra Buttons"] = "Keine Extra-Tasten"
L["+%.0f Buttons"] = "+%.0f Tasten"
L["Extra Buttons Visibility"] = "Extra-Button Sichtbarkeit"
L["MouseOver"] = true
L["MouseOver + Combat"] = true
L["Always Visible"] = "Immer sichtbar"
L["Stance Bar"] = "Haltungsleiste"
L["Pet Bar"] = "Begleiterleiste"
L["UnitFrames"] = "Einheitenfenster"
L["Party Frames"] = "Gruppenfenster"
L["Raid Frames"] = "Raidfenster"
L["PvP Frames"] = "PVP-Fenster"
L["HUD"] = true
L["Alerts"] = "Alarme"
L["TalkingHead"] = "Sprechende Köpfe"
L["NamePlates"] = "Namensplaketten"
L["Auras"] = "Auren"
L["Player"] = "Spieler"
L["Enemies"] = "Feinde"
L["Friends"] = "Freunde"
L["Explorer Mode"] = "Erkundungsmodus"
L["Player Fading"] = "Spieler ausblenden"
L["Tracker Fading"] = "Tracker ausblenden"
L["Healer Mode"] = "Heiler-Modus" 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = true
L["Click to disable the Stance Bar."] = true
L["Click to enable the Pet Action Bar."] = true
L["Click to disable the Pet Action Bar."] = true

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "zum Verlassen"
L["%s to dismount."] = "zum Absitzen"

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
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = "Fahre mit der Maus über einen Knopf und drücke die entsprechende Taste um diese zu binden. Drücke ESC um die Verknüfung der Taste zu löschen."

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "Die Tastenbelegung kann während des Kampfes nicht geändert werden."
L["Keybind changes were discarded because you entered combat."] = "Änderungen der Tastenbelegung wurde verworfen, da ein Kampf begonnen wurde."
L["Keybind changes were saved."] = "Tastenbelegung gespeichert."
L["Keybind changes were discarded."] = "Tastenbelgung verworfen."
L["No keybinds were changed."] = "Keie Tasten geändert."
L["No keybinds set."] = "Keine Tasten belegt."
L["%s is now unbound."] = "%s ist nun nicht mehr belegt."
L["%s is now bound to %s"] = "s% ist nun mit %s belegt."
