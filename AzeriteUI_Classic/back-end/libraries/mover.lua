local LibMover = CogWheel:Set("LibMover", 34)
if (not LibMover) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMover requires LibFrame to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMover requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMover requires LibEvent to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibMover requires LibTooltip to be loaded.")

LibFrame:Embed(LibMover)
LibMessage:Embed(LibMover)
LibEvent:Embed(LibMover)
LibTooltip:Embed(LibMover)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_format = string.format
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API
local GetCursorPosition = _G.GetCursorPosition
local InCombatLockdown = _G.InCombatLockdown
local IsAltKeyDown = _G.IsAltKeyDown
local IsControlKeyDown = _G.IsControlKeyDown
local IsShiftKeyDown = _G.IsShiftKeyDown

-- WoW Frames
local UIParent = _G.UIParent

-- LibFrame master frame
local UICenter = LibMover:GetFrame("UICenter")

-- Library registries
LibMover.embeds = LibMover.embeds or {}
LibMover.moverData = LibMover.moverData or {} -- data for the movers, not directly exposed. 
LibMover.moverByTarget = LibMover.moverByTarget or {} -- [target] = mover  
LibMover.targetByMover = LibMover.targetByMover or {} -- [mover] = target  

-- Create the secure master frame
-- *we're making it secure to allow for modules
--  using a secure combat movable subsystem.
if (not LibMover.frame) then
	-- We're parenting this to the LibFrame master 'UICenter', not to UIParent. 
	-- Which means we need to recalculate all positions relative to this frame later on. 
	LibMover.frame = LibMover:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
else 
	-- Reset existing versions of the mover frame
	LibMover.frame:ClearAllPoints()

	-- Remove the visibility driver if it exists, we're not going with this from build 5+. 
	UnregisterAttributeDriver(LibMover.frame, "state-visibility")
end 

-- Speedcuts
local Parent = LibMover.frame
local MoverData = LibMover.moverData
local MoverByTarget = LibMover.moverByTarget
local TargetByMover = LibMover.targetByMover 

-- Alpha of the movers and handles
local ALPHA_STOPPED = .5
local ALPHA_DRAGGING = .25

-- Backdrop used for all frames
local BACKDROP = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeSize = 2, 
	tile = false, 
	insets = { 
		top = 0, 
		bottom = 0, 
		left = 0, 
		right = 0 
	}
}

local Colors = {
	backdrop = { 102/255, 102/255, 229/255 },
	border = { 76/255, 76/255, 178/255 },
	highlight = { 250/255, 250/255, 250/255 },
	normal = { 229/255, 178/255, 38/255 },
	offwhite = { 196/255, 196/255, 196/255 }, 
	title = { 255/255, 234/255, 137/255 },
	red = { 204/255, 25/255, 25/255 },
	orange = { 255/255, 128/255, 25/255 },
	yellow = { 255/255, 204/255, 25/255 },
	green = { 25/255, 178/255, 25/255 },
	gray = { 153/255, 153/255, 153/255 }
}

---------------------------------------------------
-- Utility Functions
---------------------------------------------------
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

-- Return a value rounded to the nearest integer.
local round = function(value, precision)
	if precision then
		value = value * 10^precision
		value = (value + .5) - (value + .5)%1
		value = value / 10^precision
		return value
	else 
		return (value + .5) - (value + .5)%1
	end 
end

-- Convert a coordinate within a frame to a usable position
local parse = function(parentWidth, parentHeight, x, y, bottomOffset, leftOffset, topOffset, rightOffset)
	if (y < parentHeight * 1/3) then 
		if (x < parentWidth * 1/3) then 
			return "BOTTOMLEFT", leftOffset, bottomOffset
		elseif (x > parentWidth * 2/3) then 
			return "BOTTOMRIGHT", rightOffset, bottomOffset
		else 
			return "BOTTOM", x - parentWidth/2, bottomOffset
		end 
	elseif (y > parentHeight * 2/3) then 
		if (x < parentWidth * 1/3) then 
			return "TOPLEFT", leftOffset, topOffset
		elseif x > parentWidth * 2/3 then 
			return "TOPRIGHT", rightOffset, topOffset
		else 
			return "TOP", x - parentWidth/2, topOffset
		end 
	else 
		if (x < parentWidth * 1/3) then 
			return "LEFT", leftOffset, y - parentHeight/2
		elseif (x > parentWidth * 2/3) then 
			return "RIGHT", rightOffset, y - parentHeight/2
		else 
			return "CENTER", x - parentWidth/2, y - parentHeight/2
		end 
	end 
end

local GetParsedPosition = function(frame)

	-- Retrieve UI coordinates
	local uiScale = UICenter:GetEffectiveScale()
	local uiWidth, uiHeight = UICenter:GetSize()
	local uiBottom = UICenter:GetBottom()
	local uiLeft = UICenter:GetLeft()
	local uiTop = UICenter:GetTop()
	local uiRight = UICenter:GetRight()

	-- Turn UI coordinates into unscaled screen coordinates
	uiWidth = uiWidth*uiScale
	uiHeight = uiHeight*uiScale
	uiBottom = uiBottom*uiScale
	uiLeft = uiLeft*uiScale
	uiTop = uiTop*uiScale - WorldFrame:GetHeight() -- use values relative to edges, not origin
	uiRight = uiRight*uiScale - WorldFrame:GetWidth() -- use values relative to edges, not origin

	-- Retrieve frame coordinates
	local frameScale = frame:GetEffectiveScale()
	local x, y = frame:GetCenter()
	local bottom = frame:GetBottom()
	local left = frame:GetLeft()
	local top = frame:GetTop()
	local right = frame:GetRight()

	-- Turn frame coordinates into unscaled screen coordinates
	x = x*frameScale
	y = y*frameScale
	bottom = bottom*frameScale
	left = left*frameScale
	top = top*frameScale - WorldFrame:GetHeight() -- use values relative to edges, not origin
	right = right*frameScale - WorldFrame:GetWidth() -- use values relative to edges, not origin

	-- Figure out the frame position relative to the UI master frame
	left = left - uiLeft
	bottom = bottom - uiBottom
	right = right - uiRight
	top = top - uiTop

	-- Figure out the point within the given coordinate space
	local point, offsetX, offsetY = parse(uiWidth, uiHeight, x, y, bottom, left, top, right)

	-- Convert coordinates to the frame's scale. 
	return point, offsetX/frameScale, offsetY/frameScale
end

---------------------------------------------------
-- Mover Template
---------------------------------------------------
local Mover = LibMover:CreateFrame("Button")
local Mover_MT = { __index = Mover }

-- Pre-localize methods to avoid order conflicts
local OnUpdate, OnShow, OnHide, OnEnter, OnLeave, OnClick, OnMouseWheel, OnDragStart, OnDragStop
local UpdatePosition, UpdateScale, UpdateTexts


-- Mover Callbacks
---------------------------------------------------
-- Called while the mover is being dragged
-- TODO: Make this reflect the dragged frame's coordinates instead of the cursor, 
-- as the cursor is bound to be in the middle of it, not its most logical edge.
OnUpdate = function(self, elapsed)
	local point, offsetX, offsetY = GetParsedPosition(self)
	UpdateTexts(self, point, offsetX, offsetY)
end

-- Called when the mover is shown
OnShow = function(self)

	local data = MoverData[self]
	local target = TargetByMover[self]

	-- Resize and reposition the mover frame. 
	local targetWidth, targetHeight = target:GetSize()
	local relativeScale = target:GetEffectiveScale() / self:GetEffectiveScale()
	
	self:SetSize(targetWidth*relativeScale, targetHeight*relativeScale)
	self:Place(data.point, "UICenter", data.point, data.offsetX, data.offsetY)
	
	LibMover:SendMessage("CG_MOVER_UNLOCKED", self, TargetByMover[self])
end 

-- Called when the mover is hidden
OnHide = function(self)
	LibMover:SendMessage("CG_MOVER_LOCKED", self, TargetByMover[self])
end 

-- Called when the mouse enters the mover
OnEnter = function(self)
	self.isMouseOver = true
	if self.OnEnter then 
		return self:OnEnter()
	end
end 

-- Called when them ouse leaves the mover
OnLeave = function(self)
	self.isMouseOver = nil
	self:GetTooltip():Hide()
	if self.OnLeave then 
		return self:OnLeave()
	end 
end 

-- Called when the mover is clicked
OnClick = function(self, button)
	if (IsAltKeyDown() or IsControlKeyDown()) and (self.OnClick) then 
		
		-- Call the user/module method
		self:OnClick(button)
		
		-- Do a post update for the tooltips
		if self:IsMouseOver() then 
			OnEnter(self)
		end

	elseif IsShiftKeyDown() then 
		if (button == "LeftButton") then
			self:RestoreDefaultPosition()
		elseif (button == "RightButton") then 
			self:RestoreDefaultScale()
		end
	else 
		if (button == "LeftButton") then 
			self:Raise()
		elseif (button == "RightButton") then 
			self:Lower()
		end 
	end 
end 

-- Called when the mousewheel is used above the mover
OnMouseWheel = function(self, delta)
	if (not self:IsScalingEnabled()) then 
		return 
	end 
	local data = MoverData[self]
	if (delta < 0) then
		if (data.scale - data.scaleStep >= data.minScale) then 
			data.scale = data.scale - data.scaleStep
		else 
			data.scale = data.minScale
		end 
	else
		if (data.scale + data.scaleStep <= data.maxScale) then 
			data.scale = data.scale + data.scaleStep 
		else 
			data.scale = data.maxScale
		end 
	end
	UpdateScale(self)
	UpdateTexts(self)
end

-- Called when dragging starts
OnDragStart = function(self) 
	if (not self:IsDraggingEnabled()) then 
		return 
	end 
	self:SetScript("OnUpdate", OnUpdate)
	self:StartMoving()
	self:SetAlpha(ALPHA_DRAGGING)

	OnLeave(self)
end

-- Called when dragging stops
OnDragStop = function(self) 
	self:SetScript("OnUpdate", nil)
	self:StopMovingOrSizing()
	self:SetAlpha(ALPHA_STOPPED)

	local data = MoverData[self]
	local point, offsetX, offsetY = GetParsedPosition(self)

	if (point ~= data.point or offsetX ~= data.offsetX or offsetY ~= data.offsetY) then 
		data.point = point
		data.offsetX = offsetX
		data.offsetY = offsetY

		UpdatePosition(self)
		UpdateTexts(self)
	end

	if self:IsMouseOver() then 
		OnEnter(self)
	end
end 

-- Mover Internal API
---------------------------------------------------
UpdateTexts = function(self, point, x, y, name)
	local data = MoverData[self]
	local infoString
	if (point and x and y) then 
		infoString = string_format("|cffffb200%s|r || |cffffb200%s, %s|r || |r|cffffb200%.2f|r", point, tostring(round(x, 1)), tostring(round(y, 1)), data.scale)
	else 
		infoString = string_format("|cffffb200%s|r || |cffffb200%s, %s|r || |r|cffffb200%.2f|r", data.point, tostring(round(data.offsetX, 1)), tostring(round(data.offsetY, 1)), data.scale)
	end 
	self.name:SetText(name or data.name)
	self.info:SetText(infoString)
end

UpdateScale = function(self)
	local data = MoverData[self]

	-- Rescale the target according to the stored setting
	local target = TargetByMover[self]
	target:SetScale(data.scale)

	-- Glue the target to the mover position, 
	-- as rescaling is bound to have changed it. 
	local point, offsetX, offsetY = GetParsedPosition(self)
	target:Place(point, self, point, 0, 0)

	-- Parse the current target position and reposition it
	-- Strictly speaking we could've math'ed this. But this is easier. 
	local targetPoint, targetOffsetX, targetOffsetY = GetParsedPosition(target)
	target:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)

	-- Resize and reposition the mover frame. 
	local targetWidth, targetHeight = target:GetSize()
	local relativeScale = target:GetEffectiveScale() / self:GetEffectiveScale()

	self:SetSize(targetWidth*relativeScale, targetHeight*relativeScale)
	self:Place(data.point, "UICenter", data.point, data.offsetX, data.offsetY)

	-- Fire a message for module callbacks
	LibMover:SendMessage("CG_MOVER_SCALE_UPDATED", self, TargetByMover[self], data.scale)

	if self:IsMouseOver() then 
		OnEnter(self)
	end
end 

UpdatePosition = function(self)
	if self:IsMouseOver() then 
		OnLeave(self)
	end

	local data = MoverData[self]
	local target = TargetByMover[self]

	self:Place(data.point, "UICenter", data.point, data.offsetX, data.offsetY)

	-- Glue the target to the mover position, 
	-- as rescaling is bound to have changed it. 
	local point, offsetX, offsetY = GetParsedPosition(self)
	target:Place(point, self, point, 0, 0)

	-- Parse the current target position and reposition it
	-- Strictly speaking we could've math'ed this. But this is easier. 
	local targetPoint, targetOffsetX, targetOffsetY = GetParsedPosition(target)
	target:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)

	-- Fire a message for module callbacks
	LibMover:SendMessage("CG_MOVER_UPDATED", self, TargetByMover[self], point, offsetX, offsetY)

	if self:IsMouseOver() then 
		OnEnter(self)
	end
end 

-- Mover Public API
---------------------------------------------------
-- Lock a frame's mover
Mover.Lock = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	self:Hide()
end

-- Unlock a frame's mover
Mover.Unlock = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	self:Show()
end

-- @input enableDragging <boolean> Set if dragging should be allowed.
Mover.SetDraggingEnabled = function(self, enableDragging)
	MoverData[self].enableDragging = enableDragging and true or false
end

-- @input enableScaling <boolean> Set if scaling should be allowed.
Mover.SetScalingEnabled = function(self, enableScaling)
	MoverData[self].enableScaling = enableScaling and true or false
end

Mover.SetScale = function(self, scale)
	MoverData[self].scale = tonumber(scale) or 1
	UpdateScale(self)
	UpdateTexts(self)
end

Mover.SetMinScale = function(self, minScale)
	MoverData[self].minScale = tonumber(minScale) or .5
end 

Mover.SetMaxScale = function(self, maxScale)
	MoverData[self].maxScale = tonumber(maxScale) or 1.5
end 

Mover.SetScaleStep = function(self, scaleStep)
	MoverData[self].scaleStep = tonumber(scaleStep) or .1
end 

Mover.SetMinMaxScale = function(self, minScale, maxScale, scaleStep)
	MoverData[self].minScale = tonumber(minScale) or .5
	MoverData[self].maxScale = tonumber(maxScale) or 1.5
	MoverData[self].scaleStep = tonumber(scaleStep) or .1
end

Mover.GetScale = function(self, scale)
	return MoverData[self].scale
end

Mover.SetDefaultScale = function(self, scale)
	MoverData[self].defaultScale = tonumber(scale) or 1
end 

Mover.GetDefaultScale = function(self)
	return MoverData[self].defaultScale
end 

-- Sets the default position of the mover.
-- This will parse the position provided. 
Mover.SetDefaultPosition = function(self, ...)
	local point, offsetX, offsetY = LibMover:GetParsedPosition(self, ...)
	local data = MoverData[self]
	data.defaultPoint = point
	data.defaultOffsetX = offsetX
	data.defaultOffsetY = offsetY
end

Mover.SetName = function(self, name)
	MoverData[self].name = name
	UpdateTexts(self)
end

Mover.GetName = function(self)
	return MoverData[self].name
end

-- Not currently using this, but leaving it here for later when we will. 
Mover.SetDescription = function(self, description)
	MoverData[self].description = description
	UpdateTexts(self)
end

-- @return <boolean> if dragging is currently enabled
Mover.IsDraggingEnabled = function(self)
	return MoverData[self].enableDragging
end

-- @return <boolean> if scaling is currently enabled
Mover.IsScalingEnabled = function(self)
	return MoverData[self].enableScaling
end

-- @return <boolean> if mover is in its registered default position
Mover.IsDefaultPosition = function(self)
	local data = MoverData[self]
	return (data.point == data.defaultPoint) 
	   and (round(data.offsetX,2) == round(data.defaultOffsetX,2)) 
	   and (round(data.offsetY,2) == round(data.defaultOffsetY,2))
end 

-- @return <boolean> if mover has its registered default scale
Mover.IsDefaultScale = function(self)
	local data = MoverData[self]
	return (data.scale == data.defaultScale)
end 

-- @return <boolean> if mover is in its registered default position and have its default scale
Mover.IsDefaultPositionAndScale = function(self)
	return self:IsDefaultPosition() and self:IsDefaultScale()
end 

-- Returns the mover to its default position
Mover.RestoreDefaultPosition = function(self)
	local data = MoverData[self]
	data.point = data.defaultPoint
	data.offsetX = data.defaultOffsetX
	data.offsetY = data.defaultOffsetY
	UpdatePosition(self)
	UpdateTexts(self)
end

-- Returns the mover to its default scale
Mover.RestoreDefaultScale = function(self)
	local data = MoverData[self]
	data.scale = data.defaultScale
	UpdateScale(self)
	UpdateTexts(self)
end

Mover.GetTooltip = function(self)
	return LibMover:GetMoverTooltip()
end

Mover.ForceUpdate = function(self)
	OnShow(self)
end

---------------------------------------------------
-- Library Public API
---------------------------------------------------
LibMover.CreateMover = function(self, target)
	check(target, 1, "table")

	local numMovers = 0
	for target in pairs(MoverByTarget) do 
		numMovers = numMovers + 1
	end 

	-- Our overlay drag handle
	local mover = setmetatable(Parent:CreateFrame("Button"), Mover_MT) 
	mover:Hide()
	mover:SetFrameStrata("DIALOG")
	mover:EnableMouse(true)
	mover:EnableMouseWheel(true)
	mover:SetMovable(true)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("AnyUp")  
	mover:SetScript("OnDragStart", OnDragStart)
	mover:SetScript("OnDragStop", OnDragStop)
	mover:SetScript("OnMouseWheel", OnMouseWheel)
	mover:SetScript("OnShow", OnShow)
	mover:SetScript("OnClick", OnClick)
	mover:SetScript("OnEnter", OnEnter)
	mover:SetScript("OnLeave", OnLeave)
	mover:SetFrameLevel(100 + numMovers) 
	mover:SetBackdrop(BACKDROP)
	mover:SetBackdropColor(Colors.backdrop[1], Colors.backdrop[2], Colors.backdrop[3])
	mover:SetBackdropBorderColor(Colors.border[1], Colors.border[2], Colors.border[3])
	mover:SetAlpha(ALPHA_STOPPED)

	-- Retrieve the parsed position of the target frame,
	-- and scale, size and position the mover frame accordingly. 
	local targetPoint, targetOffsetX, targetOffsetY = GetParsedPosition(target)
	local targetWidth, targetHeight = target:GetSize()
	local targetEffectiveScale = target:GetEffectiveScale()
	local moverEffectiveScale = mover:GetEffectiveScale()
	local scale = target:GetScale()
	mover:SetSize(targetWidth*targetEffectiveScale/moverEffectiveScale, targetHeight*targetEffectiveScale/moverEffectiveScale)
	mover:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)
	
	local name = mover:CreateFontString()
	name:SetDrawLayer("OVERLAY")
	name:SetFontObject(_G.Game13Font_o1)
	name:SetTextColor(Colors.title[1], Colors.title[2], Colors.title[3])
	name:SetPoint("BOTTOM", mover, "CENTER", 0, 2)
	name:SetIgnoreParentAlpha(true)
	mover.name = name

	local info = mover:CreateFontString()
	info:SetDrawLayer("OVERLAY")
	info:SetFontObject(_G.Game13Font_o1)
	info:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	info:SetPoint("TOP", mover, "CENTER", 0, -2)
	info:SetIgnoreParentAlpha(true)
	mover.info = info

	-- An overlay visible on the cursor while dragging the movable frame
	local handle = mover:CreateTexture()
	handle:SetDrawLayer("ARTWORK")
	handle:SetAllPoints()
	handle:SetColorTexture(Colors.backdrop[1], Colors.backdrop[2], Colors.backdrop[3], ALPHA_DRAGGING)
	mover.handle = handle

	-- Store the references
	MoverByTarget[target] = mover
	TargetByMover[mover] = target

	-- Put all mover related data in here
	MoverData[mover] = {
		id = numMovers, 
		name = "CG_Mover_"..numMovers, 
		enableDragging = true, 
		enableScaling = true,
		point = targetPoint, 
		offsetX = targetOffsetX, 
		offsetY = targetOffsetY,
		scale = scale,
		scaleStep = .1, 
		minScale = .5, 
		maxScale = 1.5,
		defaultScale = 1,
		defaultPoint = targetPoint, 
		defaultOffsetX = targetOffsetX,
		defaultOffsetY = targetOffsetY
	}

	LibMover:SendMessage("CG_MOVER_CREATED", mover, target)

	return mover
end

LibMover.LockMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	MoverByTarget[target]:Hide()
end 

LibMover.UnlockMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	local mover = MoverByTarget[target]
	local data = MoverData[mover]
	if (data.enableDragging or data.enableScaling) then 
		mover:Show()
	end
end 

LibMover.ToggleMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	local mover = MoverByTarget[target]
	local data = MoverData[mover]
	if (mover:IsShown()) then 
		mover:Hide()
	else 
		local data = MoverData[mover]
		if (data.enableDragging or data.enableScaling) then 
			mover:Show()
		end
	end 
end 

LibMover.LockAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	local changed
	for target,mover in pairs(MoverByTarget) do 
		if (mover:IsShown()) then 
			mover:Hide()
			changed = true
		end 
	end 
	if (changed) then 
		LibMover:SendMessage("CG_MOVERS_LOCKED")
	end 
end 

LibMover.UnlockAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	local changed
	for target,mover in pairs(MoverByTarget) do 
		if (not mover:IsShown()) then 
			local data = MoverData[mover]
			if (data.enableDragging or data.enableScaling) then 
				mover:Show()
				changed = true
			end
		end 
	end 
	if (changed) then 
		LibMover:SendMessage("CG_MOVERS_UNLOCKED")
	end
end 

LibMover.ToggleAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	-- Make this a hard show/hide method, 
	-- don't mix visible and hidden. 
	local visible
	for target,mover in pairs(MoverByTarget) do 
		if mover:IsShown() then 
			-- A mover is visible, 
			-- so this is a hide event. 
			visible = true
			break 
		end
	end 
	if (visible) then 
		self:LockAllMovers()
	else 
		self:UnlockAllMovers()
	end 
end 

LibMover.GetMoverTooltip = function(self)
	return LibMover:GetTooltip("CG_MoverTooltip") or LibMover:CreateTooltip("CG_MoverTooltip")
end

LibMover.GetPositionHelper = function(self)
	if (not LibMover.positionHelper) then 
		local positionHelper = Parent:CreateFrame("Frame")
		positionHelper:Hide()
		LibMover.positionHelper = positionHelper
	end
	return LibMover.positionHelper
end

LibMover.GetParsedPosition = function(self, frame, ...)
	local positionHelper = LibMover:GetPositionHelper()
	positionHelper:SetSize(frame:GetSize())
	positionHelper:Place(...)
	return GetParsedPosition(positionHelper)
end

---------------------------------------------------
-- Library Event Handling
---------------------------------------------------
LibMover.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		-- Forcefully hide all movers upon combat. 
		self:LockAllMovers()
	end 
end

-- Just in case this is a library upgrade, we upgrade events & scripts.
LibMover:UnregisterAllEvents()
LibMover:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")

local embedMethods = {
	CreateMover = true,
	LockMover = true, 
	LockAllMovers = true, 
	UnlockMover = true,
	UnlockAllMovers = true, 
	ToggleMover = true, 
	ToggleAllMovers = true, 
	GetMoverTooltip = true
}

LibMover.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMover.embeds) do
	LibMover:Embed(target)
end
