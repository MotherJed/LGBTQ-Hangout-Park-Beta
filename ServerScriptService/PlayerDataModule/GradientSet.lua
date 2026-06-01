-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetGradient = ReplicatedStorage.ProfileUpdate.SetGradient

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local PlayerData = DataStoreService:GetDataStore("PlayerGradientData")

local Gradients = ReplicatedStorage:WaitForChild("Gradients")
local Tier1 = Gradients["Tier 1"]
local Tier2 = Gradients["Tier 2"]
local Tier3 = Gradients["Tier 3"]

--////////////////////////////////////////////////////
-- Utility: Find gradient by name
--////////////////////////////////////////////////////
local function GetGradient(name)
	return Tier1:FindFirstChild(name)
		or Tier2:FindFirstChild(name)
		or Tier3:FindFirstChild(name)
end

--////////////////////////////////////////////////////
-- Utility: Apply gradient to UsernameTx
--////////////////////////////////////////////////////
local function ApplyGradient(Character, Gradient)
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Overhead = HRP:WaitForChild("OverheadGUI")
	local UserFrame = Overhead:WaitForChild("UserFrame")
	local UsernameTx = UserFrame:WaitForChild("UsernameTx")

	-- Remove old gradients
	for _, child in ipairs(UsernameTx:GetChildren()) do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end

	Gradient:Clone().Parent = UsernameTx
end

--////////////////////////////////////////////////////
-- Remote: Player selects gradient
--////////////////////////////////////////////////////
SetGradient.OnServerEvent:Connect(function(Player, GradientName)

	local stats = Player:FindFirstChild("leaderstats")
	if not stats then return end

	local Minutes = stats:FindFirstChild("Minutes")
	if not Minutes then return end

	local Gradient = GetGradient(GradientName)
	if not Gradient then
		warn(Player.Name, "attempted invalid gradient:", GradientName)
		return
	end

	local Required = tonumber(Gradient:GetAttribute("RequiredMinutes"))
	if not Required then --Prevents error due to pontial nil value or is not a number
		warn("Missing RequiredMinutes for", GradientName)
		return
	end
	if Player:GetRankInGroupAsync(35122626) == 255 then
		Required = 0
	end
	task.wait(0.1)
	if Minutes.Value < Required then
		warn(Player.Name, "attempted locked gradient:", GradientName)
		return
	end

	local Character = Player.Character
	if Character then
		ApplyGradient(Character, Gradient)
	end

	-- Save immediately
	local ok, err = pcall(function()
		PlayerData:SetAsync(Player.UserId, GradientName)
	end)

	if not ok then
		warn("Save error:", err)
	end

	print(Player.Name, "equipped", GradientName)
end)

--////////////////////////////////////////////////////
-- Load + apply on spawn
--////////////////////////////////////////////////////
Players.PlayerAdded:Connect(function(Player)

	local SavedGradient
	local ok, result = pcall(function()
		return PlayerData:GetAsync(Player.UserId)
	end)

	if ok then
		SavedGradient = result
		print("Loaded Gradient:", SavedGradient)
	else
		warn("Failed to load gradient for", Player.Name)
	end

	Player.CharacterAdded:Connect(function(Character)
		if not SavedGradient then return end

		local Gradient = GetGradient(SavedGradient)
		if not Gradient then
			warn("Saved gradient missing:", SavedGradient)
			return
		end

		-- Small buffer for UI replication
		task.wait(0.25)

		ApplyGradient(Character, Gradient)
		print("Applied saved gradient:", SavedGradient)
	end)
end)
