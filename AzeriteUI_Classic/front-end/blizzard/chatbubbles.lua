local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("ChatBubbles", "LibEvent", "LibChatBubble")
Module:SetIncompatible("Prat-3.0")

local PostCreateBubble = function(bubble)
end

local PostUpdateBubble = function(bubble)
end

Module.OnInit = function(self)
end 

Module.OnEnable = function(self)
	self:EnableBubbleStyling()
	self:SetBubblePostCreateFunc(PostCreateBubble)
	self:SetBubblePostCreateFunc(PostUpdateBubble)
end 
