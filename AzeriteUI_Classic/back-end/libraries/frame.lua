local LibFrame = CogWheel:Set("LibFrame", 54)
if (not LibFrame) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibFrame requires LibClientBuild to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibFrame requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibFrame requires LibEvent to be loaded.")

local LibHook = CogWheel("LibHook")
assert(LibHook, "LibFrame requires LibHook to be loaded.")

local LibSecureHook = CogWheel("LibSecureHook")
assert(LibSecureHook, "LibFrame requires LibSecureHook to be loaded.")

-- Embed event functionality into this
LibClientBuild:Embed(LibFrame)
LibMessage:Embed(LibFrame)
LibEvent:Embed(LibFrame)
LibHook:Embed(LibFrame)
LibSecureHook:Embed(LibFrame)

-- Lua API
local _G = _G
local getmetatable = getmetatable
local math_floor = math.floor
local pairs = pairs
local pcall = pcall
local select = select
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame
local InCombatLockdown = _G.InCombatLockdown
local IsLoggedIn = _G.IsLoggedIn

-- WoW Objects
local UIParent = _G.UIParent
local WorldFrame = _G.WorldFrame

-- Default keyword used as a fallback. this will not be user editable.
local KEYWORD_DEFAULT = "UICenter"

-- Create the new frame parent 
if (not LibFrame.frameParent) then
	LibFrame.frameParent = LibFrame.frameParent or CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
end 

-- Create the UICenter frame
if (not LibFrame.frame) then
	LibFrame.frame = CreateFrame("Frame", nil, LibFrame.frameParent, "SecureHandlerAttributeTemplate")
else 
	-- needs to be done since not all previous versions held this frame
	LibFrame.frame:SetParent(LibFrame.frameParent) 
	UnregisterAttributeDriver(LibFrame.frame, "state-visibility")
end 

-- Hide the master visibility frame if we haven't yet reached login. 
-- This might improve addon loading time. 
if (not IsLoggedIn()) and (not InCombatLockdown()) then 
	LibFrame.frameParent:Hide()
end

-- Return a value rounded to the nearest integer.
local round = function(value)
	return (value + .5) - (value + .5)%1
end

local SetDisplaySize = function()

	--Retrieve UIParent size
	local width, height = UIParent:GetSize()
	width = round(width)
	height = round(height)

	-- Set the size and take scale into consideration
	local precision = 1e5
	--local uiScale = UIParent:GetEffectiveScale()
	--uiScale = ((uiScale*precision + .5) - (uiScale*precision + .5)%1)/precision

	local scale = height/1080

	local displayWidth = (((width/height) >= (16/10)*3) and width/3 or width)/scale
	local displayHeight = height/scale
	local displayRatio = displayWidth/displayHeight

	-- Implement this later when we've create an API for it.
	if false then 

		-- Higher ratio means a narrower screen.
		local desiredRatioMin = LibFrame.DesiredRatioMin or 4/3 -- 16/10 
		local desiredRatioMax = LibFrame.DesiredRatioMax or 16/10 -- 16/9

		local deviation = ((round(displayRatio*precision))/precision) - displayRatio

		-- if the goal range exists, figure out which one to use. 
		local min = ((desiredRatioMin - deviation) <= displayRatio) and ((desiredRatioMin + deviation) >= displayRatio)
		local max = ((desiredRatioMax - deviation) <= displayRatio) and ((desiredRatioMax + deviation) >= displayRatio)

		--print("Minratio, maxratio, deviation", desiredRatioMin, desiredRatioMax, deviation)

		-- The desired ratio is within the bounds of the screen size, apply it!
		if min then
			displayWidth = round(displayHeight*desiredRatioMin)
			--print("Going with Minratio, it's a fit!")
		elseif max then 
			displayWidth = round(displayHeight*desiredRatioMax)
			--print("Going with Maxratio, it's a fit!")
		else
			if (displayRatio > desiredRatioMax) then
				displayWidth = round(displayHeight*desiredRatioMax)
				--print("Going with Maxratio, as it's closest to our goal")
			elseif (displayRatio > desiredRatioMin) then 
				displayWidth = round(displayHeight*desiredRatioMin)
				--print("Going with Minratio, as it's closest to our goal")
			end
		end
	end

	LibFrame.frame:SetFrameStrata(UIParent:GetFrameStrata())
	LibFrame.frame:SetFrameLevel(UIParent:GetFrameLevel())
	LibFrame.frame:ClearAllPoints()
	LibFrame.frame:SetPoint("BOTTOM", UIParent, "BOTTOM")
	LibFrame.frame:SetScale(scale)
	LibFrame.frame:SetSize(round(displayWidth), round(displayHeight))
end 
SetDisplaySize()

-- Keep it and all its children hidden during pet battles. 
RegisterAttributeDriver(LibFrame.frame, "state-visibility", "[petbattle] hide; show")

-- Keyword registry to translate words to frame handles used for anchoring or parenting
LibFrame.keyWords = LibFrame.keyWords or { [KEYWORD_DEFAULT] = function() return LibFrame.frame end } 
LibFrame.frames = LibFrame.frames or {}
LibFrame.fontStrings = LibFrame.fontStrings or {}
LibFrame.textures = LibFrame.textures or {}
LibFrame.embeds = LibFrame.embeds or {}

-- Speed shortcuts
local frames = LibFrame.frames
local textures = LibFrame.textures
local fontStrings = LibFrame.fontStrings
local keyWords = LibFrame.keyWords

-- Our special frames
local DisplayFrame = LibFrame.frame
local VisibilityFrame = LibFrame.frameParent

-- Frame meant for events, timers, etc
local Frame = CreateFrame("Frame", nil, WorldFrame) -- parented to world frame to keep running even if the UI is hidden
local FrameMethods = getmetatable(Frame).__index

local blizzCreateFontString = FrameMethods.CreateFontString
local blizzCreateTexture = FrameMethods.CreateTexture
local blizzRegisterEvent = FrameMethods.RegisterEvent
local blizzUnregisterEvent = FrameMethods.UnregisterEvent
local blizzIsEventRegistered = FrameMethods.IsEventRegistered
local blizzSetSize = FrameMethods.SetSize
local blizzSetWidth = FrameMethods.SetWidth
local blizzSetHeight = FrameMethods.SetHeight

-- Utility Functions
-----------------------------------------------------------------
-- Translate keywords to frame handles used for anchoring.
local parseAnchor = function(anchor)
	return anchor and (keyWords[anchor] and keyWords[anchor]() or _G[anchor] and _G[anchor] or anchor) or KEYWORD_DEFAULT and keyWords[KEYWORD_DEFAULT]() or WorldFrame
end

-- Translates keywords and parses normal frames, but doesn't include the defaults and fallbacks
local parseAnchorStrict = function(anchor)
	return anchor and (keyWords[anchor] and keyWords[anchor]() or _G[anchor] and _G[anchor] or anchor) 
end

-- WoW 8.2 restricted frame check
local isRestricted = function(frame)
	if (frame and (not pcall(frame.GetPoint, frame))) then
		return true
	end
end


-- Embed source methods into target.
local embed = function(target, source)
	for i,v in pairs(source) do
		if (type(v) == "function") then
			target[i] = v
		end
	end
	return target
end

-- Frame Template
-----------------------------------------------------------------
local frameWidgetPrototype = {

	-- Position a widget, and accept keywords as anchors
	Place = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local point = ...
			self:ClearAllPoints()
			self:SetPoint(point)
		elseif (numArgs == 2) then
			local point, anchor = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor))
		elseif (numArgs == 3) then
			local point, anchor, rpoint = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor), rpoint)
		elseif (numArgs == 5) then
			local point, anchor, rpoint, xoffset, yoffset = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor), rpoint, xoffset, yoffset)
		else
			self:ClearAllPoints()
			self:SetPoint(...)
		end
	end,

	-- Set a single point on a widget without clearing first. 
	-- Like the above function, this too accepts keywords as anchors.
	Point = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local point = ...
			self:SetPoint(point)
		elseif (numArgs == 2) then
			local point, anchor = ...
			self:SetPoint(point, parseAnchor(anchor))
		elseif (numArgs == 3) then
			local point, anchor, rpoint = ...
			self:SetPoint(point, parseAnchor(anchor), rpoint)
		elseif (numArgs == 5) then
			local point, anchor, rpoint, xoffset, yoffset = ...
			self:SetPoint(point, parseAnchor(anchor), rpoint, xoffset, yoffset)
		else
			self:SetPoint(...)
		end
	end,

	-- Size a widget, and accept single input values for squares.
	Size = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local size = ...
			self:SetSize(size, size)
		elseif (numArgs == 2) then
			self:SetSize(...)
		end
	end, 

	-- Assign multiple properties at once. 
	-- Intented to simplify assignment operations in front-end stylesheets. 
	-- Process is generic enough to be a good fit for the back-end.
	SetProperties = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then 
			local list = ...
			for property,value in pairs(list) do 
				self[property] = value
			end
		else 
			for i = 1,numArgs,2 do 
				local property,value = select(i, ...)
				self[property] = value
			end 
		end 
	end,

	-- ConsolePort assumes this exists on a multiple of frames, 
	-- so we're adding it and just opt out of various things by setting it to true.
	IsForbidden = function(self) 
		return true
	end
	
}

local framePrototype
framePrototype = {
	CreateFrame = function(self, frameType, frameName, template) 
		local frame = embed(CreateFrame(frameType or "Frame", frameName, self, template), framePrototype)
		frames[frame] = true
		return frame
	end,
	CreateFontString = function(self, ...)
		local fontString = embed(blizzCreateFontString(self, ...), frameWidgetPrototype)
		fontStrings[fontString] = true
		return fontString
	end,
	CreateTexture = function(self, ...)
		local texture = embed(blizzCreateTexture(self, ...), frameWidgetPrototype)
		textures[texture] = true
		return texture
	end
}

-- Embed custom frame widget methods in the main frame prototype too 
embed(framePrototype, frameWidgetPrototype)

-- Allow more methods to be added to our frame objects. 
-- This will cascade down through all LibFrames, so use with caution!
LibFrame.AddMethod = function(self, method, func)
	-- Silently fail if the method exists.
	-- *Edit: NO! Libraries that add newer version of their methods 
	--  must be able to update those methods upon library updates!
	--if (framePrototype[method]) then
	--	return
	--end

	-- Add the new method to the prototype
	framePrototype[method] = func

	-- Add the method to any existing frames, 
	-- since we're using embedding and not inheritance. 
	for frame in pairs(frames) do
		frame[method] = func
	end
end

-- Register a keyword to trigger a function call when used as an anchor on a frame
-- Even though embeddable, this method uses the global keyword table. 
-- There are no local ones, and this is intentional.
LibFrame.RegisterKeyword = function(self, keyWord, func)
	LibFrame.keyWords[keyWord] = func
end

-- Create a frame with certain extra methods we like to have
LibFrame.CreateFrame = function(self, frameType, frameName, parent, template) 

	-- Do some argument handling to allow the directly embedded version to skip 
	-- the 'parent' argument in the same manner the inherited frame method does.
	-- Because we don't really want two different syntaxes. 
	local parsedAnchor = parseAnchorStrict(parent)
	if (not parsedAnchor) then 
		parsedAnchor = self.IsObjectType and parseAnchor(self) or parseAnchor(parent)
		if (type(parent) == "string") and (not template) then 
			template = parent 
		end 
	end

	-- Create the new frame and copy our custom methods in
	local frame = embed(CreateFrame(frameType or "Frame", frameName, parsedAnchor, template), framePrototype)

	-- Add the frame to our registry
	frames[frame] = true
	
	-- Return it to the user
	return frame
end

-- keyworded anchor > anchor > module.frame > UICenter
LibFrame.GetFrame = function(self, anchor)
	return anchor and parseAnchor(anchor) or self.frame or DisplayFrame
end

LibFrame.UpdateDisplaySize = function(self)
	if (InCombatLockdown()) then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent") 
	end 
	SetDisplaySize()
end

LibFrame.OnEvent = function(self, event, ...)
	if (InCombatLockdown()) then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent") 
	elseif (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 
	self:UpdateDisplaySize()
end

LibFrame.OnReload = function(self, event, ...)
	if (event == "PLAYER_LEAVING_WORLD") then 
		if (not InCombatLockdown()) then 
			VisibilityFrame:Hide()
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then 
		if (not VisibilityFrame:IsShown()) then 
			VisibilityFrame:Show()
		end
	end
end

LibFrame.Enable = function(self)

	-- Get rid of old events from previous handlers, 
	-- if this library for some reason was overwritten 
	-- by a more recent version from a load on demand addon. 
	self:UnregisterAllEvents()

	-- Hide the visibility frame when reloading
	-- The idea is to just stop all running OnUpdate handlers
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnReload")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnReload")

	-- New system only needs to capture changes and events
	-- affecting display size or the cinematic frame visibility.
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

	-- Register for changes to the parent frames
	self:RegisterMessage("CG_WORLD_SCALE_UPDATE", "OnEvent")
	self:RegisterMessage("CG_INTERFACE_SCALE_UPDATE", "OnEvent")
	
	-- Could it be enough to just track frame changes and not events?
	self:SetHook(UIParent, "OnSizeChanged", "UpdateDisplaySize", "LibFrame_UIParent_OnSizeChanged")
	self:SetHook(WorldFrame, "OnSizeChanged", "UpdateDisplaySize", "LibFrame_WorldFrame_OnSizeChanged")
end 

LibFrame:UnregisterAllEvents()
LibFrame:Enable()

-- Module embedding
local embedMethods = {
	CreateFrame = true,
	GetFrame = true,
	RegisterKeyword = true
}

LibFrame.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibFrame.embeds) do
	LibFrame:Embed(target)
end
