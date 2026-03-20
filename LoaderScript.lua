--[[
	===============================================
	   ADMIN SCRIPT LOADER - CLIENT SIDE ONLY
	   By: TwoHand Comunity
	   Discord: https://discord.gg/xHrJaSgy
	   
	   🔓 PUBLIC ACCESS - No admin check required!
	   Anyone who executes this script gets full access.
	   
	    HOW TO USE:
	   1. Upload this file to GitHub (get raw link)
	   2. In executor, run:
	      loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL"))()
	===============================================
]]

print("🚀 Loading Admin Script...")

-- ============================================
-- CONFIG MODULE
-- ============================================
local AdminConfig = {}

-- Command prefix
AdminConfig.Prefix = ";"

-- UI Theme colors
AdminConfig.Theme = {
	Primary = Color3.fromRGB(45, 45, 45),
	Secondary = Color3.fromRGB(35, 35, 35),
	Accent = Color3.fromRGB(0, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(0, 255, 0),
	Error = Color3.fromRGB(255, 0, 0),
}

-- Parse command function
function AdminConfig:ParseCommand(input)
	if input:sub(1, #self.Prefix) ~= self.Prefix then
		return "", {}
	end
	
	local withoutPrefix = input:sub(#self.Prefix + 1)
	local parts = withoutPrefix:split(" ")
	local command = parts[1]:lower()
	
	table.remove(parts, 1)


	return command, parts
end

-- ============================================
-- ANTI-AFK MODULE

-- ============================================
local VirtualUser = game:GetService("VirtualUser")

local AntiAFK = {}
AntiAFK.Enabled = false
AntiAFK.Connection = nil

function AntiAFK:Enable()
	if self.Enabled then return end

	self.Enabled = true

	
	local player = game:GetService("Players").LocalPlayer
	self.Connection = player.Idled:Connect(function()

		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())

	end)
	
	print("✅ Anti-AFK enabled!")
	return true
end


function AntiAFK:Disable()
	if not self.Enabled then return end
	self.Enabled = false
	
	if self.Connection then
		self.Connection:Disconnect()

		self.Connection = nil
	end
	
	print("❌ Anti-AFK disabled!")
	return false

end


function AntiAFK:Toggle()
	if self.Enabled then
		return self:Disable()
	else
		return self:Enable()
	end
end

-- ============================================
-- FLY CONTROLLER MODULE

-- ============================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local CommandExecutor

local FlyController = {}
FlyController.Flying = false
FlyController.Speed = 50
FlyController.MaxSpeed = 200
FlyController.DefaultSpeed = 50

local movementKeys = {

	Forward = Enum.KeyCode.W,
	Backward = Enum.KeyCode.S,
	Left = Enum.KeyCode.A,
	Right = Enum.KeyCode.D,
	Up = Enum.KeyCode.Space,
	Down = Enum.KeyCode.LeftShift,
}

local keysPressed = {
	Forward = false,

	Backward = false,
	Left = false,
	Right = false,
	Up = false,
	Down = false,
}

local bodyVelocity = nil
local bodyGyro = nil
local connection = nil

local function setupBodyMovers(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hrp
	
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
	bodyGyro.P = 9000
	bodyGyro.Parent = hrp
end

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

local function calculateVelocity()
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame
	
	local moveDirection = Vector3.new(0, 0, 0)
	
	if keysPressed.Forward then
		moveDirection = moveDirection + cameraCFrame.LookVector
	end
	if keysPressed.Backward then
		moveDirection = moveDirection - cameraCFrame.LookVector
	end
	
	if keysPressed.Left then
		moveDirection = moveDirection - cameraCFrame.RightVector
	end
	if keysPressed.Right then
		moveDirection = moveDirection + cameraCFrame.RightVector
	end
	
	if keysPressed.Up then
		moveDirection = moveDirection + Vector3.new(0, 1, 0)
	end
	if keysPressed.Down then
		moveDirection = moveDirection - Vector3.new(0, 1, 0)
	end
	
	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit * FlyController.Speed
	end
	
	return moveDirection
end

function FlyController:StartFlying()
	if self.Flying then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	self.Flying = true
	
	setupBodyMovers(character)
	
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	humanoid.PlatformStand = true
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
	connection = RunService.Heartbeat:Connect(function()
		if not self.Flying then return end
		if humanoid and humanoid.Parent and humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
		
		local camera = workspace.CurrentCamera
		local velocity = calculateVelocity()
		
		if bodyVelocity then
			bodyVelocity.Velocity = velocity
		end
		
		if bodyGyro then
			bodyGyro.CFrame = camera.CFrame
		end
	end)
	
	print("✈️ Flying enabled! Controls: WASD + Space (up) + Shift (down)")
end

function FlyController:StopFlying()
	if not self.Flying then return end
	
	self.Flying = false
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
			-- Only re-enable states if god mode is OFF
			-- If god mode is ON, these states should remain disabled
			local isGodMode = CommandExecutor
				and CommandExecutor.PlayerStatuses
				and CommandExecutor.PlayerStatuses.god
			if not isGodMode then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			else
				-- God mode is on - just enable climbing, keep safe state
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end
	
	removeBodyMovers()
	
	print("🪂 Flying disabled")
end

function FlyController:Toggle()
	if self.Flying then
		self:StopFlying()
	else
		self:StartFlying()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if UserInputService:GetFocusedTextBox() then return end
	
	for direction, keyCode in pairs(movementKeys) do
		if input.KeyCode == keyCode then
			keysPressed[direction] = true
			break
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	for direction, keyCode in pairs(movementKeys) do
		if input.KeyCode == keyCode then
			keysPressed[direction] = false
			break
		end
	end
end)

-- ============================================
-- CLIENT-SIDE COMMAND EXECUTOR
-- ============================================
CommandExecutor = {}
CommandExecutor.PlayerStatuses = {
	fly = false,
	god = false,
	antiafk = false
}
CommandExecutor.GodModeConnections = {}

-- Enable god mode with MAXIMUM protection (true invincibility)
function CommandExecutor:EnableGodMode()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Clean up existing connections
	if self.GodModeConnections then
		for _, conn in ipairs(self.GodModeConnections) do
			pcall(function() conn:Disconnect() end)
		end
	end
	self.GodModeConnections = {}
	
	-- DISABLE all damage-related states PERMANENTLY
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	
	-- Set health to huge
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	
	-- CRITICAL: RenderStepped has highest priority - runs BEFORE physics/damage
	-- This catches health changes INSTANTLY before death can occur
	local renderConn = RunService.RenderStepped:Connect(function()
		if self.PlayerStatuses.god then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					-- Force health to max EVERY frame with highest priority
					if hum.Health ~= math.huge then
						hum.Health = math.huge
					end
					if hum.MaxHealth ~= math.huge then
						hum.MaxHealth = math.huge
					end
				end
			end
		end

		if UtilityGUI.CameraZoomEnabled then
			UtilityGUI:ApplyCameraZoomSettings()
		end
	end)
	table.insert(self.GodModeConnections, renderConn)
	
	-- Heartbeat backup (runs after physics but before rendering)
	local heartbeatConn = RunService.Heartbeat:Connect(function()
		if self.PlayerStatuses.god then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					if hum.Health < math.huge then
						hum.Health = math.huge
					end
				end
			end
		end

		if UtilityGUI.CameraZoomEnabled then
			UtilityGUI:ApplyCameraZoomSettings()
		end
	end)
	table.insert(self.GodModeConnections, heartbeatConn)
	
	-- Monitor health property changes directly
	local healthPropConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
		if self.PlayerStatuses.god then
			if humanoid.Health ~= math.huge then
				humanoid.Health = math.huge
			end
		end
	end)
	table.insert(self.GodModeConnections, healthPropConn)
	
	-- Prevent death event
	local diedConn = humanoid.Died:Connect(function()
		if self.PlayerStatuses.god then
			-- Immediately revive
			task.spawn(function()
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				humanoid.Health = math.huge
			end)
		end
	end)
	table.insert(self.GodModeConnections, diedConn)
	
	-- Block ANY state change to Dead
	local stateConn = humanoid.StateChanged:Connect(function(oldState, newState)
		if self.PlayerStatuses.god then
			if newState == Enum.HumanoidStateType.Dead or 
			   newState == Enum.HumanoidStateType.FallingDown or
			   newState == Enum.HumanoidStateType.Ragdoll then
				-- Force back to safe state
				task.spawn(function()
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					humanoid.Health = math.huge
				end)
			end
		end
	end)
	table.insert(self.GodModeConnections, stateConn)
	
	self.PlayerStatuses.god = true
	return true
end

-- Disable god mode
function CommandExecutor:DisableGodMode()
	-- Disconnect all god mode connections
	if self.GodModeConnections then
		for _, conn in ipairs(self.GodModeConnections) do
			pcall(function() conn:Disconnect() end)
		end
		self.GodModeConnections = {}
	end
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Re-enable disabled states
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			
			-- Reset health to normal
			humanoid.MaxHealth = 100
			humanoid.Health = 100
		end
	end
	
	self.PlayerStatuses.god = false
	return true
end

function CommandExecutor:GetTargetPlayer(targetName)
	if not targetName or targetName == "" then
		return player
	end
	
	targetName = targetName:lower()
	
	if targetName == "me" or targetName == "self" then
		return player
	end
	
	if targetName == "all" then
		return "all"
	end
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower():sub(1, #targetName) == targetName then
			return plr
		end
	end
	
	return nil
end

function CommandExecutor:Execute(commandText, targetPlayer)
	local command, args = AdminConfig:ParseCommand(commandText)
	
	if command == "" then return false end
	
	-- Commands that work locally
	if command == "fly" then
		if FlyController.Flying then
			FlyController:StopFlying()
			self.PlayerStatuses.fly = false
			return true, "Flying disabled"
		else
			FlyController:StartFlying()
			self.PlayerStatuses.fly = true
			return true, "Flying enabled (Speed: " .. FlyController.Speed .. ")"
		end
		
	elseif command == "flyspeed" or command == "fs" then
		local speed = tonumber(args[1]) or 50
		FlyController.Speed = math.clamp(speed, 10, FlyController.MaxSpeed)
		return true, "Fly speed set to " .. FlyController.Speed
		
	elseif command == "speed" then
		local speed = tonumber(args[1]) or 50
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = speed
			return true, "Speed set to " .. speed
		end
		
	elseif command == "jp" or command == "jumppower" then
		local jp = tonumber(args[1]) or 50
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			-- Support both old (JumpPower) and new (JumpHeight) systems
			if humanoid.UseJumpPower then
				humanoid.JumpPower = jp
			else
				-- Convert JumpPower to JumpHeight (approximate: JumpHeight = JumpPower / 4)
				humanoid.JumpHeight = jp / 4
			end
			return true, "Jump power set to " .. jp
		end
		
	elseif command == "god" then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if self.PlayerStatuses.god then
				-- Turn off god mode
				self:DisableGodMode()
				return true, "God mode disabled"
			else
				-- Turn on god mode
				self:EnableGodMode()
				return true, "God mode enabled (true invincibility)"
			end
		end
		
	elseif command == "goto" or command == "tp" then
		-- Teleport to target player
		if not targetPlayer or targetPlayer == player then
			return false, "Please select a target player first!"
		end
		
		if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
				return true, "Teleported to " .. targetPlayer.Name
			end
		end
		return false, "Target player not found or no character"
		
	elseif command == "reset" then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			local humanoid = player.Character.Humanoid
			humanoid.WalkSpeed = 16
			-- Reset jump to default based on system type
			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
			humanoid.MaxHealth = 100
			humanoid.Health = 100
			FlyController:StopFlying()
			-- Disable god mode properly
			self:DisableGodMode()
			-- Reset all statuses
			self.PlayerStatuses.fly = false
			self.PlayerStatuses.god = false
			return true, "Character reset to normal"
		end
		
	elseif command == "respawn" then
		if player.Character then
			player.Character:BreakJoints()
			return true, "Respawning..."
		end
	
	elseif command == "antiafk" then
		local status = AntiAFK:Toggle()
		self.PlayerStatuses.antiafk = status
		if status then
			return true, "Anti-AFK enabled"
		else
			return true, "Anti-AFK disabled"
		end
	
	else
		return false, "Unknown command: " .. command
	end
	
	return false, "Command failed"
end

-- ============================================
-- ADMIN GUI
-- ============================================
local TweenService = game:GetService("TweenService")

-- Safe PlayerGui loading with timeout (5 seconds max)
local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then
	warn("⚠️ PlayerGui not found after 5 seconds - GUI might not load!")
	return
end

-- Check if already loaded
if playerGui:FindFirstChild("AdminGUI") then
	playerGui.AdminGUI:Destroy()
	print("🔄 Reloading Admin GUI...")
end

local AdminGUI = {}
AdminGUI.IsOpen = false
AdminGUI.SelectedPlayer = nil
AdminGUI.ToggleButtons = {} -- Store toggle button references

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Floating Icon
local floatingIcon = Instance.new("ImageButton")
floatingIcon.Name = "FloatingIcon"
floatingIcon.Size = UDim2.new(0, 60, 0, 60)
floatingIcon.Position = UDim2.new(1, -80, 0.5, -30)
floatingIcon.BackgroundColor3 = AdminConfig.Theme.Accent
floatingIcon.BorderSizePixel = 0
floatingIcon.AutoButtonColor = false
floatingIcon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 30)
iconCorner.Parent = floatingIcon

-- Icon emoji
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "👁️‍🗨️"
iconLabel.TextSize = 32
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Parent = floatingIcon

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 650, 0, 450)
mainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
mainFrame.BackgroundColor3 = AdminConfig.Theme.Primary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = AdminConfig.Theme.Secondary
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = AdminConfig.Theme.Secondary
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -160, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚙️ TwoHand Comunity - Admin Panel"
titleLabel.TextColor3 = AdminConfig.Theme.Text
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Discord Button
local discordButton = Instance.new("TextButton")
discordButton.Name = "DiscordButton"
discordButton.Size = UDim2.new(0, 40, 0, 40)
discordButton.Position = UDim2.new(1, -100, 0.5, -20)
discordButton.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordButton.BorderSizePixel = 0
discordButton.Text = "💬"
discordButton.TextColor3 = Color3.fromRGB(255, 255, 255)
discordButton.TextSize = 20
discordButton.Font = Enum.Font.GothamBold
discordButton.Parent = titleBar

local discordCorner = Instance.new("UICorner")
discordCorner.CornerRadius = UDim.new(0, 8)
discordCorner.Parent = discordButton

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0.5, -20)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Watermark
local watermark = Instance.new("Frame")
watermark.Name = "Watermark"
watermark.Size = UDim2.new(1, -30, 0, 30)
watermark.Position = UDim2.new(0, 15, 0, 55)
watermark.BackgroundColor3 = AdminConfig.Theme.Secondary
watermark.BorderSizePixel = 0
watermark.Parent = mainFrame

local watermarkCorner = Instance.new("UICorner")
watermarkCorner.CornerRadius = UDim.new(0, 6)
watermarkCorner.Parent = watermark

local watermarkText = Instance.new("TextLabel")
watermarkText.Size = UDim2.new(1, -20, 1, 0)
watermarkText.Position = UDim2.new(0, 10, 0, 0)
watermarkText.BackgroundTransparency = 1
watermarkText.Text = "⚙️ Made by TwoHand Comunity | discord.gg/xHrJaSgy"
watermarkText.TextColor3 = AdminConfig.Theme.Text
watermarkText.TextSize = 12
watermarkText.Font = Enum.Font.Gotham
watermarkText.TextXAlignment = Enum.TextXAlignment.Left
watermarkText.TextTransparency = 0.3
watermarkText.Parent = watermark

-- Player Selector
local playerSelectorFrame = Instance.new("Frame")
playerSelectorFrame.Name = "PlayerSelector"
playerSelectorFrame.Size = UDim2.new(1, -30, 0, 45)
playerSelectorFrame.Position = UDim2.new(0, 15, 0, 90)
playerSelectorFrame.BackgroundColor3 = AdminConfig.Theme.Secondary
playerSelectorFrame.BorderSizePixel = 0
playerSelectorFrame.Parent = mainFrame

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0, 8)
selectorCorner.Parent = playerSelectorFrame

local selectorLabel = Instance.new("TextLabel")
selectorLabel.Size = UDim2.new(0, 100, 1, 0)
selectorLabel.Position = UDim2.new(0, 10, 0, 0)
selectorLabel.BackgroundTransparency = 1
selectorLabel.Text = "Target Player:"
selectorLabel.TextColor3 = AdminConfig.Theme.Text
selectorLabel.TextSize = 14
selectorLabel.Font = Enum.Font.Gotham
selectorLabel.TextXAlignment = Enum.TextXAlignment.Left
selectorLabel.Parent = playerSelectorFrame

local playerDropdown = Instance.new("TextButton")
playerDropdown.Name = "PlayerDropdown"
playerDropdown.Size = UDim2.new(1, -220, 0, 35)
playerDropdown.Position = UDim2.new(0, 115, 0, 5)
playerDropdown.BackgroundColor3 = AdminConfig.Theme.Primary
playerDropdown.BorderSizePixel = 0
playerDropdown.Text = "Me (Self)"
playerDropdown.TextColor3 = AdminConfig.Theme.Text
playerDropdown.TextSize = 14
playerDropdown.Font = Enum.Font.GothamBold
playerDropdown.TextXAlignment = Enum.TextXAlignment.Left
playerDropdown.Parent = playerSelectorFrame

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 6)
dropdownCorner.Parent = playerDropdown

local dropdownPadding = Instance.new("UIPadding")
dropdownPadding.PaddingLeft = UDim.new(0, 10)
dropdownPadding.Parent = playerDropdown

local dropdownArrow = Instance.new("TextLabel")
dropdownArrow.Size = UDim2.new(0, 30, 1, 0)
dropdownArrow.Position = UDim2.new(1, -30, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Text = "▼"
dropdownArrow.TextColor3 = AdminConfig.Theme.Text
dropdownArrow.TextSize = 12
dropdownArrow.Font = Enum.Font.GothamBold
dropdownArrow.Parent = playerDropdown

local refreshButton = Instance.new("TextButton")
refreshButton.Name = "RefreshButton"
refreshButton.Size = UDim2.new(0, 80, 0, 35)
refreshButton.Position = UDim2.new(1, -180, 0, 5)
refreshButton.BackgroundColor3 = AdminConfig.Theme.Accent
refreshButton.BorderSizePixel = 0
refreshButton.Text = "🔄 Refresh"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.TextSize = 12
refreshButton.Font = Enum.Font.GothamBold
refreshButton.Parent = playerSelectorFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- Reset button (next to refresh)
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(0, 80, 0, 35)
resetButton.Position = UDim2.new(1, -90, 0, 5)
resetButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
resetButton.BorderSizePixel = 0
resetButton.Text = "♻️ Reset"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextSize = 12
resetButton.Font = Enum.Font.GothamBold
resetButton.Parent = playerSelectorFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetButton

-- Player List Dropdown
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerListFrame"
playerListFrame.Size = UDim2.new(0, 0, 0, 0)
playerListFrame.Position = UDim2.new(0, 115, 0, 140)
playerListFrame.BackgroundColor3 = AdminConfig.Theme.Secondary
playerListFrame.BorderSizePixel = 0
playerListFrame.Visible = false
playerListFrame.ScrollBarThickness = 4
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListFrame.ClipsDescendants = true
playerListFrame.ZIndex = 5
playerListFrame.Parent = mainFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = playerListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = playerListFrame

-- Commands Container
local commandsContainer = Instance.new("ScrollingFrame")
commandsContainer.Name = "CommandsContainer"
commandsContainer.Size = UDim2.new(1, -30, 1, -155)
commandsContainer.Position = UDim2.new(0, 15, 0, 145)
commandsContainer.BackgroundTransparency = 1
commandsContainer.BorderSizePixel = 0
commandsContainer.ScrollBarThickness = 6
commandsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
commandsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
commandsContainer.Visible = true
commandsContainer.Parent = mainFrame

local commandsLayout = Instance.new("UIListLayout")
commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
commandsLayout.Padding = UDim.new(0, 10)
commandsLayout.Parent = commandsContainer

-- Helper: Create Category
local function createCategory(name, order)
	local category = Instance.new("Frame")
	category.Name = name .. "Category"
	category.Size = UDim2.new(1, -10, 0, 0)
	category.AutomaticSize = Enum.AutomaticSize.Y
	category.BackgroundColor3 = AdminConfig.Theme.Secondary
	category.BorderSizePixel = 0
	category.LayoutOrder = order
	category.Parent = commandsContainer
	
	local categoryCorner = Instance.new("UICorner")
	categoryCorner.CornerRadius = UDim.new(0, 8)
	categoryCorner.Parent = category
	
	local categoryPadding = Instance.new("UIPadding")
	categoryPadding.PaddingTop = UDim.new(0, 10)
	categoryPadding.PaddingBottom = UDim.new(0, 10)
	categoryPadding.PaddingLeft = UDim.new(0, 10)
	categoryPadding.PaddingRight = UDim.new(0, 10)
	categoryPadding.Parent = category
	
	local categoryLayout = Instance.new("UIListLayout")
	categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
	categoryLayout.Padding = UDim.new(0, 8)
	categoryLayout.Parent = category
	
	local categoryTitle = Instance.new("TextLabel")
	categoryTitle.Name = "Title"
	categoryTitle.Size = UDim2.new(1, 0, 0, 25)
	categoryTitle.BackgroundTransparency = 1
	categoryTitle.Text = name
	categoryTitle.TextColor3 = AdminConfig.Theme.Accent
	categoryTitle.TextSize = 16
	categoryTitle.Font = Enum.Font.GothamBold
	categoryTitle.TextXAlignment = Enum.TextXAlignment.Left
	categoryTitle.LayoutOrder = 0
	categoryTitle.Parent = category
	
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.Name = "Buttons"
	buttonsFrame.Size = UDim2.new(1, 0, 0, 0)
	buttonsFrame.AutomaticSize = Enum.AutomaticSize.Y
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.LayoutOrder = 1
	buttonsFrame.Parent = category
	
	local buttonsGrid = Instance.new("UIGridLayout")
	buttonsGrid.CellSize = UDim2.new(0, 190, 0, 40)
	buttonsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	buttonsGrid.SortOrder = Enum.SortOrder.LayoutOrder
	buttonsGrid.Parent = buttonsFrame
	
	return buttonsFrame
end

-- Helper: Create Command Button
local function createCommandButton(parent, text, icon, command, order, isToggle)
	local button = Instance.new("TextButton")
	button.Name = command
	button.BackgroundColor3 = AdminConfig.Theme.Primary
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Parent = parent
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button
	
	local buttonLabel = Instance.new("TextLabel")
	buttonLabel.Name = "Label"
	buttonLabel.Size = UDim2.new(1, -60, 1, 0)
	buttonLabel.Position = UDim2.new(0, 10, 0, 0)
	buttonLabel.BackgroundTransparency = 1
	buttonLabel.Text = icon .. " " .. text
	buttonLabel.TextColor3 = AdminConfig.Theme.Text
	buttonLabel.TextSize = 13
	buttonLabel.Font = Enum.Font.GothamBold
	buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
	buttonLabel.Parent = button
	
	-- Add status indicator for toggle buttons
	if isToggle then
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "Status"
		statusLabel.Size = UDim2.new(0, 50, 1, 0)
		statusLabel.Position = UDim2.new(1, -55, 0, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = "OFF"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		statusLabel.TextSize = 11
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.Parent = button
		
		-- Store reference
		AdminGUI.ToggleButtons[command] = {button = button, status = statusLabel}
	end
	
	return button
end

-- Create Categories
local characterButtons = createCategory("⚡ Character Mods", 1)
createCommandButton(characterButtons, "Speed", "🏃", "speed", 1, false)
createCommandButton(characterButtons, "Jump Power", "🦘", "jp", 2, false)
createCommandButton(characterButtons, "God Mode", "🛡️", "god", 3, true)

local flyButtons = createCategory("✈️ Flying", 2)
createCommandButton(flyButtons, "Fly Mode", "🚀", "fly", 1, true)
createCommandButton(flyButtons, "Fly Speed", "⚡", "flyspeed", 2, false)

local teleportButtons = createCategory("🌐 Teleport", 3)
createCommandButton(teleportButtons, "Go To Player", "📍", "goto", 1, false)

local otherButtons = createCategory("🔧 Other", 4)
createCommandButton(otherButtons, "Respawn", "🔄", "respawn", 1, false)
createCommandButton(otherButtons, "Anti-AFK", "⏰", "antiafk", 2, true)

-- Notification Frame
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 300, 0, 70)
notificationFrame.Position = UDim2.new(1, 0, 0, 10)
notificationFrame.AnchorPoint = Vector2.new(1, 0)
notificationFrame.BackgroundColor3 = AdminConfig.Theme.Primary
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notificationFrame

local notificationText = Instance.new("TextLabel")
notificationText.Size = UDim2.new(1, -20, 1, -20)
notificationText.Position = UDim2.new(0, 10, 0, 10)
notificationText.BackgroundTransparency = 1
notificationText.Text = ""
notificationText.TextColor3 = AdminConfig.Theme.Text
notificationText.TextSize = 14
notificationText.Font = Enum.Font.Gotham
notificationText.TextWrapped = true
notificationText.TextXAlignment = Enum.TextXAlignment.Left
notificationText.TextYAlignment = Enum.TextYAlignment.Top
notificationText.Parent = notificationFrame

-- Input Dialog
local inputDialog = Instance.new("Frame")
inputDialog.Name = "InputDialog"
inputDialog.Size = UDim2.new(0, 400, 0, 150)
inputDialog.Position = UDim2.new(0.5, -200, 0.5, -75)
inputDialog.BackgroundColor3 = AdminConfig.Theme.Primary
inputDialog.BorderSizePixel = 0
inputDialog.Visible = false
inputDialog.ZIndex = 10
inputDialog.Parent = screenGui

local dialogCorner = Instance.new("UICorner")
dialogCorner.CornerRadius = UDim.new(0, 10)
dialogCorner.Parent = inputDialog

local dialogTitle = Instance.new("TextLabel")
dialogTitle.Size = UDim2.new(1, -20, 0, 30)
dialogTitle.Position = UDim2.new(0, 10, 0, 10)
dialogTitle.BackgroundTransparency = 1
dialogTitle.Text = "Input Required"
dialogTitle.TextColor3 = AdminConfig.Theme.Text
dialogTitle.TextSize = 16
dialogTitle.Font = Enum.Font.GothamBold
dialogTitle.TextXAlignment = Enum.TextXAlignment.Left
dialogTitle.Parent = inputDialog

local dialogInput = Instance.new("TextBox")
dialogInput.Name = "Input"
dialogInput.Size = UDim2.new(1, -40, 0, 40)
dialogInput.Position = UDim2.new(0, 20, 0, 50)
dialogInput.BackgroundColor3 = AdminConfig.Theme.Secondary
dialogInput.BorderSizePixel = 0
dialogInput.PlaceholderText = "Enter value..."
dialogInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
dialogInput.Text = ""
dialogInput.TextColor3 = AdminConfig.Theme.Text
dialogInput.TextSize = 14
dialogInput.Font = Enum.Font.Gotham
dialogInput.ClearTextOnFocus = false
dialogInput.Parent = inputDialog

local dialogInputCorner = Instance.new("UICorner")
dialogInputCorner.CornerRadius = UDim.new(0, 6)
dialogInputCorner.Parent = dialogInput

local dialogPadding = Instance.new("UIPadding")
dialogPadding.PaddingLeft = UDim.new(0, 10)
dialogPadding.Parent = dialogInput

local dialogOK = Instance.new("TextButton")
dialogOK.Name = "OK"
dialogOK.Size = UDim2.new(0, 100, 0, 35)
dialogOK.Position = UDim2.new(1, -215, 1, -45)
dialogOK.BackgroundColor3 = AdminConfig.Theme.Success
dialogOK.BorderSizePixel = 0
dialogOK.Text = "OK"
dialogOK.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogOK.TextSize = 14
dialogOK.Font = Enum.Font.GothamBold
dialogOK.Parent = inputDialog

local dialogOKCorner = Instance.new("UICorner")
dialogOKCorner.CornerRadius = UDim.new(0, 6)
dialogOKCorner.Parent = dialogOK

local dialogCancel = Instance.new("TextButton")
dialogCancel.Name = "Cancel"
dialogCancel.Size = UDim2.new(0, 100, 0, 35)
dialogCancel.Position = UDim2.new(1, -105, 1, -45)
dialogCancel.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
dialogCancel.BorderSizePixel = 0
dialogCancel.Text = "Cancel"
dialogCancel.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogCancel.TextSize = 14
dialogCancel.Font = Enum.Font.GothamBold
dialogCancel.Parent = inputDialog

local dialogCancelCorner = Instance.new("UICorner")
dialogCancelCorner.CornerRadius = UDim.new(0, 6)
dialogCancelCorner.Parent = dialogCancel

-- Functions
local dialogResult = nil
local dialogWaiting = false

function AdminGUI:ShowInputDialog(promptText)
	dialogTitle.Text = promptText
	dialogInput.Text = ""
	inputDialog.Visible = true
	dialogInput:CaptureFocus()
	dialogResult = nil
	dialogWaiting = true
	
	while dialogWaiting do
		task.wait()
	end
	
	return dialogResult
end

function AdminGUI:ShowNotification(message, notifType)
	local color = AdminConfig.Theme.Primary
	
	if notifType == "success" then
		color = AdminConfig.Theme.Success
	elseif notifType == "error" then
		color = AdminConfig.Theme.Error
	end
	
	notificationFrame.BackgroundColor3 = color
	notificationText.Text = message
	notificationFrame.Visible = true
	
	notificationFrame.Position = UDim2.new(1, 0, 0, 10)
	local slideIn = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -310, 0, 10)}
	)
	slideIn:Play()
	
	task.delay(3, function()
		local slideOut = TweenService:Create(
			notificationFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Position = UDim2.new(1, 0, 0, 10)}
		)
		slideOut:Play()
		slideOut.Completed:Wait()
		notificationFrame.Visible = false
	end)
end

function AdminGUI:TogglePanel()
	self.IsOpen = not self.IsOpen
	mainFrame.Visible = self.IsOpen
	playerListFrame.Visible = false
	
	if self.IsOpen then
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		local tween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{
				Size = UDim2.new(0, 650, 0, 450),
				Position = UDim2.new(0.5, -325, 0.5, -225)
			}
		)
		tween:Play()
	end
end

function AdminGUI:UpdatePlayerList()
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	local selfButton = Instance.new("TextButton")
	selfButton.Name = "Self"
	selfButton.Size = UDim2.new(1, -10, 0, 30)
	selfButton.BackgroundColor3 = AdminConfig.Theme.Primary
	selfButton.BorderSizePixel = 0
	selfButton.Text = "Me (Self)"
	selfButton.TextColor3 = AdminConfig.Theme.Text
	selfButton.TextSize = 13
	selfButton.Font = Enum.Font.Gotham
	selfButton.TextXAlignment = Enum.TextXAlignment.Left
	selfButton.ZIndex = 6
	selfButton.Parent = playerListFrame
	
	local selfCorner = Instance.new("UICorner")
	selfCorner.CornerRadius = UDim.new(0, 4)
	selfCorner.Parent = selfButton
	
	local selfPadding = Instance.new("UIPadding")
	selfPadding.PaddingLeft = UDim.new(0, 10)
	selfPadding.Parent = selfButton
	
	selfButton.MouseButton1Click:Connect(function()
		AdminGUI.SelectedPlayer = nil
		playerDropdown.Text = "Me (Self)"
		playerListFrame.Visible = false
	end)
	
	for _, plr in ipairs(Players:GetPlayers()) do
		local playerButton = Instance.new("TextButton")
		playerButton.Name = plr.Name
		playerButton.Size = UDim2.new(1, -10, 0, 30)
		playerButton.BackgroundColor3 = AdminConfig.Theme.Primary
		playerButton.BorderSizePixel = 0
		playerButton.Text = plr.Name
		playerButton.TextColor3 = AdminConfig.Theme.Text
		playerButton.TextSize = 13
		playerButton.Font = Enum.Font.Gotham
		playerButton.TextXAlignment = Enum.TextXAlignment.Left
		playerButton.ZIndex = 6
		playerButton.Parent = playerListFrame
		
		local pCorner = Instance.new("UICorner")
		pCorner.CornerRadius = UDim.new(0, 4)
		pCorner.Parent = playerButton
		
		local pPadding = Instance.new("UIPadding")
		pPadding.PaddingLeft = UDim.new(0, 10)
		pPadding.Parent = playerButton
		
		playerButton.MouseButton1Click:Connect(function()
			AdminGUI.SelectedPlayer = plr.Name
			playerDropdown.Text = plr.Name
			playerListFrame.Visible = false
		end)
		
		playerButton.MouseEnter:Connect(function()
			playerButton.BackgroundColor3 = AdminConfig.Theme.Accent
		end)
		playerButton.MouseLeave:Connect(function()
			playerButton.BackgroundColor3 = AdminConfig.Theme.Primary
		end)
	end
end

function AdminGUI:ExecuteCommand(command, requiresInput)
	local commandText = AdminConfig.Prefix .. command
	
	if requiresInput then
		if command == "speed" then
			local speed = self:ShowInputDialog("Enter speed value (default: 16)")
			if not speed then return end
			commandText = commandText .. " " .. speed
		elseif command == "jp" then
			local jp = self:ShowInputDialog("Enter jump power value (default: 50)")
			if not jp then return end
			commandText = commandText .. " " .. jp
		elseif command == "flyspeed" or command == "fs" then
			local flyspeed = self:ShowInputDialog("Enter fly speed (default: 50, max: 200)")
			if not flyspeed then return end
			commandText = commandText .. " " .. flyspeed
		end
	end
	
	-- Get target player from GUI selection
	local targetPlayer = nil
	if self.SelectedPlayer then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name == self.SelectedPlayer then
				targetPlayer = plr
				break
			end
		end
	end
	
	local success, message = CommandExecutor:Execute(commandText, targetPlayer)
	
	if success then
		self:ShowNotification(message, "success")
		-- Update toggle button status
		self:UpdateToggleStatus(command)
	else
		self:ShowNotification(message or "Command failed", "error")
	end
end

-- Update toggle button visual status
function AdminGUI:UpdateToggleStatus(command)
	local toggleData = self.ToggleButtons[command]
	if not toggleData then return end
	
	local isActive = CommandExecutor.PlayerStatuses[command]
	local statusLabel = toggleData.status
	
	if isActive then
		statusLabel.Text = "ON"
		statusLabel.TextColor3 = AdminConfig.Theme.Success
		toggleData.button.BackgroundColor3 = Color3.fromRGB(25, 60, 25) -- Dark green
	else
		statusLabel.Text = "OFF"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		toggleData.button.BackgroundColor3 = AdminConfig.Theme.Primary
	end
end

-- Refresh all toggle statuses
function AdminGUI:RefreshAllToggles()
	for command, _ in pairs(self.ToggleButtons) do
		self:UpdateToggleStatus(command)
	end
end

-- Event Connections
dialogOK.MouseButton1Click:Connect(function()
	if dialogInput.Text ~= "" then
		dialogResult = dialogInput.Text
	end
	dialogWaiting = false
	inputDialog.Visible = false
end)

dialogCancel.MouseButton1Click:Connect(function()
	dialogResult = nil
	dialogWaiting = false
	inputDialog.Visible = false
end)

dialogInput.FocusLost:Connect(function(enterPressed)
	if enterPressed and inputDialog.Visible then
		if dialogInput.Text ~= "" then
			dialogResult = dialogInput.Text
		end
		dialogWaiting = false
		inputDialog.Visible = false
	end
end)

local iconDragging = false
local dragInput
local dragStart
local startPos
local isDragging = false

-- Click handler (only triggers if not dragging)
floatingIcon.MouseButton1Click:Connect(function()
	if not isDragging then
		AdminGUI:TogglePanel()
	end
end)

floatingIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		isDragging = false
		dragInput = input
		dragStart = input.Position
		startPos = floatingIcon.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				iconDragging = false
				-- Reset drag flag after short delay
				task.wait(0.1)
				isDragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		
		-- Check if moved significantly (more than 3 pixels)
		if delta.Magnitude > 3 then
			isDragging = true -- Mark as dragging to prevent click
		end
		
		-- Calculate new position
		local newPosition = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
		
		floatingIcon.Position = newPosition
	end
end)

closeButton.MouseButton1Click:Connect(function()
	AdminGUI:TogglePanel()
end)

discordButton.MouseButton1Click:Connect(function()
	local discordLink = "https://discord.gg/xHrJaSgy"
	if setclipboard then
		setclipboard(discordLink)
		AdminGUI:ShowNotification("Discord link copied to clipboard!", "success")
	else
		AdminGUI:ShowNotification("Discord: discord.gg/xHrJaSgy", "info")
	end
	print("TwoHand Comunity Discord: " .. discordLink)
end)

playerDropdown.MouseButton1Click:Connect(function()
	playerListFrame.Visible = not playerListFrame.Visible
	
	if playerListFrame.Visible then
		AdminGUI:UpdatePlayerList()
		local targetHeight = math.min(#Players:GetPlayers() * 32 + 32, 200)
		playerListFrame.Size = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(
			playerListFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, playerDropdown.AbsoluteSize.X, 0, targetHeight)}
		)
		tween:Play()
	else
		playerListFrame.Size = UDim2.new(0, 0, 0, 0)
	end
end)

refreshButton.MouseButton1Click:Connect(function()
	AdminGUI:UpdatePlayerList()
	AdminGUI:RefreshAllToggles() -- Refresh toggle statuses too
	AdminGUI:ShowNotification("Player list refreshed!", "success")
end)

-- Reset button
resetButton.MouseButton1Click:Connect(function()
	AdminGUI:ExecuteCommand("reset", false)
end)

local function connectCommandButton(buttonName, command, requiresInput)
	for _, category in ipairs(commandsContainer:GetChildren()) do
		if category:IsA("Frame") then
			local buttonsFrame = category:FindFirstChild("Buttons")
			if buttonsFrame then
				local button = buttonsFrame:FindFirstChild(buttonName)
				if button and button:IsA("TextButton") then
					button.MouseButton1Click:Connect(function()
						AdminGUI:ExecuteCommand(command, requiresInput)
					end)
					
					-- Hover effect (but maintain toggle color if active)
					button.MouseEnter:Connect(function()
						local isToggleActive = CommandExecutor.PlayerStatuses[command]
						if not isToggleActive then
							TweenService:Create(
								button,
								TweenInfo.new(0.2),
								{BackgroundColor3 = AdminConfig.Theme.Accent}
							):Play()
						end
					end)
					button.MouseLeave:Connect(function()
						local isToggleActive = CommandExecutor.PlayerStatuses[command]
						local targetColor = AdminConfig.Theme.Primary
						if isToggleActive then
							targetColor = Color3.fromRGB(25, 60, 25) -- Dark green for active
						end
						TweenService:Create(
							button,
							TweenInfo.new(0.2),
							{BackgroundColor3 = targetColor}
						):Play()
					end)
					break
				end
			end
		end
	end
end

connectCommandButton("speed", "speed", true)
connectCommandButton("jp", "jp", true)
connectCommandButton("god", "god", false)
connectCommandButton("fly", "fly", false)
connectCommandButton("flyspeed", "flyspeed", true)
connectCommandButton("goto", "goto", false)
connectCommandButton("respawn", "respawn", false)
connectCommandButton("antiafk", "antiafk", false)

local dragging = false
local dragInput
local dragStart
local startPos

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

AdminGUI:UpdatePlayerList()
AdminGUI:RefreshAllToggles() -- Initialize toggle statuses

-- ============================================
-- CHARACTER RESPAWN HANDLER
-- ============================================
-- Reapply god mode when character respawns
player.CharacterAdded:Connect(function(character)
	task.wait(0.1) -- Wait for character to fully load
	if CommandExecutor.PlayerStatuses.god then
		CommandExecutor:EnableGodMode()
		AdminGUI:ShowNotification("God mode reapplied after respawn!", "success")
	end
end)

-- ============================================
-- UTILITY GUI MODULE (SEPARATE FROM ADMIN)
-- Features: Cursor Unlock, ESP Wallhack, Speed Boost
-- ============================================

local UtilityGUI = {}
UtilityGUI.CursorEnabled = false
UtilityGUI.ESPEnabled = false
UtilityGUI.SpeedEnabled = false
UtilityGUI.CrosshairEnabled = false
UtilityGUI.CameraZoomEnabled = false
UtilityGUI.FastVaultEnabled = false
UtilityGUI.DefaultSpeed = 16
UtilityGUI.BoostSpeed = 20
UtilityGUI.CameraMinZoom = 0.5
UtilityGUI.CameraMaxZoom = 20
UtilityGUI.FastVaultJumpMultiplier = 1.8
UtilityGUI.FastVaultAnimMultiplier = 2.3
UtilityGUI.FastVaultDuration = 1.0
UtilityGUI.FastVaultBoostActive = false
UtilityGUI.FastVaultProximityLoop = nil
UtilityGUI.FastVaultIndicator = nil
UtilityGUI.StoredCameraSettings = nil
UtilityGUI.CameraZoomConnection = nil
UtilityGUI.StoredMouseSettings = nil
UtilityGUI.FastVaultInputConnection = nil
UtilityGUI.FastVaultPromptShownConnection = nil
UtilityGUI.FastVaultPromptHiddenConnection = nil
UtilityGUI.FastVaultPromptHoldConnection = nil
UtilityGUI.FastVaultVisiblePrompts = {}
UtilityGUI.ESPHighlights = {}
UtilityGUI.ESPNameTags = {}
UtilityGUI.VaultESPHighlights = {}
UtilityGUI.VaultESPMarkers = {}
UtilityGUI.VaultESPConnection = nil
UtilityGUI.FastGeneratorPromptConnection = nil
UtilityGUI.FastGeneratorPromptStates = {}
UtilityGUI.CrosshairFrame = nil
UtilityGUI.GeneratorKeywords = {
	"generator", "repair", "build", "gen"
}
UtilityGUI.PalletESPHighlights = {}
UtilityGUI.PalletESPEnabled = false
UtilityGUI.PalletESPConnection = nil

-- Check if already loaded
if playerGui:FindFirstChild("UtilityGUI") then
	playerGui.UtilityGUI:Destroy()
	print("🔄 Reloading Utility GUI...")
end

-- Create separate ScreenGui for Utility
local utilityScreenGui = Instance.new("ScreenGui")
utilityScreenGui.Name = "UtilityGUI"
utilityScreenGui.ResetOnSpawn = false
utilityScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
utilityScreenGui.IgnoreGuiInset = true
utilityScreenGui.Parent = playerGui

-- ==================== FLOATING ICON BUTTON ====================
local utilityIcon = Instance.new("ImageButton")
utilityIcon.Name = "UtilityIcon"
utilityIcon.Size = UDim2.new(0, 60, 0, 60)
utilityIcon.Position = UDim2.new(1, -80, 0.5, 60)  -- Below admin icon
utilityIcon.BackgroundColor3 = Color3.fromRGB(100, 149, 237) -- Cornflower blue
utilityIcon.BorderSizePixel = 0
utilityIcon.AutoButtonColor = false
utilityIcon.Parent = utilityScreenGui

local utilityIconCorner = Instance.new("UICorner")
utilityIconCorner.CornerRadius = UDim.new(0, 30)
utilityIconCorner.Parent = utilityIcon

local utilityIconLabel = Instance.new("TextLabel")
utilityIconLabel.Size = UDim2.new(1, 0, 1, 0)
utilityIconLabel.BackgroundTransparency = 1
utilityIconLabel.Text = "⚡"
utilityIconLabel.TextSize = 32
utilityIconLabel.Font = Enum.Font.GothamBold
utilityIconLabel.Parent = utilityIcon

-- Icon shadow
local utilityIconShadow = Instance.new("ImageLabel")
utilityIconShadow.Name = "Shadow"
utilityIconShadow.BackgroundTransparency = 1
utilityIconShadow.Position = UDim2.new(0, -5, 0, -5)
utilityIconShadow.Size = UDim2.new(1, 10, 1, 10)
utilityIconShadow.ZIndex = 0
utilityIconShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
utilityIconShadow.ImageColor3 = Color3.new(0, 0, 0)
utilityIconShadow.ImageTransparency = 0.7
utilityIconShadow.Parent = utilityIcon

-- ==================== MAIN PANEL ====================
local utilityMainFrame = Instance.new("Frame")
utilityMainFrame.Name = "MainFrame"
utilityMainFrame.Size = UDim2.new(0, 400, 0, 300)
utilityMainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
utilityMainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
utilityMainFrame.BorderSizePixel = 0
utilityMainFrame.Visible = false
utilityMainFrame.Parent = utilityScreenGui

local utilityMainCorner = Instance.new("UICorner")
utilityMainCorner.CornerRadius = UDim.new(0, 12)
utilityMainCorner.Parent = utilityMainFrame

-- Create title bar
local utilityTitleBar = Instance.new("Frame")
utilityTitleBar.Name = "TitleBar"
utilityTitleBar.Size = UDim2.new(1, 0, 0, 50)
utilityTitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
utilityTitleBar.BorderSizePixel = 0
utilityTitleBar.Parent = utilityMainFrame

local utilityTitleCorner = Instance.new("UICorner")
utilityTitleCorner.CornerRadius = UDim.new(0, 12)
utilityTitleCorner.Parent = utilityTitleBar

local utilityTitleFix = Instance.new("Frame")
utilityTitleFix.Size = UDim2.new(1, 0, 0, 12)
utilityTitleFix.Position = UDim2.new(0, 0, 1, -12)
utilityTitleFix.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
utilityTitleFix.BorderSizePixel = 0
utilityTitleFix.Parent = utilityTitleBar

-- Title text
local utilityTitleLabel = Instance.new("TextLabel")
utilityTitleLabel.Size = UDim2.new(1, -100, 1, 0)
utilityTitleLabel.Position = UDim2.new(0, 20, 0, 0)
utilityTitleLabel.BackgroundTransparency = 1
utilityTitleLabel.Text = "⚡ Violence District"
utilityTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
utilityTitleLabel.TextSize = 20
utilityTitleLabel.Font = Enum.Font.GothamBold
utilityTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
utilityTitleLabel.Parent = utilityTitleBar

-- Close button
local utilityCloseButton = Instance.new("TextButton")
utilityCloseButton.Name = "CloseButton"
utilityCloseButton.Size = UDim2.new(0, 40, 0, 40)
utilityCloseButton.Position = UDim2.new(1, -45, 0, 5)
utilityCloseButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
utilityCloseButton.BorderSizePixel = 0
utilityCloseButton.Text = "✕"
utilityCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
utilityCloseButton.TextSize = 20
utilityCloseButton.Font = Enum.Font.GothamBold
utilityCloseButton.Parent = utilityTitleBar

local utilityCloseCorner = Instance.new("UICorner")
utilityCloseCorner.CornerRadius = UDim.new(0, 8)
utilityCloseCorner.Parent = utilityCloseButton

-- ==================== CONTENT AREA ====================
local utilityContentFrame = Instance.new("ScrollingFrame")
utilityContentFrame.Name = "ContentFrame"
utilityContentFrame.Size = UDim2.new(1, -40, 1, -90)
utilityContentFrame.Position = UDim2.new(0, 20, 0, 70)
utilityContentFrame.BackgroundTransparency = 1
utilityContentFrame.BorderSizePixel = 0
utilityContentFrame.ScrollBarThickness = 6
utilityContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
utilityContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
utilityContentFrame.Parent = utilityMainFrame

local utilityContentLayout = Instance.new("UIListLayout")
utilityContentLayout.Padding = UDim.new(0, 15)
utilityContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
utilityContentLayout.Parent = utilityContentFrame

-- ==================== UTILITY FUNCTIONS ====================

-- Create feature card
local function createUtilityCard(title, description, keyBind, callback)
	local card = Instance.new("Frame")
	card.Name = title .. "Card"
	card.Size = UDim2.new(1, 0, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	card.BorderSizePixel = 0
	card.Parent = utilityContentFrame
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -120, 0, 25)
	titleLabel.Position = UDim2.new(0, 15, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = card
	
	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -120, 0, 20)
	descLabel.Position = UDim2.new(0, 15, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.TextSize = 12
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card
	
	-- Keybind label
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(0, 30, 0, 30)
	keyLabel.Position = UDim2.new(1, -100, 0, 10)
	keyLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	keyLabel.BorderSizePixel = 0
	keyLabel.Text = keyBind
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.TextSize = 16
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Parent = card
	
	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyLabel
	
	-- Status button
	local statusButton = Instance.new("TextButton")
	statusButton.Name = "StatusButton"
	statusButton.Size = UDim2.new(0, 60, 0, 30)
	statusButton.Position = UDim2.new(1, -60, 0, 10)
	statusButton.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
	statusButton.BorderSizePixel = 0
	statusButton.Text = "OFF"
	statusButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusButton.TextSize = 14
	statusButton.Font = Enum.Font.GothamBold
	statusButton.Parent = card
	
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusButton
	
	-- Button functionality
	statusButton.MouseButton1Click:Connect(function()
		local newStatus = callback()
		statusButton.Text = newStatus and "ON" or "OFF"
		statusButton.BackgroundColor3 = newStatus and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
		TweenService:Create(statusButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 70, 0, 35)}):Play()
		wait(0.1)
		TweenService:Create(statusButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 60, 0, 30)}):Play()
	end)
	
	return statusButton
end

local function hasKeyword(text, keywords)
	if not text or text == "" then
		return false
	end

	local loweredText = string.lower(text)
	for _, keyword in ipairs(keywords) do
		if string.find(loweredText, keyword, 1, true) then
			return true
		end
	end

	return false
end

function UtilityGUI:NotifyToggle(featureName, enabled)
	local message = string.format("%s %s", featureName, enabled and "ON" or "OFF")
	local notifType = enabled and "success" or "info"
	if AdminGUI and AdminGUI.ShowNotification then
		AdminGUI:ShowNotification(message, notifType)
	end
end

function UtilityGUI:IsVaultObject(instance)
	if not instance then return false end

	if instance:IsA("ClickDetector") then
		return true
	end

	if not instance:IsA("ProximityPrompt") then
		return false
	end

	return instance.KeyboardKeyCode == Enum.KeyCode.E
		or instance.KeyboardKeyCode == Enum.KeyCode.Space
		or instance.ClickablePrompt == true
end

function UtilityGUI:ResolveVaultAdornee(instance)
	if not instance then return nil end

	if instance:IsA("BasePart") or instance:IsA("Model") then
		return instance
	end

	if instance:IsA("ProximityPrompt") then
		local promptParent = instance.Parent
		if promptParent and (promptParent:IsA("BasePart") or promptParent:IsA("Model")) then
			return promptParent
		end

		local modelAncestor = instance:FindFirstAncestorOfClass("Model")
		if modelAncestor then
			return modelAncestor
		end
	end

	if instance:IsA("ClickDetector") then
		local detectorParent = instance.Parent
		if detectorParent and (detectorParent:IsA("BasePart") or detectorParent:IsA("Model")) then
			return detectorParent
		end
	end

	local basePartAncestor = instance:FindFirstAncestorOfClass("BasePart")
	if basePartAncestor then
		return basePartAncestor
	end

	return instance:FindFirstAncestorOfClass("Model")
end

function UtilityGUI:GetAdorneeBasePart(adornee)
	if not adornee then return nil end

	if adornee:IsA("BasePart") then
		return adornee
	end

	if adornee:IsA("Model") then
		return adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

function UtilityGUI:GetInteractIndicatorText(instance)
	if not instance then
		return "INTERACT"
	end

	if instance:IsA("ClickDetector") then
		return "LMB"
	end

	if not instance:IsA("ProximityPrompt") then
		return "INTERACT"
	end

	if instance.KeyboardKeyCode == Enum.KeyCode.E then
		return "E"
	end

	if instance.KeyboardKeyCode == Enum.KeyCode.Space then
		return "SPACE"
	end

	if instance.ClickablePrompt then
		return "LMB"
	end

	return "INTERACT"
end

function UtilityGUI:AddVaultESP(instance)
	local adornee = self:ResolveVaultAdornee(instance)
	if not adornee or self.VaultESPHighlights[adornee] then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "Vault_ESP_Highlight"
	highlight.Adornee = adornee
	highlight.FillColor = Color3.fromRGB(0, 170, 255)
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0.2
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = workspace

	self.VaultESPHighlights[adornee] = highlight

	local markerPart = self:GetAdorneeBasePart(adornee)
	if markerPart then
		local marker = Instance.new("BillboardGui")
		marker.Name = "Interact_Indicator"
		marker.Adornee = markerPart
		marker.Size = UDim2.new(0, 90, 0, 28)
		marker.StudsOffset = Vector3.new(0, 2.5, 0)
		marker.AlwaysOnTop = true
		marker.MaxDistance = 1500
		marker.Parent = markerPart

		local markerText = Instance.new("TextLabel")
		markerText.Size = UDim2.new(1, 0, 1, 0)
		markerText.BackgroundTransparency = 1
		markerText.Text = self:GetInteractIndicatorText(instance)
		markerText.TextColor3 = Color3.fromRGB(255, 220, 0)
		markerText.TextStrokeTransparency = 0
		markerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		markerText.TextScaled = true
		markerText.Font = Enum.Font.GothamBlack
		markerText.Parent = marker

		self.VaultESPMarkers[adornee] = marker
	end
end

function UtilityGUI:ClearVaultESP()
	for _, highlight in pairs(self.VaultESPHighlights) do
		if highlight then
			highlight:Destroy()
		end
	end

	for _, marker in pairs(self.VaultESPMarkers) do
		if marker then
			marker:Destroy()
		end
	end

	table.clear(self.VaultESPHighlights)
	table.clear(self.VaultESPMarkers)

	if self.VaultESPConnection then
		self.VaultESPConnection:Disconnect()
		self.VaultESPConnection = nil
	end
end

function UtilityGUI:EnableVaultESP()
	self:ClearVaultESP()

	local descendants = workspace:GetDescendants()
	task.spawn(function()
		for index, instance in ipairs(descendants) do
			if not self.ESPEnabled then
				break
			end

			if self:IsVaultObject(instance) then
				self:AddVaultESP(instance)
			end

			if index % 200 == 0 then
				task.wait()
			end
		end
	end)

	self.VaultESPConnection = workspace.DescendantAdded:Connect(function(instance)
		if not self.ESPEnabled then return end
		if self:IsVaultObject(instance) then
			self:AddVaultESP(instance)
		end
	end)
end

function UtilityGUI:IsGeneratorPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end

	if hasKeyword(prompt.ActionText, self.GeneratorKeywords)
		or hasKeyword(prompt.ObjectText, self.GeneratorKeywords)
		or hasKeyword(prompt.Name, self.GeneratorKeywords) then
		return true
	end

	local parent = prompt.Parent
	if parent and hasKeyword(parent.Name, self.GeneratorKeywords) then
		return true
	end

	local modelAncestor = prompt:FindFirstAncestorOfClass("Model")
	if modelAncestor and hasKeyword(modelAncestor.Name, self.GeneratorKeywords) then
		return true
	end

	return false
end

function UtilityGUI:ApplyFastGeneratorPrompt(prompt)
	if not self:IsGeneratorPrompt(prompt) then
		return
	end

	if self.FastGeneratorPromptStates[prompt] then
		return
	end

	self.FastGeneratorPromptStates[prompt] = {
		HoldDuration = prompt.HoldDuration,
		MaxActivationDistance = prompt.MaxActivationDistance,
	}

	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 12)

	prompt.Destroying:Connect(function()
		self.FastGeneratorPromptStates[prompt] = nil
	end)
end

function UtilityGUI:EnableFastGeneratorCreation()
	for _, instance in ipairs(workspace:GetDescendants()) do
		if instance:IsA("ProximityPrompt") then
			self:ApplyFastGeneratorPrompt(instance)
		end
	end

	if self.FastGeneratorPromptConnection then
		self.FastGeneratorPromptConnection:Disconnect()
	end

	self.FastGeneratorPromptConnection = workspace.DescendantAdded:Connect(function(instance)
		if instance:IsA("ProximityPrompt") then
			self:ApplyFastGeneratorPrompt(instance)
		end
	end)

	if AdminGUI and AdminGUI.ShowNotification then
		AdminGUI:ShowNotification("Generator build boost aktif (hold dipercepat)", "success")
	end
end

-- ==================== FEATURE 1: CURSOR UNLOCK ====================

function UtilityGUI:ToggleCursor()
	self.CursorEnabled = not self.CursorEnabled
	
	if self.CursorEnabled then
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		print("✓ Cursor Unlocked")
	else
		UserInputService.MouseIconEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		print("✗ Cursor Locked")
	end

	self:NotifyToggle("Cursor Unlock", self.CursorEnabled)
	
	return self.CursorEnabled
end

-- ==================== FEATURE 1.5: CAMERA ZOOM UNLOCK ====================

function UtilityGUI:ApplyCameraZoomSettings()
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = self.CameraMinZoom
	player.CameraMaxZoomDistance = self.CameraMaxZoom
	-- Lock mouse to center so camera rotates by just moving mouse (no right-click hold)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

function UtilityGUI:ToggleCameraZoom()
	self.CameraZoomEnabled = not self.CameraZoomEnabled

	if self.CameraZoomEnabled then
		self.StoredCameraSettings = {
			CameraMode = player.CameraMode,
			MinZoom = player.CameraMinZoomDistance,
			MaxZoom = player.CameraMaxZoomDistance,
		}

		self.StoredMouseSettings = {
			MouseBehavior = UserInputService.MouseBehavior,
			MouseIconEnabled = UserInputService.MouseIconEnabled,
		}

		self:ApplyCameraZoomSettings()

		if self.CameraZoomConnection then
			self.CameraZoomConnection:Disconnect()
		end

		self.CameraZoomConnection = RunService.RenderStepped:Connect(function()
			if not self.CameraZoomEnabled then
				return
			end

			if player.CameraMode ~= Enum.CameraMode.Classic
				or player.CameraMinZoomDistance ~= self.CameraMinZoom
				or player.CameraMaxZoomDistance ~= self.CameraMaxZoom then
				self:ApplyCameraZoomSettings()
			end
		end)

		print("✓ Camera Zoom Enabled - Mouse scroll can change camera distance")
	else
		if self.CameraZoomConnection then
			self.CameraZoomConnection:Disconnect()
			self.CameraZoomConnection = nil
		end

		if self.StoredCameraSettings then
			player.CameraMode = self.StoredCameraSettings.CameraMode
			player.CameraMinZoomDistance = self.StoredCameraSettings.MinZoom
			player.CameraMaxZoomDistance = self.StoredCameraSettings.MaxZoom
		end

		if self.StoredMouseSettings then
			UserInputService.MouseBehavior = self.StoredMouseSettings.MouseBehavior
			UserInputService.MouseIconEnabled = self.StoredMouseSettings.MouseIconEnabled
		end

		print("✗ Camera Zoom Disabled - Original camera and mouse settings restored")
	end

	self:NotifyToggle("Camera Zoom", self.CameraZoomEnabled)

	return self.CameraZoomEnabled
end

-- ==================== FEATURE 1.6: FAST VAULT JUMP ====================

function UtilityGUI:GetLocalHumanoid()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildOfClass("Humanoid")
end

function UtilityGUI:IsNearVaultSurface(humanoid)
	local char = player.Character
	if not char then return false end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = hrp.CFrame.LookVector
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {char}

	local origin = hrp.Position + Vector3.new(0, 2.5, 0)
	local result = workspace:Raycast(origin, direction.Unit * 7, rayParams)
	if not result then
		return false
	end

	local hitYDiff = result.Position.Y - hrp.Position.Y
	return hitYDiff > -2 and hitYDiff < 6
end

function UtilityGUI:ApplyFastVaultBoost(humanoid)
	if self.FastVaultBoostActive then return end
	self.FastVaultBoostActive = true

	local originalJumpPower = humanoid.JumpPower
	local originalJumpHeight = humanoid.JumpHeight
	local usesJumpPower = humanoid.UseJumpPower

	if usesJumpPower then
		humanoid.JumpPower = originalJumpPower * self.FastVaultJumpMultiplier
	else
		humanoid.JumpHeight = originalJumpHeight * self.FastVaultJumpMultiplier
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local adjustedTracks = {}

	local function boostTrack(track)
		if adjustedTracks[track] then return end
		adjustedTracks[track] = true
		pcall(function()
			track:AdjustSpeed(self.FastVaultAnimMultiplier)
		end)
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		boostTrack(track)
	end

	local animationConn
	animationConn = animator.AnimationPlayed:Connect(function(track)
		boostTrack(track)
	end)

	task.delay(self.FastVaultDuration, function()
		if animationConn then
			animationConn:Disconnect()
		end

		for track, _ in pairs(adjustedTracks) do
			pcall(function()
				if track.IsPlaying then
					track:AdjustSpeed(1)
				end
			end)
		end

		if humanoid and humanoid.Parent then
			if usesJumpPower then
				humanoid.JumpPower = originalJumpPower
			else
				humanoid.JumpHeight = originalJumpHeight
			end
		end

		self.FastVaultBoostActive = false
	end)
end

function UtilityGUI:CreateVaultIndicator()
	if self.FastVaultIndicator then return end

	local indicator = Instance.new("Frame")
	indicator.Name = "VaultIndicator"
	indicator.Size = UDim2.new(0, 260, 0, 40)
	indicator.Position = UDim2.new(0.5, -130, 1, -90)
	indicator.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	indicator.BackgroundTransparency = 0.2
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.ZIndex = 15
	indicator.Parent = utilityScreenGui

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(0, 8)
	indCorner.Parent = indicator

	local indStroke = Instance.new("UIStroke")
	indStroke.Color = Color3.fromRGB(255, 210, 0)
	indStroke.Thickness = 1.5
	indStroke.Parent = indicator

	local indLabel = Instance.new("TextLabel")
	indLabel.Name = "Label"
	indLabel.Size = UDim2.new(1, 0, 1, 0)
	indLabel.BackgroundTransparency = 1
	indLabel.Text = "⬆ SPACE — Fast Vault"
	indLabel.TextColor3 = Color3.fromRGB(255, 210, 0)
	indLabel.TextSize = 15
	indLabel.Font = Enum.Font.GothamBold
	indLabel.Parent = indicator

	self.FastVaultIndicator = indicator
end

function UtilityGUI:SetVaultIndicatorVisible(visible)
	if self.FastVaultIndicator then
		self.FastVaultIndicator.Visible = visible
	end
end

function UtilityGUI:IsFastVaultPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end

	if prompt.KeyboardKeyCode == Enum.KeyCode.Space then
		return true
	end

	return hasKeyword(prompt.ActionText, {"vault", "jump", "climb", "mantle", "window"})
		or hasKeyword(prompt.ObjectText, {"vault", "jump", "climb", "mantle", "window"})
end

function UtilityGUI:RefreshFastVaultIndicatorFromPrompts()
	self:SetVaultIndicatorVisible(next(self.FastVaultVisiblePrompts) ~= nil)
end

function UtilityGUI:ToggleFastVault()
	self.FastVaultEnabled = not self.FastVaultEnabled

	if self.FastVaultInputConnection then
		self.FastVaultInputConnection:Disconnect()
		self.FastVaultInputConnection = nil
	end

	if self.FastVaultProximityLoop then
		self.FastVaultProximityLoop:Disconnect()
		self.FastVaultProximityLoop = nil
	end

	if self.FastVaultPromptShownConnection then
		self.FastVaultPromptShownConnection:Disconnect()
		self.FastVaultPromptShownConnection = nil
	end

	if self.FastVaultPromptHiddenConnection then
		self.FastVaultPromptHiddenConnection:Disconnect()
		self.FastVaultPromptHiddenConnection = nil
	end

	if self.FastVaultPromptHoldConnection then
		self.FastVaultPromptHoldConnection:Disconnect()
		self.FastVaultPromptHoldConnection = nil
	end

	table.clear(self.FastVaultVisiblePrompts)

	if self.FastVaultEnabled then
		self:CreateVaultIndicator()
		local proximityPromptService = game:GetService("ProximityPromptService")

		self.FastVaultPromptShownConnection = proximityPromptService.PromptShown:Connect(function(prompt)
			if not self.FastVaultEnabled then return end
			if self:IsFastVaultPrompt(prompt) then
				self.FastVaultVisiblePrompts[prompt] = true
				self:RefreshFastVaultIndicatorFromPrompts()
			end
		end)

		self.FastVaultPromptHiddenConnection = proximityPromptService.PromptHidden:Connect(function(prompt)
			if self.FastVaultVisiblePrompts[prompt] then
				self.FastVaultVisiblePrompts[prompt] = nil
				self:RefreshFastVaultIndicatorFromPrompts()
			end
		end)

		self.FastVaultPromptHoldConnection = proximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
			if not self.FastVaultEnabled then return end
			if not self:IsFastVaultPrompt(prompt) then return end

			local humanoid = self:GetLocalHumanoid()
			if not humanoid then return end
			self:ApplyFastVaultBoost(humanoid)
			print("✓ Fast Vault activated (map prompt)")
		end)

		self.FastVaultInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed or not self.FastVaultEnabled then return end
			if input.KeyCode ~= Enum.KeyCode.Space then return end
			if next(self.FastVaultVisiblePrompts) == nil then return end

			local humanoid = self:GetLocalHumanoid()
			if not humanoid then return end
			self:ApplyFastVaultBoost(humanoid)
			print("✓ Fast Vault activated")
		end)

		print("✓ Fast Vault Enabled — terhubung ke prompt map (SPACE)")
	else
		table.clear(self.FastVaultVisiblePrompts)
		self:SetVaultIndicatorVisible(false)
		print("✗ Fast Vault Disabled")
	end

	self:NotifyToggle("Fast Vault", self.FastVaultEnabled)

	return self.FastVaultEnabled
end

-- ==================== FEATURE 2: ESP WALLHACK ====================

function UtilityGUI:CreateESP(targetPlayer)
	if targetPlayer == player then return end
	
	local char = targetPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	
	-- Remove existing ESP if present
	if self.ESPHighlights[targetPlayer] then
		self.ESPHighlights[targetPlayer]:Destroy()
	end
	if self.ESPNameTags[targetPlayer] then
		self.ESPNameTags[targetPlayer]:Destroy()
	end
	
	-- Create Highlight effect
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char
	
	self.ESPHighlights[targetPlayer] = highlight

	-- Create name tag above head (DisplayName + @Username)
	local nameTag = Instance.new("BillboardGui")
	nameTag.Name = "ESP_NameTag"
	nameTag.Adornee = head
	nameTag.Size = UDim2.new(0, 220, 0, 44)
	nameTag.StudsOffset = Vector3.new(0, 3, 0)
	nameTag.AlwaysOnTop = true
	nameTag.MaxDistance = 2000
	nameTag.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.format("%s\n@%s", targetPlayer.DisplayName, targetPlayer.Name)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = nameTag

	self.ESPNameTags[targetPlayer] = nameTag
end

function UtilityGUI:RemoveESP(targetPlayer)
	if self.ESPHighlights[targetPlayer] then
		self.ESPHighlights[targetPlayer]:Destroy()
		self.ESPHighlights[targetPlayer] = nil
	end

	if self.ESPNameTags[targetPlayer] then
		self.ESPNameTags[targetPlayer]:Destroy()
		self.ESPNameTags[targetPlayer] = nil
	end
end

function UtilityGUI:ToggleESP()
	self.ESPEnabled = not self.ESPEnabled
	
	if self.ESPEnabled then
		self:EnableVaultESP()

		-- Add ESP to all existing players
		for _, plr in pairs(Players:GetPlayers()) do
			if plr.Character then
				self:CreateESP(plr)
			end
		end
		
		-- Monitor for new players
		self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(plr)
			plr.CharacterAdded:Connect(function()
				if self.ESPEnabled then
					wait(0.5)
					self:CreateESP(plr)
				end
			end)
		end)
		
		-- Monitor for character respawns
		self.CharacterAddedConnections = {}
		for _, plr in pairs(Players:GetPlayers()) do
			self.CharacterAddedConnections[plr] = plr.CharacterAdded:Connect(function()
				if self.ESPEnabled then
					wait(0.5)
					self:CreateESP(plr)
				end
			end)
		end
		
		print("✓ ESP Enabled - Players + ALL interactable objects visible")
	else
		self:ClearVaultESP()

		-- Remove all ESP
		for plr, _ in pairs(self.ESPHighlights) do
			self:RemoveESP(plr)
		end
		for plr, _ in pairs(self.ESPNameTags) do
			self:RemoveESP(plr)
		end
		
		-- Disconnect connections
		if self.PlayerAddedConnection then
			self.PlayerAddedConnection:Disconnect()
		end
		
		for _, connection in pairs(self.CharacterAddedConnections or {}) do
			connection:Disconnect()
		end
		self.CharacterAddedConnections = {}
		
		print("✗ ESP Disabled")
	end

	self:NotifyToggle("ESP", self.ESPEnabled)
	
	return self.ESPEnabled
end

-- ==================== FEATURE 2B: PALLET ESP ====================

function UtilityGUI:IsPalletObject(object)
	-- Detect if object is a pallet (simple check)
	if not object or not object:IsA("BasePart") then return false end
	
	local name = object.Name:lower()
	
	-- Simple name check for pallet
	if name:find("pallet") then
		-- Exclude humanoid parents (player characters)
		if object.Parent and object.Parent:FindFirstChildOfClass("Humanoid") then
			return false
		end
		
		-- Exclude if inside humanoid
		local current = object.Parent
		while current do
			if current:FindFirstChildOfClass("Humanoid") then
				return false
			end
			current = current.Parent
		end
		
		return true
	end
	
	return false
end

function UtilityGUI:AddPalletESP(palletObject)
	if self.PalletESPHighlights[palletObject] then return end
	
	-- Create Highlight effect - Orange transparent
	local highlight = Instance.new("Highlight")
	highlight.Name = "Pallet_ESP"
	highlight.Adornee = palletObject
	highlight.FillColor = Color3.fromRGB(255, 140, 0)  -- Orange
	highlight.FillTransparency = 0.5  -- More visible
	highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = workspace  -- Parent to workspace, not object
	
	self.PalletESPHighlights[palletObject] = highlight
end

function UtilityGUI:EnablePalletESP()
	-- Scan workspace for trap pallets
	local palletCount = 0
	local function scanForPallets(parent)
		for _, obj in pairs(parent:GetDescendants()) do
			if self:IsPalletObject(obj) then
				self:AddPalletESP(obj)
				palletCount = palletCount + 1
			end
		end
	end
	
	-- Initial scan
	scanForPallets(workspace)
	
	-- Monitor for new pallets
	if self.PalletESPConnection then
		self.PalletESPConnection:Disconnect()
	end
	
	self.PalletESPConnection = workspace.DescendantAdded:Connect(function(obj)
		if self.PalletESPEnabled and self:IsPalletObject(obj) then
			wait(0.05)  -- Small delay to ensure full object creation
			self:AddPalletESP(obj)
		end
	end)
	
	if palletCount > 0 then
		print("✓ Pallet ESP Enabled - Found " .. palletCount .. " interactive trap pallet(s)")
	else
		print("⚠️ Pallet ESP Enabled - No trap pallets found yet (they may spawn later)")
	end
end

function UtilityGUI:ClearPalletESP()
	-- Remove all pallet highlights
	for palletObj, highlight in pairs(self.PalletESPHighlights) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	table.clear(self.PalletESPHighlights)
	
	-- Disconnect monitoring
	if self.PalletESPConnection then
		self.PalletESPConnection:Disconnect()
		self.PalletESPConnection = nil
	end
	
	print("✗ Pallet ESP Disabled")
end

function UtilityGUI:TogglePalletESP()
	self.PalletESPEnabled = not self.PalletESPEnabled
	
	if self.PalletESPEnabled then
		self:EnablePalletESP()
	else
		self:ClearPalletESP()
	end
	
	self:NotifyToggle("Pallet ESP", self.PalletESPEnabled)
	return self.PalletESPEnabled
end

-- ==================== FEATURE 3: CROSSHAIR AIM ASSIST ====================

function UtilityGUI:CreateCrosshair()
	if self.CrosshairFrame then return end
	
	-- Create crosshair frame
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 200, 0, 300)
	crosshair.Position = UDim2.new(0.5, -100, 0.5, -150)
	crosshair.BackgroundTransparency = 1
	crosshair.ZIndex = 10
	crosshair.Parent = utilityScreenGui
	
	-- Add black outline helper
	local function addOutline(frame)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Thickness = 1.5
		stroke.Parent = frame
	end
	
	-- CENTER CROSSHAIR (0-30 studs)
	-- Horizontal line
	local horizontal = Instance.new("Frame")
	horizontal.Name = "Horizontal"
	horizontal.Size = UDim2.new(0, 30, 0, 2)
	horizontal.Position = UDim2.new(0.5, -15, 0.5, -1)
	horizontal.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	horizontal.BorderSizePixel = 0
	horizontal.Parent = crosshair
	addOutline(horizontal)
	
	-- Vertical line
	local vertical = Instance.new("Frame")
	vertical.Name = "Vertical"
	vertical.Size = UDim2.new(0, 2, 0, 30)
	vertical.Position = UDim2.new(0.5, -1, 0.5, -15)
	vertical.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	vertical.BorderSizePixel = 0
	vertical.Parent = crosshair
	addOutline(vertical)
	
	-- Center dot
	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, 5, 0, 5)
	centerDot.Position = UDim2.new(0.5, -2.5, 0.5, -2.5)
	centerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	centerDot.BorderSizePixel = 0
	centerDot.Parent = crosshair
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = centerDot
	addOutline(centerDot)
	
	-- RANGE MARK 1 (30-60 studs) - Close range
	local mark1 = Instance.new("Frame")
	mark1.Name = "Mark1"
	mark1.Size = UDim2.new(0, 35, 0, 2)
	mark1.Position = UDim2.new(0.5, -17.5, 0.5, 30)
	mark1.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	mark1.BorderSizePixel = 0
	mark1.Parent = crosshair
	addOutline(mark1)
	
	local label1 = Instance.new("TextLabel")
	label1.Size = UDim2.new(0, 40, 0, 15)
	label1.Position = UDim2.new(0.5, 25, 0.5, 25)
	label1.BackgroundTransparency = 1
	label1.Text = "30m"
	label1.TextColor3 = Color3.fromRGB(0, 255, 100)
	label1.TextSize = 12
	label1.Font = Enum.Font.GothamBold
	label1.TextStrokeTransparency = 0.5
	label1.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label1.Parent = crosshair
	
	-- RANGE MARK 2 (60-90 studs) - Medium range
	local mark2 = Instance.new("Frame")
	mark2.Name = "Mark2"
	mark2.Size = UDim2.new(0, 45, 0, 2)
	mark2.Position = UDim2.new(0.5, -22.5, 0.5, 60)
	mark2.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	mark2.BorderSizePixel = 0
	mark2.Parent = crosshair
	addOutline(mark2)
	
	local label2 = Instance.new("TextLabel")
	label2.Size = UDim2.new(0, 40, 0, 15)
	label2.Position = UDim2.new(0.5, 30, 0.5, 55)
	label2.BackgroundTransparency = 1
	label2.Text = "60m"
	label2.TextColor3 = Color3.fromRGB(255, 255, 0)
	label2.TextSize = 12
	label2.Font = Enum.Font.GothamBold
	label2.TextStrokeTransparency = 0.5
	label2.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label2.Parent = crosshair
	
	-- RANGE MARK 3 (90+ studs) - Long range
	local mark3 = Instance.new("Frame")
	mark3.Name = "Mark3"
	mark3.Size = UDim2.new(0, 55, 0, 2)
	mark3.Position = UDim2.new(0.5, -27.5, 0.5, 90)
	mark3.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
	mark3.BorderSizePixel = 0
	mark3.Parent = crosshair
	addOutline(mark3)
	
	local label3 = Instance.new("TextLabel")
	label3.Size = UDim2.new(0, 40, 0, 15)
	label3.Position = UDim2.new(0.5, 35, 0.5, 85)
	label3.BackgroundTransparency = 1
	label3.Text = "90m+"
	label3.TextColor3 = Color3.fromRGB(255, 100, 0)
	label3.TextSize = 12
	label3.Font = Enum.Font.GothamBold
	label3.TextStrokeTransparency = 0.5
	label3.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label3.Parent = crosshair
	
	self.CrosshairFrame = crosshair
end

function UtilityGUI:RemoveCrosshair()
	if self.CrosshairFrame then
		self.CrosshairFrame:Destroy()
		self.CrosshairFrame = nil
	end
end

function UtilityGUI:ToggleCrosshair()
	self.CrosshairEnabled = not self.CrosshairEnabled
	
	if self.CrosshairEnabled then
		self:CreateCrosshair()
		print("✓ Crosshair Enabled - Range Marks: 30m/60m/90m+")
	else
		self:RemoveCrosshair()
		print("✗ Crosshair Disabled")
	end
	
	return self.CrosshairEnabled
end

-- ==================== FEATURE 4: SPEED BOOST ====================

UtilityGUI.ShiftConnection = nil

function UtilityGUI:ToggleSpeed()
	self.SpeedEnabled = not self.SpeedEnabled
	
	if self.SpeedEnabled then
		-- Set speed to 20
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = self.BoostSpeed
			end
		end
		
		-- Simulate holding Shift key continuously
		self.ShiftConnection = RunService.RenderStepped:Connect(function()
			if self.SpeedEnabled then
				-- Continuously press shift
				local VirtualInputManager = game:GetService("VirtualInputManager")
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
				
				-- Also maintain speed at 20
				local char = player.Character
				if char then
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum and hum.WalkSpeed < self.BoostSpeed then
						hum.WalkSpeed = self.BoostSpeed
					end
				end
			end
		end)
		
		print("✓ Speed Boost Enabled: " .. self.BoostSpeed .. " + Auto Shift")
	else
		-- Stop simulating shift
		if self.ShiftConnection then
			self.ShiftConnection:Disconnect()
			self.ShiftConnection = nil
			
			-- Send shift key release
			local VirtualInputManager = game:GetService("VirtualInputManager")
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
		end
		
		-- Reset speed
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = self.DefaultSpeed
			end
		end
		
		print("✗ Speed Boost Disabled")
	end

	self:NotifyToggle("Speed Boost", self.SpeedEnabled)
	
	return self.SpeedEnabled
end

-- Handle character respawn for speed
local utilityRespawnConnection = player.CharacterAdded:Connect(function(char)
	task.wait(0.1)
	
	-- Reapply speed if enabled
	if UtilityGUI.SpeedEnabled then
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.WalkSpeed = UtilityGUI.BoostSpeed
		end
		
		-- Restart shift simulation if needed
		if not UtilityGUI.ShiftConnection then
			UtilityGUI.ShiftConnection = RunService.RenderStepped:Connect(function()
				if UtilityGUI.SpeedEnabled then
					local VirtualInputManager = game:GetService("VirtualInputManager")
					VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
					
					local char = player.Character
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum and hum.WalkSpeed < UtilityGUI.BoostSpeed then
							hum.WalkSpeed = UtilityGUI.BoostSpeed
						end
					end
				end
			end)
		end
	end

	if UtilityGUI.CameraZoomEnabled then
		UtilityGUI:ApplyCameraZoomSettings()
	end
end)

-- ==================== CREATE FEATURE CARDS ====================

local cursorButton = createUtilityCard(
	"🖱️ Cursor Unlock",
	"Unlock mouse cursor (Press K)",
	"K",
	function() return UtilityGUI:ToggleCursor() end
)

local espButton = createUtilityCard(
	"👁️ ESP Wallhack",
	"See all players through walls (Press J)",
	"J",
	function() return UtilityGUI:ToggleESP() end
)

local palletESPButton = createUtilityCard(
	"🪤 Pallet Trap Detection",
	"Highlight trap pallets in orange (Part of J key)",
	"J",
	function() return UtilityGUI:TogglePalletESP() end
)

local crosshairButton = createUtilityCard(
	"🎯 Crosshair Aim",
	"Range marks: 30m/60m/90m+ (Press H)",
	"H",
	function() return UtilityGUI:ToggleCrosshair() end
)

local cameraZoomButton = createUtilityCard(
	"📷 Camera Zoom Unlock",
	"Scroll zoom + free look (no right click) (Press G)",
	"G",
	function() return UtilityGUI:ToggleCameraZoom() end
)

local speedButton = createUtilityCard(
	"⚡ Speed Boost + Shift",
	"Speed 20 + Auto Hold Shift (Press L)",
	"L",
	function() return UtilityGUI:ToggleSpeed() end
)

-- ==================== GUI TOGGLE ====================

local function toggleUtilityGUI()
	utilityMainFrame.Visible = not utilityMainFrame.Visible
	
	if utilityMainFrame.Visible then
		utilityMainFrame.Position = UDim2.new(0.5, -200, 0.3, -150)
		TweenService:Create(utilityMainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, -200, 0.5, -150)
		}):Play()
		
		TweenService:Create(utilityIcon, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 119, 207)
		}):Play()
	else
		TweenService:Create(utilityIcon, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(100, 149, 237)
		}):Play()
	end
end

-- Icon click
utilityIcon.MouseButton1Click:Connect(toggleUtilityGUI)

-- Close button
utilityCloseButton.MouseButton1Click:Connect(function()
	TweenService:Create(utilityMainFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, -200, 0.3, -150)
	}):Play()
	wait(0.2)
	utilityMainFrame.Visible = false
	
	TweenService:Create(utilityIcon, TweenInfo.new(0.2), {
		BackgroundColor3 = Color3.fromRGB(100, 149, 237)
	}):Play()
end)

-- ==================== KEYBOARD SHORTCUTS ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- K = Cursor Toggle
	if input.KeyCode == Enum.KeyCode.K then
		UtilityGUI:ToggleCursor()
		-- Update button visual
		cursorButton.Text = UtilityGUI.CursorEnabled and "ON" or "OFF"
		cursorButton.BackgroundColor3 = UtilityGUI.CursorEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	end
	
	-- J = ESP Toggle (Players + Interactables + Pallets)
	if input.KeyCode == Enum.KeyCode.J then
		UtilityGUI:ToggleESP()
		UtilityGUI:TogglePalletESP()  -- Also toggle pallet ESP
		-- Update button visuals
		espButton.Text = UtilityGUI.ESPEnabled and "ON" or "OFF"
		espButton.BackgroundColor3 = UtilityGUI.ESPEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
		palletESPButton.Text = UtilityGUI.PalletESPEnabled and "ON" or "OFF"
		palletESPButton.BackgroundColor3 = UtilityGUI.PalletESPEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	end
	
	-- H = Crosshair Toggle
	if input.KeyCode == Enum.KeyCode.H then
		UtilityGUI:ToggleCrosshair()
		-- Update button visual
		crosshairButton.Text = UtilityGUI.CrosshairEnabled and "ON" or "OFF"
		crosshairButton.BackgroundColor3 = UtilityGUI.CrosshairEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	end

	-- G = Camera Zoom Toggle
	if input.KeyCode == Enum.KeyCode.G then
		UtilityGUI:ToggleCameraZoom()
		cameraZoomButton.Text = UtilityGUI.CameraZoomEnabled and "ON" or "OFF"
		cameraZoomButton.BackgroundColor3 = UtilityGUI.CameraZoomEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	end
	
	-- L = Speed Toggle
	if input.KeyCode == Enum.KeyCode.L then
		UtilityGUI:ToggleSpeed()
		-- Update button visual
		speedButton.Text = UtilityGUI.SpeedEnabled and "ON" or "OFF"
		speedButton.BackgroundColor3 = UtilityGUI.SpeedEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	end

end)

-- ==================== DRAGGABLE ICON ====================

local utilityDragging = false
local utilityDragStart = nil
local utilityStartPos = nil

utilityIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		utilityDragging = true
		utilityDragStart = input.Position
		utilityStartPos = utilityIcon.Position
	end
end)

utilityIcon.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		utilityDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if utilityDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - utilityDragStart
		utilityIcon.Position = UDim2.new(
			utilityStartPos.X.Scale,
			utilityStartPos.X.Offset + delta.X,
			utilityStartPos.Y.Scale,
			utilityStartPos.Y.Offset + delta.Y
		)
	end
end)

-- ==================== DRAGGABLE MAIN FRAME ====================

local utilityFrameDragging = false
local utilityFrameDragStart = nil
local utilityFrameStartPos = nil

utilityTitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		utilityFrameDragging = true
		utilityFrameDragStart = input.Position
		utilityFrameStartPos = utilityMainFrame.Position
	end
end)

utilityTitleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		utilityFrameDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if utilityFrameDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - utilityFrameDragStart
		utilityMainFrame.Position = UDim2.new(
			utilityFrameStartPos.X.Scale,
			utilityFrameStartPos.X.Offset + delta.X,
			utilityFrameStartPos.Y.Scale,
			utilityFrameStartPos.Y.Offset + delta.Y
		)
	end
end)

print("⚡ Violence District loaded - K (Cursor), J (ESP+E/SPACE/LMB Interactables), H (Crosshair), G (Camera Zoom), L (Speed+Shift)")

-- ============================================
-- INITIALIZATION
-- ============================================
print("✅ Admin Script Loaded Successfully!")
print("👤 Username: " .. player.Name)
print("🔓 Access: PUBLIC (No admin check for executor version)")
AdminGUI:ShowNotification("TwoHand Comunity Admin Script Loaded!\nAll features unlocked!", "success")

print("\n📌 How to use:")
print("   • Click the ⚙️ floating button to open admin panel")
print("   • Click the ⚡ floating button to open Violence District menu")
print("   • Or type commands in chat with prefix: " .. AdminConfig.Prefix)
print("\n⚡ Violence District shortcuts:")
print("   K = Unlock Cursor | J = ESP Wallhack (E/SPACE/LMB) | H = Crosshair | G = Camera Zoom | L = Speed+Shift")
print("\n🔧 Available commands (client-side only):")
print("   ;fly - Toggle flying (WASD + Space + Shift)")
print("   ;speed [number] - Set walk speed")
print("   ;jp [number] - Set jump power")
print("   ;god - Toggle god mode (true invincibility)")
print("   ;goto - Teleport to selected player")
print("   ;reset - Reset character to normal")
print("   ;respawn - Respawn character")
print("   ;antiafk - Toggle anti-AFK")
print("\n💡 UI Features:")
print("   • Toggle buttons show ON/OFF status")
print("   • Select target player for goto command")
print("   • Reset button (top right) for quick reset")
