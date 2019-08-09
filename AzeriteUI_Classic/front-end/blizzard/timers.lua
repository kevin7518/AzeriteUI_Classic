local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end
local Module = Core:NewModule("BlizzardMirrorTimers", "LibMessage", "LibEvent", "LibSecureHook", "LibFrame", "LibStatusBar")
local Layout

-- Lua API
local _G = _G
local math_floor = math.floor
local table_insert = table.insert
local table_sort = table.sort
local table_wipe = table.wipe
local unpack = unpack

-- WoW API 
local GetAlternatePowerInfoByID = _G.GetAlternatePowerInfoByID
local GetTime = _G.GetTime
local UnitAlternatePowerCounterInfo = _G.UnitAlternatePowerCounterInfo
local UnitPowerBarTimerInfo = _G.UnitPowerBarTimerInfo

-- WoW Constants
local ALT_POWER_TYPE_COUNTER = ALT_POWER_TYPE_COUNTER or 4

-- Utility Functions
-----------------------------------------------------------------
local sort = function(a, b)
	if (a.type and b.type and (a.type == b.type)) then
		return a.id < b.id -- same type, order by their id
	else
		return a.type < b.type -- different type, order by type
	end
end

Module.StyleTimer = function(self, frame, ignoreTextureFix)
	local timer = self.timers[frame.bar]
	local bar = timer.bar

	if (not ignoreTextureFix) then 
		for i = 1,frame:GetNumRegions() do 
			local region = select(i, frame:GetRegions())
			if (region and region:IsObjectType("Texture")) then 
				region:SetTexture(nil)
			end 
		end 
		for i = 1,bar:GetNumRegions() do 
			local region = select(i, bar:GetRegions())
			if (region and region:IsObjectType("Texture")) then 
				region:SetTexture(nil)
			end 
		end 
	end

	frame:SetSize(unpack(Layout.Size))

	bar:ClearAllPoints()
	bar:SetPoint(unpack(Layout.BarPlace))
	bar:SetSize(unpack(Layout.BarSize))
	bar:SetStatusBarTexture(Layout.BarTexture)
	bar:SetFrameLevel(frame:GetFrameLevel() + 5)

	if Layout.UseBackdrop then 
		local backdrop = bar:CreateTexture()
		backdrop:SetPoint(unpack(Layout.BackdropPlace))
		backdrop:SetSize(unpack(Layout.BackdropSize))
		backdrop:SetDrawLayer(unpack(Layout.BackdropDrawLayer))
		backdrop:SetTexture(Layout.BackdropTexture)
		backdrop:SetVertexColor(unpack(Layout.BackdropColor))
	end

	if (not ignoreTextureFix) then 
		-- just hide the spark for now
		local spark = timer.spark
		if spark then 
			spark:SetDrawLayer("OVERLAY") -- needs to be OVERLAY, as ARTWORK will sometimes be behind the bars
			spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
			spark:SetSize(.001,.001)
			spark:SetTexture(Layout.BlankTexture) 
			spark:SetVertexColor(0,0,0,0)
		end 

		-- hide the default border
		local border = timer.border
		if border then 
			border:ClearAllPoints()
			border:SetPoint("CENTER", 0, 0)
			border:SetSize(.001, .001)
			border:SetTexture(Layout.BlankTexture)
			border:SetVertexColor(0,0,0,0)
		end 
	end 

	if Layout.UseBarValue then 
		local msg = timer.msg
		if msg then 
			msg:SetParent(bar)
			msg:ClearAllPoints()
			msg:SetPoint(unpack(Layout.BarValuePlace))
			msg:SetDrawLayer("OVERLAY", 1)
			msg:SetJustifyH("CENTER")
			msg:SetJustifyV("MIDDLE")
			msg:SetFontObject(Layout.BarValueFont)
			msg:SetTextColor(unpack(Layout.BarValueColor))
		end 

	end 

	if (not ignoreTextureFix) then 
		self:SetSecureHook(bar, "SetValue", "UpdateBarTexture")
		self:SetSecureHook(bar, "SetMinMaxValues", "UpdateBarTexture")
	end 
end

Module.UpdateBarTexture = function(self, event, bar)
	local min, max = bar:GetMinMaxValues()
	local value = bar:GetValue()
	if ((not min) or (not max) or (not value)) then
		return
	end
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	bar:GetStatusBarTexture():SetTexCoord(0, (value-min)/(max-min), 0, 1) -- cropping, not shrinking
end

Module.UpdateAnchors = function(self, event, ...)
	local timers = self.timers
	local order = self.order or {}

	-- Reset the order table
	for i = #order,1,-1 do 
		order[i] = nil
	end 
	
	-- Release the points of all timers
	for bar,timer in pairs(timers) do
		timer.frame:SetParent(Layout.Anchor)
		timer.frame:ClearAllPoints() 
		if (timer.frame:IsShown()) then
			order[#order + 1] = timer
		end
	end	
	
	-- Sort and arrange visible timers
	if (#order > 0) then

		-- Sort by type -> id
		table_sort(order, sort) 

		-- Figure out the start offset
		local offsetY = Layout.AnchorOffsetY 

		-- Add space for capturebars, if visible
		if self.captureBarVisible then 
			offsetY = offsetY + Layout.Growth
		end 

		-- Position the bars
		for i = 1, #order do
			order[i].frame:SetPoint(Layout.AnchorPoint, Layout.Anchor, Layout.AnchorPoint, Layout.AnchorOffsetX, offsetY)
			offsetY = offsetY + Layout.Growth
		end
	end
end

Module.UpdateMirrorTimers = function(self)
	local timers = self.timers
	for i = 1, MIRRORTIMER_NUMTIMERS do
		local name  = "MirrorTimer"..i
		local frame = _G[name]
		
		if (frame and (not frame.bar or not timers[frame.bar])) then 
			frame.bar = _G[name.."StatusBar"]

			timers[frame.bar] = {}
			timers[frame.bar].frame = frame
			timers[frame.bar].name = name
			timers[frame.bar].bar = frame.bar
			timers[frame.bar].msg = _G[name.."Text"] or _G[name.."StatusBarTimeText"]
			timers[frame.bar].border = _G[name.."Border"] or _G[name.."StatusBarBorder"]
			timers[frame.bar].type = 1
			timers[frame.bar].id = i

			self:StyleTimer(frame)
		end 
	end 
	if (event ~= "ForceUpdate") then 
		self:UpdateAnchors()
	end 
end

Module.ForceUpdate = function(self)
	self:UpdateMirrorTimers("ForceUpdate")
	self:UpdateAnchors()
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[BlizzardTimers]")
end 

Module.OnInit = function(self)
	self.timers = {} -- all timer data, hashed by bar objects
	self.buffTimers = {} -- all buff timer frames, indexed
	self.buffTimersByAuraID = {} -- all active buff timers, hashed by auraID

	-- Update mirror timers (breath/fatigue)
	self:SetSecureHook("MirrorTimer_Show", "UpdateMirrorTimers")

	-- Update all on world entering
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ForceUpdate")
end
