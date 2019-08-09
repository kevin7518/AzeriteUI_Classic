
local LibDB = CogWheel("LibDB")
assert(LibDB, "UnitRange requires LibDB to be loaded.")

-- Really do this?
-- I do NOT like exposing this, but I don't want multiple update handlers either,
-- neither from multiple frames using this element or multiple versions of the plugin.
local UnitRangeDB = LibDB:GetDatabase("UnitRangeDB", true) or LibDB:NewDatabase("UnitRangeDB")
UnitRangeDB.frames = UnitRangeDB.frames or {}

-- Shortcut it
local Frames = UnitRangeDB.frames

-- Lua API
local _G = _G

-- WoW API
local UnitInRange = _G.UnitInRange
local UnitIsConnected = _G.UnitIsConnected

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Range
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local isInRange, isRangeInfoAvailable
	local isConnected = UnitIsConnected(unit)
	if isConnected then
		isInRange, isRangeInfoAvailable = UnitInRange(unit)
		if (isRangeInfoAvailable and (not isInRange)) then
			self:SetAlpha(element.outsideAlpha)
		else
			self:SetAlpha(element.insideAlpha)
		end
	else
		self:SetAlpha(element.insideAlpha)
	end
			
	if element.PostUpdate then
		return element:PostUpdate(unit, isConnected, isInRange, isRangeInfoAvailable)
	end	
end 

local Proxy = function(self, ...)
	return (self.Range.Override or Update)(self, ...)
end 

local timer = 0
local OnUpdate_Range = function(_, elapsed)
	timer = timer + elapsed
	if (timer >= .2) then
		for frame in pairs(Frames) do 
			if (frame:IsShown()) then
				Proxy(frame, "OnUpdate", frame.unit)
			end
		end
		timer = 0
	end
end

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Range
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.insideAlpha = element.insideAlpha or 1
		element.outsideAlpha = element.outsideAlpha or .55

		Frames[self] = true

		-- We create the range frame on the fly
		if (not UnitRangeDB.RangeFrame) then
			UnitRangeDB.RangeFrame = CreateFrame("Frame")
		end
		UnitRangeDB.RangeFrame:SetScript("OnUpdate", OnUpdate_Range)
		UnitRangeDB.RangeFrame:Show()

		return true
	end
end 

local Disable = function(self)
	local element = self.Range
	if element then
		
		-- Erase the entry
		Frames[self] = nil

		-- Return the alpha to its fallback or full
		self:SetAlpha(element.insideAlpha or 1)

		-- Spooky fun way to return if the table has entries! 
		for frame in pairs(Frames) do 
			return 
		end 

		-- Hide the range frame if the previous returned zero table entries
		if UnitRangeDB.RangeFrame then 
			UnitRangeDB.RangeFrame:Hide()
		end 
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Range", Enable, Disable, Proxy, 2)
end 

