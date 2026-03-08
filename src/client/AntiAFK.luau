--[[
	Anti-AFK Module
	Prevents auto-kick from idling
]]

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local AntiAFK = {}
AntiAFK.Enabled = false
AntiAFK.Connection = nil

function AntiAFK:Enable()
	if self.Enabled then return end
	
	self.Enabled = true
	
	-- Prevent idle kick by simulating user activity
	self.Connection = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	
	print("Anti-AFK enabled!")
end

function AntiAFK:Disable()
	if not self.Enabled then return end
	
	self.Enabled = false
	
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	
	print("Anti-AFK disabled!")
end

function AntiAFK:Toggle()
	if self.Enabled then
		self:Disable()
	else
		self:Enable()
	end
	
	return self.Enabled
end

return AntiAFK
