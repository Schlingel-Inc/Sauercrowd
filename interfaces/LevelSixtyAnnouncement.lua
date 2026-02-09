Sauercrowd.LevelSixtyAnnouncement = {}

-- Frame für die Nachricht
-- Image will be same aspect ratio as death announcement
local frameWidth = 500
local frameHeight = 280

local LevelSixtyFrame = CreateFrame("Frame", "LevelSixtyFrame", UIParent)
LevelSixtyFrame:SetSize(frameWidth, frameHeight)
LevelSixtyFrame:SetPoint("TOP", UIParent, "TOP", 0, -25)
LevelSixtyFrame:SetFrameStrata("FULLSCREEN_DIALOG")
LevelSixtyFrame:SetFrameLevel(1000)
LevelSixtyFrame:Hide()
LevelSixtyFrame:SetAlpha(0)

-- Background image (Level 60 Alert Logo)
-- TODO: Create Level60Alert.png - currently using DeathAlert.png as placeholder
local background = LevelSixtyFrame:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints(LevelSixtyFrame)
background:SetTexture("Interface\\AddOns\\Sauercrowd\\media\\LVL60Alert.png")
background:SetTexCoord(0, 1, 0, 1)

-- Level 60 message text (centered, positioned near bottom)
LevelSixtyFrame.text = LevelSixtyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
LevelSixtyFrame.text:SetPoint("BOTTOM", LevelSixtyFrame, "BOTTOM", 0, 105)
LevelSixtyFrame.text:SetWidth(frameWidth - 200)
LevelSixtyFrame.text:SetJustifyH("CENTER")
LevelSixtyFrame.text:SetJustifyV("BOTTOM")
LevelSixtyFrame.text:SetTextColor(1, 0.84, 0, 1)  -- Golden color for heroic achievement
LevelSixtyFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
LevelSixtyFrame.text:SetShadowColor(0, 0, 0, 1)
LevelSixtyFrame.text:SetShadowOffset(2, -2)
LevelSixtyFrame.text:SetText("")

-- Animation vorbereiten
local animGroup = LevelSixtyFrame:CreateAnimationGroup()

local fadeIn = animGroup:CreateAnimation("Alpha")
fadeIn:SetDuration(0.5)
fadeIn:SetFromAlpha(0)
fadeIn:SetToAlpha(1)
fadeIn:SetSmoothing("IN")

local hold = animGroup:CreateAnimation("Alpha")
hold:SetStartDelay(0.5)
hold:SetDuration(4)
hold:SetFromAlpha(1)
hold:SetToAlpha(1)

local fadeOut = animGroup:CreateAnimation("Alpha")
fadeOut:SetStartDelay(4.5)
fadeOut:SetDuration(0.8)
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetSmoothing("OUT")

-- Nach Animation Frame verstecken
animGroup:SetScript("OnFinished", function()
	LevelSixtyFrame:Hide()
end)

---Nachricht anzeigen
---@param message string
function Sauercrowd.LevelSixtyAnnouncement:ShowLevelSixtyMessage(message)
	-- Sanitize message to prevent UI injection
	LevelSixtyFrame.text:SetText(Sauercrowd:SanitizeText(message))
	LevelSixtyFrame:SetAlpha(0)
	LevelSixtyFrame:Show()
	animGroup:Stop()
	animGroup:Play()

	-- Play quest complete jingle
	PlaySound(619)
end
