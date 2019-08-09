-- ruRU locale written by Demorto#2597@ our Discord! 
local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "ruRU") 
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "Включить" 
L["Disable"] = "Отключить" 
L["Enabled"] = "|cff00aa00Включено|r"
L["Disabled"] = "|cffff0000Отключено|r"
L["<Left-Click>"] = "<Левая кнопка>"
L["<Middle-Click>"] = "<Средняя кнопка>"
L["<Right-Click>"] = "<Правая кнопка>"

-- Clock & Time Settings
--------------------------------------------
L["New Event!"] = "Новое событие!"
L["New Mail!"] = "Новая почта!"
L["%s to toggle calendar."] = "%s открытия календаря."
L["%s to use local computer time."] = "%s отображение локального времени."
L["%s to use game server time."] = "%s отображение серверного времени."
L["%s to use standard (12-hour) time."] = "%s для 12-часового формата."
L["%s to use military (24-hour) time."] = "%s для 24-часового формата."
L["Now using local computer time."] = "Сейчас отображается локальное время."
L["Now using game server time."] = "Сейчас отображается серверное время."
L["Now using standard (12-hour) time."] = "Сейчас отображается время в 12-часовом формате."
L["Now using military (24-hour) time."] = "Сейчас отображается время в 24-часовом формате."

-- Network & Performance Information
--------------------------------------------
L["Network Stats"] = "Задержка сети"
L["World latency:"] = "Глобальная задержка:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "Это задержка сервера, которая влияет на произношение заклинаний, создание вещей, взаимодействие с другими игроками и неигровыми персонажами. Это значение, которое определяет, насколько задержаны ваши боевые действия." 
L["Home latency:"] = "Локальная задержка:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "Это задержка сервера, которая влияет на такие вещи, как мировой чат, чат гильдии, аукционный дом и некоторые другие вещи, не связанные с боем."

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are in the tooltips
L["Normal"] = "Нормальный"
L["Rested"] = "Отдохнувший"
L["Resting"] = "Отдых"
L["Current Artifact Power: "] = "Текущая сила артефакта: "
L["Current Honor Points: "] = "Текущие очки чести: "
L["Current Standing: "] = "Текущее состояние: "
L["Current XP: "] = "Текущий опыт: "
L["Rested Bonus: "] = "Бонус отдыха: "
L["%s of normal experience gained from monsters."] = "%s опыта после убийства монстров."
L["You must rest for %s additional hours to become fully rested."] = "Вы должны отдохнуть в течении %s часов, чтобы полностью отдохнуть."
L["You must rest for %s additional minutes to become fully rested."] = "Вы должны отдохнуть в течении %s минут, чтобы полностью отдохнуть."
L["You should rest at an Inn."] = "Вы должны отдохнуть в Таверне."
L["Sticky Minimap bars enabled."] = "Информация об опыте\репутации закреплена на миникарте."
L["Sticky Minimap bars disabled."] = "Информация об опыте\репутации откреплена от миникарты."

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "до %s уровня" 
L["to %s"] = "до %s"
L["to next trait"] = "до следующей особенности"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "%s для отображения окна Артефакта>"
L["%s to toggle Honor Talents Window>"] = "%s для отображения окна PVP Талантов>"
L["%s to disable sticky bars."] = "%s что бы открепить информацию."
L["%s to enable sticky bars."] = "%s что бы закрепить информацию."  

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "Нажмите сюда, чтобы получить доступ к различным игровым окнам, таким как персонаж, книга заклинаний, таланты или изменить различные настройки панелей команд."

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s для отображения Основного Меню."
L["%s to toggle Options Menu."] = "%s для отображения настроек "..ADDON.."."
L["%s to toggle your Bags."] = "%s для отображения ваших Сумок."

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "Режим отладки" 
L["Debug Console"] = "Консоль отладки" 
L["Load Console"] = "Загрузить консоль"
L["Unload Console"] = "Выгрузить консоль"
L["Reload UI"] = "Перезагрузить интерфейс"
L["ActionBars"] = "Панели команд"
L["Bind Mode"] = "Режим назначения клавиш"
L["Cast on Down"] = "Срабатывать при нажатии"
L["Button Lock"] = "Блокировка кнопок"
L["More Buttons"] = "Больше кнопок"
L["No Extra Buttons"] = "Нет доп. кнопок"
L["+%.0f Buttons"] = "+%.0f кнопок"
L["Extra Buttons Visibility"] = "Отображение доп. кнопок"
L["MouseOver"] = "При наведении"
L["MouseOver + Combat"] = "При наведении и в бою"
L["Always Visible"] = "Отображать всегда"
L["Stance Bar"] = "Панель стоек"
L["Pet Bar"] = "Панель питомца"
L["UnitFrames"] = "Фреймы"
L["Party Frames"] = "Фреймы группы"
L["Raid Frames"] = "Фреймы рейда"
L["PvP Frames"] = "Фреймы PVP"
L["HUD"] = "HUD"
L["Alerts"] = "Оповещения"
L["TalkingHead"] = "Говорящие головы"
L["NamePlates"] = "Индикаторы здоровья"
L["Auras"] = "Ауры"
L["Explorer Mode"] = "Режим исследователя"
L["Player Fading"] = "Скрывать игрока"
L["Tracker Fading"] = "Скрывать трекер"
L["Healer Mode"] = "Режим лекаря" 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = "Нажмите для включения панели стоек."
L["Click to disable the Stance Bar."] = "Нажмите для выключения панели стоек."
L["Click to enable the Pet Action Bar."] = "Нажмите для включения панели питомца."
L["Click to disable the Pet Action Bar."] = "Нажмите для выключения панели питомца."

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "%s что бы покинуть транспорт."
L["%s to dismount."] = "%s что бы спешиться."

-- Abbreviations
--------------------------------------------
-- This is shown of group frames when the unit 
-- has low or very low mana. Keep it to 3 letters max! 
L["oom"] = "oom" -- out of mana

-- These are shown on the minimap compass when 
-- rotating minimap is enabled. Keep it to single letters!
L["N"] = "С" -- compass North
L["E"] = "В" -- compass East
L["S"] = "Ю" -- compass South
L["W"] = "З" -- compass West

-- Keybind mode
--------------------------------------------
-- This is shown in the frame, it is word-wrapped. 
-- Try to keep the length fairly identical to enUS, though, 
-- to make sure it fits properly inside the window. 
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = "Наведите мышь на кнопку действия и нажмите клавишу или кнопку мыши, чтобы привязать её. Нажмите клавишу ESC, чтобы сбросить привязку."

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "Назначение клавиш не работает в бою."
L["Keybind changes were discarded because you entered combat."] = "Изменения клавиш были отменены, так как вы вступили в бой."
L["Keybind changes were saved."] = "Назначение клавиш были сохранены."
L["Keybind changes were discarded."] = "Назначение клавиш были отменены."
L["No keybinds were changed."] = "Назначение клавиш не были изменены."
L["No keybinds set."] = "Клавишы не назначены."
L["%s is now unbound."] = "%s не назначены."
L["%s is now bound to %s"] = "%s назначены для %s"
