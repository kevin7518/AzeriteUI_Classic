local LibUnitFrame = CogWheel:Set("LibUnitFrame", 63)
if (not LibUnitFrame) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibUnitFrame requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibUnitFrame requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibUnitFrame requires LibFrame to be loaded.")

local LibWidgetContainer = CogWheel("LibWidgetContainer")
assert(LibWidgetContainer, "LibUnitFrame requires LibWidgetContainer to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibUnitFrame requires LibTooltip to be loaded.")

LibClientBuild:Embed(LibUnitFrame)
LibEvent:Embed(LibUnitFrame)
LibFrame:Embed(LibUnitFrame)
LibTooltip:Embed(LibUnitFrame)
LibWidgetContainer:Embed(LibUnitFrame)

-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_gsub = string.gsub
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber
local unpack = unpack

-- Blizzard API
local CreateFrame = _G.CreateFrame
local FriendsDropDown = _G.FriendsDropDown
local ShowBossFrameWhenUninteractable = _G.ShowBossFrameWhenUninteractable
local ToggleDropDownMenu = _G.ToggleDropDownMenu
local UnitExists = _G.UnitExists
local UnitGUID = _G.UnitGUID

-- Library Registries
LibUnitFrame.embeds = LibUnitFrame.embeds or {} -- who embeds this?
LibUnitFrame.frames = LibUnitFrame.frames or  {} -- global unitframe registry
LibUnitFrame.scriptHandlers = LibUnitFrame.scriptHandlers or {} -- tracked library script handlers
LibUnitFrame.scriptFrame = LibUnitFrame.scriptFrame -- library script frame, will be created on demand later on

-- Speed shortcuts
local frames = LibUnitFrame.frames
local elements = LibUnitFrame.elements
local callbacks = LibUnitFrame.callbacks
local unitEvents = LibUnitFrame.unitEvents
local frequentUpdates = LibUnitFrame.frequentUpdates
local frequentUpdateFrames = LibUnitFrame.frequentUpdateFrames
local frameElements = LibUnitFrame.frameElements
local frameElementsEnabled = LibUnitFrame.frameElementsEnabled
local scriptHandlers = LibUnitFrame.scriptHandlers
local scriptFrame = LibUnitFrame.scriptFrame

-- Color Table
--------------------------------------------------------------------------
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

-- Default Color Table
local Colors = {
	artifact = prepare( 229/255, 204/255, 127/255 ),
	class = prepareGroup(RAID_CLASS_COLORS),
	dead = prepare( 153/255, 153/255, 153/255 ),
	debuff = prepareGroup(DebuffTypeColor),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	health = prepare( 25/255, 178/255, 25/255 ),
	power = { ALTERNATE = prepare(70/255, 255/255, 131/255) },
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},
	reaction = prepareGroup(FACTION_BAR_COLORS),
	rested = prepare( 23/255, 93/255, 180/255 ),
	restedbonus = prepare( 192/255, 111/255, 255/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	threat = (not IS_CLASSIC) and {
		[0] = prepare( GetThreatStatusColor(0) ),
		[1] = prepare( GetThreatStatusColor(1) ),
		[2] = prepare( GetThreatStatusColor(2) ),
		[3] = prepare( GetThreatStatusColor(3) )
	},
	xp = prepare( 18/255, 179/255, 21/255 )
}

-- Adding this for semantic reasons, 
-- so that plugins can use it for friendly players
-- and the modules will have the choice of overriding it.
Colors.reaction.civilian = Colors.reaction[5]

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
				frame:OverrideAllElements("CustomClassColors", frame.unit)
			end 
		end
		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)
		return true
	end
end
if (not customClassColors()) then
	LibUnitFrame.CustomClassColors = function(self, event, ...)
		if customClassColors() then
			self:UnregisterEvent("ADDON_LOADED", "CustomClassColors")
			self.Listener = nil
		end
	end 
	LibUnitFrame:RegisterEvent("ADDON_LOADED", "CustomClassColors")
end

-- Secure Snippets
--------------------------------------------------------------------------
local secureSnippets = {
	initialConfigFunction = [=[
		local header = self:GetParent()
		local frames = table.new()
		table.insert(frames, self)
		self:GetChildList(frames)
		for i = 1, #frames do
			local frame = frames[i]
			local unit
			-- There's no need to do anything on frames with onlyProcessChildren
			if (not frame:GetAttribute("oUF-onlyProcessChildren")) then
				RegisterUnitWatch(frame)

				-- Attempt to guess what the header is set to spawn.
				local groupFilter = header:GetAttribute("groupFilter")

				if(type(groupFilter) == "string" and groupFilter:match("MAIN[AT]")) then
					local role = groupFilter:match("MAIN([AT])")
					if(role == "T") then
						unit = "maintank"
					else
						unit = "mainassist"
					end
				elseif(header:GetAttribute("showRaid")) then
					unit = "raid"
				elseif(header:GetAttribute("showParty")) then
					unit = "party"
				end

				local headerType = header:GetAttribute("oUF-headerType")
				local suffix = frame:GetAttribute("unitsuffix")
				if(unit and suffix) then
					if(headerType == "pet" and suffix == "target") then
						unit = unit .. headerType .. suffix
					else
						unit = unit .. suffix
					end
				elseif(unit and headerType == "pet") then
					unit = unit .. headerType
				end

				frame:SetAttribute("*type1", "target")
				frame:SetAttribute("*type2", "togglemenu")
				frame:SetAttribute("oUF-guessUnit", unit)
			end

			local body = header:GetAttribute("oUF-initialConfigFunction")
			if(body) then
				frame:Run(body, unit)
			end
		end

		header:CallMethod("styleFunction", self:GetName())

		local Clique = header:GetFrameRef("clickcast_header")
		if Clique then
			Clique:SetAttribute("clickcast_button", self)
			Clique:RunAttribute("clickcast_register")
		end
	]=]
}

-- Utility Functions
--------------------------------------------------------------------------
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

-- Library Updates
--------------------------------------------------------------------------
-- global update limit, no elements can go above this
local THROTTLE = 1/30 
local OnUpdate = function(self, elapsed)

	-- Throttle the updates, to increase the performance. 
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < THROTTLE) then
		return
	end
	local elapsed = self.elapsed

	for frame, frequentElements in pairs(frequentUpdates) do
		for element, frequency in pairs(frequentElements) do
			if frequency.hz then
				frequency.elapsed = frequency.elapsed + elapsed
				if (frequency.elapsed >= frequency.hz) then
					elements[element].Update(frame, "FrequentUpdate", frame.unit, elapsed) 
					frequency.elapsed = 0
				end
			else
				elements[element].Update(frame, "FrequentUpdate", frame.unit)
			end
		end
	end

	self.elapsed = 0
end

-- Unitframe Template
--------------------------------------------------------------------------
local UnitFrame = {} 
local UnitFrame_MT = { __index = UnitFrame }

-- Return or create the library default tooltip
-- This is shared by all unitframes, unless these methods 
-- are specifically overwritten by the modules.
UnitFrame.GetTooltip = function(self)
	return LibUnitFrame:GetUnitFrameTooltip()
end 

UnitFrame.OnEnter = function(self)
	if ((not self.unit) or (not UnitExists(self.unit))) then 
		return 
	end 

	self.isMouseOver = true

	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(160)
	tooltip:SetUnit(self.unit)

	if self.PostEnter then 
		self:PostEnter()
	end 
end

UnitFrame.OnLeave = function(self)
	self.isMouseOver = nil

	local tooltip = self:GetTooltip()
	tooltip:Hide()

	if self.PostLeave then 
		self:PostLeave()
	end 
end

UnitFrame.OverrideAllElements = function(self, event, ...)
	local unit = self.unit
	if (not unit) or (not (UnitExists(unit) or ShowBossFrameWhenUninteractable(unit))) then 
		return 
	end
	return self:UpdateAllElements(event, ...)
end

-- Special method that only updates the elements if the GUID has changed. 
-- Intention is to avoid performance drops from people coming and going in PuG raids. 
UnitFrame.OverrideAllElementsOnChangedGUID = function(self, event, ...)
	local unit = self.unit
	if (not unit) or (not (UnitExists(unit) or ShowBossFrameWhenUninteractable(unit))) then 
		return 
	end
	local currentGUID = UnitGUID(unit)
	if (self.unitGUID ~= currentGUID) then 
		self.unitGUID = currentGUID
		return self:UpdateAllElements(event, ...)
	end
end

local UpdatePet = function(self, event, unit)
	local petUnit
	if (unit == "target") then
		return
	elseif (unit == "player") then
		petUnit = "pet"
	else
		petUnit = unit.."pet"
	end
	if (not self:OnAttributeChanged("unit", UnitHasVehicleUI(unit) and petUnit or unit)) then
		return self:UpdateAllElements(event, "Forced", self.unit)
	end
end

-- Library API
--------------------------------------------------------------------------
-- Return or create the library default tooltip
LibUnitFrame.GetUnitFrameTooltip = function(self)
	return LibUnitFrame:GetTooltip("CG_UnitFrameTooltip") or LibUnitFrame:CreateTooltip("CG_UnitFrameTooltip")
end

LibUnitFrame.SetScript = function(self, scriptHandler, script)
	scriptHandlers[scriptHandler] = script
	if (scriptHandler == "OnUpdate") then
		if (not scriptFrame) then
			scriptFrame = CreateFrame("Frame", nil, LibFrame:GetFrame())
		end
		if script then 
			scriptFrame:SetScript("OnUpdate", function(self, ...) 
				script(LibUnitFrame, ...) 
			end)
		else
			scriptFrame:SetScript("OnUpdate", nil)
		end
	end
end

LibUnitFrame.GetScript = function(self, scriptHandler)
	return scriptHandlers[scriptHandler]
end

LibUnitFrame.GetUnitFrameVisibilityDriver = function(self, unit)
	local visDriver
	if (unit == "player") then 
		-- Might seem stupid, but I want the player frame to disappear along with the actionbars 
		-- when we've blown the flight master's whistle and are getting picked up.
		visDriver = "[@player,exists][vehicleui][possessbar][overridebar][mounted]show;hide"
	elseif (unit == "pet") then 
		visDriver = "[@pet,exists][nooverridebar,vehicleui]show;hide"
	else
		visDriver = string_format("[@%s,exists]show;hide", unit)
	end
	return visDriver
end 

LibUnitFrame.GetUnitFrameVehicleDriver = function(self, unit)
	local vehicleDriver
	if (unit == "player") then 
		-- Should work in all cases where the unitframe is replaced. It should always be the "pet" unit.
		--vehicleDriver = "[vehicleui]pet;player"
		vehicleDriver = "[nooverridebar,vehicleui]pet;[overridebar,@vehicle,exists]vehicle;player"
	elseif (unit == "pet") then 
		vehicleDriver = "[nooverridebar,vehicleui]player;pet"
	elseif (unit:match("^party(%d+)")) then 
		vehicleDriver = string_format("[unithasvehicleui,@%s]%s;%s", unit, unit.."pet", unit)
	elseif (unit:match("^raid(%d+)")) then 
		vehicleDriver = string_format("[unithasvehicleui,@%s]%s;%s", unit, unit.."pet", unit)
	end
	return vehicleDriver
end 

-- spawn and style a new unitframe
LibUnitFrame.SpawnUnitFrame = function(self, unit, parent, styleFunc, ...)
	check(unit, 1, "string")
	check(parent, 2, "table", "string", "nil")
	check(styleFunc, 3, "function", "string", "nil")

	-- Alllow modules to use methods as styling functions. 
	-- We don't want to allow this in the widgetcontainer back-end,  
	-- so we need a bit of trickery here to make it happen. 
	if (type(styleFunc) == "string") then 
		local func = self[styleFunc]
		if func then 
			local module, method = self, styleFunc
			styleFunc = function(...) 
				-- Always call the method by name, 
				-- don't assume the function is the same each time. 
				-- Even though it is. So this is weird. 
				return module[method](self, ...)
			end 
		end 
	end 
	
	local frame = LibUnitFrame:CreateWidgetContainer("Button", parent, "SecureUnitButtonTemplate", unit, styleFunc, ...)
	for method,func in pairs(UnitFrame) do 
		frame[method] = func
	end 

	frame.requireUnit = true
	frame.colors = frame.colors or Colors

	if (frame.ignoreMouseOver) then 
		frame:EnableMouse(false)
		frame:RegisterForClicks("")
	else 
		frame:SetAttribute("*type1", "target")
		frame:SetAttribute("*type2", "togglemenu")
		frame:SetScript("OnEnter", UnitFrame.OnEnter)
		frame:SetScript("OnLeave", UnitFrame.OnLeave)
		frame:RegisterForClicks("AnyUp")
	end 

	if (unit == "target") then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame.OverrideAllElements, true)

	elseif (unit == "focus") then
		if (not IS_CLASSIC) then 
			frame:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame.OverrideAllElements, true)
		end 

	elseif (unit == "mouseover") then
		frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("^boss(%d+)")) then
		frame.unitGroup = "boss"

		frame:SetFrameStrata("MEDIUM")
		frame:SetFrameLevel(1000)
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", UnitFrame.OverrideAllElements, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("^arena(%d+)")) then
		frame.unitGroup = "arena"

		frame:SetFrameStrata("MEDIUM")
		frame:SetFrameLevel(1000)
		frame:RegisterEvent("ARENA_OPPONENT_UPDATE", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("^party(%d+)")) then 
		frame.unitGroup = "party"
		frame:RegisterEvent("GROUP_ROSTER_UPDATE", UnitFrame.OverrideAllElements, true)
		frame:RegisterEvent("UNIT_PET", UpdatePet)

	elseif (unit:match("^raid(%d+)")) then 
		frame.unitGroup = "raid"
		frame:RegisterEvent("GROUP_ROSTER_UPDATE", UnitFrame.OverrideAllElementsOnChangedGUID, true)
		frame:RegisterEvent("UNIT_PET", UpdatePet)

	elseif (unit:match("%w+target")) then
		frame:EnableFrameFrequent(.5, "unit")
	end

	local vehicleDriver = LibUnitFrame:GetUnitFrameVehicleDriver(unit)
	if vehicleDriver then 
		local vehicleSwitcher = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
		vehicleSwitcher:SetFrameRef("UnitFrame", frame)
		vehicleSwitcher:SetAttribute("unit", unit)
		vehicleSwitcher:SetAttribute("_onattributechanged", [=[
			local frame = self:GetFrameRef("UnitFrame"); 
			frame:SetAttribute("unit", value); 
		]=])
		frame.realUnit = unit
		frame:SetAttribute("unit", SecureCmdOptionParse(vehicleDriver))
		RegisterAttributeDriver(vehicleSwitcher, "state-vehicleswitch", vehicleDriver)
	else
		frame:SetAttribute("unit", unit)
	end 

	local visDriver = LibUnitFrame:GetUnitFrameVisibilityDriver(unit)
	if frame.visibilityOverrideDriver then 
		visDriver = frame.visibilityOverrideDriver
	elseif frame.visibilityPreDriver then
		visDriver = frame.visibilityPreDriver .. visDriver
	end

	frame:SetAttribute("visibilityDriver", visDriver)
	RegisterAttributeDriver(frame, "state-visibility", visDriver)

	-- This and a global name is pretty much  
	-- the shortest route to Clique compatibility.
	_G.ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[frame] = true

	frames[frame] = true 

	if frame.PostCreate then 
		frame:PostCreate()
	end 
	
	return frame
end

-- spawn and style a new group header
LibUnitFrame.SpawnHeader = function(self, unit, parent, styleFunc, ...)
	
	local headerTemplate, unitTemplate
	if _G.Clique then 
		headerTemplate = "SecureGroupHeaderTemplate"
		unitTemplate = "SecureUnitButtonTemplate, SecureHandlerStateTemplate, SecureHandlerEnterLeaveTemplate"
	else 
		headerTemplate = "SecureGroupHeaderTemplate"
		unitTemplate = "SecureUnitButtonTemplate"
	end 

	local header = self:CreateFrame("Frame", nil, "UICenter", headerTemplate)
	header:SetAttribute("template", unitTemplate)
	header:SetAttribute("initialConfigFunction", secureSnippets.initialConfigFunction)
	for i = 1, select("#", ...), 2 do
		local attribute, value = select(i, ...)
		if (not attribute) then 
			break 
		end
		header:SetAttribute(attribute, value)
	end
	if _G.Clique then
		header:SetFrameRef("clickcast_header", _G.Clique.header)
	end

	return header
end

-- Make this a proxy for development purposes
LibUnitFrame.RegisterElement = function(self, ...)
	LibWidgetContainer:RegisterElement(...)
end 

-- Module embedding
local embedMethods = {
	SpawnUnitFrame = true,
	GetUnitFrameVehicleDriver = true, 
	GetUnitFrameVisibilityDriver = true, 
	GetUnitFrameTooltip = true
}

LibUnitFrame.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibUnitFrame.embeds) do
	LibUnitFrame:Embed(target)
end
