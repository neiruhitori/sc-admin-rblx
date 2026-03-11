--[[
	Violence District Utility GUI
	Game utility features with keyboard shortcuts
	Features: Cursor Unlock (K), ESP Wallhack (J), Crosshair (H), Speed Boost (L)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local UtilityGUI = {}
UtilityGUI.CursorEnabled = false
UtilityGUI.ESPEnabled = false
UtilityGUI.SpeedEnabled = false
UtilityGUI.CrosshairEnabled = false
UtilityGUI.DefaultSpeed = 16
UtilityGUI.BoostSpeed = 20

-- ESP Highlight storage
UtilityGUI.ESPHighlights = {}

-- Crosshair storage
UtilityGUI.CrosshairFrame = nil

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UtilityGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ==================== FLOATING ICON BUTTON ====================
local floatingIcon = Instance.new("ImageButton")
floatingIcon.Name = "UtilityIcon"
floatingIcon.Size = UDim2.new(0, 60, 0, 60)
floatingIcon.Position = UDim2.new(1, -80, 0.5, 60)
floatingIcon.BackgroundColor3 = Color3.fromRGB(100, 149, 237) -- Cornflower blue
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
iconLabel.Text = "⚡"
iconLabel.TextSize = 32
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Parent = floatingIcon

-- Icon shadow
local iconShadow = Instance.new("ImageLabel")
iconShadow.Name = "Shadow"
iconShadow.BackgroundTransparency = 1
iconShadow.Position = UDim2.new(0, -5, 0, -5)
iconShadow.Size = UDim2.new(1, 10, 1, 10)
iconShadow.ZIndex = 0
iconShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
iconShadow.ImageColor3 = Color3.new(0, 0, 0)
iconShadow.ImageTransparency = 0.7
iconShadow.Parent = floatingIcon

-- ==================== MAIN PANEL ====================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 300)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Create title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Fix corner at bottom
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Violence District"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -45, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
closeButton.BorderSizePixel = 0
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- ==================== CONTENT AREA ====================
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -40, 1, -90)
contentFrame.Position = UDim2.new(0, 20, 0, 70)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 6
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 15)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentFrame

-- ==================== UTILITY FUNCTIONS ====================

-- Create feature card
local function createFeatureCard(title, description, keyBind, status, callback)
	local card = Instance.new("Frame")
	card.Name = title .. "Card"
	card.Size = UDim2.new(1, 0, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	card.BorderSizePixel = 0
	card.Parent = contentFrame
	
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
	statusButton.BackgroundColor3 = status and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
	statusButton.BorderSizePixel = 0
	statusButton.Text = status and "ON" or "OFF"
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
	
	return card, statusButton
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
	
	return self.CursorEnabled
end

-- ==================== FEATURE 2: ESP WALLHACK ====================

function UtilityGUI:CreateESP(player)
	if player == Players.LocalPlayer then return end
	
	local char = player.Character
	if not char then return end
	
	-- Remove existing ESP if present
	if self.ESPHighlights[player] then
		self.ESPHighlights[player]:Destroy()
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
	
	self.ESPHighlights[player] = highlight
end

function UtilityGUI:RemoveESP(player)
	if self.ESPHighlights[player] then
		self.ESPHighlights[player]:Destroy()
		self.ESPHighlights[player] = nil
	end
end

function UtilityGUI:ToggleESP()
	self.ESPEnabled = not self.ESPEnabled
	
	if self.ESPEnabled then
		-- Add ESP to all existing players
		for _, player in pairs(Players:GetPlayers()) do
			if player.Character then
				self:CreateESP(player)
			end
		end
		
		-- Monitor for new players
		self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function()
				if self.ESPEnabled then
					wait(0.5)
					self:CreateESP(player)
				end
			end)
		end)
		
		-- Monitor for character respawns
		self.CharacterAddedConnections = {}
		for _, player in pairs(Players:GetPlayers()) do
			self.CharacterAddedConnections[player] = player.CharacterAdded:Connect(function()
				if self.ESPEnabled then
					wait(0.5)
					self:CreateESP(player)
				end
			end)
		end
		
		print("✓ ESP Enabled - All players visible")
	else
		-- Remove all ESP
		for player, _ in pairs(self.ESPHighlights) do
			self:RemoveESP(player)
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
	
	return self.ESPEnabled
end

-- ==================== FEATURE 3: CROSSHAIR AIM ASSIST ====================

function UtilityGUI:CreateCrosshair()
	if self.CrosshairFrame then return end
	
	-- Create crosshair frame
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 40, 0, 40)
	crosshair.Position = UDim2.new(0.5, -20, 0.5, -20)
	crosshair.BackgroundTransparency = 1
	crosshair.ZIndex = 10
	crosshair.Parent = screenGui
	
	-- Horizontal line
	local horizontal = Instance.new("Frame")
	horizontal.Name = "Horizontal"
	horizontal.Size = UDim2.new(0, 30, 0, 2)
	horizontal.Position = UDim2.new(0.5, -15, 0.5, -1)
	horizontal.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	horizontal.BorderSizePixel = 0
	horizontal.Parent = crosshair
	
	-- Vertical line
	local vertical = Instance.new("Frame")
	vertical.Name = "Vertical"
	vertical.Size = UDim2.new(0, 2, 0, 30)
	vertical.Position = UDim2.new(0.5, -1, 0.5, -15)
	vertical.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	vertical.BorderSizePixel = 0
	vertical.Parent = crosshair
	
	-- Center dot
	local centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, 4, 0, 4)
	centerDot.Position = UDim2.new(0.5, -2, 0.5, -2)
	centerDot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	centerDot.BorderSizePixel = 0
	centerDot.Parent = crosshair
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = centerDot
	
	-- Add black outline for visibility
	local function addOutline(frame)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Thickness = 1
		stroke.Parent = frame
	end
	
	addOutline(horizontal)
	addOutline(vertical)
	addOutline(centerDot)
	
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
		print("✓ Crosshair Enabled")
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
	
	return self.SpeedEnabled
end

-- Handle character respawn for speed
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	
	-- Reapply speed if enabled
	if UtilityGUI.SpeedEnabled then
		wait(0.5)
		humanoid.WalkSpeed = UtilityGUI.BoostSpeed
		
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
end)

-- ==================== CREATE FEATURE CARDS ====================

createFeatureCard(
	"🖱️ Cursor Unlock",
	"Unlock mouse cursor (Press K)",
	"K",
	UtilityGUI.CursorEnabled,
	function() return UtilityGUI:ToggleCursor() end
)

createFeatureCard(
	"👁️ ESP Wallhack",
	"See all players through walls (Press J)",
	"J",
	UtilityGUI.ESPEnabled,
	function() return UtilityGUI:ToggleESP() end
)

createFeatureCard(
	"🎯 Crosshair Aim",
	"Show crosshair for better aim (Press H)",
	"H",
	UtilityGUI.CrosshairEnabled,
	function() return UtilityGUI:ToggleCrosshair() end
)

createFeatureCard(
	"⚡ Speed Boost + Shift",
	"Speed 20 + Auto Hold Shift (Press L)",
	"L",
	UtilityGUI.SpeedEnabled,
	function() return UtilityGUI:ToggleSpeed() end
)

-- ==================== GUI TOGGLE ====================

local function toggleGUI()
	mainFrame.Visible = not mainFrame.Visible
	
	if mainFrame.Visible then
		mainFrame.Position = UDim2.new(0.5, -200, 0.3, -150)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, -200, 0.5, -150)
		}):Play()
		
		TweenService:Create(floatingIcon, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(70, 119, 207)
		}):Play()
	else
		TweenService:Create(floatingIcon, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(100, 149, 237)
		}):Play()
	end
end

-- Icon click
floatingIcon.MouseButton1Click:Connect(toggleGUI)

-- Close button
closeButton.MouseButton1Click:Connect(function()
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0.5, -200, 0.3, -150)
	}):Play()
	wait(0.2)
	mainFrame.Visible = false
	
	TweenService:Create(floatingIcon, TweenInfo.new(0.2), {
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
		local card = contentFrame:FindFirstChild("🖱️ Cursor UnlockCard")
		if card then
			local statusButton = card:FindFirstChild("StatusButton")
			if statusButton then
				statusButton.Text = UtilityGUI.CursorEnabled and "ON" or "OFF"
				statusButton.BackgroundColor3 = UtilityGUI.CursorEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
			end
		end
	end
	
	-- J = ESP Toggle
	if input.KeyCode == Enum.KeyCode.J then
		UtilityGUI:ToggleESP()
		-- Update button visual
		local card = contentFrame:FindFirstChild("👁️ ESP WallhackCard")
		if card then
			local statusButton = card:FindFirstChild("StatusButton")
			if statusButton then
				statusButton.Text = UtilityGUI.ESPEnabled and "ON" or "OFF"
				statusButton.BackgroundColor3 = UtilityGUI.ESPEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
			end
		end
	end
	
	-- H = Crosshair Toggle
	if input.KeyCode == Enum.KeyCode.H then
		UtilityGUI:ToggleCrosshair()
		-- Update button visual
		local card = contentFrame:FindFirstChild("🎯 Crosshair AimCard")
		if card then
			local statusButton = card:FindFirstChild("StatusButton")
			if statusButton then
				statusButton.Text = UtilityGUI.CrosshairEnabled and "ON" or "OFF"
				statusButton.BackgroundColor3 = UtilityGUI.CrosshairEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
			end
		end
	end
	
	-- L = Speed Toggle
	if input.KeyCode == Enum.KeyCode.L then
		UtilityGUI:ToggleSpeed()
		-- Update button visual
		local card = contentFrame:FindFirstChild("⚡ Speed Boost + ShiftCard")
		if card then
			local statusButton = card:FindFirstChild("StatusButton")
			if statusButton then
				statusButton.Text = UtilityGUI.SpeedEnabled and "ON" or "OFF"
				statusButton.BackgroundColor3 = UtilityGUI.SpeedEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
			end
		end
	end
end)

-- ==================== DRAGGABLE ICON ====================

local dragging = false
local dragStart = nil
local startPos = nil

floatingIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = floatingIcon.Position
	end
end)

floatingIcon.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		floatingIcon.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- ==================== DRAGGABLE MAIN FRAME ====================

local frameDragging = false
local frameDragStart = nil
local frameStartPos = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		frameDragging = true
		frameDragStart = input.Position
		frameStartPos = mainFrame.Position
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		frameDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if frameDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - frameDragStart
		mainFrame.Position = UDim2.new(
			frameStartPos.X.Scale,
			frameStartPos.X.Offset + delta.X,
			frameStartPos.Y.Scale,
			frameStartPos.Y.Offset + delta.Y
		)
	end
end)

print("Violence District loaded - K (Cursor), J (ESP), H (Crosshair), L (Speed+Shift)")

return UtilityGUI
