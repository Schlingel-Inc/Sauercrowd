SauercrowdOptionsDB = SauercrowdOptionsDB or {}

local UIOptions =
{
    {
        label = "PVP Warnung",
        description = "Aktiviert die PVP Warnung",
        variable = "pvp_alert",
        value = true,
    },
    {
        label = "PVP Warnung Ton",
        description = "Aktiviert den Ton für die PVP Warnung",
        variable = "pvp_alert_sound",
        value = true,
    },
    {
        label = "Todesmeldungen Ton",
        description = "Aktiviert den Ton für die Todesmeldungen",
        variable = "deathmessages_sound",
        value = true,
    },
    {
        label = "Automatisches Ablehnen von Duellen",
        description = "Lehnt automatisch alle Duell-Anfragen ab",
        variable = "auto_decline_duels",
        value = false,
    },
}

local category = Settings.RegisterVerticalLayoutCategory("Sauercrowd")

local function OnSettingChanged(setting, value)
    local key = setting:GetVariable()
    SauercrowdOptionsDB[key] = value
end

function Sauercrowd:InitializeOptionsUI()
    for _, setting in ipairs(UIOptions) do
        local settingObj = Settings.RegisterAddOnSetting(category, setting.variable, setting.variable,
            SauercrowdOptionsDB, type(setting.value), setting.label, setting.value, setting.value)

        settingObj:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, settingObj, setting.description)
    end
end

Settings.RegisterAddOnCategory(category)

function Sauercrowd:InitializeOptionsDB()
    for _, setting in ipairs(UIOptions) do
        if SauercrowdOptionsDB[setting.variable] ~= nil then
            setting.value = SauercrowdOptionsDB[setting.variable]
        end
    end
    Sauercrowd:InitializeOptionsUI()
end