Sauercrowd.Popup = {
	---@type BackdropTemplate|table
	activePopups = {}
}

---Creates and shows a generic popup with skull icon, title, and message
---@param options SC_PopupOptions
---@return table|BackdropTemplate|nil
function Sauercrowd.Popup:Show(options) --TODO: should use a frame pool for better performance
	if not options or not options.title or not options.message then
		return
	end

	-- Set defaults
	local title = options.title
	local message = options.message
	local titleColor = options.titleColor or {1, 0, 0}
	local messageColor = options.messageColor or {1, 0.82, 0}
	local borderColor = options.borderColor or {1, 0, 0, 1}
	local displayTime = options.displayTime or 3
	local playSound = options.playSound
	local rumble = options.rumble ~= false -- default true
	local frameHeight = options.FrameHeight or 140

	-- Create the frame
	local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(350, frameHeight)
	frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
	frame:SetBackdrop(Sauercrowd.Constants.BACKDROP)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	-- Store original position for rumble reset
	frame.originalPoint = { "TOP", UIParent, "TOP", 0, -150 }

	-- Skull icon
	local iconFrame = CreateFrame("Frame", nil, frame)
	iconFrame:SetSize(40, 40)
	iconFrame:SetPoint("TOP", frame, "TOP", 0, -20)

	local icon = iconFrame:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(iconFrame)
	icon:SetTexture("Interface\\AddOns\\Sauercrowd\\media\\DeathFrameIcon.png")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- Title
	local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	titleText:SetPoint("TOP", iconFrame, "BOTTOM", 0, -5)
	titleText:SetText(title)
	titleText:SetTextColor(titleColor[1], titleColor[2], titleColor[3])

	-- Message
	local messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	messageText:SetPoint("TOP", titleText, "BOTTOM", 0, -5)
	messageText:SetWidth(320)
	messageText:SetJustifyH("CENTER")
	messageText:SetText(message)
	messageText:SetTextColor(messageColor[1], messageColor[2], messageColor[3])

	-- Show the frame
	frame:SetAlpha(1)
	frame:Show()

	-- Play sound if specified
	if playSound then
		PlaySound(playSound)
	end

	-- Rumble effect if enabled
	if rumble then
		Sauercrowd:RumbleFrame(frame)
	end

	-- Store in active popups
	table.insert(self.activePopups, frame)

	-- Schedule fade out and cleanup
	C_Timer.NewTimer(displayTime, function()
		UIFrameFadeOut(frame, 1, 1, 0)
		C_Timer.After(1, function()
			frame:Hide()
			-- Remove from active popups
			for i, popup in ipairs(Sauercrowd.Popup.activePopups) do
				if popup == frame then
					table.remove(Sauercrowd.Popup.activePopups, i)
					break
				end
			end
		end)
	end)

	return frame
end

-- Hides all active popups
function Sauercrowd.Popup:HideAll()
	for _, popup in ipairs(self.activePopups) do
		if popup then
			popup:Hide()
		end
	end
	self.activePopups = {}
end
