
-- Lua API
local _G = _G

-- WoW API
local GetLootMethod = _G.GetLootMethod
local GetPartyAssignment = _G.GetPartyAssignment
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitInParty = _G.UnitInParty
local UnitInRaid = _G.UnitInRaid
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local UnitIsUnit = _G.UnitIsUnit

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.RaidRole
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local role
	local index = GetRaidTargetIndex(unit)
	if index then 
		role = "RAIDTARGET"
	elseif (UnitInParty(unit) or UnitInRaid(unit)) then 
		if (UnitIsGroupLeader(unit)) then 
			role = "LEADER"
		elseif (UnitIsGroupAssistant(unit)) then 
			role = "ASSISTANT"
		else 
			local method, pid, rid = GetLootMethod()
			if (method == "master") then
				local mlUnit
				if (pid) then
					if (pid == 0) then
						mlUnit = "player"
					else
						mlUnit = "party"..pid
					end
				elseif (rid) then
					mlUnit = "raid"..rid
				end
				if (UnitIsUnit(unit, mlUnit)) then
					role = "MASTERLOOTER"
				end
			end
			if (not role) and (UnitInRaid(unit) and (not UnitHasVehicleUI(unit))) then
				if (GetPartyAssignment("MAINTANK", unit)) then
					role = "MAINTANK"
				elseif (GetPartyAssignment("MAINASSIST", unit)) then
					role = "MAINASSIST"
				end
			end
		end 
	end

	element.role = role 

	local roleTexture = role and element.roleTextures[role]
	if roleTexture then 
		element:SetTexture(roleTexture)
		if (role == "RAIDTARGET") then 
			SetRaidTargetIconTexture(element, index)
		else 
			element:SetTexCoord(0, 1, 0, 1)
		end 
		element:Show()
	else 
		element:SetTexture(nil)
		element:Hide()
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit, role)
	end 
end 

local Proxy = function(self, ...)
	return (self.RaidRole.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.RaidRole
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		element.roleTextures = element.roleTextures or {}
		element.roleTextures.LEADER = element.roleTextures.LEADER or [[Interface\GroupFrame\UI-Group-LeaderIcon]]
		element.roleTextures.ASSISTANT = element.roleTextures.ASSISTANT or [[Interface\GroupFrame\UI-Group-AssistantIcon]]
		element.roleTextures.MASTERLOOTER = element.roleTextures.MASTERLOOTER or [[Interface\GroupFrame\UI-Group-MasterLooter]]
		element.roleTextures.MAINTANK = element.roleTextures.MAINTANK or [[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]]
		element.roleTextures.MAINASSIST = element.roleTextures.MAINASSIST or [[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]]
		element.roleTextures.RAIDTARGET = element.roleTextures.RAIDTARGET or [[Interface\TargetingFrame\UI-RaidTargetingIcons]]

		self:RegisterEvent("PARTY_LEADER_CHANGED", Proxy, true)
		self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", Proxy, true)
		self:RegisterEvent("RAID_TARGET_UPDATE", Proxy, true)

		-- Avoid duplicate events, library fires this for all elements on raid/party
		if (not self.unit:match("^party(%d+)")) and (not self.unit:match("^raid(%d+)")) then 
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Proxy, true)
		end 


		return true
	end
end 

local Disable = function(self)
	local element = self.RaidRole
	if element then
		self:UnregisterEvent("PARTY_LEADER_CHANGED", Proxy)
		self:UnregisterEvent("PARTY_LOOT_METHOD_CHANGED", Proxy)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Proxy)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("RaidRole", Enable, Disable, Proxy, 8)
end 
