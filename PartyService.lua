local RunService = game:GetService("RunService")
local DatastoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Settings = require(script.Settings)

local ActivePartyServers

if RunService:IsServer() then -- in case of a client accesses the module
	ActivePartyServers = DatastoreService:GetDataStore("ActivePartyServers")
end

local module = {}
local Parties = {}
local IsPartyServerValue = false
local IsPartyServerEmulator = false
local CurrentPartyInfo
local CurrentPartyData

local Errors = {
	[200] = "[200] Success - %s",
	[400] = "[400] Bad request - %s",
	[400.1] = "[400] Bad request (%i) - expected: %s, got: %s",
	[403] = "[403] Rejected - %s",
	[418] = "[418] I'm a teapot - %s",
	[426] = "[426] Deprecated function - %s", -- not implemented
	[426.1] = "[426] Deprecated function - it is recommended to change %s to %s", -- not implemented
	[427] = '[427] Outdated - a new update is available in the version "%s". (you are in version %s) to update your module go to: https://www.roblox.com/library/9771730581',
	[500] = "[500] Internal Script Error - %s",
}

--local BlacklistedAttributes = {"Id", "Name", "Players", "PlayerAdded", "PlayerRemoved", "Bindables", "OwnerId", "PlaceId", "MaxPlayers"} -- 🤐

local CreatedEvent = Instance.new("BindableEvent")
local DeletedEvent = Instance.new("BindableEvent")
local PlayerAddedEvent = Instance.new("BindableEvent")
local PlayerKickedEvent = Instance.new("BindableEvent")
local PlayerRemovedEvent = Instance.new("BindableEvent")
--local PartyServerStartedEvent = Instance.new("BindableEvent") -- deprecated
local OwnerChangedEvent = Instance.new("BindableEvent")
local ServerStartedEvent = Instance.new("BindableEvent")

module.Created = CreatedEvent.Event
module.Deleted = DeletedEvent.Event
module.PlayerAdded = PlayerAddedEvent.Event
module.PlayerKicked = PlayerKickedEvent.Event
module.PlayerRemoved = PlayerRemovedEvent.Event
--module.PartyServerStarted = PartyServerStartedEvent.Event -- deprecated
module.OwnerChanged = OwnerChangedEvent.Event
module.ServerStarted = ServerStartedEvent.Event

-- // Basic Typechecking (@Hanselkek, github)
export type PartyTable = {
	Id: number,
	Name: string,
	Players: {Player?},
	PlayerAdded: RBXScriptConnection,
	PlayerRemoved: RBXScriptConnection,
	PlayerKicked: RBXScriptConnection,
	PartyOwnerChanged: RBXScriptConnection,
	OwnerId: number,
	PlaceId: number,
	Data: {any?}?,
	MaxPlayers: number,
	SetAsync: () -> (),
	GetAsync: () -> (),
	InviteCode: string,
}

local function IsParty(party, parameter)
	if typeof(parameter) ~= "number" then parameter = 0 end
	if typeof(party) == "table" then
		if party.Id ~= nil and party.Name ~= nil and party.Players ~= nil and party.PlaceId ~= nil then
			return true
		else
			warn(string.format(Errors[400], "table is not a Party!"))
			return false, "no"
		end
	else
		warn(string.format(Errors[400.1], parameter, "table",  typeof(party)))
		return false, typeof(party)
	end
end

local function IsPlayer(player, parameter)
	if typeof(parameter) ~= "number" then parameter = 0 end
	if typeof(player) == "Instance" then
		if player:IsA("Player") then
			return true
		else
			warn(string.format(Errors[400], player.Name.." is not a Player!"))
			return false, "no"
		end
	else
		warn(string.format(Errors[400.1], parameter, "Instance",  typeof(player)))
		return false, typeof(player)
	end
end

local function IsClient(w)
	if RunService:IsClient() then
		if w ~= false then
			warn(string.format(Errors[403], "it is not possible to execute this function on the client!"))
		end
		return true
	else
		return false
	end
end

local function IsStudio(w)
	if RunService:IsStudio() then
		if w ~= false then
			warn(string.format(Errors[403], "it is not possible to execute this function, Server/Client is in Roblox Studio!"))
		end
		return true
	else
		return false
	end
end


function module:SetPartyServerEmulator(FakePartyData: any): boolean
	if IsStudio(false) == false then
		return nil
	end
	if IsClient() then
		return nil
	end
	
	IsPartyServerEmulator = true
	IsPartyServerValue = true
	local inviteCode = ""
	for i, v in pairs(string.split(Settings.InviteFormat, "")) do
		if v == "%" then
			continue
		end
		inviteCode = inviteCode..v
	end
	local FakePartyInfo = {
		["Id"] = 0,
		["Name"] = "Test Party",
		["Players"] = {},
		["OwnerId"] = 0,
		["PlaceId"] = game.PlaceId,
		["Data"] = FakePartyData,
		["MaxPlayers"] = 0,
		["InviteCode"] = inviteCode
	}
	Players.PlayerAdded:Wait()
	for i, v in pairs(Players:GetChildren()) do
		table.insert(FakePartyInfo.Players, v)
	end
	CurrentPartyData = FakePartyData
	CurrentPartyInfo = FakePartyInfo
	task.spawn(function()
		ServerStartedEvent:Fire(FakePartyData, FakePartyInfo)
		--PartyServerStartedEvent:Fire("ExampleCode") -- deprecated
	end)
	print(Errors[200]:format("Successfully started emulator for party system."))
	return true, "Successfully started emulator for party system."
end

function module:Create(Owner: Player, PlaceId: number, Name: string, MaxPlayers: number): PartyTable
	if IsClient() then
		return nil
	end
	if IsPlayer(Owner, 1) == false then
		return nil
	end
	if typeof(Name) ~= "string" then
		Name = Owner.Name.."`s Party"
	end
	if typeof(MaxPlayers) ~= "number" then
		--if typeof(MaxPlayers) == nil then
			MaxPlayers = 50 --0
		--end
	end
	if MaxPlayers <= 0 then
		MaxPlayers = 50
	end
	if typeof(PlaceId) ~= "number" then
		warn(string.format(Errors[400.1], 2, "number",  typeof(PlaceId)))
		return nil
	end
	if module:GetPartyPlayerIsIn(Owner) ~= nil then
		warn(Owner.Name.." is already in a party")
		return nil
	end
	local PartyPlayerAddedEvent = Instance.new("BindableEvent")
	local PartyPlayerRemovedEvent = Instance.new("BindableEvent")
	local PartyPlayerKickedEvent = Instance.new("BindableEvent")
	local PartyOwnerChangedEvent = Instance.new("BindableEvent")
	
	local PartyInfo = {
		["Id"] = #Parties+1,
		["Name"] = Name,
		["Players"] = {
			Owner,
		},
		["PlayerAdded"] = PartyPlayerAddedEvent.Event,
		["PlayerRemoved"] = PartyPlayerRemovedEvent.Event,
		["PlayerKicked"] = PartyPlayerKickedEvent.Event,
		["PartyOwnerChanged"] = PartyOwnerChangedEvent.Event,
		["Bindables"] = {
			["PlayerAdded"] = PartyPlayerAddedEvent,
			["PlayerRemoved"] = PartyPlayerRemovedEvent,
			["PlayerKicked"] = PartyPlayerKickedEvent,
			["PartyOwnerChanged"] = PartyOwnerChangedEvent,
		},
		["OwnerId"] = Owner.UserId,
		["PlaceId"] = PlaceId,
		["Data"] = nil,
		["MaxPlayers"] = MaxPlayers,
	}
	function PartyInfo:SetAsync(value)
		PartyInfo.Data = value
	end
	function PartyInfo:GetAsync()
		return PartyInfo.Data
	end
	if Settings.InviteCodeEnabled == true then
		PartyInfo["InviteCode"] = module.GetRandomInviteCode()
	end
	table.insert(Parties, PartyInfo)
	CreatedEvent:Fire(PartyInfo)
	PlayerAddedEvent:Fire(Owner, PartyInfo)
	return PartyInfo
end

function module:TeleportToLobby(LobbyId: number, Players: {Player})
	if IsStudio() then
		return nil
	end
	if IsClient() then
		return nil
	end
	if typeof(LobbyId) ~= "number" then
		warn(Errors[400.1]:format(1, "number", typeof(LobbyId)))
	end
	if typeof(Players) ~= "table" then
		warn(Errors[400.1]:format(2, "table", typeof(Players)))
		return nil
	end
	for i, v in pairs(Players) do
		if IsPlayer(v, 2) == false then
			return nil
		end
	end
	local TeleportOptions = Instance.new("TeleportOptions")
	local TeleportResult
	local yes, err = pcall(function()
		TeleportResult = TeleportService:TeleportAsync(LobbyId, Players, TeleportOptions)
	end)
	if yes then
		local yes2, err2 = pcall(function()
			ActivePartyServers:SetAsync(TeleportResult.PrivateServerId, TeleportResult.ReservedServerAccessCode)
		end)
		if yes2 then
		else
			warn(string.format(Errors[500], err2))
		end
	else
		warn(string.format(Errors[500], err))
	end
end

function module:StartParty(Party: PartyTable)
	if IsClient() then
		return nil
	end
	if IsParty(Party, 1) == false then
		return nil
	end
	if IsStudio(false) then
		warn("Cannot start a party in studio")
		return nil
	end
	local TeleportOptions = Instance.new("TeleportOptions")
	TeleportOptions.ShouldReserveServer = true
	local PartyData = Party:GetAsync()
	local TeleportResult
	local yes, err = pcall(function()
		TeleportResult = TeleportService:TeleportAsync(Party.PlaceId, Party.Players, TeleportOptions)
	end)
	if yes then
		local PartyInfoToSave = {
			["Id"] = Party.Id,
			["Name"] = Party.Name,
			["Players"] = {},
			["OwnerId"] = Party.OwnerId,
			["PlaceId"] = Party.PlaceId,
			["Data"] = Party.Data,
			["MaxPlayers"] = Party.MaxPlayers,
			["InviteCode"] = Party.InviteCode
		}
		for i, v in pairs(Party.Players) do
			table.insert(PartyInfoToSave.Players, v.UserId)
		end
		local PartyDataToSave = HttpService:JSONEncode(PartyData)
		local dataToSave = {
				["ReservedServerAccessCode"] = TeleportResult.ReservedServerAccessCode,
				["PartyData"] = PartyDataToSave,
				["PartyInfo"] = PartyInfoToSave,
		}
		local yes2, err2 = pcall(function()
			ActivePartyServers:SetAsync(TeleportResult.PrivateServerId, dataToSave)
		end)
		if yes2 then
			--print(ActivePartyServers:GetAsync(TeleportResult.PrivateServerId))
		else
			warn(string.format(Errors[500], err2))
		end
	else
		warn(string.format(Errors[500], err))
	end
end

function module:Delete(Party: PartyTable)
	if RunService:IsClient() then
		return nil
	end
	if not IsParty(Party, 1) then
		return nil
	end
	for i, v in pairs(module:GetPlayersInParty(Party)) do
		module:RemovePlayer(v, Party)
	end
	table.remove(Parties, Party.Id)
	DeletedEvent:Fire()
end

function module:PlayerIsInParty(Player: Player, Party: PartyTable): boolean
	if IsPlayer(Player, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	for i, v in pairs(Party.Players) do
		if Player == v then
			return true
		end
	end
	return false
end

--[[function module:GetPartys(): "PartysTable [deprecated]" -- deprecated
	if Settings.WarnDeprecated == true then warn(string.format(Errors[426.1], ":GetPartys()", ":GetParties()")) end
	return module:GetParties()
]]--end

function module:GetParties(): "PartiesTable"
	if IsClient() then
		return nil
	end
	return Parties
end

function module:GetPartyById(PartyId: number): PartyTable
	if IsClient() then
		return nil
	end
	if typeof(PartyId) ~= "number" then
		warn(Errors[400.1]:format(1, "number", typeof(PartyId)))
		return nil
	end
	for i, v in pairs(Parties) do
		if PartyId == v.Id then
			return v
		end
	end
	return nil
end

function module:GetPartyOwner(Party: PartyTable):Player
	if IsParty(Party, 1) == false then
		return nil 
	end
	for i, v in pairs(Party.Players) do
		if module:IsPartyOwner(v, Party) then
			return v
		end
	end
end

function module:IsPartyOwner(Player: Player, Party: PartyTable): boolean
	if IsPlayer(Player, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	if Player.UserId == Party.OwnerId then
		return true
	else
		return false
	end
end

function module:SetPartyOwner(NewOwner: Player, Party: PartyTable)
	if IsClient() then
		return nil
	end
	if IsPlayer(NewOwner, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	if module:IsPlayerInParty(NewOwner, Party) then else
		warn(Errors[400]:format(NewOwner.Name.." is not in the Party."))
		return nil, NewOwner.Name.." is not in the Party."
	end
	local OldOwner = module:GetPartyOwner(Party)
	Party.OwnerId = NewOwner.UserId
	Party.Bindables.PartyOwnerChanged:Fire(NewOwner, OldOwner)
	OwnerChangedEvent:Fire(Party, NewOwner, OldOwner)
end

function module:IsPlayerInParty(Player: Player, Party: PartyTable): boolean
	for i, v in pairs(module:GetPlayersInParty(Party)) do
		if v == Player then
			return true
		end
	end
	return false
end

function module:GetPlayersInParty(Party: PartyTable): {Player}
	if IsParty(Party, 1) == false then
		return nil
	end
	return Party.Players
end

function module:GetPartyByInviteCode(code)
	if Settings.InviteCodeEnabled ~= true then return end
	for i, v in pairs(Parties) do
		if v["InviteCode"] == code then
			return v
		end
	end
end

function module:AddPlayer(Player: Player, Party: PartyTable | string)
	local CurrentParty = nil
	if IsClient() then
		return nil
	end
	if IsPlayer(Player, 1) == false then
		return nil
	end
	if typeof(Party) == "table" then
		if IsParty(Party, 2) == false then
			return nil
		end
		-- is party
		CurrentParty = Party
	elseif typeof(Party) == "string" then
		if Settings.InviteCodeEnabled ~= true then warn("Invite Code is disabled") return end
		local partyByInvite = module:GetPartyByInviteCode(Party)
		if partyByInvite == nil then return false, "invalid invite code" end
		-- is invite
		CurrentParty = partyByInvite
	end
	if CurrentParty.MaxPlayers ~= 0 then
		if #CurrentParty.Players >= CurrentParty.MaxPlayers then
			return false, "player limit reached"
		end
	end
	if module:GetPartyPlayerIsIn(Player) ~= nil then
		return false, "player is already in a party"
	end
	if module:PlayerIsInParty(Player, CurrentParty) == false then
		table.insert(CurrentParty.Players, Player)
		CurrentParty.Bindables.PlayerAdded:Fire(Player)
		PlayerAddedEvent:Fire(CurrentParty, Player)
	else
		return false, "player is already in the party"
	end
	return true
end

function module:RemovePlayer(PlayerToRemove: Player, Party: PartyTable): boolean
	if IsClient() then
		return nil
	end
	if IsPlayer(PlayerToRemove, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	
	local FindPlayer = table.find(Party.Players, PlayerToRemove)
	if FindPlayer then
		local IsOwner = module:IsPartyOwner(PlayerToRemove, Party)
		local Players = module:GetPlayersInParty(Party)
		table.remove(Players, FindPlayer)
		if #Players > 0 then
			if IsOwner == true then
				local NewOwner = Players[math.random(1, #Players)]
				module:SetPartyOwner(NewOwner, Party)
			end
		else
			module:Delete(Party)
		end
		table.remove(Party.Players, FindPlayer)
		Party.Bindables.PlayerRemoved:Fire(PlayerToRemove)
		PlayerRemovedEvent:Fire(PlayerToRemove, Party)
		return true, "successfully removed "..PlayerToRemove.Name.." from the party!"
	else
		return false, "could not find "..PlayerToRemove.Name.." in the party"
	end
end

function module:KickPlayer(PlayerToKick: Player, Party: PartyTable): boolean
	if IsClient() then
		return nil
	end
	if IsPlayer(PlayerToKick, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	
	local PartyOwner = module:GetPartyOwner(Party)
	local FindPlayer = table.find(Party.Players, PlayerToKick)
	if FindPlayer then
		if module:IsPartyOwner(PlayerToKick, Party) then
			return false, PlayerToKick.Name.." is the Party Owner!"
		else
			module:RemovePlayer(FindPlayer, Party)
			Party.Bindables.PlayerKicked:Fire(PartyOwner, PlayerToKick)
			PlayerKickedEvent:Fire(PartyOwner, PlayerToKick, Party)
			return true, "successfully kicked "..PlayerToKick.Name.." from the party!"
		end
	else
		return false, "could not find "..PlayerToKick.Name.." in the party"
	end
end

function module:IsPartyServer()
	if IsClient() then
		return nil
	end
	return IsPartyServerValue
end

local function ChooseRandom(dictionary) -- by @1waffle1
	local list = {}
	for key, value in pairs(dictionary) do
		list[#list+1] = {key = key, value = value}
	end
	if #list == 0 then return end
	return list[math.random(#list)].value
end

function module.CanUseInviteCode(code)
	if Settings.InviteCodeEnabled == false then
		return nil
	end
	if typeof(code) ~= "string" then
		return nil
	end
	for i, v in pairs(Parties) do
		if v["InviteCode"] == code then
			return false
		end
	end
	return true
end

function module.GetRandomInviteCode()
	if Settings.InviteCodeEnabled == false then
		return nil
	end
	if typeof(Settings.InviteFormat) ~= "string" then
		return nil
	end
	local CodeFormat = string.split(Settings.InviteFormat, "")
	local Code = ""
	for i, v in pairs(CodeFormat) do
		if v == "%" then
			if CodeFormat[i+1] == "l" then
				local randomLetter = ChooseRandom(Settings.Letters)
				Code = Code..randomLetter
			elseif CodeFormat[i+1] == "L" then
				local randomLetter = ChooseRandom(Settings.Letters):upper()
				Code = Code..randomLetter
			elseif CodeFormat[i+1] == "a" then
				local random
				local randomLetterType = math.random(1, 2)
				if randomLetterType == 1 then
					random = ChooseRandom(Settings.Letters):upper()
				else
					random = ChooseRandom(Settings.Letters):lower()
				end
				
				Code = Code..random
			elseif CodeFormat[i+1] == "n" then
				local randomNumber = ChooseRandom(Settings.Numbers)
				Code = Code..randomNumber
			elseif CodeFormat[i+1] == "r" then
				local randomType = math.random(1, 2)
				local random
				if randomType == 1 then
					random = ChooseRandom(Settings.Numbers)
				else
					random = ChooseRandom(Settings.Letters)
				end
				Code = Code..random
			elseif CodeFormat[i+1] == "R" then
				local randomType = math.random(1, 2)
				local random
				if randomType == 1 then
					random = ChooseRandom(Settings.Numbers)
				else
					random = ChooseRandom(Settings.Letters):upper()
				end
				Code = Code..random
			elseif CodeFormat[i+1] == "x" then
				local randomType = math.random(1, 2)
				local random
				if randomType == 1 then
					random = ChooseRandom(Settings.Numbers)
				else
					local randomLetterType = math.random(1, 2)
					if randomLetterType == 1 then
						random = ChooseRandom(Settings.Letters):upper()
					else
						random = ChooseRandom(Settings.Letters):lower()
					end
				end
				Code = Code..random
			end
		elseif CodeFormat[i-1] == "%" then else
			Code = Code..v
		end
	end
	if module.CanUseInviteCode(Code) == false then
		return module.GetRandomInviteCode()
	else
		return Code
	end
end

function module:GetCurrentPartyInfo(): "Table"
	if IsPartyServerValue == true then
		return CurrentPartyInfo
	end
end

function module:GetCurrentPartyData(): "CurrentPartyData"
	if IsPartyServerValue == true then
		return CurrentPartyData
	end
end

function module:GetPartyPlayerIsIn(Player: Player): PartyTable -- made by @keirahela (github)
	if IsClient() then
		return nil
	end
	if IsPlayer(Player, 1) == false then
		return nil
	end

	local parties = module:GetParties()

	for i,v in pairs(parties) do
		for ind,val in pairs(v.Players) do
			if val == Player then
				return v
			end
		end
	end
	return nil
end

--[[ code ]]--

task.spawn(function() -- checks and warns if the module is outdated, it is necessary to have http requests enabled in your game
	if IsClient(false) then return end
	local ServerVersion
	local ClientVersion = Settings.Version
	local y, n = pcall(function()
		ServerVersion = HttpService:GetAsync("https://PartyService.cavaleirodev.repl.co")
	end)
	if Settings.WarnOutdated == true then
		if y then
			if ServerVersion ~= ClientVersion then
				warn(Errors[427]:format(ServerVersion, ClientVersion)) -- go to https://www.roblox.com/library/9771730581 to update your module
			else
				-- is updated
			end
		end
	end
end)

if RunService:IsServer() then
	if game.PrivateServerId ~= "" then
		--local accessCode -- moved
		local Party
		local y, n = pcall(function()
			Party = ActivePartyServers:GetAsync(game.PrivateServerId) --accessCode = ActivePartyServers:GetAsync(game.PrivateServerId)
		end)
		if y then
			IsPartyServerValue = true
			local PartyData = HttpService:JSONDecode(Party["PartyData"])
			local PartyInfo = Party["PartyInfo"]
			
			CurrentPartyInfo = PartyInfo
			CurrentPartyData = PartyData
			task.spawn(function() -- the event doesn't activate without this, don't ask me why
				ServerStartedEvent:Fire(PartyData, PartyInfo)
			end)
			--PartyServerStartedEvent:Fire(accessCode) -- deprecated
		else
			if IsPartyServerEmulator ~= true then
				IsPartyServerValue = false
			end
			warn(Errors[500]:format("error getting PartyData from DataStore. ("..n..")"))
			--warn(Errors[500]:format("error getting accessCode from DataStore. ("..err..")"))
		end
	end
end

if RunService:IsServer() then
	if module:IsPartyServer() then
		local function RemoveServer()
			local y, err = pcall(function()
				ActivePartyServers:RemoveAsync(game.PrivateServerId)
			end)
			if y then
				warn("server removed")
			else
				warn(Errors[500]:format("error removing server: "..game.PrivateServerId.." from list. ("..err..")"))
				task.wait(1)
				RemoveServer()
			end
		end
		local function CheckPlayers()
			if Players:GetChildren() == 0 then
				RemoveServer()
			end
		end
		Players.PlayerAdded:Connect(CheckPlayers)
		Players.PlayerRemoving:Connect(CheckPlayers)
		game:BindToClose(RemoveServer)
	end
end

return module
