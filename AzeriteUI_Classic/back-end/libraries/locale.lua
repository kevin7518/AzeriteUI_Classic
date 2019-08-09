local LibLocale = CogWheel:Set("LibLocale", 5)
if (not LibLocale) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local rawget = rawget
local rawset = rawset
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_match = string.match
local type = type

-- Get or create our registry
LibLocale.modules = LibLocale.modules or {}
LibLocale.embeds = LibLocale.embeds or {}

-- Get the current game client locale.
-- We're treating enGB on old clients as enUS, as it's the same in-game anyway.
local gameLocale = GetLocale()
if (gameLocale == "enGB") then
	gameLocale = "enUS"
end

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

-- Metatable used to read locales
-- 	Does not error on unset values, it simply sets them to the key and returns it.
-- 	Note that this does debugging close to impossible, so make REALLY sure 
-- 	that you properly define all entries you're going to use in at least 
-- 	the default locale definition. 
local read = {
	__index = function(tbl, key)
		local defaultValue 
		local defaultLocale = rawget(tbl, "_owner")._defaultLocale
		if defaultLocale then 
			defaultValue = rawget(LibLocale.modules[module][defaultLocale], key)
		end 
		rawset(tbl, key, defaultValue or key)

		local LibModule = CogWheel("LibModule")
		if LibModule and LibModule.AddDebugMessage then 

			local name = "XXX"
			for module,moduleTbl in pairs(LibLocale.modules) do 
				if (moduleTbl == tbl) then 
					name = module 
					break 
					--(getmetatable(moduleTbl) == read) and moduleTbl or setmetatable(LibLocale.modules[module], read)
				end
			end 
			LibModule:AddDebugMessageFormatted(("The locale '%s' is missing an entry for the key '%s'."):format(name, key))
		end

		return key
	end
}

-- Metatable used to write the default locale
-- 	This doesn't overwrite existing values. 
-- 	The point of this is to allow locales to be written in any order. 
-- 	Say that a zhCN locale is written first, we're on a zhCN client, 
-- 	but enUS is registered later on as the default locale. 
-- 	In this scenario we only want to fill in the holes in the locale table with
-- 	entries from the default enUS locale to be used as fallbacks for missing zhCN entries, 
-- 	while keeping all the existing zhCN entries intact.
local writeDefault = {
	__newindex = function(tbl, key, value)
		if (not rawget(tbl, key)) then
			rawset(tbl, key, (value == true) and key or value)
		end
	end,
	__index = function() end
}

-- Metatable used to write all other locales
-- 	This will overwrite existing values.
--	Since only the gamelocale and default locale is ever written, 
-- 	and the default locale will never overwrite existing entries, 
-- 	this metatable can safely overwrite existing entries.
local write = {
	__newindex = function(tbl, key, value)
		if (value == true) then 
			return 
		end 
		rawset(tbl, key, (value == true) and key or value)
	end,
	__index = function() end
}

-- Create a new locale
-- 	This also sets the metatable to the write or writeDefault table, 
-- 	so it is important that you don't attempt to register multiple 
-- 	locales for the same module at once, as this will fail epicly.
-- 	Also note that you HAVE to register a default locale for your module, 
-- 	or the whole system will go into meltdown and cause weird and unexpected problems.
LibLocale.NewLocale = function(self, module, locale, isDefault)
	check(module, 1, "string")
	check(locale, 2, "string")
	check(isDefault, 3, "boolean", "nil")

	-- Allow the usage of the GAME_LOCALE global 
	-- to test other locales than the client locale.
	local gameLocale = GAME_LOCALE or gameLocale
	if (locale ~= gameLocale) and (not isDefault) then
		return 
	end

	-- Retrieve or create the module locale table
	if (not LibLocale.modules[module]) then
		LibLocale.modules[module] = {}
	end
	local tbl = LibLocale.modules[module][locale]
	if (not tbl) then 
		tbl = { _owner = module, _locale = locale }
		LibLocale.modules[module][locale] = tbl
		LibLocale.modules[module]._defaultLocale = isDefault and locale or nil
	end 

	-- Return the module locale table with the correct metatable attached
	if isDefault then 
		return setmetatable(tbl, writeDefault)
	else 
		return setmetatable(tbl, write)
	end 
end

-- Get the current locale for your module
-- This also sets the metatable to the read table if not already done, 
-- so this shouldn't be called until after all the locales are registered. 
-- This function will silently fail and return nil if no locale is registered to the module. 
LibLocale.GetLocale = function(self, module)
	check(module, 1, "string")

	local tbl = LibLocale.modules[module][GAME_LOCALE or gameLocale]
	if tbl then
		return (getmetatable(tbl) == read) and tbl or setmetatable(tbl, read)
	end
end

-- Module embedding
local embedMethods = {
	NewLocale = true,
	GetLocale = true
}

LibLocale.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibLocale.embeds) do
	LibLocale:Embed(target)
end
