local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end
local Module = Core:NewModule("BlizzardFloaterHUD", "LibEvent", "LibFrame", "LibTooltip", "LibDB", "LibBlizzard", "LibClientBuild")

-- Lua API
local _G = _G
local ipairs = ipairs
local table_remove = table.remove

local MAPPY = Module:IsAddOnEnabled("Mappy")

local mt = getmetatable(CreateFrame("Frame")).__index
local Frame_ClearAllPoints = mt.ClearAllPoints
local Frame_IsShown = mt.IsShown
local Frame_SetParent = mt.SetParent
local Frame_SetPoint = mt.SetPoint

local HolderCache, StyleCache = {}, {}
local Layout

-- Default settings
local defaults = {}

local DisableTexture = function(texture, _, loop)
	if loop then
		return
	end
	texture:SetTexture(nil, true)
end

local ResetPoint = function(object, _, anchor) 
	local holder = object and HolderCache[object]
	if (holder) then 
		if (anchor ~= holder) then
			Frame_SetParent(object, holder)
			Frame_ClearAllPoints(object)
			Frame_SetPoint(object, "CENTER", holder, "CENTER", 0, 0)
		end
	end 
end

Module.CreateHolder = function(self, object, ...)
	HolderCache[object] = HolderCache[object] or self:CreateFrame("Frame", nil, "UICenter")
	HolderCache[object]:Place(...)
	HolderCache[object]:SetSize(2,2)
	return HolderCache[object]
end

Module.CreatePointHook = function(self, object)
	-- Always do this.
	ResetPoint(object)

	-- Don't create multiple hooks
	if (not StyleCache[object]) then 
		hooksecurefunc(object, "SetPoint", ResetPoint)
	end
end 

Module.DisableMappy = function(object)
	if MAPPY then 
		object.Mappy_DidHook = true -- set the flag indicating its already been set up for Mappy
		object.Mappy_SetPoint = function() end -- kill the IsVisible reference Mappy makes
		object.Mappy_HookedSetPoint = function() end -- kill this too
		object.SetPoint = nil -- return the SetPoint method to its original metamethod
		object.ClearAllPoints = nil -- return the SetPoint method to its original metamethod
	end 
end

Module.StyleDurabilityFrame = function(self)
	-- This still breaks in 8.2.0, regardless of our frame library updates. 
	-- So until further changes have been made, we need it disabled. 
	if (not Layout.StyleDurabilityFrame) or (self:IsBuild("8.2.0")) then 
		return 
	end

	self:DisableMappy(DurabilityFrame)
	self:CreateHolder(DurabilityFrame, unpack(Layout.DurabilityFramePlace))
	self:CreatePointHook(DurabilityFrame)

	-- This will prevent the durability frame size from affecting other blizzard anchors
	DurabilityFrame.IsShown = function() return false end

end 

Module.StyleErrorFrame = function(self)
	if (not Layout.StyleErrorFrame) then 
		return 
	end 

	local frame = UIErrorsFrame

	if Layout.ErrorFrameStrata then 
		frame:SetFrameStrata(Layout.ErrorFrameStrata)
	end 
end 

Module.GetFloaterTooltip = function(self)
	return self:GetTooltip("CG_FloaterTooltip") or self:CreateTooltip("CG_FloaterTooltip")
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardFloaterHUD]")
end 

Module.OnInit = function(self)
	self.db = self:NewConfig("FloaterHUD", defaults, "global")
end 

Module.OnEnable = function(self)
	self:StyleDurabilityFrame()
	self:StyleErrorFrame()
end

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end