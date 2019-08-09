
-- Lua API
local _G = _G
local string_find = string.find

-- WoW API
local SetPortraitTexture = _G.SetPortraitTexture
local UnitClass = _G.UnitClass
local UnitGUID = _G.UnitGUID
local UnitIsConnected = _G.UnitIsConnected
local UnitIsVisible = _G.UnitIsVisible

-- WoW Objects
local CLASS_ICON_TCOORDS = _G.CLASS_ICON_TCOORDS

-- Simple constant to turn degrees into radians
local degToRad = (2*math.pi)/180

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Portrait
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local guid = UnitGUID(unit) 

	if (element:IsObjectType("Model")) then 
		-- Bail out on portrait updates that aren't unit changes, 
		-- to avoid the animation bouncing around randomly.
		local guid = UnitGUID(unit)
		if (not UnitIsVisible(unit) or not UnitIsConnected(unit)) then
			if (element.showFallback2D) then 
				element:ClearModel()
				if (not element.fallback2DTexture) then 
					element.fallback2DTexture = element:CreateTexture()
					element.fallback2DTexture:SetDrawLayer("ARTWORK")
					element.fallback2DTexture:SetAllPoints()
					element.fallback2DTexture:SetTexCoord(.1, .9, .1, .9)
				end 
				SetPortraitTexture(element.fallback2DTexture, unit)
				element.fallback2DTexture:Show()
			else 
				element:SetCamDistanceScale(.35)
				element:SetPortraitZoom(0)
				element:SetPosition(0, 0, .25)
				element:SetRotation(0)
				element:ClearModel()
				element:SetModel([[interface\buttons\talktomequestionmark.m2]])
			end 
			element.guid = nil

		elseif (element.guid ~= guid or (event == "UNIT_MODEL_CHANGED")) then 
			if (element.fallback2DTexture) then 
				element.fallback2DTexture:Hide()
			end 

			element:SetCamDistanceScale(element.distanceScale or 1)
			element:SetPortraitZoom(1)
			element:SetPosition(element.positionX or 0, element.positionY or 0, element.positionZ or 0)
			element:SetRotation(element.rotation and element.rotation*degToRad or 0)
			element:ClearModel()
			element:SetUnit(unit)
			element.guid = guid
		end

	elseif element.showClass then 
		if (element.fallback2DTexture) then 
			element.fallback2DTexture:Hide()
		end 

		local _,classToken = UnitClass(unit)
		if classToken then
			element:SetTexture(element.classTexture or [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
			element:SetTexCoord(CLASS_ICON_TCOORDS[classToken][1], CLASS_ICON_TCOORDS[classToken][2], CLASS_ICON_TCOORDS[classToken][3], CLASS_ICON_TCOORDS[classToken][4])
		else
			element:SetTexture(nil)
		end
	else 
		if (element.fallback2DTexture) then 
			element.fallback2DTexture:Hide()
		end 

		element:SetTexCoord(.1, .9, .1, .9)
		SetPortraitTexture(element, unit)
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Portrait.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Portrait
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
	
		self:RegisterEvent("PORTRAITS_UPDATED", Proxy, true)
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", Proxy)
		self:RegisterEvent("UNIT_MODEL_CHANGED", Proxy)
		self:RegisterEvent("UNIT_CONNECTION", Proxy)

		if (self.unit and string_find(self.unit, "^party")) then
			self:RegisterEvent("PARTY_MEMBER_ENABLE", Proxy)
		end
	
		return true 
	end
end 

local Disable = function(self)
	local element = self.Portrait
	if element then
		element:Hide()

		self:UnregisterEvent("PARTY_MEMBER_ENABLE", Proxy)
		self:UnregisterEvent("PORTRAITS_UPDATED", Proxy)
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_MODEL_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_CONNECTION", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Portrait", Enable, Disable, Proxy, 7)
end 
