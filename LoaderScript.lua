--[[
	===============================================
	   ADMIN SCRIPT LOADER - CLIENT SIDE ONLY
	   By: NB - Nobody Comunity
	   Discord: https://discord.gg/xHrJaSgy
	   
	   🔓 PUBLIC ACCESS - No admin check required!
	   Anyone who executes this script gets full access.
	   
	    HOW TO USE:
	   1. Upload this file to GitHub (get raw link)
	   2. In executor, run:
	      loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL"))()
	===============================================
]]

-- Global error tracking
local function safeExecute(func, description)
	local success, err = pcall(func)
	if not success then
		print("❌ ERROR in " .. description .. ": " .. tostring(err))
		warn(description .. " failed: " .. tostring(err))
	end
	return success
end

print("🚀 Loading Admin Script...")
print("📌 VERSION: v4.7 - Potato Mode UI Button!")
print("     ✅ UI button for Potato Mode (no keyboard shortcut)")
print("     ✅ Click ON/OFF in Utility tab")
print("     ✅ Status indicator & visual feedback")

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
	Success = Color3.fromRGB(46, 204, 113),
	Error = Color3.fromRGB(231, 76, 60),
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
local RunService = game:GetService("RunService")

local AntiAFK = {}
AntiAFK.Enabled = false
AntiAFK.IdledConnection = nil
AntiAFK.HeartbeatConnection = nil
AntiAFK.LastActivity = 0
AntiAFK.ActivityInterval = 60 -- Kirim signal setiap 60 detik

function AntiAFK:Enable()
	if self.Enabled then return end

	self.Enabled = true
	self.LastActivity = tick()
	
	local player = game:GetService("Players").LocalPlayer
	
	-- Method 1: Handle Idled event sebagai backup
	self.IdledConnection = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end)
	
	-- Method 2: Proactive loop - kirim signal berkala SEBELUM timeout
	self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		if not self.Enabled then return end
		
		local currentTime = tick()
		
		-- Setiap 60 detik, kirim berbagai signal anti-AFK
		if currentTime - self.LastActivity >= self.ActivityInterval then
			self.LastActivity = currentTime
			
			-- Virtual user input simulation
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
			
			-- Simulate mouse movement
			VirtualUser:Button1Down(Vector2.new(0, 0))
			VirtualUser:Button1Up(Vector2.new(0, 0))
			
			-- Camera jiggle kecil (hampir tidak terlihat)
			local camera = workspace.CurrentCamera
			if camera then
				local currentCFrame = camera.CFrame
				-- Rotate kamera sangat kecil (0.001 radian = ~0.057 derajat)
				camera.CFrame = currentCFrame * CFrame.Angles(0, 0.001, 0)
				wait(0.05)
				camera.CFrame = currentCFrame -- Kembalikan posisi
			end
			
			-- Simulate character movement (sangat kecil, tidak terlihat)
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				
				if humanoid and rootPart and not FlyController.Flying then
					-- Move tiny bit forward lalu backward (net zero movement)
					humanoid:Move(Vector3.new(0, 0, 0.01), false)
					wait(0.01)
					humanoid:Move(Vector3.new(0, 0, -0.01), false)
				end
			end
		end
	end)
	
	print("✅ Anti-AFK enabled! (24/7 Active - Game akan selalu detect kamu online)")
	return true
end


function AntiAFK:Disable()
	if not self.Enabled then return end
	self.Enabled = false
	
	if self.IdledConnection then
		self.IdledConnection:Disconnect()
		self.IdledConnection = nil
	end
	
	if self.HeartbeatConnection then
		self.HeartbeatConnection:Disconnect()
		self.HeartbeatConnection = nil
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
local Optimizer

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
	
	-- Disable infinite jump if active to prevent conflict
	if InfiniteJump and InfiniteJump.Enabled then
		InfiniteJump:Disable()
		if CommandExecutor then
			CommandExecutor.PlayerStatuses.infinitejump = false
		end
		print("⚠️ Infinite Jump disabled (conflict with Fly mode)")
	end
	
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
-- INFINITE JUMP CONTROLLER MODULE
-- ============================================
local InfiniteJump = {}
InfiniteJump.Enabled = false
InfiniteJump.Flying = false
InfiniteJump.Speed = 100  -- Kecepatan terbang ke atas
InfiniteJump.DownSpeed = 50  -- Kecepatan turun
InfiniteJump.BodyVelocity = nil
InfiniteJump.SpacePressed = false
InfiniteJump.InputConnection = nil
InfiniteJump.HeartbeatConnection = nil

local function setupInfiniteJumpBodyMovers(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	
	-- Hapus BodyVelocity yang lama jika ada
	if InfiniteJump.BodyVelocity then
		InfiniteJump.BodyVelocity:Destroy()
	end
	
	InfiniteJump.BodyVelocity = Instance.new("BodyVelocity")
	InfiniteJump.BodyVelocity.MaxForce = Vector3.new(0, 0, 0)
	InfiniteJump.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
	InfiniteJump.BodyVelocity.Parent = hrp
end

local function removeInfiniteJumpBodyMovers()
	if InfiniteJump.BodyVelocity then
		InfiniteJump.BodyVelocity:Destroy()
		InfiniteJump.BodyVelocity = nil
	end
	
	if InfiniteJump.HeartbeatConnection then
		InfiniteJump.HeartbeatConnection:Disconnect()
		InfiniteJump.HeartbeatConnection = nil
	end
end

function InfiniteJump:Enable()
	if self.Enabled then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Disable fly mode if active to prevent conflict
	if FlyController.Flying then
		FlyController:StopFlying()
		if CommandExecutor then
			CommandExecutor.PlayerStatuses.fly = false
		end
		print("⚠️ Fly mode disabled (conflict with Infinite Jump)")
	end
	
	self.Enabled = true
	self.SpacePressed = false
	
	setupInfiniteJumpBodyMovers(character)
	
	-- Monitor Space key press/release
	self.InputConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if not self.Enabled then return end
		
		-- Check if Space is being held
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			self.SpacePressed = true
		else
			self.SpacePressed = false
		end
	end)
	
	-- Also monitor InputBegan/Ended for Space
	local inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then return end
		if not self.Enabled then return end
		
		if input.KeyCode == Enum.KeyCode.Space then
			self.SpacePressed = true
		end
	end)
	
	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if not self.Enabled then return end
		
		if input.KeyCode == Enum.KeyCode.Space then
			self.SpacePressed = false
		end
	end)
	
	-- Store connections for cleanup
	self.ExtraConnections = {inputBeganConn, inputEndedConn}
	
	-- Heartbeat loop untuk apply velocity
	self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		if not self.Enabled then return end
		if not self.BodyVelocity then return end
		
		local character = player.Character
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		
		if self.SpacePressed then
			-- Space ditekan - terbang ke atas
			self.BodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
			self.BodyVelocity.Velocity = Vector3.new(0, self.Speed, 0)
			self.Flying = true
		else
			-- Space dilepas - turun pelan atau biarkan gravity
			if self.Flying then
				-- Baru saja lepas space, turun perlahan
				self.BodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
				self.BodyVelocity.Velocity = Vector3.new(0, -self.DownSpeed, 0)
				
				-- Setelah delay singkat, matikan BodyVelocity biar gravity bekerja
				spawn(function()
					wait(0.5)
					if self.BodyVelocity and not self.SpacePressed then
						self.BodyVelocity.MaxForce = Vector3.new(0, 0, 0)
						self.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
						self.Flying = false
					end
				end)
			end
		end
	end)
	
	print("🚀 Infinite Jump enabled! Hold SPACE to fly up continuously!")
end

function InfiniteJump:Disable()
	if not self.Enabled then return end
	
	self.Enabled = false
	self.SpacePressed = false
	self.Flying = false
	
	if self.InputConnection then
		self.InputConnection:Disconnect()
		self.InputConnection = nil
	end
	
	if self.ExtraConnections then
		for _, conn in ipairs(self.ExtraConnections) do
			conn:Disconnect()
		end
		self.ExtraConnections = nil
	end
	
	removeInfiniteJumpBodyMovers()
	
	print("🪂 Infinite Jump disabled")
end

function InfiniteJump:Toggle()
	if self.Enabled then
		self:Disable()
		return false
	else
		self:Enable()
		return true
	end
end

function InfiniteJump:SetSpeed(speed)
	self.Speed = math.clamp(speed, 50, 300)
	print("🚀 Infinite Jump speed set to " .. self.Speed)
end

-- ============================================
-- NOCLIP CONTROLLER MODULE
-- ============================================
local NoClip = {}
NoClip.Enabled = false
NoClip.SteppedConnection = nil
NoClip.OriginalCollision = {}

function NoClip:Enable()
	if self.Enabled then return end

	local character = player.Character
	if not character then return end

	self.Enabled = true
	self.OriginalCollision = {}

	-- Store original CanCollide values for clean restoration
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			self.OriginalCollision[part] = part.CanCollide
		end
	end

	-- Stepped runs every frame before physics; continuously disabling collision
	-- lets the character pass through walls while the Humanoid's internal
	-- floor-raycast keeps the character standing on surfaces.
	self.SteppedConnection = RunService.Stepped:Connect(function()
		if not self.Enabled then return end
		local char = player.Character
		if not char then return end

		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)

	print("👻 NoClip enabled! Walk through walls (R6/R15 compatible)")
end

function NoClip:Disable()
	if not self.Enabled then return end

	self.Enabled = false

	if self.SteppedConnection then
		self.SteppedConnection:Disconnect()
		self.SteppedConnection = nil
	end

	-- Restore original collision values
	local character = player.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				local original = self.OriginalCollision[part]
				part.CanCollide = (original ~= nil) and original or true
			end
		end
		-- Reset humanoid animation state to fix walk animation after noclip
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			task.defer(function()
				if humanoid and humanoid.Parent then
					humanoid:ChangeState(Enum.HumanoidStateType.Running)
				end
			end)
		end
	end

	self.OriginalCollision = {}
	print("🧱 NoClip disabled! Collision restored.")
end

function NoClip:Toggle()
	if self.Enabled then
		self:Disable()
		return false
	else
		self:Enable()
		return true
	end
end

-- ============================================
-- ESP + PROXIMITY AURA MODULE
-- ============================================
local ESPModule = {}
ESPModule.Enabled = false
ESPModule.PlayerHighlights = {}
ESPModule.PlayerNameTags = {}
ESPModule.ProxHighlights = {}
ESPModule.ProxMarkers = {}
ESPModule.PlayerAddedConn = nil
ESPModule.CharacterAddedConns = {}
ESPModule.ProxWatchConn = nil

function ESPModule:CreatePlayerESP(targetPlayer)
	if targetPlayer == player then return end
	local char = targetPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	-- Remove existing
	if self.PlayerHighlights[targetPlayer] then
		pcall(function() self.PlayerHighlights[targetPlayer]:Destroy() end)
	end
	if self.PlayerNameTags[targetPlayer] then
		pcall(function() self.PlayerNameTags[targetPlayer]:Destroy() end)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = char
	highlight.FillColor = Color3.fromRGB(255, 50, 50)
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(255, 220, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char
	self.PlayerHighlights[targetPlayer] = highlight

	local nameTag = Instance.new("BillboardGui")
	nameTag.Name = "ESP_NameTag"
	nameTag.Adornee = head
	nameTag.Size = UDim2.new(0, 220, 0, 44)
	nameTag.StudsOffset = Vector3.new(0, 3, 0)
	nameTag.AlwaysOnTop = true
	nameTag.MaxDistance = 2000
	nameTag.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.format("%s\n@%s", targetPlayer.DisplayName, targetPlayer.Name)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = nameTag
	self.PlayerNameTags[targetPlayer] = nameTag
end

function ESPModule:RemovePlayerESP(targetPlayer)
	if self.PlayerHighlights[targetPlayer] then
		pcall(function() self.PlayerHighlights[targetPlayer]:Destroy() end)
		self.PlayerHighlights[targetPlayer] = nil
	end
	if self.PlayerNameTags[targetPlayer] then
		pcall(function() self.PlayerNameTags[targetPlayer]:Destroy() end)
		self.PlayerNameTags[targetPlayer] = nil
	end
end

function ESPModule:AddProxESP(instance)
	if not instance or not instance:IsA("ProximityPrompt") then return end
	local adornee = nil
	local parent = instance.Parent
	if parent then
		if parent:IsA("BasePart") or parent:IsA("Model") then
			adornee = parent
		else
			adornee = parent:FindFirstAncestorOfClass("Model")
				or parent:FindFirstAncestorOfClass("BasePart")
		end
	end
	if not adornee then return end
	if self.ProxHighlights[adornee] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ProxESP_Highlight"
	highlight.Adornee = adornee
	highlight.FillColor = Color3.fromRGB(0, 200, 255)
	highlight.FillTransparency = 0.6
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = workspace
	self.ProxHighlights[adornee] = highlight

	local basePart = adornee:IsA("BasePart") and adornee
		or (adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart", true))
	if basePart then
		local bill = Instance.new("BillboardGui")
		bill.Name = "ProxESP_Marker"
		bill.Adornee = basePart
		bill.Size = UDim2.new(0, 80, 0, 24)
		bill.StudsOffset = Vector3.new(0, 2.5, 0)
		bill.AlwaysOnTop = true
		bill.MaxDistance = 300
		bill.Parent = basePart

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		local keyText = "E"
		pcall(function()
			local kc = instance.KeyboardKeyCode
			if kc == Enum.KeyCode.Space then
				keyText = "SPACE"
			elseif instance.ClickablePrompt then
				keyText = "LMB"
			elseif kc ~= Enum.KeyCode.Unknown then
				keyText = kc.Name
			end
		end)
		label.Text = "[" .. keyText .. "]"
		label.TextColor3 = Color3.fromRGB(255, 220, 0)
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.Parent = bill
		self.ProxMarkers[adornee] = bill
	end
end

function ESPModule:ClearProxESP()
	for _, h in pairs(self.ProxHighlights) do
		pcall(function() if h and h.Parent then h:Destroy() end end)
	end
	for _, m in pairs(self.ProxMarkers) do
		pcall(function() if m and m.Parent then m:Destroy() end end)
	end
	table.clear(self.ProxHighlights)
	table.clear(self.ProxMarkers)
	if self.ProxWatchConn then
		self.ProxWatchConn:Disconnect()
		self.ProxWatchConn = nil
	end
end

function ESPModule:EnableProxESP()
	self:ClearProxESP()
	task.spawn(function()
		for _, inst in ipairs(workspace:GetDescendants()) do
			if not self.Enabled then break end
			if inst:IsA("ProximityPrompt") then
				self:AddProxESP(inst)
			end
		end
	end)
	self.ProxWatchConn = workspace.DescendantAdded:Connect(function(inst)
		if not self.Enabled then return end
		if inst:IsA("ProximityPrompt") then
			task.wait(0.05)
			self:AddProxESP(inst)
		end
	end)
end

function ESPModule:Enable()
	if self.Enabled then return end
	self.Enabled = true

	-- Player ESP
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			self:CreatePlayerESP(plr)
		end
		self.CharacterAddedConns[plr] = plr.CharacterAdded:Connect(function()
			if self.Enabled then
				task.wait(0.5)
				self:CreatePlayerESP(plr)
			end
		end)
	end
	self.PlayerAddedConn = Players.PlayerAdded:Connect(function(plr)
		self.CharacterAddedConns[plr] = plr.CharacterAdded:Connect(function()
			if self.Enabled then
				task.wait(0.5)
				self:CreatePlayerESP(plr)
			end
		end)
		if plr.Character then
			self:CreatePlayerESP(plr)
		end
	end)

	-- Proximity Prompt Aura ESP
	self:EnableProxESP()
	print("👁️ ESP + Proximity Aura enabled")
end

function ESPModule:Disable()
	if not self.Enabled then return end
	self.Enabled = false

	-- Remove player ESP
	for plr, _ in pairs(self.PlayerHighlights) do
		self:RemovePlayerESP(plr)
	end
	for plr, _ in pairs(self.PlayerNameTags) do
		self:RemovePlayerESP(plr)
	end

	if self.PlayerAddedConn then
		self.PlayerAddedConn:Disconnect()
		self.PlayerAddedConn = nil
	end
	for _, conn in pairs(self.CharacterAddedConns) do
		pcall(function() conn:Disconnect() end)
	end
	self.CharacterAddedConns = {}

	-- Remove proximity ESP
	self:ClearProxESP()
	print("👁️ ESP + Proximity Aura disabled")
end

function ESPModule:Toggle()
	if self.Enabled then
		self:Disable()
		return false
	else
		self:Enable()
		return true
	end
end

-- ============================================
-- CLIENT-SIDE COMMAND EXECUTOR
-- ============================================
CommandExecutor = {}
CommandExecutor.PlayerStatuses = {
	fly = false,
	infinitejump = false,
	god = false,
	antiafk = false,
	noclip = false,
	potato = false,
	potatodebug = false,
	espprox = false
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
			InfiniteJump:Disable()
			-- Disable god mode properly
			self:DisableGodMode()
			-- Reset all statuses
			self.PlayerStatuses.fly = false
			self.PlayerStatuses.infinitejump = false
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

	elseif command == "noclip" then
		local status = NoClip:Toggle()
		self.PlayerStatuses.noclip = status
		if status then
			return true, "👻 NoClip ON - walk through walls!"
		else
			return true, "🧱 NoClip OFF - collision restored"
		end
	
	elseif command == "infinitejump" or command == "infjump" or command == "ijump" then
		local status = InfiniteJump:Toggle()
		self.PlayerStatuses.infinitejump = status
		if status then
			return true, "Infinite Jump enabled! Hold SPACE to fly up!"
		else
			return true, "Infinite Jump disabled"
		end
	
	elseif command == "ijumpspeed" or command == "infinitejumpspeed" then
		local speed = tonumber(args[1]) or 100
		InfiniteJump:SetSpeed(speed)
		return true, "Infinite Jump speed set to " .. speed

	elseif command == "potatodebug" or command == "pdebug" then
		local optimizerRef = Optimizer or _G.AdminOptimizer
		if not optimizerRef then
			return false, "Optimizer not initialized yet"
		end

		local enabled = optimizerRef:SetRodDebugEnabled(not optimizerRef.RodDebugEnabled)
		self.PlayerStatuses.potatodebug = enabled
		if enabled then
			return true, "Potato rod debug enabled"
		else
			return true, "Potato rod debug disabled"
		end
	
	else
		return false, "Unknown command: " .. command
	end
	
	return false, "Command failed"
end

-- ============================================
-- OPTIMIZER MODULE (POTATO MODE)
-- ============================================
Optimizer = {}
Optimizer.PotatoModeEnabled = false
Optimizer.WaterClearingConnection = nil
Optimizer.EffectMonitorConnection = nil
Optimizer.EffectPropertyConnections = {}
Optimizer.PlayerAddedConnection = nil
Optimizer.PlayerCharacterAddedConnections = {}
Optimizer.ActiveCharacterMonitorConnections = {}
Optimizer.CharacterEffectPropertyConnections = {}
Optimizer.RodDebugEnabled = false
Optimizer.RodDebugSeenPaths = {}
Optimizer.RodDebugLogCount = 0
Optimizer.RodDebugLogLimit = 60
_G.AdminOptimizer = Optimizer

-- TARUH DI SINI
local Players = game:GetService("Players")

local function isCharacterDescendant(instance)
	local model = instance and instance:FindFirstAncestorOfClass("Model")
	return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local rodEffectKeywords = {
	"rod",
	"reel",
	"line",
	"bobber",
	"lure",
	"bait",
	"hook",
	"cast",
	"fishing",
	"vfx",
	"fx",
	"trail",
	"splash",
	"ripple",
	"waterfx",
}

local function stringContainsAnyKeyword(text, keywords)
	if not text or text == "" then
		return false
	end

	local lowerText = text:lower()
	for _, keyword in ipairs(keywords) do
		if lowerText:find(keyword, 1, true) then
			return true
		end
	end

	return false
end

local function getInstanceDebugPath(instance)
	local pathParts = {}
	local current = instance

	while current and current ~= game do
		table.insert(pathParts, 1, current.Name)
		current = current.Parent
	end

	return table.concat(pathParts, "/")
end

local function isKnownRodWorldAsset(instance)
	if not instance or isCharacterDescendant(instance) then
		return false
	end

	local instancePath = getInstanceDebugPath(instance):lower()
	if not instancePath:find("workspace/islands/", 1, true) then
		return false
	end

	return instancePath:find("/roddisplay", 1, true)
		or instancePath:find("/rod store", 1, true)
		or instancePath:find("/bobber store", 1, true)
		or instancePath:find("defaultrod", 1, true)
		or instancePath:find("/vfx", 1, true)
		or instancePath:find("/manifest", 1, true)
		or instancePath:find("/lucky rod", 1, true)
		or instancePath:find("/carbon rod", 1, true)
end

local function isKnownCosmeticRespawnAsset(instance)
	if not instance then
		return false
	end

	local instancePath = getInstanceDebugPath(instance):lower()

	return instancePath:find("workspace/cosmeticfolder/", 1, true)
		or instancePath:find("workspace/characters/", 1, true)
		or instancePath:find("!!equipped tool!!", 1, true)
		or instancePath:find("/manifest/", 1, true)
		or instancePath:find("fishingtiercolor", 1, true)
		or instancePath:find("workspace/lighting/", 1, true)
		or instancePath:find("lighting vfx", 1, true)
		or instancePath:find("pulse ripple", 1, true)
		or instancePath:find("outline", 1, true)
		or instancePath:find("smoketrail", 1, true)
		or instancePath:find("wind lines", 1, true)
end

local function isPersistentCosmeticRoot(instance)
	if not instance then
		return false
	end

	local instancePath = getInstanceDebugPath(instance):lower()

	return instancePath == "workspace/cosmeticfolder"
		or instancePath == "workspace/characters"
		or instancePath == "workspace/lighting"
		or instancePath == "workspace/camera"
		or instancePath:find("!!equipped_tool!!", 1, true)
		or instancePath:find("workspace/cosmeticfolder/", 1, true)
end

local function shouldSweepPersistentDescendant(instance)
	if not instance or not isVisualRodInstance(instance) then
		return false
	end

	return isKnownCosmeticRespawnAsset(instance)
		or isLikelyRodEffectInstance(instance)
		or isKnownRodWorldAsset(instance)
end

local function isLikelyRodEffectInstance(instance)
	if not instance then
		return false
	end

	if isKnownCosmeticRespawnAsset(instance) then
		return true
	end

	local current = instance
	local depth = 0

	while current and current ~= game and depth < 8 do
		if stringContainsAnyKeyword(current.Name, rodEffectKeywords) then
			return true
		end
		current = current.Parent
		depth += 1
	end

	return false
end

local function isVisualRodInstance(instance)
	if not instance then
		return false
	end

	return instance:IsA("BasePart")
		or instance:IsA("ParticleEmitter")
		or instance:IsA("Trail")
		or instance:IsA("Beam")
		or instance:IsA("RopeConstraint")
		or instance:IsA("Fire")
		or instance:IsA("Smoke")
		or instance:IsA("Sparkles")
		or instance:IsA("PointLight")
		or instance:IsA("SpotLight")
		or instance:IsA("SurfaceLight")
		or instance:IsA("Highlight")
		or instance:IsA("BillboardGui")
		or instance:IsA("SurfaceGui")
		or instance:IsA("SelectionBox")
		or instance:IsA("BoxHandleAdornment")
		or instance:IsA("SphereHandleAdornment")
		or instance:IsA("CylinderHandleAdornment")
		or instance:IsA("ConeHandleAdornment")
		or instance:IsA("ForceField")
		or instance:IsA("Decal")
		or instance:IsA("Texture")
		or instance:IsA("SurfaceAppearance")
		or instance:IsA("SpecialMesh")
		or instance:IsA("MeshPart")
end

local function shouldDebugRodInstance(instance)
	if not isLikelyRodEffectInstance(instance) then
		return false
	end

	if not isVisualRodInstance(instance) then
		return false
	end

	if isKnownRodWorldAsset(instance) and (instance:IsA("Model") or instance:IsA("Folder")) then
		return false
	end

	return true
end

function Optimizer:DebugRodInstance(instance, source)
	if not self.RodDebugEnabled or not instance then
		return
	end

	if not shouldDebugRodInstance(instance) then
		return
	end

	local instancePath = getInstanceDebugPath(instance)
	if self.RodDebugSeenPaths[instancePath] then
		return
	end

	if self.RodDebugLogCount >= self.RodDebugLogLimit then
		return
	end

	self.RodDebugSeenPaths[instancePath] = true
	self.RodDebugLogCount += 1
	print("[POTATO DEBUG][" .. source .. "] " .. instance.ClassName .. " -> " .. instancePath)

	if self.RodDebugLogCount == self.RodDebugLogLimit then
		warn("[POTATO DEBUG] Log limit reached. Toggle ;potatodebug again to reset logs.")
	end
end

function Optimizer:SetRodDebugEnabled(enabled)
	self.RodDebugEnabled = enabled == true
	self.RodDebugSeenPaths = {}
	self.RodDebugLogCount = 0

	if self.RodDebugEnabled then
		print("[POTATO DEBUG] Rod/effect debug enabled. New suspicious objects will be logged.")
	else
		print("[POTATO DEBUG] Rod/effect debug disabled.")
	end

	return self.RodDebugEnabled
end

local function suppressMapVisual(instance)
	if not Optimizer.PotatoModeEnabled or not instance or isCharacterDescendant(instance) then
		return 0
	end

	local removedCount = 0

	pcall(function()
		if instance:IsA("ParticleEmitter")
			or instance:IsA("Trail")
			or instance:IsA("Beam")
			or instance:IsA("RopeConstraint")
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
		elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
			if instance.Enabled then
				removedCount = 1
			end
			instance.Enabled = false
		elseif instance:IsA("SelectionBox")
			or instance:IsA("BoxHandleAdornment")
			or instance:IsA("SphereHandleAdornment")
			or instance:IsA("CylinderHandleAdornment")
			or instance:IsA("ConeHandleAdornment") then
			if instance.Visible then
				removedCount = 1
			end
			instance.Visible = false
		elseif instance:IsA("ForceField") then
			instance.Visible = false
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			if instance.Transparency < 1 then
				removedCount = 1
			end
			instance.Transparency = 1
		elseif instance:IsA("SurfaceAppearance") then
			if not (isKnownRodWorldAsset(instance) or isKnownCosmeticRespawnAsset(instance) or isLikelyRodEffectInstance(instance)) then
				removedCount = 1
				instance:Destroy()
			end
		elseif instance:IsA("SpecialMesh") then
			if instance.TextureId ~= "" and not (isKnownRodWorldAsset(instance) or isKnownCosmeticRespawnAsset(instance) or isLikelyRodEffectInstance(instance)) then
				removedCount = 1
				instance.TextureId = ""
			end
		elseif instance:IsA("MeshPart") then
			if instance.TextureID ~= "" and not (isKnownRodWorldAsset(instance) or isKnownCosmeticRespawnAsset(instance) or isLikelyRodEffectInstance(instance)) then
				removedCount = 1
				instance.TextureID = ""
			end
		end
	end)

	return removedCount
end

function Optimizer:StopEffectMonitoring()
	if self.EffectMonitorConnection then
		self.EffectMonitorConnection:Disconnect()
		self.EffectMonitorConnection = nil
	end

	for instance, connection in pairs(self.EffectPropertyConnections or {}) do
		pcall(function()
			connection:Disconnect()
		end)
		self.EffectPropertyConnections[instance] = nil
	end
end

function Optimizer:WatchMapVisual(instance)
	if not instance or isCharacterDescendant(instance) then
		return 0
	end

	local propertyName = nil
	local needsRodWatcher = isLikelyRodEffectInstance(instance)
	if needsRodWatcher then
		self:DebugRodInstance(instance, "workspace")
	end

	if instance:IsA("ParticleEmitter")
		or instance:IsA("Trail")
		or instance:IsA("Beam")
		or instance:IsA("RopeConstraint")
		or instance:IsA("Fire")
		or instance:IsA("Smoke")
		or instance:IsA("Sparkles")
		or instance:IsA("PointLight")
		or instance:IsA("SpotLight")
		or instance:IsA("SurfaceLight")
		or instance:IsA("Highlight") then
		propertyName = "Enabled"
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		propertyName = "Enabled"
	elseif instance:IsA("SelectionBox")
		or instance:IsA("BoxHandleAdornment")
		or instance:IsA("SphereHandleAdornment")
		or instance:IsA("CylinderHandleAdornment")
		or instance:IsA("ConeHandleAdornment") then
		propertyName = "Visible"
	elseif instance:IsA("ForceField") then
		propertyName = "Visible"
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		propertyName = "Transparency"
	elseif instance:IsA("SpecialMesh") then
		propertyName = "TextureId"
	elseif instance:IsA("MeshPart") then
		propertyName = "TextureID"
	end

	local removedCount = suppressMapVisual(instance)

	if propertyName and not self.EffectPropertyConnections[instance] then
		self.EffectPropertyConnections[instance] = instance:GetPropertyChangedSignal(propertyName):Connect(function()
			if not self.PotatoModeEnabled then return end
			suppressMapVisual(instance)
		end)
	end

	return removedCount
end

function Optimizer:StartEffectMonitoring()
	self:StopEffectMonitoring()

	local disabledEffects = 0
	for _, instance in ipairs(workspace:GetDescendants()) do
		disabledEffects += self:WatchMapVisual(instance)
	end

	self.EffectMonitorConnection = workspace.DescendantAdded:Connect(function(instance)
		if not self.PotatoModeEnabled then return end
		self:WatchMapVisual(instance)
	end)

	return disabledEffects
end

function Optimizer:StopCharacterMonitoring()
	if self.PlayerAddedConnection then
		self.PlayerAddedConnection:Disconnect()
		self.PlayerAddedConnection = nil
	end

	for playerRef, connection in pairs(self.PlayerCharacterAddedConnections) do
		pcall(function()
			connection:Disconnect()
		end)
		self.PlayerCharacterAddedConnections[playerRef] = nil
	end

	for playerRef, connections in pairs(self.ActiveCharacterMonitorConnections) do
		for _, connection in ipairs(connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
		self.ActiveCharacterMonitorConnections[playerRef] = nil
	end

	for instance, connection in pairs(self.CharacterEffectPropertyConnections) do
		pcall(function()
			connection:Disconnect()
		end)
		self.CharacterEffectPropertyConnections[instance] = nil
	end
end

local characterBodyPartNames = {
	Head = true,
	UpperTorso = true,
	LowerTorso = true,
	Torso = true,
	LeftArm = true,
	RightArm = true,
	LeftLeg = true,
	RightLeg = true,
	LeftHand = true,
	RightHand = true,
	LeftFoot = true,
	RightFoot = true,
	LeftLowerArm = true,
	RightLowerArm = true,
	LeftUpperArm = true,
	RightUpperArm = true,
	LeftLowerLeg = true,
	RightLowerLeg = true,
	LeftUpperLeg = true,
	RightUpperLeg = true,
	HumanoidRootPart = true,
}

local function isCosmeticCharacterPart(instance)
	if not instance or not instance:IsA("BasePart") then
		return false
	end

	if characterBodyPartNames[instance.Name] then
		return false
	end

	if instance:FindFirstAncestorOfClass("Tool") then
		return true
	end

	if instance:FindFirstAncestorOfClass("Accessory") then
		return true
	end

	local meshParent = instance:FindFirstAncestorOfClass("Model")
	if meshParent and meshParent.Name:lower():find("rod") then
		return true
	end

	return false
end

local function suppressCharacterVisual(instance)
	if not Optimizer.PotatoModeEnabled or not instance then
		return 0
	end

	local removedCount = 0

	pcall(function()
		if instance:IsA("ParticleEmitter")
			or instance:IsA("Trail")
			or instance:IsA("Beam")
			or instance:IsA("RopeConstraint")
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
		elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
			if instance.Enabled then
				removedCount = 1
			end
			instance.Enabled = false
		elseif instance:IsA("SelectionBox")
			or instance:IsA("BoxHandleAdornment")
			or instance:IsA("SphereHandleAdornment")
			or instance:IsA("CylinderHandleAdornment")
			or instance:IsA("ConeHandleAdornment") then
			if instance.Visible then
				removedCount = 1
			end
			instance.Visible = false
		elseif instance:IsA("ForceField") then
			instance.Visible = false
			removedCount = 1
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			if instance.Transparency < 1 then
				removedCount = 1
			end
			instance.Transparency = 1
		elseif instance:IsA("SurfaceAppearance") then
			removedCount = 1
			instance:Destroy()
		elseif instance:IsA("SpecialMesh") then
			if instance.TextureId ~= "" then
				removedCount = 1
			end
			instance.TextureId = ""
		elseif instance:IsA("MeshPart") then
			if instance.TextureID ~= "" then
				removedCount = 1
			end
			instance.TextureID = ""
		elseif isCosmeticCharacterPart(instance) then
			removedCount = 1
			instance.CastShadow = false
			instance.Material = Enum.Material.SmoothPlastic
			instance.Reflectance = 0
			instance.Color = Color3.fromRGB(70, 70, 70)
		end
	end)

	return removedCount
end

function Optimizer:WatchCharacterVisual(instance)
	if not instance then
		return 0
	end

	local propertyName = nil

	if instance:IsA("ParticleEmitter")
		or instance:IsA("Trail")
		or instance:IsA("Beam")
		or instance:IsA("RopeConstraint")
		or instance:IsA("Fire")
		or instance:IsA("Smoke")
		or instance:IsA("Sparkles")
		or instance:IsA("PointLight")
		or instance:IsA("SpotLight")
		or instance:IsA("SurfaceLight")
		or instance:IsA("Highlight") then
		propertyName = "Enabled"
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		propertyName = "Enabled"
	elseif instance:IsA("SelectionBox")
		or instance:IsA("BoxHandleAdornment")
		or instance:IsA("SphereHandleAdornment")
		or instance:IsA("CylinderHandleAdornment")
		or instance:IsA("ConeHandleAdornment") then
		propertyName = "Visible"
	elseif instance:IsA("ForceField") then
		propertyName = "Visible"
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		propertyName = "Transparency"
	elseif instance:IsA("SpecialMesh") then
		propertyName = "TextureId"
	elseif instance:IsA("MeshPart") then
		propertyName = "TextureID"
	elseif isCosmeticCharacterPart(instance) then
		propertyName = "Material"
	end

	local removedCount = suppressCharacterVisual(instance)

	if propertyName and not self.CharacterEffectPropertyConnections[instance] then
		local success, connection = pcall(function()
			return instance:GetPropertyChangedSignal(propertyName):Connect(function()
				if not self.PotatoModeEnabled then return end
				suppressCharacterVisual(instance)
			end)
		end)

		if success and connection then
			self.CharacterEffectPropertyConnections[instance] = connection
		end
	end

	return removedCount
end

function Optimizer:MonitorPlayerCharacter(playerRef, character)
	if not playerRef or not character then
		return 0
	end

	local existingConnections = self.ActiveCharacterMonitorConnections[playerRef]
	if existingConnections then
		for _, connection in ipairs(existingConnections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
	end

	local disabledEffects = 0
	disabledEffects += self:WatchCharacterVisual(character)

	for _, instance in ipairs(character:GetDescendants()) do
		disabledEffects += self:WatchCharacterVisual(instance)
	end

	self.ActiveCharacterMonitorConnections[playerRef] = {
		character.DescendantAdded:Connect(function(instance)
			if not self.PotatoModeEnabled then return end
			self:WatchCharacterVisual(instance)
		end)
	}

	return disabledEffects
end

function Optimizer:StartCharacterMonitoring()
	self:StopCharacterMonitoring()

	local disabledEffects = 0

	for _, playerRef in ipairs(Players:GetPlayers()) do
		if playerRef.Character then
			disabledEffects += self:MonitorPlayerCharacter(playerRef, playerRef.Character)
		end

		self.PlayerCharacterAddedConnections[playerRef] = playerRef.CharacterAdded:Connect(function(character)
			if not self.PotatoModeEnabled then return end
			task.wait(2)
			self:MonitorPlayerCharacter(playerRef, character)
		end)
	end

	self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(playerRef)
		if playerRef.Character then
			self:MonitorPlayerCharacter(playerRef, playerRef.Character)
		end

		self.PlayerCharacterAddedConnections[playerRef] = playerRef.CharacterAdded:Connect(function(character)
			if not self.PotatoModeEnabled then return end
			task.wait(2)
			self:MonitorPlayerCharacter(playerRef, character)
		end)
	end)

	return disabledEffects
end

local function removePlayerEffects(character)
	if not Optimizer.PotatoModeEnabled then
		return
	end

	for _, obj in ipairs(character:GetDescendants()) do
		
		-- PARTICLES
		if obj:IsA("ParticleEmitter") then
			obj.Enabled = false
		end
		
		-- TRAILS
		if obj:IsA("Trail") then
			obj.Enabled = false
		end
		
		-- BEAMS
		if obj:IsA("Beam") then
			obj.Enabled = false
		end
		
		-- LIGHTS
		if obj:IsA("PointLight")
		or obj:IsA("SpotLight")
		or obj:IsA("SurfaceLight") then
			obj.Enabled = false
		end
		
		-- HIGHLIGHT / GLOW
		if obj:IsA("Highlight") then
			obj.Enabled = false
		end
		
		-- FIRE EFFECT
		if obj:IsA("Fire") then
			obj.Enabled = false
		end
		
		-- SMOKE
		if obj:IsA("Smoke") then
			obj.Enabled = false
		end
		
		-- SPARKLES
		if obj:IsA("Sparkles") then
			obj.Enabled = false
		end
		
		-- FORCEFIELD GLOW
		if obj:IsA("ForceField") then
			obj.Visible = false
		end
		
		-- ACCESSORY TEXTURE
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		end

		if obj:IsA("SurfaceAppearance") then
			obj:Destroy()
		end

		if obj:IsA("SpecialMesh") then
			obj.TextureId = ""
		end

		if obj:IsA("MeshPart") then
			obj.TextureID = ""
		end

		if obj:IsA("RopeConstraint") then
			obj.Enabled = false
		end

		if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
			obj.Enabled = false
		end

		if obj:IsA("SelectionBox")
		or obj:IsA("BoxHandleAdornment")
		or obj:IsA("SphereHandleAdornment")
		or obj:IsA("CylinderHandleAdornment")
		or obj:IsA("ConeHandleAdornment") then
			obj.Visible = false
		end

		if isCosmeticCharacterPart(obj) then
			obj.CastShadow = false
			obj.Material = Enum.Material.SmoothPlastic
			obj.Reflectance = 0
			obj.Color = Color3.fromRGB(70, 70, 70)
		end
		
	end
end

function Optimizer:TogglePotato()
	self.PotatoModeEnabled = not self.PotatoModeEnabled
	
	if self.PotatoModeEnabled then
		-- Activate Potato Mode
		self:OptimizeAll()
	else
		-- Deactivate Potato Mode
		self:DisablePotato()
	end
	
	return self.PotatoModeEnabled
end

function Optimizer:DisablePotato()
	print("💯 [POTATO MODE] Disabling Potato Mode...")
	
	-- Stop water clearing loop
	if self.WaterClearingConnection then
		self.WaterClearingConnection:Disconnect()
		self.WaterClearingConnection = nil
		print("   • Water clearing loop stopped")
	end

	self:StopEffectMonitoring()
	self:StopCharacterMonitoring()
	
	self.PotatoModeEnabled = false
	print("✅ [POTATO MODE] POTATO MODE DEACTIVATED!")
	print("   • Note: Some changes (materials, shadows) are permanent until respawn")
	
	return false, "💯 POTATO MODE OFF (water loop stopped)"
end

function Optimizer:OptimizeAll()
	print("🥔 [POTATO MODE] Starting optimization...")
	-- REMOVE PLAYER EFFECTS
print("🔧 [POTATO MODE] Removing player effects...")

local characterEffectsDisabled = self:StartCharacterMonitoring()

print("✅ [POTATO MODE] Player effects removed")
	
	local optimizedParts = 0
	local disabledEffects = characterEffectsDisabled
	
	-- Helper function to optimize a single part
	local function optimizePart(part)
	if not part then return end

	-- JANGAN OPTIMIZE CHARACTER PLAYER
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return
	end

	-- MAP PART
	if part:IsA("BasePart") then
		pcall(function()
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			optimizedParts += 1
		end)
	end

	-- EFFECT MAP
	if part:IsA("ParticleEmitter") then
		part.Enabled = false
	end

	if part:IsA("Trail") then
		part.Enabled = false
	end

	if part:IsA("Beam") then
		part.Enabled = false
	end

	if part:IsA("Fire") then
		part.Enabled = false
	end

	if part:IsA("Smoke") then
		part.Enabled = false
	end

	if part:IsA("Sparkles") then
		part.Enabled = false
	end

	if part:IsA("PointLight")
	or part:IsA("SpotLight")
	or part:IsA("SurfaceLight") then
		part.Enabled = false
	end
end
	
	-- Helper to recursively optimize all children with depth limit
	local function deepOptimize(parent, depth)
		if not parent then return end
		depth = depth or 0
		if depth > 50 then return end
		
		local success, children = pcall(function()
			return parent:GetChildren()
		end)
		
		if not success or not children then return end
		
		for _, child in ipairs(children) do
			if child then
				optimizePart(child)
				deepOptimize(child, depth + 1)
			end
		end
	end
	
	-- 1. Workspace
	print("🔧 [POTATO MODE] Processing Workspace...")
	pcall(function()
		for _, playerRef in ipairs(Players:GetPlayers()) do
			if playerRef.Character then
				removePlayerEffects(playerRef.Character)
			end
		end
		deepOptimize(workspace)
		print("✅ [POTATO MODE] Workspace optimized")
	end)
	
	-- 2. Lighting - DISABLE ALL LIGHTS FOR FLAT APPEARANCE
	print("🔧 [POTATO MODE] Disabling Lighting...")
	pcall(function()
		local lighting = game:GetService("Lighting")
		if lighting then
			-- Disable ambient & shadow
			lighting.Ambient = Color3.fromRGB(100, 100, 100)
			lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
			lighting.ClockTime = 12
			lighting.Shadow = false
			
			-- Disable all light objects
			local success, children = pcall(function() return lighting:GetChildren() end)
			if success and children then
				for _, obj in ipairs(children) do
					pcall(function()
						if obj:IsA("Light") then
							obj.Enabled = false
							disabledEffects = disabledEffects + 1
						end
					end)
				end
			end
		end
		print("✅ [POTATO MODE] Lighting disabled")
	end)
	
	-- 3. Terrain
	print("🔧 [POTATO MODE] Processing Terrain...")
	pcall(function()
		local terrain = workspace.Terrain
		if terrain then
			terrain.CastShadow = false
			print("✅ [POTATO MODE] Terrain optimized")
		end
	end)
	
	-- 4. Disable all effects in the game
	print("🔧 [POTATO MODE] Disabling effects...")
	pcall(function()
		disabledEffects = disabledEffects + self:StartEffectMonitoring()
		print("✅ [POTATO MODE] Effects disabled")
	end)
	
	-- 5. WATER OPTIMIZATION (one-time terrain pass)
	print("🔧 [POTATO MODE] Optimizing Water (Terrain)...")
	local waterOptimized = 0
	pcall(function()
		local terrain = workspace.Terrain
		if not terrain then return end

		local region = Region3.new(terrain.MinimumPoint, terrain.MaximumPoint)
		region = region:ExpandToGrid(4)

		local materials, sizes = terrain:ReadVoxels(region, 4)
		local size = materials.Size
		local hasWater = false

		for x = 1, size.X do
			for y = 1, size.Y do
				for z = 1, size.Z do
					if materials[x][y][z] == Enum.Material.Water then
						materials[x][y][z] = Enum.Material.Air
						hasWater = true
					end
				end
			end
		end

		if hasWater then
			terrain:WriteVoxels(region, 4, materials, sizes)
			waterOptimized = 1
			print("   • One-time terrain water clear applied")
		end
	end)
	
	-- Handle water parts
	print("🔧 [POTATO MODE] Checking for water parts...")
	local waterPartsOptimized = 0
	pcall(function()
		local function findWaterParts(parent, depth)
			if not parent or depth > 50 then return end
			
			local success, children = pcall(function() return parent:GetChildren() end)
			if not success or not children then return end
			
			for _, part in ipairs(children) do
				if part then
					pcall(function()
						if part:IsA("BasePart") then
							local name = part.Name:lower()
							-- Check multiple water identifiers
							if name:find("water") or name:find("ocean") or name:find("sea") or name:find("fluid") or 
							   name:find("liquid") or name:find("pool") then
								-- Make water completely hidden/solid
								part.Transparency = 1 -- Completely invisible
								part.CanCollide = false
								part.Material = Enum.Material.Air
								waterPartsOptimized = waterPartsOptimized + 1
							end
						end
					end)
					
					findWaterParts(part, depth + 1)
				end
			end
		end
		
		findWaterParts(workspace, 0)
		if waterPartsOptimized > 0 then
			print("   • Water parts hidden: " .. waterPartsOptimized)
		end
	end)
	
	self.PotatoModeEnabled = true
	local totalOptimized = optimizedParts
	local totalWater = waterOptimized + waterPartsOptimized
	print("✅ [POTATO MODE] POTATO MODE ACTIVATED!")
	print("   • Parts optimized: " .. optimizedParts)
	print("   • Effects disabled: " .. disabledEffects)
	print("   • Water clearing: ONE-TIME PASS")
	print("   • Total changes: " .. (totalOptimized + disabledEffects))
	
	return true, "🥔 POTATO MODE ON! Parts:" .. totalOptimized .. " Effects:" .. disabledEffects .. " Water:ONE-PASS"
end

-- ============================================
-- ADMIN GUI
-- ============================================
local TweenService = game:GetService("TweenService")

-- Safe PlayerGui loading with timeout (5 seconds max)
print("DEBUG: Waiting for PlayerGui...")
local playerGui = player:WaitForChild("PlayerGui", 5)
if not playerGui then
	warn("⚠️ CRITICAL ERROR: PlayerGui not found after 5 seconds!")
	print("❌ Script execution halted - PlayerGui unavailable")
	error("PlayerGui loading failed")
	return
end

print("✓ PlayerGui found successfully")

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

print("✓ Admin GUI ScreenGui created")

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
mainFrame.Size = UDim2.new(0, 750, 0, 500)
mainFrame.Position = UDim2.new(0.5, -375, 0.5, -250)
mainFrame.BackgroundColor3 = AdminConfig.Theme.Primary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ZIndex = 10
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
titleLabel.Text = "⚙️ NB - Nobody Comunity - Admin Panel"
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
watermarkText.Text = "⚙️ Made by NB - Nobody Comunity | discord.gg/xHrJaSgy"
watermarkText.TextColor3 = AdminConfig.Theme.Text
watermarkText.TextSize = 12
watermarkText.Font = Enum.Font.Gotham
watermarkText.TextXAlignment = Enum.TextXAlignment.Left
watermarkText.TextTransparency = 0.3
watermarkText.Parent = watermark

-- ============================================
-- SIDEBAR SYSTEM
-- ============================================

-- Sidebar Container
local sidebarFrame = Instance.new("Frame")
sidebarFrame.Name = "Sidebar"
sidebarFrame.Size = UDim2.new(0, 160, 1, -95)
sidebarFrame.Position = UDim2.new(0, 15, 0, 90)
sidebarFrame.BackgroundColor3 = AdminConfig.Theme.Secondary
sidebarFrame.BorderSizePixel = 0
sidebarFrame.Parent = mainFrame

local sidebarCorner = Instance.new("UICorner")
sidebarCorner.CornerRadius = UDim.new(0, 8)
sidebarCorner.Parent = sidebarFrame

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 10)
sidebarPadding.PaddingBottom = UDim.new(0, 10)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.Parent = sidebarFrame

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 6)
sidebarLayout.Parent = sidebarFrame

-- Content Container (Right side)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -195, 1, -95)
contentFrame.Position = UDim2.new(0, 185, 0, 90)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.Parent = mainFrame

-- Store active tab and pages
AdminGUI.ActiveTab = nil
AdminGUI.TabPages = {}
AdminGUI.TabButtons = {}

-- Helper: Create Tab Button
local function createTabButton(name, icon, order, isDefault)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(1, 0, 0, 45)
	button.BackgroundColor3 = isDefault and AdminConfig.Theme.Accent or Color3.fromRGB(50, 50, 50)
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Parent = sidebarFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button
	
	local btnLabel = Instance.new("TextLabel")
	btnLabel.Name = "Label"
	btnLabel.Size = UDim2.new(1, -10, 1, 0)
	btnLabel.Position = UDim2.new(0, 5, 0, 0)
	btnLabel.BackgroundTransparency = 1
	btnLabel.Text = icon .. " " .. name
	btnLabel.TextColor3 = AdminConfig.Theme.Text
	btnLabel.TextSize = 13
	btnLabel.Font = Enum.Font.GothamBold
	btnLabel.TextXAlignment = Enum.TextXAlignment.Left
	btnLabel.Parent = button
	
	AdminGUI.TabButtons[name] = button
	
	return button
end

-- Helper: Create Content Page
local function createContentPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 6
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = contentFrame
	
	local pageLayout = Instance.new("UIListLayout")
	pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pageLayout.Padding = UDim.new(0, 10)
	pageLayout.Parent = page
	
	AdminGUI.TabPages[name] = page
	
	return page
end

-- Helper: Switch Tab
local function switchTab(tabName)
	if AdminGUI.ActiveTab == tabName then return end
	
	-- Hide all pages
	for name, page in pairs(AdminGUI.TabPages) do
		page.Visible = false
	end
	
	-- Reset all button colors
	for name, button in pairs(AdminGUI.TabButtons) do
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end
	
	-- Show selected page and highlight button
	if AdminGUI.TabPages[tabName] then
		AdminGUI.TabPages[tabName].Visible = true
	end
	
	if AdminGUI.TabButtons[tabName] then
		AdminGUI.TabButtons[tabName].BackgroundColor3 = AdminConfig.Theme.Accent
	end
	
	AdminGUI.ActiveTab = tabName
end

-- Create Tabs
createTabButton("Character", "⚡", 1, true)
createTabButton("Movement", "✈️", 2, false)
createTabButton("Teleport", "🌐", 3, false)
createTabButton("Utility", "🔧", 4, false)
createTabButton("Hunt", "🗺️", 5, false)

-- Create Content Pages
local characterPage = createContentPage("Character")
local movementPage = createContentPage("Movement")
local teleportPage = createContentPage("Teleport")
local utilityPage = createContentPage("Utility")
local huntPage = createContentPage("Hunt")

-- Set default tab
characterPage.Visible = true
AdminGUI.ActiveTab = "Character"

-- Player Selector (moved to top of content area, above pages)
-- New layout: [Reset] [Player Dropdown▼] [Go To] [Refresh]
local playerSelectorFrame = Instance.new("Frame")
playerSelectorFrame.Name = "PlayerSelector"
playerSelectorFrame.Size = UDim2.new(1, -195, 0, 45)
playerSelectorFrame.Position = UDim2.new(0, 185, 0, 90)
playerSelectorFrame.BackgroundColor3 = AdminConfig.Theme.Secondary
playerSelectorFrame.BorderSizePixel = 0
playerSelectorFrame.ZIndex = 1
playerSelectorFrame.Parent = mainFrame

local selectorCorner = Instance.new("UICorner")
selectorCorner.CornerRadius = UDim.new(0, 8)
selectorCorner.Parent = playerSelectorFrame

-- Reset button (leftmost)
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(0, 60, 0, 35)
resetButton.Position = UDim2.new(0, 5, 0, 5)
resetButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Bright red
resetButton.BorderSizePixel = 2
resetButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Text = "♻️"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextSize = 16
resetButton.Font = Enum.Font.GothamBold
resetButton.ZIndex = 2
resetButton.Parent = playerSelectorFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 6)
resetCorner.Parent = resetButton

-- Player dropdown button
local playerDropdown = Instance.new("TextButton")
playerDropdown.Name = "PlayerDropdown"
playerDropdown.Size = UDim2.new(1, -250, 0, 35)
playerDropdown.Position = UDim2.new(0, 70, 0, 5)
playerDropdown.BackgroundColor3 = AdminConfig.Theme.Primary
playerDropdown.BackgroundTransparency = 0
playerDropdown.BorderSizePixel = 1
playerDropdown.BorderColor3 = AdminConfig.Theme.Accent
playerDropdown.Text = "    ▼ Select Player"
playerDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
playerDropdown.TextSize = 13
playerDropdown.Font = Enum.Font.Gotham
playerDropdown.TextXAlignment = Enum.TextXAlignment.Left
playerDropdown.ZIndex = 2
playerDropdown.Parent = playerSelectorFrame

local dropdownCorner = Instance.new("UICorner")
dropdownCorner.CornerRadius = UDim.new(0, 8)
dropdownCorner.Parent = playerDropdown

-- Go To button
local gotoButton = Instance.new("TextButton")
gotoButton.Name = "GotoButton"
gotoButton.Size = UDim2.new(0, 80, 0, 35)
gotoButton.Position = UDim2.new(1, -165, 0, 5)
gotoButton.BackgroundColor3 = AdminConfig.Theme.Accent
gotoButton.BorderSizePixel = 1
gotoButton.BorderColor3 = AdminConfig.Theme.Accent
gotoButton.Text = "📍 Go"
gotoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gotoButton.TextSize = 13
gotoButton.Font = Enum.Font.GothamBold
gotoButton.ZIndex = 2
gotoButton.Parent = playerSelectorFrame

local gotoCorner = Instance.new("UICorner")
gotoCorner.CornerRadius = UDim.new(0, 6)
gotoCorner.Parent = gotoButton

-- Refresh button
local refreshButton = Instance.new("TextButton")
refreshButton.Name = "RefreshButton"
refreshButton.Size = UDim2.new(0, 75, 0, 35)
refreshButton.Position = UDim2.new(1, -75, 0, 5)
refreshButton.BackgroundColor3 = AdminConfig.Theme.Accent
refreshButton.BorderSizePixel = 1
refreshButton.BorderColor3 = AdminConfig.Theme.Accent
refreshButton.Text = "🔄"
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.TextSize = 16
refreshButton.Font = Enum.Font.GothamBold
refreshButton.ZIndex = 2
refreshButton.Parent = playerSelectorFrame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- Adjust content frame position to be below player selector
contentFrame.Position = UDim2.new(0, 185, 0, 145)
contentFrame.Size = UDim2.new(1, -195, 1, -150)
contentFrame.ZIndex = 1

-- Player List Container - SUPER SIMPLE VERSION!
local playerListContainer = Instance.new("ScrollingFrame")
playerListContainer.Name = "PlayerListContainer"
playerListContainer.Size = UDim2.new(0, 220, 0, 0)
playerListContainer.Position = UDim2.new(0, 0, 0, 0)
playerListContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Dark gray
playerListContainer.BackgroundTransparency = 0
playerListContainer.BorderSizePixel = 2
playerListContainer.BorderColor3 = Color3.fromRGB(0, 170, 255) -- Blue border
playerListContainer.Visible = false
playerListContainer.ClipsDescendants = true
playerListContainer.ZIndex = 100
playerListContainer.Active = true
playerListContainer.ScrollBarThickness = 8
playerListContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 170, 255)
playerListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListContainer.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 6)
containerCorner.Parent = playerListContainer

-- UIListLayout directly in container (NO WRAPPER FRAME!)
local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Parent = playerListContainer
print("✅ PlayerListContainer created as ScrollingFrame with UIListLayout!")

-- Search box inside player dropdown
local playerSearchBox = Instance.new("TextBox")
playerSearchBox.Name = "PlayerSearchBox"
playerSearchBox.Size = UDim2.new(0, 200, 0, 35)
playerSearchBox.BackgroundColor3 = AdminConfig.Theme.Secondary
playerSearchBox.BorderSizePixel = 1
playerSearchBox.BorderColor3 = AdminConfig.Theme.Accent
playerSearchBox.PlaceholderText = "🔎 Cari nama player..."
playerSearchBox.Text = ""
playerSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
playerSearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
playerSearchBox.TextSize = 12
playerSearchBox.Font = Enum.Font.Gotham
playerSearchBox.ZIndex = 102
playerSearchBox.LayoutOrder = -1
playerSearchBox.ClearTextOnFocus = false
playerSearchBox.Parent = playerListContainer

local playerSearchCorner = Instance.new("UICorner")
playerSearchCorner.CornerRadius = UDim.new(0, 6)
playerSearchCorner.Parent = playerSearchBox

-- ============================================
-- CONTENT SECTIONS (FOR EACH TAB)
-- ============================================

-- Helper: Create Section in Page
local function createSection(parentPage, title, order)
	local section = Instance.new("Frame")
	section.Name = title .. "Section"
	section.Size = UDim2.new(1, 0, 0, 0)
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.BackgroundColor3 = AdminConfig.Theme.Secondary
	section.BorderSizePixel = 0
	section.LayoutOrder = order
	section.Parent = parentPage
	
	local sectionCorner = Instance.new("UICorner")
	sectionCorner.CornerRadius = UDim.new(0, 8)
	sectionCorner.Parent = section
	
	local sectionPadding = Instance.new("UIPadding")
	sectionPadding.PaddingTop = UDim.new(0, 10)
	sectionPadding.PaddingBottom = UDim.new(0, 10)
	sectionPadding.PaddingLeft = UDim.new(0, 10)
	sectionPadding.PaddingRight = UDim.new(0, 10)
	sectionPadding.Parent = section
	
	local sectionLayout = Instance.new("UIListLayout")
	sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sectionLayout.Padding = UDim.new(0, 8)
	sectionLayout.Parent = section
	
	local sectionTitle = Instance.new("TextLabel")
	sectionTitle.Name = "Title"
	sectionTitle.Size = UDim2.new(1, 0, 0, 20)
	sectionTitle.BackgroundTransparency = 1
	sectionTitle.Text = title
	sectionTitle.TextColor3 = AdminConfig.Theme.Accent
	sectionTitle.TextSize = 14
	sectionTitle.Font = Enum.Font.GothamBold
	sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	sectionTitle.LayoutOrder = 0
	sectionTitle.Parent = section
	
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, 0, 0, 0)
	buttonsContainer.AutomaticSize = Enum.AutomaticSize.Y
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.LayoutOrder = 1
	buttonsContainer.Parent = section
	
	local buttonsGrid = Instance.new("UIGridLayout")
	buttonsGrid.CellSize = UDim2.new(0, 170, 0, 40)
	buttonsGrid.CellPadding = UDim2.new(0, 8, 0, 8)
	buttonsGrid.SortOrder = Enum.SortOrder.LayoutOrder
	buttonsGrid.Parent = buttonsContainer
	
	return buttonsContainer
end

-- Helper: Create Command Button (Updated for new layout)
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
	buttonLabel.Size = UDim2.new(1, -55, 1, 0)
	buttonLabel.Position = UDim2.new(0, 8, 0, 0)
	buttonLabel.BackgroundTransparency = 1
	buttonLabel.Text = icon .. " " .. text
	buttonLabel.TextColor3 = AdminConfig.Theme.Text
	buttonLabel.TextSize = 12
	buttonLabel.Font = Enum.Font.GothamBold
	buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
	buttonLabel.Parent = button
	
	-- Add status indicator for toggle buttons
	if isToggle then
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "Status"
		statusLabel.Size = UDim2.new(0, 40, 1, 0)
		statusLabel.Position = UDim2.new(1, -45, 0, 0)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = "OFF"
		statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		statusLabel.TextSize = 10
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.Parent = button
		
		-- Store reference
		AdminGUI.ToggleButtons[command] = {button = button, status = statusLabel}
	end
	
	return button
end

-- ============================================
-- CREATE ALL SECTIONS AND BUTTONS
-- ============================================

-- CHARACTER TAB
local characterStats = createSection(characterPage, "⚡ Character Stats", 1)
createCommandButton(characterStats, "Speed", "🏃", "speed", 1, false)
createCommandButton(characterStats, "Jump Power", "🦘", "jp", 2, false)

local characterAbilities = createSection(characterPage, "🛡️ Abilities", 2)
createCommandButton(characterAbilities, "Infinite Jump", "🚀", "infinitejump", 1, true)
createCommandButton(characterAbilities, "God Mode", "🛡️", "god", 2, true)
createCommandButton(characterAbilities, "NoClip Mode", "👻", "noclip", 3, true)

local visionSection = createSection(characterPage, "👁️ Vision", 3)
createCommandButton(visionSection, "ESP + Prox Aura", "👁️", "espprox", 1, true)

-- MOVEMENT TAB
local flyingSection = createSection(movementPage, "✈️ Flying Controls", 1)
createCommandButton(flyingSection, "Fly Mode", "🚀", "fly", 1, true)
createCommandButton(flyingSection, "Fly Speed", "⚡", "flyspeed", 2, false)

-- TELEPORT TAB
local teleportInfo = Instance.new("TextLabel")
teleportInfo.Name = "TeleportInfo"
teleportInfo.Size = UDim2.new(1, 0, 0, 60)
teleportInfo.BackgroundColor3 = AdminConfig.Theme.Secondary
teleportInfo.BorderSizePixel = 0
teleportInfo.Text = "📍 Use the player selector at the top\nSelect a player and click 'Go' button"
teleportInfo.TextColor3 = AdminConfig.Theme.Text
teleportInfo.TextSize = 13
teleportInfo.Font = Enum.Font.Gotham
teleportInfo.TextWrapped = true
teleportInfo.TextYAlignment = Enum.TextYAlignment.Center
teleportInfo.LayoutOrder = 1
teleportInfo.Parent = teleportPage

local teleportInfoCorner = Instance.new("UICorner")
teleportInfoCorner.CornerRadius = UDim.new(0, 8)
teleportInfoCorner.Parent = teleportInfo

-- ============================================
-- HUNT TAB
-- ============================================
-- Module: Treasure Hunt Teleport
local TreasureHunt = {}
TreasureHunt.LastFound = nil  -- simpan objek terakhir yang ditemukan
-- Keyword untuk cari treasure hunt di workspace
TreasureHunt.Keywords = {
	"treasure","hunt","chest","bounty","event","rare","special","beacon",
	"marker","location","spot","find","loot","prize"
}
function TreasureHunt:FindInWorkspace()
	local function matchKw(name)
		local low = name:lower()
		for _, kw in ipairs(self.Keywords) do
			if low:find(kw, 1, true) then return true end
		end
		return false
	end
	local results = {}
	local function scan(obj, depth)
		if depth > 8 then return end
		if matchKw(obj.Name) then
			local pos = nil
			if obj:IsA("BasePart") then
				pos = obj.Position
			elseif obj:IsA("Model") then
				local ok, cf = pcall(function() return obj:GetPivot() end)
				if ok then pos = cf.Position end
			end
			if pos then
				table.insert(results, {obj = obj, pos = pos, name = obj.Name, class = obj.ClassName})
			end
		end
		local ok, ch = pcall(function() return obj:GetChildren() end)
		if ok and ch then
			for _, c in ipairs(ch) do scan(c, depth + 1) end
		end
	end
	pcall(function() scan(workspace, 0) end)
	return results
end

-- Status label dan result list di UI Hunt page
local huntStatusLabel = Instance.new("TextLabel")
huntStatusLabel.Name = "HuntStatus"
huntStatusLabel.Size = UDim2.new(1, 0, 0, 40)
huntStatusLabel.BackgroundColor3 = AdminConfig.Theme.Secondary
huntStatusLabel.BorderSizePixel = 0
huntStatusLabel.Text = "🗺️ Klik Scan untuk cari lokasi Treasure Hunt"
huntStatusLabel.TextColor3 = AdminConfig.Theme.Text
huntStatusLabel.TextSize = 12
huntStatusLabel.Font = Enum.Font.Gotham
huntStatusLabel.TextWrapped = true
huntStatusLabel.TextYAlignment = Enum.TextYAlignment.Center
huntStatusLabel.LayoutOrder = 1
huntStatusLabel.Parent = huntPage
local huntStatusCorner = Instance.new("UICorner")
huntStatusCorner.CornerRadius = UDim.new(0, 8)
huntStatusCorner.Parent = huntStatusLabel

-- Tombol Scan
local huntScanBtn = Instance.new("TextButton")
huntScanBtn.Name = "HuntScan"
huntScanBtn.Size = UDim2.new(1, 0, 0, 40)
huntScanBtn.BackgroundColor3 = AdminConfig.Theme.Accent
huntScanBtn.BorderSizePixel = 0
huntScanBtn.Text = "🔍 Scan Treasure Hunt"
huntScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
huntScanBtn.TextSize = 13
huntScanBtn.Font = Enum.Font.GothamBold
huntScanBtn.LayoutOrder = 2
huntScanBtn.Parent = huntPage
local huntScanCorner = Instance.new("UICorner")
huntScanCorner.CornerRadius = UDim.new(0, 8)
huntScanCorner.Parent = huntScanBtn

-- Search box (muncul setelah ada hasil scan)
local huntSearchBox = Instance.new("TextBox")
huntSearchBox.Name = "HuntSearch"
huntSearchBox.Size = UDim2.new(1, 0, 0, 36)
huntSearchBox.BackgroundColor3 = AdminConfig.Theme.Secondary
huntSearchBox.BorderSizePixel = 0
huntSearchBox.PlaceholderText = "🔎 Cari nama lokasi..."
huntSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
huntSearchBox.Text = ""
huntSearchBox.TextColor3 = AdminConfig.Theme.Text
huntSearchBox.TextSize = 12
huntSearchBox.Font = Enum.Font.Gotham
huntSearchBox.ClearTextOnFocus = false
huntSearchBox.Visible = false
huntSearchBox.LayoutOrder = 3
huntSearchBox.Parent = huntPage
local huntSearchCorner = Instance.new("UICorner")
huntSearchCorner.CornerRadius = UDim.new(0, 8)
huntSearchCorner.Parent = huntSearchBox
local huntSearchPad = Instance.new("UIPadding")
huntSearchPad.PaddingLeft = UDim.new(0, 10)
huntSearchPad.Parent = huntSearchBox

-- Container hasil scan (list tombol teleport)
local huntResultsContainer = Instance.new("Frame")
huntResultsContainer.Name = "HuntResults"
huntResultsContainer.Size = UDim2.new(1, 0, 0, 0)
huntResultsContainer.AutomaticSize = Enum.AutomaticSize.Y
huntResultsContainer.BackgroundTransparency = 1
huntResultsContainer.LayoutOrder = 4
huntResultsContainer.Parent = huntPage
local huntResultsLayout = Instance.new("UIListLayout")
huntResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
huntResultsLayout.Padding = UDim.new(0, 6)
huntResultsLayout.Parent = huntResultsContainer

-- Tombol Teleport ke Found (visible setelah scan berhasil)
local huntTeleportBtn = Instance.new("TextButton")
huntTeleportBtn.Name = "HuntTeleport"
huntTeleportBtn.Size = UDim2.new(1, 0, 0, 44)
huntTeleportBtn.BackgroundColor3 = AdminConfig.Theme.Success
huntTeleportBtn.BorderSizePixel = 0
huntTeleportBtn.Text = "↩️ Kembali ke Posisi Sebelumnya"
huntTeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
huntTeleportBtn.TextSize = 13
huntTeleportBtn.Font = Enum.Font.GothamBold
huntTeleportBtn.Visible = false
huntTeleportBtn.LayoutOrder = 5
huntTeleportBtn.Parent = huntPage
local huntTeleportCorner = Instance.new("UICorner")
huntTeleportCorner.CornerRadius = UDim.new(0, 8)
huntTeleportCorner.Parent = huntTeleportBtn

-- UTILITY TAB
local systemSection = createSection(utilityPage, "🔧 System", 1)
createCommandButton(systemSection, "Respawn", "🔄", "respawn", 1, false)
createCommandButton(systemSection, "Anti-AFK", "⏰", "antiafk", 2, true)
createCommandButton(systemSection, "Potato Mode", "🥔", "potato", 3, true)
-- createCommandButton(systemSection, "Potato Debug", "🧪", "potatodebug", 4, true)

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
notificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
notificationText.TextSize = 18
notificationText.Font = Enum.Font.GothamBold
notificationText.TextWrapped = true
notificationText.TextXAlignment = Enum.TextXAlignment.Left
notificationText.TextYAlignment = Enum.TextYAlignment.Top
notificationText.TextStrokeTransparency = 0.5
notificationText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
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
	playerListContainer.Visible = false -- Hide dropdown when panel toggles
	
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

function AdminGUI:UpdatePlayerList(query)
	query = query or ""
	local queryLower = query:lower()

	-- Clear existing buttons
	for _, child in ipairs(playerListContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Add "Self" button at top
	local selfButton = Instance.new("TextButton")
	selfButton.Name = "SelfButton"
	selfButton.Size = UDim2.new(0, 200, 0, 40)
	selfButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Bright blue
	selfButton.BackgroundTransparency = 0
	selfButton.BorderSizePixel = 2
	selfButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
	selfButton.Text = "Me (Self)"
	selfButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	selfButton.TextSize = 14
	selfButton.Font = Enum.Font.GothamBold
	selfButton.TextXAlignment = Enum.TextXAlignment.Center
	selfButton.AutoButtonColor = false
	selfButton.ZIndex = 101
	selfButton.LayoutOrder = 0
	selfButton.Parent = playerListContainer
	
	selfButton.MouseButton1Click:Connect(function()
		AdminGUI.SelectedPlayer = nil
		playerDropdown.Text = "    ▼ Select Player"
		selfButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100) -- Flash green on click
		task.wait(0.1)
		selfButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		playerListContainer.Visible = false
	end)
	
	selfButton.MouseEnter:Connect(function()
		selfButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255) -- Lighter blue
	end)
	selfButton.MouseLeave:Connect(function()
		selfButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Back to bright blue
	end)
	
	local allPlayers = Players:GetPlayers()
	
	local buttonIndex = 1
	for _, plr in ipairs(allPlayers) do
		if queryLower == "" or plr.Name:lower():find(queryLower, 1, true) or plr.DisplayName:lower():find(queryLower, 1, true) then
			local playerButton = Instance.new("TextButton")
			playerButton.Name = plr.Name
			playerButton.Size = UDim2.new(0, 200, 0, 50)
			playerButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180) -- Steel blue
			playerButton.BackgroundTransparency = 0
			playerButton.BorderSizePixel = 2
			playerButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
			playerButton.AutoButtonColor = false
			playerButton.ZIndex = 101
			playerButton.LayoutOrder = buttonIndex
			
			-- Multi-line text
			local buttonText = plr.DisplayName .. "\n@" .. plr.Name
			playerButton.Text = buttonText
			playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			playerButton.TextSize = 13
			playerButton.Font = Enum.Font.Gotham
			playerButton.TextXAlignment = Enum.TextXAlignment.Center
			playerButton.TextYAlignment = Enum.TextYAlignment.Center
			playerButton.TextWrapped = true
			playerButton.Parent = playerListContainer
			
			buttonIndex = buttonIndex + 1
			
			playerButton.MouseButton1Click:Connect(function()
				AdminGUI.SelectedPlayer = plr.Name
				-- Flash green on successful click
				playerButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
				task.wait(0.1)
				-- Show display name in dropdown if different
				if plr.DisplayName ~= plr.Name then
					playerDropdown.Text = "    ▼ " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
				else
					playerDropdown.Text = "    ▼ " .. plr.Name
				end
				playerListContainer.Visible = false
			end)
			
			playerButton.MouseEnter:Connect(function()
				playerButton.BackgroundColor3 = Color3.fromRGB(100, 180, 255) -- Lighter blue
			end)
			playerButton.MouseLeave:Connect(function()
				playerButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180) -- Back to steel blue
			end)
		end
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
	print("NB - Nobody Comunity Discord: " .. discordLink)
end)

playerDropdown.MouseButton1Click:Connect(function()
	playerListContainer.Visible = not playerListContainer.Visible
	
	if playerListContainer.Visible then
		playerSearchBox.Text = ""
		AdminGUI:UpdatePlayerList("")
		
		local playerCount = #Players:GetPlayers() + 1
		local targetHeight = math.min(playerCount * 53 + 60, 350) -- +60 for search box
		
		-- Position below dropdown button
		local dropdownAbsPos = playerDropdown.AbsolutePosition
		local dropdownAbsSize = playerDropdown.AbsoluteSize
		local posX = dropdownAbsPos.X
		local posY = dropdownAbsPos.Y + dropdownAbsSize.Y + 15 -- Moved down more
		
		playerListContainer.Position = UDim2.new(0, posX, 0, posY)
		playerListContainer.Size = UDim2.new(0, 220, 0, targetHeight)
	end
end)

-- Realtime search filter for player list
playerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	AdminGUI:UpdatePlayerList(playerSearchBox.Text)
end)

refreshButton.MouseButton1Click:Connect(function()
	playerSearchBox.Text = ""
	AdminGUI:UpdatePlayerList("")
	AdminGUI:RefreshAllToggles() -- Refresh toggle statuses too
	AdminGUI:ShowNotification("Player list refreshed!", "success")
end)

-- Reset button
resetButton.MouseButton1Click:Connect(function()
	AdminGUI:ExecuteCommand("reset", false)
end)

-- Goto button
gotoButton.MouseButton1Click:Connect(function()
	AdminGUI:ExecuteCommand("goto", false)
end)

-- Add hover effects for action buttons
playerDropdown.MouseEnter:Connect(function()
	playerDropdown.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
end)
playerDropdown.MouseLeave:Connect(function()
	playerDropdown.BackgroundColor3 = AdminConfig.Theme.Primary
end)

gotoButton.MouseEnter:Connect(function()
	gotoButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
end)
gotoButton.MouseLeave:Connect(function()
	gotoButton.BackgroundColor3 = AdminConfig.Theme.Accent
end)

refreshButton.MouseEnter:Connect(function()
	refreshButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
end)
refreshButton.MouseLeave:Connect(function()
	refreshButton.BackgroundColor3 = AdminConfig.Theme.Accent
end)

resetButton.MouseEnter:Connect(function()
	resetButton.BackgroundColor3 = Color3.fromRGB(255, 150, 150) -- Lighter red
end)
resetButton.MouseLeave:Connect(function()
	resetButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Back to bright red
end)

-- ESC key to close dropdown
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.Escape and playerListContainer.Visible then
		playerListContainer.Visible = false
		playerListContainer.Size = UDim2.new(0, 0, 0, 0)
	end
end)

local function connectCommandButton(buttonName, command, requiresInput)
	-- Search in all pages for the button
	for _, page in pairs(AdminGUI.TabPages) do
		for _, section in ipairs(page:GetChildren()) do
			if section:IsA("Frame") then
				local buttonsContainer = section:FindFirstChild("ButtonsContainer")
				if buttonsContainer then
					local button = buttonsContainer:FindFirstChild(buttonName)
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
						return -- Found and connected
					end
				end
			end
		end
	end
end

-- ============================================
-- HUNT TAB HANDLERS
-- ============================================
local _huntPrevPos = nil    -- posisi sebelum klik list button
local _huntAllResults = {}  -- cache semua hasil scan untuk filter search

local function _huntDoTeleport(pos)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and pos then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
		return true
	end
	return false
end

local function _huntClearResults()
	for _, c in ipairs(huntResultsContainer:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
end

local function _huntAddResultBtn(entry, index)
	local btn = Instance.new("TextButton")
	btn.Name = "Result_" .. index
	btn.Size = UDim2.new(1, 0, 0, 44)
	btn.BackgroundColor3 = AdminConfig.Theme.Primary
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.LayoutOrder = index
	btn.Parent = huntResultsContainer

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("📍 %s\n[%s] (%.0f, %.0f, %.0f)",
		entry.name, entry.class,
		entry.pos.X, entry.pos.Y, entry.pos.Z)
	label.TextColor3 = AdminConfig.Theme.Text
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = btn

	btn.MouseButton1Click:Connect(function()
		-- Simpan posisi saat ini sebelum teleport
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			_huntPrevPos = hrp.CFrame
		end
		local ok = _huntDoTeleport(entry.pos)
		huntStatusLabel.Text = ok
			and ("✅ Teleport ke: " .. entry.name .. " — klik ↩️ untuk balik")
			or "❌ Karakter tidak ditemukan"
		if ok and _huntPrevPos then
			huntTeleportBtn.Visible = true
		end
	end)

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = AdminConfig.Theme.Accent
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = AdminConfig.Theme.Primary
	end)
end

-- Render daftar hasil (bisa difilter lewat query string)
local function _huntRenderResults(query)
	_huntClearResults()
	local q = (query or ""):lower()
	local shown = 0
	for i, entry in ipairs(_huntAllResults) do
		if q == "" or entry.name:lower():find(q, 1, true) then
			_huntAddResultBtn(entry, shown + 1)
			shown += 1
		end
	end
	if shown == 0 and q ~= "" then
		local noResult = Instance.new("TextLabel")
		noResult.Size = UDim2.new(1, 0, 0, 36)
		noResult.BackgroundTransparency = 1
		noResult.Text = "Tidak ada hasil untuk \"" .. query .. "\""
		noResult.TextColor3 = Color3.fromRGB(150, 150, 150)
		noResult.TextSize = 12
		noResult.Font = Enum.Font.Gotham
		noResult.LayoutOrder = 1
		noResult.Parent = huntResultsContainer
	end
end

-- Scan button
huntScanBtn.MouseButton1Click:Connect(function()
	huntStatusLabel.Text = "🔍 Scanning workspace..."
	_huntClearResults()
	huntTeleportBtn.Visible = false
	_huntPrevPos = nil
	task.wait(0.05)

	local results = TreasureHunt:FindInWorkspace()

	if #results == 0 then
		huntStatusLabel.Text = "❌ Tidak ditemukan objek Treasure Hunt\nCoba saat event aktif"
		huntSearchBox.Visible = false
		return
	end

	_huntAllResults = results
	huntSearchBox.Visible = true
	huntSearchBox.Text = ""
	huntStatusLabel.Text = "✅ Ditemukan " .. #results .. " lokasi — klik untuk teleport:"
	_huntRenderResults("")

	huntTeleportBtn.Visible = false  -- muncul hanya setelah klik list button
end)

-- Search box filter realtime
huntSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	_huntRenderResults(huntSearchBox.Text)
end)

-- Tombol kembali ke posisi sebelumnya (sebelum klik list button)
huntTeleportBtn.MouseButton1Click:Connect(function()
	if not _huntPrevPos then
		huntStatusLabel.Text = "❌ Belum ada posisi tersimpan"
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = _huntPrevPos
		huntStatusLabel.Text = "↩️ Kembali ke posisi sebelumnya"
		_huntPrevPos = nil
		huntTeleportBtn.Visible = false
	else
		huntStatusLabel.Text = "❌ Karakter tidak ditemukan"
	end
end)

-- ============================================
-- TAB SWITCHING LOGIC
-- ============================================

-- Connect tab buttons to switch pages
for tabName, button in pairs(AdminGUI.TabButtons) do
	button.MouseButton1Click:Connect(function()
		switchTab(tabName)
	end)
	
	-- Add hover effect for tabs
	button.MouseEnter:Connect(function()
		if AdminGUI.ActiveTab ~= tabName then
			TweenService:Create(
				button,
				TweenInfo.new(0.2),
				{BackgroundColor3 = Color3.fromRGB(70, 70, 70)}
			):Play()
		end
	end)
	
	button.MouseLeave:Connect(function()
		if AdminGUI.ActiveTab ~= tabName then
			TweenService:Create(
				button,
				TweenInfo.new(0.2),
				{BackgroundColor3 = Color3.fromRGB(50, 50, 50)}
			):Play()
		end
	end)
end

-- Close player list dropdown when clicking outside
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if playerListContainer.Visible then
			-- Check if click is outside the dropdown and player selector
			local mousePos = UserInputService:GetMouseLocation()
			local dropdownPos = playerListContainer.AbsolutePosition
			local dropdownSize = playerListContainer.AbsoluteSize
			local selectorPos = playerSelectorFrame.AbsolutePosition
			local selectorSize = playerSelectorFrame.AbsoluteSize
			
			local clickInDropdown = mousePos.X >= dropdownPos.X and mousePos.X <= dropdownPos.X + dropdownSize.X and
									mousePos.Y >= dropdownPos.Y and mousePos.Y <= dropdownPos.Y + dropdownSize.Y
			
			local clickInSelector = mousePos.X >= selectorPos.X and mousePos.X <= selectorPos.X + selectorSize.X and
									mousePos.Y >= selectorPos.Y and mousePos.Y <= selectorPos.Y + selectorSize.Y
			
			if not clickInDropdown and not clickInSelector then
				playerListContainer.Visible = false
				playerListContainer.Size = UDim2.new(0, 0, 0, 0)
			end
		end
	end
end)

-- ============================================
-- CONNECT COMMAND BUTTONS TO ACTIONS
-- ============================================

connectCommandButton("speed", "speed", true)
connectCommandButton("jp", "jp", true)
connectCommandButton("infinitejump", "infinitejump", false)
connectCommandButton("god", "god", false)
connectCommandButton("noclip", "noclip", false)
connectCommandButton("fly", "fly", false)
connectCommandButton("flyspeed", "flyspeed", true)
connectCommandButton("respawn", "respawn", false)
connectCommandButton("antiafk", "antiafk", false)
-- connectCommandButton("potatodebug", "potatodebug", false)

-- Potato Mode button - Custom handler (not a chat command)
local potatoButton = nil
for _, page in pairs(AdminGUI.TabPages) do
	for _, section in ipairs(page:GetChildren()) do
		if section:IsA("Frame") then
			local buttonsContainer = section:FindFirstChild("ButtonsContainer")
			if buttonsContainer then
				local button = buttonsContainer:FindFirstChild("potato")
				if button and button:IsA("TextButton") then
					potatoButton = button
					break
				end
			end
		end
	end
	if potatoButton then break end
end

if potatoButton then
	potatoButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			return Optimizer:TogglePotato()
		end)
		
		if success then
			local isEnabled = result
			CommandExecutor.PlayerStatuses.potato = isEnabled
			
			-- Update button visual
			local statusLabel = potatoButton:FindFirstChild("Status")
			if statusLabel then
				statusLabel.Text = isEnabled and "ON" or "OFF"
				statusLabel.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(150, 150, 150)
			end
			
			-- Update button background
			potatoButton.BackgroundColor3 = isEnabled and AdminConfig.Theme.Accent or AdminConfig.Theme.Primary
			
			-- Show notification
			if AdminGUI and AdminGUI.ShowNotification then
				if isEnabled then
					AdminGUI:ShowNotification("🥔 POTATO MODE ON! FPS boost active", "success")
				else
					AdminGUI:ShowNotification("💯 POTATO MODE OFF (water loop stopped)", "info")
				end
			end
		else
			warn("❌ Potato Mode error: " .. tostring(result))
			if AdminGUI and AdminGUI.ShowNotification then
				AdminGUI:ShowNotification("Error: " .. tostring(result), "error")
			end
		end
	end)
	
	-- Hover effects
	potatoButton.MouseEnter:Connect(function()
		if not CommandExecutor.PlayerStatuses.potato then
			TweenService:Create(
				potatoButton,
				TweenInfo.new(0.2),
				{BackgroundColor3 = AdminConfig.Theme.Accent}
			):Play()
		end
	end)
	
	potatoButton.MouseLeave:Connect(function()
		if not CommandExecutor.PlayerStatuses.potato then
			TweenService:Create(
				potatoButton,
				TweenInfo.new(0.2),
				{BackgroundColor3 = AdminConfig.Theme.Primary}
			):Play()
		end
	end)
end

-- ESP + Proximity Aura Button Handler
local espProxButton = nil
for _, page in pairs(AdminGUI.TabPages) do
	for _, section in ipairs(page:GetChildren()) do
		if section:IsA("Frame") then
			local buttonsContainer = section:FindFirstChild("ButtonsContainer")
			if buttonsContainer then
				local btn = buttonsContainer:FindFirstChild("espprox")
				if btn and btn:IsA("TextButton") then
					espProxButton = btn
					break
				end
			end
		end
	end
	if espProxButton then break end
end

if espProxButton then
	espProxButton.MouseButton1Click:Connect(function()
		local enabled = ESPModule:Toggle()
		CommandExecutor.PlayerStatuses.espprox = enabled

		local statusLabel = espProxButton:FindFirstChild("Status")
		if statusLabel then
			statusLabel.Text = enabled and "ON" or "OFF"
			statusLabel.TextColor3 = enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(150, 150, 150)
		end
		espProxButton.BackgroundColor3 = enabled and Color3.fromRGB(25, 60, 25) or AdminConfig.Theme.Primary

		AdminGUI:ShowNotification(
			enabled and "👁️ ESP + Prox Aura ON" or "👁️ ESP + Prox Aura OFF",
			enabled and "success" or "info"
		)
	end)

	espProxButton.MouseEnter:Connect(function()
		if not CommandExecutor.PlayerStatuses.espprox then
			TweenService:Create(espProxButton, TweenInfo.new(0.2), {BackgroundColor3 = AdminConfig.Theme.Accent}):Play()
		end
	end)
	espProxButton.MouseLeave:Connect(function()
		if not CommandExecutor.PlayerStatuses.espprox then
			TweenService:Create(espProxButton, TweenInfo.new(0.2), {BackgroundColor3 = AdminConfig.Theme.Primary}):Play()
		end
	end)
end

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
	if CommandExecutor.PlayerStatuses.noclip then
		NoClip.Enabled = false -- reset so Enable() runs fresh
		NoClip:Enable()
		AdminGUI:ShowNotification("👻 NoClip reapplied after respawn!", "success")
	end
end)

-- ============================================
-- VIOLENCE DISTRICT MODULE (OPTIONAL)
-- ============================================

--[[
	⚡ VIOLENCE DISTRICT adalah module TERPISAH dan OPTIONAL!
	
	FITUR Violence District:
	• 🖱️ Cursor Unlock (K)
	• 👁️ ESP Wallhack (J) - Player + Interactable objects
	• 🪤 Pallet ESP (J) - Trap pallet detection
	• 🎯 Crosshair (H) - Range marks 30m/60m/90m+
	• 📷 Camera Zoom (G) - Free scroll zoom
	• ⚡ Speed Boost (L) - Speed 20 + Auto Shift
	
	Cara Load Violence District:
	1. Load TERPISAH setelah LoaderScript.lua:
	   loadstring(game:HttpGet("YOUR_GITHUB_URL/vd.lua"))()
	
	2. Atau gunakan EXECUTOR_TEMPLATE.lua yang sudah include keduanya
	
	⚠️ CATATAN:
	- vd.lua HARUS di-load SETELAH LoaderScript.lua
	- vd.lua butuh _G.AdminGUI dari LoaderScript untuk notifications
	- Jika tidak butuh Violence District, skip vd.lua saja
]]

-- Export AdminGUI to global for VD module to access (if loaded manually)
_G.AdminGUI = AdminGUI

-- Reference to Violence District (will be set by vd.lua if loaded)
local UtilityGUI = _G.ViolenceDistrict or {}

-- ============================================
-- INITIALIZATION
-- ============================================
print("✅ Admin Script Loaded Successfully!")
print("👤 Username: " .. player.Name)
print("🔓 Access: PUBLIC (No admin check for executor version)")
AdminGUI:ShowNotification("NB - Nobody Comunity Admin Script Loaded!\nAll features unlocked!", "success")

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
print("   ;infinitejump - Toggle infinite jump (Hold SPACE to fly up!)")
print("   ;ijumpspeed [number] - Set infinite jump speed (50-300)")
print("   ;god - Toggle god mode (true invincibility)")
print("   ;noclip - Toggle NoClip mode (walk through walls)")
print("   ;goto - Teleport to selected player")
print("   ;reset - Reset character to normal")
print("   ;respawn - Respawn character")
print("   ;antiafk - Toggle anti-AFK (24/7 active, no auto-kick)")
print("   ;potatodebug - Toggle rod/effect debug logging for Potato Mode")
print("\n💡 UI Features:")
print("   • Toggle buttons show ON/OFF status")
print("   • Select target player for goto command")
print("   • Reset button (top right) for quick reset")
