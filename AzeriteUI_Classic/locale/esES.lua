-- esES locale written by Sonshine#3640@ our Discord!
local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "esES")
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "Activar" 
L["Disable"] = "Desactivar" 
L["Enabled"] = "Activado"
L["Disabled"] = "Desactivado"
L["<Left-Click>"] = "<Click Izquierdo>"
L["<Middle-Click>"] = "<Click central>"
L["<Right-Click>"] = "<Click Derecho>"

-- Clock & Time Settings
--------------------------------------------
-- These are shown in tooltips
L["New Event!"] = "Evento nuevo!"
L["New Mail!"] = "Correo nuevo!"
L["%s to toggle calendar."] = "%s para mostrar/ocultar el calendario."
L["%s to use local computer time."] = "%s para usar la hora local del ordenador."
L["%s to use game server time."] = "%s para usar la hora del servidor."
L["%s to use standard (12-hour) time."] = "%s para usar la hora estándar (12h)."
L["%s to use military (24-hour) time."] = "%s para usar la hora militar (24h)."
L["Now using local computer time."] = "Ahora estás utilizando la hora del ordenador."
L["Now using game server time."] = "Ahora estás utilizando la hora del servidor."
L["Now using standard (12-hour) time."] = "Ahora estás utilizando la hora estándar (12h)."
L["Now using military (24-hour) time."] = "Ahora estás utilizando la hora militar (24h)."

-- Network & Performance Information
--------------------------------------------
-- These are shown in tooltips
L["Network Stats"] = "Estadísticas de Red"
L["World latency:"] = "Latencia mundo:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "Esta es la latencia del servidor, y afecta a los lanzamientos, la fabricación y la interacción con otros jugadores y NPC's. Este es el valor que decide cuánto tardan tus habilidades de combate." 
L["Home latency:"] = "Latencia hogar:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "Esta es la latencia del hogar, que afecta a cosas como el chat, el chat de hermandad, la casa de subastas y otras cosas no relacionadas con el combate."

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are shown in tooltips
L["Normal"] = "Normal"
L["Rested"] = "Descansado"
L["Resting"] = "Descansando"
L["Current Artifact Power: "] = "Poder de artefacto actual: "
L["Current Honor Points: "] = "Puntos de Honor actuales: "
L["Current Standing: "] = "Estado actual: "
L["Current XP: "] = "EXP actual: "
L["Rested Bonus: "] = "Bonus de Descanso: "
L["%s of normal experience gained from monsters."] = "%s de experiencia normal obtenida de monstruos."
L["You must rest for %s additional hours to become fully rested."] = "Debes descansar durante %s horas más para estar totalmente descansado."
L["You must rest for %s additional minutes to become fully rested."] = "Debes descansar durante %s minutos más para estar totalmente descansado."
L["You should rest at an Inn."] = "Deberías descansar en una Taberna."
L["Sticky Minimap bars enabled."] = "Barras fijas del Minimapa activadas."
L["Sticky Minimap bars disabled."] = "Barras fijas del Minimapa desactivadas."

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "para el nivel %s" 
L["to %s"] = "para %s"
L["to next trait"] = "para el siguiente nivel"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "%s para mostrar/ocultar la ventana de Artefacto>"
L["%s to toggle Honor Talents Window>"] = "%s para mostrar/ocultar la ventana de Talentos de Honor>"
L["%s to disable sticky bars."] = "%s para desactivar las barras fijas."
L["%s to enable sticky bars."] = "%s para activar las barras fijas."  

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Haz click aquí para acceder a los paneles del juego."

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s para mostrar/ocultar el menú de Blizzard."
L["%s to toggle Options Menu."] = "%s para mostrar/ocultar el menú de opciones "..ADDON.."."
L["%s to toggle your Bags."] = "%s para mostrar/ocultar tus bolsas."

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "Modo Debug" 
L["Debug Console"] = "Consola Debug" 
L["Load Console"] = "Cargar Consola"
L["Unload Console"] = "Desactivar Consola"
L["Reload UI"] = "Reiniciar UI"
L["ActionBars"] = "Barras de acción"
L["Bind Mode"] = "Modo de Atajsos de teclado"
L["Cast on Down"] = "Lanzamiento al presionar"
L["Button Lock"] = "Bloqueo de botones"
L["More Buttons"] = "Más botones"
L["No Extra Buttons"] = "Sin botones extra"
L["+%.0f Buttons"] = "+%.0f botones"
L["Extra Buttons Visibility"] = "Visibilidad de botones extra"
L["MouseOver"] = "Ratón encima"
L["MouseOver + Combat"] = "Ratón encima + combate"
L["Always Visible"] = "Siempre visible"
L["Stance Bar"] = "Barra de Estados"
L["Pet Bar"] = "Barra de Mascota"
L["UnitFrames"] = "Frames"
L["Party Frames"] = "Frames de grupo"
L["Raid Frames"] = "Frames de raid"
L["PvP Frames"] = "Frames PvP"
L["HUD"] = "HUD"
L["Alerts"] = "Alertas"
L["TalkingHead"] = "Cabeza Flotante"
L["NamePlates"] = "Placas de Nombres"
L["Auras"] = "Аuras"
L["Explorer Mode"] = "Modo Explorador"
L["Player Fading"] = "Desvanecimiento de Jugador"
L["Tracker Fading"] = "Desvanecimiento del rastreador"
L["Healer Mode"] = "Modo Sanador" 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = "Click para activar la barra de Estados."
L["Click to disable the Stance Bar."] = "Click para desactivar la barra de Estados."
L["Click to enable the Pet Action Bar."] = "Click para activar la barra de Acción de Mascota."
L["Click to disable the Pet Action Bar."] = "Click para desactivar la barra de Acción de Mascota."

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "%s para abandonar el vehículo."
L["%s to dismount."] = "%s para desmontar."

-- Abbreviations
--------------------------------------------
L["oom"] = "sm" -- out of mana
L["N"] = "N" -- compass North
L["E"] = "E" -- compass East
L["S"] = "S" -- compass South
L["W"] = "O" -- compass West

-- Keybind mode
--------------------------------------------
-- This is shown in the frame, it is word-wrapped. 
-- Try to keep the length fairly identical to enUS, though, 
-- to make sure it fits properly inside the window. 
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = true

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "Los atajos de teclado no pueden ser cambiados mientras estás en combate."
L["Keybind changes were discarded because you entered combat."] = "Los atajos de teclado han sido descartados porque has entrado en combate."
L["Keybind changes were saved."] = "Los atajos de teclado han sido guardados."
L["Keybind changes were discarded."] = "Los atajos de teclado han sido descartados."
L["No keybinds were changed."] = "No se ha cambiado ningún atajo de teclado."
L["No keybinds set."] = "No hay atajos de teclado."
L["%s is now unbound."] = "%s no tiene atajo de teclado."
L["%s is now bound to %s"] = "%s tiene como atajo de teclado %s"
