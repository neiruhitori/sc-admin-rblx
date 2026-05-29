--[[
	===============================================
	   VIOLENCE DISTRICT MODULE (TEST VERSION)
	   By: NB - Nobody Comunity
	===============================================
]]

print("🔧 Loading Violence District module (TEST)...")

-- Get required services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("✅ Services loaded successfully!")

-- Create ScreenGui
local utilityScreenGui = Instance.new("ScreenGui")
utilityScreenGui.Name = "UtilityGUI_Test"
utilityScreenGui.ResetOnSpawn = false
utilityScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
utilityScreenGui.IgnoreGuiInset = true
utilityScreenGui.Parent = playerGui

print("✅ ScreenGui created!")

-- Create simple notification
local function showNotification(message)
	print("📢 NOTIFICATION: " .. message)
	
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0, 300, 0, 50)
	notif.Position = UDim2.new(1, -310, 0, 10)
	notif.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	notif.BorderSizePixel = 0
	notif.Text = message
	notif.TextColor3 = Color3.fromRGB(255, 255, 255)
	notif.TextSize = 14
	notif.Font = Enum.Font.GothamBold
	notif.TextWrapped = true
	notif.Parent = utilityScreenGui
	
	-- Auto destroy after 3 seconds
	task.delay(3, function()
		notif:Destroy()
	end)
end

print("✅ Notification function ready!")

-- Test notification
showNotification("Violence District Test Module Loaded!")

print("✅ VD Test Module loaded successfully!")
print("📋 No errors detected!")
