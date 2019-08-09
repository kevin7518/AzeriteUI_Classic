
-- Lua API
local _G = _G

-- WoW API
local GetLatestThreeSenders = _G.GetLatestThreeSenders
local HasNewMail = _G.HasNewMail

local GetTooltip = function(element)
	return element.GetTooltip and element:GetTooltip() or element._owner.GetTooltip and element._owner:GetTooltip()
end 

local OnEnter = function(element)
	local tooltip = GetTooltip(element)
	if (not tooltip) then 
		return 
	end 

	tooltip:SetDefaultAnchor()
	
	local sender1, sender2, sender3 = GetLatestThreeSenders()
	if (sender1 or sender2 or sender3) then

		tooltip:AddLine(HAVE_MAIL_FROM, 240/255, 240/255, 240/255)

		if sender1 then
			tooltip:AddLine(sender1, 25/255, 178/255, 25/255)
		end

		if sender2 then
			tooltip:AddLine(sender2, 25/255, 178/255, 25/255)
		end

		if sender3 then
			tooltip:AddLine(sender3, 25/255, 178/255, 25/255)
		end

	else
		tooltip:AddLine(HAVE_MAIL, 240/255, 240/255, 240/255)
	end

	tooltip:Show()
end

local OnLeave = function(element)
	local tooltip = GetTooltip(element)
	if (not tooltip) then 
		return 
	end 
	tooltip:Hide()
end 

local Update = function(self, event, ...)
	local element = self.Mail
	if (element.PreUpdate) then 
		element:PreUpdate()
	end 
	local hasMail = HasNewMail()
	if hasMail then
		element:Show()
	else
		element:Hide()
	end
	if (element.PostUpdate) then 
		return element:PostUpdate(element, hasMail)
	end 
end 

local Proxy = function(self, ...)
	return (self.Mail.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Mail
	if element then 
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateTooltip = UpdateTooltip

		element:SetScript("OnEnter", OnEnter)
		element:SetScript("OnLeave", OnLeave)

		self:RegisterEvent("UPDATE_PENDING_MAIL", Proxy)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)

		return true
	end 
end 

local Disable = function(self)
	local element = self.Mail
	if element then 
		element.UpdateTooltip = nil

		element:SetScript("OnEnter", nil)
		element:SetScript("OnLeave", nil)

		self:UnregisterEvent("UPDATE_PENDING_MAIL", Proxy)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	end 
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)), (CogWheel("LibMinimap", true)) }) do 
	Lib:RegisterElement("Mail", Enable, Disable, Proxy, 6)
end 
