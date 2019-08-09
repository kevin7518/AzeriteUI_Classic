local ADDON = ...
local L = CogWheel("LibLocale"):NewLocale(ADDON, "zhCN")
if (not L) then 
	return 
end 

-- General Stuff
--------------------------------------------
-- Most of these are inserted into other strings, 
-- the idea here is to keep them short and simple. 
L["Enable"] = "启用" 
L["Disable"] = "禁用" 
L["Enabled"] = "|cff00aa00启用|r"
L["Disabled"] = "|cffff0000禁用|r"
L["<Left-Click>"] = "<鼠标左键>"
L["<Middle-Click>"] = "<鼠标中键>"
L["<Right-Click>"] = "<鼠标右键>"

-- Clock & Time Settings
--------------------------------------------
L["New Event!"] = "新事件！"
L["New Mail!"] = "新邮件！"
L["%s to toggle calendar."] = "按下 %s 打开或关闭日历。"
L["%s to use local computer time."] = "按下 %s 使用计算机本地时间。"
L["%s to use game server time."] = "按下 %s 使用游戏服务器时间。"
L["%s to use standard (12-hour) time."] = "按下 %s 使用12小时制。"
L["%s to use military (24-hour) time."] = "按下 %s 使用24小时制。"
L["Now using local computer time."] = "现在使用计算机本地时间。"
L["Now using game server time."] = "现在使用游戏服务器时间。"
L["Now using standard (12-hour) time."] = "现在使用12小时制。"
L["Now using military (24-hour) time."] = "现在使用24小时制。"

-- Network & Performance Information
--------------------------------------------
L["Network Stats"] = "网络状态"
L["World latency:"] = "世界延迟:"
L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."] = "这是世界服务器的延迟，它影响施法，制造，与其他玩家或NPC的交互。这个数值决定战斗操作的延迟。" 
L["Home latency:"] = "本地延迟:"
L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."] = "这是本地服务器的延迟。它影响聊天，拍卖行和一些其他非战斗操作。"

-- XP, Honor & Artifact Bars
--------------------------------------------
-- These are in the tooltips
L["Normal"] = "正常"
L["Rested"] = "休息充分"
L["Resting"] = "休息中"
L["Current Artifact Power: "] = "当前神器能量: "
L["Current Honor Points: "] = "当前荣誉点数: "
L["Current Standing: "] = "当前声望: "
L["Current XP: "] = "当前经验值: "
L["Rested Bonus: "] = "休息充分奖励: "
L["%s of normal experience gained from monsters."] = "%s 从怪物处获取到的正常经验值"
L["You must rest for %s additional hours to become fully rested."] = "你还需要休息 %s 小时以获得休息充分状态。"
L["You must rest for %s additional minutes to become fully rested."] = "你还需要休息 %s 分钟以获得休息充分状态。"
L["You should rest at an Inn."] = "你应该在旅馆休息。"
L["Sticky Minimap bars enabled."] = "粘性小地图条已启用。"
L["Sticky Minimap bars disabled."] = "粘性小地图条已禁用。"

-- These are displayed within the circular minimap bar frame, 
-- and must be very short, or we'll have an ugly overflow going. 
L["to level %s"] = "到 %s 级" 
L["to %s"] = "到 %s"
L["to next trait"] = "到下一个特质"

-- Try to keep the following fairly short, as they should
-- ideally be shown on a single line in the tooltip, 
-- even with the "<Right-Click>" and similar texts inserted.
L["%s to toggle Artifact Window>"] = "按下 %s 打开或关闭神器窗口>"
L["%s to toggle Honor Talents Window>"] = "按下 %s 打开或关闭荣誉天赋窗口>"
L["%s to disable sticky bars."] = "按下 %s 禁用粘性小地图条。"
L["%s to enable sticky bars."] = "按下 %s 启用粘性小地图条。"  

-- Config & Micro Menu
--------------------------------------------
-- Config button tooltip
-- *Doing it this way to keep the localization file generic, 
--  while making sure the end result still is personalized to the addon.
L["Main Menu"] = ADDON
L["Click here to get access to game panels."] = "单击此处可访问各种游戏窗口，例如角色，法术书，天赋，或更改动作栏的各种设置。"

-- These should be fairly short to fit in a single line without 
-- having the tooltip grow to very high widths. 
L["%s to toggle Blizzard Menu."] = "按下 %s 打开或关闭 Blizzard 菜单。"
L["%s to toggle Options Menu."] = "按下 %s 打开或关闭 "..ADDON.." 菜单。"
L["%s to toggle your Bags."] = "按下 %s 打开或关闭你的背包。"

-- Config Menu
--------------------------------------------
-- Remember that these shall fit on a button, 
-- so they can't be that long. 
-- You don't need a full description here. 
L["Debug Mode"] = "调试模式" 
L["Debug Console"] = "调试控制台" 
L["Load Console"] = "加载控制台"
L["Unload Console"] = "卸载控制台"
L["Reload UI"] = "重新载入界面"
L["ActionBars"] = "动作栏"
L["Bind Mode"] = "键位绑定模式"
L["Cast on Down"] = "按下施法"
L["Button Lock"] = "按钮锁定"
L["More Buttons"] = "更多按钮"
L["No Extra Buttons"] = "无额外按钮"
L["+%.0f Buttons"] = "+%.0f 按钮"
L["Extra Buttons Visibility"] = "额外按钮显示模式"
L["MouseOver"] = "鼠标停留显示"
L["MouseOver + Combat"] = "鼠标停留及战斗中显示"
L["Always Visible"] = "一直显示"
L["Stance Bar"] = "姿态栏"
L["Pet Bar"] = "宠物栏"
L["UnitFrames"] = "单位框体"
L["Party Frames"] = "队伍框体"
L["Raid Frames"] = "团队框体"
L["PvP Frames"] = "PVP框体"
L["HUD"] = "HUD"
L["Alerts"] = "警报"
L["TalkingHead"] = "对话框"
L["NamePlates"] = "姓名板"
L["Auras"] = "光环"
L["Explorer Mode"] = "探索者模式"
L["Player Fading"] = "玩家渐隐"
L["Tracker Fading"] = "跟踪器渐隐"
L["Healer Mode"] = "治疗模式" 

-- Menu button tooltips, not actually used at the moment. 
L["Click to enable the Stance Bar."] = "点击以启用姿态栏。"
L["Click to disable the Stance Bar."] = "点击以禁用姿态栏。"
L["Click to enable the Pet Action Bar."] = "点击以启用宠物动作栏。"
L["Click to disable the Pet Action Bar."] = "点击以禁用宠物动作栏。"

-- Various Button Tooltips
--------------------------------------------
L["%s to leave the vehicle."] = "按下 %s 离开载具。"
L["%s to dismount."] = "按下 %s 解散坐骑。"

-- Abbreviations
--------------------------------------------
-- This is shown of group frames when the unit 
-- has low or very low mana. Keep it to 3 letters max! 
L["oom"] = "oom" -- out of mana

-- These are shown on the minimap compass when 
-- rotating minimap is enabled. Keep it to single letters!
L["N"] = "北" -- compass North
L["E"] = "东" -- compass East
L["S"] = "南" -- compass South
L["W"] = "西" -- compass West

-- Keybind mode
--------------------------------------------
-- This is shown in the frame, it is word-wrapped. 
-- Try to keep the length fairly identical to enUS, though, 
-- to make sure it fits properly inside the window. 
L["Hover your mouse over any actionbutton and press a key or a mouse button to bind it. Press the ESC key to clear the current actionbutton's keybinding."] = "鼠标指向任何动作条按钮来绑定它。按Esc键来清除当前动作条按钮的按键绑定。"

-- These are output to the chat frame. 
L["Keybinds cannot be changed while engaged in combat."] = "战斗中无法修改键位绑定。"
L["Keybind changes were discarded because you entered combat."] = "键位绑定改动因进入战斗状态而被舍弃。"
L["Keybind changes were saved."] = "键位绑定改动已保存。"
L["Keybind changes were discarded."] = "键位绑定改动已舍弃。"
L["No keybinds were changed."] = "键位绑定无改动。"
L["No keybinds set."] = "无键位绑定。"
L["%s is now unbound."] = "%s 已解除绑定。"
L["%s is now bound to %s"] = "%s 已绑定到 %s"
