local LibHook = CogWheel:Set("LibHook", 7)
if (not LibHook) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local type = type

LibHook.embeds = LibHook.embeds or {}
LibHook.hooks = LibHook.hooks or {} 
LibHook.modules = LibHook.modules or {} 

local Hooks = LibHook.hooks
local Modules = LibHook.modules

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

-- @input 
-- frameHandle, scriptHandler, hook[, uniqueID]
LibHook.ClearHook = function(self, frame, handler, hook, uniqueID)
	check(frame, 1, "table")
	check(handler, 2, "string")
	check(hook, 3, "function", "string")

	if (not Hooks[frame]) or (not Hooks[frame][handler]) then 
		return 
	end 

	local hookList = Hooks[frame][handler]

	if uniqueID then 
		hookList.unique[uniqueID] = nil
	else 
		for id = #hookList.list,1,-1 do 
			local func = hookList.list[id]
			if (func == hook) then 
				table_remove(hookList.list, id)
			end 
		end 
	end 
end 

-- @input 
-- frameHandle, scriptHandler, hook[, uniqueID]
LibHook.SetHook = function(self, frame, handler, hook, uniqueID)
	check(frame, 1, "table")
	check(handler, 2, "string")
	check(hook, 3, "function", "string")
	check(uniqueID, 4, "string", "nil")

	-- If the hook is a method, we need a uniqueID for our module reference list!
	if (type(hook) == "string") then 

		-- Let's make this backwards compatible and just make up an ID when it's not provided(?)
		if (not uniqueID) then 
			uniqueID = (self:GetName()).."_"..hook
		end

		-- Reference the module
		Modules[uniqueID] = self
	end

	if (not Hooks[frame]) then 
		Hooks[frame] = {}
	end 

	if (not Hooks[frame][handler]) then 
		Hooks[frame][handler] = { list = {}, unique = {} }

		-- We only need a single handler
		-- Problem discovered in 8.2.0: 
		-- The 'self' here will only refer to the first module
		-- that registered a hook for this frame and script handler. 
		-- Meaning unless we track each registration's module, 
		-- we'll get a nil error or weird bug by usind the wrong 'self'!
		local hookList = Hooks[frame][handler]
		frame:HookScript(handler, function(...)
			for id,func in pairs(hookList.unique) do 
				if (type(func) == "string") then 
					local module = Modules[id]
					if (module) then 
						module[func](module, id, ...)
					end
				else
					-- We allow unique hooks to just run a function
					-- without passing the self.
					func(...)
				end 
			end 

			-- This only ever occurs when the hook is a function, 
			-- and no uniqueID is given.
			for _,func in ipairs(hookList.list) do 
				func(...)
			end 
		end)
	end 
	
	local hookList = Hooks[frame][handler]

	if uniqueID then 
		hookList.unique[uniqueID] = hook
	else 
		local exists
		for _,func in ipairs(hookList.list) do 
			if (func == hook) then 
				exists = true 
				break 
			end 
		end 
		if (not exists) then 
			table_insert(hookList.list, hook)
		end 
	end 

end 

-- Module embedding
local embedMethods = {
	SetHook = true,
	ClearHook = true
}

LibHook.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibHook.embeds) do
	LibHook:Embed(target)
end
