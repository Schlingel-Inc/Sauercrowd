Sauercrowd.Rules = {}
Sauercrowd.MailRecipients = {}

function Sauercrowd.Rules.ProhibitAuctionhouseUsage()
	-- Attempt to use CloseAuctionHouse as a fallback
    if CloseAuctionHouse then
        CloseAuctionHouse() -- Built-in function to close the Auction House
    end

    if AuctionFrame and AuctionFrame:IsShown() then
        AuctionFrame:Hide() -- Directly hide the frame
    end

	Sauercrowd.Popup:Show({
		title = "Auktionshaus gesperrt!",
		message = "Die Nutzung des Auktionshauses ist während des Events nicht erlaubt.",
		displayTime = 3
	})
end

function Sauercrowd.Rules:AutoDeclineDuels()
	if(not SauercrowdOptionsDB.auto_decline_duels) then
		return
	end

	CancelDuel()
end

function Sauercrowd.Rules:ProhibitTradeWithNonGuildMembers()
	local tradePartner = UnitName("NPC")
	if tradePartner then
		local guild = GetGuildInfo("NPC")
		local playerGuild = GetGuildInfo("player")
		if not guild or guild ~= playerGuild then
			CancelTrade()
			Sauercrowd.Popup:Show({
				title = "Handel blockiert!",
				message = "Du kannst nur mit Gildenmitgliedern handeln.",
				displayTime = 3
			})
		end
	end
end

function Sauercrowd.Rules:ProhibitGroupingWithNonGuildMembers()
	-- Request fresh guild roster data
	C_GuildInfo.GuildRoster()

	-- Build list of all guild members
	local guildMembers = {}
	local numTotalGuildMembers = GetNumGuildMembers()
	for i = 1, numTotalGuildMembers do
		local name = GetGuildRosterInfo(i)
		if name then
			table.insert(guildMembers, Sauercrowd:RemoveRealmFromName(name))
		end
	end

	-- Check all group members
	local numGroupMembers = GetNumGroupMembers()
	for i = 1, numGroupMembers do
		local unit = "party" .. i
		if not UnitExists(unit) then
			unit = "raid" .. i
		end

		-- Skip disconnected players - they'll be checked again when they reconnect
		if UnitExists(unit) and not UnitIsConnected(unit) then
			-- Player is offline/disconnected, don't kick them
		else
			local memberName = UnitName(unit)
			-- Skip if name is not yet available (loading state)
			if memberName and memberName ~= UNKNOWNOBJECT and memberName ~= "" then
				local shortMemberName = Sauercrowd:RemoveRealmFromName(memberName)
				local isInGuild = tContains(guildMembers, shortMemberName)

				if not isInGuild then
					LeaveParty()
					Sauercrowd.Popup:Show({
						title = "Gruppe verlassen!",
						message = "Du kannst nur mit Gildenmitgliedern in einer Gruppe sein.",
						displayTime = 3
					})
					return
				end
			end
		end
	end
end

function Sauercrowd.Rules.ProhibitMailboxUsage()
	C_GuildInfo.GuildRoster()
	local bankRankIndex = 1 -- Fallback Guildmaster

	for i = 1, GuildControlGetNumRanks() do
		rankName = GuildControlGetRankName(i)
		if rankName == "Gildenbank" then
			bankRankIndex = i
		end
	end

	Sauercrowd.MailRecipients = {}
	for i = 1, GetNumGuildMembers() do
		local name, rankName, rankIndex = GetGuildRosterInfo(i)
		if name and rankIndex and bankRankIndex and rankIndex + 1 == bankRankIndex then
			table.insert(Sauercrowd.MailRecipients, Sauercrowd:RemoveRealmFromName(name))
		end
	end
	if SendMailFrame then
		SendMailFrame:Hide()
		if(not SendMailFrame:IsShown()) then
			C_Timer.After(0.01666666666, function()
				local _, rank = _G.GetGuildInfo("player");
				if rank ~= "Gildenbank" then
					SendMailFrame:Show()
					InboxFrame:Hide()
					MailFrameTab1:Hide()
					MailFrameTab2:Hide()
				end
			end)
		else
			closeMailFrame()
		end
	else
	closeMailFrame()
	end
end

function closeMailFrame()
	if MailFrame and MailFrame:IsShown() then
		MailFrame:Hide()
	end
	Sauercrowd.Popup:Show({
		title = "Briefkasten gesperrt!",
		message = "Die Nutzung des Briefkastens ist während des Events nicht erlaubt.",
		displayTime = 3
	})
end

function Sauercrowd.Rules:Initialize()
	Sauercrowd.EventManager:RegisterHandler("MAIL_SHOW",
		function()
			Sauercrowd.Rules.ProhibitMailboxUsage()
		end, 0, "MailboxBlock")

	-- Hook AuctionFrame directly to catch cases where event doesn't fire due to Blizzard errors
	Sauercrowd.EventManager:RegisterHandler("AUCTION_HOUSE_SHOW",
		function()
			Sauercrowd.Rules.ProhibitAuctionhouseUsage()
		end, 0, "AuctionHouseBlock")

	Sauercrowd.EventManager:RegisterHandler("TRADE_SHOW",
		function()
			Sauercrowd.Rules:ProhibitTradeWithNonGuildMembers()
		end, 0, "TradeBlock")

	-- Instantly decline party invites from non-guild members
	Sauercrowd.EventManager:RegisterHandler("PARTY_INVITE_REQUEST",
		function(event, sender)
			local isInGuild = Sauercrowd.GuildCache:IsGuildMember(sender)
			if not isInGuild then
				StaticPopup_Hide("PARTY_INVITE")
				DeclineGroup()
			end
		end, 0, "PartyInviteCheck")

	Sauercrowd.EventManager:RegisterHandler("GROUP_ROSTER_UPDATE",
		function()
			Sauercrowd.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "GroupRosterCheck")

	Sauercrowd.EventManager:RegisterHandler("RAID_ROSTER_UPDATE",
		function()
			Sauercrowd.Rules:ProhibitGroupingWithNonGuildMembers()
		end, 0, "RaidRosterCheck")

	Sauercrowd.EventManager:RegisterHandler("DUEL_REQUESTED",
		function()
			Sauercrowd.Rules:AutoDeclineDuels()
		end, 0, "DuelAutoDecline")

	Sauercrowd.EventManager:RegisterHandler("DUEL_TO_THE_DEATH_REQUESTED",
		function()
			Sauercrowd.Rules:AutoDeclineDuels()
		end, 0, "DuelToDeathAutoDecline")
end
