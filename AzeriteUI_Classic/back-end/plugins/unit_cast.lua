local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "UnitCast requires LibClientBuild to be loaded.")

local IS_CLASSIC = LibClientBuild:IsClassic()

-- Lua API
local _G = _G
local math_floor = math.floor
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetCVar = _G.GetCVar
local GetNetStats = _G.GetNetStats
local GetTime = _G.GetTime
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local UnitClass = _G.UnitClass
local UnitExists = _G.UnitExists
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitReaction = _G.UnitReaction

-- Localization
local L_FAILED = _G.FAILED
local L_INTERRUPTED = _G.INTERRUPTED
local L_MILLISECONDS_ABBR = _G.MILLISECONDS_ABBR

-- Constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- Define it here so it can call itself later on
local Update

-- Utility Functions
-----------------------------------------------------------
local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

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
		return tostring(value - value%1)
	end	
end

local formatTime = function(time)
	if time > DAY then -- more than a day
		return ("%.0f%s"):format((time / DAY) - (time / DAY)%1, "d")
	elseif time > HOUR then -- more than an hour
		return ("%.0f%s"):format((time / HOUR) - (time / HOUR)%1, "h")
	elseif time > MINUTE then -- more than a minute
		return ("%.0f%s %.0f%s"):format((time / MINUTE) - (time / MINUTE)%1, "m", (time%MINUTE) - (time%MINUTE)%1, "s")
	elseif time > 10 then -- more than 10 seconds
		return ("%.0f%s"):format((time) - (time)%1, "s")
	elseif time > 0 then
		return ("%.1f"):format(time)
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
			return tostring((value) - (value)%1)
		end 
	end
end 

local clear = function(element)
	element.name = nil
	element.text = nil
	if element.Name then 
		element.Name:SetText("")
	end
	if element.Value then 
		element.Value:SetText("")
	end
	if element.Failed then 
		element.Failed:SetText("")
	end
	if element.SpellQueue then 
		element.SpellQueue:SetValue(0, true)
	end
	element:SetValue(0, true)
end

local updateSpellQueueOrientation = function(element)
	if (element.channeling) then 
		local orientation = element:GetOrientation()
		if (orientation ~= element.SpellQueue:GetOrientation()) then 
			element.SpellQueue:SetOrientation(orientation)
		end 
	else 
		local orientation
		local barDirection = element:GetOrientation()
		if (barDirection == "LEFT") then
			orientation = "RIGHT" 
		elseif (barDirection == "RIGHT") then 
			orientation = "LEFT" 
		elseif (barDirection == "UP") then 
			orientation = "DOWN" 
		elseif (barDirection == "DOWN") then 
			orientation = "UP" 
		end
		local spellQueueDirection = element.SpellQueue:GetOrientation()
		if (spellQueueDirection ~= orientation) then 
			element.SpellQueue:SetOrientation(orientation)
		end
	end 
end

local updateSpellQueueValue = function(element)
	local ms = tonumber(GetCVar("SpellQueueWindow")) or 400 -- that large value is WoW's default
	local max = element.total or element.max

	-- Don't allow values above max, it'd look wrong
	local value = ms / 1e3
	if (value > max) then
		value = max
	end

	-- Hide the overlay if it'd take up less than 5% of your bar, 
	-- or if the total length of the window is shorter than 100ms. 
	local ratio = value / max 
	if (ratio < .05) or (ms < 100) then 
		value = 0
	end 

	element.SpellQueue:SetMinMaxValues(0, max)
	element.SpellQueue:SetValue(value, true)
end

local UpdateColor = function(element, unit)
	if element.OverrideColor then
		return element:OverrideColor(unit)
	end
	local self = element._owner
	local color, r, g, b
	if (element.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		color = class and self.colors.class[class]
	elseif (element.colorPetAsPlayer and UnitIsUnit(unit, "pet")) then 
		local _, class = UnitClass("player")
		color = class and self.colors.class[class]
	elseif (element.colorReaction and UnitReaction(unit, "player")) then
		color = self.colors.reaction[UnitReaction(unit, "player")]
	end
	if color then 
		r, g, b = color[1], color[2], color[3]
	end 
	if (r) then 
		element:SetStatusBarColor(r, g, b)
	end 
	if element.PostUpdateColor then 
		element:PostUpdateColor(unit)
	end 
end

local OnUpdate = function(element, elapsed)
	local self = element._owner
	local unit = self.unit
	if (not unit) or (not UnitExists(unit)) then 
		clear(element)
		element.castID = nil
		element.casting = nil
		element.channeling = nil
		if (element:IsShown()) then 
			element:Hide()
			self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
		end
		return element.PostUpdate and element:PostUpdate(unit)
	end
	local r, g, b
	if (element.casting or element.tradeskill) then
		local duration = element.duration + elapsed
		if (duration >= element.max) then
			clear(element) 
			element.tradeskill = nil
			element.casting = nil
			element.channeling = nil
			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
			return element.PostUpdate and element:PostUpdate(unit)
		end
		if element.Value then
			if element.tradeskill then
				element.Value:SetText(formatTime(element.max - duration))
			elseif (element.delay and (element.delay > 0)) then
				element.Value:SetFormattedText("%s|cffff0000 +%s|r", formatTime(floor(element.max - duration)), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(element.max - duration))
			end
		end
		if element.SpellQueue then 
			updateSpellQueueValue(element)
		end 
		element.duration = duration
		element:SetValue(duration)

		if element.PostUpdate then 
			element:PostUpdate(unit, duration, element.max, element.delay)
		end

	elseif element.channeling then
		local duration = element.duration - elapsed
		if (duration <= 0) then
			clear(element)
			element.channeling = nil
			return element.PostUpdate and element:PostUpdate(unit)
		end
		if element.Value then
			if element.tradeskill then
				element.Value:SetText(formatTime(duration))
			elseif (element.delay and (element.delay > 0)) then
				element.Value:SetFormattedText("%s|cffff0000 +%s|r", formatTime(duration), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(duration))
			end
		end
		if element.SpellQueue then 
			updateSpellQueueValue(element)
		end 
		element.duration = duration
		element:SetValue(duration)

		if element.PostUpdate then 
			element:PostUpdate(unit, duration)
		end
		
	elseif element.failedMessageTimer then 
		element.failedMessageTimer = element.failedMessageTimer - elapsed
		if (element.failedMessageTimer > 0) then 
			return 
		end 
		element.failedMessageTimer = nil
		local msg = element.Failed or element.Value or element.Name
		if msg then 
			msg:SetText("")
		end
	else
		clear(element)
		element.casting = nil
		element.castID = nil
		element.channeling = nil
		if (element:IsShown()) then 
			element:Hide()
			self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
		end
		return element.PostUpdate and element:PostUpdate(unit)
	end
end 

Update = function(self, event, unit, ...)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Cast
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if (event == "UNIT_SPELLCAST_START") then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
		if name then
			endTime = endTime / 1e3
			startTime = startTime / 1e3

			local now = GetTime()
			local max = endTime - startTime

			element.castID = castID
			element.name = name
			element.text = text
			element.duration = now - startTime
			element.max = max
			element.delay = 0
			element.casting = true
			element.notInterruptible = notInterruptible
			element.tradeskill = isTradeSkill
			element.total = nil
			element.starttime = nil
			element.failedMessageTimer = nil
	
			element:SetMinMaxValues(0, element.total or element.max, true)
			element:SetValue(element.duration, true) 
			element:UpdateColor(unit)

			if element.Name then element.Name:SetText(utf8sub(text, 32, true)) end
			if element.Icon then element.Icon:SetTexture(texture) end
			if element.Value then element.Value:SetText("") end
			if element.Shield then 
				if element.notInterruptible and not UnitIsUnit(unit ,"player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
			if element.SpellQueue then 
				updateSpellQueueOrientation(element)
				updateSpellQueueValue(element)
			end 
	
			if (not element:IsShown()) then 
				element:Show()
				self:SendMessage("CG_UNITFRAME_HAS_CAST_ELEMENT", self, unit)
			end

		else
			element:SetValue(0, true)
			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end
		
	elseif (event == "UNIT_SPELLCAST_FAILED") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end
		
		clear(element)
		
		element.tradeskill = nil
		element.total = nil
		element.casting = nil
		element.channeling = nil
		element.notInterruptible = nil
		element.castID = nil

		if element.Shield then element.Shield:Hide() end 

		if element.timeToHold then
			element.failedMessageTimer = element.timeToHold
			local msg = element.Failed or element.Value or element.Name
			if msg then 
				msg:SetText(utf8sub(L_FAILED, 32, true)) 
			end 
		else
			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end 
		
	elseif (event == "UNIT_SPELLCAST_STOP") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end

		clear(element)
		element.casting = nil
		element.notInterruptible = nil
		element.tradeskill = nil
		element.total = nil

		if (element:IsShown()) then 
			element:Hide()
			self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
		end
		
	elseif (event == "UNIT_SPELLCAST_INTERRUPTED") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end
		
		clear(element)

		element.tradeskill = nil
		element.total = nil
		element.casting = nil
		element.channeling = nil
		element.notInterruptible = nil
		element.castID = nil

		if element.Shield then element.Shield:Hide() end 

		if element.timeToHold then
			element.failedMessageTimer = element.timeToHold
			local msg = element.Failed or element.Value or element.Name
			if msg then 
				msg:SetText(utf8sub(L_INTERRUPTED, 32, true)) 
			end 
		else
			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end 

		
	elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") then 
		element.notInterruptible = nil
		if element.Shield then 
			if element.notInterruptible and (not UnitIsUnit(unit ,"player")) then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end

	elseif (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
		element.notInterruptible = true
		if element.Shield then 
			if element.notInterruptible and (not UnitIsUnit(unit ,"player")) then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end
	
	elseif (event == "UNIT_SPELLCAST_DELAYED") then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
		if (not startTime) or (not element.duration) then 
			return 
		end
		
		local duration = GetTime() - (startTime / 1000)
		if (duration < 0) then 
			duration = 0 
		end

		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration

		element:SetValue(duration)
		
	elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then	
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		if name then
			endTime = endTime / 1e3
			startTime = startTime / 1e3

			local max = endTime - startTime
			local duration = endTime - GetTime()

			element.duration = duration
			element.max = max
			element.delay = 0
			element.channeling = true
			element.notInterruptible = notInterruptible
			element.name = name
			element.text = text

			element.casting = nil
			element.castID = nil
			element.failedMessageTimer = nil
	
			element:SetMinMaxValues(0, max, true)
			element:SetValue(duration, true)
			element:UpdateColor(unit)

			if element.Name then element.Name:SetText(utf8sub(name, 32, true)) end
			if element.Icon then element.Icon:SetTexture(texture) end
			if element.Value then element.Value:SetText("") end
			if element.Shield then 
				if element.notInterruptible and not UnitIsUnit(unit ,"player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
			if element.SpellQueue then 
				updateSpellQueueOrientation(element)
				updateSpellQueueValue(element)
			end 

			if (not element:IsShown()) then 
				element:Show()
				self:SendMessage("CG_UNITFRAME_HAS_CAST_ELEMENT", self, unit)
			end
			
		else
			element:SetValue(0, true)

			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end
		
	elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		if (not name) or (not element.duration) then 
			return 
		end

		local duration = (endTime / 1000) - GetTime()
		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration
		element.max = (endTime - startTime) / 1000

		if element.SpellQueue then 
			updateSpellQueueValue(element)
		end 
	
		element:SetMinMaxValues(0, element.max)
		element:SetValue(duration)
	
	elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
		if element:IsShown() then
			clear(element)
			element.channeling = nil
			element.notInterruptible = nil
			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end
		
	else
		if UnitCastingInfo(unit) then
			return Update(self, "UNIT_SPELLCAST_START", unit)
		end
		if UnitChannelInfo(unit) then
			return Update(self, "UNIT_SPELLCAST_CHANNEL_START", unit)
		end
		if (not element.failedMessageTimer) then 
			clear(element)

			element.casting = nil
			element.notInterruptible = nil
			element.tradeskill = nil
			element.total = nil

			if (element:IsShown()) then 
				element:Hide()
				self:SendMessage("CG_UNITFRAME_LOST_CAST_ELEMENT", self, unit)
			end
		end 
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Cast.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Cast
	if element then
		if IS_CLASSIC then 
			element:Hide()
			return
		end 

		element._owner = self
		element.ForceUpdate = ForceUpdate

		-- Events doesn't fire for (unit)target units, 
		-- so we're relying on the unitframe library's global update handler for that.
		local unit = self.unit
		if (not (unit and unit:match("%wtarget$"))) then
			self:RegisterEvent("UNIT_SPELLCAST_START", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_FAILED", Proxy)
			--self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_STOP", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_DELAYED", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Proxy)

			if (not IS_CLASSIC) then 
				self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Proxy)
				self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Proxy)
			end 
		end 

		element.UpdateColor = UpdateColor
		element:SetScript("OnUpdate", OnUpdate)

		return true
	end
end 

local Disable = function(self)
	local element = self.Cast
	if element then
		element:SetScript("OnUpdate", nil)
		element:Hide()

		if IS_CLASSIC then 
			return
		end 

		self:UnregisterEvent("UNIT_SPELLCAST_START", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED", Proxy)
		--self:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_STOP", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_DELAYED", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Proxy)

		if (not IS_CLASSIC) then 
			self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED", Proxy)
			self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Proxy)
		end
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Cast", Enable, Disable, Proxy, 24)
end 
