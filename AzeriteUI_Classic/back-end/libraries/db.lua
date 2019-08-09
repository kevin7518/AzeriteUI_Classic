local LibDB = CogWheel:Set("LibDB", 14)
if (not LibDB) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibEvent requires LibDB to be loaded.")

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

-- WoW API
local GetRealmName = _G.GetRealmName
local UnitFactionGroup = _G.UnitFactionGroup
local UnitName = _G.UnitName

-- Get or create our registries
LibDB.databases = LibDB.databases or {}
LibDB.configs = LibDB.configs or {} 
LibDB.globals = LibDB.globals or {} 
LibDB.embeds = LibDB.embeds or {}
LibDB.frame = LibDB.frame or CreateFrame("Frame")

-- Speed up things a bit more
local databases = LibDB.databases
local configs = LibDB.configs
local globals = LibDB.globals
local addons = LibDB.addons
local frame = LibDB.frame

-- Assign a smart metatable to the config table
-- Note: do NOT iterate over this table, it'll add nil entries! 
setmetatable(configs, { __index = function(tbl,key) tbl[key] = {} return tbl[key] end })

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

-- Deep copy a table into a new table 
-- or into the optional target.
local copyTable
copyTable = function(source, target)
	local new = target or {}
	for i,v in pairs(source) do
		if (type(v) == "table") then
			if (new[i] and (type(new[i]) == "table")) then
				new[i] = copyTable(source[i], new[i]) 
			else
				new[i] = copyTable(source[i])
			end
		else
			new[i] = source[i]
		end
	end
	return new
end

LibDB.ParseSavedVariables = function(self)

	-- The name of the global variable containing saved settings
	local globalName = globals[tostring(self:GetOwner())] -- tostring(self)

	-- THe actual global table
	globalDB = _G[globalName]
	if (not globalDB) then
		return error(("LibDB: The global table '%s' doesn't exist. Did you forget to register it with RegisterSavedVariablesGlobal in the top level module first?"):format(globalName))
	end	

	-- Our local cache for the current addon object
	-- Will be created on demand if it doesn't exist
	local configDB = configs[tostring(self:GetOwner())]

	-- Merge and/or overwrite current configs with stored settings.
	-- *doesn't matter that we mess up any links by replacing the tables, 
	--  because this all happens before any module's OnInit or OnEnable,
	--  meaning if the modules do it right, they haven't fetched their config or db yet.
	for name,data in pairs(globalDB) do

		if data.profiles and configDB[name] and configDB[name].profiles then
			local profiles = data.profiles -- speeeed!

			-- add stored realm dbs to our db
			if profiles.realm then
				for realm,realmdata in pairs(profiles.realm) do
					configDB[name].profiles.realm[realm] = copyTable(profiles.realm[realm], configDB[name].profiles.realm[realm])
				end
			end

			-- add stored faction dbs to our db
			if profiles.faction then
				for faction,factiondata in pairs(profiles.faction) do
					configDB[name].profiles.faction[faction] = copyTable(profiles.faction[faction], configDB[name].profiles.faction[faction])
				end
			end

			-- add stored character dbs to our db
			if profiles.character then
				for char,chardata in pairs(profiles.character) do
					configDB[name].profiles.character[char] = copyTable(profiles.character[char], configDB[name].profiles.character[char])
				end
			end

			-- global config
			if profiles.global then
				configDB[name].profiles.global = copyTable(profiles.global, configDB[name].profiles.global)
			end
		end
	end	
	
	-- Point the saved variables back to our configs.
	-- *This isn't redundant, because there can be new configs here 
	--  that hasn't previously been saved either because of me adding a new module, 
	--	or because it's the first time running the addon.
	for name,data in pairs(configDB) do
		globalDB[name] = { profiles = configDB[name].profiles }
	end
end

-- All new configs are registered as direct descendants of the top level module
-- We're using pure strings as table keys since these will be copied to the 
-- saved variables stored in text files on disk by blizzard. 
LibDB.NewConfig = function(self, name, config, returnProfile)
	check(name, 1, "string")
	check(config, 2, "table")

	local configDB = configs[tostring(self:GetOwner())]
	if configDB[name] then
		return error(("The config '%s' already exists!"):format(name))
	end	
	
	local faction = UnitFactionGroup("player")
	local realm = GetRealmName() 
	local character = UnitName("player")	

	configDB[name] = {
		defaults = copyTable(config),
		profiles = {
			realm = { [realm] = copyTable(config) },
			faction = { [faction] = copyTable(config) },
			character = { [character.."-"..realm] = copyTable(config) }, -- we need the realm name here to avoid duplicates
			global = copyTable(config)
		}
	}

	-- Need to sync this up against the global saved variables, 
	-- or the settings won't store.
	self:ParseSavedVariables()

	return self:GetConfig(name, returnProfile)
end

-- If the 'profile' argument is left out, the 'global' profile will be returned
-- The 'option' argument allows the module to retrieve options 
-- for specific realms, characters or faction.
-- Remember that the realm name is a part of the character profile name!
LibDB.GetConfig = function(self, name, profile, option, silent)
	check(name, 1, "string")
	check(profile, 2, "string", "nil")
	check(option, 3, "string", "nil")
	check(silent, 4, "boolean", "nil")

	local configDB = configs[tostring(self:GetOwner())]
	if (not configDB[name]) then
		if (silent) then 
			return 
		else
			return error(("The config '%s' doesn't exist!"):format(name))
		end
	end	
	local config
	if (profile == "realm") then
		config = configDB[name].profiles.realm[option or (GetRealmName())]
		
	elseif (profile == "character") then
		config = configDB[name].profiles.character[option or (UnitName("player").."-"..GetRealmName())]
		
	elseif (profile == "faction") then
		config = configDB[name].profiles.faction[option or (UnitFactionGroup("player"))]
		
	elseif (profile == "global") or (not profile) then
		config = configDB[name].profiles.global
	end
	if (not config) then
		return error(("The config '%s' doesn't have a profile named '%s'!"):format(name, profile))
	end
	return config
end

LibDB.GetConfigDefaults = function(self, name)
	check(name, 1, "string")
	local configDB = configs[tostring(self:GetOwner())]
	if (not configDB[name]) then
		return error(("The config '%s' doesn't exist!"):format(name))
	end	
	return configDB[name].defaults
end

LibDB.GetDatabase = function(self, name, silent)
	check(name, 1, "string")
	if (not databases[name]) then
		if (not silent) then 
			return error(("The static config '%s' doesn't exist!"):format(name))
		end 
	end	
	return databases[name]
end

LibDB.NewDatabase = function(self, name, config)
	check(name, 1, "string")
	check(config, 2, "table", "nil")
	if (databases[name]) then
		return error(("The static config '%s' already exists!"):format(name))
	end	
	databases[name] = config or {}
	return databases[name]
end


-- This must be called before any configs are created, 
-- or LibDB won't know what table to parse, retrieve from or save too.
LibDB.RegisterSavedVariablesGlobal = function(self, globalName)
	check(globalName, 1, "string")

	-- We don't want this to be done several times
	if self:GetParent() then
		return error("LibDB: You cannot call RegisterSavedVariablesGlobal on anything but the top level module.")
	end

	-- Add the name of the new global to our registry
	-- Note that several modules and addons can point to the same global.
	globals[tostring(self)] = globalName

	-- Create the global variable itself
	_G[globalName] = {}

	-- Parse saved variables and set up profiles for char, realm etc 
	return self:ParseSavedVariables()
end

-- Module embedding
local embedMethods = {
	RegisterSavedVariablesGlobal = true,
	ParseSavedVariables = true, 
	NewConfig = true,
	GetConfig = true,
	GetConfigDefaults = true,
	NewDatabase = true,
	GetDatabase = true
}

-- Since this can only be called by top level modules, 
-- there's no reason including it in any other.
local onlyOnOwner = {
	RegisterSavedVariablesGlobal = true,
	ParseSavedVariables = true
}

LibDB.Embed = function(self, target)
	for method in pairs(embedMethods) do
		if (not onlyOnOwner[method]) or (not target:GetParent()) then
			target[method] = self[method]
		end
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibDB.embeds) do
	LibDB:Embed(target)
end
