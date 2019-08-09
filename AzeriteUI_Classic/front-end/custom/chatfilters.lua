local ADDON, Private = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("ChatFilters", "LibEvent", "LibMessage", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibFader", "LibSlash")
Module:SetIncompatible("Prat-3.0")

-- Something isn't working as intended, disabling it until we can figure it out. 
Module:SetIncompatible("AzeriteUI")

-- Lua API
local _G = _G
local pairs = pairs
local string_format = string.format

-- WoW API
local ChatFrame_AddMessageEventFilter = _G.ChatFrame_AddMessageEventFilter
local ChatFrame_RemoveMessageEventFilter = _G.ChatFrame_RemoveMessageEventFilter
local GetTime = _G.GetTime

-- Delay in seconds between each allowed identical message
local throttle = 10 

-- Cache of throttled messages
local throttledMessages = {} 

-- Channels we wish to throttle
local throttledChannels = {
	"CHAT_MSG_INSTANCE_CHAT", 
	"CHAT_MSG_INSTANCE_CHAT_LEADER", 
	"CHAT_MSG_BN_CONVERSATION", 
	"CHAT_MSG_BN_INLINE_TOAST_ALERT", 
	"CHAT_MSG_BN_INLINE_TOAST_BROADCAST", 
	"CHAT_MSG_BN_INLINE_TOAST_CONVERSATION", 
	"CHAT_MSG_BN_WHISPER", 
	"CHAT_MSG_BN_WHISPER_INFORM", 
	"CHAT_MSG_CHANNEL", 
	"CHAT_MSG_GUILD", 
	"CHAT_MSG_MONSTER_WHISPER", 
	"CHAT_MSG_OFFICER", 
	"CHAT_MSG_PARTY", 
	"CHAT_MSG_PARTY_LEADER", 
	"CHAT_MSG_RAID", 
	"CHAT_MSG_RAID_BOSS_WHISPER", 
	"CHAT_MSG_RAID_LEADER", 
	"CHAT_MSG_RAID_WARNING", 
	"CHAT_MSG_SAY", 
	"CHAT_MSG_SYSTEM", 
	"CHAT_MSG_WHISPER", 
	"CHAT_MSG_WHISPER_INFORM", 
	"CHAT_MSG_YELL"
}

local throttleMessages = function(self, event, msg, ...)
	if (not msg) then 
		return 
	end

    -- We use this in all conditionals, let's avoid double function calls!
	local now = GetTime()
	
	-- Prune away messages that has timed out without repetitions. 
	-- This iteration shouldn't cost much when called on every new message, 
	-- the database simply won't have time to accumulate very many entries. 
	for msg,when in pairs(throttledMessages) do 
		if ((when < now) and (msg ~= text)) then 
			throttledMessages[msg] = nil
			--Module:AddDebugMessageFormatted(string_format("ChatFilters cleared the timer for: '%s'", msg))
		end
	end

    -- If the timer for this message hasn't been set, or if 10 seconds have passed, 
    -- we set the timer to 10 new seconds, show the message once, and return. 
    if (not throttledMessages[msg]) then 
		throttledMessages[msg] = now + 10 
		--Module:AddDebugMessageFormatted(string_format("ChatFilters set a 10 second throttle for: '%s'", msg))
        return 
	end
	
    -- If we got here the timer has been set, but it's still too early.
	if ((throttledMessages[msg]) and (throttledMessages[msg] > now)) then 
		--Module:AddDebugMessageFormatted(string_format("ChatFilters filtered out: '%s'", msg))
		return true
	end 
end

Module.OnInit = function(self)
	-- Here we are, doing nothing. 
	-- Will add a db creation here if we ever add more advanced filters and options. 
end

Module.OnEnable = function(self)
	for i = 1,#throttledChannels do 
		ChatFrame_AddMessageEventFilter(throttledChannels[i], throttleMessages)	
	end
end

Module.OnDisable = function(self)
	for i = 1,#throttledChannels do 
		ChatFrame_RemoveMessageEventFilter(throttledChannels[i], throttleMessages)	
	end
end