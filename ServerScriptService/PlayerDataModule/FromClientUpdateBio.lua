-- @ScriptType: Script
local BioEvent = game.ReplicatedStorage.ProfileUpdate.BioEvent
local PronounsEvent = game.ReplicatedStorage.ProfileUpdate.PronounsEvent

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("ProfileData")
local TextService = game:GetService("TextService")

local ProfileList = game.ReplicatedStorage.ProfileList



-- Default data structure
local DEFAULT_DATA = {
	Bio = "",
	Pronouns = "",
}

-- Function to load player data from DataStore
local function loadPlayerData(playerId)
	local success, data = pcall(function()
		return DataStore:GetAsync(playerId)
	end)

	if success and data then
		return data
	else
		return DEFAULT_DATA
	end
end

-- Function to filter text safely
local function filterText(text, playerId)
	local success, filtered = pcall(function()
		return TextService:FilterStringAsync(text, playerId):GetNonChatStringForBroadcastAsync()
	end)

	if success then
		return filtered
	else
		warn("Filtering failed for text:", text)
		return nil
	end
end

-- Function to save player data
local function savePlayerData(playerId, dataType, newText)
	-- Load existing data
	local playerData = loadPlayerData(playerId)

	-- Filter the new text
	local filteredText = filterText(newText, playerId)
	if not filteredText then
		return false, "Text filtering failed"
	end

	-- Update the specific field
	playerData[dataType] = filteredText

	-- Save to DataStore
	local success, errorMsg = pcall(function()
		DataStore:SetAsync(playerId, playerData)
	end)

	if success then
		return true, filteredText
	else
		warn("Failed to save data for player", playerId, ":", errorMsg)
		return false, "Save failed"
	end
end

-- Bio update handler
BioEvent.OnServerEvent:Connect(function(player, sentBio)
	local success, result = savePlayerData(player.UserId, "Bio", sentBio)
	if success then
		-- Update ProfileList if it exists
		local profileEntry = ProfileList:FindFirstChild(player.Name)
		if profileEntry and profileEntry:FindFirstChild("AboutMe") then
			profileEntry.AboutMe.Text = result
		end

		BioEvent:FireClient(player, result)
	else
		BioEvent:FireClient(player, nil)
	end
end)
-- Pronouns update handler
PronounsEvent.OnServerEvent:Connect(function(player, sentPronouns)
	local success, result = savePlayerData(player.UserId, "Pronouns", sentPronouns)
	if success then
		-- Update ProfileList if it exists
		local profileEntry = ProfileList:FindFirstChild(player.Name)
		if profileEntry and profileEntry:FindFirstChild("Pronouns") then
			profileEntry.Pronouns.Text = result
		end

		-- Update overhead GUI if character exists
		local character = player.Character
		if character then
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local overheadGUI = humanoidRootPart:FindFirstChild("OverheadGUI")
				if overheadGUI then
					local frame = overheadGUI:FindFirstChild("UserFrame")
					if frame then
						frame.PronounsTx.Text = result
					end
				end
			end
		end

		PronounsEvent:FireClient(player, result)
	else
		PronounsEvent:FireClient(player, nil)
	end
end)




-- Handle player joining
local function onPlayerAdded(player)
	-- Load player data
	local playerData = loadPlayerData(player.UserId)

	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		-- Load fresh data when character spawns
		local freshData = loadPlayerData(player.UserId)
		if freshData then
			-- Wait for character to fully load
			task.wait(0.1)
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				local overheadGUI = humanoidRootPart:FindFirstChild("OverheadGUI")
				if overheadGUI and overheadGUI:FindFirstChild("Frame") then
					local frame = overheadGUI.UserFrame
					if frame:FindFirstChild("PronounsTx") then
						frame.PronounsTx.Text = freshData.Pronouns
					end
					-- Also update bio if the overhead GUI has a bio field
					--if frame:FindFirstChild("BioTx") then
					--	frame.BioTx.Text = freshData.Bio
					--end
				end
			end
		end
	end)

	-- Update ProfileList and send data to client
	task.wait(0.5) -- Give time for UI to load
	if playerData then
		local profileEntry = ProfileList:FindFirstChild(player.Name)
		if profileEntry then
			if profileEntry:FindFirstChild("AboutMe") then
				profileEntry.AboutMe.Text = playerData.Bio
			end
			if profileEntry:FindFirstChild("Pronouns") then
				profileEntry.Pronouns.Text = playerData.Pronouns
			end
		end

		-- Send data to client
		BioEvent:FireClient(player, playerData.Bio)
		PronounsEvent:FireClient(player, playerData.Pronouns)
	end
end

-- Connect to player joining event
game.Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game
for _, player in game.Players:GetPlayers() do
	onPlayerAdded(player)
end