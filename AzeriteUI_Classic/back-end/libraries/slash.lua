local LibSlash = CogWheel:Set("LibSlash", 7)
if (not LibSlash) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_gsub = string.gsub
local string_join = string.join
local string_lower = string.lower
local string_match = string.match
local string_upper = string.upper
local string_split = string.split
local type = type

-- WoW Objects
local SlashCmdList = _G.SlashCmdList

LibSlash.embeds = LibSlash.embeds or {}
LibSlash.commands = LibSlash.commands or {}

-- Speed shortcuts
local Commands = LibSlash.commands

-- Shortcuts to ReloadUI
-- *We don't check for existence here, 
--  since these commands should only ever have this usage.
_G.SLASH_RELOADUI1 = "/rl"
_G.SLASH_RELOADUI2 = "/reload"
_G.SLASH_RELOADUI3 = "/reloadui"
_G.SlashCmdList.RELOADUI = _G.ReloadUI

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

local parseArguments = function(msg)
	-- Remove spaces at the start and end
	msg = string_gsub(msg, "^%s+", "")
	msg = string_gsub(msg, "%s+$", "")

	-- Replace all space characters with single spaces
	msg = string_gsub(msg, "%s+", " ") 

	-- If multiple arguments exist, split them into separate return values
	if string_find(msg, "%s") then
		return string_split(" ", msg) 
	else
		return msg
	end
end 

LibSlash.RegisterChatCommand = function(self, command, func, forced)
	check(command, 1, "string")
	check(func, 2, "function", "string")
	check(forced, 3, "boolean", "nil")

	-- Just make it lowercase, avoid mixups.
	command = string_lower(command)

	-- Just silently fail if the command exists.
	-- The nil return value will tell the module it failed.
	if Commands[command] and (not forced) then 
		return 
	end 
	
	-- Create a unique name for the command
	local name = "CG_CHATCOMMAND_"..string_upper(command) 

	-- Register the chat command, keep it lowercase
	_G["SLASH_"..name.."1"] = "/"..string_lower(command)

	-- Register the function called by the command 
	if (type(func) == "function") then 
		SlashCmdList[name] = function(msg, editBox)
			func(editBox, parseArguments(msg))
		end 
	else 
		local module = self -- overdoing the locals?
		SlashCmdList[name] = function(msg, editBox)
			-- Make the arguments lower case, we don't want case sensitivity here. 
			module[func](module, editBox, parseArguments(string_lower(msg)))
		end 
	end 

	-- Store it for future upgrades or unregistering.
	Commands[command] = func

	-- Return true to indicate a new command was successfully registered
	return true
end

LibSlash.UnregisterChatCommand = function(self, command)
	check(command, 1, "string")

	-- Just make it lowercase, avoid mixups.
	command = string_lower(command)

	-- Just silently fail if the command doesn't exist.
	-- The nil return value will tell the module it failed.
	if (not Commands[command]) then 
		return 
	end 

	-- Generate the name as it was stored
	-- *Future library versions must either follow this format,
	--  or take this older version into account when upgrading. 
	local name = "CG_CHATCOMMAND_"..string_upper(command) 

	-- Kill the slash command
	_G["SLASH_"..name.."1"] = nil

	-- Kill the slash handler
	SlashCmdList[name] = nil

	-- Kill the database entry
	Commands[command] = nil

	return true
end

-- Module embedding
local embedMethods = {
	RegisterChatCommand = true,
	UnregisterChatCommand = true
}

LibSlash.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibSlash.embeds) do
	LibSlash:Embed(target)
end

-- Upgrade existing commands to use our current handler
for command,func in pairs(Commands) do
	-- Re-generate the name
	-- *if we change the format of the name, 
	--  we must take older formats into account.
	local name = "CG_CHATCOMMAND_"..string_upper(command) 

	-- Update registered functions to use our current argument parsing.
	if (type(func) == "function") then 
		SlashCmdList[name] = function(msg, editBox)
			func(editBox, parseArguments(msg))
		end 
	else 
		local module = self -- overdoing the locals?
		SlashCmdList[name] = function(msg, editBox)
			module[func](module, editBox, parseArguments(msg))
		end 
	end 
end

