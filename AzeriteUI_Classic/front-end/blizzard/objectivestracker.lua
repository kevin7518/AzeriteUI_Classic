local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardObjectivesTracker", "LibEvent", "LibFrame", "LibClientBuild")
Module:SetIncompatible("!KalielsTracker")

local L, Layout

-- Lua API
local _G = _G
local math_min = math.min

-- WoW API
local hooksecurefunc = _G.hooksecurefunc
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local GetScreenHeight = _G.GetScreenHeight

local IN_COMBAT, IN_BOSS_FIGHT, IN_ARENA

Module.StyleTracker = function(self)
	hooksecurefunc("ObjectiveTracker_Update", function()
		local frame = ObjectiveTrackerFrame.MODULES
		if frame then
			for i = 1, #frame do
				local modules = frame[i]
				if modules then
					local header = modules.Header
					local background = modules.Header.Background
					background:SetAtlas(nil)

					local text = modules.Header.Text
					text:SetParent(header)
				end
			end
		end
	end)
end 

Module.PositionTracker = function(self)
	if (not ObjectiveTrackerFrame) then 
		return self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end 

	local ObjectiveFrameHolder = self:CreateFrame("Frame", nil, "UICenter")
	ObjectiveFrameHolder:SetWidth(Layout.Width)
	ObjectiveFrameHolder:SetHeight(22)
	ObjectiveFrameHolder:Place(unpack(Layout.Place))
	
	ObjectiveTrackerFrame:SetParent(self.frame) -- taint or ok?
	ObjectiveTrackerFrame:ClearAllPoints()
	ObjectiveTrackerFrame:SetPoint("TOP", ObjectiveFrameHolder, "TOP")

	-- Create a dummy frame to cover the tracker  
	-- to block mouse input when it's faded out. 
	local ObjectiveFrameCover = self:CreateFrame("Frame", nil, "UICenter")
	ObjectiveFrameCover:SetParent(ObjectiveFrameHolder)
	ObjectiveFrameCover:SetFrameLevel(ObjectiveTrackerFrame:GetFrameLevel() + 5)
	ObjectiveFrameCover:SetAllPoints()
	ObjectiveFrameCover:EnableMouse(true)
	ObjectiveFrameCover:Hide()

	-- Minihack to fix mouseover fading
	self.frame:ClearAllPoints()
	self.frame:SetAllPoints(ObjectiveTrackerFrame)
	self.frame.holder = ObjectiveFrameHolder
	self.frame.cover = ObjectiveFrameCover

	local top = ObjectiveTrackerFrame:GetTop() or 0
	local screenHeight = GetScreenHeight()
	local maxHeight = screenHeight - (Layout.SpaceBottom + Layout.SpaceTop)
	local objectiveFrameHeight = math_min(maxHeight, Layout.MaxHeight)

	if Layout.Scale then 
		ObjectiveTrackerFrame:SetScale(Layout.Scale)
		ObjectiveTrackerFrame:SetWidth(Layout.Width / Layout.Scale)
		ObjectiveTrackerFrame:SetHeight(objectiveFrameHeight / Layout.Scale)
	else
		ObjectiveTrackerFrame:SetScale(1)
		ObjectiveTrackerFrame:SetWidth(Layout.Width)
		ObjectiveTrackerFrame:SetHeight(objectiveFrameHeight)
	end	

	ObjectiveTrackerFrame:SetClampedToScreen(false)
	ObjectiveTrackerFrame:SetAlpha(.9)

	local ObjectiveTrackerFrame_SetPosition = function(_,_, parent)
		if parent ~= ObjectiveFrameHolder then
			ObjectiveTrackerFrame:ClearAllPoints()
			ObjectiveTrackerFrame:SetPoint("TOP", ObjectiveFrameHolder, "TOP")
		end
	end
	hooksecurefunc(ObjectiveTrackerFrame,"SetPoint", ObjectiveTrackerFrame_SetPosition)

	self:StyleTracker()
end

Module.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then 
		local addon = ...
		if (addon == "Blizzard_ObjectiveTracker") then 
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			self:PositionTracker()
		end 
	end 
end

Module.CreateDriver = function(self)
	if Layout.HideInCombat or Layout.HideInBossFights or Layout.HideInArena then 

		local driverFrame = self:CreateFrame("Frame", nil, _G.UIParent, "SecureHandlerAttributeTemplate")

		driverFrame:HookScript("OnShow", function() 
			if _G.ObjectiveTrackerFrame then 
				_G.ObjectiveTrackerFrame:SetAlpha(.9)
				self.frame.cover:Hide()
				-- This taints. 
				--_G.ObjectiveTracker_Expand()
			end
		end)

		-- DifficultyID: https://wow.gamepedia.com/DifficultyID
		driverFrame:HookScript("OnHide", function() 
			if _G.ObjectiveTrackerFrame then 
				_G.ObjectiveTrackerFrame:SetAlpha(0)
				self.frame.cover:Show()
				-- This taints. 
				--_G.ObjectiveTracker_Collapse()
			end
		end)

		driverFrame:SetAttribute("_onattributechanged", [=[
			if (name == "state-vis") then
				if (value == "show") then 
					if (not self:IsShown()) then 
						self:Show(); 
					end 
				elseif (value == "hide") then 
					if (self:IsShown()) then 
						self:Hide(); 
					end 
				end 
			end
		]=])

		local driver = "hide;show"
		if Layout.HideInArena then 
			driver = "[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists]" .. driver
		end 
		if Layout.HideInBossFights then 
			driver = "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists]" .. driver
		end 
		if Layout.HideInCombat then 
			driver = "[combat]" .. driver
		end 

		RegisterAttributeDriver(driverFrame, "state-vis", driver)
	end 

end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardObjectivesTracker]")
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
end

Module.OnInit = function(self)
	self.frame = self:CreateFrame("Frame", nil, "UICenter")
	self:PositionTracker()
end 

Module.OnEnable = function(self)
	self:CreateDriver()
end
