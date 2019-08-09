
-- until we can fix map stuff
do 
	return 
end 

-- Lua API
local _G = _G
local string_format = string.format

-- WoW API
local GetCurrentMapAreaID = _G.GetCurrentMapAreaID
local GetDifficultyInfo = _G.GetDifficultyInfo
local GetMinimapZoneText = _G.GetMinimapZoneText
local GetInstanceInfo = _G.GetInstanceInfo
local GetSubZoneText = _G.GetSubZoneText
local GetZonePVPInfo = _G.GetZonePVPInfo
local GetZoneText = _G.GetZoneText
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsInRaid = _G.IsInRaid
local SetMapToCurrentZone = _G.SetMapToCurrentZone

-- WoW Frames
local WorldMapFrame = _G.WorldMapFrame


local Update = function(self, event, unit)
	if (event == "PLAYER_ENTERING_WORLD") or (event == "ZONE_CHANGED_INDOORS") or (event == "ZONE_CHANGED_NEW_AREA") or (event == "WORLD_MAP_CLOSED") then
		-- Don't force this anymore, we don't want to mess with the WorldMap, 
		-- as zone changing when looking at things when taking a taxi is super annoying. 
		-- We're queueing all updates until the world map is closed now, like with the tracker.
		if (not WorldMapFrame:IsShown()) then
			SetMapToCurrentZone() 
		end
	end
	local element = self.Difficulty
	if element.PreUpdate then
		element:PreUpdate()
	end


	local mapID, isContinent = GetCurrentMapAreaID()
	local minimapZoneName = GetMinimapZoneText()
	local pvpType, isSubZonePvP, factionName = GetZonePVPInfo()
	local zoneName = GetZoneText()
	local subzoneName = GetSubZoneText()
	local instance = IsInInstance()

	if (subzoneName == zoneName) then 
		subzoneName = "" 
	end

	-- This won't be available directly at first login
	local territory
	if pvpType == "sanctuary" then
		territory = SANCTUARY_TERRITORY
	elseif pvpType == "arena" then
		territory = FREE_FOR_ALL_TERRITORY
	elseif pvpType == "friendly" then
		territory = string_format(FACTION_CONTROLLED_TERRITORY, factionName)
	elseif pvpType == "hostile" then
		territory = string_format(FACTION_CONTROLLED_TERRITORY, factionName)
	elseif pvpType == "contested" then
		territory = CONTESTED_TERRITORY
	elseif pvpType == "combat" then
		territory = COMBAT_ZONE
	end

	if instance then
		local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
		local _, groupType, isHeroic, isChallengeMode, toggleDifficultyID = GetDifficultyInfo(difficultyID)
		
		local maxMembers, instanceDescription
		if instanceType == "party" then
			if difficultyID == 2 then 
				instanceDescription = DUNGEON_DIFFICULTY2
			else
				instanceDescription = DUNGEON_DIFFICULTY1
			end
			maxMembers = 5
		elseif instanceType == "raid" then
			-- 10 player raids
			if difficultyID == 3 then 
				instanceDescription = RAID_DIFFICULTY1
				maxMembers = 10

			-- 25 player raids
			elseif difficultyID == 4 then 
				instanceDescription = RAID_DIFFICULTY2
				maxMembers = 25

			-- 10 player heoric
			elseif difficultyID == 5 then 
				instanceDescription = RAID_DIFFICULTY3
				maxMembers = 10

			-- 25 player heroic
			elseif difficultyID == 6 then 
				instanceDescription = RAID_DIFFICULTY4
				maxMembers = 25

			-- Legacy LFR (prior to Siege of Orgrimmar)
			elseif difficultyID == 7 then 
				instanceDescription = RAID 
				maxMembers = 25
			
			-- 40 player raids
			elseif difficultyID == 9 then 
				instanceDescription = RAID_DIFFICULTY_40PLAYER
				maxMembers = 40
			
			-- normal raid (WoD)
			elseif difficultyID == 14 then 

			-- heroic raid (WoD)
			elseif difficultyID == 15 then 

			-- mythic raid  (WoD)
			elseif difficultyID == 16 then 

			-- LFR 
			elseif difficultyID == 17 then 
				instanceDescription = RAID 
				maxMembers = 40
			end
		elseif instanceType == "scenario" then
		elseif instanceType == "arena" then
		elseif instanceType == "pvp" then
			instanceDescription = PVP
		else 
			-- "none" -- This shouldn't happen, ever.
		end
		if (IsInRaid() or IsInGroup()) then
			self.data.difficulty = instanceDescription or difficultyName
		else
			local where = instanceDescription or difficultyName
			if where and where ~= "" then
				self.data.difficulty = "(" .. SOLO .. ") " .. where
			else
				-- I'll be surprised if this ever occurs. 
				self.data.difficulty = SOLO
			end
		end
		self.data.instanceName = name or minimapZoneName or ""
	else
		-- make sure it doesn't bug out at login from unavailable data 
		if (territory and territory ~= "") then
			if IsInRaid() then
				self.data.difficulty = RAID .. " " .. territory 
			elseif IsInGroup() then
				self.data.difficulty = PARTY .. " " .. territory 
			else 
				self.data.difficulty = SOLO .. " " .. territory 
			end
		else
			if IsInRaid() then
				self.data.difficulty = RAID 
			elseif IsInGroup() then
				self.data.difficulty = PARTY 
			else 
				self.data.difficulty = SOLO
			end
		end
		self.data.instanceName = ""
	end



	if element.PostUpdate then 
		return element:PostUpdate()
	end 
end 

local Proxy = function(self, ...)
	return (self.Difficulty.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Difficulty
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue

		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		self:RegisterEvent("ZONE_CHANGED_INDOORS", Proxy)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", Proxy)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)

		return true
	end
end 

local Disable = function(self)
	local element = self.Difficulty
	if element then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		self:UnregisterEvent("ZONE_CHANGED", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_INDOORS", Proxy)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Difficulty", Enable, Disable, Proxy, 3)
end 
