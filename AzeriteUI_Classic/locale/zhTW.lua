local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "zhTW")
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "啟用" 
L["Disable"] = "停用" 
L["Enabled"] = "|cff00aa00已啟用|r"
L["Disabled"] = "|cffff0000已停用|r"
L["<Left-Click>"] = "<左鍵>"
L["<Middle-Click>"] = "<中鍵>"
L["<Right-Click>"] = "<右鍵>"

-- Clock & Time Settings
--------------------------------------------
-- These are shown in tooltips
L["New Event!"] = "有新活動!"
L["New Mail!"] = "有新郵件!"
L["%s to toggle calendar."] = "%s 切換顯示行事曆。"
L["%s to use local computer time."] = "%s 使用本地電腦時間。"
L["%s to use game server time."] = "%s 使用遊戲伺服器時間。"
L["%s to use standard (12-hour) time."] = "%s 使用標準 (12小時制) 時間。"
L["%s to use military (24-hour) time."] = "%s 使用軍用 (24小時制) 時間。"
L["Now using local computer time."] = "現在使用本地電腦時間。"
L["Now using game server time."] = "現在使用遊戲伺服器時間。"
L["Now using standard (12-hour) time."] = "現在使用標準 (12小時制) 時間。"
L["Now using military (24-hour) time."] = "現在使用軍用 (24小時制) 時間。"

-- Network & Performance Information
--------------------------------------------
-- These are shown in tooltips
L["Network Stats"] = "網路狀態"
L["World latency:"] = "世界延遲:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "這是世界伺服器的延遲，會影響施法、專業製作以及和其他玩家與 NPC 互動。這是決定你的戰鬥行動延遲程度的數值。" 
L["Home latency:"] = "本地延遲:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "這是本地伺服器的延遲，會影響像是聊天、公會聊天、拍賣場和一些其他非戰鬥相關的東西。"

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are shown in tooltips
L["Normal"] = "正常"
L["Rested"] = "已休息"
L["Resting"] = "休息中"
L["Current Artifact Power: "] = "目前神兵之力: " 
L["Current Honor Points: "] = "目前榮譽點數: "
L["Current Standing: "] = "目前標準: "
L["Current XP: "] = "目前經驗值: "
L["Rested Bonus: "] = "休息加成: "
L["%s of normal experience gained from monsters."] = "%s 從怪物身上獲得的正常經驗值。"
L["You must rest for %s additional hours to become fully rested."] = "你必須再多休息 %s 小時才會變成完全休息狀態。"
L["You must rest for %s additional minutes to become fully rested."] = "你必須再多休息 %s 分鐘才會變成完全休息狀態。"
L["You should rest at an Inn."] = "你應該在旅店休息。"
L["Sticky Minimap bars enabled."] = "小地圖固定顯示經驗條已啟用。"
L["Sticky Minimap bars disabled."] = "小地圖固定顯示經驗條已停用。"

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "到等級 %s" 
L["to %s"] = "到 %s"
L["to next trait"] = "到下個特質"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "%s 切換顯示神器視窗>"
L["%s to toggle Honor Talents Window>"] = "%s 切換顯示榮譽天賦視窗>"
L["%s to disable sticky bars."] = "%s 停用小地圖固定顯示經驗條。"
L["%s to enable sticky bars."] = "%s 啟用小地圖固定顯示經驗條。" 

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "點一下這裡打開遊戲內的各種視窗，像是角色資訊、法術書、天賦...等等，或是更改快捷列的各項設定。"

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "%s 切換顯示暴雪微型選單。"
L["%s to toggle Options Menu."] = "%s 切換顯示 "..ADDON.." 選項選單。"
L["%s to toggle your Bags."] = "%s 切換顯示背包。"

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "除錯模式"
L["Debug Console"] = "除錯主控台"
L["Load Console"] = "載入主控台"
L["Unload Console"] = "取消載入主控台"
L["Reload UI"] = "重新載入介面"
L["ActionBars"] = "快捷列"
L["Bind Mode"] = "按鍵設定模式"
L["Cast on Down"] = "按下時施法"
L["Button Lock"] = "鎖定按鈕"
L["More Buttons"] = "更多按鈕"
L["No Extra Buttons"] = "不要更多按鈕"
L["+%.0f Buttons"] = "+%.0f 按鈕"
L["Extra Buttons Visibility"] = "何時顯示更多按鈕"
L["MouseOver"] = "滑鼠指向"
L["MouseOver + Combat"] = "滑鼠指向 + 戰鬥中"
L["Always Visible"] = "總是顯示"
L["Stance Bar"] = "姿勢列"
L["Pet Bar"] = "寵物列"
L["UnitFrames"] = "單位框架"
L["Party Frames"] = "隊伍框架"
L["Raid Frames"] = "團隊框架"
L["PvP Frames"] = "PvP 框架"
L["HUD"] = "HUD"
L["Alerts"] = "通知"
L["TalkingHead"] = "說話的頭"
L["NamePlates"] = "名條/血條"
L["Auras"] = "光環"
L["Player"] = "玩家"
L["Enemies"] = "敵方"
L["Friends"] = "友方"
L["Explorer Mode"] = "探險家模式"
L["Player Fading"] = "自動淡出玩家框架"
L["Tracker Fading"] = "自動淡出任務目標清單"
L["Healer Mode"] = "治療者模式"

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = "點一下啟用姿勢列。"
L["Click to disable the Stance Bar."] = "點一下停用姿勢列。"
L["Click to enable the Pet Action Bar."] = "點一下啟用寵物快捷列。"
L["Click to disable the Pet Action Bar."] = "點一下停用寵物快捷列。"

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "%s 離開載具。"
L["%s to dismount."] = "%s 解除坐騎。"

-- Abbreviations
--------------------------------------------
-- This is shown of group frames when the unit 
-- has low or very low mana. Keep it to 3 letters max! 
L["oom"] = "沒魔" -- out of mana

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
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = "將滑鼠游標指向任何快捷列按鈕，然後按下鍵盤或滑鼠按鍵來設定快速鍵。按下 ESC 鍵清除目前已設定的快速鍵。"

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "戰鬥中無法變更快速鍵。"
L["Keybind changes were discarded because you entered combat."] = "已放棄變更快速鍵，因為你進入戰鬥了。"
L["Keybind changes were saved."] = "已儲存快速鍵變更。"
L["Keybind changes were discarded."] = "已放棄快速鍵變更。"
L["No keybinds were changed."] = "沒有任何快速鍵有變更。"
L["No keybinds set."] = "沒有設定快速鍵。"
L["%s is now unbound."] = "%s 已取消綁定。"
L["%s is now bound to %s"] = "%s 現在綁定給 %s"
