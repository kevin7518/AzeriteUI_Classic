local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("TooltipStyling", "LibEvent", "LibDB", "LibTooltip")
local Layout

-- Lua API
local _G = _G
local math_floor = math.floor
local tostring = tostring

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance 
local SetCVar = _G.SetCVar
local UnitReaction = _G.UnitReaction

local LEVEL = UnitLevel("player") 

-- Set defalut values for all our tooltips
-- The modules can overwrite this by adding their own settings, 
-- this is just the fallbacks to have a consistent base look.
Module.StyleTooltips = function(self)

	self:SetDefaultTooltipBackdrop(Layout.TooltipBackdrop)
	self:SetDefaultTooltipBackdropColor(unpack(Layout.TooltipBackdropColor)) 
	self:SetDefaultTooltipBackdropBorderColor(unpack(Layout.TooltipBackdropBorderColor)) 

	-- Points the backdrop is offset outwards
	-- (left, right, top, bottom)
	self:SetDefaultTooltipBackdropOffset(10, 10, 10, 14)

	-- Points the bar is moved up towards the tooltip
	self:SetDefaultTooltipStatusBarOffset(2)

	-- Points the bar is shrunk inwards the left and right sides 
	self:SetDefaultTooltipStatusBarInset(4, 4)

	-- The height of the healthbar.
	-- The bar grows from top to bottom.
	self:SetDefaultTooltipStatusBarHeight(6) 
	self:SetDefaultTooltipStatusBarHeight(6, "health") 
	self:SetDefaultTooltipStatusBarHeight(5, "power") 

	-- Use our own texture for the bars
	self:SetDefaultTooltipStatusBarTexture(Layout.TooltipStatusBarTexture)

	-- Set the default spacing between statusbars
	self:SetDefaultTooltipStatusBarSpacing(2)

	-- Default position of all tooltips.
	self:SetDefaultTooltipPosition(unpack(Layout.TooltipPlace))

	-- Set the default colors for new tooltips
	self:SetDefaultTooltipColorTable(Layout.Colors)

	-- Post update tooltips already created
	-- with some important values
	self:PostCreateTooltips()
end 

-- Add some of our own stuff to our tooltips.
-- Making this a proxy of the standard post creation method.
Module.PostCreateTooltips = function(self)
	self:ForAllTooltips(function(tooltip) 
		self:PostCreateTooltip(tooltip)
	end) 
end 

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LOGIN") then 
		self:PostCreateTooltips()
	end 
end 

Module.OnEnable = function(self)
	self:PostCreateTooltips()
	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[TooltipStyling]")

	-- This will be called by the library upon creating new tooltips.
	self.PostCreateTooltip = function(self, tooltip)

		tooltip.PostCreateLinePair = Layout.PostCreateLinePair
		tooltip.PostCreateBar = Layout.PostCreateBar

		if Layout.PostCreateTooltip then 
			Layout.PostCreateTooltip(tooltip)
		end 
	end

	
end

Module.OnInit = function(self)
	self:StyleTooltips()
end 
