Sauercrowd.PvP = {}

function Sauercrowd:CheckTargetPvP()
	local unit = "target"
	if not UnitExists(unit) or not UnitIsPVP(unit) then
		return
	end

	local targetFaction = UnitFactionGroup(unit)
	local playerFaction = UnitFactionGroup("player")

	if targetFaction ~= playerFaction and not UnitIsPlayer(unit) then
		local name = UnitName(unit) or "Unbekannt"
		self:ShowPvPWarning(name .. " (" .. targetFaction .. "-NPC)")
		return
	end

	if UnitIsPlayer(unit) then
		local name = UnitName(unit)
		local now = GetTime()
		self.lastPvPAlert = self.lastPvPAlert or {}
		local lastAlert = self.lastPvPAlert[name] or 0

		if (now - lastAlert) > Sauercrowd.Constants.COOLDOWNS.PVP_ALERT then
			self.lastPvPAlert[name] = now
			self:ShowPvPWarning(name .. " ist PvP-aktiv!")
		end
	end
end

---@param text string
function Sauercrowd:ShowPvPWarning(text)
	Sauercrowd.Popup:Show({
		title = "PvP Warnung!",
		message = text,
		titleColor = {1, 0, 0},
		messageColor = {1, 0.82, 0},
		borderColor = {1, 0, 0, 1},
		displayTime = 2,
		playSound = SauercrowdOptionsDB["pvp_alert_sound"] and Sauercrowd.Constants.SOUNDS.PVP_ALERT or nil,
		rumble = true
	})
end

---@param frame Frame|table
function Sauercrowd:RumbleFrame(frame)
	if not frame then
		return
	end

	-- Store current position before rumble
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
	frame.originalPoint = { point, relativeTo, relativePoint, xOfs or 0, yOfs or 0 }

	local rumbleTime = 0.2
	local interval = 0.04
	local totalTicks = math.floor(rumbleTime / interval)
	local tick = 0

	C_Timer.NewTicker(interval, function(t)
		if not frame:IsShown() then
			t:Cancel()
			return
		end

		tick = tick + 1
		local offsetX = math.random(-2, 2)
		local offsetY = math.random(-2, 2)

		frame:ClearAllPoints()
		frame:SetPoint(
			frame.originalPoint[1],
			frame.originalPoint[2],
			frame.originalPoint[3],
			frame.originalPoint[4] + offsetX,
			frame.originalPoint[5] + offsetY
		)

		if tick >= totalTicks then
			-- Reset to original position
			frame:ClearAllPoints()
			frame:SetPoint(
				frame.originalPoint[1],
				frame.originalPoint[2],
				frame.originalPoint[3],
				frame.originalPoint[4],
				frame.originalPoint[5]
			)
			t:Cancel()
		end
	end, totalTicks)
end

function Sauercrowd.PvP:Initialize()
	Sauercrowd.EventManager:RegisterHandler("PLAYER_TARGET_CHANGED",
		function()
			if SauercrowdOptionsDB["pvp_alert"] == false then
				return
			end
			Sauercrowd:CheckTargetPvP()
		end, 0, "PvPTargetChecker")
end