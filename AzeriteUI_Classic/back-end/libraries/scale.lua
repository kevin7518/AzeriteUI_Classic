local LibScale = CogWheel:Set("LibScale", 1)
if (not LibScale) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibScale requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibScale requires LibEvent to be loaded.")

local LibHook = CogWheel("LibHook")
assert(LibHook, "LibScale requires LibHook to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibScale)
LibEvent:Embed(LibScale)
LibHook:Embed(LibScale)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local math_floor = math.floor
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame
local InCombatLockdown = _G.InCombatLockdown

-- WoW Objects
local UIParent = _G.UIParent
local WorldFrame = _G.WorldFrame

-- Library registries
LibScale.embeds = LibScale.embeds or {}


-- Utility Functions
-----------------------------------------------------------------

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end




-- Library API
-----------------------------------------------------------------

LibScale.GetFrameSize = function(self, frame)
	local width, height = frame:GetSize()
	return math_floor(width + .5), math_floor(height + .5)
end 

LibScale.UpdateWorldScales = function(self)

	local oldWidth, oldHeight = self.worldWidth, self.worldHeight
	local newWidth, newHeight = self:GetFrameSize(WorldFrame)
	if (not newWidth) or (not newHeight) then 
		return 
	end 

	local oldScale
	if (oldWidth and oldHeight) then
		oldScale = math_floor((oldWidth/oldHeight)*100)*100
	end 
	local newScale = math_floor((newWidth/newHeight)*100)*100

	self.worldWidth = newWidth
	self.worldHeight = newHeight
	self.worldScale = newScale

	return newScale ~= oldScale 
end 

LibScale.UpdateInterfaceScales = function(self)

	local oldWidth, oldHeight = self.interfaceWidth, self.interfaceHeight
	local newWidth, newHeight = self:GetFrameSize(UIParent)
	if (not newWidth) or (not newHeight) then 
		return 
	end 

	local oldScale
	if (oldWidth and oldHeight) then
		oldScale = math_floor((oldWidth/oldHeight)*100)*100
	end 
	local newScale = math_floor((newWidth/newHeight)*100)*100

	self.interfaceWidth = newWidth
	self.interfaceHeight = newHeight
	self.interfaceScale = newScale

	return (newScale ~= oldScale) or (newWidth ~= oldWidth) or (newHeight ~= oldHeight)
end 

LibScale.OnEvent = function(self, event, ...)
	if self:UpdateWorldScales() then 
		self:SendMessage("CG_WORLD_SCALE_UPDATE")
	end 
	if self:UpdateInterfaceScales() then 
		self:SendMessage("CG_INTERFACE_SCALE_UPDATE")
	end 
end

LibScale.Enable = function(self)

	self:UpdateWorldScales()
	self:UpdateInterfaceScales()

	self:UnregisterAllEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent") -- window/resolution changes
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent") -- scale slider changes

	self:SetHook(WorldFrame, "OnSizeChanged", "OnEvent", "LibScale_WorldFrame_OnSizeChanged")
	self:SetHook(UIParent, "OnSizeChanged", "OnEvent", "LibScale_UIParent_OnSizeChanged")
end 

LibScale:UnregisterAllEvents()
LibScale:Enable()

--LibScale:RegisterEvent("PLAYER_ENTERING_WORLD", "Enable")

local embedMethods = {
}

LibScale.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibScale.embeds) do
	LibScale:Embed(target)
end
