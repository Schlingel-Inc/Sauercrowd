local frame = CreateFrame("Frame")
frame:RegisterEvent("MAIL_INBOX_UPDATE")

local playerName = UnitName("player")

-- Checkt, ob der Absender "sicher" ist (man selbst, Gildenkollege oder Blizzard)
---@param index number
---@return boolean isSafe
local function IsSafeSender(index)
    -- Wir holen uns die wichtigen Daten direkt über den Index
    -- 3: sender, 9: wasRead 13: isGM
    local _, _, sender, _, _, _, _, _, wasRead, _, _, _, isGM = GetInboxHeaderInfo(index)

    -- 1. Blizzard/System Check (isGM ist true bei offizieller Post)
    if isGM then return true end

    -- 2. Falls kein Sender existiert, ist es meist eine System-Mail
    if not sender or sender == "" then return true end

    -- 3. Eigen-Check
    if sender == playerName then return true end

	-- 4. Eine bereits gelesene Mail
	if wasRead then return true end

    -- 5. Gilden-Check
    if Sauercrowd.GuildCache:IsGuildMember(sender) then return true end

    return false
end

-- Eigenes Warn-Popup, wenn man auf eine "fremde" Mail klickt
StaticPopupDialogs["CONFIRM_DELETE_NON_GUILD_MAIL"] = {
    text = "|cffff0000HINWEIS:|r Post von Nicht-Gildenmitglied!\n\nDiese Post muss gelöscht werden.",
    button1 = "Löschen",
    button2 = "Abbrechen",
    ---@type fun(self: Frame, data: {slot: number, itemCount: number}|nil)
    OnAccept = function(_, data)
        if data and data.slot then
            if not data.itemCount or data.itemCount == 0 then
                DeleteInboxItem(data.slot)
            else
				local itemsPerPage = INBOXITEMS_TO_DISPLAY or 7
                local buttonIndex = ((data.slot - 1) % itemsPerPage) + 1
                ---@type Button|table|nil
                local mailButton = _G["MailItem"..buttonIndex.."Button"]
                if mailButton then
                    -- Hide the guard temporarily to allow the original click handler to work
                    if mailButton.mailGuard then
                        mailButton.mailGuard:Hide()
                    end

                    -- Click the button to open the mail
                    mailButton:Click()

                    -- Kurz warten, bis das Fenster offen ist, dann Blizzards Lösch-Button triggern
                    C_Timer.After(0.1, function()
                        if OpenMailFrame:IsVisible() then
                            OpenMailDeleteButton:Click()

                            -- Falls Blizzard nochmal nachfragt (bei Items/Geld), bestätigen wir das auch automatisch
                            C_Timer.After(0.1, function()
                                for j = 1, 4 do
                                    local popupFrame = _G["StaticPopup"..j]
                                    if popupFrame and popupFrame:IsVisible() and (popupFrame.which == "DELETE_MAIL" or popupFrame.which == "CONFIRM_DELETE_ITEM") then
                                        _G["StaticPopup"..j.."Button1"]:Click()
                                    end
                                end
                            end)
                        end
                    end)
                end
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

---Hier speichern wir (taint-sicher) die Buttons, die wir deaktiviert haben, damit sie nicht versehentlich wieder aktiviert werden können
---@type table<Button, boolean>
local deadButtons = {}

---Macht "Alle öffnen"-Buttons unbrauchbar, um Unfälle zu vermeiden
---@param btn Button
local function KillButton(btn)
    if not btn or deadButtons[btn] then return end
    btn:Disable()
    btn:SetAlpha(0.3)

    -- Wir legen einen unsichtbaren Blocker drüber, damit auch andere Addons nicht drankommen
    local blocker = CreateFrame("Button", nil, btn)
    blocker:SetAllPoints()
    blocker:SetFrameLevel(btn:GetFrameLevel() + 2)
    blocker:EnableMouse(true)
    blocker:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffff0000Dieser Button ist gesperrt!", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    blocker:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Verhindert, dass der Button wieder aktiviert wird
    hooksecurefunc(btn, "Enable", function() btn:Disable() end)
    deadButtons[btn] = true
end

-- Geht die aktuelle Post-Seite durch
local function UniversalScan()
    if not MailFrame:IsVisible() then return end

    -- Wie viele Items sind insgesamt da?
    local numItems = GetInboxNumItems()

    -- Wie viele Items werden pro Seite angezeigt? (Standard ist 7)
    ---@type number
    local itemsPerPage = INBOXITEMS_TO_DISPLAY

    -- Aktuelle Seite berechnen (Blizzard speichert das in InboxFrame.pageNum)
    local currentPage = InboxFrame.pageNum or 1

    -- Wir loopen NUR über die 7 sichtbaren Buttons
    for i = 1, itemsPerPage do
        local mailIndex = ((currentPage - 1) * itemsPerPage) + i

        -- Nur fortfahren, wenn der berechnete Index nicht über der Gesamtzahl liegt
        if mailIndex <= numItems then
            ---@type Frame
            local item = _G["MailItem"..i]
            ---@type FontString
            local senderText = _G["MailItem"..i.."Sender"]
            ---@type CheckButton|table
            local button = _G["MailItem"..i.."Button"]

            if item and button then
                local itemCount = select(8, GetInboxHeaderInfo(mailIndex))

                if not IsSafeSender(mailIndex) then
                    -- Fremder Absender: Name wird rot
                    if senderText then senderText:SetTextColor(1, 0, 0) end

                    if not button.mailGuard then
                        button.mailGuard = CreateFrame("Button", nil, button)
                        button.mailGuard:SetAllPoints()
                        button.mailGuard:SetFrameLevel(button:GetFrameLevel() + 10)
                        button.mailGuard:EnableMouse(true)
                    end

                    button.mailGuard:SetScript("OnClick", function()
                        local dialog = StaticPopup_Show("CONFIRM_DELETE_NON_GUILD_MAIL")
                        if dialog then dialog.data = {slot = mailIndex, itemCount = itemCount} end
                    end)
                    button.mailGuard:Show()
                else
                    -- Sicherer Absender
                    if senderText then senderText:SetTextColor(1, 0.8, 0) end
                    if button.mailGuard then button.mailGuard:Hide() end
                end
            end
        else
            -- Falls weniger als 7 Briefe auf der aktuellen Seite sind (z.B. letzte Seite)
            -- müssen wir die Guards der leeren Zeilen verstecken
            ---@type CheckButton|table
            local button = _G["MailItem"..i.."Button"]
            if button and button.mailGuard then button.mailGuard:Hide() end
        end
    end

    -- Sucht nach "Open All" Buttons (nur im Mailbox-Bereich) und deaktiviert sie
    if MailFrame and MailFrame:IsVisible() then
        -- Check known mail addon buttons
        local mailButtons = {
            "OpenAllMail",              -- Common addon button
            "AutoLootMailButton"
        }

        for _, btnName in ipairs(mailButtons) do
            local btn = _G[btnName]
            if btn and btn:IsVisible() then
                KillButton(btn)
            end
        end

        -- Scan only frames that are children of MailFrame
        ---@type Frame[]
        local childFrames = {MailFrame:GetChildren()}
        for _, child in ipairs(childFrames) do
            if child and child:IsObjectType("Button") and child:IsVisible() then
                ---@cast child Button
                local txt = child.GetText and child:GetText()
                local name = child.GetName and child:GetName() or ""
                if txt and txt:find(OPEN_ALL_MAIL_BUTTON) then
                    if not name:find("MailItem") then
                        KillButton(child)
                    end
                end
            end
        end
    end
end

-- Delayed Scan
local function DelayedScan()
    C_Timer.After(0.05, UniversalScan)
end

-- Event-Handler
frame:SetScript("OnEvent", function(_, event)
    ---@cast event WowEvent
    if event == "MAIL_INBOX_UPDATE" then
        DelayedScan()
    end
end)

-- Hook auf das MailFrame
MailFrame:HookScript("OnShow", DelayedScan)

-- Diese Funktion wird von Blizzard jedes Mal aufgerufen, wenn die Inbox sich optisch aktualisiert
hooksecurefunc("InboxFrame_Update", function()
    DelayedScan()
end)

-- Falls irgendein Addon noch was macht
if MailFrameTab1 then
    MailFrameTab1:HookScript("OnClick", DelayedScan)
end

local errorListener = CreateFrame("Frame")
errorListener:RegisterEvent("UI_ERROR_MESSAGE")
errorListener:SetScript("OnEvent", function(...)
    local msg = select(4, ...)
    if msg == ERR_MAIL_TARGET_NOT_FOUND then
        if UIErrorsFrame then UIErrorsFrame:Clear() end

        Sauercrowd:Print("Diese Mail kann nicht gelöscht werden, da sie bereits geöffnet war und der Charakter mittlerweile gelöscht wurde! Ein Bezug zur Gilde ist nicht mehr nachvollziehbar")
    end
end)