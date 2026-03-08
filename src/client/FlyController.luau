--[[
	Fly Controller
	Handles client-side flying mechanics
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AdminRemote = require(ReplicatedStorage.Shared.AdminRemote)

local FlyController = {}
FlyController.Flying = false
FlyController.DefaultSpeed = 50
FlyController.Speed = 50
FlyController.MaxSpeed = 200

-- Movement keys
local movementKeys = {
	Forward = Enum.KeyCode.W,
	Backward = Enum.KeyCode.S,
	Left = Enum.KeyCode.A,
	Right = Enum.KeyCode.D,
	Up = Enum.KeyCode.Space,
	Down = Enum.KeyCode.LeftShift,
}

-- Track which keys are pressed
local keysPressed = {
	Forward = false,
	Backward = false,
	Left = false,
	Right = false,
	Up = false,
	Down = false,
}

-- Body movers
local bodyVelocity = nil
local bodyGyro = nil
local connection = nil

-- Setup body movers
local function setupBodyMovers(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	
	-- Create BodyVelocity
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hrp
	
	-- Create BodyGyro
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
	bodyGyro.P = 9000
	bodyGyro.Parent = hrp
end

-- Remove body movers
local function removeBodyMovers()
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
	
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Calculate velocity based on camera and key presses
local function calculateVelocity()
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame
	
	local moveDirection = Vector3.new(0, 0, 0)
	
	-- Forward/Backward
	if keysPressed.Forward then
		moveDirection = moveDirection + cameraCFrame.LookVector
	end
	if keysPressed.Backward then
		moveDirection = moveDirection - cameraCFrame.LookVector
	end
	
	-- Left/Right
	if keysPressed.Left then
		moveDirection = moveDirection - cameraCFrame.RightVector
	end
	if keysPressed.Right then
		moveDirection = moveDirection + cameraCFrame.RightVector
	end
	
	-- Up/Down
	if keysPressed.Up then
		moveDirection = moveDirection + Vector3.new(0, 1, 0)
	end
	if keysPressed.Down then
		moveDirection = moveDirection - Vector3.new(0, 1, 0)
	end
	
	-- Normalize and apply speed
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit * FlyController.Speed
	end
	
	return moveDirection
end

-- Start flying
function FlyController:StartFlying()
	if self.Flying then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	self.Flying = true
	
	-- Setup body movers
	setupBodyMovers(character)
	
	-- Enable body movers
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	
	-- Keep character in standing/idle pose while flying
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	-- Update loop
	connection = RunService.Heartbeat:Connect(function()
		if not self.Flying then return end
		
		local camera = workspace.CurrentCamera
		local velocity = calculateVelocity()
		
		if bodyVelocity then
			bodyVelocity.Velocity = velocity
		end
		
		if bodyGyro then
			bodyGyro.CFrame = camera.CFrame
		end
	end)
	
	print("Flying enabled! Controls: WASD + Space (up) + Shift (down)")
end

-- Stop flying
function FlyController:StopFlying()
	if not self.Flying then return end
	
	self.Flying = false
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Re-enable disabled states
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	
	removeBodyMovers()
	
	print("Flying disabled")
end

-- Toggle flying
function FlyController:Toggle()
	if self.Flying then
		self:StopFlying()
	else
		self:StartFlying()
	end
end

-- Handle key input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	for direction, keyCode in pairs(movementKeys) do
		if input.KeyCode == keyCode then
			keysPressed[direction] = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	for direction, keyCode in pairs(movementKeys) do
		if input.KeyCode == keyCode then
			keysPressed[direction] = false
		end
	end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function()
	if FlyController.Flying then
		FlyController:StopFlying()
	end
end)

-- Listen for server fly toggle
AdminRemote.ToggleFly.OnClientEvent:Connect(function(enabled)
	if enabled then
		FlyController:StartFlying()
	else
		FlyController:StopFlying()
	end
end)

return FlyController
