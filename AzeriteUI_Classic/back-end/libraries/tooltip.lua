local LibTooltip = CogWheel:Set("LibTooltip", 52)
if (not LibTooltip) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibTooltip requires LibClientBuild to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibTooltip requires LibEvent to be loaded.")

local LibSecureHook = CogWheel("LibSecureHook")
assert(LibSecureHook, "LibTooltip requires LibSecureHook to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibTooltip requires LibFrame to be loaded.")

local LibTooltipScanner = CogWheel("LibTooltipScanner")
assert(LibTooltipScanner, "LibTooltip requires LibTooltipScanner to be loaded.")

local LibStatusBar = CogWheel("LibStatusBar")
assert(LibStatusBar, "LibTooltip requires LibStatusBar to be loaded.")

-- Embed functionality into the library
LibFrame:Embed(LibTooltip)
LibEvent:Embed(LibTooltip)
LibSecureHook:Embed(LibTooltip)

-- Lua API
local _G = _G
local assert = assert
local error = error
local getmetatable = getmetatable
local ipairs = ipairs
local math_abs = math.abs
local math_ceil = math.ceil 
local math_floor = math.floor
local pairs = pairs
local select = select 
local setmetatable = setmetatable
local string_find = string.find
local string_format = string.format
local string_gsub = string.gsub
local string_join = string.join
local string_match = string.match
local string_rep = string.rep
local string_upper = string.upper
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

-- WoW API 
local GetCVarBool = _G.GetCVarBool
local GetQuestGreenRange = _G.GetQuestGreenRange
local GetTime = _G.GetTime
local hooksecurefunc = _G.hooksecurefunc
local UnitClass = _G.UnitClass
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitReaction = _G.UnitReaction

-- Library Registries
LibTooltip.embeds = LibTooltip.embeds or {} -- modules and libs that embed this
LibTooltip.defaults = LibTooltip.defaults or {} -- global tooltip defaults (can be modified by modules)
LibTooltip.tooltips = LibTooltip.tooltips or {} -- tooltips keyed by frame handle 
LibTooltip.tooltipsByName = LibTooltip.tooltipsByName or {} -- tooltips keyed by frame name
LibTooltip.tooltipSettings = LibTooltip.tooltipSettings or {} -- per tooltip settings
LibTooltip.tooltipDefaults = LibTooltip.tooltipDefaults or {} -- per tooltip defaults
LibTooltip.visibleTooltips = LibTooltip.visibleTooltips or {} -- currently visible tooltips
LibTooltip.numTooltips = LibTooltip.numTooltips or 0 -- current number of tooltips created

-- Elements attached to Blizzard frames
LibTooltip.blizzardBackdrops = LibTooltip.blizzardBackdrops or {}

-- Inherit the template too, we override the older methods farther down anyway
LibTooltip.tooltipTemplate = LibTooltip.tooltipTemplate or LibTooltip:CreateFrame("GameTooltip", "CG_TooltipTemplate", "UICenter")

-- Shortcuts
local Defaults = LibTooltip.defaults
local Tooltips = LibTooltip.tooltips
local TooltipsByName = LibTooltip.tooltipsByName
local TooltipSettings = LibTooltip.tooltipSettings
local TooltipDefaults = LibTooltip.tooltipDefaults
local Tooltip = LibTooltip.tooltipTemplate
local Visible = LibTooltip.visibleTooltips
local Backdrops = LibTooltip.blizzardBackdrops

-- Constants we might change or make variable later on
local TEXT_INSET = 10 -- text insets from tooltip edges
local RIGHT_PADDING= 40 -- padding between left and right messages
local LINE_PADDING = 4 -- padding between lines of text

-- Fonts
local FONT_TITLE = Game15Font_o1 
local FONT_NORMAL = Game13Font_o1 -- Game12Font_o1
local FONT_VALUE = Game13Font_o1

-- Blizzard textures we use 
local BOSS_TEXTURE = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:16:16:-2:1|t"
local FFA_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-FFA:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_ALLIANCE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_NEUTRAL_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Neutral:16:12:-2:1:64:64:6:34:0:40|t"
local FACTION_HORDE_TEXTURE = "|TInterface\\TargetingFrame\\UI-PVP-Horde:16:16:-4:0:64:64:0:40:0:40|t"

-- Blizzard tooltips
local blizzardTips = {
	"GameTooltip",
	"ItemRefTooltip",
	"ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2",
	"ItemRefShoppingTooltip3",
	"AutoCompleteBox",
	"FriendsTooltip",
	"ShoppingTooltip1",
	"ShoppingTooltip2",
	"ShoppingTooltip3",
	"WorldMapTooltip", -- Deprecated in 8.1.5
	"WorldMapCompareTooltip1",
	"WorldMapCompareTooltip2",
	"WorldMapCompareTooltip3",
	"ReputationParagonTooltip",
	"StoryTooltip",
	"EmbeddedItemTooltip",
	"QueueStatusFrame" 
} 

-- Textures in the combat pet tooltips
local borderedFrameTextures = { 
	"BorderTopLeft", 
	"BorderTopRight", 
	"BorderBottomRight", 
	"BorderBottomLeft", 
	"BorderTop", 
	"BorderRight", 
	"BorderBottom", 
	"BorderLeft", 
	"Background" 
}

local fakeBackdrop = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	tile = false,
	edgeSize = 16,
	insets = { 
		left = 5,
		right = 4,
		top = 5,
		bottom = 4
	}
}
local fakeBackdropColor = { 0, 0, 0, .95 }
local fakeBackdropBorderColor = { .3, .3, .3, 1 }


-- Utility Functions
---------------------------------------------------------
-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Prefix and camel case a word (e.g. 'name' >> 'prefixName' )
local getPrefixed = function(name, prefix)
	return name and string_gsub(name, "^%l", string_upper)
end 

-- RGB to Hex Color Code
local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local prepare = function(...)
	local tbl
	if (select("#", ...) == 1) then
		local old = ...
		if (old.r) then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if (#tbl == 3) then
		tbl.colorCode = hex(unpack(tbl))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local prepareGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = prepare(v)
	end 
	return tbl
end 

-- Small utility function to anchor line based on lineIndex.
-- Note that this expects there to be a 10px inset from edge to text, 
-- plus a 2px padding between the lines. Makes these variable?
local alignLine = function(tooltip, lineIndex)

	local left = tooltip.lines.left[lineIndex]
	local right = tooltip.lines.right[lineIndex]
	left:ClearAllPoints()

	if (lineIndex == 1) then 
		left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", TEXT_INSET, -TEXT_INSET)
	else
		left:SetPoint("TOPLEFT", tooltip["TextLeft"..(lineIndex-1)], "BOTTOMLEFT", 0, -LINE_PADDING)
	end 

	-- If this is a single line, anchor it to the right side too, to allow wrapping.
	if (not right:IsShown()) then 
		left:SetPoint("RIGHT", tooltip, "RIGHT", -TEXT_INSET, 0)
	end 
end 

-- Small utility function to create a left/right pair of lines
local createNewLinePair = function(tooltip, lineIndex)

	-- Retrieve the global tooltip name
	local tooltipName = tooltip:GetName()

	local left = tooltip:CreateFontString(tooltipName.."TextLeft"..lineIndex)
	left:Hide()
	left:SetDrawLayer("ARTWORK")
	left:SetFontObject((lineIndex == 1) and FONT_TITLE or FONT_NORMAL)
	left:SetTextColor(tooltip.colors.offwhite[1], tooltip.colors.offwhite[2], tooltip.colors.offwhite[3])
	left:SetJustifyH("LEFT")
	left:SetJustifyV("TOP")
	left:SetIndentedWordWrap(false)
	left:SetWordWrap(false)
	left:SetNonSpaceWrap(false)

	tooltip["TextLeft"..lineIndex] = left
	tooltip.lines.left[#tooltip.lines.left + 1] = left

	local right = tooltip:CreateFontString(tooltipName.."TextRight"..lineIndex)
	right:Hide()
	right:SetDrawLayer("ARTWORK")
	right:SetFontObject((lineIndex == 1) and FONT_TITLE or FONT_NORMAL)
	right:SetTextColor(tooltip.colors.offwhite[1], tooltip.colors.offwhite[2], tooltip.colors.offwhite[3])
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("TOP") 
	right:SetIndentedWordWrap(false)
	right:SetWordWrap(false)
	right:SetNonSpaceWrap(false)
	right:SetPoint("TOP", left, "TOP", 0, 0)
	right:SetPoint("RIGHT", tooltip, "RIGHT", -TEXT_INSET, 0)
	tooltip["TextRight"..lineIndex] = right
	tooltip.lines.right[#tooltip.lines.right + 1] = right

	if tooltip.PostCreateLinePair then 
		tooltip:PostCreateLinePair(lineIndex, left, right)
	end 

	-- Align the new line
	alignLine(tooltip, lineIndex)
end 

-- Number abbreviations
local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(math_floor(value))
	end	
end

-- Time constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- Time formatting
local formatTime = function(time)
	if time > DAY then -- more than a day
		return "%.0f%s %.0f%s", time/DAY - time/DAY%1, "d", time%DAY/HOUR, "h"
	elseif time > HOUR then -- more than an hour
		return "%.0f%s %.0f%s", time/HOUR - time/HOUR%1, "h", time%HOUR - time%HOUR%1 , "m"
	elseif time > MINUTE then -- more than a minute
		return "%.0f%s %.0f%s", time/MINUTE - time/MINUTE%1, "m", time%MINUTE - time%1  , "s"
	elseif time > 5 then -- more than 5 seconds
		return "%.0f%s", time - time%1, "s"
	elseif time > 0 then
		return "%.1f%s", time, "s"
	else
		return ""
	end	
end


-- zhCN exceptions
local gameLocale = GetLocale()
if (gameLocale == "zhCN") then 
	short = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(math_floor(value))
		end 
	end
end 


-- Default Color & Texture Tables
--------------------------------------------------------------------------
local Colors = {

	-- some basic ui colors used by all text
	normal = prepare(229/255, 178/255, 38/255),
	highlight = prepare(250/255, 250/255, 250/255),
	offwhite = prepare(196/255, 196/255, 196/255), 
	title = prepare(255/255, 234/255, 137/255),

	-- health bar coloring
	health = prepare( 25/255, 178/255, 25/255 ),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	dead = prepare( 153/255, 153/255, 153/255 ),

	-- difficulty coloring
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},

	-- class and reaction
	class = prepareGroup(RAID_CLASS_COLORS),
	reaction = prepareGroup(FACTION_BAR_COLORS),
	quality = prepareGroup(ITEM_QUALITY_COLORS),
	
	-- magic school coloring
	debuff = prepareGroup(DebuffTypeColor),

	-- power colors, added below
	power = {}
}

-- Power bar colors need special handling, 
-- as some of them contain sub tables.
for powerType, powerColor in pairs(PowerBarColor) do 
	if (type(powerType) == "string") then 
		if (powerColor.r) then 
			Colors.power[powerType] = prepare(powerColor)
		else 
			if powerColor[1] and (type(powerColor[1]) == "table") then 
				Colors.power[powerType] = prepareGroup(powerColor)
			end 
		end  
	end 
end 

-- Add support for custom class colors
local customClassColors = function()
	if CUSTOM_CLASS_COLORS then
		local updateColors = function()
			Colors.class = prepareGroup(CUSTOM_CLASS_COLORS)
			for frame in pairs(frames) do 
				frame:UpdateAllElements("CustomClassColors", frame.unit)
			end 
		end
		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)
		return true
	end
end
if (not customClassColors()) then
	LibTooltip.CustomClassColors = function(self, event, ...)
		if customClassColors() then
			self:UnregisterEvent("ADDON_LOADED", "CustomClassColors")
			self.Listener = nil
		end
	end 
	LibTooltip:RegisterEvent("ADDON_LOADED", "CustomClassColors")
end

-- Library hardcoded fallbacks
local LibraryDefaults = {
	autoCorrectScale = true, -- automatically correct the tooltip scale when shown
	backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 16,
		insets = {
			left = 2.5,
			right = 2.5,
			top = 2.5,
			bottom = 2.5
		}
	},
	backdropBorderColor = { .25, .25, .25, 1 },
	backdropColor = { 0, 0, 0, .85 },
	backdropOffsets = { 0, 0, 0, 0 }, -- points the backdrop is offset from the edges of the tooltip (left, right, top, bottom)
	barInsets = { 0, 0 }, -- points the bars are shrunk from the edges
	barSpacing = 2, -- spacing between multiple bars
	barOffset = 2, -- points the bars are moved upwards towards the tooltip
	defaultAnchor = function() return "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y end,
	barHeight = 6, -- height of bars with no specific type given
	barHeight_health = 6, -- height of bars with the "health" type
	barHeight_power = 4 -- height of bars with the "power" type
}

-- Assign the library hardcoded defaults as fallbacks 
setmetatable(Defaults, { __index = LibraryDefaults } )


-- Tooltip Template
---------------------------------------------------------
local Tooltip_MT = { __index = Tooltip }

-- Original Blizzard methods we need
local FrameMethods = getmetatable(CreateFrame("Frame")).__index
local Blizzard_SetScript = FrameMethods.SetScript
local Blizzard_GetScript = FrameMethods.GetScript


-- Retrieve a tooltip specific setting
Tooltip.GetCValue = function(self, name)
	return TooltipSettings[self][name]
end 

-- Retrieve a tooltip specific default
Tooltip.GetDefaultCValue = function(self, name)
	return TooltipDefaults[self][name]
end 

-- Store a tooltip specific setting
Tooltip.SetCValue = function(self, name, value)
	TooltipSettings[self][name] = value
end 

-- Store a tooltip specific default
Tooltip.SetDefaultCValue = function(self, name, value)
	TooltipDefaults[self][name] = value
end 

-- Updates the tooltip size based on visible lines
Tooltip.UpdateLayout = function(self)

	local currentWidth = self.minimumWidth
	local currentHeight = 0
	local overflowWidth

	for lineIndex in ipairs(self.lines.left) do 

		-- Stop when we hit the first hidden line
		local left = self.lines.left[lineIndex]
		if (not left:IsShown()) then 
			break 
		end 

		-- Width of the current line
		local lineWidth = 0

		-- TODO: Add a system to make sure even overflow is controlled, 
		-- by forcefully line-breaking the offending sides.
		local right = self.lines.right[lineIndex]
		if right:IsShown() then 
			lineWidth = left:GetStringWidth() + RIGHT_PADDING + right:GetStringWidth()
			if (lineWidth > (overflowWidth or self.maximumWidth)) then 
				overflowWidth = lineWidth
			end 
		else 
			lineWidth = left:GetStringWidth()
		end 

		-- Increase the width if this line was larger
		if (lineWidth > currentWidth) then 
			currentWidth = lineWidth 
		end 
	end 

	-- Don't allow it past maximum,
	-- except for when a double line caused the overflow(?)
	if (currentWidth > (overflowWidth or self.maximumWidth)) then 
		currentWidth = overflowWidth or self.maximumWidth
	end 

	-- Set the width, add text inset to the final width
	self:SetWidth(currentWidth + TEXT_INSET*2)

	-- Second iteration to figure out heights now that text is wrapped
	for lineIndex in ipairs(self.lines.left) do 
		-- Stop when we hit the first hidden line
		local left = self.lines.left[lineIndex]
		if (not left:IsShown()) then 
			break 
		end 

		-- Increase the height
		if (lineIndex == 1) then 
			currentHeight = currentHeight + left:GetStringHeight()
		else 
			currentHeight = currentHeight + LINE_PADDING + left:GetStringHeight()
		end 
	end 

	-- Set the height, add text inset to the final width
	self:SetHeight(currentHeight + TEXT_INSET*2)
end 

-- Backdrop update callback
-- Update the size and position of the backdrop, make space for bars.
Tooltip.UpdateBackdropLayout = function(self)

	-- Allow modules to fully override this.
	if self.OverrideBackdrop then 
		return self:OverrideBackdrop()
	end 

	-- Retrieve current settings
	local left, right, top, bottom = unpack(self:GetCValue("backdropOffsets"))
	local barSpacing = self:GetCValue("barSpacing") 
	local barHeight = self:GetCValue("barHeight")

	-- Make space for visible bars
	for i,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			-- Figure out the size of the current bar.
			bottom = bottom + barSpacing + (bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight)
		end 
	end 

	-- Position the backdrop
	local backdrop = self.Backdrop
	backdrop:SetPoint("LEFT", -left, 0)
	backdrop:SetPoint("RIGHT", right, 0)
	backdrop:SetPoint("TOP", 0, top)
	backdrop:SetPoint("BOTTOM", 0, -bottom)
	backdrop:SetBackdrop(self:GetCValue("backdrop"))
	backdrop:SetBackdropBorderColor(unpack(self:GetCValue("backdropBorderColor")))
	backdrop:SetBackdropColor(unpack(self:GetCValue("backdropColor")))

	-- Call module post updates if they exist.
	if self.PostUpdateBackdrop then 
		return self:PostUpdateBackdrop()
	end 	
end 

-- Bar update callback
-- Update the position and size of the bars
Tooltip.UpdateBarLayout = function(self)

	-- Allow modules to fully override this.
	if (self.OverrideBars) then 
		return self:OverrideBars()
	end 

	-- Retrieve general bar data
	local barLeft, barRight = unpack(self:GetCValue("barInsets"))
	local barHeight = self:GetCValue("barHeight")
	local barSpacing = self:GetCValue("barSpacing")
	local barOffset = self:GetCValue("barOffset")

	-- Iterate through all the visible bars, 
	-- and size and position them. 
	for i,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			
			-- Figure out the size of the current bar.
			local barSize = bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight

			-- Size and position the bar
			bar:SetHeight(barSize)
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", barLeft, -barOffset)
			bar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -barRight, -barOffset)

			-- Update offsets
			barOffset = barOffset + barSize + barSpacing
		end 
	end 

	-- Call module post updates if they exist.
	if (self.PostUpdateBars) then 
		return self:PostUpdateBars()
	end 
end 

Tooltip.GetNumBars = function(self)
	return self.numBars
end

Tooltip.GetAllBars = function(self)
	return ipairs(self.bars)
end

Tooltip.AddBar = function(self, barType)
	self.numBars = self.numBars + 1

	-- create an additional bar if needed
	if (self.numBars > #self.bars) then 
		local bar = self:CreateStatusBar()
		local barTexture = self:GetCValue("barTexture")
		if barTexture then 
			bar:SetStatusBarTexture(barTexture)
		end 

		-- Add a value string, but let the modules handle it.
		local value = bar:CreateFontString()
		value:SetFontObject(FONT_VALUE)
		value:SetPoint("CENTER", 0, 0)
		value:SetDrawLayer("OVERLAY")
		value:SetJustifyH("CENTER")
		value:SetJustifyV("MIDDLE")
		value:SetShadowOffset(0, 0)
		value:SetShadowColor(0, 0, 0, 0)
		value:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3], .75)
		value:Hide()
		
		bar.Value = value

		-- Store the new bar
		self.bars[self.numBars] = bar

		if self.PostCreateBar then 
			self:PostCreateBar(bar)
		end
	end 

	local bar = self.bars[self.numBars]
	bar:SetValue(0, true)
	bar:SetMinMaxValues(0, 1, true)
	bar.barType = barType

	return bar
end

Tooltip.GetBar = function(self, barIndex)
	return self.bars[barIndex]
end

Tooltip.GetHealthBar = function(self, barIndex)
end

Tooltip.GetPowerBar = function(self, barIndex)
end

-- Update the color of the tooltip's current unit
-- Returns the r, g, b value
Tooltip.GetUnitHealthColor = function(self, unit)
	if self.OverrideUnitHealthColor then
		return self:OverideUnitHealthColor(unit)
	end
	local r, g, b
	if self.data then 
		if (self.data.isPet and self.data.petRarity) then 
			r, g, b = unpack(self.colors.quality[self.data.petRarity - 1])
		else
			if ((not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)) then
				r, g, b = unpack(self.colors.tapped)
			elseif (not UnitIsConnected(unit)) then
				r, g, b = unpack(self.colors.disconnected)
			elseif (UnitIsDeadOrGhost(unit)) then
				r, g, b = unpack(self.colors.dead)
			elseif (UnitIsPlayer(unit)) then
				local _, class = UnitClass(unit)
				if class then 
					r, g, b = unpack(self.colors.class[class])
				else 
					r, g, b = unpack(self.colors.disconnected)
				end 
			elseif (UnitReaction(unit, "player")) then
				r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
			else
				r, g, b = 1, 1, 1
			end
		end 
	else 
		if ((not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)) then
			r, g, b = unpack(self.colors.tapped)
		elseif (not UnitIsConnected(unit)) then
			r, g, b = unpack(self.colors.disconnected)
		elseif (UnitIsDeadOrGhost(unit)) then
			r, g, b = unpack(self.colors.dead)
		elseif (UnitIsPlayer(unit)) then
			local _, class = UnitClass(unit)
			if class then 
				r, g, b = unpack(self.colors.class[class])
			else 
				r, g, b = unpack(self.colors.disconnected)
			end 
		elseif (UnitReaction(unit, "player")) then
			r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
		else
			r, g, b = 1, 1, 1
		end
	end 
	if self.PostUpdateUnitHealthColor then
		return self:PostUpdateUnitHealthColor(unit)
	end
	return r,g,b
end 
Tooltip.UnitColor = Tooltip.GetUnitHealthColor -- make the original blizz call a copy of this, for compatibility

Tooltip.GetUnitPowerColor = function(self, unit)
	if self.OverrideUnitPowerColor then
		return self:OverrideUnitPowerColor(unit)
	end
	local powerID, powerType = UnitPowerType(unit)
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
	end
	if self.PostUpdateUnitPowerColor then
		return self:PostUpdateUnitPowerColor(unit)
	end
	return r, g, b
end 

-- Mimic the UIParent scale regardless of what the effective scale is
Tooltip.UpdateScale = function(self)
	if self:GetCValue("autoCorrectScale") then 
		local currentScale = self:GetScale()
		local targetScale = UIParent:GetEffectiveScale() / self:GetParent():GetEffectiveScale()
		if (math_abs(currentScale - targetScale) > .05) then 
			self:SetScale(targetScale)
			self:Show()
			return true
		end 
	end 
end 

Tooltip.GetPositionOffset = function(self)

	-- Add offset for any visible bars 
	local offset = 0

	-- Get standard values for size and spacing
	local barSpacing = self:GetCValue("barSpacing")
	local barHeight = self:GetCValue("barHeight")

	for barIndex,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			offset = offset + barSpacing + (bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight)
		end 
	end 

	return offset
end 

Tooltip.UpdatePosition = function(self)

	-- Retrieve default anchor for this tooltip
	local defaultAnchor = self:GetCValue("defaultAnchor")

	local position
	if (type(defaultAnchor) == "function") then 
		position = { defaultAnchor(self, self:GetOwner()) }
	else 
		position = { unpack(defaultAnchor) }
	end 

	-- only check for offsets when the bottom is the anchor, 
	-- since the bars currently only are shown there
	local point = position[1]
	if ((type(point) == "string") and (string_find(point, "BOTTOM"))) then 

		-- Add the offset only if there is one
		local offset = self:GetPositionOffset()
		if (offset > 0) then 
			if (type(position[#position]) == "number") then 
				position[#position] = position[#position] + offset
			else
				position[#position + 1] = 0
				position[#position + 1] = offset
			end 
		end 
	end 

	-- Position it, and take bar height into account
	self:Place(unpack(position))
end 

Tooltip.SetDefaultPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			self:SetDefaultCValue("defaultAnchor", defaultAnchor)
		else 
			self:SetDefaultCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		self:SetDefaultCValue("defaultAnchor", { ... })
	end 
end 

Tooltip.SetPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			self:SetCValue("defaultAnchor", defaultAnchor)
		else 
			self:SetCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		self:SetCValue("defaultAnchor", { ... })
	end 
end 

Tooltip.SetMinimumWidth = function(self, width)
	self.minimumWidth = width
end 

Tooltip.SetMaximumWidth = function(self, width)
	self.maximumWidth = width
end 

Tooltip.SetDefaultBackdrop = function(self, backdropTable)
	check(backdropTable, 1, "table", "nil")
	self:SetDefaultCValue("backdrop", backdropTable)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetDefaultCValue("defaultBackdropOffset", { left, right, top, bottom })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetDefaultCValue("barInsets", { left, right })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetDefaultCValue("barOffset", barOffset)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		self:SetDefaultCValue("barHeight"..barType, barHeight)
	else 
		self:SetDefaultCValue("barHeight", barHeight)
	end 
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()
end 

Tooltip.SetBackdrop = function(self, backdrop)
	check(backdrop, 1, "table", "nil")
	self:SetCValue("backdrop", backdropTable)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetCValue("backdropOffset", { left, right, top, bottom })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetCValue("barInsets", { left, right })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetCValue("barOffset", barOffset)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarTexture = function(self, barTexture, barIndex)
	check(barTexture, 1, "string")
	check(barIndex, 2, "number", "nil")

	if barIndex then 
		local bar = self.bars[barIndex]
		if bar then 
			bar:SetStatusBarTexture(barTexture)
		end 
	else
		for barIndex,bar in ipairs(self.bars) do 
			bar:SetStatusBarTexture(barTexture)
		end 
	end 
end 

Tooltip.SetBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		self:SetCValue("barHeight"..barType, barHeight)
	else 
		self:SetCValue("barHeight", barHeight)
	end 
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()
end 



-- Rewritten Tooltip API
-- *Blizz compatibility and personal additions
---------------------------------------------------------

Tooltip.SetOwner = function(self, owner, anchor)
	self:Hide()
	self:ClearAllPoints()
	
	self.owner = owner
	self.anchor = anchor
end

Tooltip.GetOwner = function(self)
	return self.owner
end 

Tooltip.SetDefaultAnchor = function(self, parent)
	-- Keyword parse the owner frame, to allow tooltips to use our custom crames. 
	self:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	-- Notify other listeners the tooltip is now in default position
	self.default = 1

	-- Update position
	self:UpdatePosition()
end 

Tooltip.SetSmartAnchor = function(self, parent, offsetX, offsetY)

	-- Keyword parse the owner frame, to allow tooltips to use our custom crames. 
	self:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	local width, height = UIParent:GetSize()
	local left = parent:GetLeft()
	local right = width - parent:GetRight()
	local bottom = parent:GetBottom() 
	local top = height - parent:GetTop()
	local point = ((bottom < top) and "BOTTOM" or "TOP") .. ((left < right) and "LEFT" or "RIGHT") 
	local rPoint = ((bottom < top) and "TOP" or "BOTTOM") .. ((left < right) and "RIGHT" or "LEFT") 
	
	offsetX = (offsetX or 10) * ((left < right) and 1 or -1)
	offsetY = (offsetY or 10) * ((bottom < top) and 1 or -1)

	self:Place(point, parent, rPoint, offsetX, offsetY)
end 


-- Returns the correct difficulty color compared to the player.
-- Using this as a tooltip method to access our custom colors.
Tooltip.GetDifficultyColorByLevel = function(self, level)
	local colors = self.colors.quest

	level = level - UnitLevel("player") -- LEVEL
	if (level > 4) then
		return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
	elseif (level > 2) then
		return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
	elseif (level >= -2) then
		return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
	else
		return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
	end
end

Tooltip.SetAction = function(self, slot)
	if (not self.owner) then
		self:Hide()
		return
	end

	-- Switch to item function if the action is an item
	local actionType, id = GetActionInfo(slot)
	if (actionType == "item") then 
		return self:SetActionItem(slot)
	end 

	-- Continue normally if it's a normal character action
	local data = self:GetTooltipDataForAction(slot, self.data)
	if data then 

		-- Because a millionth of a second matters.
		local colors = self.colors

		-- Shouldn't be any bars here, but if for some reason 
		-- the tooltip wasn't properly hidden before this, 
		-- we make sure the bars are reset!
		self:ClearStatusBars(true) -- suppress layout updates

		-- Action Title
		if data.schoolType then 
			self:AddDoubleLine(data.name, data.schoolType, colors.title[1], colors.title[2], colors.title[3], colors.quest.gray[1], colors.quest.gray[2], colors.quest.gray[3], true, true)
		else 
			self:AddLine(data.name, colors.title[1], colors.title[2], colors.title[3], true)
		end 

		-- Cost and range
		if (data.spellCost or data.spellRange) then 
			if (data.spellRange and data.spellCost) then 
				self:AddDoubleLine(data.spellCost, data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)

			elseif data.spellRange then 
				self:AddLine(data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true)

			elseif data.spellCost then 
				self:AddLine(data.spellCost, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)
			end 
		end 

		-- Time and Cooldown 
		if (data.castTime or data.cooldownTime) then 
			if (data.castTime and data.cooldownTime) then 
				self:AddDoubleLine(data.castTime, data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.cooldownTime then 
				self:AddDoubleLine(data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.castTime then 
				self:AddLine(data.castTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
			end 
		end 

		-- Cooldown remaining. Check for charges first.
		if (data.charges and data.maxCharges and (data.charges > 0) and (data.charges < data.maxCharges)) then

			local msg = string_format(SPELL_RECHARGE_TIME, string_format(formatTime(data.chargeDuration - (GetTime() - data.chargeStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])

		elseif (data.cooldownEnable and (data.cooldownEnable ~= 0) and (data.cooldownStart > 0) and (data.cooldownDuration > 0)) then 
			
			local msg = string_format(ITEM_COOLDOWN_TIME, string_format(formatTime(data.cooldownDuration - (GetTime() - data.cooldownStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])
			
		end 

		-- Description
		if data.unmetRequirement then 
			self:AddLine(data.unmetRequirement, colors.quest.red[1], colors.quest.red[2], colors.quest.red[3], true)
		end 

		if data.description then 
			self:AddLine(data.description, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
		end 

		self:Show()
	end 
end 

Tooltip.SetActionItem = function(self, slot)
	if (not self.owner) then
		self:Hide()
		return
	end
	local data = self:GetTooltipDataForActionItem(slot, self.data)
	if data then 

		-- Because a millionth of a second matters.
		local colors = self.colors
		local offwhiteR, offwhiteG, offwhiteB = colors.offwhite[1], colors.offwhite[2], colors.offwhite[3]

		-- User settings
		local colorNameAsSpell = self.colorNameAsSpellWithUse and data.itemHasUseEffect 
		local skipItemLevel = self.hideItemLevelWithUse and data.itemHasUseEffect
		local skipStats = self.hideStatsWithUseEffect and data.itemHasUseEffect
		local skipBinds = self.hideBindsWithUseEffect and data.itemHasUseEffect
		local skipUnique = self.hideUniqueWithUseEffect and data.itemHasUseEffect
		local skipEquipAndType = self.hideEquipTypeWithUseEffect and data.itemHasUseEffect

		-- Shouldn't be any bars here, but if for some reason 
		-- the tooltip wasn't properly hidden before this, 
		-- we make sure the bars are reset!
		self:ClearStatusBars(true) -- suppress layout updates

		-- item name and item level on top
		if data.itemLevel and (not skipItemLevel) then 
			self:AddDoubleLine(data.itemName, data.itemLevel, colors.quality[data.itemRarity][1], colors.quality[data.itemRarity][2], colors.quality[data.itemRarity][3], colors.normal[1], colors.normal[2], colors.normal[3], true)
		elseif colorNameAsSpell then 
			self:AddLine(data.itemName, colors.title[1], colors.title[2], colors.title[3], true)
		else 
			self:AddLine(data.itemName, colors.quality[data.itemRarity][1], colors.quality[data.itemRarity][2], colors.quality[data.itemRarity][3], true)
		end 

		-- item bind status
		if data.itemIsBound and (not skipBinds) then 
			self:AddLine(data.itemBind, offwhiteR, offwhiteG, offwhiteB)
		end 

		-- item unique status
		if data.itemIsUnique and (not skipUnique) then 
			self:AddLine(data.itemUnique, offwhiteR, offwhiteG, offwhiteB)
		end 

		-- item equip location and type
		if (not skipEquipAndType) then 
			if (data.itemEquipLoc and (data.itemEquipLoc ~= "")) then 
				local itemType
				if data.itemType then 
					if data.itemEquipLoc ~= "INVTYPE_TRINKET" and data.itemEquipLoc ~= "INVTYPE_FINGER" and data.itemEquipLoc ~= "INVTYPE_NECK" then 
						itemType = data.itemSubType or data.itemType
					end 
				end 
				if (itemType) then
					self:AddDoubleLine(_G[data.itemEquipLoc], itemType, offwhiteR, offwhiteG, offwhiteB, offwhiteR, offwhiteG, offwhiteB)
				else 
					self:AddLine(_G[data.itemEquipLoc], offwhiteR, offwhiteG, offwhiteB)
				end 
			
			elseif (data.itemType or data.itemSubType) then 
				if (data.itemClassID == LE_ITEM_CLASS_MISCELLANEOUS) then 
					-- This includes hearthstones, flight master's whistle and similar

				elseif (data.itemClassID == LE_ITEM_CLASS_CONSUMABLE) then 
					-- Food, drink, flasks, etc
					self:AddLine(data.itemSubType or data.itemType, offwhiteR, offwhiteG, offwhiteB)

				else 
					self:AddLine(data.itemSubType or data.itemType, offwhiteR, offwhiteG, offwhiteB)
				end 
			end 
		end 

		if (not skipStats) then 

			-- damage and speed
			if (data.itemDamageMin and data.itemDamageMax) then 
				if data.itemSpeed then 
					self:AddDoubleLine(string_format(DAMAGE_TEMPLATE, math_floor(data.itemDamageMin), math_floor(data.itemDamageMax)), string_format("%s %s", ITEM_MOD_CR_SPEED_SHORT, data.itemSpeed), colors.highlight[1], colors.highlight[2], colors.highlight[3], offwhiteR, offwhiteG, offwhiteB)
					
				else 
					self:AddLine(string_format(DAMAGE_TEMPLATE, math_floor(data.itemDamageMin), math_floor(data.itemDamageMax)), colors.highlight[1], colors.highlight[2], colors.highlight[3])
				end 
			end 

			-- damage pr second
			if data.itemDPS then 
				self:AddLine(string_format(DPS_TEMPLATE, string_format("%.1f", data.itemDPS+.05)), colors.highlight[1], colors.highlight[2], colors.highlight[3])
			end 

			local stat1R, stat1G, stat1B = colors.normal[1], colors.normal[2], colors.normal[3]
			local statR, statG, statB = colors.quest.green[1], colors.quest.green[2], colors.quest.green[3] 
			
			-- armor 
			if (data.itemArmor and (data.itemArmor ~= 0)) then 
				self:AddLine(string_format("%s %s", (data.itemArmor > 0) and ("+"..tostring(data.itemArmor)) or tostring(data.itemArmor), RESISTANCE0_NAME), offwhiteR, offwhiteG, offwhiteB)
			end 
			
			-- block 
			if data.itemBlock and (data.itemBlock ~= 0) then 
				self:AddLine(string_format("%s %s", (data.itemBlock > 0) and ("+"..tostring(data.itemBlock)) or tostring(data.itemBlock), ITEM_MOD_BLOCK_RATING_SHORT), offwhiteR, offwhiteG, offwhiteB)
			end 

			-- parry?

			-- primary stat
			if data.primaryStatValue and (data.primaryStatValue ~= 0) then 
				self:AddLine(string_format("%s %s", (data.primaryStatValue > 0) and ("+"..tostring(data.primaryStatValue)) or tostring(data.primaryStatValue), data.primaryStat), stat1R, stat1G, stat1B)

			end 

			-- stamina
			if data.itemStamina and (data.itemStamina ~= 0) then 
				self:AddLine(string_format("%s %s", (data.itemStamina > 0) and ("+"..tostring(data.itemStamina)) or tostring(data.itemStamina), ITEM_MOD_STAMINA_SHORT), stat1R, stat1G, stat1B)

			end 

			-- secondary stats
			if data.sorted2ndStats then 
				for _,stat in ipairs(data.sorted2ndStats) do 
					self:AddLine(stat, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3])
				end 
			end 

			-- no benefit stats
			if data.uselessStats then 
				for key,value in pairs(data.uselessStats) do 
					self:AddLine(string_format("%s %s", (value > 0) and ("+"..tostring(value)) or tostring(value), _G[key]), colors.quest.gray[1], colors.quest.gray[2], colors.quest.gray[3])
				end 
			end 

		end

		-- use effect
		if data.itemHasUseEffect then 
			self:AddLine(data.itemUseEffect, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
		end 

		-- equip effect(s)
		if data.itemHasEquipEffect then 
			for _,stat in ipairs(data.itemEquipEffects) do 
				self:AddLine(stat, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
			end 
		end 

		-- description
		if data.itemDescription then
			for _,msg in ipairs(data.itemDescription) do 
				self:AddLine(msg, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
			end 
		end

		-- durability
		if data.itemDurability then 
			self:AddLine(string_format(DURABILITY_TEMPLATE, data.itemDurability, data.itemDurabilityMax), offwhiteR, offwhiteG, offwhiteB)
		end 

		-- sell value


		self:Show()
	end 
end

Tooltip.SetPetAction = function(self, slot)
	if (not self.owner) then
		self:Hide()
		return
	end
	local data = self:GetTooltipDataForPetAction(slot, self.data)
	if data then 

		-- Because a millionth of a second matters.
		local colors = self.colors

		-- Shouldn't be any bars here, but if for some reason 
		-- the tooltip wasn't properly hidden before this, 
		-- we make sure the bars are reset!
		self:ClearStatusBars(true) -- suppress layout updates

		-- Action Title
		if data.schoolType then 
			self:AddDoubleLine(data.name, data.schoolType, colors.title[1], colors.title[2], colors.title[3], colors.quest.gray[1], colors.quest.gray[2], colors.quest.gray[3], true, true)
		else 
			self:AddLine(data.name, colors.title[1], colors.title[2], colors.title[3], true)
		end 

		-- Cost and range
		if (data.spellCost or data.spellRange) then 
			if (data.spellRange and data.spellCost) then 
				self:AddDoubleLine(data.spellCost, data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)

			elseif data.spellRange then 
				self:AddLine(data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true)

			elseif data.spellCost then 
				self:AddLine(data.spellCost, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)
			end 
		end 

		-- Time and Cooldown 
		if (data.castTime or data.cooldownTime) then 
			if (data.castTime and data.cooldownTime) then 
				self:AddDoubleLine(data.castTime, data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.cooldownTime then 
				self:AddDoubleLine(data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.castTime then 
				self:AddLine(data.castTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
			end 
		end 

		-- Cooldown remaining. Check for charges first.
		if (data.charges and data.maxCharges and (data.charges > 0) and (data.charges < data.maxCharges)) then

			local msg = string_format(SPELL_RECHARGE_TIME, string_format(formatTime(data.chargeDuration - (GetTime() - data.chargeStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])

		elseif (data.cooldownEnable and (data.cooldownEnable ~= 0) and (data.cooldownStart > 0) and (data.cooldownDuration > 0)) then 
			
			local msg = string_format(ITEM_COOLDOWN_TIME, string_format(formatTime(data.cooldownDuration - (GetTime() - data.cooldownStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])
			
		end 

		-- Description
		if data.description then 
			self:AddLine(data.description, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
		end 

		self:Show()
	end 
end

Tooltip.SetItem = function(self, item)
end 

Tooltip.SetItemID = function(self, itemID)
end 

Tooltip.SetItemLink = function(self, itemLink)
end 

Tooltip.SetUnit = function(self, unit)
	if (not self.owner) then
		self:Hide()
		return
	end
	self.unit = unit
	local unit = self:GetTooltipUnit()
	if unit then 
		local data = self:GetTooltipDataForUnit(unit, self.data)
		if data then 

			-- Because a millionth of a second matters.
			local colors = self.colors

			-- Shouldn't be any bars here, but if for some reason 
			-- the tooltip wasn't properly hidden before this, 
			-- we make sure the bars are reset!
			self:ClearStatusBars(true) -- suppress layout updates

			-- Add our health and power bars
			-- These will be automatically updated thanks to 
			-- their provided barTypes here. 
			self:AddBar("health")
			self:AddBar("power")

			-- Add unit data
			-- *Add support for totalRP3 if it's enabled? 

			-- name 
			local displayName = data.name
			if data.isPlayer then 
				if data.isFFA then
					displayName = FFA_TEXTURE .. " " .. displayName
				elseif (data.isPVP and data.englishFaction) then
					if (data.englishFaction == "Horde") then
						displayName = FACTION_HORDE_TEXTURE .. " " .. displayName
					elseif (data.englishFaction == "Alliance") then
						displayName = FACTION_ALLIANCE_TEXTURE .. " " .. displayName
					elseif (data.englishFaction == "Neutral") then
						-- They changed this to their new atlas garbage in Legion, 
						-- so for the sake of simplicty we'll just use the FFA PvP icon instead. Works.
						displayName = FFA_TEXTURE .. " " .. displayName
					end
				end
			else 
				if data.isBoss then
					displayName = BOSS_TEXTURE .. " " .. displayName
				end
			end

			local levelText
			if (data.effectiveLevel and (data.effectiveLevel > 0)) then 
				local r, g, b, colorCode = self:GetDifficultyColorByLevel(data.effectiveLevel)
				levelText = colorCode .. data.effectiveLevel .. "|r"
			end 

			local r, g, b = self:GetUnitHealthColor(unit)
			if levelText then 
				if self.showLevelWithName then 
					self:AddLine(levelText .. colors.quest.gray.colorCode .. ": |r" .. displayName, r, g, b, true)
				else 
					self:AddDoubleLine(displayName, levelText, r, g, b, nil, nil, nil, true)
				end 
			else
				self:AddLine(displayName, r, g, b, true)
			end 

			-- titles
			-- *add player title to a separate line, same as with npc titles?
			if data.title then 
				self:AddLine(data.title, colors.normal[1], colors.normal[2], colors.normal[3], true)
			end 

			-- Players
			if data.isPlayer then 
				if data.guild then 
					self:AddLine(data.guild, colors.title[1], colors.title[2], colors.title[3])
				end  

				local levelLine

				if data.raceDisplayName then 
					levelLine = (levelLine and levelLine.." " or "") .. data.raceDisplayName
				end 

				if (data.classDisplayName and data.class) then 
					if self.colorClass then 
						levelLine = (levelLine and levelLine.." " or "") .. colors.class[data.class].colorCode .. data.classDisplayName .. "|r"
					else 
						levelLine = (levelLine and levelLine.." " or "") .. data.classDisplayName
					end 
				end 

				if levelLine then 
					self:AddLine(levelLine, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
				end 

				-- player faction (Horde/Alliance/Neutral)
				if data.localizedFaction then 
					self:AddLine(data.localizedFaction)
				end 


			-- Battle Pets
			elseif data.isPet then 


			-- All other NPCs
			else  
				if data.city then 
					self:AddLine(data.city, colors.title[1], colors.title[2], colors.title[3])
				end 

				-- Beast etc 
				if data.creatureFamily then 
					self:AddLine(data.creatureType, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

				-- Humanoid, Crab, etc 
				elseif data.creatureType then 
					self:AddLine(data.creatureType, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
				end  
			end 

			if self:UpdateBarValues(unit, true) then 
				self:UpdateBackdropLayout()
				self:UpdateBarLayout()
				self:UpdatePosition()
			end 
			self:Show()
		end 
	end 
end

Tooltip.SetSpellByID = function(self, spellID)
	if (not self.owner) then
		self:Hide()
		return
	end

	local data = self:GetTooltipDataForSpellID(spellID, self.data)
	if data then 

		-- Because a millionth of a second matters.
		local colors = self.colors

		-- Shouldn't be any bars here, but if for some reason 
		-- the tooltip wasn't properly hidden before this, 
		-- we make sure the bars are reset!
		self:ClearStatusBars(true) -- suppress layout updates

		-- Action Title
		if data.schoolType then 
			self:AddDoubleLine(data.name, data.schoolType, colors.title[1], colors.title[2], colors.title[3], colors.quest.gray[1], colors.quest.gray[2], colors.quest.gray[3], true, true)
		else 
			self:AddLine(data.name, colors.title[1], colors.title[2], colors.title[3], true)
		end 

		-- Cost and range
		if (data.spellCost or data.spellRange) then 
			if (data.spellRange and data.spellCost) then 
				self:AddDoubleLine(data.spellCost, data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)

			elseif data.spellRange then 
				self:AddLine(data.spellRange, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true)

			elseif data.spellCost then 
				self:AddLine(data.spellCost, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], true, true)
			end 
		end 

		-- Time and Cooldown 
		if (data.castTime or data.cooldownTime) then 
			if (data.castTime and data.cooldownTime) then 
				self:AddDoubleLine(data.castTime, data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3], colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.cooldownTime then 
				self:AddDoubleLine(data.cooldownTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])

			elseif data.castTime then 
				self:AddLine(data.castTime, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
			end 
		end 

		-- Cooldown remaining. Check for charges first.
		if (data.charges and data.maxCharges and (data.charges > 0) and (data.charges < data.maxCharges)) then

			local msg = string_format(SPELL_RECHARGE_TIME, string_format(formatTime(data.chargeDuration - (GetTime() - data.chargeStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])

		elseif (data.cooldownEnable and (data.cooldownEnable ~= 0) and (data.cooldownStart > 0) and (data.cooldownDuration > 0)) then 
			
			local msg = string_format(ITEM_COOLDOWN_TIME, string_format(formatTime(data.cooldownDuration - (GetTime() - data.cooldownStart))))
			self:AddLine(msg, colors.normal[1], colors.normal[2], colors.normal[3])
			
		end 

		-- Description
		if data.description then 
			self:AddLine(data.description, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
		end 

		self:Show()
	end
end

local ShowAuraTooltip = function(self, data)

	-- Because a millionth of a second matters.
	local colors = self.colors

	-- Shouldn't be any bars here, but if for some reason 
	-- the tooltip wasn't properly hidden before this, 
	-- we make sure the bars are reset!
	self:ClearStatusBars(true) -- suppress layout updates

	self:AddLine(data.name, colors.title[1], colors.title[2], colors.title[3], true)

	if data.spellId then 
		-- How to NOT localize. This is just baaaaad!
		local spellIDText = STAT_CATEGORY_SPELL .. " " .. ID
		self:AddLine(spellIDText .. ": " .. data.spellId, colors.offwhite[1], colors.offwhite[2], colors.offwhite[3])
	end 

	if data.description then 
		self:AddLine(data.description, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3], true)
	end 

	if data.timeRemaining then 
		self:AddLine(data.timeRemaining, colors.normal[1], colors.normal[2], colors.normal[3], true)
	end 

	self:Show()

end

Tooltip.SetUnitAura = function(self, unit, auraID, filter)
	if (not self.owner) then
		self:Hide()
		return
	end
	self.unit = unit
	local unit = self:GetTooltipUnit()
	if unit then 
		local data = self:GetTooltipDataForUnitAura(unit, auraID, filter, self.data)
		if data then 
			ShowAuraTooltip(self, data)
		end 
	end 
end

Tooltip.SetUnitBuff = function(self, unit, buffID, filter)
	if (not self.owner) then
		self:Hide()
		return
	end
	self.unit = unit
	local unit = self:GetTooltipUnit()
	if unit then 
		local data = self:GetTooltipDataForUnitBuff(unit, buffID, filter, self.data)
		if data then 
			ShowAuraTooltip(self, data)
		end 
	end 
end

Tooltip.SetUnitDebuff = function(self, unit, debuffID, filter)
	if (not self.owner) then
		self:Hide()
		return
	end
	self.unit = unit
	local unit = self:GetTooltipUnit()
	if unit then 
		local data = self:GetTooltipDataForUnitDebuff(unit, debuffID, filter, self.data)
		if data then 
			ShowAuraTooltip(self, data)
		end 
	end 
end

-- The same as the old Blizz call is doing. Bad. 
Tooltip.GetUnit = function(self)
	local unit = self.unit
	if UnitExists(unit) then 
		return UnitName(unit), unit
	else
		return nil, unit
	end 
end

-- Retrieve the actual unit the cursor is hovering over, 
-- as the blizzard method for this is just subpar and buggy.
Tooltip.GetTooltipUnit = function(self)
	local unit = self.unit
	if (not unit) then 
		return UnitExists("mouseover") and "mouseover" or nil
	elseif UnitExists(unit) then 
		return UnitIsUnit(unit, "mouseover") and "mouseover" or unit 
	end
end

-- Figure out if the current tooltip is a given unit,
-- but do it properly using our own API calls.
Tooltip.IsUnit = function(self, unit)
	local ourUnit = self:GetTooltipUnit()
	return ourUnit and UnitExists(unit) and UnitIsUnit(unit, ourUnit) or false
end
	
Tooltip.AddLine = function(self, msg, r, g, b, wrap)

	-- Increment the line counter
	self.numLines = self.numLines + 1

	-- Create new lines when needed
	if (not self.lines.left[self.numLines]) then 
		createNewLinePair(self, self.numLines)
	end 

	-- Always fall back to default coloring if color is not provided
	if not (r and g and b) then 
		r, g, b = self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3]
	end 

	local left = self.lines.left[self.numLines]
	left:SetText(msg)
	left:SetTextColor(r, g, b)
	left:SetWordWrap(wrap or false) -- just wrap by default?
	left:Show()

	local right = self.lines.right[self.numLines]
	right:Hide()
	right:SetText("")
	right:SetWordWrap(false)

	-- Align the line
	alignLine(self, self.numLines)

end

Tooltip.AddDoubleLine = function(self, leftMsg, rightMsg, r, g, b, r2, g2, b2, leftWrap, rightWrap)

	-- Increment the line counter
	self.numLines = self.numLines + 1

	-- Create new lines when needed
	if (not self.lines.left[self.numLines]) then 
		createNewLinePair(self, self.numLines)
	end 

	-- Always fall back to default coloring if color is not provided
	if not(r and g and b) then 
		r, g, b = self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3]
	end 
	if not(r2 and g2 and b2) then 
		r2, g2, b2 = self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3]
	end 

	local left = self.lines.left[self.numLines]
	left:SetText(leftMsg)
	left:SetTextColor(r, g, b)
	left:SetWordWrap(leftWrap or false)
	left:Show()

	local right = self.lines.right[self.numLines]
	right:SetText(rightMsg)
	right:SetTextColor(r2, g2, b2)
	right:SetWordWrap(rightWrap or false)
	right:Show()
end

Tooltip.GetNumLines = function(self)
	return self.numLines
end

Tooltip.GetLine = function(self, lineIndex)
	return self.lines.left[lineIndex], self.lines.right[lineIndex]
end

Tooltip.ClearLine = function(self, lineIndex, noUpdate)

	-- Only clear the given line if it's visible in the first place!
	if (self.numLines >= lineIndex) then 

		-- Retrieve the fontstrings, remove them from the table
		local left = table_remove(self.lines.left[lineIndex])
		left:Hide()
		left:SetText("")
		left:SetTextColor(self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3])
		left:ClearAllPoints()

		local right = table_remove(self.lines.right[lineIndex])
		right:Hide()
		right:SetText("")
		right:SetTextColor(self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3])

		-- Reduce the number of visible lines
		self.numLines = self.numLines - 1

		-- Add the lines back into our pool. Waste not!
		self.lines.left[#self.lines.left + 1] = left
		self.lines.right[#self.lines.right + 1] = right

		-- Anchor the line that took the removed line's place to 
		-- the previous line (or tooltip start, if it was the first line).
		-- The other lines are anchored to each other, so need no updates.
		alignLine(self, lineIndex)

		-- Update layout
		if (not noUpdate) then 
			self:UpdateLayout()
			self:UpdateBackdropLayout()
		end 
		return true
	end 
end

Tooltip.ClearAllLines = function(self, noUpdate)

	-- Figure out if we should call the layout updates later
	local needUpdate = self.numLines > 0

	-- Reset the line counter
	self.numLines = 0

	-- We iterate using the number of left lines, 
	-- but all left lines have a matching right line.

	for lineIndex in ipairs(self.lines.left) do 
		local left = self.lines.left[lineIndex]
		left:Hide()
		left:SetText("")
		left:SetTextColor(self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3])
		left:ClearAllPoints()

		local right = self.lines.right[lineIndex]
		right:Hide()
		right:SetText("")
		right:SetTextColor(self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3])
	end 

	-- Do a second pass to re-align points from start to finish.
	for lineIndex in ipairs(self.lines.left) do 
		alignLine(self, lineIndex)
	end 
	
	-- Update layout
	if needUpdate and (not noUpdate) then 
		self:UpdateLayout()
		self:UpdateBackdropLayout()
	end 
	return needUpdate
end

Tooltip.ClearStatusBar = function(self, barIndex, noUpdate)
	local needUpdate
	local bar = self.bars[barIndex]
	if bar then 

		-- Queue a layout update since we're actually hiding a bar
		if bar:IsShown() then 
			needUpdate = true
			bar:Hide()
		end 

		-- Clear the bar even if it was hidden
		bar:SetValue(0, true)
		bar:SetMinMaxValues(0, 1, true)

		-- Update the layout only if a visible bar was hidden,
		-- and only if the noUpdate flag isn't set.
		if needUpdate and (not noUpdate) then 
			self:UpdateBarLayout()
		end 
	end 
	return needUpdate
end

Tooltip.ClearStatusBars = function(self, noUpdate)

	-- clear bar counter
	self.numBars = 0

	local needUpdate
	for i,bar in ipairs(self.bars) do 

		-- Queue a layout update since we're actually hiding a bar
		if bar:IsShown() then 
			needUpdate = true
			bar:Hide()
		end 

		-- Clear the bar even if it was hidden
		bar:SetValue(0, true)
		bar:SetMinMaxValues(0, 1, true)
	end

	-- Update the layout only if a visible bar was hidden,
	-- and only if the noUpdate flag isn't set.
	if needUpdate and (not noUpdate) then 
		self:UpdateBarLayout()
	end 
	return needUpdate
end 

Tooltip.ClearMoney = function(self)
end

Tooltip.SetText = function(self)
end

Tooltip.GetText = function(self)
end

Tooltip.AppendText = function(self)
end

Tooltip.GetUnitColor = function(self, unit)
	local r, g, b = self:GetUnitHealthColor(unit)
	local r2, g2, b2 = self:GetUnitPowerColor(unit)
	return r, g, b, r2, g2, b2
end 

-- Special script handlers we fake
local proxyScripts = {
	OnTooltipAddMoney = true,
	OnTooltipCleared = true,
	OnTooltipSetDefaultAnchor = true,
	OnTooltipSetItem = true,
	OnTooltipSetUnit = true
}

Tooltip.SetScript = function(self, handle, script)
	self.scripts[handle] = script
	if (not proxyScripts[handle]) then 
		Blizzard_SetScript(self, handle, script)
	end 
end

Tooltip.GetScript = function(self, handle)
	return self.scripts[handle]
end


-- Tooltip Script Handlers
---------------------------------------------------------

Tooltip.OnShow = function(self)

	Visible[self] = true

	-- Hide all other registered tooltips when showing one
	for tooltip in pairs(Visible) do 
		if (tooltip ~= self) then 
			tooltip:Hide()
		end 
	end 

	self:UpdateScale()
	self:UpdateLayout()
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()

	-- Tooltips are put in their owner's strata when shown, 
	-- so we need to bump them back to where they belong.
	self:SetFrameStrata("TOOLTIP")

	-- Get rid of the Blizzard GameTooltip if possible
	if (not GameTooltip:IsForbidden()) and (GameTooltip:IsShown()) then 
		GameTooltip:Hide()
	end 

	-- Is the battle pet tip forbidden too? Batter safe than sorry!
	if BattlePetTooltip and ((not BattlePetTooltip:IsForbidden() and BattlePetTooltip:IsShown())) then 
		BattlePetTooltip:Hide()
	end 

end 

Tooltip.OnHide = function(self)
	Visible[self] = nil

	self:ClearMoney(true) -- -- suppress layout updates from this
	self:ClearStatusBars(true) -- suppress layout updates from this
	self:ClearAllLines(true)

	-- Clear all bar types when hiding the tooltip
	for i,bar in ipairs(self.bars) do 
		bar.barType = nil
	end 

	-- Clear all data when hiding the tooltip
	for i,v in pairs(self.data) do 
		self.data[i] = nil
	end 

	-- Reset the layout
	self:UpdateLayout()
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()

	self.needsReset = true
	self.comparing = false
	self.default = nil
end 

Tooltip.OnTooltipAddMoney = function(self, cost, maxcost)
	if (not maxcost) then 
		self:SetMoney(cost, nil, string_format("%s:", SELL_PRICE))
	else
		self:AddLine(string_format("%s:", SELL_PRICE), 1.0, 1.0, 1.0)
		local indent = string_rep(" ", 4)
		self:SetMoney(cost, nil, string_format("%s%s:", indent, MINIMUM))
		self:SetMoney(maxcost, nil, string_format("%s%s:", indent, MAXIMUM))
	end
end 

Tooltip.OnTooltipCleared = function(self)
	self:ClearMoney()
	self:ClearInsertedFrames()
end 

Tooltip.OnTooltipSetDefaultAnchor = function(self)
	self:SetDefaultAnchor("UICenter")
end 

-- This will update values for bar types handled by the library.
-- Currently only includes unit health and unit power.
Tooltip.UpdateBarValues = function(self, unit, noUpdate)
	local guid = UnitGUID(unit)
	local disconnected = not UnitIsConnected(unit)
	local dead = UnitIsDeadOrGhost(unit)
	local needUpdate

	for i,bar in ipairs(self.bars) do
		local isShown = bar:IsShown()
		if (bar.barType == "health") then
			if (disconnected or dead) then 
				local updateNeeded = self:ClearStatusBar(i,true)
				needUpdate = needUpdate or updateNeeded
			else 
				local min = UnitHealth(unit) or 0
				local max = UnitHealthMax(unit) or 0

				-- Only show units with health, hide the bar otherwise
				if ((min > 0) and (max > 0)) then 
					if (not isShown) then 
						bar:Show()
						needUpdate = true
					end 
					bar:SetStatusBarColor(self:GetUnitHealthColor(unit))
					bar:SetMinMaxValues(0, max, needUpdate or (guid ~= bar.guid))
					bar:SetValue(min, needUpdate or (guid ~= bar.guid))
					bar.guid = guid
				else 
					local updateNeeded = self:ClearStatusBar(i,true)
					needUpdate = needUpdate or updateNeeded
				end 
			end 

		elseif (bar.barType == "power") then
			if (disconnected or dead) then 
				local updateNeeded = self:ClearStatusBar(i,true)
				needUpdate = needUpdate or updateNeeded
			else 
				local powerID, powerType = UnitPowerType(unit)
				local min = UnitPower(unit, powerID) or 0
				local max = UnitPowerMax(unit, powerID) or 0
		
				-- Only show the power bar if there's actual power to show
				if (powerType and (min > 0) and (max > 0)) then 
					if (not isShown) then 
						bar:Show()
						needUpdate = true
					end 
					bar:SetStatusBarColor(self:GetUnitPowerColor(unit))
					bar:SetMinMaxValues(0, max, needUpdate or (guid ~= bar.guid))
					bar:SetValue(min, needUpdate or (guid ~= bar.guid))
					bar.guid = guid
				else
					local updateNeeded = self:ClearStatusBar(i,true)
					needUpdate = needUpdate or updateNeeded
				end
			end
		end 
		if (bar:IsShown() and self.PostUpdateStatusBar) then 
			self:PostUpdateStatusBar(bar, bar:GetValue(), bar:GetMinMaxValues())
		end 
	end 

	-- Update the layout only if a visible bar was hidden,
	-- and only if the noUpdate flag isn't set.
	if needUpdate and (not noUpdate) then 
		self:UpdateBackdropLayout()
		self:UpdateBarLayout()
		self:UpdatePosition()
	end 
	return needUpdate
end 

Tooltip.OnTooltipSetUnit = function(self)
	local unit = self:GetTooltipUnit()
	if (not unit) then 
		self:Hide()
		return 
	end 

	-- module post updates
	if self.PostUpdateUnit then 
		return self:PostUpdateUnit(unit)
	end 
end 

Tooltip.OnTooltipSetItem = function(self)
	if (IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not self:IsEquippedItem())) then
		--self:ShowCompareItem()
	else
		--local shoppingTooltip1, shoppingTooltip2 = unpack(self.shoppingTooltips)
		--shoppingTooltip1:Hide()
		--shoppingTooltip2:Hide()
	end
end 

local tooltipUpdateTime = 2/10 -- same as blizz
Tooltip.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < tooltipUpdateTime) then 
		return 
	end 

	local needUpdate

	local unit = self:GetTooltipUnit()
	if unit then 
		if self:UpdateBarValues(unit, true) then 
			needUpdate = true 
		end 
	end 

	if needUpdate then 
		self:UpdateBackdropLayout()
		self:UpdateBarLayout()
		if self.default then 
			self:UpdatePosition()
		end 
	end 

	local owner = self:GetOwner()
	if (owner and owner.UpdateTooltip) then
		owner:UpdateTooltip()
	end
	self.elapsed = 0
end 


-- Library API
---------------------------------------------------------

LibTooltip.SetDefaultCValue = function(self, name, value)
	Defaults[name] = value
end 

LibTooltip.GetDefaultCValue = function(self, name)
	return Defaults[name]
end 

-- Our own secure hook to position tooltips using GameTooltip_SetDefaultAnchor. 
-- Note that we're borrowing some methods from GetFrame for this one.
-- This is to allow keyword parsing for objects like UICenter. 
local SetDefaultAnchor = function(tooltip, parent)
	-- On behalf of the whole community I would like to say
	-- FUCK YOUR FORBIDDEN TOOLTIPS BLIZZARD! >:( 
	if tooltip:IsForbidden() then 
		return 
	end
	
	-- We're only repositioning from the default position, 
	-- and we shouldn't interfere with tooltips placed next to their owners.  
	if (tooltip:GetAnchorType() ~= "ANCHOR_NONE") then 
		return 
	end

	-- The GetFrame call here is to allow our keyword parsing, 
	-- so even the default tooltips can be positioned relative to our special frames. 
	tooltip:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	-- Attempt to find our own defaults, or just go with normal blizzard defaults otherwise. 

	-- Retrieve default anchor for this tooltip
	local defaultAnchor = LibTooltip:GetDefaultCValue("defaultAnchor")

	local position
	if (type(defaultAnchor) == "function") then 
		position = { defaultAnchor(tooltip, parent) }
	else 
		position = { unpack(defaultAnchor) }
	end 

	if defaultAnchor then 
		Tooltip.Place(tooltip, unpack(position))
	else 
		Tooltip.Place(tooltip, "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -_G.CONTAINER_OFFSET_X - 13, _G.CONTAINER_OFFSET_Y)
	end 
end 

-- Set a default position for all registered tooltips. 
-- Also used as a fallback position for Blizzard / 3rd Party addons 
-- that rely on GameTooltip_SetDefaultAnchor to position their tooltips. 
LibTooltip.SetDefaultTooltipPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			LibTooltip:SetDefaultCValue("defaultAnchor", defaultAnchor)
		else 
			LibTooltip:SetDefaultCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		LibTooltip:SetDefaultCValue("defaultAnchor", { ... })
	end 
	LibTooltip:SetSecureHook("GameTooltip_SetDefaultAnchor", SetDefaultAnchor)
end 

LibTooltip.SetDefaultTooltipBackdrop = function(self, backdropTable)
	check(backdropTable, 1, "table", "nil")
	LibTooltip:SetDefaultCValue("backdrop", backdropTable)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	LibTooltip:SetDefaultCValue("backdropColor", { r, g, b, a })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	LibTooltip:SetDefaultCValue("backdropBorderColor", { r, g, b, a })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	LibTooltip:SetDefaultCValue("backdropOffsets", { left, right, top, bottom })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	LibTooltip:SetDefaultCValue("barInsets", { left, right })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	LibTooltip:SetDefaultCValue("barOffset", barOffset)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipStatusBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		LibTooltip:SetDefaultCValue("barHeight"..barType, barHeight)
	else 
		LibTooltip:SetDefaultCValue("barHeight", barHeight)
	end 
	LibTooltip:ForAllTooltips("UpdateBars")
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipStatusBarSpacing = function(self, barSpacing)
	check(barSpacing, 1, "number")
	LibTooltip:SetDefaultCValue("barSpacing", barSpacing)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipColorTable = function(self, colorTable)
	check(colorTable, 1, "table")
	Colors = colorTable -- pure override
end 

LibTooltip.SetDefaultTooltipStatusBarTexture = function(self, barTexture)
	check(barTexture, 1, "string")
	LibTooltip:SetDefaultCValue("barTexture", barTexture)
	LibTooltip:ForAllTooltips("SetStatusBarTexture", barTexture)
end 

LibTooltip.CreateTooltip = function(self, name)
	check(name, 1, "string")

	-- Tooltip reference names aren't global, 
	-- but they still need to be unique from other registered tooltips. 
	if Tooltips[name] then 
		return 
	end 

	LibTooltip.numTooltips = LibTooltip.numTooltips + 1

	-- Note that the global frame name is unrelated to the tooltip name requested by the modules.
	local tooltipName = "CG_GameTooltip_"..LibTooltip.numTooltips

	local tooltip = setmetatable(LibTooltip:CreateFrame("Frame", tooltipName, "UICenter"), Tooltip_MT)
	tooltip:Hide() -- keep it hidden while setting it up
	tooltip:SetSize(160 + TEXT_INSET*2, TEXT_INSET*2) -- minimums
	tooltip.needsReset = true -- flag indicating tooltip must be reset
	tooltip.updateTooltip = .2 -- tooltip update frequency
	tooltip.owner = nil -- current owner
	tooltip.anchor = nil -- current anchor
	tooltip.numLines = 0 -- current number of visible lines
	tooltip.numBars = 0 -- current number of visible bars
	tooltip.numTextures = 0 -- current number of visible textures
	tooltip.minimumWidth = 160 -- current minimum display width
	tooltip.maximumWidth = 360 -- current maximum display width
	tooltip.colors = Colors -- assign our color table, can be replaced by modules to override colors. 
	tooltip.lines = { left = {}, right = {} } -- pool of all text lines
	tooltip.bars = {} -- pool of all bars
	tooltip.textures = {} -- pool of all textures
	tooltip.data = {} -- store data about the current item, unit, etc
	tooltip.scripts = {} -- current script handlers

	-- Add the custom backdrop
	local backdrop = tooltip:CreateFrame()
	backdrop:SetFrameLevel(tooltip:GetFrameLevel()-1)
	backdrop:SetPoint("LEFT", 0, 0)
	backdrop:SetPoint("RIGHT", 0, 0)
	backdrop:SetPoint("TOP", 0, 0)
	backdrop:SetPoint("BOTTOM", 0, 0)
	backdrop:SetScript("OnShow", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)
	backdrop:SetScript("OnHide", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)
	tooltip.Backdrop = backdrop

	-- Create initial textures
	for i = 1,10 do
		local texture = tooltip:CreateTexture(tooltipName.."Texture"..i)
		texture:Hide()
		texture:SetDrawLayer("ARTWORK")
		texture:SetSize(12,12)
		tooltip["Texture"..i] = texture
		tooltip.textures[#tooltip.textures + 1] = texture
	end

	-- Embed the statusbar creation methods directly into the tooltip.
	-- This will give modules and plugins easy access to proper bars. 
	LibStatusBar:Embed(tooltip)

	-- Embed scanner functionality directly into the tooltip too
	LibTooltipScanner:Embed(tooltip)

	-- Create current and default settings tables.
	TooltipDefaults[tooltip] = setmetatable({}, { __index = Defaults })
	TooltipSettings[tooltip] = setmetatable({}, { __index = TooltipDefaults[tooltip] })

	-- Initial backdrop update
	tooltip:UpdateBackdropLayout()

	-- Assign script handlers
	tooltip:SetScript("OnHide", Tooltip.OnHide)
	tooltip:SetScript("OnShow", Tooltip.OnShow)
	tooltip:SetScript("OnTooltipAddMoney", Tooltip.OnTooltipAddMoney)
	tooltip:SetScript("OnTooltipCleared", Tooltip.OnTooltipCleared)
	tooltip:SetScript("OnTooltipSetDefaultAnchor", Tooltip.OnTooltipSetDefaultAnchor)
	tooltip:SetScript("OnTooltipSetItem", Tooltip.OnTooltipSetItem)
	tooltip:SetScript("OnTooltipSetUnit", Tooltip.OnTooltipSetUnit)
	tooltip:SetScript("OnUpdate", Tooltip.OnUpdate)

	-- Store by frame handle for internal usage.
	Tooltips[tooltip] = true

	-- Store by internal name to allow 
	-- modules to retrieve each other's tooltips.
	TooltipsByName[name] = tooltip

	LibTooltip:ForAllEmbeds("PostCreateTooltip", tooltip)
	
	return tooltip
end 

LibTooltip.GetTooltip = function(self, name)
	check(name, 1, "string")
	return TooltipsByName[name]
end 

LibTooltip.KillBlizzardBorderedFrameTextures = function(self, tooltip)
	if (not tooltip) then 
		return 
	end
	local texture
	for _,texName in ipairs(borderedFrameTextures) do
		texture = tooltip[texName]
		if (texture and texture.SetTexture) then 
			texture:SetTexture(nil)
		end
	end
end

LibTooltip.KillBlizzardTooltipBackdrop = function(self, tooltip)
	if (Backdrops[tooltip]) then 
		return 
	end 
	tooltip:SetBackdrop(nil) -- a reset is needed first, or we'll get weird bugs
	tooltip.SetBackdrop = function() end -- kill off the original backdrop function
	tooltip.GetBackdrop = function() return fakeBackdrop end
	tooltip.GetBackdropColor = function() return unpack(fakeBackdropColor) end
	tooltip.GetBackdropBorderColor = function() return unpack(fakeBackdropBorderColor) end
end

LibTooltip.SetBlizzardTooltipBackdropOffsets = function(self, tooltip, left, right, top, bottom)
	if (not Backdrops[tooltip]) then 
		return
	end
	Backdrops[tooltip]:ClearAllPoints()
	Backdrops[tooltip]:SetPoint("LEFT", -left, 0)
	Backdrops[tooltip]:SetPoint("RIGHT", right, 0)
	Backdrops[tooltip]:SetPoint("TOP", 0, top)
	Backdrops[tooltip]:SetPoint("BOTTOM", 0, -bottom)
end 

LibTooltip.SetBlizzardTooltipBackdrop = function(self, tooltip, backdrop)
	if (not Backdrops[tooltip]) then 
		local backdrop = CreateFrame("Frame", nil, tooltip)
		backdrop:SetFrameStrata(tooltip:GetFrameStrata())
		backdrop:SetFrameLevel(tooltip:GetFrameLevel())
		backdrop:SetPoint("LEFT", 0, 0)
		backdrop:SetPoint("RIGHT", 0, 0)
		backdrop:SetPoint("TOP", 0, 0)
		backdrop:SetPoint("BOTTOM", 0, 0)
		hooksecurefunc(tooltip, "SetFrameStrata", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)
		hooksecurefunc(tooltip, "SetFrameLevel", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)
		hooksecurefunc(tooltip, "SetParent", function(self) backdrop:SetFrameLevel(self:GetFrameLevel()) end)
		Backdrops[tooltip] = backdrop
	end 
	Backdrops[tooltip]:SetBackdrop(nil)
	Backdrops[tooltip]:SetBackdrop(backdrop)
end 

LibTooltip.SetBlizzardTooltipBackdropColor = function(self, tooltip, ...)
	if (not Backdrops[tooltip]) then 
		return 
	end 
	Backdrops[tooltip]:SetBackdropColor(...)
end 

LibTooltip.SetBlizzardTooltipBackdropBorderColor = function(self, tooltip, ...)
	if (not Backdrops[tooltip]) then 
		return 
	end 
	Backdrops[tooltip]:SetBackdropBorderColor(...)
end 

LibTooltip.ForAllTooltips = function(self, method, ...)
	check(method, 1, "string", "function")
	for tooltip in pairs(Tooltips) do 
		if (type(method) == "string") then 
			if tooltip[method] then 
				tooltip[method](tooltip, ...)
			end 
		else
			method(tooltip, ...)
		end 
	end 
end 

LibTooltip.GetAllBlizzardTooltips = function(self)
	local counter = 0
	local max = #blizzardTips
	return function() 
		local name, tooltip
		while (counter <= max) do 
			counter = counter + 1
			name = blizzardTips[counter]
			tooltip = name and _G[name]
			if tooltip then 
				break 
			end 
		end
		if tooltip then 
			return tooltip 
		end 
	end 
end 

LibTooltip.ForAllBlizzardTooltips = function(self, method, ...)
	check(method, 1, "string", "function")
	for i,tooltipName in ipairs(blizzardTips) do 
		local tooltip = _G[tooltipName]
		if tooltip then
			if (type(method) == "string") then 
				if self[method] then 
					self[method](self, tooltip, ...)
				elseif tooltip[method] then 
					tooltip[method](tooltip, ...)
				end 
			else
				method(tooltip, ...)
			end 
		end
	end
end 

-- Module embedding
local embedMethods = {
	CreateTooltip = true, 
	GetTooltip = true,
	SetDefaultTooltipPosition = true, 
	SetDefaultTooltipColorTable = true, 
	SetDefaultTooltipBackdrop = true, 
	SetDefaultTooltipBackdropBorderColor = true, 
	SetDefaultTooltipBackdropColor = true, 
	SetDefaultTooltipBackdropOffset = true,
	SetDefaultTooltipStatusBarInset = true, 
	SetDefaultTooltipStatusBarOffset = true, 
	SetDefaultTooltipStatusBarTexture = true, 
	SetDefaultTooltipStatusBarSpacing = true, 
	SetDefaultTooltipStatusBarHeight = true, 
	SetBlizzardTooltipBackdrop = true, 
	SetBlizzardTooltipBackdropColor = true, 
	SetBlizzardTooltipBackdropBorderColor = true, 
	SetBlizzardTooltipBackdropOffsets = true, 
	KillBlizzardTooltipBackdrop = true, 
	KillBlizzardBorderedFrameTextures = true,
	GetAllBlizzardTooltips = true, 
	ForAllTooltips = true,
	ForAllBlizzardTooltips = true,
}

-- Iterate all embedded modules for the given method name or function
-- Silently fail if nothing exists. We don't want an error here. 
LibTooltip.ForAllEmbeds = function(self, method, ...)
	for target in pairs(self.embeds) do 
		if (target) then 
			if (type(method) == "string") then
				if target[method] then
					target[method](target, ...)
				end
			else
				method(target, ...)
			end
		end 
	end 
end 

LibTooltip.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTooltip.embeds) do
	LibTooltip:Embed(target)
end
