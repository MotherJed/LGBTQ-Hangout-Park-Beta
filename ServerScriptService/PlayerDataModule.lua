-- @ScriptType: ModuleScript
-- PlayerDataModule

local PlayerData = {}

PlayerData.DataStore = "PlayerData"
PlayerData.DataStoreService = game:GetService("DataStoreService")
PlayerData.DataStore = PlayerData.DataStoreService:GetDataStore(PlayerData.DataStore)

PlayerData.DefaultData = {
	Minutes = 0,

	Settings = {
		GlobalShadows = false,
		MusicMuted = false,
		Coyote = false,
		ClockTime = 12.5,
		NatureMuted = false,
	},

	Profile = {
		Bio = "",
		Pronouns = "",
	},

	Flags = {},

	Gradient = "Default",
	
	QuizRersultTable = {
		Result = "",
		CoolDown = 0
	},
}


PlayerData.Cache = {}

function PlayerData:Get(player)
	if PlayerData.Cache[player.UserId] then
		return PlayerData.Cache[player.UserId]
	end
	local success, data = pcall(function()
		return PlayerData.DataStore:GetAsync(player.UserId)
	end)
	if success then
		PlayerData.Cache[player.UserId] = data
		return data
	else
		warn("Failed to get data for player " .. player.Name .. ": " .. tostring(data))
		return nil
	end
end

return PlayerData