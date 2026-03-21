--[[
	===============================================
	   ADMIN SCRIPT LOADER - CLEAN VERSION
	   By: TwoHand Comunity
	   
	   ✅ OPTIMIZED FOR EXECUTOR
	   - Better error handling
	   - Suppress game-level warnings
	   - All features standalone
	   
	   📝 HOW TO USE:
	   1. Copy & Paste entire content to executor
	   2. Or: loadstring(game:HttpGet("RAW_GITHUB_URL"))()
	===============================================
]]

local startTime = tick()

-- Suppress unnecessary game warnings
local originalWarn = warn
warn = function(...)
	local msg = tostring(select(1, ...))
	-- Only show critical errors, not game-internal ones
	if msg:match("CrossExperience") or msg:match("Failed to load") or msg:match("color string") then
		return -- Silently ignore game-level errors
	end
	originalWarn(...)
end

print("🚀 Loading Mount Skuy Admin Script...")

-- ============================================
-- CONFIG MODULE
-- ============================================
local AdminConfig = {}
AdminConfig.Prefix = ";"
AdminConfig.Theme = {
	Primary = Color3.fromRGB(45, 45, 45),
	Secondary = Color3.fromRGB(35, 35, 35),
	Accent = Color3.fromRGB(0, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(0, 255, 0),
	Error = Color3.fromRGB(255, 0, 0),
}

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
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
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
	
	print("✅ Anti-AFK disabled!")
	return false
end

function AntiAFK:Toggle()
	return self.Enabled and self:Disable() or self:Enable()
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
		pcall(function() bodyVelocity:Destroy() end)
		bodyVelocity = nil
	end
	
	if bodyGyro then
		pcall(function() bodyGyro:Destroy() end)
		bodyGyro = nil
	end
	
	if connection then
		pcall(function() connection:Disconnect() end)
		connection = nil
	end
end

local function calculateVelocity()
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame
	
	local moveDirection = Vector3.new(0, 0, 0)
	
	if keysPressed.Forward then moveDirection = moveDirection + cameraCFrame.LookVector end
	if keysPressed.Backward then moveDirection = moveDirection - cameraCFrame.LookVector end
	if keysPressed.Left then moveDirection = moveDirection - cameraCFrame.RightVector end
	if keysPressed.Right then moveDirection = moveDirection + cameraCFrame.RightVector end
	if keysPressed.Up then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
	if keysPressed.Down then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
	
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
	
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)
	
	connection = RunService.Heartbeat:Connect(function()
		if not self.Flying then return end
		if humanoid and humanoid.Parent then
			pcall(function()
				if humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
					humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				end
			end)
		end
		
		local camera = workspace.CurrentCamera
		local velocity = calculateVelocity()
		
		if bodyVelocity then bodyVelocity.Velocity = velocity end
		if bodyGyro then bodyGyro.CFrame = camera.CFrame end
	end)
	
	print("✈️ Flying enabled! (WASD + Space/Shift)")
end

function FlyController:StopFlying()
	if not self.Flying then return end
	self.Flying = false
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				humanoid.PlatformStand = false
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			end)
		end
	end
	
	removeBodyMovers()
	print("🪂 Flying disabled")
end

function FlyController:Toggle()
	return self.Flying and self:StopFlying() or self:StartFlying()
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
-- COMMAND EXECUTOR
-- ============================================
CommandExecutor = {}
CommandExecutor.PlayerStatuses = {
	fly = false,
	god = false,
	antiafk = false
}
CommandExecutor.GodModeConnections = {}

function CommandExecutor:EnableGodMode()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	for _, conn in ipairs(self.GodModeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	self.GodModeConnections = {}
	
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge
	end)
	
	local renderConn = RunService.RenderStepped:Connect(function()
		if self.PlayerStatuses.god and player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health ~= math.huge then
				hum.Health = math.huge
			end
		end
	end)
	table.insert(self.GodModeConnections, renderConn)
	
	local diedConn = humanoid.Died:Connect(function()
		if self.PlayerStatuses.god then
			task.spawn(function()
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					humanoid.Health = math.huge
				end)
			end)
		end
	end)
	table.insert(self.GodModeConnections, diedConn)
	
	self.PlayerStatuses.god = true
	return true
end

function CommandExecutor:DisableGodMode()
	for _, conn in ipairs(self.GodModeConnections) do
		pcall(function() conn:Disconnect() end)
	end
	self.GodModeConnections = {}
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				
				humanoid.MaxHealth = 100
				humanoid.Health = 100
			end)
		end
	end
	
	self.PlayerStatuses.god = false
	return true
end

function CommandExecutor:GetTargetPlayer(targetName)
	if not targetName or targetName == "" or targetName == "me" or targetName == "self" then
		return player
	end
	
	if targetName == "all" then return "all" end
	
	targetName = targetName:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower():sub(1, #targetName) == targetName then
			return plr
		end
	end
	
	return nil
end

function CommandExecutor:Execute(commandText, targetPlayer)
	local command, args = AdminConfig:ParseCommand(commandText)
	if command == "" then return false, "Invalid command" end
	
	if command == "fly" then
		if FlyController.Flying then
			FlyController:StopFlying()
			self.PlayerStatuses.fly = false
			return true, "Flying disabled"
		else
			FlyController:StartFlying()
			self.PlayerStatuses.fly = true
			return true, "Flying enabled"
		end
		
	elseif command == "flyspeed" or command == "fs" then
		local speed = tonumber(args[1]) or 50
		FlyController.Speed = math.clamp(speed, 10, FlyController.MaxSpeed)
		return true, "Fly speed: " .. FlyController.Speed
		
	elseif command == "speed" then
		local speed = tonumber(args[1]) or 16
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = speed
			end
		end)
		return true, "Speed set to " .. speed
		
	elseif command == "jp" or command == "jumppower" then
		local jp = tonumber(args[1]) or 50
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				local humanoid = player.Character.Humanoid
				if humanoid.UseJumpPower then
					humanoid.JumpPower = jp
				else
					humanoid.JumpHeight = jp / 4
				end
			end
		end)
		return true, "Jump power set to " .. jp
		
	elseif command == "god" then
		if self.PlayerStatuses.god then
			self:DisableGodMode()
			return true, "God mode disabled"
		else
			self:EnableGodMode()
			return true, "God mode enabled"
		end
		
	elseif command == "reset" then
		pcall(function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				local humanoid = player.Character.Humanoid
				humanoid.WalkSpeed = 16
				if humanoid.UseJumpPower then
					humanoid.JumpPower = 50
				else
					humanoid.JumpHeight = 7.2
				end
				humanoid.MaxHealth = 100
				humanoid.Health = 100
				FlyController:StopFlying()
				self:DisableGodMode()
				self.PlayerStatuses.fly = false
				self.PlayerStatuses.god = false
			end
		end)
		return true, "Character reset"
		
	elseif command == "respawn" then
		pcall(function()
			if player.Character then
				player.Character:BreakJoints()
			end
		end)
		return true, "Respawning..."
		
	elseif command == "antiafk" then
		local status = AntiAFK:Toggle()
		self.PlayerStatuses.antiafk = status
		return true, status and "Anti-AFK enabled" or "Anti-AFK disabled"
		
	else
		return false, "Unknown command: " .. command
	end
end

-- ============================================
-- ADMIN GUI
-- ============================================
local TweenService = game:GetService("TweenService")

-- Safe PlayerGui loading with timeout
print("⏳ Initializing GUI...")
local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then
	print("❌ ERROR: PlayerGui not found after 5 seconds!")
	return
end

-- Prevent duplicate GUI
if playerGui:FindFirstChild("AdminGUI") then
	playerGui.AdminGUI:Destroy()
end

local AdminGUI = {}
AdminGUI.IsOpen = false
AdminGUI.SelectedPlayer = nil
AdminGUI.ToggleButtons = {}

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

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚙️ Admin Panel"
titleLabel.TextColor3 = AdminConfig.Theme.Text
titleLabel.TextSize = 18
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

-- Commands Container
local commandsContainer = Instance.new("ScrollingFrame")
commandsContainer.Name = "CommandsContainer"
commandsContainer.Size = UDim2.new(1, -30, 1, -80)
commandsContainer.Position = UDim2.new(0, 15, 0, 60)
commandsContainer.BackgroundTransparency = 1
commandsContainer.BorderSizePixel = 0
commandsContainer.ScrollBarThickness = 6
commandsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
commandsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
commandsContainer.Parent = mainFrame

local commandsLayout = Instance.new("UIListLayout")
commandsLayout.SortOrder = Enum.SortOrder.LayoutOrder
commandsLayout.Padding = UDim.new(0, 10)
commandsLayout.Parent = commandsContainer

-- Helper function: Create button
local function createButton(parent, text, icon, command, order)
	local button = Instance.new("TextButton")
	button.Name = command
	button.BackgroundColor3 = AdminConfig.Theme.Secondary
	button.BorderSizePixel = 0
	button.Text = icon .. " " .. text
	button.TextColor3 = AdminConfig.Theme.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = order
	button.Size = UDim2.new(0.5, -8, 0, 40)
	button.Parent = parent
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button
	
	return button
end

-- Category frame
local categoryFrame = Instance.new("Frame")
categoryFrame.Name = "Commands"
categoryFrame.Size = UDim2.new(1, 0, 0, 0)
categoryFrame.AutomaticSize = Enum.AutomaticSize.Y
categoryFrame.BackgroundTransparency = 1
categoryFrame.LayoutOrder = 1
categoryFrame.Parent = commandsContainer

local categoryLayout = Instance.new("UIGridLayout")
categoryLayout.CellSize = UDim2.new(0.5, -8, 0, 40)
categoryLayout.CellPadding = UDim2.new(0, 15, 0, 10)
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
categoryLayout.Parent = categoryFrame

-- Create command buttons
createButton(categoryFrame, "Speed", "🏃", "speed", 1)
createButton(categoryFrame, "Jump", "🦘", "jp", 2)
createButton(categoryFrame, "God", "🛡️", "god", 3)
createButton(categoryFrame, "Fly", "🚀", "fly", 4)
createButton(categoryFrame, "Respawn", "🔄", "respawn", 5)
createButton(categoryFrame, "Anti-AFK", "⏰", "antiafk", 6)

-- Notification
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "Notification"
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
notificationText.Parent = notificationFrame

-- Functions
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
	end)
end

function AdminGUI:TogglePanel()
	self.IsOpen = not self.IsOpen
	mainFrame.Visible = self.IsOpen
	
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

-- Event Connections
floatingIcon.MouseButton1Click:Connect(function()
	pcall(function()
		AdminGUI:TogglePanel()
	end)
end)

closeButton.MouseButton1Click:Connect(function()
	pcall(function()
		AdminGUI:TogglePanel()
	end)
end)

-- Connect command buttons
for _, button in ipairs(categoryFrame:GetChildren()) do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			pcall(function()
				local success, message = CommandExecutor:Execute(AdminConfig.Prefix .. button.Name, player)
				AdminGUI:ShowNotification(message, success and "success" or "error")
			end)
		end)
		
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = AdminConfig.Theme.Accent}):Play()
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = AdminConfig.Theme.Secondary}):Play()
		end)
	end
end

-- Dragging
local isDragging = false
floatingIcon.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = true
		local startPos = floatingIcon.Position
		local startMouse = UserInputService:GetMouseLocation()
		
		local conn
		conn = UserInputService.InputChanged:Connect(function(input2, gp2)
			if input2.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = UserInputService:GetMouseLocation() - startMouse
				floatingIcon.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				conn:Disconnect()
				isDragging = false
			end
		end)
	end
end)

-- Completion
print("✅ Admin Script loaded successfully!")
print("📊 Loading time: " .. string.format("%.2f", tick() - startTime) .. "s")
print("🎮 Commands: ;fly ;speed ;jp ;god ;reset ;respawn ;antiafk")
print("💡 Click the floating icon to open admin panel")
