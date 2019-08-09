local LibClientBuild = CogWheel:Set("LibClientBuild", 31)
if (not LibClientBuild) then
	return
end

-- Lua API
local _G = _G
local pairs = pairs
local select = select
local string_match = string.match
local tonumber = tonumber
local tostring = tostring

LibClientBuild.embeds = LibClientBuild.embeds or {}

local clientPatch, clientBuild = _G.GetBuildInfo() 
clientBuild = tonumber(clientBuild)

local clientIsAtLeast = {}
local builds = {
	["Classic"] = 31407, 
		["1.13.2"] = 31407, -- August 8th 2019 Pre-Launch build
}
local patchExceptions = {
	["1.13.2"] = "1.13.2" -- Classic!
}

for version, build in pairs(builds) do
	if (clientBuild >= build) then
		clientIsAtLeast[version] = true 
		clientIsAtLeast[build] = true 
		clientIsAtLeast[tostring(build)] = true 
	end
end

-- Return the build number for a given patch.
-- Return current build if the given patch is the current. EXPERIMENTAL! 
LibClientBuild.GetBuildForPatch = function(self, version)
	return (clientPatch == version) and clientBuild or builds[version]
end 

-- Return the current WoW client build
LibClientBuild.GetBuild = function(self)
	return clientBuild
end 

-- Check if the current client is 
-- at least the requested version.
LibClientBuild.IsBuild = function(self, version)
	local patchException = patchExceptions[version]
	if patchException then 
		return (patchException == clientPatch) and clientIsAtLeast[version]
	else 
		return clientIsAtLeast[version]
	end 
end

-- Module embedding
local embedMethods = {
	IsBuild = true,
	GetBuild = true, 
	GetBuildForPatch = true
}

LibClientBuild.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibClientBuild.embeds) do
	LibClientBuild:Embed(target)
end
