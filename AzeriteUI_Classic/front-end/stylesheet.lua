--[[--

The purpose of this file is to supply all the front-end modules 
with static layout data used during the setup phase. 

--]]--

local ADDON, Private = ...

local L = CogWheel("LibLocale"):GetLocale(ADDON)
local LibDB = CogWheel("LibDB")

------------------------------------------------
-- Addon Environment
------------------------------------------------
-- Lua API
local _G = _G
local math_cos = math.cos
local math_floor = math.floor
local math_pi = math.pi 
local math_sin = math.sin
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetCVarDefault = _G.GetCVarDefault
local UnitCanAttack = _G.UnitCanAttack
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel

-- Private Addon API
local GetAuraFilterFunc = Private.GetAuraFilterFunc
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Just because we repeat them so many times
local MenuButtonFontSize, MenuButtonW, MenuButtonH = 14, 300, 50

------------------------------------------------
-- Utility Functions
------------------------------------------------
local degreesToRadiansConstant = 360 * 2*math_pi
local degreesToRadians = function(degrees)
	return degrees/degreesToRadiansConstant
end 

------------------------------------------------
-- Module Updates
------------------------------------------------
local Core_Window_CreateBorder = function(self)
	local mod = 1 -- .75
	local border = self:CreateFrame("Frame")
	border:SetFrameLevel(self:GetFrameLevel()-1)
	border:SetPoint("TOPLEFT", -6, 8)
	border:SetPoint("BOTTOMRIGHT", 6, -8)
	border:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("tooltip_border_blizzcompatible"),
		edgeSize = 32, 
		tile = false, 
		insets = { 
			top = 9, 
			bottom = 9, 
			left = 9, 
			right = 9 
		}
	})
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border:SetBackdropColor(.05, .05, .05, .85)

	return border
end

local Core_Window_OnHide = function(self)
	self:GetParent():Update()
end

local Core_Window_OnShow = function(self)
	self:GetParent():Update()
end

local Core_MenuButton_PostCreate = function(self, text, ...)
	local msg = self:CreateFontString()
	msg:SetPoint("CENTER", 0, 0)
	msg:SetFontObject(GetFont(MenuButtonFontSize, false))
	msg:SetJustifyH("RIGHT")
	msg:SetJustifyV("TOP")
	msg:SetIndentedWordWrap(false)
	msg:SetWordWrap(false)
	msg:SetNonSpaceWrap(false)
	msg:SetTextColor(0,0,0)
	msg:SetShadowOffset(0, -.85)
	msg:SetShadowColor(1,1,1,.5)
	msg:SetText(text)
	self.Msg = msg

	local bg = self:CreateTexture()
	bg:SetDrawLayer("ARTWORK")
	bg:SetTexture(GetMedia("menu_button_disabled"))
	bg:SetVertexColor(.9, .9, .9)
	bg:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
	bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
	self.NormalBackdrop = bg

	local pushed = self:CreateTexture()
	pushed:SetDrawLayer("ARTWORK")
	pushed:SetTexture(GetMedia("menu_button_pushed"))
	pushed:SetVertexColor(.9, .9, .9)
	pushed:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
	pushed:SetPoint("CENTER", msg, "CENTER", 0, 0)
	self.PushedBackdrop = pushed

	local arrowUp = self:CreateTexture()
	arrowUp:Hide()
	arrowUp:SetDrawLayer("OVERLAY")
	arrowUp:SetSize(20,20)
	arrowUp:SetTexture([[Interface\BUTTONS\Arrow-Down-Down]])
	arrowUp:SetDesaturated(true)
	arrowUp:SetTexCoord(0,1,1,1,0,0,1,0) 
	arrowUp:SetPoint("LEFT", 2, 1)
	self.ArrowUp = arrowUp

	local arrowDown = self:CreateTexture()
	arrowDown:Hide()
	arrowDown:SetDrawLayer("OVERLAY")
	arrowDown:SetSize(20,20)
	arrowDown:SetTexture([[Interface\BUTTONS\Arrow-Down-Down]])
	arrowDown:SetTexCoord(0,1,1,1,0,0,1,0) 
	arrowDown:SetPoint("LEFT", 2, -1)
	self.ArrowDown = arrowDown

	return self
end

local Core_MenuButton_PostCreate_Scaled = function(self, text, ...)
	local msg = self:CreateFontString()
	msg:SetPoint("CENTER", 0, 0)
	msg:SetFontObject(GetFont(MenuButtonFontSize, false))
	msg:SetJustifyH("RIGHT")
	msg:SetJustifyV("TOP")
	msg:SetIndentedWordWrap(false)
	msg:SetWordWrap(false)
	msg:SetNonSpaceWrap(false)
	msg:SetTextColor(0,0,0)
	msg:SetShadowOffset(0, -.85)
	msg:SetShadowColor(1,1,1,.5)
	msg:SetText(text)
	self.Msg = msg

	local bg = self:CreateTexture()
	bg:SetDrawLayer("ARTWORK")
	bg:SetTexture(GetMedia("menu_button_disabled"))
	bg:SetVertexColor(.9, .9, .9)
	bg:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
	bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
	self.NormalBackdrop = bg

	local pushed = self:CreateTexture()
	pushed:SetDrawLayer("ARTWORK")
	pushed:SetTexture(GetMedia("menu_button_pushed"))
	pushed:SetVertexColor(.9, .9, .9)
	pushed:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
	pushed:SetPoint("CENTER", msg, "CENTER", 0, 0)
	self.PushedBackdrop = pushed

	local arrowUp = self:CreateTexture()
	arrowUp:Hide()
	arrowUp:SetDrawLayer("OVERLAY")
	arrowUp:SetSize(20,20)
	arrowUp:SetTexture([[Interface\BUTTONS\Arrow-Down-Down]])
	arrowUp:SetDesaturated(true)
	arrowUp:SetTexCoord(0,1,1,1,0,0,1,0) 
	arrowUp:SetPoint("LEFT", 2, 1)
	self.ArrowUp = arrowUp

	local arrowDown = self:CreateTexture()
	arrowDown:Hide()
	arrowDown:SetDrawLayer("OVERLAY")
	arrowDown:SetSize(20,20)
	arrowDown:SetTexture([[Interface\BUTTONS\Arrow-Down-Down]])
	arrowDown:SetTexCoord(0,1,1,1,0,0,1,0) 
	arrowDown:SetPoint("LEFT", 2, -1)
	self.ArrowDown = arrowDown

	return self
end

local Core_MenuButton_Layers_PostUpdate = function(self)
	local isPushed = self.isDown or self.isChecked or self.windowIsShown
	local show = isPushed and self.PushedBackdrop or self.NormalBackdrop
	local hide = isPushed and self.NormalBackdrop or self.PushedBackdrop

	hide:SetAlpha(0)
	show:SetAlpha(1)

	if isPushed then
		self.ArrowDown:SetShown(self.hasWindow)
		self.ArrowUp:Hide()
		self.Msg:SetPoint("CENTER", 0, -2)
		if self:IsMouseOver() then
			show:SetVertexColor(1, 1, 1)
		elseif (self.isChecked or self.windowIsShown) then 
			show:SetVertexColor(.9, .9, .9)
		else
			show:SetVertexColor(.75, .75, .75)
		end
	else
		self.ArrowDown:Hide()
		self.ArrowUp:SetShown(self.hasWindow)
		self.Msg:SetPoint("CENTER", 0, 0)
		if self:IsMouseOver() then
			show:SetVertexColor(1, 1, 1)
		else
			show:SetVertexColor(.75, .75, .75)
		end
	end
end

local Core_MenuButton_PostUpdate = function(self, updateType, db, option, checked)
	if (updateType == "GET_VALUE") then 
	elseif (updateType == "SET_VALUE") then 
		if checked then 
			self.isChecked = true
		else
			self.isChecked = false
		end 
	elseif (updateType == "TOGGLE_VALUE") then 
		if option then 
			self.Msg:SetText(self.enabledTitle or L["Disable"])
			self.isChecked = true
		else 
			self.Msg:SetText(self.disabledTitle or L["Enable"])
			self.isChecked = false
		end 
	elseif (updateType == "TOGGLE_MODE") then 
		if option then 
			self.Msg:SetText(self.enabledTitle or L["Disable"])
			self.isChecked = true
		else 
			self.Msg:SetText(self.disabledTitle or L["Enable"])
			self.isChecked = false
		end 
	end 
	Core_MenuButton_Layers_PostUpdate(self, updateType, db, option, checked)
end

-- ActionButton stack/charge count Post Update
local ActionButton_StackCount_PostUpdate = function(self, count)
	local font = GetFont(((tonumber(count) or 0) < 10) and 18 or 14, true) 
	if (self.Count:GetFontObject() ~= font) then 
		self.Count:SetFontObject(font)
	end
end

-- General bind mode border creation method
local BindMode_MenuWindow_CreateBorder = Core_Window_CreateBorder

-- Binding Dialogue MenuButton
local BindMode_MenuButton_PostCreate = Core_MenuButton_PostCreate
local BindMode_MenuButton_PostUpdate = Core_MenuButton_Layers_PostUpdate

-- BindButton PostCreate 
local BindMode_BindButton_PostCreate = function(self)
	self.bg:ClearAllPoints()
	self.bg:SetPoint("CENTER", 0, 0)
	self.bg:SetTexture(GetMedia("actionbutton_circular_mask"))
	self.bg:SetSize(64 + 8, 64 + 8) -- icon is 44, 44
	self.bg:SetVertexColor(.4, .6, .9, .75)
	self.msg:SetFontObject(GetFont(16, true))
end

-- BindButton PostUpdate
local BindMode_BindButton_PostUpdate = function(self)
	self.bg:SetVertexColor(.4, .6, .9, .75)
end

-- BindButton PostEnter graphic updates 
local BindMode_BindButton_PostEnter = function(self)
	self.bg:SetVertexColor(.4, .6, .9, 1)
end

-- BindButton PostLeave graphic updates
local BindMode_BindButton_PostLeave = function(self)
	self.bg:SetVertexColor(.4, .6, .9, .75)
end

-- Blizzard GameMenu Button Post Updates
local Blizzard_GameMenu_Button_PostCreate = Core_MenuButton_PostCreate 
local Blizzard_GameMenu_Button_PostUpdate = Core_MenuButton_Layers_PostUpdate

-- Blizzard MicroMenu Button Post Updates
local BlizzardMicroMenu_Button_PostCreate = Core_MenuButton_PostCreate
local BlizzardMicroMenu_Button_PostUpdate = Core_MenuButton_Layers_PostUpdate

-- Blizzard Popup PostCreate styling
local BlizzardPopup_PostCreate = function(self, popup)
	popup:SetBackdrop(nil)
	popup:SetBackdropColor(0,0,0,0)
	popup:SetBackdropBorderColor(0,0,0,0)

	-- 8.2.0 Additions
	if (popup.Border) then 
		popup.Border:Hide()
		popup.Border:SetAlpha(0)
	end

	-- add a bigger backdrop frame with room for our larger buttons
	if (not popup.backdrop) then
		local backdrop = CreateFrame("Frame", nil, popup)
		backdrop:SetFrameLevel(popup:GetFrameLevel())
		backdrop:SetPoint("TOPLEFT", -10, 10)
		backdrop:SetPoint("BOTTOMRIGHT", 10, -10)
		popup.backdrop = backdrop
	end	

	local backdrop = popup.backdrop
	backdrop:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("tooltip_border_blizzcompatible"),
		edgeSize = 32, 
		tile = false, -- tiles don't tile vertically (?)
		--tile = true, tileSize = 256, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	})
	backdrop:SetBackdropColor(.05, .05, .05, .85)
	backdrop:SetBackdropBorderColor(1,1,1,1)

	-- remove button artwork
	for i = 1,4 do
		local button = popup["button"..i]
		if button then
			button:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
			button:GetHighlightTexture():SetVertexColor(0, 0, 0, 0)
			button:GetPushedTexture():SetVertexColor(0, 0, 0, 0)
			button:GetDisabledTexture():SetVertexColor(0, 0, 0, 0)
			button:SetBackdrop(nil)
			button:SetBackdropColor(0,0,0,0)
			button:SetBackdropBorderColor(0,0,0.0)

			-- Create our own custom border.
			-- Using our new thick tooltip border, just scaled down slightly.
			local sizeMod = 3/4
			local border = CreateFrame("Frame", nil, button)
			border:SetFrameLevel(button:GetFrameLevel() - 1)
			border:SetPoint("TOPLEFT", -23*sizeMod, 23*sizeMod -2)
			border:SetPoint("BOTTOMRIGHT", 23*sizeMod, -23*sizeMod -2)
			border:SetBackdrop({
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = GetMedia("tooltip_border"),
				edgeSize = 32*sizeMod,
				insets = {
					left = 22*sizeMod,
					right = 22*sizeMod,
					top = 22*sizeMod +2,
					bottom = 22*sizeMod -2
				}
			})
			border:SetBackdropColor(.05, .05, .05, .75)
			border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		
			button:HookScript("OnEnter", function() 
				button:SetBackdropColor(0,0,0,0)
				button:SetBackdropBorderColor(0,0,0.0)
				border:SetBackdropColor(.1, .1, .1, .75)
				border:SetBackdropBorderColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3])
			end)

			button:HookScript("OnLeave", function() 
				button:SetBackdropColor(0,0,0,0)
				button:SetBackdropBorderColor(0,0,0.0)
				border:SetBackdropColor(.05, .05, .05, .75)
				border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
			end)
		end
	end

	-- remove editbox artwork
	local name = popup:GetName()

	local editbox = _G[name .. "EditBox"]
	local editbox_left = _G[name .. "EditBoxLeft"]
	local editbox_mid = _G[name .. "EditBoxMid"]
	local editbox_right = _G[name .. "EditBoxRight"]

	-- these got added in... uh... cata?
	if editbox_left then editbox_left:SetTexture(nil) end
	if editbox_mid then editbox_mid:SetTexture(nil) end
	if editbox_right then editbox_right:SetTexture(nil) end

	editbox:SetBackdrop(nil)
	editbox:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeSize = 1,
		tile = false,
		tileSize = 0,
		insets = {
			left = -6,
			right = -6,
			top = 0,
			bottom = 0
		}
	})
	editbox:SetBackdropColor(0, 0, 0, 0)
	editbox:SetBackdropBorderColor(.15, .1, .05, 1)
	editbox:SetTextInsets(6,6,0,0)
end

-- Blizzard Popup anchor points post updates
local BlizzardPopup_Anchors_PostUpdate = function(self)
	local previous
	for i = 1, _G.STATICPOPUP_NUMDIALOGS do
		local popup = _G["StaticPopup"..i]
		local point, anchor, rpoint, x, y = popup:GetPoint()
		if (anchor == previous) then
			-- We only change the offsets values, not the anchor points, 
			-- since experience tells me that this is a safer way to avoid potential taint!
			popup:ClearAllPoints()
			popup:SetPoint(point, anchor, rpoint, 0, -32)
		end
		previous = popup
	end
end

-- Group Tools Menu Button Creation 
local GroupTools_Button_PostCreate = function(self) end 

-- Group Tools Menu Button Disable
local GroupTools_Button_OnDisable = function(self) end

-- Group Tools Menu Button Enable
local GroupTools_Button_OnEnable = function(self) end

-- Group Tools Menu Window Border
local GroupTools_Window_CreateBorder = function(self)
	local mod = 1 -- not .75 as the rest?
	local border = self:CreateFrame("Frame")
	border:SetFrameLevel(self:GetFrameLevel()-1)
	border:SetPoint("TOPLEFT", -23*mod, 23*mod)
	border:SetPoint("BOTTOMRIGHT", 23*mod, -23*mod)
	border:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("tooltip_border"),
		edgeSize = 32*mod, 
		tile = false, 
		insets = { 
			top = 23*mod, 
			bottom = 23*mod, 
			left = 23*mod, 
			right = 23*mod 
		}
	})
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border:SetBackdropColor(.05, .05, .05, .85)

	return border
end

local Minimap_RingFrame_SingleRing_ValueFunc = function(Value, Handler) 
	Value:ClearAllPoints()
	Value:SetPoint("BOTTOM", Handler.Toggle.Frame.Bg, "CENTER", 2, -2)
	Value:SetFontObject(GetFont(24, true)) 
end

local Minimap_RingFrame_OuterRing_ValueFunc = function(Value, Handler) 
	Value:ClearAllPoints()
	Value:SetPoint("TOP", Handler.Toggle.Frame.Bg, "CENTER", 1, -2)
	Value:SetFontObject(GetFont(16, true)) 
	Value.Description:Hide()
end

local Minimap_ZoneName_PlaceFunc = function(Handler) 
	return "BOTTOMRIGHT", Handler.Clock, "BOTTOMLEFT", -8, 0 
end

local Minimap_Performance_PlaceFunc = function(performanceFrame, Handler)
	performanceFrame:ClearAllPoints()
	performanceFrame:SetPoint("TOPLEFT", Handler.Latency, "TOPLEFT", 0, 0)
	performanceFrame:SetPoint("BOTTOMRIGHT", Handler.FrameRate, "BOTTOMRIGHT", 0, 0)
end

local Minimap_Performance_Latency_PlaceFunc = function(Handler) 
	return "BOTTOMRIGHT", Handler.Zone, "TOPRIGHT", 0, 6 
end

local Minimap_Performance_FrameRate_PlaceFunc = function(Handler) 
	return "BOTTOM", Handler.Clock, "TOP", 0, 6 
end 

local NamePlates_RaidTarget_PostUpdate = function(element, unit)
	local self = element._owner
	if self:IsElementEnabled("Auras") then 
		self.Auras:ForceUpdate()
	else 
		element:ClearAllPoints()
		element:SetPoint(unpack(self.layout.RaidTargetPlace))
	end 
end

local NamePlates_Auras_PostUpdate = function(element, unit, visible)
	local self = element._owner
	if (not self) then 
		return 
	end 

	-- The aura frame misalignment continues, 
	-- so we might have to re-anchor it to the frame on post updates. 
	-- Edit: This does NOT fix it...?
	-- Do we need to hook to something else?
	-- Edit2: Trying to anchor to Health element instead, 
	-- as some blizzard sizing might be the issue(?). 
	element:ClearAllPoints()
	if element.point then 
		element:SetPoint(element.point, element.anchor, element.relPoint, element.offsetX, element.offsetY)
	else 
		element:SetPoint(unpack(self.layout.AuraFramePlace))
	end 

	local raidTarget = self.RaidTarget
	if raidTarget then 
		raidTarget:ClearAllPoints()
		if visible then
			if visible > 3 then 
				raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace_AuraRows))
			elseif visible > 0 then
				raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace_AuraRow))
			else 
				raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace))
			end  
		else
			raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace))
		end
	end 
end

local NamePlate_CastBar_PostUpdate = function(cast, unit)
	if cast.notInterruptible then

		-- Set it to the protected look 
		if (cast.currentStyle ~= "protected") then 
			cast:SetSize(68, 9)
			cast:ClearAllPoints()
			cast:SetPoint("TOP", 0, -26)
			cast:SetStatusBarTexture(GetMedia("cast_bar"))
			cast:SetTexCoord(0, 1, 0, 1)
			cast.Bg:SetSize(68, 9)
			cast.Bg:SetTexture(GetMedia("cast_bar"))
			cast.Bg:SetVertexColor(.15, .15, .15, 1)

			cast.currentStyle = "protected"
		end 

		-- Color the bar appropriately
		if UnitIsPlayer(unit) then 
			if UnitIsEnemy(unit, "player") then 
				cast:SetStatusBarColor(Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3]) 
			else 
				cast:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3]) 
			end  
		elseif UnitCanAttack("player", unit) then 
			cast:SetStatusBarColor(Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3]) 
		else 
			cast:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3]) 
		end 
	else 

		-- Return to standard castbar styling and position 
		if (cast.currentStyle == "protected") then 
			cast:SetSize(84, 14)
			cast:ClearAllPoints()
			cast:SetPoint("TOP", 0, -22)
			cast:SetStatusBarTexture(GetMedia("nameplate_bar"))
			cast:SetTexCoord(14/256, 242/256, 14/64, 50/64)

			cast.Bg:SetSize(84*256/228, 14*64/36)
			cast.Bg:SetTexture(GetMedia("nameplate_backdrop"))
			cast.Bg:SetVertexColor(1, 1, 1, 1)

			cast.currentStyle = nil 
		end 

		-- Standard bar coloring
		cast:SetStatusBarColor(Colors.cast[1], Colors.cast[2], Colors.cast[3]) 
	end 
end

-- Tooltip Bar post updates
-- Show health values for tooltip health bars, and hide others.
-- Will expand on this later to tailer all tooltips to our needs.  
local Tooltip_StatusBar_PostUpdate = function(tooltip, bar, value, min, max)
	if (bar.barType == "health") then 
		if (value >= 1e8) then 			bar.Value:SetFormattedText("%.0fm", value/1e6) 		-- 100m, 1000m, 2300m, etc
		elseif (value >= 1e6) then 		bar.Value:SetFormattedText("%.1fm", value/1e6) 		-- 1.0m - 99.9m 
		elseif (value >= 1e5) then 		bar.Value:SetFormattedText("%.0fk", value/1e3) 		-- 100k - 999k
		elseif (value >= 1e3) then 		bar.Value:SetFormattedText("%.1fk", value/1e3) 		-- 1.0k - 99.9k
		elseif (value > 0) then 		bar.Value:SetText(tostring(math_floor(value))) 		-- 1 - 999
		else 							bar.Value:SetText("")
		end 
		if (not bar.Value:IsShown()) then 
			bar.Value:Show()
		end
	else 
		if (bar.Value:IsShown()) then 
			bar.Value:Hide()
			bar.Value:SetText("")
		end
	end 
end 

local Tooltip_LinePair_PostCreate = function(tooltip, lineIndex, left, right)
	local fontObject = (lineIndex == 1) and GetFont(15, true) or GetFont(13, true)
	left:SetFontObject(fontObject)
	right:SetFontObject(fontObject)
end

local Tooltip_Bar_PostCreate = function(tooltip, bar)
	if bar.Value then 
		bar.Value:SetFontObject(GetFont(15, true))
	end
end

local Tooltip_PostCreate = function(tooltip)
	-- Turn off UIParent scale matching
	tooltip:SetCValue("autoCorrectScale", false)

	-- What items will be displayed automatically when available
	tooltip.showHealthBar =  true
	tooltip.showPowerBar =  true

	-- Unit tooltips
	tooltip.colorUnitClass = true -- color the unit class on the info line
	tooltip.colorUnitPetRarity = true -- color unit names by combat pet rarity
	tooltip.colorUnitNameClass = true -- color unit names by player class
	tooltip.colorUnitNameReaction = true -- color unit names by NPC standing
	tooltip.colorHealthClass = true -- color health bars by player class
	tooltip.colorHealthPetRarity = true -- color health by combat pet rarity
	tooltip.colorHealthReaction = true -- color health bars by NPC standing 
	tooltip.colorHealthTapped = true -- color health bars if unit is tap denied
	tooltip.colorPower = true -- color power bars by power type
	tooltip.colorPowerTapped = true -- color power bars if unit is tap denied

	-- Force our colors into all tooltips created so far
	tooltip.colors = Colors

	-- Add our post updates for statusbars
	tooltip.PostUpdateStatusBar = Tooltip_StatusBar_PostUpdate
end

local PlayerFrame_CastBarPostUpdate = function(element, unit)
	local self = element._owner
	local cast = self.Cast
	local health = self.Health

	local isPlayer = UnitIsPlayer(unit) -- and UnitIsEnemy(unit)
	local unitLevel = UnitLevel(unit)
	local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
	local isBoss = unitClassification == "boss" or unitClassification == "worldboss"
	local isEliteOrRare = unitClassification == "rare" or unitClassification == "elite" or unitClassification == "rareelite"

	if ((unitLevel and unitLevel == 1) and (not UnitIsPlayer("target"))) then 
		health.Value:Hide()
		health.ValueAbsorb:Hide()
		cast.Value:Hide()
		cast.Name:Hide()
	elseif (cast.casting or cast.channeling) then 
		health.Value:Hide()
		health.ValueAbsorb:Hide()
		cast.Value:Show()
		cast.Name:Show()
	else 
		health.Value:Show()
		health.ValueAbsorb:Show()
		cast.Value:Hide()
		cast.Name:Hide()
	end 
end

local TargetFrame_CastBarPostUpdate = function(element, unit)
	local self = element._owner
	local cast = self.Cast
	local health = self.Health

	local isPlayer = UnitIsPlayer(unit) -- and UnitIsEnemy(unit)
	local unitLevel = UnitLevel(unit)
	local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
	local isBoss = unitClassification == "boss" or unitClassification == "worldboss"
	local isEliteOrRare = unitClassification == "rare" or unitClassification == "elite" or unitClassification == "rareelite"

	if ((unitLevel and unitLevel == 1) and (not UnitIsPlayer("target"))) then 
		health.Value:Hide()
		health.ValueAbsorb:Hide()
		health.ValuePercent:Hide()
		cast.Value:Hide()
		cast.Name:Hide()
	elseif (cast.casting or cast.channeling) then 
		health.Value:Hide()
		health.ValueAbsorb:Hide()
		health.ValuePercent:Hide()
		cast.Value:Show()
		cast.Name:Show()
	else 
		health.Value:Show()
		health.ValueAbsorb:Show()
		health.ValuePercent:SetShown(isBoss or isPlayer or isEliteOrRare)
		cast.Value:Hide()
		cast.Name:Hide()
	end 
end

local SmallFrame_CastBarPostUpdate = function(element, unit)
	local self = element._owner
	local cast = self.Cast
	local health = self.Health
	local status = self.UnitStatus

	-- This takes presedence
	local casting = cast.casting or cast.channeling
	cast.Name:SetShown(casting)

	-- Only show the health value if we're not casting, and no status should be visible
	if (status) then 
		if (casting) then 
			status:Hide()
			health.Value:Hide()
		elseif (status.status) then 
			status:Show()
			health.Value:Hide()
		else 
			status:Hide()
			health.Value:Show()
		end 
	else 
		health.Value:SetShown(not casting)
	end 
end

------------------------------------------------
-- Module Stylesheets
------------------------------------------------
-- Addon Core
local Core = {
	Colors = Colors,

	FadeInUI = true, 
		FadeInSpeed = .75,
		FadeInDelay = 1.5,

	DisableUIWidgets = {
		ActionBars = true, 
		--Alerts = true,
		Auras = true,
		BuffTimer = true, 
		CaptureBar = true,
		CastBars = true,
		Chat = true,
		LevelUpDisplay = true,
		Minimap = true,
		--ObjectiveTracker = true, 
		OrderHall = true,
		PlayerPowerBarAlt = true, 
		QuestWatchFrame = true, 
		TotemFrame = true, 
		Tutorials = true,
		
		UnitFramePlayer = true,
		UnitFramePet = true,
		UnitFrameTarget = true,
		UnitFrameToT = true,
		UnitFramePet = true,
		UnitFrameFocus = true,
		UnitFrameParty = true,
		UnitFrameBoss = true,
		UnitFrameArena = not(	CogWheel("LibModule"):IsAddOnEnabled("sArena") 
							or	CogWheel("LibModule"):IsAddOnEnabled("Gladius") 
							or 	CogWheel("LibModule"):IsAddOnEnabled("GladiusEx") ),

		--Warnings = true,
		WorldMap = true,
		WorldState = true,
		ZoneText = true
	},
	DisableUIMenuPages = {
		{ ID = 5, Name = "InterfaceOptionsActionBarsPanel" },
		{ ID = 10, Name = "CompactUnitFrameProfiles" }
	},
	UseEasySwitch = true, 
		EasySwitch = {
			["GoldieSix"] = { goldpawui = true, goldpaw = true, goldui = true, gui5 = true, gui = true },
			["DiabolicUI"] = { diabolicui2 = true, diabolicui = true, diabolic = true, diabloui = true, dui2 = true, dui = true }
		},
		
	UseMenu = true, 
		MenuPlace = { "BOTTOMRIGHT", -41, 32 },
		MenuSize = { 320 -10, 70 }, 

		MenuToggleButtonSize = { 48, 48 }, 
		MenuToggleButtonPlace = { "BOTTOMRIGHT", -4, 4 }, 
		MenuToggleButtonIcon = GetMedia("config_button"), 
		MenuToggleButtonIconPlace = { "CENTER", 0, 0 }, 
		MenuToggleButtonIconSize = { 96, 96 }, 
		MenuToggleButtonIconColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		MenuBorderBackdropColor = { .05, .05, .05, .85 },
		MenuBorderBackdropBorderColor = { 1, 1, 1, 1 },
		MenuWindow_CreateBorder = Core_Window_CreateBorder,
		MenuWindow_OnHide = Core_Window_OnHide, 
		MenuWindow_OnShow = Core_Window_OnShow,

		MenuButtonSize = { MenuButtonW, MenuButtonH },
		MenuButtonSpacing = 10, 
		MenuButtonSizeMod = .75, 
		MenuButton_PostCreate = Core_MenuButton_PostCreate, 
		MenuButton_PostUpdate = Core_MenuButton_PostUpdate
}

-- ActionBars
local ActionBars = {
	Colors = Colors,

	-- Button Tooltips
	-------------------------------------------------------
	UseTooltipSettings = true, 
		TooltipColorNameAsSpellWithUse = true, -- color item name as a spell (not by rarity) when it has a Use effect
		TooltipHideItemLevelWithUse = true, -- hide item level when it has a Use effect 
		TooltipHideBindsWithUse = true, -- hide item bind status when it has a Use effect
		TooltipHideEquipTypeWithUse = false, -- hide item equip location and item type with Use effect
		TooltipHideUniqueWithUse = true, -- hide item unique status when it has a Use effect
		TooltipHideStatsWithUse = true, -- hide item stats when it has a Use effect

	-- Bar Layout
	-------------------------------------------------------
	UseActionBarMenu = true, 

	-- Button Layout
	-------------------------------------------------------
	-- Generic
	ButtonSize = { 64, 64 },
	MaskTexture = GetMedia("actionbutton_circular_mask"),

	-- Icon
	IconSize = { 44, 44 },
	IconPlace = { "CENTER", 0, 0 },

	-- Button Pushed Icon Overlay
	PushedSize = { 44, 44 },
	PushedPlace = { "CENTER", 0, 0 },
	PushedColor = { 1, 1, 1, .15 },
	PushedDrawLayer = { "ARTWORK", 1 },
	PushedBlendMode = "ADD",

	-- Auto-Attack Flash
	FlashSize = { 44, 44 },
	FlashPlace = { "CENTER", 0, 0 },
	FlashColor = { 1, 0, 0, .25 },
	FlashTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	FlashDrawLayer = { "ARTWORK", 2 },

	-- Cooldown Count Number
	CooldownCountPlace = { "CENTER", 1, 0 },
	CooldownCountJustifyH = "CENTER",
	CooldownCountJustifyV = "MIDDLE",
	CooldownCountFont = GetFont(16, true),
	CooldownCountShadowOffset = { 0, 0 },
	CooldownCountShadowColor = { 0, 0, 0, 1 },
	CooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	-- Cooldown 
	CooldownSize = { 44, 44 },
	CooldownPlace = { "CENTER", 0, 0 },
	CooldownSwipeTexture = GetMedia("actionbutton_circular_mask"),
	CooldownBlingTexture = GetMedia("blank"),
	CooldownSwipeColor = { 0, 0, 0, .75 },
	CooldownBlingColor = { 0, 0, 0 , 0 },
	ShowCooldownSwipe = true,
	ShowCooldownBling = true,

	-- Charge Cooldown 
	ChargeCooldownSize = { 44, 44 },
	ChargeCooldownPlace = { "CENTER", 0, 0 },
	ChargeCooldownSwipeColor = { 0, 0, 0, .5 },
	ChargeCooldownBlingColor = { 0, 0, 0, 0 },
	ChargeCooldownSwipeTexture = GetMedia("actionbutton_circular_mask"),
	ChargeCooldownBlingTexture = GetMedia("blank"),
	ShowChargeCooldownSwipe = true,
	ShowChargeCooldownBling = false,

	-- Charge Count / Stack Size Text
	CountPlace = { "BOTTOMRIGHT", -3, 3 },
	CountJustifyH = "CENTER",
	CountJustifyV = "BOTTOM",
	CountFont = GetFont(18, true),
	CountShadowOffset = { 0, 0 },
	CountShadowColor = { 0, 0, 0, 1 },
	CountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
	CountMaxDisplayed = 99,
	CountPostUpdate = ActionButton_StackCount_PostUpdate, 

	-- Keybind Text
	KeybindPlace = { "TOPLEFT", 5, -5 },
	KeybindJustifyH = "CENTER",
	KeybindJustifyV = "BOTTOM",
	KeybindFont = GetFont(15, true),
	KeybindShadowOffset = { 0, 0 },
	KeybindShadowColor = { 0, 0, 0, 1 },
	KeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	-- Spell Highlights
	UseSpellHighlight = true, 
		SpellHighlightPlace = { "CENTER", 0, 0 },
		SpellHighlightSize = { 64/(122/256), 64/(122/256) },
		SpellHighlightTexture = GetMedia("actionbutton-spellhighlight"),
		SpellHighlightColor = { 255/255, 225/255, 125/255, .75 }, 

	-- Spell AutoCast
	UseSpellAutoCast = true, 
		SpellAutoCastPlace = { "CENTER", 0, 0 },
		SpellAutoCastSize = { 64/(122/256), 64/(122/256) },
		SpellAutoCastAntsTexture = GetMedia("actionbutton-ants-small"),
		SpellAutoCastAntsColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3] },
		SpellAutoCastGlowTexture = GetMedia("actionbutton-ants-small-glow"),
		SpellAutoCastGlowColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3] },

	-- Backdrop 
	UseBackdropTexture = true, 
		BackdropPlace = { "CENTER", 0, 0 },
		BackdropSize = { 64/(122/256), 64/(122/256) },
		BackdropTexture = GetMedia("actionbutton-backdrop"),
		BackdropDrawLayer = { "BACKGROUND", 1 },

	-- Border 
	UseBorderTexture = true, 
		BorderPlace = { "CENTER", 0, 0 },
		BorderSize = { 64/(122/256), 64/(122/256) },
		BorderTexture = GetMedia("actionbutton-border"),
		BorderDrawLayer = { "BORDER", 1 },
		BorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

	-- Gloss
	UseGlow = true, 
		GlowPlace = { "CENTER", 0, 0 },
		GlowSize = { 44/(122/256),44/(122/256) },
		GlowTexture = GetMedia("actionbutton-glow-white"),
		GlowDrawLayer = { "ARTWORK", 1 },
		GlowBlendMode = "ADD",
		GlowColor = { 1, 1, 1, .5 },

	-- Floaters
	-------------------------------------------------------
	UseExitButton = true, 
		--ExitButtonPlace = { "CENTER", "Minimap", "TOPLEFT", 14,-36 }, 
		ExitButtonPlace = { "CENTER", "Minimap", "CENTER", -math_cos(45*math_pi/180) * (213/2 + 10), math_sin(45*math_pi/180) * (213/2 + 10) }, 
		ExitButtonSize = { 32, 32 },
		ExitButtonTexturePlace = { "CENTER", 0, 0 }, 
		ExitButtonTextureSize = { 80, 80 }, 
		ExitButtonTexturePath = GetMedia("icon_exit_flight")

}

-- Bind Mode
local BindMode = {
	Colors = Colors,

	-- Binding Dialogue
	Place = { "TOP", "UICenter", "TOP", 0, -100 }, 
	Size = { 520, 180 },

	-- General border creation method
	MenuWindow_CreateBorder = BindMode_MenuWindow_CreateBorder,

	-- Binding Dialogue Buttons
	MenuButtonSize = { MenuButtonW, MenuButtonH },
	MenuButtonSpacing = 10, 
	MenuButtonSizeMod = .75, 
	MenuButton_PostCreate = BindMode_MenuButton_PostCreate,
	MenuButton_PostUpdate = BindMode_MenuButton_PostUpdate, 

	-- ActionButton Bind Overlays
	BindButton_PostCreate = BindMode_BindButton_PostCreate, 
	BindButton_PostUpdate = BindMode_BindButton_PostUpdate,
	BindButton_PostEnter = BindMode_BindButton_PostEnter,
	BindButton_PostLeave = BindMode_BindButton_PostLeave
}

-- Blizzard Chat Frames
local BlizzardChatFrames = {
	Colors = Colors,

	DefaultChatFramePlace = { "LEFT", 85, -60 },
	DefaultChatFrameSize = { 499, 176 }, -- 519, 196
	DefaultClampRectInsets = { -54, -54, -310, -330 },

	AlternateChatFramePlace = { "TOPLEFT", 85, -64 },
	AlternateChatFrameSize = { 499, 176 }, -- 519, 196
	AlternateClampRectInsets = { -54, -54, -310, -330 },

	ChatFadeTime = 5, 
	ChatVisibleTime = 15, 
	ChatIndentedWordWrap = false, 

	EditBoxHeight = 45, 
	EditBoxOffsetH = 15, 
	
	UseButtonTextures = true,
		ButtonFrameWidth = 48, ScrollBarWidth = 32, 
		ButtonTextureSize = { 64, 64 }, 
		ButtonTextureColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		ButtonTextureNormal = GetMedia("point_block"),
		ButtonTextureScrollToBottom = GetMedia("icon_chat_down"), 
		ButtonTextureMinimizeButton = GetMedia("icon_chat_minus"),
		ButtonTextureChatEmotes = GetMedia("config_button_emotes")
}

-- Blizzard Floaters
local BlizzardFloaterHUD = {
	Colors = Colors,

	StyleExtraActionButton = true, 
		ExtraActionButtonFramePlace = { "CENTER", 210 + 27, -60 },
		ExtraActionButtonPlace = { "CENTER", 0, 0 },
		ExtraActionButtonSize = { 64, 64 },

		ExtraActionButtonIconPlace = { "CENTER", 0, 0 },
		ExtraActionButtonIconSize = { 44, 44 },
		ExtraActionButtonIconMaskTexture = GetMedia("actionbutton_circular_mask"),  

		ExtraActionButtonCount = GetFont(18, true),
		ExtraActionButtonCountPlace = { "BOTTOMRIGHT", -3, 3 },
		ExtraActionButtonCountJustifyH = "CENTER",
		ExtraActionButtonCountJustifyV = "BOTTOM",

		ExtraActionButtonCooldownSize = { 44, 44 },
		ExtraActionButtonCooldownPlace = { "CENTER", 0, 0 },
		ExtraActionButtonCooldownSwipeTexture = GetMedia("actionbutton_circular_mask"),
		ExtraActionButtonCooldownBlingTexture = GetMedia("blank"),
		ExtraActionButtonCooldownSwipeColor = { 0, 0, 0, .5 },
		ExtraActionButtonCooldownBlingColor = { 0, 0, 0 , 0 },
		ExtraActionButtonShowCooldownSwipe = true,
		ExtraActionButtonShowCooldownBling = true,

		ExtraActionButtonKeybindPlace = { "TOPLEFT", 5, -5 },
		ExtraActionButtonKeybindJustifyH = "CENTER",
		ExtraActionButtonKeybindJustifyV = "BOTTOM",
		ExtraActionButtonKeybindFont = GetFont(15, true),
		ExtraActionButtonKeybindShadowOffset = { 0, 0 },
		ExtraActionButtonKeybindShadowColor = { 0, 0, 0, 1 },
		ExtraActionButtonKeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },
	
		UseExtraActionButtonBorderTexture = true,
			ExtraActionButtonBorderPlace = { "CENTER", 0, 0 },
			ExtraActionButtonBorderSize = { 64/(122/256), 64/(122/256) },
			ExtraActionButtonBorderTexture = GetMedia("actionbutton-border"),
			ExtraActionButtonBorderDrawLayer = { "BORDER", 1 },
			ExtraActionButtonBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

		ExtraActionButtonKillStyleTexture = true, 

	StyleZoneAbilityButton = true, 
		ZoneAbilityButtonFramePlace = { "CENTER", 210 + 27, -60 },
		ZoneAbilityButtonPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonSize = { 64, 64 },

		ZoneAbilityButtonIconPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonIconSize = { 44, 44 },
		ZoneAbilityButtonIconMaskTexture = GetMedia("actionbutton_circular_mask"),  

		ZoneAbilityButtonCount = GetFont(18, true),
		ZoneAbilityButtonCountPlace = { "BOTTOMRIGHT", -3, 3 },
		ZoneAbilityButtonCountJustifyH = "CENTER",
		ZoneAbilityButtonCountJustifyV = "BOTTOM",

		ZoneAbilityButtonCooldownSize = { 44, 44 },
		ZoneAbilityButtonCooldownPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonCooldownSwipeTexture = GetMedia("actionbutton_circular_mask"),
		ZoneAbilityButtonCooldownBlingTexture = GetMedia("blank"),
		ZoneAbilityButtonCooldownSwipeColor = { 0, 0, 0, .5 },
		ZoneAbilityButtonCooldownBlingColor = { 0, 0, 0 , 0 },
		ZoneAbilityButtonShowCooldownSwipe = true,
		ZoneAbilityButtonShowCooldownBling = true,

		UseZoneAbilityButtonBorderTexture = true,
			ZoneAbilityButtonBorderPlace = { "CENTER", 0, 0 },
			ZoneAbilityButtonBorderSize = { 64/(122/256), 64/(122/256) },
			ZoneAbilityButtonBorderTexture = GetMedia("actionbutton-border"),
			ZoneAbilityButtonBorderDrawLayer = { "BORDER", 1 },
			ZoneAbilityButtonBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

		ZoneAbilityButtonKillStyleTexture = true, 

	StyleDurabilityFrame = true, 
		DurabilityFramePlace = { "CENTER", 190, 0 },

	StyleVehicleSeatIndicator = true, 
		VehicleSeatIndicatorPlace = { "CENTER", 424, 0 }, 

	StyleTalkingHeadFrame = true, 
		StyleTalkingHeadFramePlace = { "TOP", 0, -(60 + 40) }, 

	StyleAlertFrames = true, 
		AlertFramesPlace = { "TOP", "UICenter", "TOP", 0, -40 }, 
		AlertFramesPlaceTalkingHead = { "TOP", "UICenter", "TOP", 0, -240 }, 
		AlertFramesSize = { 180, 20 },
		AlertFramesPosition = "TOP",
		AlertFramesAnchor = "BOTTOM", 
		AlertFramesOffset = -10,

	StyleErrorFrame = true, 
		ErrorFrameStrata = "LOW"
}

-- Blizzard Game Menu (Esc)
local BlizzardGameMenu = {
	MenuButtonSize = { MenuButtonW, MenuButtonH },
	MenuButtonSpacing = 10, 
	MenuButtonSizeMod = .75, 
	MenuButton_PostCreate = Blizzard_GameMenu_Button_PostCreate,
	MenuButton_PostUpdate = Blizzard_GameMenu_Button_PostUpdate
}

-- Blizzard MicroMenu
local BlizzardMicroMenu = {
	Colors = Colors,

	ButtonFont = GetFont(MenuButtonFontSize, false),
	ButtonFontColor = { 0, 0, 0 }, 
	ButtonFontShadowOffset = { 0, -.85 },
	ButtonFontShadowColor = { 1, 1, 1, .5 },
	ConfigWindowBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("tooltip_border"),
		edgeSize = 32 *.75, 
		insets = { 
			top = 23 *.75, 
			bottom = 23 *.75, 
			left = 23 *.75, 
			right = 23 *.75 
		}
	},

	MenuButtonSize = { MenuButtonW, MenuButtonH },
	MenuButtonSpacing = 10, 
	MenuButtonSizeMod = .75, 
	MenuButtonTitleColor = { Colors.title[1], Colors.title[2], Colors.title[3] },
	MenuButtonNormalColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] }, 
	MenuButton_PostCreate = BlizzardMicroMenu_Button_PostCreate,
	MenuButton_PostUpdate = BlizzardMicroMenu_Button_PostUpdate, 
	MenuWindow_CreateBorder = Core_Window_CreateBorder
}

-- Blizzard Objectives Tracker
local BlizzardObjectivesTracker = {
	Colors = Colors,

	Place = { "TOPRIGHT", -60, -260 },
	Width = 235, -- 235 default
	Scale = 1.1, 
	SpaceTop = 260, 
	SpaceBottom = 330, 
	MaxHeight = 480,
	HideInCombat = false, 
	HideInBossFights = true, 
	HideInArena = true
}

-- Blizzard Instance Countdown Timers
local BlizzardTimers = {
	Colors = Colors,

	Size = { 111, 14 },
		Anchor = CogWheel("LibFrame"):GetFrame(),
		AnchorPoint = "TOP",
		AnchorOffsetX = 0,
		AnchorOffsetY = -370, -- -220
		Growth = -50, 

	BlankTexture = GetMedia("blank"), 

	BarPlace = { "CENTER", 0, 0 },
		BarSize = { 111, 12 }, 
		BarTexture = GetMedia("cast_bar"), 
		BarColor = { Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3] }, 
		BarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},

	UseBarValue = true, 
		BarValuePlace = { "CENTER", 0, 0 }, 
		BarValueFont = GetFont(14, true),
		BarValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .7 },

	UseBackdrop = true, 
		BackdropPlace = { "CENTER", 1, -2 }, 
		BackdropSize = { 193,93 }, 
		BackdropTexture = GetMedia("cast_back"),
		BackdropDrawLayer = { "BACKGROUND", -5 },
		BackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

}

-- Blizzard Popup Styling
local BlizzardPopupStyling = {
	Colors = Colors, 
	PostCreatePopup = BlizzardPopup_PostCreate,
	PostUpdateAnchors = BlizzardPopup_Anchors_PostUpdate
}

-- Blizzard font replacements
local BlizzardFonts = {
	ChatFont = GetFont(15, true),
	ChatBubbleFont = GetFont(10, true)
}

-- Group Leader Tools
local GroupTools = {
	Colors = Colors,

	MenuPlace = { "TOPLEFT", "UICenter", "TOPLEFT", 22, -42 },
	MenuAlternatePlace = { "BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 22, 350 },
	MenuSize = { 300*.75 +30, 410 }, 

	MenuToggleButtonSize = { 48, 48 }, 
	MenuToggleButtonPlace = { "TOPLEFT", "UICenter", "TOPLEFT", -18, -40 }, 
	MenuToggleButtonAlternatePlace = { "BOTTOMLEFT", "UICenter", "BOTTOMLEFT", -18, 348 }, 
	MenuToggleButtonIcon = GetMedia("raidtoolsbutton"), 
	MenuToggleButtonIconPlace = { "CENTER", 0, 0 }, 
	MenuToggleButtonIconSize = { 64*.75, 128*.75 }, 
	MenuToggleButtonIconColor = { 1, 1, 1 }, 

	UseMemberCount = true, 
		MemberCountNumberPlace = { "TOP", 0, -20 }, 
		MemberCountNumberJustifyH = "CENTER",
		MemberCountNumberJustifyV = "MIDDLE", 
		MemberCountNumberFont = GetFont(14, true),
		MemberCountNumberColor = { Colors.title[1], Colors.title[2], Colors.title[3] },

	UseRoleCount = true, 
		RoleCountTankPlace = { "TOP", -70, -100 }, 
		RoleCountTankFont = GetFont(14, true),
		RoleCountTankColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountTankTexturePlace = { "TOP", -70, -44 },
		RoleCountTankTextureSize = { 64, 64 },
		RoleCountTankTexture = GetMedia("grouprole-icons-tank"),
		
		RoleCountHealerPlace = { "TOP", 0, -100 }, 
		RoleCountHealerFont = GetFont(14, true),
		RoleCountHealerColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountHealerTexturePlace = { "TOP", 0, -44 },
		RoleCountHealerTextureSize = { 64, 64 },
		RoleCountHealerTexture = GetMedia("grouprole-icons-heal"),

		RoleCountDPSPlace = { "TOP", 70, -100 }, 
		RoleCountDPSFont = GetFont(14, true),
		RoleCountDPSColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountDPSTexturePlace = { "TOP", 70, -44 },
		RoleCountDPSTextureSize = { 64, 64 },
		RoleCountDPSTexture = GetMedia("grouprole-icons-dps"),

	UseRaidTargetIcons = true, 
		RaidTargetIcon1Place = { "TOP", -80, -140 },
		RaidTargetIcon2Place = { "TOP", -28, -140 },
		RaidTargetIcon3Place = { "TOP",  28, -140 },
		RaidTargetIcon4Place = { "TOP",  80, -140 },
		RaidTargetIcon5Place = { "TOP", -80, -190 },
		RaidTargetIcon6Place = { "TOP", -28, -190 },
		RaidTargetIcon7Place = { "TOP",  28, -190 },
		RaidTargetIcon8Place = { "TOP",  80, -190 },
		RaidTargetIconsSize = { 48, 48 }, 
		RaidRoleRaidTargetTexture = GetMedia("raid_target_icons"),
		RaidRoleCancelTexture = nil,

	UseRolePollButton = true, 
		RolePollButtonPlace = { "TOP", 0, -260 }, 
		RolePollButtonSize = { 300*.75, 50*.75 },
		RolePollButtonTextFont = GetFont(14, false), 
		RolePollButtonTextColor = { 0, 0, 0 }, 
		RolePollButtonTextShadowColor = { 1, 1, 1, .5 }, 
		RolePollButtonTextShadowOffset = { 0, -.85 }, 
		RolePollButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		RolePollButtonTextureNormal = GetMedia("menu_button_disabled"), 
	
	UseReadyCheckButton = true, 
		ReadyCheckButtonPlace = { "TOP", -30, -310 }, 
		ReadyCheckButtonSize = { 300*.75 - 80, 50*.75 },
		ReadyCheckButtonTextFont = GetFont(14, false), 
		ReadyCheckButtonTextColor = { 0, 0, 0 }, 
		ReadyCheckButtonTextShadowColor = { 1, 1, 1, .5 }, 
		ReadyCheckButtonTextShadowOffset = { 0, -.85 }, 
		ReadyCheckButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		ReadyCheckButtonTextureNormal = GetMedia("menu_button_smaller"), 
		
	UseWorldMarkerFlag = true, 
		WorldMarkerFlagPlace = { "TOP", 88, -310 }, 
		WorldMarkerFlagSize = { 70*.75, 50*.75 },
		WorldMarkerFlagContentSize = { 32, 32 }, 
		WorldMarkerFlagBackdropSize = { 512 *1/3 *.75, 256 *1/3 *.75 },
		WorldMarkerFlagBackdropTexture = GetMedia("menu_button_tiny"), 

	UseConvertButton = true, 
		ConvertButtonPlace = { "TOP", 0, -360 }, 
		ConvertButtonSize = { 300*.75, 50*.75 },
		ConvertButtonTextFont = GetFont(14, false), 
		ConvertButtonTextColor = { 0, 0, 0 }, 
		ConvertButtonTextShadowColor = { 1, 1, 1, .5 }, 
		ConvertButtonTextShadowOffset = { 0, -.85 }, 
		ConvertButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		ConvertButtonTextureNormal = GetMedia("menu_button_disabled"), 

	MenuWindow_CreateBorder = GroupTools_Window_CreateBorder,
	PostCreateButton = GroupTools_Button_PostCreate, 
	OnButtonDisable = GroupTools_Button_OnDisable, 
	OnButtonEnable = GroupTools_Button_OnEnable
}

-- Minimap
local Minimap = {
	Colors = Colors,

	Size = { 213, 213 }, 
	Place = { "BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -58, 59 }, 
	MaskTexture = GetMedia("minimap_mask_circle_transparent"),
	BlobAlpha = { 0, 96, 0, 0 }, -- blobInside, blobOutside, ringOutside, ringInside 

	UseBlipTextures = true, 
		BlipScale = 1.15, 
		BlipTextures = {
			["8.1.0"] = GetMedia("Blip-Nandini-New-810"),
			["8.1.5"] = GetMedia("Blip-Nandini-New-815"),
			["8.2.0"] = GetMedia("Blip-Nandini-New-820"),

			-- Blizzard Fallback
			["8.2.5"] = [[Interface\MiniMap\ObjectIconsAtlas]]
		},

	UseCompass = true, 
		CompassTexts = { L["N"] }, -- only setting the North tag text, as we don't want a full compass ( order is NESW )
		CompassFont = GetFont(12, true), 
		CompassColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 }, 
		CompassRadiusInset = 10, -- move the text 10 points closer to the center of the map

	UseMapBorder = true, 
		MapBorderPlace = { "CENTER", 0, 0 }, 
		MapBorderSize = { 419, 419 }, 
		MapBorderTexture = GetMedia("minimap-border"),
		MapBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
	
	UseMapBackdrop = true, 
		MapBackdropTexture = GetMedia("minimap_mask_circle"),
		MapBackdropColor = { 0, 0, 0, .75 }, 

	UseMapOverlay = true, 
		MapOverlayTexture = GetMedia("minimap_mask_circle"),
		MapOverlayColor = { 0, 0, 0, .15 },

	-- Put XP and XP on the minimap!
	UseStatusRings = true, 
		RingFrameBackdropPlace = { "CENTER", 0, 0 },
		RingFrameBackdropSize = { 413, 413 }, 
		
		-- Backdrops
		RingFrameBackdropDrawLayer = { "BACKGROUND", 1 }, 
		RingFrameBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		RingFrameBackdropTexture = GetMedia("minimap-onebar-backdrop"), 
		RingFrameBackdropDoubleTexture = GetMedia("minimap-twobars-backdrop"), 

		-- Single Ring
		RingFrameSingleRingTexture = GetMedia("minimap-bars-single"), 
		RingFrameSingleRingSparkSize = { 6,34 * 208/256 }, 
		RingFrameSingleRingSparkInset = { 22 * 208/256 }, 
		RingFrameSingleRingValueFunc = Minimap_RingFrame_SingleRing_ValueFunc,

		-- Outer Ring
		RingFrameOuterRingTexture = GetMedia("minimap-bars-two-outer"), 
		RingFrameOuterRingSparkSize = { 6,20 * 208/256 }, 
		RingFrameOuterRingSparkInset = { 15 * 208/256 }, 
		RingFrameOuterRingValueFunc = Minimap_RingFrame_OuterRing_ValueFunc,

		-- Outer Ring
		OuterRingPlace = { "CENTER", 0, 2 }, 
		OuterRingSize = { 208, 208 }, 
		OuterRingClockwise = true, 
		OuterRingDegreeOffset = 90*3 - 14,
		OuterRingDegreeSpan = 360 - 14*2, 
		OuterRingShowSpark = true, 
		OuterRingSparkBlendMode = "ADD",
		OuterRingSparkOffset = -1/10, 
		OuterRingSparkFlash = { nil, nil, 1, 1 }, 
		OuterRingColorXP = true,
		OuterRingColorStanding = true,
		OuterRingColorPower = true,
		OuterRingColorValue = true,
		OuterRingBackdropMultiplier = 1, 
		OuterRingSparkMultiplier = 1, 
		OuterRingValuePlace = { "CENTER", 0, -9 },
		OuterRingValueJustifyH = "CENTER",
		OuterRingValueJustifyV = "MIDDLE",
		OuterRingValueFont = GetFont(15, true),
		OuterRingValueShowDeficit = true, 
		OuterRingValueDescriptionPlace = { "CENTER", 0, -(15/2 + 2) }, 
		OuterRingValueDescriptionWidth = 100, 
		OuterRingValueDescriptionColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3] }, 
		OuterRingValueDescriptionJustifyH = "CENTER", 
		OuterRingValueDescriptionJustifyV = "MIDDLE", 
		OuterRingValueDescriptionFont = GetFont(12, true),
		OuterRingValuePercentFont = GetFont(16, true),

		-- Inner Ring
		InnerRingPlace = { "CENTER", 0, 2 }, 
		InnerRingSize = { 208, 208 }, 
		InnerRingBarTexture = GetMedia("minimap-bars-two-inner"),
		InnerRingClockwise = true, 
		InnerRingDegreeOffset = 90*3 - 21,
		InnerRingDegreeSpan = 360 - 21*2, 
		InnerRingShowSpark = true, 
		InnerRingSparkSize = { 6, 27 * 208/256 },
		InnerRingSparkBlendMode = "ADD",
		InnerRingSparkOffset = -1/10,
		InnerRingSparkInset = 46 * 208/256,  
		InnerRingSparkFlash = { nil, nil, 1, 1 }, 
		InnerRingColorXP = true,
		InnerRingColorStanding = true,
		InnerRingColorPower = true,
		InnerRingColorValue = true,
		InnerRingBackdropMultiplier = 1, 
		InnerRingSparkMultiplier = 1, 
		InnerRingValueFont = GetFont(15, true),
		InnerRingValuePercentFont = GetFont(15, true), 

	ToggleSize = { 56, 56 }, 
	ToggleBackdropSize = { 100, 100 },
	ToggleBackdropTexture = GetMedia("point_plate"), 
	ToggleBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

	-- Change alpha on texts based on target
	UseTargetUpdates = true, 

	UseClock = true, 
		ClockPlace = { "BOTTOMRIGHT", -(13 + 213), -8 },
		ClockFont = GetFont(15, true),
		ClockColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] }, 

	UseZone = true, 
		ZonePlaceFunc = Minimap_ZoneName_PlaceFunc,
		ZoneFont = GetFont(15, true),

	UseCoordinates = true, 
		CoordinatePlace = { "BOTTOM", 3, 23 },
		CoordinateFont = GetFont(12, true), 
		CoordinateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 }, 

	UsePerformance = true, 
		PerformanceFramePlaceAdvancedFunc = Minimap_Performance_PlaceFunc,

		LatencyFont = GetFont(12, true), 
		LatencyColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },
		LatencyPlaceFunc = Minimap_Performance_Latency_PlaceFunc, 

		FrameRateFont = GetFont(12, true), 
		FrameRateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },
		FrameRatePlaceFunc = Minimap_Performance_FrameRate_PlaceFunc, 

	UseMail = true,
		MailPlace = 
			CogWheel("LibModule"):IsAddOnEnabled("MBB") and 
			{ "BOTTOMRIGHT", -(31 + 213 + 40), 35 } or 
			{ "BOTTOMRIGHT", -(31 + 213), 35 },
		MailSize = { 43, 32 },
		MailTexture = GetMedia("icon_mail"),
		MailTexturePlace = { "CENTER", 0, 0 }, 
		MailTextureSize = { 66, 66 },
		MailTextureDrawLayer = { "ARTWORK", 1 },
		MailTextureRotation = 15 * (2*math_pi)/360,

	UseMBB = true, 
		MBBSize = { 32, 32 },
		MBBPlace = { "BOTTOMRIGHT", -(31 + 213), 35 },
		MBBTexture = GetMedia("plus"),

	UseGroupFinderEye = true, 
		GroupFinderEyePlace = { "CENTER", math_cos(45*math_pi/180) * (213/2 + 10), math_sin(45*math_pi/180) * (213/2 + 10) }, 
		GroupFinderEyeSize = { 64, 64 }, 
		GroupFinderEyeTexture = GetMedia("group-finder-eye-green"),
		GroupFinderEyeColor = { .90, .95, 1 }, 
		GroupFinderQueueStatusPlace = { "BOTTOMRIGHT", _G.QueueStatusMinimapButton, "TOPLEFT", 0, 0 }

}

-- NamePlates
local NamePlates = {
	Colors = Colors,

	UseNamePlates = true, 
		Size = { 80, 32 }, 
	
	UseHealth = true, 
		HealthPlace = { "TOP", 0, -2 },
		HealthSize = { 84, 14 }, 
		HealthBarOrientation = "LEFT", 
		HealthTexture = GetMedia("nameplate_bar"),
		HealthTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
		HealthSparkMap = {
			top = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			}
		},
		HealthColorTapped = true,
		HealthColorDisconnected = true,
		HealthColorClass = true, -- color players in their class colors
		HealthColorCivilian = true, -- color friendly players as civilians
		HealthColorReaction = true,
		HealthColorHealth = true,
		HealthColorThreat = true,
		HealthThreatFeedbackUnit = "player",
		HealthThreatHideSolo = false, 
		HealthFrequent = true,

	UseHealthBackdrop = true, 
		HealthBackdropPlace = { "CENTER", 0, 0 },
		HealthBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
		HealthBackdropTexture = GetMedia("nameplate_backdrop"),
		HealthBackdropDrawLayer = { "BACKGROUND", -2 },
		HealthBackdropColor = { 1, 1, 1, 1 },

	UseHealPredict = true, 
		HealPredictPlace = { "TOPRIGHT", 0, 0 }, -- relative to the health bar, not the frame! 
		HealPredictSize = { 84, 14 }, 
		HealPredictFrequentUpdates = true, 
		HealPredictOrientation = "LEFT", 
		HealPredictTexture = GetMedia("nameplate_bar"),
		HealPredictTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
		HealthPreviewOnTexCoordChanged = HealthPreview_OnTexCoordChanged, 

	UseCast = true, 
		CastPlace = { "TOP", 0, -22 },
		CastSize = { 84, 14 }, 
		CastOrientation = "LEFT", 
		CastColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], 1 },
		CastTexture = GetMedia("nameplate_bar"),
		CastTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
		CastTimeToHoldFailed = .5, 
		CastSparkMap = {
			top = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			}
		},

		UseCastBackdrop = true, 
			CastBackdropPlace = { "CENTER", 0, 0 },
			CastBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
			CastBackdropTexture = GetMedia("nameplate_backdrop"),
			CastBackdropDrawLayer = { "BACKGROUND", 0 },
			CastBackdropColor = { 1, 1, 1, 1 },

		UseCastName = true, 
			CastNamePlace = { "TOP", 0, -20 },
			CastNameFont = GetFont(12, true),
			CastNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
			CastNameDrawLayer = { "OVERLAY", 1 }, 
			CastNameJustifyH = "CENTER", 
			CastNameJustifyV = "MIDDLE",

		UseCastShield = true, 
			CastShieldPlace = { "CENTER", 0, -1 }, 
			CastShieldSize = { 124, 69 },
			CastShieldTexture = GetMedia("cast_back_spiked"),
			CastShieldDrawLayer = { "BACKGROUND", -5 },
			CastShieldColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		CastPostUpdate = NamePlate_CastBar_PostUpdate,

	UseThreat = true, 
		ThreatPlace = { "CENTER", 0, 0 },
		ThreatSize = { 84*256/(256-28), 14*64/(64-28) },
		ThreatTexture = GetMedia("nameplate_glow"),
		ThreatColor = { 1, 1, 1, 1 },
		ThreatDrawLayer = { "BACKGROUND", -3 },
		ThreatHideSolo = true, 

	UseAuras = true, 
		AuraFrameSize = { 30*3 + 4*2, 30*2 + 4  }, 
		--AuraFramePlace = { "TOP", 0, 30*2+5 + 10 },

		-- Try to work around the problem with misaligned auras by changing the anchor? 
		-- I can't seem to find any position but the initial, so it might be that they're 
		-- anchored before the frame has a real size and the anchor just "sticks"...? 
		-- Weirdness. Can't reproduce it consistantly, which backs up that theory. 
		-- So for now I'll just attempt to work around it, see if it goes away!
		AuraFramePlace = { "TOPLEFT", (84 - (30*3 + 4*2))/2, 30*2 + 4 + 10 },
		AuraPoint = "BOTTOMLEFT", AuraAnchor = "Health", AuraRelPoint = "TOPLEFT",
		AuraOffsetX = (84 - (30*3 + 4*2))/2, AuraOffsetY = 10 + 4,

		AuraSize = 30, 
		AuraSpaceH = 4, 
		AuraSpaceV = 4, 
		AuraGrowthX = "LEFT", 
		AuraGrowthY = "UP", 
		AuraMax = 6, 
		AuraMaxBuffs = nil, 
		AuraMaxDebuffs = nil, 
		AuraDebuffsFirst = false, 
		ShowAuraCooldownSpirals = false, 
		ShowAuraCooldownTime = true, 
		AuraFilter = nil, 
		AuraBuffFilter = "PLAYER HELPFUL", 
		AuraDebuffFilter = "PLAYER HARMFUL", 
		AuraFilterFunc = GetAuraFilterFunc("nameplate"), 
		BuffFilterFunc = GetAuraFilterFunc("nameplate"), 
		DebuffFilterFunc = GetAuraFilterFunc("nameplate"), 
		AuraDisableMouse = true, -- don't allow mouse input here
		AuraTooltipDefaultPosition = nil, 
		AuraTooltipPoint = "BOTTOMLEFT", 
		AuraTooltipAnchor = nil, 
		AuraTooltipRelPoint = "TOPLEFT", 
		AuraTooltipOffsetX = -8, 
		AuraTooltipOffsetY = -16,

		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 30 - 6, 30 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = GetFont(12, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 },
		AuraTimeFont = GetFont(11, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 30 + 10, 30 + 10 },
		AuraBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 12 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

		PostUpdateAura = NamePlates_Auras_PostUpdate,

	UseRaidTarget = true, 
		RaidTargetPlace = { "TOP", 0, 44 }, -- no auras
		RaidTargetPlace_AuraRow = { "TOP", 0, 80 }, -- auras, 1 row
		RaidTargetPlace_AuraRows = { "TOP", 0, 112 }, -- auras, 2 rows
		RaidTargetSize = { 64, 64 },
		RaidTargetTexture = GetMedia("raid_target_icons"),
		RaidTargetDrawLayer = { "ARTWORK", 0 },
		PostUpdateRaidTarget = NamePlates_RaidTarget_PostUpdate,

	-- CVars adjusted at startup
	SetConsoleVars = {
		-- Because we want friendly NPC nameplates
		-- We're toning them down a lot as it is, 
		-- but we still prefer to have them visible, 
		-- and not the fugly super sized names we get otherwise.
		--nameplateShowFriendlyNPCs = 1, -- Don't enforce this

		-- Insets at the top and bottom of the screen 
		-- which the target nameplate will be kept away from. 
		-- Used to avoid the target plate being overlapped 
		-- by the target frame or actionbars and keep it in view.
		nameplateLargeTopInset = .08, -- default .1
		nameplateOtherTopInset = .08, -- default .08
		nameplateLargeBottomInset = .02, -- default .15
		nameplateOtherBottomInset = .02, -- default .1
		nameplateClassResourceTopInset = 0,

		-- Nameplate scale
		nameplateMinScale = 1, 
		nameplateMaxScale = 1, 
		nameplateLargerScale = 1, -- Scale modifier for large plates, used for important monsters
		nameplateGlobalScale = 1,
		NamePlateHorizontalScale = 1,
		NamePlateVerticalScale = 1,

		-- Alpha defaults (these are enforced to other values by the back-end now)
		nameplateMaxAlpha = GetCVarDefault("nameplateMaxAlpha"), 
		nameplateMinAlphaDistance = GetCVarDefault("nameplateMinAlphaDistance"), 
		nameplateMinAlpha = GetCVarDefault("nameplateMinAlpha"),
		nameplateMaxAlphaDistance = GetCVarDefault("nameplateMaxAlphaDistance"),
		nameplateOccludedAlphaMult = GetCVarDefault("nameplateOccludedAlphaMult"), 
		nameplateSelectedAlpha = GetCVarDefault("nameplateSelectedAlpha"), 

		-- The minimum distance from the camera plates will reach their minimum scale and alpha
		nameplateMinScaleDistance = GetCVarDefault("nameplateMinScaleDistance"), 
		
		-- The maximum distance from the camera where plates will still have max scale and alpha
		nameplateMaxScaleDistance = GetCVarDefault("nameplateMaxScaleDistance"),

		-- Show nameplates above heads or at the base (0 or 2,
		nameplateOtherAtBase = 0,

		-- Scale and Alpha of the selected nameplate (current target,
		nameplateSelectedScale = 1 -- default 1
	}
}

-- Custom Tooltips
local TooltipStyling = {
	Colors = Colors,

	-- Going with full positioning after 8.2.0. 
	TooltipPlace = { "BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -(48 + 58 + 213), (107 + 59) }, 
	--TooltipPlace = { "BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -48, 107 }, 

	TooltipStatusBarTexture = GetMedia("statusbar_normal"), 
	TooltipBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = false, 
		edgeFile = GetMedia("tooltip_border_blizzcompatible"), edgeSize = 32, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	},
	TooltipBackdropColor = { .05, .05, .05, .85 },
	TooltipBackdropBorderColor = { 1, 1, 1, 1 },

	PostCreateTooltip = Tooltip_PostCreate,
	PostCreateLinePair = Tooltip_LinePair_PostCreate, 
	PostCreateBar = Tooltip_Bar_PostCreate
}

------------------------------------------------------------------
-- UnitFrame Config Templates
------------------------------------------------------------------
-- Table containing common values for the templates
local Constant = {
	SmallFrame = { 136, 47 },
	SmallBar = { 112, 11 }, 
	SmallBarTexture = GetMedia("cast_bar"),
	SmallAuraSize = 30, 

	TinyFrame = { 130, 30 }, 
	TinyBar = { 80, 14 }, 
	TinyBarTexture = GetMedia("cast_bar"),

	RaidFrame = { 110 *.94, 30 *.94 }, 
	RaidBar = { 80 *.94, 14  *.94}, 
}

local Template_SmallFrame = {
	Colors = Colors,

	Size = Constant.SmallFrame,
	FrameLevel = 20, 
	
	HealthPlace = { "CENTER", 0, 0 }, 
		HealthSize = Constant.SmallBar,  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = Constant.SmallBarTexture, 
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSetFlippedHorizontally = false, 
		HealthBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 193,93 },
			HealthBackdropTexture = GetMedia("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = GetFont(14, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthShowPercent = true, 


	UseCastBar = true,
		CastBarPlace = { "CENTER", 0, 0 },
		CastBarSize = Constant.SmallBar,
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		CastBarTexture = Constant.SmallBarTexture, 
		CastBarColor = { 1, 1, 1, .15 },

	-- This should be the same as the health value
	UseCastBarName = true, 
		CastBarNameParent = "Health",
		CastBarNamePlace = { "CENTER", 0, 1 },
		CastBarNameSize = { Constant.SmallBar[1] - 20, Constant.SmallBar[2] }, 
		CastBarNameFont = GetFont(12, true),
		CastBarNameColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
		CastBarNameDrawLayer = { "OVERLAY", 1 }, 
		CastBarNameJustifyH = "CENTER", 
		CastBarNameJustifyV = "MIDDLE",

	CastBarPostUpdate =	SmallFrame_CastBarPostUpdate,
	HealthBarPostUpdate = SmallFrame_CastBarPostUpdate, 

	UseTargetHighlight = true, 
		TargetHighlightParent = "Health", 
		TargetHighlightPlace = { "CENTER", 1, -2 },
		TargetHighlightSize = { 193,93 },
		TargetHighlightTexture = GetMedia("cast_back_outline"), 
		TargetHighlightDrawLayer = { "BACKGROUND", 0 },
		TargetHighlightShowTarget = true, TargetHighlightTargetColor = { 255/255, 239/255, 169/255, 1 }, 
		TargetHighlightShowFocus = true, TargetHighlightFocusColor = { 144/255, 195/255, 255/255, 1 }, 

} 

local Template_SmallFrame_Auras = setmetatable({
	UseAuras = true, 
		AuraFrameSize = { Constant.SmallAuraSize*6 + 4*5, Constant.SmallAuraSize }, 
		AuraFramePlace = { "LEFT", Constant.SmallFrame[1] + 13, -1 },
		AuraSize = Constant.SmallAuraSize, 
		AuraSpaceH = 4, 
		AuraSpaceV = 4, 
		AuraGrowthX = "RIGHT", 
		AuraGrowthY = "UP", 
		AuraMax = 6, 
		AuraMaxBuffs = nil, 
		AuraMaxDebuffs = nil, 
		AuraDebuffsFirst = false, 
		ShowAuraCooldownSpirals = false, 
		ShowAuraCooldownTime = true, 
		AuraFilter = nil, 
		AuraBuffFilter = "HELPFUL", 
		AuraDebuffFilter = "HARMFUL", 
		AuraFilterFunc = nil, 
		BuffFilterFunc = nil, 
		DebuffFilterFunc = nil, 
		AuraTooltipDefaultPosition = nil, 
		AuraTooltipPoint = "BOTTOMLEFT", 
		AuraTooltipAnchor = nil, 
		AuraTooltipRelPoint = "TOPLEFT", 
		AuraTooltipOffsetX = 8, 
		AuraTooltipOffsetY = 16,

		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { Constant.SmallAuraSize - 6, Constant.SmallAuraSize - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = GetFont(12, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 }, -- { "CENTER", 0, 0 },
		AuraTimeFont = GetFont(11, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { Constant.SmallAuraSize + 14, Constant.SmallAuraSize + 14 },
		AuraBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

	
}, { __index = Template_SmallFrame })

local Template_SmallFrameReversed = setmetatable({
	HealthBarOrientation = "LEFT", 
	HealthBarSetFlippedHorizontally = true, 
	CastBarOrientation = "LEFT", 
	CastBarSetFlippedHorizontally = true, 
}, { __index = Template_SmallFrame })

local Template_SmallFrameReversed_Auras = setmetatable({
	HealthBarOrientation = "LEFT", 
	HealthBarSetFlippedHorizontally = true, 
	CastBarOrientation = "LEFT", 
	CastBarSetFlippedHorizontally = true, 
	AuraFramePlace = { "RIGHT", -(Constant.SmallFrame[1] + 13), -1 },
	AuraGrowthX = "LEFT", 
	AuraGrowthY = "DOWN", 
	AuraTooltipPoint = "TOPRIGHT", 
	AuraTooltipRelPoint = "BOTTOMRIGHT", 
	AuraTooltipOffsetX = -8, 
	AuraTooltipOffsetY = -16
}, { __index = Template_SmallFrame_Auras })

local Template_TinyFrame = {
	Colors = Colors,

	Size = Constant.TinyFrame,

	HealthPlace = { "BOTTOM", 0, 0 }, 
		HealthSize = Constant.TinyBar,  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = Constant.TinyBarTexture, 
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSetFlippedHorizontally = false, 
		HealthBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 140,90 },
			HealthBackdropTexture = GetMedia("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = GetFont(13, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthShowPercent = true, 
		
	
	UseCastBar = true,
		CastBarPlace = { "BOTTOM", 0, 0 },
		CastBarSize = Constant.TinyBar,
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		CastBarTexture = Constant.TinyBarTexture, 
		CastBarColor = { 1, 1, 1, .15 },

	UseRange = true, 
		RangeOutsideAlpha = .6, -- was .35, but that's too hard to see

	UseTargetHighlight = true, 
		TargetHighlightParent = "Health", 
		TargetHighlightPlace = { "CENTER", 1, -2 },
		TargetHighlightSize = { 140, 90 },
		TargetHighlightTexture = GetMedia("cast_back_outline"), 
		TargetHighlightDrawLayer = { "BACKGROUND", 0 },
		TargetHighlightShowTarget = true, TargetHighlightTargetColor = { 255/255, 229/255, 109/255, 1 }, 
		TargetHighlightShowFocus = true, TargetHighlightFocusColor = { 44/255, 165/255, 255/255, 1 }, 

}

------------------------------------------------------------------
-- Singular Units
------------------------------------------------------------------
-- Player
local UnitFramePlayer = { 
	Colors = Colors,

	Place = { "BOTTOMLEFT", 167, 100 },
	Size = { 439, 93 },
	ExplorerHitRects = { 60, 0, -140, 0 },
	
	UseBorderBackdrop = false,
		BorderFramePlace = nil,
		BorderFrameSize = nil,
		BorderFrameBackdrop = nil,
		BorderFrameBackdropColor = nil,
		BorderFrameBackdropBorderColor = nil,
		
	HealthPlace = { "BOTTOMLEFT", 27, 27 },
		HealthSize = nil, 
		HealthType = "StatusBar", -- health type
		HealthBarTexture = nil, -- only called when non-progressive frames are used
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HealthBarSetFlippedHorizontally = false, 
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = 3, -- .2, -- speed of the smoothing method
		HealthColorTapped = false, -- color tap denied units 
		HealthColorDisconnected = false, -- color disconnected units
		HealthColorClass = false, -- color players by class 
		HealthColorReaction = false, -- color NPCs by their reaction standing with us
		HealthColorHealth = true, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

	UseHealthBackdrop = true,
		HealthBackdropPlace = { "CENTER", 1, -.5 },
		HealthBackdropSize = { 716, 188 },
		HealthBackdropDrawLayer = { "BACKGROUND", -1 },

	UseHealthValue = true, 
		HealthValuePlace = { "LEFT", 27, 4 },
		HealthValueDrawLayer = { "OVERLAY", 1 },
		HealthValueJustifyH = "CENTER", 
		HealthValueJustifyV = "MIDDLE", 
		HealthValueFont = GetFont(18, true),
		HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UseAbsorbValue = true, 
			AbsorbValuePlaceFunction = function(self) return "LEFT", self.Health.Value, "RIGHT", 13, 0 end, 
			AbsorbValueDrawLayer = { "OVERLAY", 1 }, 
			AbsorbValueFont = GetFont(18, true),
			AbsorbValueJustifyH = "CENTER", 
			AbsorbValueJustifyV = "MIDDLE",
			AbsorbValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
	
	UsePowerBar = true,
		PowerPlace = { "BOTTOMLEFT", -101, 38 },
		PowerSize = { 120, 140 },
		PowerType = "StatusBar", 
		PowerBarTexture = GetMedia("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSmoothingMode = "bezier-fast-in-slow-out",
		PowerBarSmoothingFrequency = .45,
		PowerColorSuffix = "_CRYSTAL", 
		PowerIgnoredResource = "MANA",
	
		UsePowerBackground = true,
			PowerBackgroundPlace = { "CENTER", 0, 0 },
			PowerBackgroundSize = { 120/(206-50)*255, 140/(219-37)*255 },
			PowerBackgroundTexture = GetMedia("power_crystal_back"),
			PowerBackgroundDrawLayer = { "BACKGROUND", -2 },
			PowerBackgroundColor = { 1, 1, 1, .95 },
			PowerBarSparkMap = {
				top = {
					{ keyPercent =   0/256, offset =  -65/256 }, 
					{ keyPercent =  72/256, offset =    0/256 }, 
					{ keyPercent = 116/256, offset =  -16/256 }, 
					{ keyPercent = 128/256, offset =  -28/256 }, 
					{ keyPercent = 256/256, offset =  -84/256 }, 
				},
				bottom = {
					{ keyPercent =   0/256, offset =  -47/256 }, 
					{ keyPercent =  84/256, offset =    0/256 }, 
					{ keyPercent = 135/256, offset =  -24/256 }, 
					{ keyPercent = 142/256, offset =  -32/256 }, 
					{ keyPercent = 225/256, offset =  -79/256 }, 
					{ keyPercent = 256/256, offset = -168/256 }, 
				}
			},
	
		UsePowerForeground = true,
			PowerForegroundPlace = { "BOTTOM", 7, -51 }, 
			PowerForegroundSize = { 198,98 }, 
			PowerForegroundTexture = GetMedia("pw_crystal_case"), 
			PowerForegroundDrawLayer = { "ARTWORK", 1 },

		UsePowerValue = true, 
			PowerValuePlace = { "CENTER", 0, -16 },
			PowerValueDrawLayer = { "OVERLAY", 1 },
			PowerValueJustifyH = "CENTER", 
			PowerValueJustifyV = "MIDDLE", 
			PowerValueFont = GetFont(18, true),
			PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

		UseWinterVeilPower = true, 
			WinterVeilPowerSize = { 120 / ((255-50*2)/255), 140 / ((255-37*2)/255) },
			WinterVeilPowerPlace = { "CENTER", -2, 24 },
			WinterVeilPowerTexture = GetMedia("seasonal_winterveil_crystal"), 
			WinterVeilPowerDrawLayer = { "OVERLAY", 0 },
			WinterVeilPowerColor = { 1, 1, 1 }, 
			--WinterVeilPowerColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 

	UseManaText = true,
		ManaTextParent = "Power", 
		ManaTextPlace = { "CENTER", 1, -32 },
		ManaTextDrawLayer = { "OVERLAY", 1 },
		ManaTextJustifyH = "CENTER", 
		ManaTextJustifyV = "MIDDLE", 
		ManaTextFont = GetFont(14, true),
		ManaTextColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
		ManaTextOverride = function(element, unit, min, max)
			if (min == 0) or (max == 0) or (min == max) then
				element:SetText("")
			else
				element:SetFormattedText("%.0f", math_floor(min/max * 100))
			end 
		end,

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "RIGHT",
		CastBarDisableSmoothing =  true, 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .25 }, 
		CastBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		CastBarPostUpdate = PlayerFrame_CastBarPostUpdate,

		UseCastBarName = true, 
			CastBarNameParent = "Health",
			CastBarNamePlace = { "LEFT", 27, 4 },
			CastBarNameSize = { 250, 40 }, 
			CastBarNameFont = GetFont(18, true),
			CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
			CastBarNameDrawLayer = { "OVERLAY", 1 }, 
			CastBarNameJustifyH = "LEFT", 
			CastBarNameJustifyV = "MIDDLE",

		UseCastBarValue = true, 
			CastBarValueParent = "Health",
			CastBarValuePlace = { "RIGHT", -27, 4 },
			CastBarValueDrawLayer = { "OVERLAY", 1 },
			CastBarValueJustifyH = "CENTER",
			CastBarValueJustifyV = "MIDDLE",
			CastBarValueFont = GetFont(18, true),
			CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UseCombatIndicator = true, 
		CombatIndicatorPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 - 80/2) },
		CombatIndicatorSize = { 80,80 },
		CombatIndicatorTexture = GetMedia("icon-combat"),
		CombatIndicatorDrawLayer = {"OVERLAY", -2 },
		CombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
		UseCombatIndicatorGlow = false, 

		UseLoveCombatIndicator = true, 
			LoveCombatIndicatorPlace = { "BOTTOMLEFT", -(41 + 48/2 -4), (22 - 48/2 +4) },
			LoveCombatIndicatorSize = { 48,48 },
			LoveCombatIndicatorTexture = GetMedia("icon-heart-red"),
			LoveCombatIndicatorDrawLayer = {"OVERLAY", -2 },
			LoveCombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
		
	UseThreat = true,
		ThreatHideSolo = true, 
		ThreatFadeOut = 3, 

		UseHealthThreat = true, 
			ThreatHealthPlace = { "CENTER", 1, -1 },
			ThreatHealthSize = { 716, 188 },
			ThreatHealthDrawLayer = { "BACKGROUND", -2 },
			ThreatHealthAlpha = .75, 

		UsePowerThreat = true, 
			ThreatPowerPlace = { "CENTER", 0, 0 }, 
			ThreatPowerSize = { 120/157*256, 140/183*256 },
			ThreatPowerTexture = GetMedia("power_crystal_glow"),
			ThreatPowerDrawLayer = { "BACKGROUND", -2 },
			ThreatPowerAlpha = .75,

		UsePowerBgThreat = true, 
			ThreatPowerBgPlace = { "BOTTOM", 7, -51 }, 
			ThreatPowerBgSize = { 198,98 },
			ThreatPowerBgTexture = GetMedia("pw_crystal_case_glow"),
			ThreatPowerBgDrawLayer = { "BACKGROUND", -3 },
			ThreatPowerBgAlpha = .75,

		UseManaThreat = true, 
			ThreatManaPlace = { "CENTER", 0, 0 }, 
			ThreatManaSize = { 188, 188 },
			ThreatManaTexture = GetMedia("orb_case_glow"),
			ThreatManaDrawLayer = { "BACKGROUND", -2 },
			ThreatManaAlpha = .75,

	UseMana = true, 
		ManaType = "Orb",
		ManaExclusiveResource = "MANA", 
		ManaPlace = { "BOTTOMLEFT", -97 +5, 22 + 5 }, 
		ManaSize = { 103, 103 },
		ManaOrbTextures = { GetMedia("pw_orb_bar4"), GetMedia("pw_orb_bar3"), GetMedia("pw_orb_bar3") },
		ManaColorSuffix = "_ORB", 

		UseManaBackground = true, 
			ManaBackgroundPlace = { "CENTER", 0, 0 }, 
			ManaBackgroundSize = { 113, 113 }, 
			ManaBackgroundTexture = GetMedia("pw_orb_bar3"),
			ManaBackgroundDrawLayer = { "BACKGROUND", -2 }, 
			ManaBackgroundColor = { 22/255, 26/255, 22/255, .82 },

		UseManaShade = true, 
			ManaShadePlace = { "CENTER", 0, 0 }, 
			ManaShadeSize = { 127, 127 }, 
			ManaShadeTexture = GetMedia("shade_circle"), 
			ManaShadeDrawLayer = { "BORDER", -1 }, 
			ManaShadeColor = { 0, 0, 1, 1 }, 

		UseManaForeground = true, 
			ManaForegroundPlace = { "CENTER", 0, 0 }, 
			ManaForegroundSize = { 188, 188 }, 
			ManaForegroundDrawLayer = { "BORDER", 1 },

		UseManaValue = true, 
			ManaValuePlace = { "CENTER", 3, 0 },
			ManaValueDrawLayer = { "OVERLAY", 1 },
			ManaValueJustifyH = "CENTER", 
			ManaValueJustifyV = "MIDDLE", 
			ManaValueFont = GetFont(18, true),
			ManaValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

		UseWinterVeilMana = true, 
			WinterVeilManaSize = { 188, 188 },
			WinterVeilManaPlace = { "CENTER", 0, 0 },
			WinterVeilManaTexture = GetMedia("seasonal_winterveil_orb"), 
			WinterVeilManaDrawLayer = { "OVERLAY", 0 },
			WinterVeilManaColor = { 1, 1, 1 }, 
			--WinterVeilManaColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

	UseAuras = true,
		AuraSize = 40, -- aurasize
		AuraSpaceH = 6, -- horizontal spacing between auras
		AuraSpaceV = 6, -- vertical spacing between auras
		AuraMax = 8, -- max number of auras
		AuraMaxBuffs = nil, -- max number of buffs
		AuraMaxDebuffs = 3, -- max number of debuffs
		AuraDebuffsFirst = true, -- display debuffs before buffs
		AuraGrowthX = "RIGHT", -- horizontal growth of auras
		AuraGrowthY = "UP", -- vertical growth of auras
		AuraFilter = nil, -- general aura filter, only used if the below aren't here
		AuraBuffFilter = "HELPFUL", -- buff specific filter passed to blizzard API calls
		AuraDebuffFilter = "HARMFUL", -- debuff specific filter passed to blizzard API calls
		AuraFilterFunc = nil, -- general aura filter function, called when the below aren't there
		BuffFilterFunc = GetAuraFilterFunc("player"), -- buff specific filter function
		DebuffFilterFunc = GetAuraFilterFunc("player"), -- debuff specific filter function
		--BuffFilterFunc = function() return true end, -- buff specific filter function
		--DebuffFilterFunc = function() return true end, -- debuff specific filter function
		AuraFrameSize = { 40*8 + 6*7, 40 },
		AuraFramePlace = { "BOTTOMLEFT", 27 + 10, 27 + 24 + 40 },
		AuraTooltipDefaultPosition = nil,
		AuraTooltipPoint = "BOTTOMLEFT",
		AuraTooltipAnchor = nil,
		AuraTooltipRelPoint = "TOPLEFT",
		AuraTooltipOffsetX = 8,
		AuraTooltipOffsetY = 16,
		ShowAuraCooldownSpirals = false, -- show cooldown spirals on auras
		ShowAuraCooldownTime = true, -- show time text on auras
		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 40 - 6, 40 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = GetFont(14, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 }, -- { "CENTER", 0, 0 },
		AuraTimeFont = GetFont(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

	UseProgressiveFrames = true,
		UseProgressiveHealthThreat = true, 
		UseProgressiveManaForeground = true, 

		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = GetMedia("hp_cap_bar"),
		SeasonedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedHealthBackdropTexture = GetMedia("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatTexture = GetMedia("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = GetMedia("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = GetMedia("hp_cap_bar_highlight"),
		SeasonedManaOrbTexture = GetMedia("orb_case_hi"),
		SeasonedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		
		HardenedLevel = 40,
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = GetMedia("hp_lowmid_bar"),
		HardenedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedHealthBackdropTexture = GetMedia("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatTexture = GetMedia("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = GetMedia("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = GetMedia("hp_lowmid_bar"),
		HardenedManaOrbTexture = GetMedia("orb_case_hi"),
		HardenedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = GetMedia("hp_lowmid_bar"),
		NoviceHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NoviceHealthBackdropTexture = GetMedia("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatTexture = GetMedia("hp_low_case_glow"),
		NovicePowerForegroundTexture = GetMedia("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = GetMedia("hp_lowmid_bar"),
		NoviceManaOrbTexture = GetMedia("orb_case_low"),
		NoviceManaOrbColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },

}

-- PlayerHUD (combo points and castbar)
local UnitFramePlayerHUD = {
	Colors = Colors,

	Size = { 103, 103 }, 
	Place = { "BOTTOMLEFT", 75, 127 },
	IgnoreMouseOver = true,  

	UseCastBar = true,
		CastBarPlace = { "CENTER", "UICenter", "CENTER", 0, -133 }, 
		CastBarSize = Constant.SmallBar,
		CastBarTexture = Constant.SmallBarTexture, 
		CastBarColor = { 70/255, 255/255, 131/255, .69 }, 
		CastBarOrientation = "RIGHT",
		CastTimeToHoldFailed = .5, 
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},

		UseCastBarBackground = true, 
			CastBarBackgroundPlace = { "CENTER", 1, -1 }, 
			CastBarBackgroundSize = { 193,93 },
			CastBarBackgroundTexture = GetMedia("cast_back"), 
			CastBarBackgroundDrawLayer = { "BACKGROUND", 1 },
			CastBarBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			
		UseCastBarValue = true, 
			CastBarValuePlace = { "CENTER", 0, 0 },
			CastBarValueFont = GetFont(14, true),
			CastBarValueDrawLayer = { "OVERLAY", 1 },
			CastBarValueJustifyH = "CENTER",
			CastBarValueJustifyV = "MIDDLE",
			CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UseCastBarName = true, 
			CastBarNamePlace = { "TOP", 0, -(12 + 14) },
			CastBarNameFont = GetFont(15, true),
			CastBarNameDrawLayer = { "OVERLAY", 1 },
			CastBarNameJustifyH = "CENTER",
			CastBarNameJustifyV = "MIDDLE",
			CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UseCastBarShield = true, 
			CastBarShieldPlace = { "CENTER", 1, -2 }, 
			CastBarShieldSize = { 193, 93 },
			CastBarShieldTexture = GetMedia("cast_back_spiked"), 
			CastBarShieldDrawLayer = { "BACKGROUND", 1 }, 
			CastBarShieldColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			CastShieldHideBgWhenShielded = true, 

		UseCastBarSpellQueue = true, 
			CastBarSpellQueuePlace = { "CENTER", "UICenter", "CENTER", 0, -133 }, 
			CastBarSpellQueueSize = Constant.SmallBar,
			CastBarSpellQueueTexture = Constant.SmallBarTexture, 
			CastBarSpellQueueColor = { 1, 1, 1, .5 },
			CastBarSpellQueueOrientation = "LEFT",
			CastBarSpellQueueSparkMap = {
				top = {
					{ keyPercent =   0/128, offset = -16/32 }, 
					{ keyPercent =  10/128, offset =   0/32 }, 
					{ keyPercent = 119/128, offset =   0/32 }, 
					{ keyPercent = 128/128, offset = -16/32 }
				},
				bottom = {
					{ keyPercent =   0/128, offset = -16/32 }, 
					{ keyPercent =  10/128, offset =   0/32 }, 
					{ keyPercent = 119/128, offset =   0/32 }, 
					{ keyPercent = 128/128, offset = -16/32 }
				}
			},

	UseClassPower = not CogWheel("LibModule"):IsAddOnEnabled("SimpleClassPower"), 
		ClassPowerPlace = { "CENTER", "UICenter", "CENTER", 0, 0 }, 
		ClassPowerSize = { 2,2 }, 
		ClassPowerHideWhenUnattackable = true, 
		ClassPowerMaxComboPoints = 5, 
		ClassPowerHideWhenNoTarget = true, 
		ClassPowerAlphaWhenEmpty = .5, 
		ClassPowerAlphaWhenOutOfCombat = 1,
		ClassPowerAlphaWhenOutOfCombatRunes = .5, 
		ClassPowerReverseSides = false, 
		ClassPowerRuneSortOrder = "ASC",

		ClassPowerPostCreatePoint = function(element, id, point)
			point.case = point:CreateTexture()
			point.case:SetDrawLayer("BACKGROUND", -2)
			point.case:SetVertexColor(211/255, 200/255, 169/255)

			point.slotTexture:SetPoint("TOPLEFT", -1.5, 1.5)
			point.slotTexture:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
			point.slotTexture:SetVertexColor(130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3)

			point:SetOrientation("UP") -- set the bars to grow from bottom to top.
			point:SetSparkTexture(GetMedia("blank")) -- this will be too tricky to rotate and map
			
		end,

		ClassPowerPostUpdate = function(element, unit, min, max, newMax, powerType)

			--	Class Powers available in Legion/BfA: 
			--------------------------------------------------------------------------------- 
			-- 	* Arcane Charges 	Generated points. 5 cap. 0 baseline.
			--	* Chi: 				Generated points. 5 cap, 6 if talented, 0 baseline.
			--	* Combo Points: 	Fast generated points. 5 cap, 6-10 if talented, 0 baseline.
			--	* Holy Power: 		Fast generated points. 5 cap, 0 baseline.
			--	* Soul Shards: 		Slowly generated points. 5 cap, 1 point baseline.
			--	* Stagger: 			Generated points. 3 cap. 3 baseline. 
			--	* Runes: 			Fast refilling points. 6 cap, 6 baseline.
		
			local style
		
			-- 5 points: 4 circles, 1 larger crystal
			if (powerType == "COMBO_POINTS") then 
				style = "ComboPoints"
		
			-- 5 points: 5 circles, center one larger
			elseif (powerType == "CHI") then
				style = "Chi"
		
			--5 points: 3 circles, 3 crystals, last crystal larger
			elseif (powerType == "ARCANE_CHARGES") or (powerType == "HOLY_POWER") or (powerType == "SOUL_SHARDS") then 
				style = "SoulShards"
		
			-- 3 points: 
			elseif (powerType == "STAGGER") then 
				style = "Stagger"
		
			-- 6 points: 
			elseif (powerType == "RUNES") then 
				style = "Runes"
			end 
		
			-- For my own reference, these are properly sized and aligned so far:
			-- yes 	ComboPoints 
			-- no 	Chi
			-- yes 	SoulShards (also ArcaneCharges, HolyPower)
			-- no 	Stagger
			-- no 	Runes
		
			-- Do we need to set or update the textures?
			if (style ~= element.powerStyle) then 
		
				local posMod = element.flipSide and -1 or 1
		
				if (style == "ComboPoints") then
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(GetMedia("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMedia("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMedia("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMedia("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMedia("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMedia("point_plate"))
		
					point3:SetPoint("CENTER", -231*posMod,-79)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(GetMedia("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(4*posMod))
					point3.slotTexture:SetTexture(GetMedia("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetTexture(GetMedia("point_plate"))
				
					point4:SetPoint("CENTER", -225*posMod,-44)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(GetMedia("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(GetMedia("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMedia("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(GetMedia("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(GetMedia("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(GetMedia("point_diamond"))
		
				elseif (style == "Chi") then
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(GetMedia("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMedia("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMedia("point_plate"))
		
					point2:SetPoint("CENTER", -223*posMod,-109)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMedia("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMedia("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMedia("point_plate"))
		
					point3:SetPoint("CENTER", -234*posMod,-73)
					point3:SetSize(39,40)
					point3:SetStatusBarTexture(GetMedia("point_hearth"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMedia("point_hearth"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(80,80)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMedia("point_plate"))
				
					point4:SetPoint("CENTER", -221*posMod,-36)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(GetMedia("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(0)
					point4.slotTexture:SetTexture(GetMedia("point_crystal"))
					point4.slotTexture:SetRotation(0)
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMedia("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-9)
					point5:SetSize(13,13)
					point5:SetStatusBarTexture(GetMedia("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(0)
					point5.slotTexture:SetTexture(GetMedia("point_crystal"))
					point5.slotTexture:SetRotation(0)
					point5.case:SetPoint("CENTER",0, 0)
					point5.case:SetSize(60,60)
					point5.case:SetRotation(0)
					point5.case:SetTexture(GetMedia("point_plate"))
		
				elseif (style == "SoulShards") then 
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(12,12)
					point1:SetStatusBarTexture(GetMedia("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMedia("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(54,54)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMedia("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMedia("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMedia("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMedia("point_plate"))
		
					point3:SetPoint("CENTER", -235*posMod,-80)
					point3:SetSize(11,15)
					point3:SetStatusBarTexture(GetMedia("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point3.slotTexture:SetTexture(GetMedia("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetPoint("CENTER",0,0)
					point3.case:SetSize(65,60)
					point3.case:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetTexture(GetMedia("point_diamond"))
				
					point4:SetPoint("CENTER", -227*posMod,-44)
					point4:SetSize(12,18)
					point4:SetStatusBarTexture(GetMedia("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(GetMedia("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER",0,0)
					point4.case:SetSize(78,79)
					point4.case:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetTexture(GetMedia("point_diamond"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(GetMedia("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(GetMedia("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(GetMedia("point_diamond"))
		
		
					-- 1.414213562
				elseif (style == "Stagger") then 
					local point1, point2, point3 = element[1], element[2], element[3]
		
					point1:SetPoint("CENTER", -223*posMod,-109)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(GetMedia("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point1.slotTexture:SetTexture(GetMedia("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(60,60)
					point1.case:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetTexture(GetMedia("point_plate"))
		
					point2:SetPoint("CENTER", -234*posMod,-73)
					point2:SetSize(39,40)
					point2:SetStatusBarTexture(GetMedia("point_hearth"))
					point2:GetStatusBarTexture():SetRotation(0)
					point2.slotTexture:SetTexture(GetMedia("point_hearth"))
					point2.slotTexture:SetRotation(0)
					point2.case:SetPoint("CENTER", 0,0)
					point2.case:SetSize(80,80)
					point2.case:SetRotation(0)
					point2.case:SetTexture(GetMedia("point_plate"))
				
					point3:SetPoint("CENTER", -221*posMod,-36)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(GetMedia("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMedia("point_crystal"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0, 0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMedia("point_plate"))
		
		
				elseif (style == "Runes") then 
					local point1, point2, point3, point4, point5, point6 = element[1], element[2], element[3], element[4], element[5], element[6]
		
					point1:SetPoint("CENTER", -203*posMod,-131)
					point1:SetSize(28,28)
					point1:SetStatusBarTexture(GetMedia("point_rune2"))
					point1:GetStatusBarTexture():SetRotation(0)
					point1.slotTexture:SetTexture(GetMedia("point_rune2"))
					point1.slotTexture:SetRotation(0)
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(0)
					point1.case:SetTexture(GetMedia("point_dk_block"))
		
					point2:SetPoint("CENTER", -227*posMod,-107)
					point2:SetSize(28,28)
					point2:SetStatusBarTexture(GetMedia("point_rune4"))
					point2:GetStatusBarTexture():SetRotation(0)
					point2.slotTexture:SetTexture(GetMedia("point_rune4"))
					point2.slotTexture:SetRotation(0)
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(68,68)
					point2.case:SetRotation(0)
					point2.case:SetTexture(GetMedia("point_dk_block"))
		
					point3:SetPoint("CENTER", -253*posMod,-83)
					point3:SetSize(30,30)
					point3:SetStatusBarTexture(GetMedia("point_rune1"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMedia("point_rune1"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(74,74)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMedia("point_dk_block"))
				
					point4:SetPoint("CENTER", -220*posMod,-64)
					point4:SetSize(28,28)
					point4:SetStatusBarTexture(GetMedia("point_rune3"))
					point4:GetStatusBarTexture():SetRotation(0)
					point4.slotTexture:SetTexture(GetMedia("point_rune3"))
					point4.slotTexture:SetRotation(0)
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(68,68)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMedia("point_dk_block"))
		
					point5:SetPoint("CENTER", -246*posMod,-38)
					point5:SetSize(32,32)
					point5:SetStatusBarTexture(GetMedia("point_rune2"))
					point5:GetStatusBarTexture():SetRotation(0)
					point5.slotTexture:SetTexture(GetMedia("point_rune2"))
					point5.slotTexture:SetRotation(0)
					point5.case:SetPoint("CENTER", 0, 0)
					point5.case:SetSize(78,78)
					point5.case:SetRotation(0)
					point5.case:SetTexture(GetMedia("point_dk_block"))
		
					point6:SetPoint("CENTER", -214*posMod,-10)
					point6:SetSize(40,40)
					point6:SetStatusBarTexture(GetMedia("point_rune1"))
					point6:GetStatusBarTexture():SetRotation(0)
					point6.slotTexture:SetTexture(GetMedia("point_rune1"))
					point6.slotTexture:SetRotation(0)
					point6.case:SetPoint("CENTER", 0, 0)
					point6.case:SetSize(98,98)
					point6.case:SetRotation(0)
					point6.case:SetTexture(GetMedia("point_dk_block"))
		
				end 
		
				-- Store the element's full stylestring
				element.powerStyle = style
			end 
		end, 

	UsePlayerAltPowerBar = true,
		PlayerAltPowerBarPlace = { "CENTER", "UICenter", "CENTER", 0, -(133 + 56)  }, 
		PlayerAltPowerBarSize = Constant.SmallBar,
		PlayerAltPowerBarTexture = Constant.SmallBarTexture, 
		PlayerAltPowerBarColor = { Colors.power.ALTERNATE[1], Colors.power.ALTERNATE[2], Colors.power.ALTERNATE[3], .69 }, 
		PlayerAltPowerBarOrientation = "RIGHT",
		PlayerAltPowerBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},

		UsePlayerAltPowerBarBackground = true, 
			PlayerAltPowerBarBackgroundPlace = { "CENTER", 1, -2 }, 
			PlayerAltPowerBarBackgroundSize = { 193,93 },
			PlayerAltPowerBarBackgroundTexture = GetMedia("cast_back"), 
			PlayerAltPowerBarBackgroundDrawLayer = { "BACKGROUND", 1 },
			PlayerAltPowerBarBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			
		UsePlayerAltPowerBarValue = true, 
			PlayerAltPowerBarValuePlace = { "CENTER", 0, 0 },
			PlayerAltPowerBarValueFont = GetFont(14, true),
			PlayerAltPowerBarValueDrawLayer = { "OVERLAY", 1 },
			PlayerAltPowerBarValueJustifyH = "CENTER",
			PlayerAltPowerBarValueJustifyV = "MIDDLE",
			PlayerAltPowerBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UsePlayerAltPowerBarName = true, 
			PlayerAltPowerBarNamePlace = { "TOP", 0, -(12 + 14) },
			PlayerAltPowerBarNameFont = GetFont(15, true),
			PlayerAltPowerBarNameDrawLayer = { "OVERLAY", 1 },
			PlayerAltPowerBarNameJustifyH = "CENTER",
			PlayerAltPowerBarNameJustifyV = "MIDDLE",
			PlayerAltPowerBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

}

-- Target
local UnitFrameTarget = { 
	Colors = Colors,

	Place = { "TOPRIGHT", -153, -79 },
	Size = { 439, 93 },
	HitRectInsets = { 0, -80, -30, 0 }, 
	
	HealthPlace = { "TOPRIGHT", 27, 27 },
		HealthSize = nil, 
		HealthType = "StatusBar", -- health type
		HealthBarTexture = nil, -- only called when non-progressive frames are used
		HealthBarOrientation = "LEFT", -- bar orientation
		HealthBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HealthBarSetFlippedHorizontally = true, 
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthColorTapped = true, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorThreat = true, 
			HealthThreatFeedbackUnit = "player",
			HealthThreatHideSolo = false, 
		HealthColorHealth = false, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

	UseHealthBackdrop = true,
		HealthBackdropPlace = { "CENTER", 1, -.5 },
		HealthBackdropSize = { 716, 188 },
		HealthBackdropTexCoord = { 1, 0, 0, 1 }, 
		HealthBackdropDrawLayer = { "BACKGROUND", -1 },

	UseHealthValue = true, 
		HealthValuePlace = { "RIGHT", -27, 4 },
		HealthValueDrawLayer = { "OVERLAY", 1 },
		HealthValueJustifyH = "CENTER", 
		HealthValueJustifyV = "MIDDLE", 
		HealthValueFont = GetFont(18, true),
		HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
		
	UseHealthPercent = true, 
		HealthPercentPlace = { "LEFT", 27, 4 },
		HealthPercentDrawLayer = { "OVERLAY", 1 },
		HealthPercentJustifyH = "CENTER",
		HealthPercentJustifyV = "MIDDLE",
		HealthPercentFont = GetFont(18, true),
		HealthPercentColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },


		UseAbsorbValue = true, 
			AbsorbValuePlaceFunction = function(self) return "RIGHT", self.Health.Value, "LEFT", -13, 0 end, 
			AbsorbValueDrawLayer = { "OVERLAY", 1 }, 
			AbsorbValueFont = GetFont(18, true),
			AbsorbValueJustifyH = "CENTER", 
			AbsorbValueJustifyV = "MIDDLE",
			AbsorbValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UsePowerBar = true,
		PowerVisibilityFilter = function(element, unit) 
			if UnitIsDeadOrGhost(unit) then 
				return false 
			end 
			if (UnitIsPlayer(unit) and (IsInGroup() or IsInInstance())) then 
				return true 
			end 
			local unitLevel = UnitLevel(unit)
			local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
			if (unitClassification == "boss") or (unitClassification == "worldboss") then 
				return true
			end 
		end,

		PowerInOverlay = true, 
		PowerPlace ={ "CENTER", 439/2 + 79 +2, 93/2 -62 + 4 +6 }, 
		PowerSize = { 68, 68 },
		PowerType = "StatusBar", 
		PowerBarSparkTexture = GetMedia("blank"),
		PowerBarTexture = GetMedia("power_crystal_small_front"),
		PowerBarTexCoord = { 1, 0, 0, 1 },
		PowerBarOrientation = "UP",
		PowerBarSetFlippedHorizontally = true, 
		PowerBarSmoothingMode = "bezier-fast-in-slow-out",
		PowerBarSmoothingFrequency = .5,
		PowerColorSuffix = "_CRYSTAL", 
		PowerHideWhenEmpty = true,
		PowerHideWhenDead = true,  
		PowerIgnoredResource = nil,
		PowerShowAlternate = true, 
	
		UsePowerBackground = true,
			PowerBackgroundPlace = { "CENTER", 0, 0 },
			PowerBackgroundSize = { 68, 68 },
			PowerBackgroundTexture = GetMedia("power_crystal_small_back"),
			PowerBackgroundTexCoord = { 1, 0, 0, 1 },
			PowerBackgroundDrawLayer = { "BACKGROUND", -2 },
			PowerBackgroundColor = { 1, 1, 1, .85 },

		UsePowerValue = true, 
			PowerValueOverride = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
				local value = element.Value
				if (min == 0 or max == 0) and (not value.showAtZero) then
					value:SetText("")
				else
					value:SetFormattedText("%.0f", math_floor(min/max * 100))
				end 
			end,
			PowerValuePlace = { "CENTER", 0, -5 },
			PowerValueDrawLayer = { "OVERLAY", 1 },
			PowerValueJustifyH = "CENTER", 
			PowerValueJustifyV = "MIDDLE", 
			PowerValueFont = GetFont(13, true),
			PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UsePortrait = true, 
		PortraitPlace = { "TOPRIGHT", 73, 8 },
		PortraitSize = { 85, 85 }, 
		PortraitAlpha = .85, 
		PortraitDistanceScale = 1,
		PortraitPositionX = 0,
		PortraitPositionY = 0,
		PortraitPositionZ = 0,
		PortraitRotation = 0, -- in degrees
		PortraitShowFallback2D = true, -- display 2D portraits when unit is out of range of 3D models

		UsePortraitBackground = true, 
			PortraitBackgroundPlace = { "TOPRIGHT", 116, 55 },
			PortraitBackgroundSize = { 173, 173 },
			PortraitBackgroundTexture = GetMedia("party_portrait_back"), 
			PortraitBackgroundDrawLayer = { "BACKGROUND", 0 }, 
			PortraitBackgroundColor = { .5, .5, .5 }, 

		UsePortraitShade = true, 
			PortraitShadePlace = { "TOPRIGHT", 83, 21 },
			PortraitShadeSize = { 107, 107 }, 
			PortraitShadeTexture = GetMedia("shade_circle"),
			PortraitShadeDrawLayer = { "BACKGROUND", -1 },

		UsePortraitForeground = true, 
			PortraitForegroundPlace = { "TOPRIGHT", 123, 61 },
			PortraitForegroundSize = { 187, 187 },
			PortraitForegroundDrawLayer = { "BACKGROUND", 0 },

	UseTargetIndicator = true, 
		TargetIndicatorYouByFriendPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByFriendSize = { 96, 48 },
		TargetIndicatorYouByFriendTexture = GetMedia("icon_target_green"),
		TargetIndicatorYouByFriendColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorYouByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByEnemySize = { 96, 48 },
		TargetIndicatorYouByEnemyTexture = GetMedia("icon_target_red"),
		TargetIndicatorYouByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorPetByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorPetByEnemySize = { 96, 48 },
		TargetIndicatorPetByEnemyTexture = GetMedia("icon_target_blue"),
		TargetIndicatorPetByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		UseLoveTargetIndicator = true, 
			LoveTargetIndicatorYouByFriendPlace = { "TOPRIGHT", -10 + 50/2 + 4, 12 + 50/2 -4 },
			LoveTargetIndicatorYouByFriendSize = { 48,48 },
			LoveTargetIndicatorYouByFriendTexture = GetMedia("icon-heart-green"),
			LoveTargetIndicatorYouByFriendColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

			LoveTargetIndicatorYouByEnemyPlace = { "TOPRIGHT", -10 + 50/2 + 4, 12 + 50/2 -4 },
			LoveTargetIndicatorYouByEnemySize = { 48,48 },
			LoveTargetIndicatorYouByEnemyTexture = GetMedia("icon-heart-red"),
			LoveTargetIndicatorYouByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

			LoveTargetIndicatorPetByEnemyPlace = { "TOPRIGHT", -10 + 50/2 + 4, 12 + 50/2 -4 },
			LoveTargetIndicatorPetByEnemySize = { 48,48 },
			LoveTargetIndicatorPetByEnemyTexture = GetMedia("icon-heart-blue"),
			LoveTargetIndicatorPetByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },


	UseClassificationIndicator = true, 
		ClassificationPlace = { "BOTTOMRIGHT", 72, -43 },
		ClassificationSize = { 84, 84 },
		ClassificationColor = { 1, 1, 1 },
		ClassificationIndicatorAllianceTexture = GetMedia("icon_badges_alliance"),
		ClassificationIndicatorHordeTexture = GetMedia("icon_badges_horde"),
		ClassificationIndicatorBossTexture = GetMedia("icon_badges_boss"),
		ClassificationIndicatorEliteTexture = GetMedia("icon_classification_elite"),
		ClassificationIndicatorRareTexture = GetMedia("icon_classification_rare"),

	UseLevel = true, 
		LevelVisibilityFilter = function(element, unit) 
			if UnitIsDeadOrGhost(unit) then 
				return false 
			end 
			if (UnitIsPlayer(unit) and (IsInGroup() or IsInInstance())) then 
				return false
			end 
			local unitLevel = UnitLevel(unit)
			local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
			if (unitClassification == "boss") or (unitClassification == "worldboss") then 
				return false
			end 
			return true
		end,

		LevelPlace = { "CENTER", 298, -15 }, 
		LevelDrawLayer = { "BORDER", 1 },
		LevelJustifyH = "CENTER",
		LevelJustifyV = "MIDDLE", 
		LevelFont = GetFont(13, true),
		LevelHideCapped = true, 
		LevelHideFloored = true, 
		LevelColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3] },
		LevelAlpha = .7,

		UseLevelBadge = true, 
			LevelBadgeSize = { 86, 86 }, 
			LevelBadgeTexture = GetMedia("point_plate"),
			LevelBadgeDrawLayer = { "BACKGROUND", 1 },
			LevelBadgeColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		UseLevelSkull = true, 
			LevelSkullSize = { 64, 64 }, 
			LevelSkullTexture = GetMedia("icon_skull"),
			LevelSkullDrawLayer = { "BORDER", 2 }, 
			LevelSkullColor = { 1, 1, 1, 1 }, 

		UseLevelDeadSkull = true, 
			LevelDeadSkullSize = { 64, 64 }, 
			LevelDeadSkullTexture = GetMedia("icon_skull_dead"),
			LevelDeadSkullDrawLayer = { "BORDER", 2 }, 
			LevelDeadSkullColor = { 1, 1, 1, 1 }, 

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "LEFT", 
		CastBarSetFlippedHorizontally = true, 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .25 }, 
		CastBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		CastBarPostUpdate = TargetFrame_CastBarPostUpdate,

		UseCastBarName = true, 
			CastBarNameParent = "Health",
			CastBarNamePlace = { "RIGHT", -27, 4 },
			CastBarNameSize = { 250, 40 }, 
			CastBarNameFont = GetFont(18, true),
			CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
			CastBarNameDrawLayer = { "OVERLAY", 1 }, 
			CastBarNameJustifyH = "RIGHT", 
			CastBarNameJustifyV = "MIDDLE",

		UseCastBarValue = true, 
			CastBarValueParent = "Health",
			CastBarValuePlace = { "LEFT", 27, 4 },
			CastBarValueDrawLayer = { "OVERLAY", 1 },
			CastBarValueJustifyH = "CENTER",
			CastBarValueJustifyV = "MIDDLE",
			CastBarValueFont = GetFont(18, true),
			CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
		
	UseThreat = true,
		ThreatHideSolo = true, 
		ThreatFadeOut = 3, 

		UseHealthThreat = true, 
			ThreatHealthTexCoord = { 1,0,0,1 },
			ThreatHealthDrawLayer = { "BACKGROUND", -2 },
			ThreatHealthAlpha = .75, 

		UsePortraitThreat = true, 
			ThreatPortraitPlace = { "CENTER", 0, 0 }, 
			ThreatPortraitSize = { 187, 187 },
			ThreatPortraitTexture = GetMedia("portrait_frame_glow"),
			ThreatPortraitDrawLayer = { "BACKGROUND", -2 },
			ThreatPortraitAlpha = .75,

	UseAuras = true,
		AuraSize = 40, -- aurasize
		AuraSpaceH = 6, -- horizontal spacing between auras
		AuraSpaceV = 6, -- vertical spacing between auras
		AuraMax = 7, -- max number of auras
		AuraMaxBuffs = 3, -- max number of buffs
		AuraMaxDebuffs = nil, -- max number of debuffs
		AuraDebuffsFirst = true, -- display debuffs before buffs
		AuraGrowthX = "LEFT", -- horizontal growth of auras
		AuraGrowthY = "DOWN", -- vertical growth of auras
		AuraFilter = nil, -- general aura filter, only used if the below aren't here
		AuraBuffFilter = "HELPFUL", -- buff specific filter passed to blizzard API calls
		AuraDebuffFilter = "HARMFUL", -- debuff specific filter passed to blizzard API calls
		AuraFilterFunc = nil, -- general aura filter function, called when the below aren't there
		BuffFilterFunc = GetAuraFilterFunc("target"), -- buff specific filter function
		DebuffFilterFunc = GetAuraFilterFunc("target"), -- debuff specific filter function
		AuraFrameSize = { 40*7 + 6*(7 -1), 40 },
		AuraFramePlace = { "TOPRIGHT", -(27 + 10), -(27 + 40 + 20) },
		AuraTooltipDefaultPosition = nil,
		AuraTooltipPoint = "TOPRIGHT",
		AuraTooltipAnchor = nil,
		AuraTooltipRelPoint = "BOTTOMRIGHT",
		AuraTooltipOffsetX = -8,
		AuraTooltipOffsetY = -16,
		ShowAuraCooldownSpirals = false, -- show cooldown spirals on auras
		ShowAuraCooldownTime = true, -- show time text on auras
		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 40 - 6, 40 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = GetFont(14, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 }, -- { "CENTER", 0, 0 },
		AuraTimeFont = GetFont(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 }, 

	UseName = true, 
		NamePlace = { "TOPRIGHT", -40, 18 },
		NameSize = { 250, 18 },
		NameFont = GetFont(18, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameDrawLayer = { "OVERLAY", 1 }, 
		NameJustifyH = "RIGHT", 
		NameJustifyV = "TOP",


	UseProgressiveFrames = true,
		UseProgressiveHealth = true, 
		UseProgressiveHealthBackdrop = true, 
		UseProgressiveHealthThreat = true, 
		UseProgressiveCastBar = true, 
		UseProgressiveThreat = true, 
		UseProgressivePortrait = true, 

		BossHealthPlace = { "TOPRIGHT", -27, -27 }, 
		BossHealthSize = { 533, 40 },
		BossHealthTexture = GetMedia("hp_boss_bar"),
		BossHealthSparkMap = {
			top = {
				{ keyPercent =    0/1024, offset = -24/64 }, 
				{ keyPercent =   13/1024, offset =   0/64 }, 
				{ keyPercent = 1018/1024, offset =   0/64 }, 
				{ keyPercent = 1024/1024, offset = -10/64 }
			},
			bottom = {
				{ keyPercent =    0/1024, offset = -39/64 }, 
				{ keyPercent =   13/1024, offset = -16/64 }, 
				{ keyPercent =  949/1024, offset = -16/64 }, 
				{ keyPercent =  977/1024, offset =  -1/64 }, 
				{ keyPercent =  984/1024, offset =  -2/64 }, 
				{ keyPercent = 1024/1024, offset = -52/64 }
			}
		},
		BossHealthValueVisible = true, 
		BossHealthPercentVisible = true, 
		BossHealthBackdropPlace = { "CENTER", -.5, 1 }, 
		BossHealthBackdropSize = { 694, 190 }, 
		BossHealthThreatPlace = { "CENTER", -.5, 1 }, 
		BossHealthThreatSize = { 694, 190 }, 
		BossHealthBackdropTexture = GetMedia("hp_boss_case"),
		BossHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossHealthThreatTexture = GetMedia("hp_boss_case_glow"),
		BossPowerForegroundTexture = GetMedia("pw_crystal_case"),
		BossPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossCastPlace = { "TOPRIGHT", -27, -27 }, 
		BossCastSize = { 533, 40 },
		BossCastTexture = GetMedia("hp_boss_bar"),
		BossCastSparkMap = {
			top = {
				{ keyPercent =    0/1024, offset = -24/64 }, 
				{ keyPercent =   13/1024, offset =   0/64 }, 
				{ keyPercent = 1018/1024, offset =   0/64 }, 
				{ keyPercent = 1024/1024, offset = -10/64 }
			},
			bottom = {
				{ keyPercent =    0/1024, offset = -39/64 }, 
				{ keyPercent =   13/1024, offset = -16/64 }, 
				{ keyPercent =  949/1024, offset = -16/64 }, 
				{ keyPercent =  977/1024, offset =  -1/64 }, 
				{ keyPercent =  984/1024, offset =  -2/64 }, 
				{ keyPercent = 1024/1024, offset = -52/64 }
			}
		},
		BossPortraitForegroundTexture = GetMedia("portrait_frame_hi"),
		BossPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		SeasonedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = GetMedia("hp_cap_bar"),
		SeasonedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedHealthValueVisible = true, 
		SeasonedHealthPercentVisible = false, 
		SeasonedHealthBackdropPlace = { "CENTER", -1, .5 }, 
		SeasonedHealthBackdropSize = { 716, 188 },
		SeasonedHealthBackdropTexture = GetMedia("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatPlace = { "CENTER", -1, .5  +1 }, 
		SeasonedHealthThreatSize = { 716, 188 }, 
		SeasonedHealthThreatTexture = GetMedia("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = GetMedia("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedCastPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = GetMedia("hp_cap_bar"),
		SeasonedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedPortraitForegroundTexture = GetMedia("portrait_frame_hi"),
		SeasonedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		
		HardenedLevel = 40,
		HardenedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = GetMedia("hp_lowmid_bar"),
		HardenedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedHealthValueVisible = true, 
		HardenedHealthPercentVisible = false, 
		HardenedHealthBackdropPlace = { "CENTER", -1, -.5 }, 
		HardenedHealthBackdropSize = { 716, 188 }, 
		HardenedHealthBackdropTexture = GetMedia("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		HardenedHealthThreatSize = { 716, 188 }, 
		HardenedHealthThreatTexture = GetMedia("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = GetMedia("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedCastPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = GetMedia("hp_lowmid_bar"),
		HardenedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedPortraitForegroundTexture = GetMedia("portrait_frame_hi"),
		HardenedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		NoviceHealthPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = GetMedia("hp_lowmid_bar"),
		NoviceHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NoviceHealthValueVisible = true, 
		NoviceHealthPercentVisible = false, 
		NoviceHealthBackdropPlace = { "CENTER", -1, -.5 }, 
		NoviceHealthBackdropSize = { 716, 188 }, 
		NoviceHealthBackdropTexture = GetMedia("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		NoviceHealthThreatSize = { 716, 188 }, 
		NoviceHealthThreatTexture = GetMedia("hp_low_case_glow"),
		NovicePowerForegroundTexture = GetMedia("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceCastPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = GetMedia("hp_lowmid_bar"),
		NoviceCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NovicePortraitForegroundTexture = GetMedia("portrait_frame_lo"),
		NovicePortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 

		CritterHealthPlace = { "TOPRIGHT", -24, -24 }, 
		CritterHealthSize = { 40, 36 },
		CritterHealthTexture = GetMedia("hp_critter_bar"),
		CritterHealthSparkMap = {
			top = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 14/64, offset =  -1/64 }, 
				{ keyPercent = 49/64, offset =  -1/64 }, 
				{ keyPercent = 64/64, offset = -34/64 }
			},
			bottom = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 15/64, offset =   0/64 }, 
				{ keyPercent = 32/64, offset =  -1/64 }, 
				{ keyPercent = 50/64, offset =  -4/64 }, 
				{ keyPercent = 64/64, offset = -27/64 }
			}
		},
		CritterHealthValueVisible = false, 
		CritterHealthPercentVisible = false, 
		CritterHealthBackdropPlace = { "CENTER", 0, 1 }, 
		CritterHealthBackdropSize = { 98,96 }, 
		CritterHealthBackdropTexture = GetMedia("hp_critter_case"),
		CritterHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterHealthThreatPlace = { "CENTER", 0, 1 +1 }, 
		CritterHealthThreatSize = { 98,96 }, 
		CritterHealthThreatTexture = GetMedia("hp_critter_case_glow"),
		CritterPowerForegroundTexture = GetMedia("pw_crystal_case_low"),
		CritterPowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterCastPlace = { "TOPRIGHT", -24, -24 },
		CritterCastSize = { 40, 36 },
		CritterCastTexture = GetMedia("hp_critter_bar"),
		CritterCastSparkMap = {
			top = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 14/64, offset =  -1/64 }, 
				{ keyPercent = 49/64, offset =  -1/64 }, 
				{ keyPercent = 64/64, offset = -34/64 }
			},
			bottom = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 15/64, offset =   0/64 }, 
				{ keyPercent = 32/64, offset =  -1/64 }, 
				{ keyPercent = 50/64, offset =  -4/64 }, 
				{ keyPercent = 64/64, offset = -27/64 }
			}
		},
		CritterPortraitForegroundTexture = GetMedia("portrait_frame_lo"),
		CritterPortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 

}

-- Target of Target
local UnitFrameToT = setmetatable({
	Place = { "RIGHT", "UICenter", "TOPRIGHT", -492, -96 + 6 }, -- adding 4 pixels up to avoid it covering the targetframe health percentage / cast time values

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 - 4 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "RIGHT",
		NameJustifyV = "TOP",
		NameFont = GetFont(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	HealthFrequentUpdates = true, 
	HealthColorTapped = true, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = false, -- color anything else in the default health color
	HideWhenUnitIsPlayer = true, -- hide the frame when the unit is the player
	HideWhenUnitIsTarget = true, -- hide the frame when the unit matches our target
	HideWhenTargetIsCritter = true, -- hide the frame when unit is a critter
		
}, { __index = Template_SmallFrameReversed })

-- Player Pet
local UnitFramePet = setmetatable({
	Place = { "LEFT", "UICenter", "BOTTOMLEFT", 362, 125 },

	HealthFrequentUpdates = true, 
	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = false, -- color disconnected units
	HealthColorClass = false, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = false, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

}, { __index = Template_SmallFrame })

-- Focus
local UnitFrameFocus = setmetatable({
	Place = { "RIGHT", "UICenter", "BOTTOMLEFT", 332, 270 },

	UseName = true, 
		NamePlace = { "BOTTOMLEFT", (Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 10 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "LEFT",
		NameJustifyV = "TOP",
		NameFont = GetFont(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = GetAuraFilterFunc("focus"), 
	DebuffFilterFunc = GetAuraFilterFunc("focus"), 

	HealthFrequentUpdates = true, 
	HealthColorTapped = true, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = false, -- color anything else in the default health color
	HideWhenUnitIsPlayer = false, -- hide the frame when the unit is the player, or the target
	HideWhenTargetIsCritter = false, -- hide the frame when unit is a critter

	UseUnitStatus = true, 
		UnitStatusPlace = { "CENTER", 0, 0 },
		UnitStatusDrawLayer = { "ARTWORK", 2 },
		UnitStatusJustifyH = "CENTER",
		UnitStatusJustifyV = "MIDDLE",
		UnitStatusFont = GetFont(14, true),
		UnitStatusColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		UseUnitStatusMessageOOM = L["oom"],
		UnitStatusHideAFK = true, 
		UnitStatusHideOffline = true, 
		UnitStatusHideDead = true, 
		UnitStatusSize = nil, 
		UnitStatusPostUpdate = function(element, unit) 
			local self = element._owner
			local healthValue = self.Health.Value

			if (UnitCastingInfo(unit) or UnitChannelInfo(unit)) then 
				element:Hide()
			elseif element.status then 
				element:Show()
				healthValue:Hide()
			else 
				element:Hide()
				healthValue:Show()
			end 

		end,

}, { __index = Template_SmallFrame_Auras })

------------------------------------------------------------------
-- Grouped Units
------------------------------------------------------------------
-- Boss 
local UnitFrameBoss = setmetatable({
	Place = { "TOPRIGHT", "UICenter", "RIGHT", -64, 261 }, -- Position of the initial frame
		GrowthX = 0, -- Horizontal growth per new unit
		GrowthY = -97, -- Vertical growth per new unit

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = GetFont(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = GetAuraFilterFunc("boss"), 
	DebuffFilterFunc = GetAuraFilterFunc("boss"), 

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = false, -- color disconnected units
	HealthColorClass = false, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

}, { __index = Template_SmallFrameReversed_Auras })

-- Arena 
local UnitFrameArena = setmetatable({
	Place = { "TOPRIGHT", "UICenter", "RIGHT", -64, 261 }, -- Position of the initial frame
		GrowthX = 0, -- Horizontal growth per new unit
		GrowthY = -97, -- Vertical growth per new unit

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = GetFont(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = GetAuraFilterFunc("arena"), 
	DebuffFilterFunc = GetAuraFilterFunc("arena"), 

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color
	
}, { __index = Template_SmallFrameReversed_Auras })

-- Party 
local UnitFrameParty = setmetatable({

	Size = { 130, 130 }, -- Add room for portraits
	Place = { "TOPLEFT", "UICenter", "TOPLEFT", 50, -42 }, -- Position of the initial frame
		GroupAnchor = "TOPLEFT", 
		GrowthX = 130, -- Horizontal growth per new unit
		GrowthY = 0, -- Vertical growth per new unit
	AlternatePlace = { "BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 56, 360 + 10 }, -- Position of the healermode frame
		AlternateGroupAnchor = "BOTTOMLEFT", 
		AlternateGrowthX = 140, -- Horizontal growth per new unit
		AlternateGrowthY = 0, -- Vertical growth per new unit

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

	UseUnitStatus = true, -- Prio #4
		UnitStatusPlace = { "CENTER", 0, -(7 + 100/2) },
		UnitStatusDrawLayer = { "ARTWORK", 2 },
		UnitStatusJustifyH = "CENTER",
		UnitStatusJustifyV = "MIDDLE",
		UnitStatusFont = GetFont(12, true),
		UnitStatusColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		UseUnitStatusMessageOOM = L["oom"],
		UnitStatusHideAFK = true, 
		UnitStatusHideOffline = true, 
		UnitStatusHideDead = true, 
		UnitStatusSize = nil, 
		UnitStatusPostUpdate = function(element, unit) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.GroupAura
			local rz = self.ResurrectIndicator
			local hv = self.Health.Value

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status or rz.status) then 
					element:Hide()
				end 
				hv:Hide()
			else
				hv:Show()
			end 
		end,

	UseResurrectIndicator = true, -- Prio #3
		ResurrectIndicatorPlace = { "CENTER", 0, -7 }, 
		ResurrectIndicatorSize = { 32, 32 }, 
		ResurrectIndicatorDrawLayer = { "OVERLAY", 1 },
		ResurrectIndicatorPostUpdate = function(element, unit, incomingResurrect) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.GroupAura
			local us = self.UnitStatus
			local hv = self.Health.Value

			if element:IsShown() then 
				hv:Hide()

				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status) then 
					return element:Hide()
				end 
				-- Hide lower priority element
				us:Hide()
			else
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) and (not rc.status) then 
					if (us.status) then 
						us:Show()
						hv:Hide()
					else
						hv:Show()
					end 
				end
			end 
		end,

	UseReadyCheck = true, -- Prio #2
		ReadyCheckPlace = { "CENTER", 0, -7 }, 
		ReadyCheckSize = { 32, 32 }, 
		ReadyCheckDrawLayer = { "OVERLAY", 7 },
		ReadyCheckPostUpdate = function(element, unit, status) 
			local self = element._owner

			local rd = self.GroupAura
			local rz = self.ResurrectIndicator
			local us = self.UnitStatus
			local hv = self.Health.Value

			if element:IsShown() then 
				hv:Hide()

				-- Hide if a higher priority element is visible
				if rd:IsShown() then 
					return element:Hide()
				end 
				-- Hide all lower priority elements
				rz:Hide()
				us:Hide()
			else 
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) then 
					if (rz.status) then 
						rz:Show()
						us:Hide()
						hv:Hide()
					elseif (us.status) then 
						rz:Hide()
						us:Show()
						hv:Hide()
					else 
						hv:Show()
					end 
				else 
					hv:Show()
				end 
			end 
		end,

	UseGroupAura = true, -- Prio #1
		GroupAuraSize = { 36, 36 },
		GroupAuraPlace = { "BOTTOM", 0, Constant.TinyBar[2]/2 - 36/2 -1 }, 
		GroupAuraButtonIconPlace = { "CENTER", 0, 0 },
		GroupAuraButtonIconSize = { 36 - 6, 36 - 6 },
		GroupAuraButtonIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		GroupAuraButtonCountPlace = { "BOTTOMRIGHT", 9, -6 },
		GroupAuraButtonCountFont = GetFont(12, true),
		GroupAuraButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		GroupAuraButtonTimePlace = { "CENTER", 0, 0 },
		GroupAuraButtonTimeFont = GetFont(11, true),
		GroupAuraButtonTimeColor = { 250/255, 250/255, 250/255, .85 },
		GroupAuraButtonBorderFramePlace = { "CENTER", 0, 0 }, 
		GroupAuraButtonBorderFrameSize = { 36 + 16, 36 + 16 },
		GroupAuraButtonBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 16 },
		GroupAuraButtonBorderBackdropColor = { 0, 0, 0, 0 },
		GroupAuraButtonBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },
		GroupAuraButtonDisableMouse = false, 
		GroupAuraTooltipDefaultPosition = nil, 
		--GroupAuraTooltipPoint = "BOTTOMLEFT", 
		--GroupAuraTooltipAnchor = nil, 
		--GroupAuraTooltipRelPoint = "TOPLEFT", 
		--GroupAuraTooltipOffsetX = -8, 
		--GroupAuraTooltipOffsetY = -16,

		GroupAuraPostUpdate = function(element, unit)
			local self = element._owner 

			local rz = self.ResurrectIndicator
			local rc = self.ReadyCheck
			local us = self.UnitStatus
			local hv = self.Health.Value

			if element:IsShown() then 
				-- Hide all lower priority elements
				rc:Hide()
				rz:Hide()
				us:Hide()
				hv:Hide()
			else 
				-- Display lower priority elements as needed 
				if rc.status then 
					rc:Show()
					rz:Hide()
					us:Hide()
					hv:Hide()
				elseif rz.status then 
					rc:Hide()
					rz:Show()
					us:Hide()
					hv:Hide()
				elseif us.status then 
					rc:Hide()
					rz:Hide()
					us:Show()
					hv:Hide()
				else
					hv:Show()
				end 
			end 
		end, 

	UseGroupRole = true, 
		GroupRolePlace = { "TOP", 0, 0 }, 
		GroupRoleSize = { 40, 40 }, 

		UseGroupRoleBackground = true, 
			GroupRoleBackgroundPlace = { "CENTER", 0, 0 }, 
			GroupRoleBackgroundSize = { 77, 77 }, 
			GroupRoleBackgroundDrawLayer = { "BACKGROUND", 1 }, 
			GroupRoleBackgroundTexture = GetMedia("point_plate"),
			GroupRoleBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseGroupRoleHealer = true, 
			GroupRoleHealerPlace = { "CENTER", 0, 0 }, 
			GroupRoleHealerSize = { 34, 34 },
			GroupRoleHealerTexture = GetMedia("grouprole-icons-heal"),
			GroupRoleHealerDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleTank = true, 
			GroupRoleTankPlace = { "CENTER", 0, 0 }, 
			GroupRoleTankSize = { 34, 34 },
			GroupRoleTankTexture = GetMedia("grouprole-icons-tank"),
			GroupRoleTankDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleDPS = true, 
			GroupRoleDPSPlace = { "CENTER", 0, 0 }, 
			GroupRoleDPSSize = { 34, 34 },
			GroupRoleDPSTexture = GetMedia("grouprole-icons-dps"),
			GroupRoleDPSDrawLayer = { "ARTWORK", 1 },


	UsePortrait = true, 
		PortraitPlace = { "BOTTOM", 0, 22 },
		PortraitSize = { 70, 73 }, 
		PortraitAlpha = .85, 
		PortraitDistanceScale = 1,
		PortraitPositionX = 0,
		PortraitPositionY = 0,
		PortraitPositionZ = 0,
		PortraitRotation = 0, -- in degrees
		PortraitShowFallback2D = true, -- display 2D portraits when unit is out of range of 3D models

		UsePortraitBackground = true, 
			PortraitBackgroundPlace = { "BOTTOM", 0, -6 }, 
			PortraitBackgroundSize = { 130, 130 },
			PortraitBackgroundTexture = GetMedia("party_portrait_back"), 
			PortraitBackgroundDrawLayer = { "BACKGROUND", 0 }, 
			PortraitBackgroundColor = { .5, .5, .5 }, 

		UsePortraitShade = true, 
			PortraitShadePlace = { "BOTTOM", 0, 16 },
			PortraitShadeSize = { 86, 86 }, 
			PortraitShadeTexture = GetMedia("shade_circle"),
			PortraitShadeDrawLayer = { "BACKGROUND", -1 },

		UsePortraitForeground = true, 
			PortraitForegroundPlace = { "BOTTOM", 0, -38 },
			PortraitForegroundSize = { 194, 194 },
			PortraitForegroundTexture = GetMedia("party_portrait_border"), 
			PortraitForegroundDrawLayer = { "BACKGROUND", 0 },
			PortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

	UseAuras = true, 
		AuraFrameSize = { 30*3 + 2*5, 30  }, 
		AuraFramePlace = { "BOTTOM", 0, -(30 + 16) },
		AuraSize = 30, 
		AuraSpaceH = 4, 
		AuraSpaceV = 4, 
		AuraGrowthX = "RIGHT", 
		AuraGrowthY = "DOWN", 
		AuraMax = 3, 
		AuraMaxBuffs = nil, 
		AuraMaxDebuffs = nil, 
		AuraDebuffsFirst = false, 
		ShowAuraCooldownSpirals = false, 
		ShowAuraCooldownTime = true, 
		AuraFilter = nil, 
		AuraBuffFilter = "PLAYER HELPFUL", 
		AuraDebuffFilter = "PLAYER HARMFUL", 
		AuraFilterFunc = GetAuraFilterFunc("nameplate"), 
		BuffFilterFunc = GetAuraFilterFunc("nameplate"), 
		DebuffFilterFunc = nil, 
		AuraDisableMouse = true, -- don't allow mouse input here
		AuraTooltipDefaultPosition = nil, 
		--AuraTooltipPoint = "BOTTOMLEFT", 
		--AuraTooltipAnchor = nil, 
		--AuraTooltipRelPoint = "TOPLEFT", 
		--AuraTooltipOffsetX = -8, 
		--AuraTooltipOffsetY = -16,

		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 30 - 6, 30 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = GetFont(12, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 },
		AuraTimeFont = GetFont(11, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 30 + 10, 30 + 10 },
		AuraBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 12 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },
	
}, { __index = Template_TinyFrame })

-- Use a metatable to dynamically create the colors
local spellTypeColor = setmetatable({
	["Custom"] = { 1, .9294, .7607 }, -- same color I used for "unknown" zone names (instances, bgs, contested zones on pve realms)
--	["none"] = { 0, 0, 0 }
}, { __index = function(tbl,key)
		local v = DebuffTypeColor[key]
		if v then
			tbl[key] = { v.r, v.g, v.b }
			return tbl[key]
		end
	end
})

-- Raid
local UnitFrameRaid = setmetatable({

	Size = Constant.RaidFrame, 
	Place = { "TOPLEFT", "UICenter", "TOPLEFT", 64, -42 }, -- Position of the initial frame
	AlternatePlace = { "BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64, 360 - 10 }, -- Position of the initial frame
		GroupSizeNormal = 5,
		GrowthXNormal = 0, -- Horizontal growth per new unit within a group
		GrowthYNormal = -38 - 4, -- Vertical growth per new unit within a group
		GrowthYNormalHealerMode = -(-38 - 4), -- Vertical growth per new unit within a group
		GroupGrowthXNormal = 110, 
		GroupGrowthYNormal = -(38 + 8)*5 - 10,
		GroupGrowthYNormalHealerMode = -(-(38 + 8)*5 - 10),
		GroupColsNormal = 5, 
		GroupRowsNormal = 1, 
		GroupAnchorNormal = "TOPLEFT", 
		GroupAnchorNormalHealerMode = "BOTTOMLEFT", 

		GroupSizeEpic = 8,
		GrowthXEpic = 0, 
		GrowthYEpic = -38 - 4,
		GrowthYEpicHealerMode = -(-38 - 4),
		GroupGrowthXEpic = 110, 
		GroupGrowthYEpic = -(38 + 8)*8 - 10,
		GroupGrowthYEpicHealerMode = -(-(38 + 8)*8 - 10),
		GroupColsEpic = 5, 
		GroupRowsEpic = 1, 
		GroupAnchorEpic = "TOPLEFT", 
		GroupAnchorEpicHealerMode = "BOTTOMLEFT", 

	HealthSize = Constant.RaidBar, 
		HealthBackdropSize = { 140 *.94, 90 *.94 },
		HealthColorTapped = false, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class
		HealthColorPetAsPlayer = true, -- color your pet as you 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorHealth = true, -- color anything else in the default health color
		UseHealthValue = false,

	UseName = true, 
		NamePlace = { "TOP", 0, 1 - 2 }, 
		NameDrawLayer = { "ARTWORK", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = GetFont(11, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,
		NameMaxChars = 8, 
		NameUseDots = false, 

	UseUnitStatus = true, -- Prio #4
		UnitStatusPlace = { "CENTER", 0, -7 },
		UnitStatusDrawLayer = { "ARTWORK", 2 },
		UnitStatusJustifyH = "CENTER",
		UnitStatusJustifyV = "MIDDLE",
		UnitStatusFont = GetFont(12, true),
		UnitStatusColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		UseUnitStatusMessageOOM = L["oom"],
		UnitStatusSize = nil, 
		UnitStatusPostUpdate = function(element, unit) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.GroupAura
			local rz = self.ResurrectIndicator

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status or rz.status) then 
					element:Hide()
				end 
			end 
		end,

	UseGroupRole = true, 
		GroupRolePlace = { "RIGHT", 10, -8 }, 
		GroupRoleSize = { 28, 28 }, 

		UseGroupRoleBackground = true, 
			GroupRoleBackgroundPlace = { "CENTER", 0, 0 }, 
			GroupRoleBackgroundSize = { 54, 54 }, 
			GroupRoleBackgroundDrawLayer = { "BACKGROUND", 1 }, 
			GroupRoleBackgroundTexture = GetMedia("point_plate"),
			GroupRoleBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseGroupRoleHealer = true, 
			GroupRoleHealerPlace = { "CENTER", 0, 0 }, 
			GroupRoleHealerSize = { 24, 24 },
			GroupRoleHealerTexture = GetMedia("grouprole-icons-heal"),
			GroupRoleHealerDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleTank = true, 
			GroupRoleTankPlace = { "CENTER", 0, 0 }, 
			GroupRoleTankSize = { 24, 24 },
			GroupRoleTankTexture = GetMedia("grouprole-icons-tank"),
			GroupRoleTankDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleDPS = false, 
			GroupRoleDPSPlace = { "CENTER", 0, 0 }, 
			GroupRoleDPSSize = { 24, 24 },
			GroupRoleDPSTexture = GetMedia("grouprole-icons-dps"),
			GroupRoleDPSDrawLayer = { "ARTWORK", 1 },

		GroupRolePostUpdate = function(element, unit, groupRole)
			if groupRole then 
				if groupRole == "DAMAGER" then 
					element.Bg:Hide()
				else 
					element.Bg:Show()
				end 
			end 
		end, 

	UseResurrectIndicator = true, -- Prio #3
		ResurrectIndicatorPlace = { "CENTER", 0, -7 }, 
		ResurrectIndicatorSize = { 32, 32 }, 
		ResurrectIndicatorDrawLayer = { "OVERLAY", 1 },
		ResurrectIndicatorPostUpdate = function(element, unit, incomingResurrect) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.GroupAura
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status) then 
					return element:Hide()
				end 
				-- Hide lower priority element
				us:Hide()
			else
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) and (not rc.status) then 
					if (us.status) then 
						us:Show()
					end 
				end
			end 
		end,

	UseReadyCheck = true, -- Prio #2
		ReadyCheckPlace = { "CENTER", 0, -7 }, 
		ReadyCheckSize = { 32, 32 }, 
		ReadyCheckDrawLayer = { "OVERLAY", 7 },
		ReadyCheckPostUpdate = function(element, unit, status) 
			local self = element._owner

			local rd = self.GroupAura
			local rz = self.ResurrectIndicator
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if rd:IsShown() then 
					return element:Hide()
				end 
				-- Hide all lower priority elements
				rz:Hide()
				us:Hide()
			else 
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) then 
					if (rz.status) then 
						rz:Show()
						us:Hide()
					elseif (us.status) then 
						rz:Hide()
						us:Show()
					end 
				end 
			end 
		end,

	UseRaidRole = true, 
		RaidRolePoint = "RIGHT", RaidRoleAnchor = "Name", RaidRolePlace = { "LEFT", -1, 1 }, 
		RaidRoleSize = { 16, 16 }, 
		RaidRoleDrawLayer = { "ARTWORK", 3 },
		RaidRoleRaidTargetTexture = GetMedia("raid_target_icons_small"),

	UseGroupAura = true, -- Prio #1
		GroupAuraSize = { 24, 24 },
		GroupAuraPlace = { "BOTTOM", 0, Constant.TinyBar[2]/2 - 24/2 -(1 + 2) }, 
		GroupAuraButtonIconPlace = { "CENTER", 0, 0 },
		GroupAuraButtonIconSize = { 24 - 6, 24 - 6 },
		GroupAuraButtonIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		GroupAuraButtonCountPlace = { "BOTTOMRIGHT", 9, -6 },
		GroupAuraButtonCountFont = GetFont(12, true),
		GroupAuraButtonCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		GroupAuraButtonTimePlace = { "CENTER", 0, 0 },
		GroupAuraButtonTimeFont = GetFont(11, true),
		GroupAuraButtonTimeColor = { 250/255, 250/255, 250/255, .85 },
		GroupAuraButtonBorderFramePlace = { "CENTER", 0, 0 }, 
		GroupAuraButtonBorderFrameSize = { 24 + 12, 24 + 12 },
		GroupAuraButtonBorderBackdrop = { edgeFile = GetMedia("aura_border"), edgeSize = 12 },
		GroupAuraButtonBorderBackdropColor = { 0, 0, 0, 0 },
		GroupAuraButtonBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },
		GroupAuraButtonDisableMouse = false, 
		GroupAuraTooltipDefaultPosition = nil, 
		--GroupAuraTooltipPoint = "BOTTOMLEFT", 
		--GroupAuraTooltipAnchor = nil, 
		--GroupAuraTooltipRelPoint = "TOPLEFT", 
		--GroupAuraTooltipOffsetX = -8, 
		--GroupAuraTooltipOffsetY = -16,

		GroupAuraPostUpdate = function(element, unit)
			local self = element._owner 

			local rz = self.ResurrectIndicator
			local rc = self.ReadyCheck
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide all lower priority elements
				rc:Hide()
				rz:Hide()
				us:Hide()

				-- Colorize the border
				if (element.filter == "HARMFUL") then 
					local color = element.debuffType and spellTypeColor[element.debuffType]
					if color then 
						element.Border:SetBackdropBorderColor(color[1], color[2], color[3])
					else
						element.Border:SetBackdropBorderColor(Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3)
					end
				else
					element.Border:SetBackdropBorderColor(Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3)
				end
		
			else 
				-- Display lower priority elements as needed 
				if rc.status then 
					rc:Show()
					rz:Hide()
					us:Hide()
				elseif rz.status then 
					rc:Hide()
					rz:Show()
					us:Hide()
				elseif us.status then 
					rc:Hide()
					rz:Hide()
					us:Show()
				end 
			end 
		end, 

	TargetHighlightSize = { 140 * .94, 90 *.94 },

}, { __index = Template_TinyFrame })


LibDB:NewDatabase(ADDON..":[Core]", Core)
LibDB:NewDatabase(ADDON..":[ActionBarMain]", ActionBars)
LibDB:NewDatabase(ADDON..":[Bindings]", BindMode)
LibDB:NewDatabase(ADDON..":[BlizzardChatFrames]", BlizzardChatFrames)
LibDB:NewDatabase(ADDON..":[BlizzardFloaterHUD]", BlizzardFloaterHUD)
LibDB:NewDatabase(ADDON..":[BlizzardFonts]", BlizzardFonts)
LibDB:NewDatabase(ADDON..":[BlizzardGameMenu]", BlizzardGameMenu)
LibDB:NewDatabase(ADDON..":[BlizzardMicroMenu]", BlizzardMicroMenu)
LibDB:NewDatabase(ADDON..":[BlizzardObjectivesTracker]", BlizzardObjectivesTracker)
LibDB:NewDatabase(ADDON..":[BlizzardPopupStyling]", BlizzardPopupStyling)
LibDB:NewDatabase(ADDON..":[BlizzardTimers]", BlizzardTimers)
LibDB:NewDatabase(ADDON..":[GroupTools]", GroupTools)
LibDB:NewDatabase(ADDON..":[Minimap]", Minimap)
LibDB:NewDatabase(ADDON..":[NamePlates]", NamePlates)
LibDB:NewDatabase(ADDON..":[TooltipStyling]", TooltipStyling)
LibDB:NewDatabase(ADDON..":[UnitFramePlayerHUD]", UnitFramePlayerHUD)
LibDB:NewDatabase(ADDON..":[UnitFramePlayer]", UnitFramePlayer)
LibDB:NewDatabase(ADDON..":[UnitFramePet]", UnitFramePet)
LibDB:NewDatabase(ADDON..":[UnitFrameTarget]", UnitFrameTarget)
LibDB:NewDatabase(ADDON..":[UnitFrameToT]", UnitFrameToT)
LibDB:NewDatabase(ADDON..":[UnitFrameFocus]", UnitFrameFocus)
LibDB:NewDatabase(ADDON..":[UnitFrameBoss]", UnitFrameBoss)
LibDB:NewDatabase(ADDON..":[UnitFrameArena]", UnitFrameArena)
LibDB:NewDatabase(ADDON..":[UnitFrameParty]", UnitFrameParty)
LibDB:NewDatabase(ADDON..":[UnitFrameRaid]", UnitFrameRaid)
