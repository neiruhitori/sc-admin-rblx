--[[
	Client Main Script
	Initializes admin GUI and fly controller
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for AdminConfig to check if player is admin
local AdminConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AdminConfig"))
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Load Utility GUI for all players
require(script.UtilityGUI)

-- Only load Admin GUI if player is admin
if AdminConfig:IsAdmin(player) then
	require(script.AdminGUI)
	require(script.FlyController)
	print("Admin GUI and Fly Controller initialized for " .. player.Name)
else
	print("Client initialized for " .. player.Name)
end
