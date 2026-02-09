-- Helper function to extract Twitch handle from guild note
---@param note string|nil
---@return string|nil
local function ExtractTwitchHandle(note)
    if not note or note == "" then
        return nil
    end
    -- Guild note is just the handle itself
    return note
end

_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    ---@cast self GameTooltip
    local unit = select(2, self:GetUnit())
    if not unit then
        return
    end

    local guildName, rank = _G.GetGuildInfo(unit);
    if (guildName and _G.UnitExists(unit) and _G.UnitPlayerControlled(unit)) then
        _G.GameTooltip:AddLine(string.format('%s der Gilde %s', rank, guildName))

        -- Try to get Twitch handle from guild note
        if not IsInGuild() then return end

        local playerName = UnitName(unit)
        if not playerName then return end

        if not Sauercrowd.GuildCache:IsGuildMember(playerName) then
            return
        end
        -- Search through guild roster for this player
        local memberInfo = Sauercrowd.GuildCache:GetMemberInfo(playerName)
        if not memberInfo then return end

        local twitchHandle = ExtractTwitchHandle(memberInfo.publicNote)
        if twitchHandle and twitchHandle ~= "" then
            -- Sanitize handle to prevent UI injection
            local safeHandle = Sauercrowd:SanitizeText(twitchHandle)
            _G.GameTooltip:AddLine(" ")
            _G.GameTooltip:AddLine("Content Creator:", 0.39, 0.25, 0.65)
            _G.GameTooltip:AddLine(safeHandle, 1, 1, 1)
        end
    end
end)