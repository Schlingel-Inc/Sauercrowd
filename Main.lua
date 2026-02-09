local function MuteGroupInviteSounds()
	-- Mute party invite sound (the "whoosh" when receiving/sending invites)
	MuteSoundFile(567275) -- IG_PLAYER_INVITE file ID
	-- Mute LFG role check sound
	MuteSoundFile(567478) -- ReadyCheck/RoleCheck "wom wom wommm" sound
end

local function HideMinimapMail()
    local mail = MiniMapMailFrame or MiniMapMailIcon
    if not mail then return end
		---@cast mail Frame

    -- Stop Blizzard from updating/showing it
    if mail.UnregisterAllEvents then
        mail:UnregisterAllEvents()
    end

    -- Hide it now
    mail:Hide()

    -- Make it non-interactive (optional)
    mail:SetAlpha(0)
    mail:SetScript("OnEnter", nil)
    mail:SetScript("OnLeave", nil)

    -- Prevent future :Show() calls (optional)
    if mail.Show then
        mail.Show = function() end
    end
end

function Sauercrowd:OnLoad()
	-- Register addon message prefix for cross-client communication
	C_ChatInfo.RegisterAddonMessagePrefix(Sauercrowd.prefix) -- TODO: This one is unused for now??

	Sauercrowd.EventManager:Initialize()
	Sauercrowd.GuildCache:Initialize()
	Sauercrowd.Death:Initialize()
	Sauercrowd.Rules:Initialize()
	Sauercrowd.LevelUps:Initialize()
	Sauercrowd.PvP:Initialize()
	Sauercrowd.ChatFilter:Initialize()

	Sauercrowd:InitializeOptionsDB()
	Sauercrowd:InitMinimapIcon()
	Sauercrowd:InitializeTwitchHandlePrompt()
	Sauercrowd:InitializeWelcomePopup()

	HideMinimapMail()
	MuteGroupInviteSounds()
end

local addonLoadedFrame = CreateFrame("Frame")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(_, _, addonName)
	---@cast addonName string
	if addonName == Sauercrowd.name then
		Sauercrowd:OnLoad()
	end
end)
