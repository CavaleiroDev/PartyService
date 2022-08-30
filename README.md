# PartyService
Hi roblox developers!

 a while ago I had the idea to create this module for my game and I decided to make it public, with this module you can create party systems for your game

**[Get the model](https://www.roblox.com/library/9771730581/Party-Service-Beta)**

How to use:
first get the module in the link above

creating a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

local event = game.ReplicatedStorage.CreateEvent

event.OnServerEvent:Connect(function(Owner)
	local PartyInfo = PartyService:Create(Owner, 9743022048, "Test Party", 10) -- PartyOwner, PlaceId, PartyName (optional), MaxPlayers (optional)
end)

```
deleting a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

PartyService:Delete(PartyInfo)
```
adding a player to a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

local event = game.ReplicatedStorage.JoinEvent

event.OnServerEvent:Connect(function(Player, PartyInfo)
	PartyService:AddPlayer(Player, Party)
end)
```
removing a player from a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

local event = game.ReplicatedStorage.LeaveEvent

event.OnServerEvent:Connect(function(Player, PartyInfo)
	PartyService:RemovePlayer(Player, PartyInfo)
end)
```
kicking a player from a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

local event = game.ReplicatedStorage.KickEvent

event.OnServerEvent:Connect(function(Player, PartyInfo)
	PartyService:KickPlayer(Player, PartyInfo)
end)
```
starting a party
```
local PartyService = require(game.ReplicatedStorage.PartyService)

PartyService:StartParty(PartyInfo)
```
teleporting players back
```
local PartyService = require(game.ReplicatedStorage.PartyService)

PartyService:TeleportToLobby(7965317636, game.Players:GetChildren()) -- LobbyId, table with the players to teleport
```
starting party server emulator
```
local PartyService = require(game.ReplicatedStorage.PartyService)

PartyService:SetPartyServerEmulator()
```
Getting the Party that the player is in
```
local PartyService = require(game.ReplicatedStorage.PartyService)

PartyService:getPartyPlayerIsIn(Player)
```
for the complete api consult the script that comes with the module

FAQ:

Q: what are the differences between :RemovePlayer() and :KickPlayer()?
R:KickPlayer() won't work if you're trying to remove the party owner + :KickPlayer() fires the PlayerKicked event which returns the party owner, the kicked player and the party. this way you can create a custom message saying: "you were kicked out of a party! by OwnerName". if you want to remove the party owner or another player when he clicks a leave button i recommend using :RemovePlayer(), it will automatically choose a new owner

remembering: this project is in BETA that is bugs can occur, if any error happens to you please report the bug here.
