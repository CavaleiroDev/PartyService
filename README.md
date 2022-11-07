# PartyService
****Introduction****

***What Is?***
party service is an open-source module that facilitates the creation of party systems, it is very simple to use

***Why Use It?***

* easy to create party systems
* frequently updated
* FREE
* send data between places
* idk, it's cool! i guess
* open-source

***Get the Model***
[*Roblox*](https://www.roblox.com/library/9771730581) | [*GitHub*](https://github.com/CavaleiroDev/PartyService) | [*a random site i published it*](https://devforum.roblox.com/t/1816870) | [*Documentation*](https://github.com/CavaleiroDev/PartyService/wiki)

****How to Use****

first get the model or use the module id to get updates automatically

```
local PartyService = require(game.ReplicatedStorage.PartyService)
```
or
```
local PartyService = require(9771730581)
```

if you want to create a party you can use:
```
PartyService:Create(Player, PlaceId, PartyName, MaxPlayers)
-- Owner: the party owner/party leader, it doesn't matter
-- PlaceId: the place id of the place the players will be teleported to
-- PartyName (optional): a string that can be used to display to other players, if nil it will be set to "[OwnerName]`s Party"
-- MaxPlayers (optional): self explanatory, the module does not add more players if the limit is already reached. if it is 0 or nil the limit will be set to 50
```
if you want to delete a party use:
```
PartyService:Delete(Party)
-- Party: the table that is returned from PartyService:Create()
```
if you want to add a player to a party use:
```
PartyService:AddPlayer(Player, Party)
-- Player: the player to be added
-- Party: the table that is returned from PartyService:Create()
```
if you want to remove a player from a party use:
```
PartyService:RemovePlayer(Player, Party)
-- Player: the player to be removed
-- Party: the table that is returned from PartyService:Create()
```
if you want to kick a player from a party use:
```
PartyService:KickPlayer(Player, Party)
-- Player: the player to be kicked
-- Party: the table that is returned from PartyService:Create()
```
if you want to start a party use:
```
PartyService:StartParty(Party)
-- Party: the table that is returned from PartyService:Create()
```
if you want to teleport players back from a game use:
```
PartyService:TeleportToLobby(LobbyId, PlayersTable)
-- LobbyId: the place id of the lobby the players will be teleported to
-- PlayersTable: a table with the instance of the players to be teleported
```
if you want to test a game started from a party in studio use:
```
PartyService:SetPartyServerEmulator(FakeData)
-- FakeData: a test data that the place would receive from a party
```
if you want to save a data to be read later when the party starts use:
```
Party:SetAsync(Data)
-- Data: data to be sent
```


****Some example codes****
a simple script that creates parties when the player enters the game (on the lobby place): 
```
local PartyService = require(game.ReplicatedStorage.PartyService) -- requires de module

game.Players.PlayerAdded:Connect(function(plr) -- when a player enters the game
	local NewParty = PartyService:Create(plr, PlaceId, "cool party", 4) -- creates a new party
	plr.PlayerGui.Gui.StartButton.MouseButton1Click:Connect(function() -- when start button is pressed
		PartyService:StartParty(NewParty) -- starts the party
	end)
end)
```
a simple script that detects when the game started by a party and places the selected map in workspace: 
```
local PartyService = require(game.ReplicatedStorage.PartyService)
local LobbyPlaceId = 12345678 -- lobby place id

local FakeData = { -- for testing reasons
	["Map"] = "TestMap", -- a test map you have or a random map you have
	["Inventories"] = {
		["CavaleiroDev"] = "TestSword", -- your name and a test sword or a random sword you have
	}
}

PartyService:SetPartyServerEmulator(FakeData) -- now the game will recognize when you test in roblox studio

PartyService.ServerStarted:Connect(function(PartyData, PartyInfo) -- put here the code to start the game
	local Map = game.ReplicatedStorage:FindFirstChild(PartyData["Map"]) -- gets the map data in the table
	if Map then
		Map:Clone().Parent = workspace
	else
		warn("error: no map selected")
		PartyService:TeleportToLobby(LobbyPlaceId , game.Players:GetChildren())
	end
	for PlayerName, Weapon in pairs(PartyData["Inventories"]) do  -- gets the players inventory data in the table
		local WeaponModel = game.ReplicatedStorage.Weapons:FindFirstChild(Weapon)
		local player = game.Players:FindFirstChild(PlayerName)
		if WeaponModel then
			if player then
				WeaponModel:Clone().Parent = player.Backpack
			end
		end
	end
end)
```

****Update logs****
* [v1.1](https://devforum.roblox.com/t/1816870/4?u=cavaleirodev)
* [v2](https://devforum.roblox.com/t/1816870/5?u=cavaleirodev)
* [v2.1 (current version)](https://devforum.roblox.com/t/1816870/6?u=cavaleirodev)

****Info****
thanks for reading this far

I hope this module has helped you, if you want the model you can get it [here ](https://www.roblox.com/library/9771730581/Party-Service-v2-Beta). If you have any questions or find a bug please feel free to comment below.

oh and thank you so much for the 100 sales :partying_face::partying_face::partying_face:.
