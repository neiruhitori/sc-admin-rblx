--[[
	===============================================
	   VIOLENCE DISTRICT MODULE
	   By: NB - Nobody Comunity
	   
	   Features:
	   - Cursor Unlock (K)
	   - ESP Wallhack (J)
	   - Pallet ESP (J)
	   - Crosshair Aim (H)
	   - Camera Zoom (G)
	   - Speed Boost (L)
	===============================================
]]

-- ============================================
-- VIOLENCE DISTRICT INITIALIZATION
-- ============================================

print("🔧 Loading Violence District module...")

-- Get required services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- UTILITY GUI MODULE
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
UtilityGUI.PotatoModeEnabled = false
UtilityGUI.WaterClearingConnection = nil
UtilityGUI.EffectMonitorConnection = nil
UtilityGUI.LightingMonitorConnection = nil
UtilityGUI.LightingEnforcementConnection = nil
UtilityGUI.EffectPropertyConnections = {}
UtilityGUI.AtmosphereStates = {}
UtilityGUI.StoredLightingSettings = nil

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

-- ==================== NOTIFICATION SYSTEM ====================
local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 300, 0, 60)
notificationFrame.Position = UDim2.new(1, 0, 0, 10)
notificationFrame.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.ZIndex = 300
notificationFrame.Parent = utilityScreenGui

local notificationCorner = Instance.new("UICorner")
notificationCorner.CornerRadius = UDim.new(0, 8)
notificationCorner.Parent = notificationFrame

local notificationText = Instance.new("TextLabel")
notificationText.Name = "NotificationText"
notificationText.Size = UDim2.new(1, -20, 1, -10)
notificationText.Position = UDim2.new(0, 10, 0, 5)
notificationText.BackgroundTransparency = 1
notificationText.Text = ""
notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationText.TextSize = 14
notificationText.Font = Enum.Font.GothamBold
notificationText.TextWrapped = true
notificationText.TextXAlignment = Enum.TextXAlignment.Left
notificationText.TextYAlignment = Enum.TextYAlignment.Center
notificationText.ZIndex = 301
notificationText.Parent = notificationFrame

-- Notification function
function UtilityGUI:ShowNotification(message, notifType)
	print("[VD DEBUG] ShowNotification called with:", message, notifType)
	
	local color = Color3.fromRGB(100, 149, 237) -- Default blue
	
	if notifType == "success" then
		color = Color3.fromRGB(46, 204, 113) -- Green
	elseif notifType == "error" then
		color = Color3.fromRGB(231, 76, 60) -- Red
	elseif notifType == "info" then
		color = Color3.fromRGB(52, 152, 219) -- Blue
	end
	
	notificationFrame.BackgroundColor3 = color
	notificationText.Text = message
	notificationFrame.Visible = true
	
	-- Slide in animation
	notificationFrame.Position = UDim2.new(1, 0, 0, 10)
	local slideIn = TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(1, -310, 0, 10)}
	)
	slideIn:Play()
	
	-- Auto hide after 3 seconds
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
	self:ShowNotification(message, notifType)
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

	self:ShowNotification("Generator build boost aktif (hold dipercepat)", "success")
end

-- ==================== FEATURE 8: POTATO MODE (OPTIMIZER) ====================

local function isCharacterDescendant(instance)
	local model = instance and instance:FindFirstAncestorOfClass("Model")
	return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isPromptRelated(instance)
	if not instance then
		return false
	end

	local function hasPromptDescendant(target)
		return target and target:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil
	end

	if instance:IsA("ProximityPrompt") then
		return true
	end

	if hasPromptDescendant(instance) then
		return true
	end

	local parent = instance.Parent
	if hasPromptDescendant(parent) then
		return true
	end

	local modelAncestor = instance:FindFirstAncestorOfClass("Model")
	if hasPromptDescendant(modelAncestor) then
		return true
	end

	local basePartAncestor = instance:FindFirstAncestorOfClass("BasePart")
	if hasPromptDescendant(basePartAncestor) then
		return true
	end

	if instance:IsA("Highlight") and hasPromptDescendant(instance.Adornee) then
		return true
	end

	if (instance:IsA("Trail") or instance:IsA("Beam")) then
		local attachment0 = instance.Attachment0
		local attachment1 = instance.Attachment1
		if hasPromptDescendant(attachment0 and attachment0.Parent) or hasPromptDescendant(attachment1 and attachment1.Parent) then
			return true
		end
	end

	if instance:IsA("ParticleEmitter") then
		local emitterParent = instance.Parent
		if emitterParent and emitterParent:IsA("Attachment") and hasPromptDescendant(emitterParent.Parent) then
			return true
		end
	end

	return false
end

local function suppressPotatoVisual(self, instance)
	if not instance then
		return 0
	end

	if instance:IsDescendantOf(workspace) and isCharacterDescendant(instance) then
		return 0
	end

	local removedCount = 0

	pcall(function()
		if isPromptRelated(instance) then
			return
		end

		if instance:IsA("ParticleEmitter")
			or instance:IsA("Trail")
			or instance:IsA("Beam")
			or instance:IsA("Fire")
			or instance:IsA("Smoke")
			or instance:IsA("Sparkles")
			or instance:IsA("PointLight")
			or instance:IsA("SpotLight")
			or instance:IsA("SurfaceLight")
			or instance:IsA("Highlight") then
			if instance.Enabled then
				removedCount = 1
			end
			instance.Enabled = false
		elseif instance:IsA("ForceField") then
			instance.Visible = false
		elseif instance:IsA("Atmosphere") then
			if not self.AtmosphereStates[instance] then
				self.AtmosphereStates[instance] = {
					Density = instance.Density,
					Offset = instance.Offset,
					Glare = instance.Glare,
					Haze = instance.Haze,
				}
			end
			if instance.Density ~= 0 or instance.Offset ~= 0 or instance.Glare ~= 0 or instance.Haze ~= 0 then
				removedCount = 1
			end
			instance.Density = 0
			instance.Offset = 0
			instance.Glare = 0
			instance.Haze = 0
		end
	end)

	return removedCount
end

function UtilityGUI:StopEffectMonitoring()
	if self.EffectMonitorConnection then
		self.EffectMonitorConnection:Disconnect()
		self.EffectMonitorConnection = nil
	end

	if self.LightingMonitorConnection then
		self.LightingMonitorConnection:Disconnect()
		self.LightingMonitorConnection = nil
	end

	for instance, connection in pairs(self.EffectPropertyConnections) do
		pcall(function()
			connection:Disconnect()
		end)
		self.EffectPropertyConnections[instance] = nil
	end

	for atmosphere, state in pairs(self.AtmosphereStates) do
		if atmosphere and atmosphere.Parent and state then
			pcall(function()
				atmosphere.Density = state.Density
				atmosphere.Offset = state.Offset
				atmosphere.Glare = state.Glare
				atmosphere.Haze = state.Haze
			end)
		end
		self.AtmosphereStates[atmosphere] = nil
	end
end

function UtilityGUI:WatchPotatoVisual(instance)
	if not instance then
		return 0
	end

	local shouldWatch = instance:IsA("ParticleEmitter")
		or instance:IsA("Trail")
		or instance:IsA("Beam")
		or instance:IsA("Fire")
		or instance:IsA("Smoke")
		or instance:IsA("Sparkles")
		or instance:IsA("PointLight")
		or instance:IsA("SpotLight")
		or instance:IsA("SurfaceLight")
		or instance:IsA("Highlight")
		or instance:IsA("ForceField")
		or instance:IsA("Atmosphere")

	if not shouldWatch then
		return 0
	end

	local removedCount = suppressPotatoVisual(self, instance)

	if not self.EffectPropertyConnections[instance] then
		self.EffectPropertyConnections[instance] = instance.Changed:Connect(function()
			if not self.PotatoModeEnabled then return end
			suppressPotatoVisual(self, instance)
		end)
		instance.Destroying:Connect(function()
			local connection = self.EffectPropertyConnections[instance]
			if connection then
				pcall(function()
					connection:Disconnect()
				end)
				self.EffectPropertyConnections[instance] = nil
			end
			self.AtmosphereStates[instance] = nil
		end)
	end

	return removedCount
end

function UtilityGUI:StartEffectMonitoring()
	self:StopEffectMonitoring()

	local disabledEffects = 0

	for _, instance in ipairs(workspace:GetDescendants()) do
		disabledEffects = disabledEffects + self:WatchPotatoVisual(instance)
	end

	local lighting = game:GetService("Lighting")
	for _, instance in ipairs(lighting:GetDescendants()) do
		disabledEffects = disabledEffects + self:WatchPotatoVisual(instance)
	end

	self.EffectMonitorConnection = workspace.DescendantAdded:Connect(function(instance)
		if not self.PotatoModeEnabled then return end
		self:WatchPotatoVisual(instance)
	end)

	self.LightingMonitorConnection = lighting.DescendantAdded:Connect(function(instance)
		if not self.PotatoModeEnabled then return end
		self:WatchPotatoVisual(instance)
	end)

	return disabledEffects
end

function UtilityGUI:ApplyPotatoLighting()
	local lighting = game:GetService("Lighting")
	if not lighting then return end

	lighting.Ambient = Color3.fromRGB(185, 185, 185)
	lighting.OutdoorAmbient = Color3.fromRGB(210, 210, 210)
	lighting.Brightness = 4
	lighting.ExposureCompensation = 0.5
	lighting.ClockTime = 13.5
	lighting.GlobalShadows = false
	lighting.FogEnd = 100000

	for _, obj in ipairs(lighting:GetChildren()) do
		pcall(function()
			if obj:IsA("Atmosphere") then
				if not self.AtmosphereStates[obj] then
					self.AtmosphereStates[obj] = {
						Density = obj.Density,
						Offset = obj.Offset,
						Glare = obj.Glare,
						Haze = obj.Haze,
					}
				end

				obj.Density = 0
				obj.Offset = 0
				obj.Glare = 0
				obj.Haze = 0
			end
		end)
	end
end

function UtilityGUI:StartLightingEnforcement()
	local lighting = game:GetService("Lighting")
	if not lighting then return end

	if not self.StoredLightingSettings then
		self.StoredLightingSettings = {
			Ambient = lighting.Ambient,
			OutdoorAmbient = lighting.OutdoorAmbient,
			Brightness = lighting.Brightness,
			ExposureCompensation = lighting.ExposureCompensation,
			ClockTime = lighting.ClockTime,
			GlobalShadows = lighting.GlobalShadows,
			FogEnd = lighting.FogEnd,
		}
	end

	if self.LightingEnforcementConnection then
		self.LightingEnforcementConnection:Disconnect()
		self.LightingEnforcementConnection = nil
	end

	self:ApplyPotatoLighting()

	self.LightingEnforcementConnection = RunService.RenderStepped:Connect(function()
		if not self.PotatoModeEnabled then return end
		self:ApplyPotatoLighting()
	end)
	end

function UtilityGUI:TogglePotato()
	self.PotatoModeEnabled = not self.PotatoModeEnabled

	if self.PotatoModeEnabled then
		self:OptimizeAll()
	else
		self:DisablePotato()
	end

	self:NotifyToggle("Potato Mode", self.PotatoModeEnabled)
	return self.PotatoModeEnabled
end

function UtilityGUI:OptimizeAll()
	print("🥔 [POTATO MODE] Activating bright sky mode...")

	if self.WaterClearingConnection then
		self.WaterClearingConnection:Disconnect()
		self.WaterClearingConnection = nil
	end

	self:StopEffectMonitoring()
	self:StartLightingEnforcement()

	print("✅ [POTATO MODE] Bright sky mode active")
	print("   • Atmosphere forced OFF")
	print("   • Sky and lighting forced bright")

	self:ShowNotification("🥔 POTATO MODE ON! Bright sky active", "success")
end

function UtilityGUI:DisablePotato()
	print("💯 [POTATO MODE] Disabling Potato Mode...")
	
	-- Stop water clearing loop
	if self.WaterClearingConnection then
		self.WaterClearingConnection:Disconnect()
		self.WaterClearingConnection = nil
		print("   • Water clearing loop stopped")
	end

	self:StopLightingEnforcement()
	self:StopEffectMonitoring()
	
	print("✅ [POTATO MODE] POTATO MODE DEACTIVATED!")
	print("   • Note: Some changes (materials, shadows) are permanent until respawn")
	
	self:ShowNotification("💯 POTATO MODE OFF (water loop stopped)", "info")
end

-- ==================== FEATURE 9: CROSSHAIR ====================

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
		
		print("✓ ESP Enabled - Players visible through walls")
	else
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
	
	-- Try Highlight first
	local highlight = Instance.new("Highlight")
	highlight.Name = "Pallet_ESP_Highlight"
	highlight.Adornee = palletObject
	highlight.FillColor = Color3.fromRGB(255, 140, 0)  -- Orange
	highlight.FillTransparency = 0.3  -- Very visible
	highlight.OutlineColor = Color3.fromRGB(255, 100, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = palletObject.Parent or workspace
	
	-- Also add BillboardGui marker for absolute visibility
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "Pallet_ESP_Marker"
	billboardGui.Adornee = palletObject
	billboardGui.Size = UDim2.new(4, 0, 4, 0)
	billboardGui.MaxDistance = 500
	billboardGui.StudsOffset = Vector3.new(0, 2, 0)
	billboardGui.Parent = palletObject
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Parent = billboardGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	self.PalletESPHighlights[palletObject] = {highlight = highlight, billboard = billboardGui}
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
			wait(0.05)
			self:AddPalletESP(obj)
		end
	end)
	
	if palletCount > 0 then
		print("✓ Pallet ESP Enabled - Found " .. palletCount .. " pallets (Orange markers visible on screen)")
	else
		print("⚠️ Pallet ESP Enabled - No pallets found in workspace yet")
	end
end

function UtilityGUI:ClearPalletESP()
	-- Remove all pallet highlights
	for palletObj, objects in pairs(self.PalletESPHighlights) do
		if objects.highlight and objects.highlight.Parent then
			pcall(function() objects.highlight:Destroy() end)
		end
		if objects.billboard and objects.billboard.Parent then
			pcall(function() objects.billboard:Destroy() end)
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
	"Highlight trap pallets in orange (button only)",
	"-",
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
	
	-- J = ESP Toggle (Players only)
	if input.KeyCode == Enum.KeyCode.J then
		UtilityGUI:ToggleESP()
		-- Update button visuals
		espButton.Text = UtilityGUI.ESPEnabled and "ON" or "OFF"
		espButton.BackgroundColor3 = UtilityGUI.ESPEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(100, 100, 110)
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
        
        -- N = Potato Mode Toggle
        if input.KeyCode == Enum.KeyCode.N then
                UtilityGUI:TogglePotato()
        end
end)

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

-- ==================== EXPORT MODULE ====================

-- Export to global for access from main script
_G.ViolenceDistrict = UtilityGUI

print("⚡ Violence District loaded - K (Cursor), J (ESP+E/SPACE/LMB Interactables), H (Crosshair), G (Camera Zoom), L (Speed+Shift)")

-- Show success notification
print("[VD DEBUG] About to call ShowNotification...")
print("[VD DEBUG] UtilityGUI type:", type(UtilityGUI))
print("[VD DEBUG] ShowNotification type:", type(UtilityGUI.ShowNotification))

UtilityGUI:ShowNotification("Violence District Module Loaded! All VD features unlocked!", "success")
