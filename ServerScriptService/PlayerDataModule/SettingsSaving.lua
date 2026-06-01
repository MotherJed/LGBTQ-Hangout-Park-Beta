-- @ScriptType: Script
local ServerMods = game.ReplicatedStorage.ServerMods --Folder

local GlobalShadows = ServerMods.SettingsSaving.GlobalShadows
local MusicToggle = ServerMods.SettingsSaving.MusicToggle
local CoyoteEvent = ServerMods.SettingsSaving.Coyote
local ClockTimeSet = ServerMods.SettingsSaving.ClockTimeSet
local NatureSounds = ServerMods.SettingsSaving.NatureSounds

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("SettingsDataRefresh")

local SettingsTable = {
	["Global Shadows"] = false,
	["Music Muted"] = false,
	["Coyote"] = false,
	["ClockTime"] = 12.5,
	["Nature Muted"] = false,
}

-- nil is optional to change to string, bool, or other values.
-- All false meaning that "Muted = false"
-- Reason I added Coyote now:
-- Because in future, players are not gonna wanna listen to that every in-game night.

local function GetPlayerData(UserId)
	local Success, Result = pcall(function()
		return DataStore:GetAsync(UserId)
	end)

	if Success then
		return Result
	else
		warn("Failed to get data for UserId:", UserId, Result)
		return nil
	end
end

local function SavePlayerData(UserId, Data)
	local Success, Result = pcall(function()
		DataStore:SetAsync(UserId, Data)
	end)

	if not Success then
		warn("Failed to save data for UserId:", UserId, Result)
	end
end



function GlobalShadowsToggle(Plr, Tog)
	local GetData = GetPlayerData(Plr.UserId)

	if GetData == nil then
		SettingsTable["Global Shadows"] = Tog
		SavePlayerData(Plr.UserId, SettingsTable)
	else
		SavePlayerData(Plr.UserId, {
			["Global Shadows"] = Tog,
			["Music Muted"] = GetData["Music Muted"],
			["Coyote"] = GetData["Coyote"],
			["ClockTime"] = GetData["ClockTime"],
			["Nature Muted"] = GetData["Nature Muted"],
		})
	end
end

function MusicToggleE(Plr, Tog)
	local GetData = GetPlayerData(Plr.UserId)

	if GetData == nil then
		SettingsTable["Music Muted"] = Tog
		SavePlayerData(Plr.UserId, SettingsTable)
	else
		SavePlayerData(Plr.UserId, {
			["Global Shadows"] = GetData["Global Shadows"],
			["Music Muted"] = Tog,
			["Coyote"] = GetData["Coyote"],
			["ClockTime"] = GetData["ClockTime"],
			["Nature Muted"] = GetData["Nature Muted"],
		})
	end
end

function ClockSet(Plr, TimeV)
	local GetData = GetPlayerData(Plr.UserId)

	if GetData == nil then
		SettingsTable["ClockTime"] = TimeV
		SavePlayerData(Plr.UserId, SettingsTable)
	else
		SavePlayerData(Plr.UserId, {
			["Global Shadows"] = GetData["Global Shadows"],
			["Music Muted"] = GetData["Music Muted"],
			["Coyote"] = GetData["Coyote"],
			["ClockTime"] = TimeV,
			["Nature Muted"] = GetData["Nature Muted"],
		})
	end
end

function NatureSoundsSet(Plr, Muted)
	local GetData = GetPlayerData(Plr.UserId)

	if GetData == nil then
		SettingsTable["Nature Muted"] = Muted
		SavePlayerData(Plr.UserId, SettingsTable)
	else
		SavePlayerData(Plr.UserId, {
			["Global Shadows"] = GetData["Global Shadows"],
			["Music Muted"] = GetData["Music Muted"],
			["Coyote"] = GetData["Coyote"],
			["ClockTime"] = GetData["ClockTime"],
			["Nature Muted"] = Muted,
		})
	end
end

CoyoteEvent.OnServerEvent:Connect(function(Plr, Muted)
	local GetData = GetPlayerData(Plr.UserId)

	if GetData == nil then
		SettingsTable["Coyote"] = Muted
		SavePlayerData(Plr.UserId, SettingsTable)
	else
		SavePlayerData(Plr.UserId, {
			["Global Shadows"] = GetData["Global Shadows"],
			["Music Muted"] = GetData["Music Muted"],
			["Coyote"] = Muted,
			["ClockTime"] = GetData["ClockTime"],
			["Nature Muted"] = GetData["Nature Muted"],
		})
	end
end)

game.Players.PlayerAdded:Connect(function(Plr)
	local Data = GetPlayerData(Plr.UserId)

	if Data == nil then
		SavePlayerData(Plr.UserId, SettingsTable)

		task.wait(1)

		local ClockTimeS = SettingsTable["ClockTime"]

		ClockTimeSet:FireClient(Plr, ClockTimeS)
	else
		local TogGS = Data["Global Shadows"]
		local TogMM = Data["Music Muted"]
		local CoyoteS = Data["Coyote"]
		local ClockTimeS = Data["ClockTime"]
		local TogNM = Data["Nature Muted"]
		
		GlobalShadows:FireClient(Plr, TogGS)
		CoyoteEvent:FireClient(Plr, CoyoteS)
		ClockTimeSet:FireClient(Plr, ClockTimeS)
		MusicToggle:FireClient(Plr, TogMM)
		NatureSounds:FireClient(Plr, TogNM)
	end
end)

GlobalShadows.OnServerEvent:Connect(GlobalShadowsToggle)
MusicToggle.OnServerEvent:Connect(MusicToggleE)
ClockTimeSet.OnServerEvent:Connect(ClockSet)
NatureSounds.OnServerEvent:Connect(NatureSoundsSet)