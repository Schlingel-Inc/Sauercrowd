-- GuildCache.lua
-- Caching-System für Guild Roster Daten zur Performance-Optimierung

Sauercrowd.GuildCache = {
	---@type table<string, boolean>
	members = {},           -- Cached guild member list (name -> true)
	---@type SC_RosterMember[]
	fullRoster = {},        -- Full roster data with details
	lastUpdate = 0,         -- Timestamp of last cache update
	isUpdating = false      -- Flag to prevent concurrent updates
}

---Prüft, ob der Cache noch gültig ist
---@return boolean isValid
function Sauercrowd.GuildCache:IsValid()
	local now = GetTime()
	local age = now - self.lastUpdate
	return age < Sauercrowd.Constants.COOLDOWNS.GUILD_ROSTER_CACHE
end

---Fordert ein Roster-Update vom Server an
---Die Daten werden automatisch über den GUILD_ROSTER_UPDATE Handler verarbeitet
---@return boolean sentNewRequest
function Sauercrowd.GuildCache:RequestUpdate()
	if self.isUpdating then
		return false
	end

	self.isUpdating = true
	C_GuildInfo.GuildRoster()
	return true
end

-- Verarbeitet die Roster-Daten und füllt den Cache
function Sauercrowd.GuildCache:ProcessRosterData()
	-- Leere alte Daten
	wipe(self.members)
	wipe(self.fullRoster)

	local numTotalMembers = GetNumGuildMembers()

	for i = 1, numTotalMembers do
		local name, rankName, rankIndex, level, classDisplayName, zone,
			  publicNote, officerNote, isOnline, status, class = GetGuildRosterInfo(i)

		if name then
			-- Entferne Realm-Namen für einfacheren Vergleich
			local shortName = Sauercrowd:RemoveRealmFromName(name)

			-- Speichere in schneller Lookup-Tabelle
			self.members[shortName] = true

			-- Berechne Last Online Daten
			local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
			yearsOffline = yearsOffline or 0
			monthsOffline = monthsOffline or 0
			daysOffline = daysOffline or 0
			hoursOffline = hoursOffline or 0

			local totalDaysOffline = (yearsOffline * 365) + (monthsOffline * 30) + daysOffline + (hoursOffline / 24)

			-- Speichere vollständige Daten
			table.insert(self.fullRoster, {
				name = shortName,
				fullName = name,
				rank = rankName,
				rankIndex = rankIndex,
				level = level,
				class = class,
				classDisplayName = classDisplayName,
				zone = zone,
				publicNote = publicNote,
				officerNote = officerNote,
				isOnline = isOnline,
				status = status,
				yearsOffline = yearsOffline,
				monthsOffline = monthsOffline,
				daysOffline = daysOffline,
				hoursOffline = hoursOffline,
				totalDaysOffline = totalDaysOffline
			})
		end
	end

	self.lastUpdate = GetTime()
	self.isUpdating = false
end

---Gibt die vollständige Roster-Liste zurück (als Array mit allen Details)
---@return SC_RosterMember[] roster Array mit vollständigen Mitgliederdaten
function Sauercrowd.GuildCache:GetFullRoster()
	return self.fullRoster -- TODO: Do we really want to return the roster or just copy ?
end

---Prüft schnell, ob ein Spieler in der Gilde ist
---@param playerName string Der Name des Spielers (mit oder ohne Realm)
---@return boolean isGuildMember true wenn Spieler in der Gilde ist
function Sauercrowd.GuildCache:IsGuildMember(playerName)
	if not playerName then return false end

	-- Entferne Realm-Namen falls vorhanden
	local shortName = Sauercrowd:RemoveRealmFromName(playerName)

	-- Prüfe direkt im Cache
	return self.members[shortName] == true
end

---Gibt detaillierte Informationen über ein Gildenmitglied zurück
---@param playerName string Der Name des Spielers
---@return SC_RosterMember|nil info Mitgliederdaten oder nil wenn nicht gefunden
function Sauercrowd.GuildCache:GetMemberInfo(playerName)
	if not playerName then return nil end

	local shortName = Sauercrowd:RemoveRealmFromName(playerName)
	local roster = self:GetFullRoster()

	for _, member in ipairs(roster) do
		if member.name == shortName then
			return member
		end
	end

	return nil
end

---Gibt alle Mitglieder mit einem bestimmten Rang zurück
---@param rankName string Der Name des Rangs (z.B. "Devschlingel")
---@return SC_RosterMember[] filteredRoster Array mit Mitgliedern dieses Rangs
function Sauercrowd.GuildCache:GetMembersByRank(rankName)
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.rank == rankName then
			table.insert(result, member)
		end
	end

	return result
end

---Gibt alle online Mitglieder zurück
---@return SC_RosterMember[] filteredRoster Array mit online Mitgliedern
function Sauercrowd.GuildCache:GetOnlineMembers()
	local roster = self:GetFullRoster()
	local result = {}

	for _, member in ipairs(roster) do
		if member.isOnline then
			table.insert(result, member)
		end
	end

	return result
end

-- Erzwingt eine Aktualisierung des Caches
function Sauercrowd.GuildCache:ForceRefresh()
	return self:RequestUpdate()
end

---Gibt Cache-Statistiken zurück
---@return SC_GuildCacheStats stats Statistiken über den Cache
function Sauercrowd.GuildCache:GetStats()
	local now = GetTime()
	local age = now - self.lastUpdate
	local isValid = self:IsValid()

	return {
		memberCount = #self.fullRoster,
		lastUpdate = self.lastUpdate,
		age = age,
		isValid = isValid,
		expiresIn = math.max(0, Sauercrowd.Constants.COOLDOWNS.GUILD_ROSTER_CACHE - age)
	}
end

-- Initialisiert das GuildCache Modul
function Sauercrowd.GuildCache:Initialize()
	-- Update bei Guild Roster Updates (wird automatisch beim Login gefeuert)
	Sauercrowd.EventManager:RegisterHandler("GUILD_ROSTER_UPDATE",
		function()
			-- Verarbeite Roster-Daten immer wenn das Event feuert
			-- Dies hält den Cache immer aktuell
			Sauercrowd.GuildCache:ProcessRosterData()
		end, 0, "GuildCacheAutoUpdate")

	-- Initial update beim Login
	Sauercrowd.EventManager:RegisterHandler("PLAYER_ENTERING_WORLD",
		function()
			-- Warte kurz nach dem Login, dann fordere Roster an
			C_Timer.After(2, function()
				Sauercrowd.GuildCache:RequestUpdate()
			end)
		end, 90, "GuildCacheInit")
end
