local LibChatWindow, version = CogWheel:Set("LibChatWindow", 24)
if (not LibChatWindow) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibChatWindow requires LibClientBuild to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibChatWindow requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibChatWindow requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibChatWindow requires LibFrame to be loaded.")

local LibSecureHook = CogWheel("LibSecureHook")
assert(LibSecureHook, "LibChatWindow requires LibSecureHook to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibChatWindow)
LibEvent:Embed(LibChatWindow)
LibFrame:Embed(LibChatWindow)
LibSecureHook:Embed(LibChatWindow)

-- Lua API 
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error 
local ipairs = ipairs
local pairs = pairs
local select = select
local string_find = string.find
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local type = type
local unpack = unpack

-- WoW API
local FCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame
local GetCVar = _G.GetCVar
local hooksecurefunc = _G.hooksecurefunc
local UIFrameFadeRemoveFrame = _G.UIFrameFadeRemoveFrame

-- WoW Objects
local CHAT_FRAMES = _G.CHAT_FRAMES
local CHAT_FRAME_TEXTURES = _G.CHAT_FRAME_TEXTURES

-- Create or retrieve our registries
LibChatWindow.embeds = LibChatWindow.embeds or {}
LibChatWindow.windows = LibChatWindow.windows or {}
LibChatWindow.frame = LibChatWindow.frame or LibChatWindow:CreateFrame("Frame")

-- Speed shortcuts
local windows = LibChatWindow.windows

-- Blizzard API methods
local SetAlpha = LibChatWindow.frame.SetAlpha

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if (type(value) == select(i, ...)) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- module post create/post handle updates
local postUpdateWindowProxy = function(self, frame, isTemporary, ...)
	local postCreateWindow = isTemporary and self.PostCreateTemporaryChatWindow or self.PostCreateChatWindow
	if postCreateWindow then 
		if isTemporary then 
			postCreateWindow(self, frame, isTemporary, ...)
		else 
			postCreateWindow(self, frame)
		end 
	end 
end 

LibChatWindow.GetAllChatWindows = function(self)
	return ipairs(CHAT_FRAMES)
end 

LibChatWindow.GetAllHandledChatWindows = function(self)
	return ipairs(windows)
end 

LibChatWindow.HandleWindow = function(self, frame, isTemporary, ...)
	-- silenty exit if the window has been handled already
	if windows[frame] then 
		return 
	end 

	-- Add the window to our registry
	table_insert(windows, frame)  

	-- hashed for faster checks. we keep window data here too.
	windows[frame] = {} 

	-- module post updates
	self:ForAllEmbeds(postUpdateWindowProxy, frame, isTemporary, ...)
end

LibChatWindow.HandleAllChatWindows = function(self)
	for _,frameName in self:GetAllChatWindows() do 
		local frame = _G[frameName]
		if frame then 
			LibChatWindow:HandleWindow(frame, frame.isTemporary)
		end 
	end 
end

LibChatWindow.IsChatWindowHandled = function(self, frame)
	return windows[frame] and true or false
end 

LibChatWindow.IsChatWindowTemporary = function(self, frame)
	return frame.isTemporary and true or false
end 

LibChatWindow.SetChatWindowPosition = function(self, frame, ...)
	local db = windows[frame]
	if (not db) then 
		return 
	end 
	db.slaveMaster = nil
	db.position = { ... }
	db.queuePositionUpdate = true
end

LibChatWindow.SetChatWindowSize = function(self, frame, ...)
	local db = windows[frame]
	if (not db) then 
		return 
	end 
	db.slaveMaster = nil
	db.size = { ... }
	db.queueSizeUpdate = true
end

LibChatWindow.SetChatWindowAsSlaveTo = function(self, frame, master)
	local db = windows[frame]
	if (not db) then 
		return 
	end 
	db.slaveMaster = master
	db.queuePositionUpdate = true
	db.queueSizeUpdate = true
end

LibChatWindow.UpdateChatWindowPositions = function(self, forced)
	for _,frame in self:GetAllHandledChatWindows() do 
		local db = windows[frame]
		if (db.position or db.slaveMaster) and (db.queuePositionUpdate or forced) then 
			-- Is this the best way to stop blizzard from taking control back?
			frame.ignoreFramePositionManager = true
			if db.slaveMaster then 
				frame:ClearAllPoints()
				frame:SetAllPoints(db.slaveMaster)
			else 
				frame.Place(frame, unpack(db.position))
			end 
			db.queuePositionUpdate = nil
		end 
		self:ForAllEmbeds("PostUpdateChatWindowPosition", frame)
	end 
end

LibChatWindow.UpdateChatWindowSizes = function(self, forced)
	for _,frame in self:GetAllHandledChatWindows() do 
		local db = windows[frame]
		if (db.size or db.slaveMaster) and (db.queueSizeUpdate or forced) then 
			if db.slaveMaster then 
				local scale = db.slaveMaster:GetEffectiveScale()
				local width, height = db.slaveMaster:GetSize()
				frame:SetSize(width/scale, height/scale)
			else 
				frame:SetSize(unpack(db.size))
			end 
			db.queueSizeUpdate = nil
		end 
		self:ForAllEmbeds("PostUpdateChatWindowSize", frame)
	end 
end

LibChatWindow.UpdateChatWindowColors = function(self, forced)
	for _,frame in self:GetAllHandledChatWindows() do 
		self:ForAllEmbeds("PostUpdateChatWindowColors", frame)
	end 
end

local chatFrameTextures = {
	"Background",
	"TopLeftTexture", 
	"BottomLeftTexture", 
	"TopRightTexture", 
	"BottomRightTexture",
	"LeftTexture", 
	"RightTexture", 
	"BottomTexture", 
	"TopTexture"
}

local buttonFrameTextures = {
	"Background",
	"TopLeftTexture", 
	"BottomLeftTexture", 
	"TopRightTexture", 
	"BottomRightTexture",
	"LeftTexture", 
	"RightTexture", 
	"BottomTexture", 
	"TopTexture"
}

local editBoxTextures = {
	"Left", 
	"Mid", 
	"Right", 
	"FocusLeft", 
	"FocusMid", 
	"FocusRight", 
	"ConversationIcon"
}

local tabTextures = {
	"Left",
	"Middle", 
	"Right", 
	"SelectedLeft", 
	"SelectedMiddle", 
	"SelectedRight", 
	"HighlightLeft", 
	"HighlightMiddle", 
	"HighlightRight"
}

LibChatWindow.GetChatWindowTextures = function(self, frame)
	local counter = 0
	local name = frame:GetName()
	return function() 
		counter = counter + 1
		if chatFrameTextures[counter] then 
			local tex = _G[name..chatFrameTextures[counter]]
			if tex then 
				return tex 
			end 
		end 
	end 
end 

LibChatWindow.GetChatWindowButtonFrameTextures = function(self, frame)
	local counter = 0
	local buttonFrame = _G[frame:GetName().."ButtonFrame"]
	if buttonFrame then 
		local name = buttonFrame:GetName()
		return function() 
			counter = counter + 1
			if buttonFrameTextures[counter] then 
				local tex = _G[name..buttonFrameTextures[counter]]
				if tex then 
					return tex 
				end 
			end 
		end 
	end 
end 

LibChatWindow.GetChatWindowEditBoxTextures = function(self, frame)
	local counter = 0
	local editBox = _G[frame:GetName().."EditBox"]
	if editBox then 
		local name = editBox:GetName()
		return function() 
			counter = counter + 1
			if editBoxTextures[counter] then 
				local tex = _G[name..editBoxTextures[counter]]
				if tex then 
					return tex 
				end 
			end 
		end 
	end 
end

LibChatWindow.GetChatWindowTabTextures = function(self, frame)
	local counter = 0
	local tab = _G[frame:GetName().."Tab"]
	if tab then 
		local name = tab:GetName()
		return function() 
			counter = counter + 1
			if tabTextures[counter] then 
				local tex = _G[name..tabTextures[counter]]
				if tex then 
					return tex 
				end 
			end 
		end 
	end 
end 

LibChatWindow.GetChatWindowMenuButton = function(self)
	return _G.ChatFrameMenuButton
end 

LibChatWindow.GetChatWindowChannelButton = function(self)
	return _G.ChatFrameChannelButton
end 

LibChatWindow.GetChatWindowVoiceDeafenButton = function(self)
	return _G.ChatFrameToggleVoiceDeafenButton
end 

LibChatWindow.GetChatWindowVoiceMuteButton = function(self)
	return _G.ChatFrameToggleVoiceMuteButton
end 

LibChatWindow.GetChatWindowFriendsButton = function(self)
	return _G.FriendsMicroButton
end 

LibChatWindow.GetChatWindowClickAnywhereButton = function(self, frame)
	return _G[frame:GetName().."ClickAnywhereButton"]
end 

LibChatWindow.GetChatWindowButtonFrame = function(self, frame)
	return _G[frame:GetName().."ButtonFrame"]
end 

LibChatWindow.GetChatWindowMinimizeButton = function(self, frame)
	return _G[frame:GetName().."ButtonFrameMinimizeButton"]
end 

LibChatWindow.GetChatWindowEditBox = function(self, frame)
	return _G[frame:GetName().."EditBox"]
end 

LibChatWindow.GetChatWindowCurrentEditBox = function(self, frame)
	if (GetCVar("chatStyle") == "classic") then
		return _G.ChatFrame1EditBox
	else
		if frame.isDocked then
			for _, frame in pairs(_G.GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES) do
				local editbox = _G[frame:GetName().."EditBox"]
				if (editbox and editbox:IsShown()) then
					return editbox
				end
			end
		end
		return _G[frame:GetName().."EditBox"]
	end
end 

LibChatWindow.GetChatWindowScrollToBottomButton = function(self, frame)
	return frame.ScrollToBottomButton
end 

LibChatWindow.GetChatWindowScrollBar = function(self, frame)
	return frame.ScrollBar
end 

LibChatWindow.GetChatWindowScrollBarThumbTexture = function(self, frame)
	return frame.ScrollBar and frame.ScrollBar.ThumbTexture
end 

LibChatWindow.GetChatWindowTab = function(self, frame)
	return _G[frame:GetName().."Tab"]
end 

LibChatWindow.GetChatWindowTabText = function(self, frame)
	return _G[frame:GetName().."TabText"]
end 

LibChatWindow.GetChatWindowTabIcon = function(self, frame)
	return _G[frame:GetName().."TabConversationIcon"]
end 

LibChatWindow.GetSelectedChatFrame = function(self)
	return _G.SELECTED_CHAT_FRAME
end 

LibChatWindow.OnEvent = function(self, event, ...)
	if (event == "UPDATE_CHAT_WINDOWS")
	or (event == "UPDATE_FLOATING_CHAT_WINDOWS") 
	or (event == "UI_SCALE_CHANGED") 
	or (event == "DISPLAY_SIZE_CHANGED") 
	or (event == "CG_VIDEO_OPTIONS_APPLY") 
	or (event == "CG_VIDEO_OPTIONS_OKAY") 
	or (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateChatWindowPositions(true)
	end 

	if (event == "UPDATE_CHAT_WINDOWS")
	or (event == "UPDATE_FLOATING_CHAT_WINDOWS") 
	or (event == "UI_SCALE_CHANGED") 
	or (event == "DISPLAY_SIZE_CHANGED") 
	or (event == "CG_VIDEO_OPTIONS_APPLY") 
	or (event == "CG_VIDEO_OPTIONS_OKAY") 
	or (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateChatWindowSizes(true)
	end 

	if (event == "UPDATE_CHAT_COLOR")
	or (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateChatWindowColors(true)
	end 

	if (event == "CG_OPEN_TEMPORARY_CHAT_WINDOW") then 
		local currentFrame = ...
		self:HandleWindow(currentFrame, currentFrame.isTemporary, select(2, ...))
	end 

end 

LibChatWindow.Enable = function(self)
	self:UnregisterAllEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

	-- fired when chat window settings are loaded into the client
	self:RegisterEvent("UPDATE_CHAT_WINDOWS", "OnEvent")

	-- fired when chat window layouts need to be updated
	self:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", "OnEvent")

	-- fired on client scale, resolution or window size changes
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterMessage("CG_VIDEO_OPTIONS_APPLY", "OnEvent")
	self:RegisterMessage("CG_VIDEO_OPTIONS_OKAY", "OnEvent")

	-- forcefully fired upon temporary window creation
	self:RegisterMessage("CG_OPEN_TEMPORARY_CHAT_WINDOW", "OnEvent")

	-- proxy temporary windows creation through our event system
	-- @return currentFrame, chatType, chatTarget, sourceChatFrame, selectWindow 
	self:SetSecureHook("FCF_OpenTemporaryWindow", function(...) 
		local frame = FCF_GetCurrentChatFrame()
		if frame then 
			self:SendMessage("CG_OPEN_TEMPORARY_CHAT_WINDOW", frame, ...) 
		end 
	end, "CG_OPEN_TEMPORARY_CHAT_WINDOW")

	-- initial positioning
	self:UpdateChatWindowPositions(true)

	-- Need to set this to avoid frame popping back up
	CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 0
end 

LibChatWindow:UnregisterAllEvents()
LibChatWindow:RegisterEvent("PLAYER_ENTERING_WORLD", "Enable")


-- Module embedding
local embedMethods = {

	-- runs post create callbacks for all frames
	HandleAllChatWindows = true, 

	-- chat frame queries
	IsChatWindowHandled = true, 
	IsChatWindowTemporary = true,

	-- chat frames tables
	GetAllChatWindows = true, 
	GetAllTemporaryChatWindows = true, 
	GetAllHandledChatWindows = true, 

	-- returns currently selected chat window, if any
	GetSelectedChatFrame = true,

	-- returns currently active editbox, if any
	GetChatWindowCurrentEditBox = true, 

	-- returns the friends micro button (above the chat menu button)
	GetChatWindowFriendsButton = true, 

	-- returns specific objects
	GetChatWindowClickAnywhereButton = true, 
	GetChatWindowButtonFrame = true,
	GetChatWindowChannelButton = true, 
	GetChatWindowEditBox = true, 
	GetChatWindowMenuButton = true,
	GetChatWindowMinimizeButton = true, 
	GetChatWindowScrollToBottomButton = true, 
	GetChatWindowScrollBar = true, 
	GetChatWindowScrollBarThumbTexture = true, 
	GetChatWindowTab = true, 
	GetChatWindowTabIcon = true, 
	GetChatWindowTabText = true, 
	GetChatWindowVoiceDeafenButton = true, 
	GetChatWindowVoiceMuteButton = true, 

	-- texture iterators (for tex in self:<Method>() do )
	GetChatWindowTextures = true, 
	GetChatWindowButtonFrameTextures = true,
	GetChatWindowEditBoxTextures = true, 
	GetChatWindowTabTextures = true, 

	-- chat frame setup
	SetChatWindowPosition = true, 
	SetChatWindowSize = true, 
	SetChatWindowAsSlaveTo = true
}

-- Iterate all embedded modules for the given method name or function
-- Silently fail if nothing exists. We don't want an error here. 
LibChatWindow.ForAllEmbeds = function(self, method, ...)
	for target in pairs(self.embeds) do 
		if (target) then 
			if (type(method) == "string") then
				if target[method] then
					target[method](target, ...)
				end
			else
				method(target, ...)
			end
		end 
	end 
end 

LibChatWindow.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibChatWindow.embeds) do
	LibChatWindow:Embed(target)
end
