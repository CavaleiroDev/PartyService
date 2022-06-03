local RunService = game:GetService("RunService")
local DatastoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")

--local Configuration = require(script.Configuration) -- ð¤

local ActivePartyServers


local module = {}


if RunService:IsServer() then
	ActivePartyServers = DatastoreService:GetDataStore("ActivePartyServers")
end

local Partys = {}
local IsPartyServerValue = false
local IsPartyServerEmulator = false

local Errors = {
	[200] = "[200] Success - %s",
	[400] = "[400] Bad request - %s",
	[400.1] = "[400] Bad request (%i) - expected: %s, got: %s",
	[403] = "[403] Rejected - %s",
	[500] = "[500] Internal Script Error - %s",
}

local BlacklistedAttributes = {"Id", "Name", "Players", "PlayerAdded", "PlayerRemoved", "Bindables", "OwnerId", "PlaceId", "MaxPlayers"} -- ð¤

local CreatedEvent = Instance.new("BindableEvent")
local DeletedEvent = Instance.new("BindableEvent")
local PlayerAddedEvent = Instance.new("BindableEvent")
local PlayerKickedEvent = Instance.new("BindableEvent")
local PlayerRemovedEvent = Instance.new("BindableEvent")
local PartyServerStartedEvent = Instance.new("BindableEvent")
local OwnerChangedEvent = Instance.new("BindableEvent")

module.Created = CreatedEvent.Event
module.Deleted = DeletedEvent.Event
module.PlayerAdded = PlayerAddedEvent.Event
module.PlayerKicked = PlayerKickedEvent.Event
module.PlayerRemoved = PlayerRemovedEvent.Event
module.PartyServerStarted = PartyServerStartedEvent.Event
module.OwnerChanged = OwnerChangedEvent.Event

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
			warn(string.format(Errors[403], "it is not possible to execute this function, Server/Client is or not in Roblox Studio!"))
		end
		return true
	else
		return false
	end
end


function module:SetPartyServerEmulator()
	if IsStudio(false) == false then
		return nil
	end
	if IsClient() then
		return nil
	end
	
	IsPartyServerEmulator = true
	IsPartyServerValue = true
	spawn(function()
		PartyServerStartedEvent:Fire("ExampleCode")
	end)
	print(Errors[200]:format("Successfully started emulator for party system."))
	return true, "Successfully started emulator for party system."
end

function module:Create(Owner, PlaceId, Name, MaxPlayers)
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
		if typeof(MaxPlayers) == nil then
			MaxPlayers = 0
		end
	end
	if typeof(PlaceId) ~= "number" then
		warn(string.format(Errors[400.1], 2, "number",  typeof(PlaceId)))
		return nil
	end
	local PartyPlayerAddedEvent = Instance.new("BindableEvent")
	local PartyPlayerRemovedEvent = Instance.new("BindableEvent")
	local PartyPlayerKickedEvent = Instance.new("BindableEvent")
	local PartyOwnerChangedEvent = Instance.new("BindableEvent")
	
	local PartyInfo = {
		["Id"] = #Partys+1,
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
		["MaxPlayers"] = MaxPlayers,
	}
	table.insert(Partys, PartyInfo)
	CreatedEvent:Fire(PartyInfo)
	PlayerAddedEvent:Fire(Owner, PartyInfo)
	return PartyInfo
end

function module:TeleportToLobby(LobbyId, Players)
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

function module:StartParty(Party)
	if IsStudio() then
		return nil
	end
	if IsClient() then
		return nil
	end
	if IsParty(Party, 1) == false then
		return nil
	end
	local TeleportOptions = Instance.new("TeleportOptions")
	TeleportOptions.ShouldReserveServer = true
	local TeleportResult
	local yes, err = pcall(function()
		TeleportResult = TeleportService:TeleportAsync(Party.PlaceId, Party.Players, TeleportOptions)
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

function module:Delete(Party)
	if RunService:IsClient() then
		return nil
	end
	if not IsParty(Party, 1) then
		return nil
	end
	for i, v in pairs(module:GetPlayersInParty(Party)) do
		module:RemovePlayer(v, Party)
	end
	table.remove(Partys, Party.Id)
	DeletedEvent:Fire()
end

function module:PlayerIsInParty(Player, Party)
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

function module:GetPartys()
	if IsClient() then
		return nil
	end
	return Partys
end

function module:GetPartyById(PartyId)
	if IsClient() then
		return nil
	end
	if typeof(PartyId) ~= "number" then
		warn(Errors[400.1]:format(1, "number", typeof(PartyId)))
		return nil
	end
	for i, v in pairs(Partys) do
		if PartyId == v.Id then
			return v
		end
	end
	return nil
end

function module:GetPartyOwner(Party)
	if IsParty(Party, 1) == false then
		return nil 
	end
	for i, v in pairs(Party.Players) do
		if module:IsPartyOwner(v, Party) then
			return v
		end
	end
end

function module:IsPartyOwner(Player, Party)
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

function module:SetPartyOwner(NewOwner, Party)
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

function module:IsPlayerInParty(Player, Party)
	for i, v in pairs(module:GetPlayersInParty(Party)) do
		if v == Player then
			return true
		end
	end
	return false
end

function module:GetPlayersInParty(Party)
	if IsParty(Party, 1) == false then
		return nil
	end
	return Party.Players
end

function module:AddPlayer(Player, Party)
	if IsClient() then
		return nil
	end
	if IsPlayer(Player, 1) == false then
		return nil
	end
	if IsParty(Party, 2) == false then
		return nil
	end
	if #Party.MaxPlayers ~= 0 then
		if #Party.Players >= Party.MaxPlayers then
			return nil
		end
	end
	if module:PlayerIsInParty(Player, Party) == false then
		table.insert(Party.Players, Player)
		Party.Bindables.PlayerAdded:Fire(Player)
		PlayerAddedEvent:Fire(Party, Player)
	else
		return nil
	end
end

function module:RemovePlayer(PlayerToRemove, Party)
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
		table.remove(Players, PlayerToRemove)
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

function module:KickPlayer(PlayerToKick, Party)
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

if RunService:IsServer() then
	if game.PrivateServerId ~= "" then
		local accessCode
		local y, err = pcall(function()
			accessCode = ActivePartyServers:GetAsync(game.PrivateServerId)
		end)
		if y then
			IsPartyServerValue = true
			PartyServerStartedEvent:Fire(accessCode)
		else
			if IsPartyServerEmulator ~= true then
				IsPartyServerValue = false
			end
			warn(Errors[500]:format("error getting accessCode from DataStore. ("..err..")"))
		end
	else
	end
end

function module:IsPartyServer()
	if IsClient() then
		return nil
	end
	return IsPartyServerValue
end

if RunService:IsServer() then
	if module.IsPartyServer() then
		local function RemoveServer()
			local y, err = pcall(function()
				ActivePartyServers:RemoveAsync(game.PrivateServerId)
			end)
			if y then
			else
				warn(Errors[500]:format("error removing server: "..game.PrivateServerId.." from list. ("..err..")"))
				wait(1)
				RemoveServer()
			end
		end
		local function CheckPlayers()
			if #game.Players:GetChildren() == 0 then
				RemoveServer()
			end
		end
		game.Players.PlayerAdded:Connect(CheckPlayers)
		game.Players.PlayerRemoving:Connect(CheckPlayers)
		game:BindToClose(RemoveServer)
	end
end

return
