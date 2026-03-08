--[[
	===============================================
	   FISH IT AUTO FARM SCRIPT
	   By: TwoHand Comunity
	   Discord: https://discord.gg/xHrJaSgy
	   
	   🎣 FISH IT GAME AUTO FARMING
	   Features: Auto Fish, Perfect Catch, Auto Sell, Teleports
	   
	   📋 HOW TO USE:
	   1. Upload this file to GitHub (get raw link)
	   2. In executor, run:
	      loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL"))()
	===============================================
]]

print("🎣 Loading Fish It Auto Farm Script...")

-- Add error handler
local success, errorMsg = pcall(function()

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- Helper function to get character safely
local function getCharacter()
	return player.Character
end

-- Helper function to get HumanoidRootPart safely
local function getHRP()
	local char = getCharacter()
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

-- ============================================
-- CONFIG
-- ============================================
local Config = {
	-- Theme colors
	Theme = {
		Primary = Color3.fromRGB(25, 25, 35),
		Secondary = Color3.fromRGB(35, 35, 45),
		Accent = Color3.fromRGB(88, 101, 242),
		Success = Color3.fromRGB(67, 181, 129),
		Error = Color3.fromRGB(240, 71, 71),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(150, 150, 150),
	},
	
	-- Auto Fishing Settings
	AutoFish = {
		Enabled = false,
		InstantCatch = true,
		PerfectCatch = true,
		AutoSell = false,
		AutoEquipBestRod = true,
	},
	
	-- Auto Weather Settings
	AutoWeather = {
		Enabled = false,
		SelectedWeathers = {
			Cloudy = false,
			Wind = false,
			Snow = false,
			Storm = false,
			Radiant = false,
		},
		MaxSlots = 3,
		CheckInterval = 5, -- Check every 5 seconds
	},
	
	-- Delays (in seconds)
	Delays = {
		TalonDelay = 0.1,
		WildesDelay = 3.2,
		CastDelay = 0.5,
		SellDelay = 30,
	},
	
	-- Fishing Spots
	FishingSpots = {
		["Spawn"] = CFrame.new(-180, 145, 195),
		["Ocean"] = CFrame.new(150, 140, -200),
		["Deep Ocean"] = CFrame.new(500, 135, -400),
		["Volcano"] = CFrame.new(-350, 160, -450),
		["Ice Area"] = CFrame.new(-600, 145, 200),
		["Ancient Isle"] = CFrame.new(800, 150, 100),
		["Secret Pond"] = CFrame.new(-200, 155, 500),
	},
	
	-- Current selected spot
	SelectedSpot = "Spawn",
}

-- ============================================
-- ANTI-AFK
-- ============================================
local AntiAFK = {}
AntiAFK.Connection = nil

function AntiAFK:Enable()
	if self.Connection then return end
	
	local VirtualUser = game:GetService("VirtualUser")
	self.Connection = player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
	
	print("✅ Anti-AFK Enabled")
end

function AntiAFK:Disable()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	print("❌ Anti-AFK Disabled")
end

-- Auto-enable Anti-AFK
AntiAFK:Enable()

-- ============================================
-- WEATHER CONTROLLER
-- ============================================
local WeatherController = {}
WeatherController.Active = false
WeatherController.Connection = nil
WeatherController.Stats = {
	WeathersBought = 0,
	PointsSpent = 0,
}

-- Find Weather Machine GUI
function WeatherController:FindWeatherMachine()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Try common GUI names for weather machine
	local weatherGuis = {"WeatherMachine", "WeatherGui", "Weather", "WeatherShop"}
	for _, guiName in ipairs(weatherGuis) do
		local gui = playerGui:FindFirstChild(guiName)
		if gui then
			return gui
		end
	end
	
	return nil
end

-- Get available weather slots (0-3)
function WeatherController:GetAvailableSlots()
	local weatherGui = self:FindWeatherMachine()
	if not weatherGui then 
		print("⚠️ Weather GUI not found, assuming slots available")
		return 1 -- Always assume at least 1 slot available if can't detect
	end
	
	-- Try to find slot info from GUI
	local slotLabel = weatherGui:FindFirstChild("AvailableSlots", true) or 
	                  weatherGui:FindFirstChild("Slots", true)
	
	if slotLabel and slotLabel.Text then
		local current, max = slotLabel.Text:match("(%d+)/(%d+)")
		if current and max then
			local available = tonumber(max) - tonumber(current)
			print("📊 Detected slots:", current .. "/" .. max, "- Available:", available)
			return available
		end
	end
	
	-- Count existing weather effects in workspace
	local usedSlots = 0
	for _, obj in pairs(workspace:GetChildren()) do
		local name = obj.Name:lower()
		if name:find("weather") or name:find("storm") or name:find("rain") or name:find("snow") then
			usedSlots = usedSlots + 1
		end
	end
	
	local available = math.max(0, Config.AutoWeather.MaxSlots - usedSlots)
	print("📊 Detected", usedSlots, "active weathers -", available, "slots available")
	return available
end

-- Get current points
function WeatherController:GetPoints()
	-- Method 1: Try leaderstats (most common in Roblox games)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		for _, stat in pairs(leaderstats:GetChildren()) do
			local statName = stat.Name:lower()
			if statName:find("point") or statName:find("coin") or statName:find("money") or 
			   statName:find("cash") or statName:find("currency") then
				local value = stat.Value or 0
				print("💰 Found points in leaderstats:", stat.Name, "=", value)
				return tonumber(value) or 0
			end
		end
	end
	
	-- Method 2: Scan all GUI text labels
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			for _, obj in pairs(gui:GetDescendants()) do
				-- Only check TextLabel and TextButton, skip ImageButton
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					if obj.Text and obj.Text ~= "" then
						local text = obj.Text
						-- Look for patterns like "Points: 1000" or "💰 1000"
						local points = text:match("Points?:?%s*(%d+)") or 
						              text:match("Coins?:?%s*(%d+)") or
						              text:match("Money:?%s*(%d+)") or
						              text:match("💰%s*(%d+)") or
						              text:match("Currency:?%s*(%d+)")
						
						if points then
							local value = tonumber(points)
							print("💰 Found points in GUI:", gui.Name, "-", text, "=", value)
							return value
						end
					end
				end
			end
		end
	end
	
	-- Method 3: Check for Data folder (alternative stats)
	local dataFolder = player:FindFirstChild("Data") or player:FindFirstChild("PlayerData")
	if dataFolder then
		for _, stat in pairs(dataFolder:GetChildren()) do
			local statName = stat.Name:lower()
			if statName:find("point") or statName:find("coin") or statName:find("money") then
				local value = stat.Value or 0
				print("💰 Found points in Data:", stat.Name, "=", value)
				return tonumber(value) or 0
			end
		end
	end
	
	print("⚠️ Could not detect points - assuming unlimited")
	return 999999 -- Return high number so it doesn't stop auto-buy
end

-- Buy a specific weather
function WeatherController:BuyWeather(weatherName)
	local success = false
	print("🔍 Trying to buy weather:", weatherName)
	
	-- Method 1: Scan ALL GUIs for weather buttons (not just weather GUI)
	local playerGui = player:WaitForChild("PlayerGui")
	print("📱 Scanning all GUIs for weather buttons...")
	
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			-- Try different button name patterns
			local buttonPatterns = {
				weatherName,
				weatherName:lower(),
				weatherName:upper(),
				weatherName .. "Button",
				weatherName .. "Btn",
			}
			
			for _, pattern in ipairs(buttonPatterns) do
				local weatherButton = gui:FindFirstChild(pattern, true)
				if weatherButton then
					print("🔘 Found button in", gui.Name, ":", weatherButton.Name, "Type:", weatherButton.ClassName)
					
					if weatherButton:IsA("GuiButton") or weatherButton:IsA("TextButton") or weatherButton:IsA("ImageButton") then
						-- Try multiple click methods for maximum compatibility
						local clickAttempts = 0
						
						-- Method 1: firesignal MouseButton1Click
						if firesignal then
							pcall(function()
								firesignal(weatherButton.MouseButton1Click)
								clickAttempts = clickAttempts + 1
								print("   🖱️ Fired MouseButton1Click signal")
							end)
							task.wait(0.2)
						end
						
						-- Method 2: firesignal MouseButton1Down + MouseButton1Up
						if firesignal then
							pcall(function()
								firesignal(weatherButton.MouseButton1Down)
								task.wait(0.05)
								firesignal(weatherButton.MouseButton1Up)
								clickAttempts = clickAttempts + 1
								print("   🖱️ Fired MouseButton1Down/Up signals")
							end)
							task.wait(0.2)
						end
						
						-- Method 3: firesignal Activated
						pcall(function()
							firesignal(weatherButton.Activated)
							clickAttempts = clickAttempts + 1
							print("   🖱️ Fired Activated signal")
						end)
						task.wait(0.2)
						
						if clickAttempts > 0 then
							print("✅ Clicked weather button!", clickAttempts, "methods tried")
							success = true
							break
						end
					end
				end
			end
			
			if success then break end
		end
	end
	
	-- Method 2: Scan ALL RemoteEvents/RemoteFunctions in game
	if not success then
		print("🔍 Scanning for weather remotes...")
		local locations = {ReplicatedStorage, workspace, player.PlayerGui}
		
		for _, location in ipairs(locations) do
			for _, remote in pairs(location:GetDescendants()) do
				if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
					local remoteName = remote.Name:lower()
					
					-- Check if remote name contains weather-related keywords
					if remoteName:find("weather") or remoteName:find("purchase") or 
					   remoteName:find("buy") or remoteName:find("shop") then
						
						print("📡 Trying remote:", remote:GetFullName())
						
						-- Try different parameter formats
						local paramFormats = {
							{weatherName},
							{weatherName:lower()},
							{weatherName:upper()},
							{"Weather", weatherName},
							{"BuyWeather", weatherName},
							{weatherName, 1},
							{1, weatherName},
						}
						
						for _, params in ipairs(paramFormats) do
							local result = pcall(function()
								if remote:IsA("RemoteEvent") then
									remote:FireServer(unpack(params))
								elseif remote:IsA("RemoteFunction") then
									remote:InvokeServer(unpack(params))
								end
								success = true
							end)
							
							if result and success then
								-- Convert params to string for display
								local paramStr = ""
								for i, p in ipairs(params) do
									paramStr = paramStr .. tostring(p)
									if i < #params then paramStr = paramStr .. ", " end
								end
								print("✅ Success with remote:", remote.Name, "Params:", paramStr)
								break
							end
						end
						
						if success then break end
					end
				end
			end
			if success then break end
		end
	end
	
	-- Method 3: Try to interact with Weather Machine in workspace
	if not success then
		print("🔍 Looking for Weather Machine in workspace...")
		for _, obj in pairs(workspace:GetDescendants()) do
			local objName = obj.Name:lower()
			
			if objName:find("weather") or objName:find("machine") then
				print("🏭 Found potential machine:", obj:GetFullName())
				
				-- Try ProximityPrompt
				local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
				if prompt then
					print("🔔 Found ProximityPrompt")
					if fireproximityprompt then
						pcall(function()
							fireproximityprompt(prompt)
							success = true
						end)
						if success then
							print("✅ Fired ProximityPrompt!")
							break
						end
					end
				end
				
				-- Try ClickDetector
				local detector = obj:FindFirstChildOfClass("ClickDetector", true)
				if detector then
					print("🖱️ Found ClickDetector")
					if fireclickdetector then
						pcall(function()
							fireclickdetector(detector)
							success = true
						end)
						if success then
							print("✅ Fired ClickDetector!")
							break
						end
					end
				end
			end
		end
	end
	
	-- Method 4: Try bindable events/functions (for local scripts)
	if not success then
		print("🔍 Checking for local bindables...")
		for _, bindable in pairs(ReplicatedStorage:GetDescendants()) do
			if bindable:IsA("BindableEvent") or bindable:IsA("BindableFunction") then
				local bindName = bindable.Name:lower()
				if bindName:find("weather") or bindName:find("buy") then
					print("🔗 Trying bindable:", bindable.Name)
					pcall(function()
						if bindable:IsA("BindableEvent") then
							bindable:Fire(weatherName)
						else
							bindable:Invoke(weatherName)
						end
						success = true
					end)
					if success then break end
				end
			end
		end
	end
	
	if success then
		self.Stats.WeathersBought = self.Stats.WeathersBought + 1
		print("☁️✅ Successfully bought weather:", weatherName)
		print("   💡 Total purchases:", self.Stats.WeathersBought)
		print("   ⏱️ Waiting to verify purchase...")
		
		-- Wait a bit and check if weather appeared
		task.wait(1)
		
		-- Try to detect if weather is active in workspace
		local weatherFound = false
		for _, obj in pairs(workspace:GetChildren()) do
			local objName = obj.Name:lower()
			if objName:find(weatherName:lower()) or objName:find("weather") then
				weatherFound = true
				print("   ✅ Weather effect detected in workspace:", obj.Name)
				break
			end
		end
		
		if not weatherFound then
			print("   ⚠️ Weather effect not detected yet (might take time to load)")
		end
	else
		print("❌ Failed to buy weather:", weatherName)
	end
	
	return success
end

-- Get list of selected weathers
function WeatherController:GetSelectedWeathers()
	local selected = {}
	for weather, enabled in pairs(Config.AutoWeather.SelectedWeathers) do
		if enabled then
			table.insert(selected, weather)
		end
	end
	return selected
end

-- Update weather stats label safely
function WeatherController:UpdateStatsLabel()
	pcall(function()
		local playerGui = player:WaitForChild("PlayerGui")
		-- Find the script's GUI
		for _, gui in pairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				-- Look for the weather stats label
				local label = gui:FindFirstChild("WeathersBought", true)
				if label and label:IsA("TextLabel") then
					label.Text = "☁️ Weathers Bought: " .. self.Stats.WeathersBought
					print("📊 Updated weather stats:", self.Stats.WeathersBought)
					return
				end
			end
		end
		-- If not found, just log it
		print("⚠️ Weather stats label not found (GUI might not be loaded yet)")
	end)
end

-- Debug: List all weather-related remotes in game
function WeatherController:ListAllRemotes()
	print("=== 🔍 SCANNING ALL REMOTES ===")
	local count = 0
	
	-- Scan ReplicatedStorage
	print("\n📦 ReplicatedStorage:")
	for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
		if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
			print("  -", remote.ClassName, ":", remote:GetFullName())
			count = count + 1
		end
	end
	
	-- Scan Workspace
	print("\n🌍 Workspace:")
	for _, remote in pairs(workspace:GetDescendants()) do
		if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
			print("  -", remote.ClassName, ":", remote:GetFullName())
			count = count + 1
		end
	end
	
	-- Scan PlayerGui
	print("\n📱 PlayerGui:")
	for _, remote in pairs(player.PlayerGui:GetDescendants()) do
		if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
			print("  -", remote.ClassName, ":", remote:GetFullName())
			count = count + 1
		end
	end
	
	-- List all GUIs
	print("\n📱 All GUIs in PlayerGui:")
	for _, gui in pairs(player.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			print("  - ScreenGui:", gui.Name)
		end
	end
	
	print("\n✅ Total Remotes Found:", count)
	print("=== END SCAN ===\n")
end

-- Debug: Try to find weather machine
function WeatherController:DebugWeatherMachine()
	print("=== 🔍 DEBUGGING WEATHER MACHINE ===")
	
	-- Check PlayerGui
	local playerGui = player:WaitForChild("PlayerGui")
	print("\n📱 Checking PlayerGui for Weather GUIs...")
	
	for _, gui in pairs(playerGui:GetChildren()) do
		local guiName = gui.Name:lower()
		if guiName:find("weather") or guiName:find("shop") or guiName:find("store") then
			print("  ✅ Found potential GUI:", gui.Name)
			
			-- List all buttons in this GUI
			for _, button in pairs(gui:GetDescendants()) do
				if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
					-- Safely get text property
					local buttonText = "N/A"
					pcall(function()
						if button:IsA("TextButton") or button:IsA("TextLabel") then
							buttonText = button.Text or "N/A"
						end
					end)
					print("    🔘", button.ClassName, ":", button.Name, "- Text:", buttonText)
				end
			end
		end
	end
	
	-- Check Workspace
	print("\n🌍 Checking Workspace for Weather Machine...")
	for _, obj in pairs(workspace:GetDescendants()) do
		local objName = obj.Name:lower()
		if objName:find("weather") then
			print("  ✅ Found:", obj:GetFullName(), "- Type:", obj.ClassName)
			
			-- Check for ProximityPrompt
			local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
			if prompt then
				print("    🔔 Has ProximityPrompt:", prompt:GetFullName())
			end
			
			-- Check for ClickDetector  
			local detector = obj:FindFirstChildOfClass("ClickDetector", true)
			if detector then
				print("    🖱️ Has ClickDetector:", detector:GetFullName())
			end
		end
	end
	
	print("=== END DEBUG ===\n")
end

-- Start auto weather buying
function WeatherController:Start()
	if self.Active then return end
	
	self.Active = true
	Config.AutoWeather.Enabled = true
	print("☁️ Auto Weather Started!")
	
	task.spawn(function()
		while Config.AutoWeather.Enabled and self.Active do
			task.wait(Config.AutoWeather.CheckInterval)
			
			-- Get selected weathers
			local selectedWeathers = self:GetSelectedWeathers()
			if #selectedWeathers == 0 then
				print("⚠️ No weathers selected for auto-buy")
				task.wait(5)
				continue
			end
			
			print("\n🔄 Auto-buy cycle starting...")
			print("   Selected weathers:", table.concat(selectedWeathers, ", "))
			
			-- Check points (but don't stop if can't detect)
			local points = self:GetPoints()
			print("   💰 Current points:", points)
			
			-- Only stop if points is explicitly 0 AND detected (not 999999)
			if points == 0 then
				print("⚠️ No points detected, but continuing anyway...")
			end
			
			-- Check available slots
			local availableSlots = self:GetAvailableSlots()
			print("   📊 Available slots:", availableSlots)
			
			if availableSlots > 0 then
				-- Buy random selected weather
				local randomWeather = selectedWeathers[math.random(1, #selectedWeathers)]
				print("   🎲 Attempting to buy:", randomWeather)
				
				local success = self:BuyWeather(randomWeather)
				
				if success then
					print("   ✅ Purchase successful!")
					self:UpdateStatsLabel()
					task.wait(2) -- Wait a bit after successful purchase
				else
					print("   ❌ Purchase failed - will retry next cycle")
					task.wait(1)
				end
			else
				print("   ⏳ No slots available - waiting...")
			end
		end
		
		print("🛑 Auto weather loop ended")
	end)
end

-- Stop auto weather
function WeatherController:Stop()
	self.Active = false
	Config.AutoWeather.Enabled = false
	
	print("🛑 Auto Weather Stopped!")
end

-- ============================================
-- FISHING CONTROLLER
-- ============================================
local FishingController = {}
FishingController.CurrentRod = nil
FishingController.IsFishing = false
FishingController.LastCast = 0
FishingController.FishCaught = 0
FishingController.PerfectCatches = 0
FishingController.LastSellTime = 0
FishingController.CastConnection = nil
FishingController.BiteDetector = nil

-- Find the fishing rod in player's inventory/character
function FishingController:FindRod()
	local character = getCharacter()
	
	-- Check character first
	if character then
		for _, item in pairs(character:GetChildren()) do
			if item:IsA("Tool") then
				local name = item.Name:lower()
				if name:find("rod") or name:find("fishing") or name:find("pole") then
					return item
				end
			end
		end
	end
	
	-- Check backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in pairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				local name = item.Name:lower()
				if name:find("rod") or name:find("fishing") or name:find("pole") then
					return item
				end
			end
		end
	end
	
	return nil
end

-- Equip the fishing rod
function FishingController:EquipRod()
	local rod = self:FindRod()
	local character = getCharacter()
	if not character then return false end
	
	if rod and rod.Parent ~= character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:EquipTool(rod)
			task.wait(0.3)
			self.CurrentRod = rod
			return true
		end
	elseif rod and rod.Parent == character then
		self.CurrentRod = rod
		return true
	end
	return false
end

-- Cast the fishing rod
function FishingController:Cast()
	if not self.CurrentRod then
		if not self:EquipRod() then
			return false
		end
	end
	
	local now = tick()
	if now - self.LastCast < Config.Delays.CastDelay then
		return false
	end
	
	local tool = self.CurrentRod
	local casted = false
	
	-- Method 1: Try RemoteEvents in tool
	if tool:FindFirstChild("events") then
		local events = tool.events
		if events:FindFirstChild("cast") then
			pcall(function()
				events.cast:FireServer(100)
			end)
			casted = true
		elseif events:FindFirstChild("Cast") then
			pcall(function()
				events.Cast:FireServer(100)
			end)
			casted = true
		end
	end
	
	-- Method 2: Try RemoteEvent in ReplicatedStorage
	local repStorage = game:GetService("ReplicatedStorage")
	for _, remote in pairs(repStorage:GetDescendants()) do
		if remote:IsA("RemoteEvent") then
			local name = remote.Name:lower()
			if name:find("cast") or name:find("fish") then
				pcall(function()
					remote:FireServer()
				end)
				casted = true
				break
			end
		end
	end
	
	-- Method 3: Tool Activation
	if tool then
		pcall(function()
			tool:Activate()
		end)
		casted = true
	end
	
	if casted then
		self.LastCast = now
		self.IsFishing = true
		print("🎣 Cast successful!")
	end
	
	return casted
end

-- Detect fish bite and catch it
function FishingController:CheckForBite()
	if not self.CurrentRod then return false end
	
	-- Method 1: Look for bobber in workspace
	local bobber = nil
	for _, obj in pairs(workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if name:find("bob") or name:find("float") or name:find("hook") or name:find("bait") then
			if obj:IsA("Part") or obj:IsA("Model") then
				bobber = obj
				break
			end
		end
	end
	
	-- Method 2: Check GUI prompts
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in pairs(playerGui:GetDescendants()) do
		if gui:IsA("TextLabel") or gui:IsA("TextButton") then
			local text = gui.Text:lower()
			if text:find("reel") or text:find("catch") or text:find("!") then
				if gui.Visible then
					print("🐟 Fish detected via GUI!")
					return self:CatchFish()
				end
			end
		end
	end
	
	-- Method 3: Check bobber for bite indicators
	if bobber then
		-- Check for particle effects
		for _, child in pairs(bobber:GetDescendants()) do
			if child:IsA("ParticleEmitter") and child.Enabled then
				print("🐟 Fish detected via particles!")
				return self:CatchFish()
			end
			
			-- Check for sound
			if child:IsA("Sound") and child.Playing then
				print("🐟 Fish detected via sound!")
				return self:CatchFish()
			end
		end
		
		-- Check for ProximityPrompt
		local proximityPrompt = bobber:FindFirstChildOfClass("ProximityPrompt", true)
		if proximityPrompt and proximityPrompt.Enabled then
			print("🐟 Fish detected via proximity!")
			return self:CatchFish()
		end
		
		-- Check for ClickDetector
		local clickDetector = bobber:FindFirstChildOfClass("ClickDetector", true)
		if clickDetector then
			print("🐟 Fish detected via click detector!")
			return self:CatchFish()
		end
	end
	
	return false
end

-- Catch the fish (reel in)
function FishingController:CatchFish()
	if not self.CurrentRod then return false end
	
	-- Apply perfect timing delay
	if Config.AutoFish.PerfectCatch then
		task.wait(Config.Delays.TalonDelay)
	end
	
	local tool = self.CurrentRod
	local caught = false
	
	-- Method 1: Fire reel RemoteEvent
	if tool:FindFirstChild("events") then
		local events = tool.events
		if events:FindFirstChild("reel") then
			pcall(function()
				events.reel:FireServer()
			end)
			caught = true
		elseif events:FindFirstChild("Reel") then
			pcall(function()
				events.Reel:FireServer()
			end)
			caught = true
		elseif events:FindFirstChild("catch") then
			pcall(function()
				events.catch:FireServer()
			end)
			caught = true
		end
	end
	
	-- Method 2: Try RemoteEvents in ReplicatedStorage
	local repStorage = game:GetService("ReplicatedStorage")
	for _, remote in pairs(repStorage:GetDescendants()) do
		if remote:IsA("RemoteEvent") then
			local name = remote.Name:lower()
			if name:find("reel") or name:find("catch") or name:find("fish") then
				pcall(function()
					remote:FireServer()
				end)
				caught = true
				break
			end
		end
	end
	
	-- Method 3: Fire ProximityPrompt
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			pcall(function()
				fireproximityprompt(obj)
			end)
			caught = true
			break
		end
	end
	
	-- Method 4: Click ClickDetector
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("ClickDetector") then
			local parent = obj.Parent
			if parent then
				pcall(function()
					fireclickdetector(obj)
				end)
				caught = true
				break
			end
		end
	end
	
	-- Method 5: Deactivate/Activate tool
	if tool then
		pcall(function()
			tool:Deactivate()
			task.wait(0.05)
			tool:Activate()
		end)
		caught = true
	end
	
	if caught then
		self.FishCaught = self.FishCaught + 1
		if Config.AutoFish.PerfectCatch then
			self.PerfectCatches = self.PerfectCatches + 1
		end
		self.IsFishing = false
		print("✅ Fish caught! Total: " .. self.FishCaught)
	end
	
	return caught
end

-- Auto sell caught fish
function FishingController:SellFish()
	local now = tick()
	if now - self.LastSellTime < Config.Delays.SellDelay then
		return false
	end
	
	local humanoidRootPart = getHRP()
	if not humanoidRootPart then return false end
	
	-- Find the sell NPC or area
	local sellPart = workspace:FindFirstChild("SellArea") or workspace:FindFirstChild("Merchant")
	
	if not sellPart then
		-- Look in NPCs folder
		local npcs = workspace:FindFirstChild("NPCs")
		if npcs then
			sellPart = npcs:FindFirstChild("Merchant") or npcs:FindFirstChild("Seller")
		end
	end
	
	if sellPart then
		-- Save current position
		local originalPos = humanoidRootPart.CFrame
		
		-- Teleport to sell area
		local sellCFrame
		if sellPart:IsA("Model") then
			sellCFrame = sellPart:GetPivot()
		else
			sellCFrame = sellPart.CFrame
		end
		
		humanoidRootPart.CFrame = sellCFrame * CFrame.new(0, 3, 0)
		task.wait(0.5)
		
		-- Find and activate ProximityPrompt or fire remote
		local prompt = sellPart:FindFirstChildOfClass("ProximityPrompt", true)
		if prompt then
			fireproximityprompt(prompt)
		end
		
		-- Fire sell remote if exists
		if ReplicatedStorage:FindFirstChild("Events") then
			local events = ReplicatedStorage.Events
			if events:FindFirstChild("SellFish") then
				events.SellFish:FireServer()
			end
		end
		
		task.wait(1)
		
		-- Return to original position
		humanoidRootPart.CFrame = originalPos
		
		self.LastSellTime = now
		return true
	end
	
	return false
end

-- Main auto fishing loop
-- Main auto fishing loop
function FishingController:StartAutoFish()
	Config.AutoFish.Enabled = true
	print("🎣 Auto Fishing Started!")
	
	task.spawn(function()
		while Config.AutoFish.Enabled do
			local character = getCharacter()
			
			-- Equip rod if needed
			if not self.CurrentRod or (character and self.CurrentRod.Parent ~= character) then
				if self:EquipRod() then
					print("🎣 Rod equipped")
					task.wait(0.5)
				else
					print("⚠️ No fishing rod found!")
					task.wait(3)
					continue
				end
			end
			
			-- Cast if not fishing
			if not self.IsFishing then
				local success = self:Cast()
				if success then
					task.wait(0.3) -- Wait for cast animation
				else
					task.wait(1)
					continue
				end
			end
			
			-- Check for bite with appropriate timing
			if Config.AutoFish.InstantCatch then
				-- Instant mode: check frequently
				for i = 1, 20 do
					if not Config.AutoFish.Enabled then break end
					if self:CheckForBite() then
						break
					end
					task.wait(0.1)
				end
			else
				-- Normal mode: wait for natural bite
				for i = 1, 10 do
					if not Config.AutoFish.Enabled then break end
					if self:CheckForBite() then
						break
					end
					task.wait(0.5)
				end
			end
			
			-- Reset fishing state
			self.IsFishing = false
			
			-- Auto sell periodically
			if Config.AutoFish.AutoSell then
				local now = tick()
				if now - self.LastSellTime >= Config.Delays.SellDelay then
					print("💰 Auto selling...")
					self:SellFish()
				end
			end
			
			-- Wait before next cast
			task.wait(Config.Delays.CastDelay)
		end
	end)
end

function FishingController:StopAutoFish()
	Config.AutoFish.Enabled = false
	self.IsFishing = false
	print("🛑 Auto Fishing Stopped!")
end

-- ============================================
-- TELEPORT CONTROLLER
-- ============================================
local TeleportController = {}

function TeleportController:TeleportTo(spotName)
	local cframe = Config.FishingSpots[spotName]
	local humanoidRootPart = getHRP()
	if cframe and humanoidRootPart then
		humanoidRootPart.CFrame = cframe
		Config.SelectedSpot = spotName
		return true
	end
	return false
end

function TeleportController:AddCustomSpot(name)
	local humanoidRootPart = getHRP()
	if humanoidRootPart then
		Config.FishingSpots[name] = humanoidRootPart.CFrame
		return true
	end
	return false
end

-- ============================================
-- GUI
-- ============================================
print("🔨 Creating GUI...")
local GUI = {}
GUI.IsOpen = false
GUI.Elements = {}

local playerGui = player:WaitForChild("PlayerGui")
print("✅ PlayerGui loaded")

-- Remove old GUI if exists
if playerGui:FindFirstChild("FishItGUI") then
	playerGui.FishItGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishItGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Floating Toggle Button
local toggleButton = Instance.new("ImageButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(1, -80, 0.5, -30)
toggleButton.BackgroundColor3 = Config.Theme.Accent
toggleButton.BorderSizePixel = 0
toggleButton.AutoButtonColor = false
toggleButton.Parent = screenGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 30)
toggleCorner.Parent = toggleButton

local toggleIcon = Instance.new("TextLabel")
toggleIcon.Size = UDim2.new(1, 0, 1, 0)
toggleIcon.BackgroundTransparency = 1
toggleIcon.Text = "🎣"
toggleIcon.TextSize = 32
toggleIcon.Font = Enum.Font.GothamBold
toggleIcon.Parent = toggleButton

print("✅ Floating button created")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
mainFrame.BackgroundColor3 = Config.Theme.Primary
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Make draggable
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainFrame.InputBegan:Connect(function(input)
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

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Config.Theme.Secondary
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Config.Theme.Secondary
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -120, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎣 Fish It - Auto Farm"
titleLabel.TextColor3 = Config.Theme.Text
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0.5, -20)
closeButton.BackgroundColor3 = Config.Theme.Error
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
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, -30, 0, 25)
watermark.Position = UDim2.new(0, 15, 0, 55)
watermark.BackgroundTransparency = 1
watermark.Text = "⚡ Made by TwoHand Comunity | discord.gg/xHrJaSgy"
watermark.TextColor3 = Config.Theme.TextDark
watermark.TextSize = 11
watermark.Font = Enum.Font.Gotham
watermark.TextXAlignment = Enum.TextXAlignment.Left
watermark.Parent = mainFrame

-- Tab System
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(0, 150, 1, -90)
tabContainer.Position = UDim2.new(0, 10, 0, 85)
tabContainer.BackgroundColor3 = Config.Theme.Secondary
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 8)
tabCorner.Parent = tabContainer

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabContainer

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 10)
tabPadding.PaddingBottom = UDim.new(0, 10)
tabPadding.PaddingLeft = UDim.new(0, 10)
tabPadding.PaddingRight = UDim.new(0, 10)
tabPadding.Parent = tabContainer

-- Content Container
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, -180, 1, -90)
contentContainer.Position = UDim2.new(0, 170, 0, 85)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.Parent = mainFrame

-- Helper: Create Tab Button
local currentTab = nil
local function createTabButton(name, icon, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Size = UDim2.new(1, 0, 0, 40)
	button.BackgroundColor3 = Config.Theme.Primary
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.LayoutOrder = order
	button.Parent = tabContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = icon .. " " .. name
	label.TextColor3 = Config.Theme.Text
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = button
	
	return button
end

-- Helper: Create Tab Content
local function createTabContent(name)
	local content = Instance.new("ScrollingFrame")
	content.Name = name .. "Content"
	content.Size = UDim2.new(1, -10, 1, 0)
	content.BackgroundColor3 = Config.Theme.Secondary
	content.BorderSizePixel = 0
	content.Visible = false
	content.ScrollBarThickness = 6
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = contentContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = content
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = content
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 15)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingRight = UDim.new(0, 15)
	padding.Parent = content
	
	return content
end

-- Helper: Create Toggle Button
local function createToggle(parent, text, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundColor3 = Config.Theme.Primary
	container.BorderSizePixel = 0
	container.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Config.Theme.Text
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 50, 0, 25)
	toggle.Position = UDim2.new(1, -60, 0.5, -12.5)
	toggle.BackgroundColor3 = default and Config.Theme.Success or Config.Theme.TextDark
	toggle.BorderSizePixel = 0
	toggle.Text = ""
	toggle.Parent = container
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggle
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 19, 0, 19)
	toggleCircle.Position = default and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggle
	
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = toggleCircle
	
	local enabled = default
	
	toggle.MouseButton1Click:Connect(function()
		enabled = not enabled
		callback(enabled)
		
		TweenService:Create(toggle, TweenInfo.new(0.2), {
			BackgroundColor3 = enabled and Config.Theme.Success or Config.Theme.TextDark
		}):Play()
		
		TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
			Position = enabled and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5)
		}):Play()
	end)
	
	return container
end

-- Helper: Create Slider
local function createSlider(parent, text, min, max, default, suffix, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 60)
	container.BackgroundColor3 = Config.Theme.Primary
	container.BorderSizePixel = 0
	container.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 25)
	label.Position = UDim2.new(0, 10, 0, 5)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Config.Theme.Text
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 60, 0, 25)
	valueLabel.Position = UDim2.new(1, -70, 0, 5)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default) .. suffix
	valueLabel.TextColor3 = Config.Theme.Accent
	valueLabel.TextSize = 14
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container
	
	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(1, -20, 0, 6)
	sliderBack.Position = UDim2.new(0, 10, 1, -20)
	sliderBack.BackgroundColor3 = Config.Theme.Secondary
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = container
	
	local sliderBackCorner = Instance.new("UICorner")
	sliderBackCorner.CornerRadius = UDim.new(1, 0)
	sliderBackCorner.Parent = sliderBack
	
	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Config.Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBack
	
	local sliderFillCorner = Instance.new("UICorner")
	sliderFillCorner.CornerRadius = UDim.new(1, 0)
	sliderFillCorner.Parent = sliderFill
	
	local draggingSlider = false
	
	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
		end
	end)
	
	sliderBack.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = UserInputService:GetMouseLocation().X
			local sliderPos = sliderBack.AbsolutePosition.X
			local sliderSize = sliderBack.AbsoluteSize.X
			
			local percent = math.clamp((mousePos - sliderPos) / sliderSize, 0, 1)
			local value = math.floor(min + (max - min) * percent)
			
			sliderFill.Size = UDim2.new(percent, 0, 1, 0)
			valueLabel.Text = tostring(value) .. suffix
			callback(value)
		end
	end)
	
	return container
end

-- Helper: Create Button
local function createButton(parent, text, icon, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 45)
	button.BackgroundColor3 = Config.Theme.Accent
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = icon .. " " .. text
	label.TextColor3 = Config.Theme.Text
	label.TextSize = 15
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = button
	
	button.MouseButton1Click:Connect(callback)
	
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(
				Config.Theme.Accent.R * 255 + 20,
				Config.Theme.Accent.G * 255 + 20,
				Config.Theme.Accent.B * 255 + 20
			)
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Config.Theme.Accent
		}):Play()
	end)
	
	return button
end

-- Helper: Create Info Label
local function createInfoLabel(parent, text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundColor3 = Config.Theme.Primary
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = Config.Theme.TextDark
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = label
	
	return label
end

-- Create Tabs
local mainTab = createTabButton("Main", "🏠", 1)
local teleportTab = createTabButton("Teleport", "📍", 2)
local automationTab = createTabButton("Automation", "⚙️", 3)
local settingsTab = createTabButton("Settings", "🔧", 4)

print("✅ Tab buttons created")

-- Create Tab Contents
local mainContent = createTabContent("Main")
local teleportContent = createTabContent("Teleport")
local automationContent = createTabContent("Automation")
local settingsContent = createTabContent("Settings")

print("✅ Tab contents created")

-- Main Tab Content
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, 0, 0, 120)
statsFrame.BackgroundColor3 = Config.Theme.Primary
statsFrame.BorderSizePixel = 0
statsFrame.Parent = mainContent

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 6)
statsCorner.Parent = statsFrame

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, -20, 0, 25)
statsTitle.Position = UDim2.new(0, 10, 0, 10)
statsTitle.BackgroundTransparency = 1
statsTitle.Text = "📊 Statistics"
statsTitle.TextColor3 = Config.Theme.Accent
statsTitle.TextSize = 16
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = statsFrame

local fishCaughtLabel = Instance.new("TextLabel")
fishCaughtLabel.Size = UDim2.new(1, -20, 0, 25)
fishCaughtLabel.Position = UDim2.new(0, 10, 0, 40)
fishCaughtLabel.BackgroundTransparency = 1
fishCaughtLabel.Text = "🎣 Fish Caught: 0"
fishCaughtLabel.TextColor3 = Config.Theme.Text
fishCaughtLabel.TextSize = 14
fishCaughtLabel.Font = Enum.Font.Gotham
fishCaughtLabel.TextXAlignment = Enum.TextXAlignment.Left
fishCaughtLabel.Parent = statsFrame

GUI.Elements.FishCaughtLabel = fishCaughtLabel

local perfectCatchLabel = Instance.new("TextLabel")
perfectCatchLabel.Size = UDim2.new(1, -20, 0, 25)
perfectCatchLabel.Position = UDim2.new(0, 10, 0, 65)
perfectCatchLabel.BackgroundTransparency = 1
perfectCatchLabel.Text = "⭐ Perfect Catches: 0"
perfectCatchLabel.TextColor3 = Config.Theme.Text
perfectCatchLabel.TextSize = 14
perfectCatchLabel.Font = Enum.Font.Gotham
perfectCatchLabel.TextXAlignment = Enum.TextXAlignment.Left
perfectCatchLabel.Parent = statsFrame

GUI.Elements.PerfectCatchLabel = perfectCatchLabel

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 90)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Config.Theme.TextDark
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statsFrame

GUI.Elements.StatusLabel = statusLabel

createToggle(mainContent, "🎣 Auto Fishing", false, function(enabled)
	if enabled then
		FishingController:StartAutoFish()
		GUI.Elements.StatusLabel.Text = "Status: Auto Fishing Active 🟢"
		GUI.Elements.StatusLabel.TextColor3 = Config.Theme.Success
	else
		FishingController:StopAutoFish()
		GUI.Elements.StatusLabel.Text = "Status: Idle 🔴"
		GUI.Elements.StatusLabel.TextColor3 = Config.Theme.TextDark
	end
end)

createToggle(mainContent, "⚡ Instant Catch", true, function(enabled)
	Config.AutoFish.InstantCatch = enabled
end)

createToggle(mainContent, "⭐ Perfect Catch", true, function(enabled)
	Config.AutoFish.PerfectCatch = enabled
end)

createButton(mainContent, "Sell All Fish", "💰", function()
	FishingController:SellFish()
end)

-- Teleport Tab Content
createInfoLabel(teleportContent, "📍 Click a location to teleport instantly")

for spotName, _ in pairs(Config.FishingSpots) do
	createButton(teleportContent, spotName, "📍", function()
		TeleportController:TeleportTo(spotName)
	end)
end

createButton(teleportContent, "Save Current Position", "💾", function()
	local success = TeleportController:AddCustomSpot("Custom Spot " .. #Config.FishingSpots + 1)
	if success then
		print("✅ Custom spot saved!")
	end
end)

-- Automation Tab Content
createToggle(automationContent, "💰 Auto Sell Fish", false, function(enabled)
	Config.AutoFish.AutoSell = enabled
end)

createSlider(automationContent, "Sell Interval", 10, 120, 30, "s", function(value)
	Config.Delays.SellDelay = value
end)

createToggle(automationContent, "🛡️ Anti AFK", true, function(enabled)
	if enabled then
		AntiAFK:Enable()
	else
		AntiAFK:Disable()
	end
end)

createInfoLabel(automationContent, "ℹ️ Auto Sell will teleport you to merchant periodically")

-- Weather Section
local weatherTitle = Instance.new("TextLabel")
weatherTitle.Size = UDim2.new(1, -20, 0, 30)
weatherTitle.BackgroundTransparency = 1
weatherTitle.Text = "☁️ Auto Weather"
weatherTitle.TextColor3 = Config.Theme.Accent
weatherTitle.TextSize = 16
weatherTitle.Font = Enum.Font.GothamBold
weatherTitle.TextXAlignment = Enum.TextXAlignment.Left
weatherTitle.Parent = automationContent

createToggle(automationContent, "🌤️ Enable Auto Buy Weather", false, function(enabled)
	if enabled then
		-- Check if any weather is selected
		local hasSelection = false
		for _, selected in pairs(Config.AutoWeather.SelectedWeathers) do
			if selected then
				hasSelection = true
				break
			end
		end
		
		if not hasSelection then
			print("⚠️ Please select at least one weather to buy!")
			return
		end
		
		WeatherController:Start()
	else
		WeatherController:Stop()
	end
end)

-- Weather selection checkboxes
local weatherList = {"Cloudy", "Wind", "Snow", "Storm", "Radiant"}
local weatherIcons = {
	Cloudy = "☁️",
	Wind = "💨",
	Snow = "❄️",
	Storm = "⛈️",
	Radiant = "✨",
}

for _, weatherName in ipairs(weatherList) do
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 35)
	container.BackgroundColor3 = Config.Theme.Secondary
	container.BorderSizePixel = 0
	container.Parent = automationContent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container
	
	local checkbox = Instance.new("TextButton")
	checkbox.Size = UDim2.new(0, 25, 0, 25)
	checkbox.Position = UDim2.new(0, 10, 0.5, -12.5)
	checkbox.BackgroundColor3 = Config.Theme.Primary
	checkbox.BorderSizePixel = 0
	checkbox.Text = ""
	checkbox.Parent = container
	
	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(0, 4)
	checkCorner.Parent = checkbox
	
	local checkmark = Instance.new("TextLabel")
	checkmark.Size = UDim2.new(1, 0, 1, 0)
	checkmark.BackgroundTransparency = 1
	checkmark.Text = ""
	checkmark.TextColor3 = Config.Theme.Success
	checkmark.TextSize = 18
	checkmark.Font = Enum.Font.GothamBold
	checkmark.Parent = checkbox
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -50, 1, 0)
	label.Position = UDim2.new(0, 45, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = weatherIcons[weatherName] .. " " .. weatherName
	label.TextColor3 = Config.Theme.Text
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	
	checkbox.MouseButton1Click:Connect(function()
		Config.AutoWeather.SelectedWeathers[weatherName] = not Config.AutoWeather.SelectedWeathers[weatherName]
		checkmark.Text = Config.AutoWeather.SelectedWeathers[weatherName] and "✓" or ""
		
		TweenService:Create(checkbox, TweenInfo.new(0.2), {
			BackgroundColor3 = Config.AutoWeather.SelectedWeathers[weatherName] and Config.Theme.Success or Config.Theme.Primary
		}):Play()
	end)
end

-- Weather stats
local weatherStatsLabel = Instance.new("TextLabel")
weatherStatsLabel.Name = "WeathersBought"
weatherStatsLabel.Size = UDim2.new(1, -20, 0, 25)
weatherStatsLabel.BackgroundTransparency = 1
weatherStatsLabel.Text = "☁️ Weathers Bought: 0"
weatherStatsLabel.TextColor3 = Config.Theme.TextDark
weatherStatsLabel.TextSize = 12
weatherStatsLabel.Font = Enum.Font.Gotham
weatherStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
weatherStatsLabel.Parent = automationContent

GUI.Elements.WeathersBoughtLabel = weatherStatsLabel

createInfoLabel(automationContent, "ℹ️ Max 3 weather slots. Auto re-buy when time expires")

-- Settings Tab Content
createSlider(settingsContent, "Cast Delay", 0.1, 5, 0.5, "s", function(value)
	Config.Delays.CastDelay = value
end)

createSlider(settingsContent, "Talon Delay (Perfect Timing)", 0.05, 1, 0.1, "s", function(value)
	Config.Delays.TalonDelay = value
end)

createSlider(settingsContent, "Wildes Delay", 1, 10, 3.2, "s", function(value)
	Config.Delays.WildesDelay = value
end)

createInfoLabel(settingsContent, "⚙️ Lower delays = faster but might be detectable")

createButton(settingsContent, "Reset to Default", "♻️", function()
	Config.Delays.CastDelay = 0.5
	Config.Delays.TalonDelay = 0.1
	Config.Delays.WildesDelay = 3.2
	Config.Delays.SellDelay = 30
	print("✅ Settings reset to default")
end)

-- Debug Section
local debugTitle = Instance.new("TextLabel")
debugTitle.Size = UDim2.new(1, -20, 0, 30)
debugTitle.BackgroundTransparency = 1
debugTitle.Text = "🐛 Debug Tools"
debugTitle.TextColor3 = Config.Theme.Accent
debugTitle.TextSize = 16
debugTitle.Font = Enum.Font.GothamBold
debugTitle.TextXAlignment = Enum.TextXAlignment.Left
debugTitle.Parent = settingsContent

createButton(settingsContent, "List All Remotes", "📡", function()
	WeatherController:ListAllRemotes()
	print("✅ Check console for remote list!")
end)

createButton(settingsContent, "Debug Weather Machine", "☁️", function()
	WeatherController:DebugWeatherMachine()
	print("✅ Check console for weather debug info!")
end)

createButton(settingsContent, "Test Buy Weather (Cloudy)", "🧪", function()
	print("🧪 Testing manual weather buy...")
	local success = WeatherController:BuyWeather("Cloudy")
	if success then
		print("✅ Test successful!")
	else
		print("❌ Test failed - check debug info above")
	end
end)

createInfoLabel(settingsContent, "ℹ️ Debug tools print info to executor console (F9)")

-- Tab Switching Logic
local function switchTab(tab, content)
	-- Hide all content
	for _, child in pairs(contentContainer:GetChildren()) do
		if child:IsA("ScrollingFrame") then
			child.Visible = false
		end
	end
	
	-- Reset all tab colors
	for _, child in pairs(tabContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child.BackgroundColor3 = Config.Theme.Primary
		end
	end
	
	-- Show selected content and highlight tab
	content.Visible = true
	tab.BackgroundColor3 = Config.Theme.Accent
	currentTab = tab
end

mainTab.MouseButton1Click:Connect(function() switchTab(mainTab, mainContent) end)
teleportTab.MouseButton1Click:Connect(function() switchTab(teleportTab, teleportContent) end)
automationTab.MouseButton1Click:Connect(function() switchTab(automationTab, automationContent) end)
settingsTab.MouseButton1Click:Connect(function() switchTab(settingsTab, settingsContent) end)

-- Default tab
switchTab(mainTab, mainContent)

-- Toggle Button Functionality
toggleButton.MouseButton1Click:Connect(function()
	GUI.IsOpen = not GUI.IsOpen
	mainFrame.Visible = GUI.IsOpen
	
	if GUI.IsOpen then
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 700, 0, 500)
		}):Play()
	end
end)

closeButton.MouseButton1Click:Connect(function()
	GUI.IsOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	task.wait(0.2)
	mainFrame.Visible = false
end)

-- Update Statistics Loop
task.spawn(function()
	while task.wait(0.5) do
		if GUI.Elements.FishCaughtLabel then
			GUI.Elements.FishCaughtLabel.Text = "🎣 Fish Caught: " .. FishingController.FishCaught
		end
		if GUI.Elements.PerfectCatchLabel then
			GUI.Elements.PerfectCatchLabel.Text = "⭐ Perfect Catches: " .. FishingController.PerfectCatches
		end
	end
end)

-- ============================================
-- INITIALIZATION
-- ============================================
print("✅ Fish It Auto Farm Loaded Successfully!")
print("🎣 Click the floating button to open the menu")
print("💬 Join our Discord: discord.gg/xHrJaSgy")
print("⚡ Made by TwoHand Comunity")

-- Auto-scan for remotes on startup (helps with debugging)
print("\n🔍 Auto-scanning game remotes for weather system...")
task.spawn(function()
	task.wait(2) -- Wait a bit for game to load
	WeatherController:ListAllRemotes()
	WeatherController:DebugWeatherMachine()
	print("\n💡 TIP: Go to Settings tab and use Debug Tools to re-scan anytime!")
end)

end) -- End of pcall

if not success then
	warn("❌ ERROR LOADING SCRIPT: " .. tostring(errorMsg))
	warn("Please report this error to discord.gg/xHrJaSgy")
end
