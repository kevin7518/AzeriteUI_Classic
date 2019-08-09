local LibQuest = CogWheel:Set("LibQuest", 2)
if (not LibQuest) then	
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

LibQuest.embeds = LibQuest.embeds or {}

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

LibQuest.GetQuestLog = function(self)
end 

-- Module embedding
local embedMethods = {
	GetQuestLog = true
}

LibQuest.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibQuest.embeds) do
	LibQuest:Embed(target)
end
