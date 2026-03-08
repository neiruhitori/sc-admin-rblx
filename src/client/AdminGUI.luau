--[[
	Admin GUI Client
	Modern button-based admin panel with draggable icon
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AdminConfig = require(ReplicatedStorage.Shared.AdminConfig)
local AdminRemote = require(ReplicatedStorage.Shared.AdminRemote)

local AdminGUI = {}
AdminGUI.IsOpen = false
AdminGUI.SelectedPlayer = nil
AdminGUI.CurrentTab = "Admin" -- Track current tab
AdminGUI.StatusRefreshRate = 2 -- Refresh status every 2 seconds
AdminGUI.ButtonStatuses = {} -- Track button status indicators

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- ==================== FLOATING ICON BUTTON ====================
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

-- Icon emoji/text
local iconLabel = Instance.new("TextLabel")
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚙️"
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
mainFrame.Size = UDim2.new(0, 650, 0, 450)
mainFrame.Position = UDim2.new(0.5, -325, 0.5, -225)
mainFrame.BackgroundColor3 = AdminConfig.Theme.Primary
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
titleBar.BackgroundColor3 = AdminConfig.Theme.Secondary
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Fix corner at bottom
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = AdminConfig.Theme.Secondary
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

-- Title text
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚙️ Admin Panel"
titleLabel.TextColor3 = AdminConfig.Theme.Text
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close button
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

-- ==================== PLAYER SELECTOR ====================
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

-- Player dropdown button
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

-- Dropdown arrow
local dropdownArrow = Instance.new("TextLabel")
dropdownArrow.Size = UDim2.new(0, 30, 1, 0)
dropdownArrow.Position = UDim2.new(1, -30, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Text = "▼"
dropdownArrow.TextColor3 = AdminConfig.Theme.Text
dropdownArrow.TextSize = 12
dropdownArrow.Font = Enum.Font.GothamBold
dropdownArrow.Parent = playerDropdown

-- Refresh button
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
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- ==================== PLAYER LIST DROPDOWN ====================
local playerListFrame = Instance.new("ScrollingFrame")
playerListFrame.Name = "PlayerListFrame"
playerListFrame.Size = UDim2.new(0, 0, 0, 0)
playerListFrame.Position = UDim2.new(0, 115, 0, 160)
playerListFrame.BackgroundColor3 = AdminConfig.Theme.Secondary
playerListFrame.BorderSizePixel = 0
playerListFrame.Visible = false
playerListFrame.ScrollBarThickness = 4
playerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListFrame.ClipsDescendants = true
playerListFrame.Parent = mainFrame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = playerListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.Name
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = playerListFrame

-- ==================== COMMANDS CONTAINER ====================
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

-- Helper function to create category section
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
	
	-- Category title
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
	
	-- Buttons container
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

-- Helper function to create command button
local function createCommandButton(parent, text, icon, command, order)
	local button = Instance.new("TextButton")
	button.Name = command
	button.BackgroundColor3 = AdminConfig.Theme.Primary
	button.BorderSizePixel = 0
	button.Text = ""
	button.TextColor3 = AdminConfig.Theme.Text
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Parent = parent
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button
	
	-- Status badge indicator
	local statusBadge = Instance.new("Frame")
	statusBadge.Name = "StatusBadge"
	statusBadge.Size = UDim2.new(0, 8, 0, 8)
	statusBadge.Position = UDim2.new(0, 5, 0, 5)
	statusBadge.BackgroundColor3 = AdminConfig.Theme.Success
	statusBadge.BorderSizePixel = 0
	statusBadge.Visible = false
	statusBadge.ZIndex = 2
	statusBadge.Parent = button
	
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = statusBadge
	
	local buttonLabel = Instance.new("TextLabel")
	buttonLabel.Size = UDim2.new(1, -10, 1, 0)
	buttonLabel.Position = UDim2.new(0, 10, 0, 0)
	buttonLabel.BackgroundTransparency = 1
	buttonLabel.Text = icon .. " " .. text
	buttonLabel.TextColor3 = AdminConfig.Theme.Text
	buttonLabel.TextSize = 13
	buttonLabel.Font = Enum.Font.GothamBold
	buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
	buttonLabel.Parent = button
	
	-- Store reference for status updates
	AdminGUI.ButtonStatuses[command] = statusBadge
	
	return button
end

-- Create categories and buttons
local playerControlButtons = createCategory("👥 Player Control", 1)
createCommandButton(playerControlButtons, "Kill", "💀", "kill", 1)
createCommandButton(playerControlButtons, "Kick", "🚪", "kick", 2)
createCommandButton(playerControlButtons, "Respawn", "🔄", "respawn", 3)
createCommandButton(playerControlButtons, "Freeze", "🧊", "freeze", 4)
createCommandButton(playerControlButtons, "Unfreeze", "🔥", "unfreeze", 5)

local teleportButtons = createCategory("🌐 Teleport", 2)
createCommandButton(teleportButtons, "TP to Player", "📍", "tp", 1)
createCommandButton(teleportButtons, "Goto Player", "🎯", "goto", 2)

local characterButtons = createCategory("⚡ Character Mods", 3)
createCommandButton(characterButtons, "Speed", "🏃", "speed", 1)
createCommandButton(characterButtons, "Jump Power", "🦘", "jp", 2)
createCommandButton(characterButtons, "God Mode [OFF]", "🛡️", "god", 3)

local flyButtons = createCategory("✈️ Flying", 4)
createCommandButton(flyButtons, "Fly [OFF]", "🚀", "fly", 1)
createCommandButton(flyButtons, "Fly Speed", "⚡", "flyspeed", 2)

local otherButtons = createCategory("📢 Other", 5)
createCommandButton(otherButtons, "Announce", "📣", "announce", 1)
createCommandButton(otherButtons, "Anti-AFK [OFF]", "⏰", "antiafk", 2)

-- ==================== NOTIFICATION FRAME ====================
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

-- ==================== FUNCTIONS ====================

-- Show notification
function AdminGUI:ShowNotification(message: string, notifType: string?)
	local color = AdminConfig.Theme.Primary
	
	if notifType == "success" then
		color = AdminConfig.Theme.Success
	elseif notifType == "error" then
		color = AdminConfig.Theme.Error
	elseif notifType == "announce" then
		color = AdminConfig.Theme.Accent
	end
	
	notificationFrame.BackgroundColor3 = color
	notificationText.Text = message
	notificationFrame.Visible = true
	
	-- Slide in
	notificationFrame.Position = UDim2.new(1, 0, 0, 10)
	local slideIn = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -310, 0, 10)}
	)
	slideIn:Play()
	
	-- Auto hide
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

-- Toggle main panel
function AdminGUI:TogglePanel()
	self.IsOpen = not self.IsOpen
	mainFrame.Visible = self.IsOpen
	playerListFrame.Visible = false
	
	if self.IsOpen then
		-- Animate in
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

-- Update player list
function AdminGUI:UpdatePlayerList()
	-- Clear current list
	for _, child in ipairs(playerListFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Add "Me (Self)" option
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
	
	-- Add all players
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
		
		-- Hover effect
		playerButton.MouseEnter:Connect(function()
			playerButton.BackgroundColor3 = AdminConfig.Theme.Accent
		end)
		playerButton.MouseLeave:Connect(function()
			playerButton.BackgroundColor3 = AdminConfig.Theme.Primary
		end)
	end
end

-- Execute command
function AdminGUI:ExecuteCommand(command: string, requiresPlayer: boolean, requiresInput: boolean)
	local commandText = AdminConfig.Prefix .. command
	
	-- Check if command requires player target
	if requiresPlayer then
		if not self.SelectedPlayer then
			self:ShowNotification("Please select a target player first!", "error")
			return
		end
		commandText = commandText .. " " .. self.SelectedPlayer
	end
	
	-- Check if command requires additional input (speed, jp, announce, flyspeed, etc.)
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
		elseif command == "announce" then
			local msg = self:ShowInputDialog("Enter announcement message")
			if not msg then return end
			commandText = commandText .. " " .. msg
		end
	end
	
	-- Fire command to server
	AdminRemote.ExecuteCommand:FireServer(commandText)
end

-- ==================== INPUT DIALOG ====================
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

-- Show input dialog
local dialogResult = nil
local dialogWaiting = false

function AdminGUI:ShowInputDialog(promptText: string): string?
	dialogTitle.Text = promptText
	dialogInput.Text = ""
	inputDialog.Visible = true
	dialogInput:CaptureFocus()
	dialogResult = nil
	dialogWaiting = true
	
	-- Wait for user input
	while dialogWaiting do
		task.wait()
	end
	
	return dialogResult
end

-- Dialog OK button
dialogOK.MouseButton1Click:Connect(function()
	if dialogInput.Text ~= "" then
		dialogResult = dialogInput.Text
	end
	dialogWaiting = false
	inputDialog.Visible = false
end)

-- Dialog Cancel button
dialogCancel.MouseButton1Click:Connect(function()
	dialogResult = nil
	dialogWaiting = false
	inputDialog.Visible = false
end)

-- Dialog Enter key
dialogInput.FocusLost:Connect(function(enterPressed)
	if enterPressed and inputDialog.Visible then
		if dialogInput.Text ~= "" then
			dialogResult = dialogInput.Text
		end
		dialogWaiting = false
		inputDialog.Visible = false
	end
end)

-- ==================== EVENT CONNECTIONS ====================

-- Floating icon click
floatingIcon.MouseButton1Click:Connect(function()
	AdminGUI:TogglePanel()
end)

-- Floating icon drag
local iconDragging = false
local iconDragStart
local iconStartPos
local dragOffset

floatingIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		iconDragStart = input.Position
		iconStartPos = floatingIcon.AbsolutePosition
		-- Calculate offset from cursor to icon corner
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
		
		local newX = input.Position.X + dragOffset.X
		local newY = input.Position.Y + dragOffset.Y
		
		-- Clamp to screen bounds
		newX = math.clamp(newX, 0, viewport.X - 60)
		newY = math.clamp(newY, 0, viewport.Y - 60)
		
		floatingIcon.Position = UDim2.new(0, newX, 0, newY)
	end
end)

-- Close button
closeButton.MouseButton1Click:Connect(function()
	AdminGUI:TogglePanel()
end)

-- Player dropdown
playerDropdown.MouseButton1Click:Connect(function()
	playerListFrame.Visible = not playerListFrame.Visible
	
	if playerListFrame.Visible then
		AdminGUI:UpdatePlayerList()
		-- Animate dropdown
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

-- Refresh button
refreshButton.MouseButton1Click:Connect(function()
	AdminGUI:UpdatePlayerList()
	AdminGUI:ShowNotification("Player list refreshed!", "success")
end)

-- Reset button
resetButton.MouseButton1Click:Connect(function()
	AdminRemote.ExecuteCommand:FireServer(AdminConfig.Prefix .. "reset")
end)

-- Handle notifications from server
AdminRemote.Notify.OnClientEvent:Connect(function(message, notifType)
	AdminGUI:ShowNotification(message, notifType)
end)

-- Connect all command buttons
local function connectCommandButton(buttonName, command, requiresPlayer, requiresInput)
	-- Find button in any category
	for _, category in ipairs(commandsContainer:GetChildren()) do
		if category:IsA("Frame") then
			local buttonsFrame = category:FindFirstChild("Buttons")
			if buttonsFrame then
				local button = buttonsFrame:FindFirstChild(buttonName)
				if button and button:IsA("TextButton") then
					button.MouseButton1Click:Connect(function()
						AdminGUI:ExecuteCommand(command, requiresPlayer, requiresInput)
					end)
					
					-- Hover effect
					button.MouseEnter:Connect(function()
						TweenService:Create(
							button,
							TweenInfo.new(0.2),
							{BackgroundColor3 = AdminConfig.Theme.Accent}
						):Play()
					end)
					button.MouseLeave:Connect(function()
						TweenService:Create(
							button,
							TweenInfo.new(0.2),
							{BackgroundColor3 = AdminConfig.Theme.Primary}
						):Play()
					end)
					break
				end
			end
		end
	end
end

-- Connect all commands (command, requiresPlayer, requiresInput)
connectCommandButton("kill", "kill", true, false)
connectCommandButton("kick", "kick", true, false)
connectCommandButton("respawn", "respawn", false, false)
connectCommandButton("freeze", "freeze", true, false)
connectCommandButton("unfreeze", "unfreeze", true, false)
connectCommandButton("tp", "tp", true, false)
connectCommandButton("goto", "goto", true, false)
connectCommandButton("speed", "speed", false, true)
connectCommandButton("jp", "jp", false, true)
connectCommandButton("god", "god", false, false)
connectCommandButton("fly", "fly", false, false)
connectCommandButton("flyspeed", "flyspeed", false, true)
connectCommandButton("antiafk", "antiafk", false, false)
connectCommandButton("announce", "announce", false, true)

-- Hover effects for UI buttons
local function addButtonHover(button: TextButton, hoverColor: Color3?)
	local originalColor = button.BackgroundColor3
	button.MouseEnter:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.2),
			{BackgroundColor3 = hoverColor or Color3.fromRGB(
				math.min(originalColor.R * 255 + 30, 255) / 255,
				math.min(originalColor.G * 255 + 30, 255) / 255,
				math.min(originalColor.B * 255 + 30, 255) / 255
			)}
		):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.2),
			{BackgroundColor3 = originalColor}
		):Play()
	end)
end

addButtonHover(closeButton)
addButtonHover(refreshButton)
addButtonHover(resetButton)
addButtonHover(floatingIcon)
addButtonHover(dialogOK)
addButtonHover(dialogCancel)

-- Make title bar draggable
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

-- Close dropdown when clicking outside
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if playerListFrame.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			local dropdownPos = playerDropdown.AbsolutePosition
			local dropdownSize = playerDropdown.AbsoluteSize
			local listPos = playerListFrame.AbsolutePosition
			local listSize = playerListFrame.AbsoluteSize
			
			-- Check if click is outside dropdown and list
			if not (mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
					mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y) and
			   not (mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
					mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y) then
				playerListFrame.Visible = false
			end
		end
	end
end)

-- Initialize player list
AdminGUI:UpdatePlayerList()

print("🎨 Modern Admin GUI loaded! Click the floating button to open admin panel.")

return AdminGUI
