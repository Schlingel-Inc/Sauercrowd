-- Initialize the saved variable if needed
function Sauercrowd:InitializeTwitchHandles()
    if not SauercrowdTwitchHandles then
        SauercrowdTwitchHandles = {
            ---@type string|nil Account-wide Twitch handle
            handle = nil,
            ---@type number Account-wide death count
            deaths = 0
        }
    end
    -- Ensure deaths counter exists for existing installations
    if SauercrowdTwitchHandles.deaths == nil then
        SauercrowdTwitchHandles.deaths = 0
    end
end

---Pending handle storage (not saved, session-only)
---@type string|nil
local pendingTwitchHandle = nil

---Get the account-wide Twitch handle
---@return string|nil twitchHandle
function Sauercrowd:GetTwitchHandle()
    return SauercrowdTwitchHandles and SauercrowdTwitchHandles.handle
end

---Get the account-wide death count
---@return number deathCount
function Sauercrowd:GetDeathCount()
    Sauercrowd:InitializeTwitchHandles()
    return SauercrowdTwitchHandles.deaths or 0
end

-- Increment the account-wide death count
function Sauercrowd:IncrementDeathCount()
    Sauercrowd:InitializeTwitchHandles()
    SauercrowdTwitchHandles.deaths = (SauercrowdTwitchHandles.deaths or 0) + 1

    -- Update guild note with new death count
    local handle = Sauercrowd:GetTwitchHandle()
    if handle and handle ~= "" then
        Sauercrowd:UpdateGuildNoteWithHandleSilently(handle)
    end
end

-- Set the account-wide Twitch handle
---@param handle string
function Sauercrowd:SetTwitchHandle(handle)
    Sauercrowd:InitializeTwitchHandles()
    SauercrowdTwitchHandles.handle = handle
    -- Reset death counter when setting handle for first character
    SauercrowdTwitchHandles.deaths = 0

    -- Update guild note with the handle
    if handle and handle ~= "" then
        Sauercrowd:UpdateGuildNoteWithHandle(handle)
    end
end

-- Internal function to update guild note
---@param handle string
---@param showMessages boolean !unused!
local function UpdateGuildNote(handle, showMessages)
    if not IsInGuild() then
        -- Store as pending if not in guild
        pendingTwitchHandle = handle
        return
    end

    local playerName = UnitName("player")
    if not playerName then
        pendingTwitchHandle = handle
        return
    end

    C_Timer.After(2, function()
        local numMembers = GetNumGuildMembers()
        local deathCount = Sauercrowd:GetDeathCount()
        local noteText = string.format("%s (Tode: %d)", handle, deathCount)

        for i = 1, numMembers do
            local name = GetGuildRosterInfo(i)
            if name then
                local shortName = Sauercrowd:RemoveRealmFromName(name)
                if shortName == playerName then
                    GuildRosterSetPublicNote(i, noteText)
                    pendingTwitchHandle = nil -- Clear pending since we succeeded
                    return
                end
            end
        end

        -- If we get here, roster data isn't fully loaded yet - store as pending
        pendingTwitchHandle = handle
    end)
end

-- Update guild note to include Twitch handle (shows user feedback)
---@param handle string
function Sauercrowd:UpdateGuildNoteWithHandle(handle)
    UpdateGuildNote(handle, true)
end

-- Update guild note to include Twitch handle (silent, no user feedback)
---@param handle string
function Sauercrowd:UpdateGuildNoteWithHandleSilently(handle)
    UpdateGuildNote(handle, false)
end

local twitchPromptFrame

-- Create the prompt frame
---@return table|BackdropTemplate
local function CreateTwitchHandlePrompt()
    local frame = CreateFrame("Frame", "SauercrowdTwitchPrompt", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(550, 480)
    frame:SetPoint("CENTER")
    frame:SetBackdrop(Sauercrowd.Constants.BACKDROP)
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Header Image
    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\AddOns\\Sauercrowd\\media\\Header.png")
    header:SetSize(530, 301)
    header:SetPoint("TOP", 0, -5)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", header, "BOTTOM", 0, -10)
    title:SetText("Content Creator Identifikation")

    -- Description
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -15)
    desc:SetWidth(360)
    desc:SetJustifyH("CENTER")
    desc:SetText("Gib deinen Twitch/YouTube Handle ein:")

    -- Input box
    local editBox = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    editBox:SetSize(300, 30)
    editBox:SetPoint("TOP", desc, "BOTTOM", 0, -20)
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
    editBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    editBox:SetFontObject("GameFontNormal")
    editBox:SetTextInsets(10, 10, 0, 0)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(50)

    -- Shared save logic
    local function SaveAndClose()
        local handle = editBox:GetText()
        if handle and handle ~= "" then
            Sauercrowd:SetTwitchHandle(handle)
            frame:Hide()
        end
    end

    editBox:SetScript("OnEnterPressed", SaveAndClose)

    -- Save button
    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetSize(100, 25)
    saveButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    saveButton:SetText("Speichern")
    saveButton:SetScript("OnClick", SaveAndClose)

    return frame
end

-- Show the prompt if needed
function Sauercrowd:ShowTwitchHandlePromptIfNeeded()
    if not UnitName("player") then
        return
    end

    Sauercrowd:InitializeTwitchHandles()
    local handle = Sauercrowd:GetTwitchHandle()

    -- If handle is set and not empty, update guild note silently
    if handle and handle ~= "" then
        Sauercrowd:UpdateGuildNoteWithHandleSilently(handle)
    -- Show prompt if no handle is set (nil means never asked)
    elseif handle == nil then
        twitchPromptFrame = twitchPromptFrame or CreateTwitchHandlePrompt()
        twitchPromptFrame:Show()
    end
end

-- Initialize and register events
function Sauercrowd:InitializeTwitchHandlePrompt()
    Sauercrowd.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD", function()
        Sauercrowd:ShowTwitchHandlePromptIfNeeded()
        Sauercrowd.EventManager:UnregisterHandler("PLAYER_ENTERING_WORLD", "TwitchHandlePrompt")
    end, 0, "TwitchHandlePrompt")

    -- Handle pending Twitch handle updates when guild roster updates
    Sauercrowd.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE", function()
        if pendingTwitchHandle then
            Sauercrowd:UpdateGuildNoteWithHandleSilently(pendingTwitchHandle)
        end
    end, 0, "TwitchHandlePending")
end