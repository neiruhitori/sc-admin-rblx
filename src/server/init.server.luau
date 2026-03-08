--[[
	Server Main Script
	Initializes admin command system
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminCommands = require(script.AdminCommands)

-- Initialize admin system
AdminCommands:Initialize()

print("Server initialized! Admin Commands ready.")
