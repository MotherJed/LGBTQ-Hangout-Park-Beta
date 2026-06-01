-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataStore = DataStoreService:GetDataStore("TimeRefresh")

local SessionData = {}
local MAX_RETRIES = 3

local function SaveData(plr)
	local leaderstats = plr:FindFirstChild("leaderstats")
	local Minutes = leaderstats and leaderstats:FindFirstChild("Minutes")

	-- Cache the value BEFORE any async call so it doesn't matter
	-- if the player object is destroyed during the yield
	local valueToSave = Minutes and Minutes.Value or nil
	if valueToSave == nil then return end

	local key = tostring(plr.UserId)

	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			return DataStore:UpdateAsync(key, function(old)
				return valueToSave
			end)
		end)

		if success then
			return
		end

		warn("Failed to save data for "..plr.Name.." (attempt "..attempt.."/"..MAX_RETRIES.."): "..err)

		if attempt < MAX_RETRIES then
			task.wait(1)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = plr

	local Minutes = Instance.new("IntValue")
	Minutes.Name = "Minutes"
	Minutes.Parent = leaderstats

	local success, data = pcall(function()
		return DataStore:GetAsync(plr.UserId)
	end)

	if success and data ~= nil then
		Minutes.Value = data
	end

	SessionData[plr] = true

	task.spawn(function()
		if plr.UserId == 61476960 then
		else
			while SessionData[plr] do

				task.wait(60)

				if plr.Parent then
					Minutes.Value += 1
				end
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	SessionData[plr] = nil
	SaveData(plr)
end)

-- Save all players' data when the server shuts down
--game:BindToClose(function()
--	if game:GetService("RunService"):IsStudio() then
--		return
--	end
--	for plr in SessionData do
--		SaveData(plr)
--	end
--end)