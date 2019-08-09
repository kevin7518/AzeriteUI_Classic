local LibWidgetContainer = CogWheel:Set("LibWidgetContainer", 22)
if (not LibWidgetContainer) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibWidgetContainer requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibWidgetContainer requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibWidgetContainer requires LibFrame to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibWidgetContainer)
LibEvent:Embed(LibWidgetContainer)
LibFrame:Embed(LibWidgetContainer)

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

-- WoW API
local CreateFrame = _G.CreateFrame

-- Library Registries
LibWidgetContainer.embeds = LibWidgetContainer.embeds or {} -- who embeds this?
LibWidgetContainer.frames = LibWidgetContainer.frames or  {} -- global unitframe registry
LibWidgetContainer.elements = LibWidgetContainer.elements or {} -- global element registry
LibWidgetContainer.callbacks = LibWidgetContainer.callbacks or {} -- global frame and element callback registry
LibWidgetContainer.unitEvents = LibWidgetContainer.unitEvents or {} -- global frame unitevent registry
LibWidgetContainer.frequentUpdates = LibWidgetContainer.frequentUpdates or {} -- global element frequent update registry
LibWidgetContainer.frequentUpdateFrames = LibWidgetContainer.frequentUpdateFrames or {} -- global frame frequent update registry
LibWidgetContainer.frameElements = LibWidgetContainer.frameElements or {} -- per unitframe element registry
LibWidgetContainer.frameElementsEnabled = LibWidgetContainer.frameElementsEnabled or {} -- per unitframe element enabled registry
LibWidgetContainer.frameElementsDisabled = LibWidgetContainer.frameElementsDisabled or {} -- per unitframe element manually disabled registry
LibWidgetContainer.scriptHandlers = LibWidgetContainer.scriptHandlers or {} -- tracked library script handlers
LibWidgetContainer.scriptFrame = LibWidgetContainer.scriptFrame -- library script frame, will be created on demand later on

-- Shortcuts
local frames = LibWidgetContainer.frames
local elements = LibWidgetContainer.elements
local callbacks = LibWidgetContainer.callbacks
local unitEvents = LibWidgetContainer.unitEvents
local frequentUpdates = LibWidgetContainer.frequentUpdates
local frequentUpdateFrames = LibWidgetContainer.frequentUpdateFrames
local frameElements = LibWidgetContainer.frameElements
local frameElementsEnabled = LibWidgetContainer.frameElementsEnabled
local frameElementsDisabled = LibWidgetContainer.frameElementsDisabled
local scriptHandlers = LibWidgetContainer.scriptHandlers
local scriptFrame = LibWidgetContainer.scriptFrame

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

-- Embed source methods into target.
local embed = function(target, source)
	for i,v in pairs(source) do
		if (type(v) == "function") then
			target[i] = v
		end
	end
	return target
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


-- WidgetFrame Template
--------------------------------------------------------------------------
local WidgetFrame = LibWidgetContainer:CreateFrame("Button")
local WidgetFrame_MT = { __index = WidgetFrame }

-- Methods we don't wish to expose to the modules
--------------------------------------------------------------------------
local IsEventRegistered = WidgetFrame_MT.__index.IsEventRegistered
local RegisterEvent = WidgetFrame_MT.__index.RegisterEvent
local RegisterUnitEvent = WidgetFrame_MT.__index.RegisterUnitEvent
local UnregisterEvent = WidgetFrame_MT.__index.UnregisterEvent
local UnregisterAllEvents = WidgetFrame_MT.__index.UnregisterAllEvents

local IsMessageRegistered = LibWidgetContainer.IsMessageRegistered
local RegisterMessage = LibWidgetContainer.RegisterMessage
local SendMessage = LibWidgetContainer.SendMessage
local UnregisterMessage = LibWidgetContainer.UnregisterMessage

local UpdateAllElements = function(self, ...)
	return (self.OverrideAllElements or self.UpdateAllElements) (self, ...)
end 

WidgetFrame.OnUnitChanged = function(self, unit)
	if (self.unit ~= unit) then
		self.unit = unit
		self.id = tonumber(string_match(unit, "^.-(%d+)"))
		self.unitGUID = nil -- really?

		-- Update all unit events
		for event in pairs(unitEvents) do 
			local hasEvent, eventUnit = IsEventRegistered(self, event)
			if (hasEvent and eventUnit ~= unit) then 

				-- This erases previously registered unit events
				RegisterUnitEvent(self, event, unit, self.realUnit)
			end 
		end 
		return true
	end 
end 

-- Allow modules or other libraries to insert their own handlers by proxy
WidgetFrame.OnAttributeChanged = function(self, attribute, value)
	if (attribute == "unit") then

		-- replace playerpet with pet
		value = value:gsub("playerpet", "pet")

		-- Bail out if the unit isn't changed
		if (self.unit == value) then 
			return 
		end 

		-- Update all elements to the new unit
		if self:OnUnitChanged(value) then

			-- The above updates frame.unit
			UpdateAllElements(self, "Forced", self.unit)
			return true
		end 
	end
end

WidgetFrame.OnEvent = function(frame, event, ...)
	if (frame:IsVisible() and callbacks[frame] and callbacks[frame][event]) then 
		local events = callbacks[frame][event]
		local isUnitEvent = unitEvents[event]
		for i = 1, #events do
			if isUnitEvent then 
				events[i](frame, event, ...)
			else 
				events[i](frame, event, frame.unit, ...)
			end 
		end
	end 
end

WidgetFrame.RegisterEvent = function(self, event, func, unitless)
	if (frequentUpdateFrames[self] and event ~= "UNIT_PORTRAIT_UPDATE" and event ~= "UNIT_MODEL_CHANGED") then 
		return 
	end
	if (not callbacks[self]) then
		callbacks[self] = {}
	end
	if (not callbacks[self][event]) then
		callbacks[self][event] = {}
	end
	
	local events = callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(self, event)) then
		if unitless then 
			RegisterEvent(self, event)
		else 
			unitEvents[event] = true
			RegisterUnitEvent(self, event, self.unit)
		end 
	end
end

WidgetFrame.UnregisterEvent = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not callbacks[self] or not callbacks[self][event] then
		return
	end

	local events = callbacks[self][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				table_remove(events, i)
				--events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

WidgetFrame.UnregisterAllEvents = function(self)
	if not callbacks[self] then 
		return
	end
	for event, funcs in pairs(callbacks[self]) do
		for i = #funcs, 1, -1 do
			table_remove(funcs, i)
			--funcs[i] = nil
		end
	end
	UnregisterAllEvents(self)
end

WidgetFrame.RegisterMessage = function(self, event, func, unitless)
	if (frequentUpdateFrames[self]) then 
		return 
	end
	if (not callbacks[self]) then
		callbacks[self] = {}
	end
	if (not callbacks[self][event]) then
		callbacks[self][event] = {}
	end
	
	local events = callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsMessageRegistered(self, event, WidgetFrame.OnEvent)) then
		RegisterMessage(self, event, WidgetFrame.OnEvent)
		if (not unitless) then 
			unitEvents[event] = true
		end 
	end
end

WidgetFrame.SendMessage = SendMessage -- Don't need a proxy on this one

WidgetFrame.UnregisterMessage = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not callbacks[self] or not callbacks[self][event] then
		return
	end

	local events = callbacks[self][event]

	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				table_remove(events, i)
			end
		end
		if (#events == 0) then
			if (IsMessageRegistered(self, event, WidgetFrame.OnEvent)) then
				UnregisterMessage(self, event, WidgetFrame.OnEvent) 
			end
		end
	end
end

WidgetFrame.UpdateAllElements = function(self, event, ...)
	if (self.PreUpdate) then
		self:PreUpdate(event, unit, ...)
	end
	if (frameElements[self]) then
		for element in pairs(frameElementsEnabled[self]) do
			-- Will run the registered Update function for the element, 
			-- which isually is the "Proxy" method in my elements. 
			-- We cannot direcly access the ForceUpdate method, 
			-- as that is meant for in-module updates to that unique
			-- instance of the element, and doesn't exist on the template element itself. 
			elements[element].Update(self, event or "Forced", self.unit)
		end
	end
	if (self.PostUpdate) then
		self:PostUpdate(event, unit, ...)
	end
end

WidgetFrame.EnableElement = function(self, element)
	if (not frameElements[self]) then
		frameElements[self] = {}
		frameElementsEnabled[self] = {}
	end

	-- don't double enable
	if frameElementsEnabled[self][element] then 
		return 
	end 

	-- removed manually disabled entry
	if (frameElementsDisabled[self] and frameElementsDisabled[self][element]) then 
		frameElementsDisabled[self][element] = nil
	end 
	
	-- upvalues ftw
	local frameElements = frameElements[self]
	local frameElementsEnabled = frameElementsEnabled[self]
	
	-- avoid duplicates
	local found
	for i = 1, #frameElements do
		if (frameElements[i] == element) then
			found = true
			break
		end
	end
	if (not found) then
		-- insert the element into the list
		table_insert(frameElements, element)
	end

	-- attempt to enable the element
	if elements[element].Enable(self, self.unit) then
		-- success!
		frameElementsEnabled[element] = true
	end
end

WidgetFrame.DisableElement = function(self, element, softDisable)
	if (not frameElementsDisabled[self]) then 
		frameElementsDisabled[self] = {}
	end 

	-- mark this as manually disabled
	if (not softDisable) then 
		frameElementsDisabled[self][element] = true
	end
	
	-- silently fail if the element hasn't been enabled for the frame
	if ((not frameElementsEnabled[self]) or (not frameElementsEnabled[self][element])) then
		return
	end
	
	-- run the disable script
	elements[element].Disable(self, self.unit)

	-- remove the element from the enabled registries
	for i = #frameElements[self], 1, -1 do
		if (frameElements[self][i] == element) then
			table_remove(frameElements[self], i)
			--frameElements[self][i] = nil
		end
	end
	
	-- remove the enabled status
	frameElementsEnabled[self][element] = nil
	
	-- remove the element's frequent update entry
	if (frequentUpdates[self] and frequentUpdates[self][element]) then
		-- remove the element's frequent update entry
		frequentUpdates[self][element].elapsed = nil
		frequentUpdates[self][element].hz = nil
		frequentUpdates[self][element] = nil
		
		-- Remove the frame object's frequent update entry
		-- if no elements require it anymore.
		local count = 0
		for i,v in pairs(frequentUpdates[self]) do
			count = count + 1
		end
		if (count == 0) then
			frequentUpdates[self] = nil
		end
		
		-- Disable the entire script handler if no elements
		-- on any frames require frequent updates. 
		count = 0
		for i,v in pairs(frequentUpdates) do
			count = count + 1
		end
		if (count == 0) then
			if LibWidgetContainer:GetScript("OnUpdate") then
				LibWidgetContainer:SetScript("OnUpdate", nil)
			end
		end
	end
end

WidgetFrame.IsElementEnabled = function(self, element)
	local enabled = frameElementsEnabled[self] and frameElementsEnabled[self][element]
	if enabled then 
		return true 
	else 
		return false 
	end 
end

WidgetFrame.EnableFrequentUpdates = function(self, element, frequency)
	if (not frequentUpdates[self]) then
		frequentUpdates[self] = {}
	end
	frequentUpdates[self][element] = { elapsed = 0, hz = tonumber(frequency) or .5 }
	if (not LibWidgetContainer:GetScript("OnUpdate")) then
		LibWidgetContainer:SetScript("OnUpdate", OnUpdate)
	end
end

WidgetFrame.EnableFrameFrequent = function(frame, throttle, toggleKey)
	frequentUpdateFrames[frame] = throttle or .5
	local timer = 0
	local key = toggleKey
	frame:SetScript("OnUpdate", function(self, elapsed)
		if key and (not self[key]) then 
			return
		end
		timer = timer + elapsed
		if (timer > frequentUpdateFrames[self]) then
			-- Is this really a good thing to do?
			-- Maybe select just a minor few, 
			-- or do some checks on the unit or GUID to 
			-- figure out if we actually need an update?
			(self.OverrideAllElements or self.UpdateAllElements) (self, "FrequentUpdate", self[key])
			timer = 0
		end
	end)
end 

-- Library API
--------------------------------------------------------------------------
LibWidgetContainer.SetScript = function(self, scriptHandler, script)
	check(scriptHandler, 1, "string")
	check(script, 2, "function", "nil")
	scriptHandlers[scriptHandler] = script
	if (scriptHandler == "OnUpdate") then
		if (not scriptFrame) then
			scriptFrame = CreateFrame("Frame", nil, LibFrame:GetFrame())
		end
		if script then 
			scriptFrame:SetScript("OnUpdate", function(self, ...) 
				script(LibWidgetContainer, ...) 
			end)
		else
			scriptFrame:SetScript("OnUpdate", nil)
		end
	end
end

LibWidgetContainer.GetScript = function(self, scriptHandler)
	check(scriptHandler, 1, "string")
	return scriptHandlers[scriptHandler]
end

-- Not a public method
LibWidgetContainer.InitWidgetContainer = function(self, frame, unit, styleFunc, ...)
	if (type(unit) == "string") then 
		frame.unit = unit
		frame.id = tonumber(string_match(unit, "^.-(%d+)"))
	end 

	if styleFunc then
		styleFunc(frame, frame.unit, frame.id, ...) 
	end
	
	for element in pairs(elements) do
		-- Don't enable elements that's been manually disabled in styleFunc
		if (not (frameElementsDisabled[frame] and frameElementsDisabled[frame][element])) then 
			frame:EnableElement(element, frame.unit)
		end
	end

	frame:SetScript("OnEvent", WidgetFrame.OnEvent)
	frame:SetScript("OnAttributeChanged", WidgetFrame.OnAttributeChanged)
	frame:HookScript("OnShow", function(self) UpdateAllElements(self, "Forced", self.unit) end) 

	-- Not sure all needs this one
	-- But player, pet and all other units that exist before targeted do, 
	-- or certain stuff like player specialization and similar won't be updated, 
	-- as registering for their change event isn't enough, they need an initial update too!
	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateAllElements, true)


	-- Add the frame to our registry
	frames[frame] = true
	
	-- Return it to the user
	return frame
end

-- Apply the widget container element and event handling to an existing frame
-- Currently assumes a frame of type "Button" or anything farther up in the hierarchy
LibWidgetContainer.ApplyWidgetContainer = function(self, frame, parent, unit, styleFunc, ...)
	check(frame, 1, "table")
	check(parent, 2, "string", "table", "nil")
	check(unit, 3, "string", "nil")
	check(styleFunc, 4, "function", "nil")

	-- Assign the widget meta methods
	setmetatable(frame, WidgetFrame_MT)

	return LibWidgetContainer:InitWidgetContainer(frame, unit, styleFunc, ...)
end

-- Create a frame with certain extra methods we like to have
-- Currently assumes a frame of type "Button" or anything farther up in the hierarchy
LibWidgetContainer.CreateWidgetContainer = function(self, frameType, parent, template, unit, styleFunc, ...) 
	check(frameType, 1, "string", "nil")
	check(parent, 2, "string", "table", "nil")
	check(template, 3, "string", "nil")
	check(unit, 4, "string", "nil")
	check(styleFunc, 5, "function", "nil")

	-- This is for Clique compatibility, 
	-- as it requires global frame names to function. 
	local name
	if unit then 
		local counter = 0
		for frame in pairs(frames) do 
			counter = counter + 1
		end 
		name = "CG_UnitFrame_"..(counter + 1)
	end 

	local frame = setmetatable(LibWidgetContainer:CreateFrame(frameType or "Frame", name, parent, template or "SecureHandlerAttributeTemplate"), WidgetFrame_MT)

	-- we sure we want to be doing this?
	frame:SetFrameStrata("LOW")
	frame:SetFrameLevel(1000)
	
	return LibWidgetContainer:InitWidgetContainer(frame, unit, styleFunc, ...)
end

-- register a widget/element
LibWidgetContainer.RegisterElement = function(self, elementName, enableFunc, disableFunc, updateFunc, version)
	check(elementName, 1, "string")
	check(enableFunc, 2, "function")
	check(disableFunc, 3, "function")
	check(updateFunc, 4, "function")
	check(version, 5, "number", "nil")

	-- Does an old version of the element exist?
	local old = elements[elementName]
	local needUpdate
	if old then
		if old.version then 
			if version then 
				if version <= old.version then 
					return 
				end 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				return 
			end 
		else 
			if version then 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				-- Two unversioned. just follow first come first served, 
				-- to allow the standalone addon to trumph. 
				return 
			end 
		end  
	end 

	-- Create our new element 
	local new = {
		Enable = enableFunc,
		Disable = disableFunc,
		Update = updateFunc,
		version = version
	}

	-- Change the pointer to the new element
	-- (doesn't change what table 'old' still points to)
	elements[elementName] = new 

	-- Postupdate existing frames embedding this if it exists
	if needUpdate then 

		-- Iterate all frames for it
		for widgetFrame, element in pairs(frameElementsEnabled) do 
			if (element == elementName) then 

				-- Run the old disable method, 
				-- to get rid of old events and onupdate handlers.
				if old.Disable then 
					old.Disable(widgetFrame)
				end 

				-- Run the new enable method
				if new.Enable then 
					new.Enable(widgetFrame, widgetFrame.unit, true)
				end 
			end 
		end 
	end 
end

-- Module embedding
local embedMethods = {
	CreateWidgetContainer = true,
	GetWidgetContainer = true,
	ApplyWidgetContainer = true
}

LibWidgetContainer.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibWidgetContainer.embeds) do
	LibWidgetContainer:Embed(target)
end
