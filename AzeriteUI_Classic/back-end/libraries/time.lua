local LibTime = CogWheel:Set("LibTime", 3)
if (not LibTime) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API
local GetGameTime = _G.GetGameTime

-- WoW Strings
local S_AM = TIMEMANAGER_AM
local S_PM = TIMEMANAGER_PM

-- Library registries
LibTime.embeds = LibTime.embeds or {}

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

-- Calculates standard hours
LibTime.ComputeStandardHours = function(self, hour)
	if (hour > 12) then
		return hour - 12, S_PM
	elseif (hour == 0) then
		return 12, S_AM
	else
		return hour, S_AM
	end
end

-- Calculates military time, but assumes the given time is standard (12 hour)
LibTime.ComputeMilitaryHours = function(self, hour, am)
	if (am and hour == 12) then
		return 0
	elseif (not am and hour < 12) then
		return hour + 12
	else
		return hour
	end
end

-- Retrieve the local client computer time
LibTime.GetLocalTime = function(self, useStandardTime)
	local hour, minute = tonumber(date("%H")), tonumber(date("%M"))
	if useStandardTime then 
		local hour, suffix = self:ComputeStandardHours(hour)
		return hour, minute, suffix
	else 
		return hour, minute
	end 
end

-- Retrieve the server time
LibTime.GetServerTime = function(self, useStandardTime)
	local hour, minute = GetGameTime()
	if useStandardTime then 
		local hour, suffix = self:ComputeStandardHours(hour)
		return hour, minute, suffix
	else 
		return hour, minute
	end
end

LibTime.GetTime = function(self, useStandardTime, useServerTime)
	return self[useServerTime and "GetServerTime" or "GetLocalTime"](self, useStandardTime)
end

local embedMethods = {
	GetTime = true, 
	GetLocalTime = true, 
	GetServerTime = true, 
	ComputeMilitaryHours = true, 
	ComputeStandardHours = true
}

LibTime.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTime.embeds) do
	LibTime:Embed(target)
end
