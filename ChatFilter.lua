-- ChatFilter.lua
-- Adds SC icon prefix to guild member messages in chat

Sauercrowd.ChatFilter = {}
local ChatFilter = Sauercrowd.ChatFilter

-- Icon texture path
local SC_ICON = "|TInterface\\AddOns\\Sauercrowd\\media\\minimap_sc_font.tga:16:16:0:0|t"

-- Store original AddMessage functions for each chat frame
local originalAddMessage = {}

--- Hook function to add icon for guild members
---@param self Frame
---@param message string
---@param r number
---@param g number
---@param b number
---@param chatID number
---@param ... any
---@return nil
local function AddMessage_Hook(self, message, r, g, b, chatID, ...)
    -- Safety check: ensure GuildCache is initialized and populated
    if not Sauercrowd.GuildCache or not Sauercrowd.GuildCache.members then
        return originalAddMessage[self](self, message, r, g, b, chatID, ...)
    end

    -- Extract player name from the message
    -- Different chat types use different formats:
    -- Guild: [Gilde] |Hplayer:Name-Realm|h[Name]|h: message (German)
    -- Guild: [Guild] |Hplayer:Name-Realm|h[Name]|h: message (English)
    -- Whisper incoming: |Hplayer:Name-Realm|h[Name]|h flüstert: message (German)
    -- Whisper incoming: |Hplayer:Name-Realm|h[Name]|h whispers: message (English)
    -- Whisper outgoing: An |Hplayer:Name-Realm|h[Name]|h: message (German)
    -- Whisper outgoing: To |Hplayer:Name-Realm|h[Name]|h: message (English)
    -- Say/Yell: [Name]: message or |Hplayer:Name-Realm|h[Name]|h: message
    -- Party/Raid: |Hplayer:Name-Realm|h[Name]|h: message

    local playerName = nil

    -- Try to extract from hyperlink format (covers most cases)
    -- Pattern: |Hplayer:Name-Realm|h[Name]|h
    -- Try multiple patterns for better coverage
    playerName = message:match("|Hplayer:([^|]+)|h%[.-%]|h")
    if not playerName then
        playerName = message:match("|Hplayer:([^|]+)|h")
    end

    -- If not found, try bracket format (old style or system messages)
    if not playerName then
        -- Match [Name] but not channel names like [Gilde], [General], etc.
        -- We do this by ensuring it's followed by common chat indicators
        playerName = message:match("%[(.-)%] flüstert:")  -- German whisper
        if not playerName then
            playerName = message:match("%[(.-)%] whispers:")  -- English whisper
        end
        if not playerName then
            playerName = message:match("^%[(.-)%]:")  -- Say/Yell format
        end
    end

    if playerName then
        -- Remove realm name for lookup
        local cleanName = Sauercrowd:RemoveRealmFromName(playerName)

        -- Check if this player is a guild member
        if Sauercrowd.GuildCache:IsGuildMember(cleanName) then
            -- Check message length to avoid truncation (WoW limit is ~255 chars)
            -- Icon texture string is about 60 chars, be conservative
            if #message < 200 then
                -- Add SC icon at the very beginning of the message
                message = SC_ICON .. " " .. message
            else
                -- For long messages, try to add icon after channel prefix
                -- Find the first |h after the channel name
                local channelEnd = message:find("|h:", 1, true)
                if channelEnd and channelEnd < 50 then
                    message = message:sub(1, channelEnd + 2) .. " " .. SC_ICON .. message:sub(channelEnd + 3)
                end
                -- If can't find good spot, skip icon to avoid truncation
            end
        end
    end

    -- Call the original AddMessage with potentially modified message
    return originalAddMessage[self](self, message, r, g, b, chatID, ...)
end

-- Initialize the chat filter
function ChatFilter:Initialize()
    -- Hook AddMessage for all default chat frames (usually 1-7)
    -- NUM_CHAT_WINDOWS is a WoW global, fallback to 10 if not available
    local maxChatWindows = NUM_CHAT_WINDOWS or 10

    for i = 1, maxChatWindows do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and chatFrame.AddMessage then
            -- Store original function
            originalAddMessage[chatFrame] = chatFrame.AddMessage
            -- Replace with our hooked version
            chatFrame.AddMessage = AddMessage_Hook
        end
    end
end