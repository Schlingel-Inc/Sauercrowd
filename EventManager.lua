-- EventManager.lua
-- Zentraler Event-Manager für das Sauercrowd Addon
-- Verwaltet alle WoW-Events an einem Ort für bessere Performance und Wartbarkeit

--- TODO: Why not make use of Interface/AddOns/Blizzard_SharedXMLBase/GlobalCallbackRegistry.lua ?
Sauercrowd.EventManager = {
	---@type Frame
	frame = nil,
	---@type table<WowEvent, SC_EventHandler[]>
	handlers = {},  -- { eventName = { {callback, priority, enabled}, ... } }
}

--- Registriert einen Event-Handler
---@param event WowEvent Der Name des WoW-Events (z.B. "PLAYER_DEAD")
---@param callback fun(event: string, ...: any) Die Funktion, die aufgerufen werden soll
---@param priority number|nil Optional: Priorität (höher = früher ausgeführt), Standard: 0
---@param identifier string|nil Optional: Eindeutiger Identifier für den Handler
---@return string id Der Identifier des registrierten Handlers
function Sauercrowd.EventManager:RegisterHandler(event, callback, priority, identifier)
	priority = priority or 0
	identifier = identifier or tostring(callback)

	-- Initialisiere Handler-Liste für dieses Event
	if not self.handlers[event] then
		self.handlers[event] = {}
	end

	-- Prüfe ob dieser Handler bereits existiert
	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			-- Handler bereits registriert, überspringen
			return identifier
		end
	end

	-- Füge Handler hinzu
	table.insert(self.handlers[event], {
		callback = callback,
		priority = priority,
		enabled = true,
		identifier = identifier
	})

	-- Sortiere Handler nach Priorität (höchste zuerst)
	table.sort(self.handlers[event], function(a, b)
		return a.priority > b.priority
	end)

	-- Registriere Event beim Frame, falls noch nicht geschehen
	if not self.frame:IsEventRegistered(event) then
		self.frame:RegisterEvent(event)
	end

	return identifier
end

--- Entfernt einen Event-Handler
---@param event WowEvent Der Event-Name
---@param identifier string Der Identifier des zu entfernenden Handlers
function Sauercrowd.EventManager:UnregisterHandler(event, identifier)
	if not self.handlers[event] then return end

	for i = #self.handlers[event], 1, -1 do
		if self.handlers[event][i].identifier == identifier then
			table.remove(self.handlers[event], i)
		end
	end

	-- Wenn keine Handler mehr für dieses Event existieren, unregister vom Frame
	if #self.handlers[event] == 0 then
		self.frame:UnregisterEvent(event)
		self.handlers[event] = nil
	end
end

--- Aktiviert oder deaktiviert einen Handler
---@param event WowEvent Der Event-Name
---@param identifier string Der Identifier des Handlers
---@param enabled boolean true = aktiviert, false = deaktiviert
function Sauercrowd.EventManager:SetHandlerEnabled(event, identifier, enabled)
	if not self.handlers[event] then return end

	for _, handler in ipairs(self.handlers[event]) do
		if handler.identifier == identifier then
			handler.enabled = enabled
			return
		end
	end
end

--- Hauptevent-Handler - verteilt Events an registrierte Callbacks
---@param _ Frame
---@param event WowEvent
---@param ... any
local function OnEvent(_, event, ...)
	local handlers = Sauercrowd.EventManager.handlers[event]
	if not handlers then return end

	-- Rufe alle aktivierten Handler für dieses Event auf
	for _, handler in ipairs(handlers) do
		if handler.enabled then
			-- Führe Handler mit Fehlerbehandlung aus
			pcall(handler.callback, event, ...)
		end
	end
end

--- Initialisiert den EventManager
function Sauercrowd.EventManager:Initialize()
	if self.frame then
		-- Bereits initialisiert
		return
	end

	-- Erstelle den zentralen Event-Frame
	self.frame = CreateFrame("Frame", "SauercrowdEventManagerFrame")
	self.frame:SetScript("OnEvent", OnEvent)
end
