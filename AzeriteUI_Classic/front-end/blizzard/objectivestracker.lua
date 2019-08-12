local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardObjectivesTracker", "LibEvent", "LibFrame")
Module:SetIncompatible("!KalielsTracker")

local L, Layout

-- Lua API
local _G = _G
local math_min = math.min

-- WoW API
local hooksecurefunc = _G.hooksecurefunc
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local GetScreenHeight = _G.GetScreenHeight

Module.StyleTracker = function(self)
	local scaffold = self:CreateFrame("Frame", nil, "UICenter")
	scaffold:SetWidth(Layout.Width)
	scaffold:SetHeight(22)
	scaffold:Place(unpack(Layout.Place))
	
	QuestWatchFrame:SetParent(self.frame)
	QuestWatchFrame:ClearAllPoints()
	QuestWatchFrame:SetPoint("BOTTOMRIGHT", scaffold, "BOTTOMRIGHT")

	-- Create a dummy frame to cover the tracker  
	-- to block mouse input when it's faded out. 
	local mouseKiller = self:CreateFrame("Frame", nil, "UICenter")
	mouseKiller:SetParent(scaffold)
	mouseKiller:SetFrameLevel(QuestWatchFrame:GetFrameLevel() + 5)
	mouseKiller:SetAllPoints()
	mouseKiller:EnableMouse(true)
	mouseKiller:Hide()

	-- Minihack to fix mouseover fading
	self.frame:ClearAllPoints()
	self.frame:SetAllPoints(QuestWatchFrame)
	self.frame.holder = scaffold
	self.frame.cover = mouseKiller

	local top = QuestWatchFrame:GetTop() or 0
	local bottom = QuestWatchFrame:GetBottom() or 0
	local screenHeight = GetScreenHeight()
	local maxHeight = screenHeight - (Layout.SpaceBottom + Layout.SpaceTop)
	local objectiveFrameHeight = math_min(maxHeight, Layout.MaxHeight)

	if Layout.Scale then 
		QuestWatchFrame:SetScale(Layout.Scale)
		QuestWatchFrame:SetWidth(Layout.Width / Layout.Scale)
		QuestWatchFrame:SetHeight(objectiveFrameHeight / Layout.Scale)
	else
		QuestWatchFrame:SetScale(1)
		QuestWatchFrame:SetWidth(Layout.Width)
		QuestWatchFrame:SetHeight(objectiveFrameHeight)
	end	

	QuestWatchFrame:SetClampedToScreen(false)
	QuestWatchFrame:SetAlpha(.9)

	local QuestWatchFrame_SetPosition = function(_,_, parent)
		if (parent ~= scaffold) then
			QuestWatchFrame:ClearAllPoints()
			QuestWatchFrame:SetPoint("BOTTOMRIGHT", scaffold, "BOTTOMRIGHT")
		end
	end
	hooksecurefunc(QuestWatchFrame,"SetPoint", QuestWatchFrame_SetPosition)

	local dummyLine = QuestWatchFrame:CreateFontString()
	dummyLine:SetFontObject(Layout.FontObject)
	dummyLine:SetWidth(Layout.Width)
	dummyLine:SetJustifyH("RIGHT")
	dummyLine:SetJustifyV("BOTTOM") 
	dummyLine:SetIndentedWordWrap(false)
	dummyLine:SetWordWrap(true)
	dummyLine:SetNonSpaceWrap(false)
	dummyLine:SetSpacing(0)

	QuestWatchQuestName:ClearAllPoints()
	QuestWatchQuestName:SetPoint("TOPRIGHT", QuestWatchFrame, "TOPRIGHT", 0, 0)

	-- Hook line styling
	hooksecurefunc("QuestWatch_Update", function() 
		local Colors = Layout.Colors

		local questIndex
		local numObjectives
		local watchText
		local watchTextIndex = 1
		local objectivesCompleted
		local text, type, finished

		for i = 1, GetNumQuestWatches() do
			questIndex = GetQuestIndexForWatch(i)
			if (questIndex) then
				numObjectives = GetNumQuestLeaderBoards(questIndex)
				if (numObjectives > 0) then

					watchText = _G["QuestWatchLine"..watchTextIndex]
					watchText.isTitle = true

					-- Kill trailing nonsense
					text = watchText:GetText() or ""
					text = string.gsub(text, "%.$", "") 
					text = string.gsub(text, "%?$", "") 
					text = string.gsub(text, "%!$", "") 
					watchText:SetText(text)
					
					-- Align the quest title better
					if (watchTextIndex == 1) then
						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", QuestWatchQuestName, "TOPRIGHT", 0, -4)
					else
						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", _G["QuestWatchLine"..(watchTextIndex - 1)], "BOTTOMRIGHT", 0, -10)
					end
					watchTextIndex = watchTextIndex + 1

					-- Style the objectives
					objectivesCompleted = 0
					for j = 1, numObjectives do
						text, type, finished = GetQuestLogLeaderBoard(j, questIndex)
						watchText = _G["QuestWatchLine"..watchTextIndex]
						watchText.isTitle = nil

						-- Kill trailing nonsense
						text = string.gsub(text, "%.$", "") 
						text = string.gsub(text, "%?$", "") 
						text = string.gsub(text, "%!$", "") 

						local objectiveText, minCount, maxCount = string.match(text, "(.+): (%d+)/(%d+)")
						if (objectiveText and minCount and maxCount) then 
							minCount = tonumber(minCount)
							maxCount = tonumber(maxCount)
							if (minCount and maxCount) then 
								if (minCount == maxCount) then 
									text = Colors.quest.green.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								elseif (maxCount > 0) and (minCount/maxCount >= 2/3 ) then 
									text = Colors.quest.yellow.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								elseif (maxCount > 0) and (minCount/maxCount >= 1/3 ) then 
									text = Colors.quest.orange.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								else 
									text = Colors.quest.red.colorCode .. minCount .. "/" .. maxCount .. "|r " .. objectiveText
								end 
							end 
						end 
						watchText:SetText(text)

						-- Color the objectives
						if (finished) then
							watchText:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3])
							objectivesCompleted = objectivesCompleted + 1
						else
							watchText:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
						end

						watchText:ClearAllPoints()
						watchText:SetPoint("TOPRIGHT", "QuestWatchLine"..(watchTextIndex - 1), "BOTTOMRIGHT", 0, -4)

						--watchText:Show()

						watchTextIndex = watchTextIndex + 1
					end

					-- Brighten the quest title if all the quest objectives were met
					watchText = _G["QuestWatchLine"..(watchTextIndex - numObjectives - 1)]
					if ( objectivesCompleted == numObjectives ) then
						watchText:SetTextColor(Colors.title[1], Colors.title[2], Colors.title[3])
					else
						watchText:SetTextColor(Colors.title[1]*.75, Colors.title[2]*.75, Colors.title[3]*.75)
					end

				end 
			end 
		end 

		local top, bottom

		local lineID = 1
		local line = _G["QuestWatchLine"..lineID]
		top = line:GetTop()

		while line do 
			if (line:IsShown()) then 
				line:SetShadowOffset(0,0)
				line:SetShadowColor(0,0,0,0)
				line:SetFontObject(line.isTitle and Layout.FontObjectTitle or Layout.FontObject)
				local _,size = line:GetFont()
				local spacing = size*.2 - size*.2%1

				line:SetJustifyH("RIGHT")
				line:SetJustifyV("BOTTOM") 
				line:SetIndentedWordWrap(false)
				line:SetWordWrap(true)
				line:SetNonSpaceWrap(false)
				line:SetSpacing(spacing)

				dummyLine:SetFontObject(line:GetFontObject())
				dummyLine:SetText(line:GetText() or "")
				dummyLine:SetSpacing(spacing)

				line:SetWidth(Layout.Width)
				line:SetHeight(dummyLine:GetHeight())

				bottom = line:GetBottom()
			end 

			lineID = lineID + 1
			line = _G["QuestWatchLine"..lineID]
		end

		QuestWatchFrame:SetHeight(top - bottom)

	end)
end

Module.CreateDriver = function(self)
	if (Layout.HideInCombat or Layout.HideInBossFights) then 
		local driverFrame = self:CreateFrame("Frame", nil, _G.UIParent, "SecureHandlerAttributeTemplate")
		driverFrame:HookScript("OnShow", function() 
			if _G.QuestWatchFrame then 
				_G.QuestWatchFrame:SetAlpha(.9)
				self.frame.cover:Hide()
			end
		end)
		driverFrame:HookScript("OnHide", function() 
			if _G.QuestWatchFrame then 
				_G.QuestWatchFrame:SetAlpha(0)
				self.frame.cover:Show()
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
	self:StyleTracker()
end 

Module.OnEnable = function(self)
	self:CreateDriver()
end
