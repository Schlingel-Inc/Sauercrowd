local addonName = ...
---@class SauercrowdAddon
Sauercrowd = {}

Sauercrowd.name = addonName
Sauercrowd.prefix = addonName
Sauercrowd.colorCode = "|cFF911d1d"
Sauercrowd.lastPvPAlert = {}
Sauercrowd.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "Unbekannt"

---@param message string
function Sauercrowd:Print(message)
	print(("%s[%s]|r %s"):format(self.colorCode, self.name, message))
end

---@param fullName string
---@return string shortName
function Sauercrowd:RemoveRealmFromName(fullName)
	return fullName:match("([^-]+)") or fullName
end

---@param tbl table
---@return number count
function Sauercrowd:CountTable(tbl)
	local count = table.count(tbl)
	return count
end

---Sanitizes text to prevent UI injection via escape codes
---Removes texture, color, and hyperlink escape sequences
---@param text string
---@return string
function Sauercrowd:SanitizeText(text)
	if not text or type(text) ~= "string" then
		return text
	end
	-- Remove texture escape sequences |Tpath:height:width:...|t
	text = text:gsub("|T[^|]*|t", "")
	-- Remove color escape sequences |cFFFFFFFF...|r
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	-- Remove hyperlink escape sequences |Htype:data|h...|h
	text = text:gsub("|H[^|]*|h", "")
	text = text:gsub("|h", "")
	return text
end

---Validates that an addon message sender is a guild member
---Uses GuildCache for fast lookup
---@param sender string
---@return boolean isValid
function Sauercrowd:IsValidGuildSender(sender)
	if not sender then return false end
	local shortName = self:RemoveRealmFromName(sender)
	return Sauercrowd.GuildCache:IsGuildMember(shortName)
end
