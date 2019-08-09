
-- Lua API
local _G = _G

-- WoW API
local GetReadyCheckStatus = _G.GetReadyCheckStatus
local UnitExists = _G.UnitExists

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.ReadyCheck
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local status = GetReadyCheckStatus(unit)
	if (UnitExists(unit) and status) then
		if(status == "ready") then
			element:SetTexture(element.readyTexture)
		elseif(status == "notready") then
			element:SetTexture(element.notReadyTexture)
		else
			element:SetTexture(element.waitingTexture)
		end
		element:Show()
	elseif(event ~= "READY_CHECK_FINISHED") then
		status = nil
		element:Hide()
	end

	element.status = status

	if(event == "READY_CHECK_FINISHED") then
		if (element.status == "waiting") then
			element:SetTexture(element.notReadyTexture)
		end
		element.FadeOut:Play()
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit, status)
	end 
end 

local Proxy = function(self, ...)
	return (self.ReadyCheck.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.ReadyCheck
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		element.readyTexture = element.readyTexture or [[Interface/RAIDFRAME/ReadyCheck-Ready]]
		element.notReadyTexture = element.notReadyTexture or [[Interface/RAIDFRAME/ReadyCheck-NotReady]]
		element.waitingTexture = element.waitingTexture or [[Interface/RAIDFRAME/ReadyCheck-Waiting]]

		local animGroup = element:CreateAnimationGroup()
		animGroup:HookScript("OnFinished", function() 
			element:Hide() 
			element:PostUpdate(self.unit)
		end)
		element.FadeOut = animGroup

		local fadeOut = animGroup:CreateAnimation("Alpha")
		fadeOut:SetFromAlpha(1)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(element.fadeTime or 1.5)
		fadeOut:SetStartDelay(element.finishedTime or 10)

		self:RegisterEvent("READY_CHECK", Proxy, true)
		self:RegisterEvent("READY_CHECK_CONFIRM", Proxy, true)
		self:RegisterEvent("READY_CHECK_FINISHED", Proxy, true)

		return true
	end
end 

local Disable = function(self)
	local element = self.ReadyCheck
	if element then
		self:UnregisterEvent("READY_CHECK", Proxy)
		self:UnregisterEvent("READY_CHECK_CONFIRM", Proxy)
		self:UnregisterEvent("READY_CHECK_FINISHED", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("ReadyCheck", Enable, Disable, Proxy, 3)
end 
