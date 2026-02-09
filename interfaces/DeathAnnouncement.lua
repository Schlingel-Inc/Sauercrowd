Sauercrowd.DeathAnnouncement = {}

-- Frame für die Nachricht
-- Image is 669x373 (1.79:1 ratio), scale down to fit nicely at top of screen
local frameWidth = 500
local frameHeight = 280  -- Maintains ~1.79:1 ratio (same as Level 60 notification)

local DeathMessageFrame = CreateFrame("Frame", "DeathMessageFrame", UIParent)
DeathMessageFrame:SetSize(frameWidth, frameHeight)
DeathMessageFrame:SetPoint("TOP", UIParent, "TOP", 0, -25)
DeathMessageFrame:SetFrameStrata("FULLSCREEN_DIALOG")
DeathMessageFrame:SetFrameLevel(1000)
DeathMessageFrame:Hide()
DeathMessageFrame:SetAlpha(0)

-- Background image (Death Alert Logo)
local background = DeathMessageFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(DeathMessageFrame)
background:SetTexture("Interface\\AddOns\\Sauercrowd\\media\\DeathAlert.png")
background:SetTexCoord(0, 1, 0, 1)  -- Ensure full image is displayed

-- Death message text (centered, positioned near bottom)
DeathMessageFrame.text = DeathMessageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
DeathMessageFrame.text:SetPoint("BOTTOM", DeathMessageFrame, "BOTTOM", 0, 100)
DeathMessageFrame.text:SetWidth(frameWidth - 200)
DeathMessageFrame.text:SetJustifyH("CENTER")
DeathMessageFrame.text:SetJustifyV("BOTTOM")
DeathMessageFrame.text:SetTextColor(1, 1, 1, 1)
DeathMessageFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
DeathMessageFrame.text:SetShadowColor(0, 0, 0, 1)
DeathMessageFrame.text:SetShadowOffset(2, -2)
DeathMessageFrame.text:SetText("")

-- Animation vorbereiten
local animGroup = DeathMessageFrame:CreateAnimationGroup()

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.4)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local hold = animGroup:CreateAnimation("Alpha")
hold:SetStartDelay(0.4)
hold:SetDuration(3)
hold:SetFromAlpha(1)
hold:SetToAlpha(1)

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(3.4)
fadeOut:SetDuration(0.6)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

-- Nach Animation Frame verstecken
animGroup:SetScript("OnFinished", function()
	DeathMessageFrame:Hide()
end)

-- Nachricht anzeigen (simple version without queue)
---@param message string
function Sauercrowd.DeathAnnouncement:ShowDeathMessage(message)
	-- Sanitize message to prevent UI injection
	DeathMessageFrame.text:SetText(Sauercrowd:SanitizeText(message))
	DeathMessageFrame:SetAlpha(0)
	DeathMessageFrame:Show()
	animGroup:Stop()
	animGroup:Play()

	if SauercrowdOptionsDB["deathmessages_sound"] == true then
		PlaySound(8192) -- Horde-Flagge zurückgebracht
	end
end
