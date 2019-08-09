local LibClientBuild = CogWheel:Set("LibClientBuild", 29)
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
	["Vanilla"] = 6141,
		["0.5.3"] 	= 3368, 
		["0.5.5"] 	= 3494, 
		["0.6"] 	= 3592, -- Rest state, Inns, Hearthstone, Guilds. Scarlet Monestary + Blackfathom Depths. 
		["0.7"] 	= 3694, -- Level cap 45. PvP. Postal system. Mounts. Gnomeregan + Uldaman. 
		["0.7.1"] 	= 3702, 
		["0.7.2"] 	= 3702, 
		["0.7.3"] 	= 3702, 
		["0.7.5"] 	= 3702, 
		["0.7.6"] 	= 3712, 
		["0.8"] 	= 3734, 
		["0.9"] 	= 3807, 
		["0.9.1"] 	= 3810, 
		["0.10"] 	= 3892, 
		["0.10.1"] 	= 3892, 
		["0.11"] 	= 3925, 
		["0.12"] 	= 3988, 
		["1.1.0"] 	= 4044, 
		["1.1.1"] 	= 4062, 
		["1.1.2"] 	= 4125, 
		["1.2.0"] 	= 4149, -- Maraudon. Cloak & Helm hiding added to interface options. 
		["1.2.1"] 	= 4150, 
		["1.2.2"] 	= 4196, 
		["1.2.3"] 	= 4211, 
		["1.2.4"] 	= 4222, 
		["1.3.0"] 	= 4284, -- Dire Maul. Dungeon Member caps. (Ony/Molten Core 40, BRS 15, DM 5, all others 5)
		["1.3.1"] 	= 4297, 
		["1.3.2"] 	= 4297, 
		["1.4.0"] 	= 4341, -- PvP Honor System. 
		["1.4.1"] 	= 4364, -- Minimum instance level requirements. 
		["1.4.2"] 	= 4375, 
		["1.5.0"] 	= 4442, -- Battlegrounds. 
		["1.5.1"] 	= 4499, 
		["1.6.0"] 	= 4500, -- Blackwing Lair. Darkmoon Faire. Battlemasters.  
		["1.6.1"] 	= 4544, 
		["1.7.0"] 	= 4671, -- Zul'Gurub. Arathi Basin. Stranglethorn Fishing Extravaganza. 
		["1.7.1"] 	= 4695, -- Arathi Basin geometry change to prevent exploits.
		["1.8.0"] 	= 4735, -- Dragons of Nightmare. Silithus revamped. 
		["1.8.1"] 	= 4769, -- Arathi Basin geometry hack fixes.  
		["1.8.2"] 	= 4784, 
		["1.8.3"] 	= 4807, -- Blizzard Launcher.
		["1.8.4"] 	= 4878, 
		["1.9.0"] 	= 4937, -- Ahn'Qiraj.
		["1.9.1"] 	= 4983, 
		["1.9.2"] 	= 4996, 
		["1.9.3"] 	= 5059, 
		["1.9.4"] 	= 5086, 
		["1.10.0"] 	= 5195, -- Weather FX.
		["1.10.1"] 	= 5230, 
		["1.10.2"] 	= 5302, 
		["1.11.0"] 	= 5428, -- Naxxramas.
		["1.11.1"] 	= 5462, 
		["1.11.2"] 	= 5464, 
		["1.12.0"] 	= 5595, 
		["1.12.1"] 	= 5875, 
		["1.12.2"] 	= 6005, 
		["1.12.3"] 	= 6141, 

	["The Burning Crusade"] = 8606, ["TBC"] = 8606, 
		["2.0.1"] 	= 6180, 
		["2.0.3"] 	= 6299, 
		["2.0.4"] 	= 6314,
		["2.0.5"] 	= 6320,
		["2.0.6"] 	= 6337,
		["2.0.7"] 	= 6383,
		["2.0.8"] 	= 6403,
		["2.0.9"] 	= 6403, 
		["2.0.10"] 	= 6448,
		["2.0.11"] 	= 6448, 
		["2.0.12"] 	= 6546,
		["2.1.0"] 	= 6692,
		["2.1.0a"] 	= 6729,
		["2.1.1"] 	= 6739,
		["2.1.2"] 	= 6803,
		["2.1.3"] 	= 6898,
		["2.1.4"] 	= 6898, 
		["2.2.0"] 	= 7272,
		["2.2.2"] 	= 7318,
		["2.2.3"] 	= 7359,
		["2.3.0"] 	= 7561,
		["2.3.2"] 	= 7741,
		["2.3.3"] 	= 7799,
		["2.4.0"] 	= 8089,
		["2.4.1"] 	= 8125,
		["2.4.2"] 	= 8209,
		["2.4.3"] 	= 8606,
	
	["Wrath of the Lich King"] = 12340, ["WotLK"] = 12340, 
		["3.0.2"] 	= 9056,
		["3.0.3"] 	= 9183,
		["3.0.8"] 	= 9464,
		["3.0.8a"] 	= 9506,
		["3.0.9"] 	= 9551,
		["3.1.0"] 	= 9767,
		["3.1.1"] 	= 9806,
		["3.1.1a"] 	= 9835,
		["3.1.2"] 	= 9901,
		["3.1.3"] 	= 9947,
		["3.2.0"] 	= 10192,
		["3.2.0a"] 	= 10314,
		["3.2.2"] 	= 10482,
		["3.2.2a"] 	= 10505,
		["3.3.0"] 	= 10958,
		["3.3.0a"] 	= 11159,
		["3.3.2"] 	= 11403,
		["3.3.3"] 	= 11685,
		["3.3.3a"] 	= 11723,
		["3.3.5"] 	= 12213,
		["3.3.5a"] 	= 12340,

	["Cataclysm"] = 15595, ["Cata"] = 15595,
		["4.0.1"] 	= 13164,
		["4.0.1a"] 	= 13205,
		["4.0.3"] 	= 13287,
		["4.0.3a"] 	= 13329,
		["4.0.6"] 	= 13596,
		["4.0.6a"] 	= 13623,
		["4.1.0"] 	= 13914,
		["4.1.0a"] 	= 14007,
		["4.2.0"] 	= 14333,
		["4.2.0a"] 	= 14480,
		["4.2.2"] 	= 14545,
		["4.3.0"] 	= 15005,
		["4.3.0a"] 	= 15050,
		["4.3.2"] 	= 15211,
		["4.3.3"] 	= 15354,
		["4.3.4"] 	= 15595,

	["Mists of Pandaria"] = 18414, ["MoP"] = 18414,
		["5.0.4"] 	= 16016,
		["5.0.5"] 	= 16048,
		["5.0.5a"] 	= 16057,
		["5.0.5b"] 	= 16135,
		["5.1.0"] 	= 16309,
		["5.1.0a"] 	= 16357,
		["5.2.0"] 	= 16650, -- 16826
		["5.3.0"] 	= 17128,
		["5.4.0"] 	= 17399,
		["5.4.1"] 	= 17538,
		["5.4.2"] 	= 17688,
		["5.4.7"] 	= 18019,
		["5.4.8"] 	= 18414,

	["Warlords of Draenor"] = 20779, ["WoD"] = 20779, 
		["6.0.2"] 	= 19034,
		["6.0.3"] 	= 19243,
		["6.0.3a"] 	= 19243, 
		["6.0.3b"] 	= 19342, 
		["6.1.0"] 	= 19702,
		["6.1.2"] 	= 19865,
		["6.2.0"] 	= 20173,
		["6.2.0a"] 	= 20338,
		["6.2.2"] 	= 20444,
		["6.2.2a"] 	= 20574,
		["6.2.3"] 	= 20779,
		["6.2.3a"] 	= 20886,
		["6.2.4"] 	= 21345,
		["6.2.4a"] 	= 21463,
		["6.2.4a"] 	= 21463,
		["6.2.4a"] 	= 21463,
		["6.2.4a"] 	= 21742,
			
	["Legion"] = 23420, -- using 7.1.5 as reference here
		["7.0.3"] 	= 22810, -- 22248
		["7.1.0"] 	= 23222, -- 22900
		["7.1.5"] 	= 23420, -- 23360
		["7.2.0"] 	= 24015, -- 23835
		["7.2.5"] 	= 24742, -- 24330
		["7.3.0"] 	= 25195, -- 24920
		["7.3.2"] 	= 25549, -- 25326
		["7.3.5"] 	= 25860, -- latest: 26972

	["Battle for Azeroth"] = 27101, ["BfA"] = 27101, 
		["8.0.1"] 	= 27101, 
		["8.1.0"] 	= 29600, 
		["8.1.5"] 	= 29704, 
		["8.2.0"] 	= 30920, 
		["8.2.0"] 	= 31229, 

	["Classic"] = 31407, 
		["1.13.2"] = 31407, -- August 8th 2019 Pre-Launch build
}

-- This should only be required when a PTR patch's build 
-- is lower than the lower retail patch's build!
-- 
-- The [key] is the name we query it by, what we call it, 
-- while the "value" is what GetBuildInfo() would return. 
-- 
-- Examples: 
-- ["BfA"] = "8.0.1", 
-- ["8.0.1"] = "8.0.1"
local patchExceptions = {
	["8.1.0"] = "8.1.0",
	["8.1.5"] = "8.1.5",
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

-- Check if the current client is a Classic client
LibClientBuild.IsClassic = function(self, version)
	-- First check if this is a classic patch at all.
	-- This is needed since the classic build numbers 
	-- are slightly behind the retail builds. 
	if (not string_match(clientPatch, "1\.13\.(%d+)")) then 
		return false
	end

	-- If a specific build version was requested, 
	-- make sure we're at that version or higher.
	if version then 
		local patchException = patchExceptions[version]
		if patchException then 
			return (patchException == clientPatch) and clientIsAtLeast[version]
		else 
			return clientIsAtLeast[version]
		end
	end 

	-- If this was just a generic Classic check,
	-- tell the module we're good to go!
	return true
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
