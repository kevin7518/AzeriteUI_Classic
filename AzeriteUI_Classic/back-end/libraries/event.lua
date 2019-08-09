local LibEvent = CogWheel:Set("LibEvent", 4
)
if (not LibEvent) then 
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local type = type

-- This library uses LibMessage as a base, 
-- and just fires callbacks to connect to blizzard events.
local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibEvent requires LibMessage to be loaded.")

-- We're reusing the frame and event table in case of an upgrade, 
-- so there is no need to reregister the events.
-- Should be noted that LibMessage also reuse the old event table, 
-- so nothing is lost at all during a library upgrade.
LibEvent.events = LibMessage:New(LibEvent, "RegisterEvent", "RegisterUnitEvent", "UnregisterEvent", "UnregisterAllEvents", "IsEventRegistered")
LibEvent.frame = LibEvent.frame or CreateFrame("Frame")
LibEvent.embeds = LibEvent.embeds or {}

-- More speed shortcuts
local events = LibEvent.events
local frame = LibEvent.frame

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

-- Called for the first instance of an event registered to this library
LibEvent.OnRegister = function(self, event, ...)
	frame:RegisterEvent(event)
end

LibEvent.OnRegisterAlternate = function(self, event, ...)
	frame:RegisterUnitEvent(event, ...)
end

-- Called when all instances of an event is unregistered from this library
LibEvent.OnUnregister = function(self, event, ...)
	frame:UnregisterEvent(event)
end

-- Called when a module is being disabled
LibEvent.OnDisable = function(self, module, event, ...)
	module:UnregisterAllEvents()
end

-- Script to fire blizzard events into the event listeners
LibEvent.frame:SetScript("OnEvent", function(_, event, ...)
	LibEvent:Fire(event, ...)
	for target in pairs(LibEvent.embeds) do
		target:Fire(event, ...)
	end
end)

-- Module embedding
-- These metods are created by the LibMessage:New() call
local embedMethods = {
	Fire = true,
	IsEventRegistered = true, 
	RegisterEvent = true,
	RegisterUnitEvent = true,
	UnregisterEvent = true,
	UnregisterAllEvents = true
}

LibEvent.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibEvent.embeds) do
	LibEvent:Embed(target)
end
