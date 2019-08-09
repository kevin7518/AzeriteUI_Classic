local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardFonts", "LibEvent")
local Layout

-- Lua API
local _G = _G

-- WoW API
local GetLocale = _G.GetLocale
local IsAddOnLoaded = _G.IsAddOnLoaded
local hooksecurefunc = _G.hooksecurefunc

Module.SetFontObjects = function(self)
	-- Various chat constants
	_G.CHAT_FONT_HEIGHTS = { 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 32 }

	-- Chat Font
	-- This is the cont used by chat windows and inputboxes. 
	-- When set early enough in the loading process, all windows inherit this.
	_G.ChatFontNormal:SetFontObject(Layout.ChatFont)

	-- Chat Bubble Font
	-- This is what chat bubbles inherit from. 
	-- We should use this in our custom bubbles too.
	_G.ChatBubbleFont:SetFontObject(Layout.ChatBubbleFont)
end

Module.SetCombatText = function(self)

	-- speed!
	local CombatText_ClearAnimationList = _G.CombatText_ClearAnimationList
	local CombatText_FountainScroll = _G.CombatText_FountainScroll
	local CombatText_StandardScroll = _G.CombatText_StandardScroll

	-- Various globals controlling the FCT
	_G.NUM_COMBAT_TEXT_LINES = 10 -- 20
	_G.COMBAT_TEXT_CRIT_MAXHEIGHT = 70 -- 60
	_G.COMBAT_TEXT_CRIT_MINHEIGHT = 35 -- 30
	--COMBAT_TEXT_CRIT_SCALE_TIME = 0.05
	--COMBAT_TEXT_CRIT_SHRINKTIME = 0.2
	_G.COMBAT_TEXT_FADEOUT_TIME = .75 -- 1.3
	_G.COMBAT_TEXT_HEIGHT = 25 -- 25
	--COMBAT_TEXT_LOW_HEALTH_THRESHOLD = 0.2
	--COMBAT_TEXT_LOW_MANA_THRESHOLD = 0.2
	--COMBAT_TEXT_MAX_OFFSET = 130
	_G.COMBAT_TEXT_SCROLLSPEED = 1.3 -- 1.9
	_G.COMBAT_TEXT_SPACING = 2 * _G.COMBAT_TEXT_Y_SCALE --10
	--COMBAT_TEXT_STAGGER_RANGE = 20
	--COMBAT_TEXT_X_ADJUSTMENT = 80

	-- Hooking changes to text positions after blizz setting changes, 
	-- to show the text in positions that work well with our UI. 
	hooksecurefunc("CombatText_UpdateDisplayedMessages", function() 
		if ( COMBAT_TEXT_FLOAT_MODE == "1" ) then
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_StandardScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 259 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY = 389 * _G.COMBAT_TEXT_Y_SCALE
			}
		elseif ( COMBAT_TEXT_FLOAT_MODE == "2" ) then
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_StandardScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 389 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY =  259 * _G.COMBAT_TEXT_Y_SCALE
			}
		else
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_FountainScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 389 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY = 609 * _G.COMBAT_TEXT_Y_SCALE
			}
		end
		CombatText_ClearAnimationList()
	end)

end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardFonts]")
end

Module.OnInit = function(self)
	-- This new one only affects the style and shadow of the chat font, 
	-- and the size, style and shadow of the chat bubble font.  
	Module:SetFontObjects()

	-- Just modifying floating combat text settings here, nothing else.
	if IsAddOnLoaded("Blizzard_CombatText") then
		Module:SetCombatText()
	else
		Module.HookCombatText = function(self, event, addon, ...)
			if (addon == "Blizzard_CombatText") then
				self:SetCombatText()
				self:UnregisterEvent("ADDON_LOADED", "HookCombatText")
			end
		end
		Module:RegisterEvent("ADDON_LOADED", "HookCombatText")
	end
end
