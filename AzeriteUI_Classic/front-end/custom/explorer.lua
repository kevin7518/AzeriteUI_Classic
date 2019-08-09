local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("ExplorerMode", "PLUGIN", "LibEvent", "LibDB", "LibFader", "LibFrame")

-- Lua API
local _G = _G
local table_insert = table.insert
local unpack = unpack

local defaults = {
	enableExplorer = true,
	enableTrackerFading = false, 

	useFadingInInstance = true, 
	useFadingInvehicles = false
}

local deprecated = {
	enableExplorerInstances = true,
	enablePlayerFading = true,
	enableTrackerFadingInstances = true
}

Module.ParseSavedSettings = function(self)
	local db = self:NewConfig("ExplorerMode", defaults, "global")
	for key,remove in pairs(deprecated) do
		if remove then 
			db[key] = nil
		end 
	end
	return db
end

Module.PostUpdateSettings = function(self)
	local db = self.db
	if db.enableExplorer then 
		self:AttachModuleFrame("ActionBarMain")
		self:AttachModuleFrame("UnitFramePlayer")
		self:AttachModuleFrame("UnitFramePet")
	else 
		self:DetachModuleFrame("ActionBarMain")
		self:DetachModuleFrame("UnitFramePlayer")
		self:DetachModuleFrame("UnitFramePet")
	end 
	if db.enableTrackerFading then 
		self:AttachModuleFrame("BlizzardObjectivesTracker")
	else 
		self:DetachModuleFrame("BlizzardObjectivesTracker")
	end 
end

Module.AttachModuleFrame = function(self, moduleName)
	local module = Core:GetModule(moduleName, true)
	if module and not(module:IsIncompatible() or module:DependencyFailed()) then 
		local frame = module:GetFrame()
		if frame then 
			self:RegisterObjectFade(frame)
		end 
	end 
end 

Module.DetachModuleFrame = function(self, moduleName)
	local module = Core:GetModule(moduleName, true)
	if module and not(module:IsIncompatible() or module:DependencyFailed()) then 
		local frame = module:GetFrame()
		if frame then 
			self:UnregisterObjectFade(frame)
		end 
	end 
end 

Module.OnInit = function(self)
	self.db = self:ParseSavedSettings()

	local proxy = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	proxy.PostUpdateSettings = function() self:PostUpdateSettings() end
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:SetAttribute("_onattributechanged", [=[
		if (not name) then
			return 
		end 

		-- Seems to be some inconsistencies in name returns, 
		-- so we make it lower case to avoid issues. 
		name = string.lower(name); 

		-- Identify what attribute or setting was change
		if (name == "change-enableexplorer") then 
			self:SetAttribute("enableExplorer", value); 
		elseif (name == "change-enabletrackerfading") then 
			self:SetAttribute("enableTrackerFading", value); 
		end 

		-- Run Lua callbacks
		self:CallMethod("PostUpdateSettings"); 
	]=])

	self.proxyUpdater = proxy
end 

Module.OnEnable = function(self)
	self:PostUpdateSettings()
end

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end