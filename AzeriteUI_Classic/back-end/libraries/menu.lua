local LibMenu = CogWheel:Set("LibMenu", 1)
if (not LibMenu) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMenu requires LibFrame to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMenu requires LibMessage to be loaded.")

LibFrame:Embed(LibMenu)
LibMessage:Embed(LibMenu)

-- Lua API
local _G = _G
local assert = assert
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API

-- Library registries
LibMenu.embeds = LibMenu.embeds or {}
LibMenu.entries = LibMenu.entries or {}
LibMenu.menus = LibMenu.menus or {}
LibMenu.toggles = LibMenu.toggles or {}
LibMenu.containers = LibMenu.containers or {}

-- Shortcuts
local Entries = LibMenu.entries
local Menus = LibMenu.menus
local Toggles = LibMenu.toggles
local Containers = LibMenu.containers

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

local secureSnippets = {
	
}

-- Menu Template
local Menu = {}
local Menu_MT = { __index = Menu }

-- Container template
local Container = {}
local Container_MT = { __index = Container }

-- Entry template
local Entry = {}
local Entry_MT = { __index = Entry }

-- Toggle Button template
local Toggle = {}
local Toggle_MT = { __index = Toggle }

Menu.AddToogle = function(self)

	local toggle = setmetatable(self:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate"), Toggle_MT)
	

	if Menu.PostCreateToggle then 
		Menu:PostCreateToggle(toggle)
	end 

	return toggle
end

Menu.AddContainer = function(self, level, entryID)

	local container = setmetatable(self:CreateFrame("Frame", nil, parent or "UICenter", "SecureHandlerAttributeTemplate"), Container_MT)
	container:Hide()
	container:EnableMouse(true)
	container:SetFrameStrata("DIALOG")
	container:SetFrameLevel(frameLevel)
	if (level > 1) then 
		self:AddFrameToAutoHide(container)
	end 


	if Menu.PostCreateContainer then 
		Menu:PostCreateContainer(container)
	end 
end

Container.AddEntry = function(self, optionType, optionDB, optionName, ...)

	local entry = setmetatable(self:CreateFrame("CheckButton", nil, "SecureHandlerClickTemplate"), Entry_MT)

	if Container.PostCreateEntry then 
		Container:PostCreateEntry()
	end 

	return entry
end

LibMenu.CreateSecureCallbackHandler = function(self, menuID)
	check(menuID, 1, "string")
end

LibMenu.CreateOptionsMenu = function(self, menuID, menuTable)
	check(menuID, 1, "string")
	check(menuTable, 2, "table", "nil")

	if (LibMenu[self] and LibMenu[self][menuID]) then 
		error(("A menu with the ID '%s' is already registered to the module."):format(menu), 3)
	end

	local menu = setmetatable(LibMenu:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate"), Menu_MT)
	menu.id = menuID

	if menuTable then 

	end

	if (not LibMenu[self]) then 
		LibMenu[self] = {}
	end 
	LibMenu[self][menuID] = menu

	return menu
end

LibMenu.GetOptionsMenu = function(self, menuID)
	check(menuID, 1, "string")
	return LibMenu[self] and LibMenu[self][menuID]
end

LibMenu.GetSecureCallbackHandler = function(self, menuID)
	check(menuID, 1, "string")
end

local embedMethods = {
	CreateOptionsMenu = true,
	CreateSecureCallbackHandler = true, 
	GetOptionsMenu = true,
	GetSecureCallbackHandler = true
}

LibMenu.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMenu.embeds) do
	LibMenu:Embed(target)
end

-- Upgrade metatables of existing objects
for menu in pairs(Menus) do setmetatable(menu, Menu_MT) end 
for toggle in pairs(Toggles) do setmetatable(toggle, Toggle_MT) end 
for container in pairs(Containers) do setmetatable(container, Container_MT) end 
for entry in pairs(Entries) do setmetatable(entry, Entry_MT) end 
