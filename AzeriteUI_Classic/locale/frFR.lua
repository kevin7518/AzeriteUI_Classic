-- frFR locale written by HipNoTiK#2609 @ our Discord!
local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "frFR")
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "Activer" 
L["Disable"] = "Desactiver" 
L["Enabled"] = "|cff00aa00Activé|r"
L["Disabled"] = "|cffff0000Désactivé|r"
L["<Left-Click>"] = "<Clic-Gauche>"
L["<Middle-Click>"] = "<Clic-Central>"
L["<Right-Click>"] = "<Clic-Droit>"

-- Clock & Time Settings
--------------------------------------------
-- These are shown in tooltips
L["New Event!"] = "Nouvel Evênement!"
L["New Mail!"] = "Nouveau Courrier!"
L["%s to toggle calendar."] = "%s pour afficher le calendrier."
L["%s to use local computer time."] = "%s pour utiliser l\'heure locale."
L["%s to use game server time."] = "%s pour utiliser l\'heure du royaume."
L["%s to use standard (12-hour) time."] = "%s pour utiliser l\'heure en mode 12H."
L["%s to use military (24-hour) time."] = "%s pour utiliser l\'heure en mode 24H."
L["Now using local computer time."] = "Utilise l\'heure locale."
L["Now using game server time."] = "Utilise l\'heure du royaume."
L["Now using standard (12-hour) time."] = "Utilise l\'heure en mode 12H."
L["Now using military (24-hour) time."] = "Utilise l\'heure en mode 24H."

-- Network & Performance Information
--------------------------------------------
-- These are shown in tooltips
L["Network Stats"] = "Stats Réseau"
L["World latency:"] = "Latence du Monde:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "C'est la latence du Monde, laquelle affecte l'incantation des sorts, la fabrication d'objets, toutes interations avec d'autre joueurs et PNJ. C'est la valeur qui indique le temps de réponses de vos actions en combat." 
L["Home latency:"] = "Latence du Domicile:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "C'est la latence du Domicile, laquelle affecte le tchat, la discussion de guilde, l'hôtel des ventes et toutes les choses qui ne sont pas en combat."

-- XP, Honor & Artifact Bars
------------------------------------v--------
-- These are shown in tooltips
L["Normal"] = "Normal"
L["Rested"] = "Reposé"
L["Resting"] = "En cours de Repos"
L["Current Artifact Power: "] = "Niveau de puissance actuel:" 
L["Current Honor Points: "] = "Points d'Honneur:"
L["Current Standing: "] = "Posture:"
L["Current XP: "] = "XP:"
L["Rested Bonus: "] = "Bonus de Repos:"
L["%s of normal experience gained from monsters."] = "%s d\'expérience normale gagnée grâce aux montres."
L["You must rest for %s additional hours to become fully rested."] = "Vous devez vous reposer pendant encore %s heures pour être complètement reposé."
L["You must rest for %s additional minutes to become fully rested."] = "Vous devez vous reposer pendant encore %s minutes pour être complètement reposé."
L["You should rest at an Inn."] = "Vous devriez vous reposer dans une Auberge."
L["Sticky Minimap bars enabled."] = "Barres de la Mini-Carte épinglées."
L["Sticky Minimap bars disabled."] = "Barres de la Mini-Carte desépinglées."

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "pour monter niveau %s" 
L["to %s"] = "jusqu\'à %"
L["to next trait"] = "jusqu\'au prochain trait"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "%s pour afficher la Fenêtre de l\'Artéfact>"
L["%s to toggle Honor Talents Window>"] = "%s pour afficher la Fenêtre des Talents d\'Honneur>"
L["%s to disable sticky bars."] = "%s pour desépingler les barres." 
L["%s to enable sticky bars."] = "%s pour épingler les barres." 

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Cliquez ici pour accéder à de diverses fenêtre en jeu tel que la fiche de personnage, le livre des sorts, talents etc, ou pour changer les réglages des barres d'actions."

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s pour afficher le Micro Menu Blizzard."
L["%s to toggle Options Menu."] = "%s pour afficher le menu Options de "..ADDON.."."
L["%s to toggle your Bags."] = "%s pour afficher vos Sacs."

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "Mode Debug" 
L["Debug Console"] = "Console de Déboggage" 
L["Load Console"] = "Charger la Console"
L["Unload Console"] = "Décharger la Console"
L["Reload UI"] = "Recharger l\'interface"
L["ActionBars"] = "Barres d\'Actions"
L["Bind Mode"] = "Affecter Raccourcis"
L["Cast on Down"] = "Incanter à l\'appuie"
L["Button Lock"] = "Vérrouiller les Boutons"
L["More Buttons"] = "+ de Boutons"
L["No Extra Buttons"] = "Aucun Bouton en +"
L["+%.0f Buttons"] = "+%.0f Boutons"
L["Extra Buttons Visibility"] = "Visibilité Boutons en +"
L["MouseOver"] = "MouseOver" -- TODO ?
L["MouseOver + Combat"] = "MouseOver + Combat"
L["Always Visible"] = "Toujours Visible"
L["Stance Bar"] = "Barre de Posture"
L["Pet Bar"] = "Barre du Familier"
L["UnitFrames"] = "Interface"
L["Party Frames"] = "Fenêtre de Groupe"
L["Raid Frames"] = "Fenêtre de Raid"
L["PvP Frames"] = "Fenêtre JcJ"
L["HUD"] = "HUD"
L["Alerts"] = "Alertes"
L["TalkingHead"] = "TalkingHead" -- TODO ?
L["NamePlates"] = "Barres de Noms"
L["Auras"] = "Auras"
L["Player"] = "Joueur"
L["Enemies"] = "Ennemis" 
L["Friends"] = "Amis"
L["Explorer Mode"] = "Mode Explorateur"
L["Player Fading"] = "Masquer l\'interface du Joueur" -- TODO ?
L["Tracker Fading"] = "Masquer le Tracker" -- TODO ?
L["Healer Mode"] = "Mode Healer" 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = "Cliquer pour activer la Barre de Postures."
L["Click to disable the Stance Bar."] = "Cliquer pour désactiver la Barre de Postures."
L["Click to enable the Pet Action Bar."] = "Cliquer pour activer la Barre d'action du Familier."
L["Click to disable the Pet Action Bar."] = "Cliquer pour désactiver la Barre d'action du Familier."

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "%s pour quitter le véhicule."
L["%s to dismount."] = "%s pour descendre de monture."

-- Abbreviations
--------------------------------------------
-- This is shown of group frames when the unit 
-- has low or very low mana. Keep it to 3 letters max! 
L["oom"] = "oom" -- out of mana

-- These are shown on the minimap compass when 
-- rotating minimap is enabled. Keep it to single letters!
L["N"] = "N" -- compass North
L["E"] = "E" -- compass East
L["S"] = "S" -- compass South
L["W"] = "W" -- compass West

-- Keybind mode
--------------------------------------------
-- This is shown in the frame, it is word-wrapped. 
-- Try to keep the length fairly identical to enUS, though, 
-- to make sure it fits properly inside the window. 
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = "Passez la souris sur un bouton de la barre d\'action et appuyez sur une touche ou un bouton de la souris pour affecter le raccourci. Appuyez sur ECHAP pour effacer le raccourci actuel."

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "Les raccourcis ne peuvent être changé en combat."
L["Keybind changes were discarded because you entered combat."] = "Les changements de raccourcis ont été annulé car vous êtes en combat."
L["Keybind changes were saved."] = "Les changements de raccourcis ont été sauvegardé."
L["Keybind changes were discarded."] = "Les changements de raccourcis ont été annulé."
L["No keybinds were changed."] = "Aucuns raccourcis n'a été changé."
L["No keybinds set."] = "Aucun raccourci défini."
L["%s is now unbound."] = "%s est maintenant délié."
L["%s is now bound to %s"] = "%s est maintenant lié à %s"

