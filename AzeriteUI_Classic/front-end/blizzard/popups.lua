local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardPopupStyling", "LibEvent")
local Layout

-- Lua API
local _G = _G

-- WoW API
local InCombatLockdown = _G.InCombatLockdown

Module.StylePopUp = function(self, popup)
	if (self.styled and self.styled[popup]) then 
		return 
	end 
	if (not self.styled) then
		self.styled = {}
	end
	if Layout.PostCreatePopup then 
		Layout.PostCreatePopup(self, popup)
	end 
	self.styled[popup] = true
end

-- Not strictly certain if moving them in combat would taint them, 
-- but knowing the blizzard UI, I'm not willing to take that chance.
Module.PostUpdateAnchors = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 
	if Layout.PostUpdateAnchors then 
		Layout.PostUpdateAnchors(self)
	end 
end

Module.StylePopUps = function(self)
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local popup = _G["StaticPopup"..i]
		if popup then
			self:StylePopUp(popup)
		end
	end
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:PostUpdateAnchors()
	end 
end 

Module.PreInit = function(self)
	Layout = CogWheel("LibDB"):GetDatabase(Core:GetPrefix()..":[BlizzardPopupStyling]")
end 

Module.OnInit = function(self)
	self:StylePopUps() 
	self:PostUpdateAnchors() 

	-- The popups are re-anchored by blizzard, so we need to re-adjust them when they do.
	hooksecurefunc("StaticPopup_SetUpPosition", function() self:PostUpdateAnchors() end)
end 
