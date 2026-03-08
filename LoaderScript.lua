--[[
	===============================================
	   ADMIN SCRIPT LOADER - CLIENT SIDE ONLY
	   By: Mount Skuy Admin System
	   
	   Cara pakai:
	   1. Upload file ini ke GitHub (raw link)
	   2. Di executor, jalankan:
	      loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL"))()
	===============================================
]]

print("🚀 Loading Admin Script...")

-- ============================================
-- CONFIG MODULE
-- ============================================
local AdminConfig = {}

-- GANTI USERNAME KAMU DI SINI!
AdminConfig.Admins = {
	"Danielle_0021", -- Ganti dengan username Roblox kamu
	[8987066648] = true, -- Contoh: [123456789] = true
	-- Atau tambahkan lebih banyak admin:
	-- "Username2",
}

AdminConfig.Prefix = ";"

AdminConfig.Theme = {
	Primary = Color3.fromRGB(45, 45, 45),
	Secondary = Color3.fromRGB(35, 35, 35),
	Accent = Color3.fromRGB(0, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(0, 255, 0),
	Error = Color3.fromRGB(255, 0, 0),
}

function AdminConfig:IsAdmin(player)
	for _, adminName in ipairs(self.Admins) do
		if typeof(adminName) == "string" and player.Name == adminName then
			return true
		end
	end
	
	if self.Admins[player.UserId] then
		return true
	end
	
	return false
end

function AdminConfig:ParseCommand(input)
	if not input:sub(1, #self.Prefix) == self.Prefix then
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
	local hrp = character:WaitForChild("HumanoidRootPart")
	
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
	
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	
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
	
	print("✈️ Flying enabled! Controls: WASD + Space (up) + Shift (down)")
end

function FlyController:StopFlying()
	if not self.Flying then return end
	
	self.Flying = false
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
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
	if gameProcessed then return end
	
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
local CommandExecutor = {}
CommandExecutor.PlayerStatuses = {
	fly = false,
	god = false,
	antiafk = false
}

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
			player.Character.Humanoid.JumpPower = jp
			return true, "Jump power set to " .. jp
		end
		
	elseif command == "god" then
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			if self.PlayerStatuses.god then
				-- Turn off god mode
				player.Character.Humanoid.MaxHealth = 100
				player.Character.Humanoid.Health = 100
				self.PlayerStatuses.god = false
				return true, "God mode disabled"
			else
				-- Turn on god mode
				player.Character.Humanoid.MaxHealth = math.huge
				player.Character.Humanoid.Health = math.huge
				self.PlayerStatuses.god = true
				return true, "God mode enabled"
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
			player.Character.Humanoid.WalkSpeed = 16
			player.Character.Humanoid.JumpPower = 50
			player.Character.Humanoid.MaxHealth = 100
			player.Character.Humanoid.Health = 100
			FlyController:StopFlying()
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
local playerGui = player:WaitForChild("PlayerGui")

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

local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚙️"
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
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚙️ Admin Panel (Client-Side)"
titleLabel.TextColor3 = AdminConfig.Theme.Text
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

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

-- Player Selector
local playerSelectorFrame = Instance.new("Frame")
playerSelectorFrame.Name = "PlayerSelector"
playerSelectorFrame.Size = UDim2.new(1, -30, 0, 45)
playerSelectorFrame.Position = UDim2.new(0, 15, 0, 60)
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
playerListFrame.Position = UDim2.new(0, 115, 0, 110)
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
commandsContainer.Size = UDim2.new(1, -30, 1, -125)
commandsContainer.Position = UDim2.new(0, 15, 0, 115)
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

floatingIcon.MouseButton1Click:Connect(function()
	AdminGUI:TogglePanel()
end)

local iconDragging = false
local iconDragStart
local iconStartPos
local dragOffset -- Offset from click point to icon position

floatingIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		iconDragStart = input.Position
		iconStartPos = floatingIcon.AbsolutePosition
		-- Calculate offset from mouse to icon top-left corner
		dragOffset = Vector2.new(
			iconStartPos.X - iconDragStart.X,
			iconStartPos.Y - iconDragStart.Y
		)
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				iconDragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local viewport = workspace.CurrentCamera.ViewportSize
		
		-- Apply offset so icon follows cursor at click point
		local newX = input.Position.X + dragOffset.X
		local newY = input.Position.Y + dragOffset.Y
		
		newX = math.clamp(newX, 0, viewport.X - 60)
		newY = math.clamp(newY, 0, viewport.Y - 60)
		
		floatingIcon.Position = UDim2.new(0, newX, 0, newY)
	end
end)

closeButton.MouseButton1Click:Connect(function()
	AdminGUI:TogglePanel()
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
-- INITIALIZATION
-- ============================================
print("✅ Admin Script Loaded Successfully!")
print("👤 Username: " .. player.Name)

if AdminConfig:IsAdmin(player) then
	print("✅ You are an ADMIN!")
	AdminGUI:ShowNotification("Admin Script Loaded!\nYou are an admin.", "success")
else
	print("⚠️ You are NOT an admin!")
	AdminGUI:ShowNotification("Admin Script Loaded!\nBut you are not in the admin list.", "error")
end

print("\n📌 How to use:")
print("   • Click the ⚙️ floating button to open admin panel")
print("   • Or type commands in chat with prefix: " .. AdminConfig.Prefix)
print("\n🔧 Available commands (client-side only):")
print("   ;fly - Toggle flying (WASD + Space + Shift)")
print("   ;speed [number] - Set walk speed")
print("   ;jp [number] - Set jump power")
print("   ;god - Toggle god mode")
print("   ;goto - Teleport to selected player")
print("   ;reset - Reset character to normal")
print("   ;respawn - Respawn character")
print("   ;antiafk - Toggle anti-AFK")
print("\n💡 UI Features:")
print("   • Toggle buttons show ON/OFF status")
print("   • Select target player for goto command")
print("   • Reset button (top right) for quick reset")
