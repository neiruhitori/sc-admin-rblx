--[[
	Admin Commands Server Handler
	Menangani semua admin commands dari client
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage.Shared.AdminConfig)
local AdminRemote = require(ReplicatedStorage.Shared.AdminRemote)

local AdminCommands = {}
AdminCommands.Commands = {}
AdminCommands.PlayerStatus = {} -- Track player status (god, fly, invis, etc)
AdminCommands.GodModeConnections = {} -- Track connections for god mode

-- Helper function to get or create player status
local function getPlayerStatus(playerName: string)
	if not AdminCommands.PlayerStatus[playerName] then
		AdminCommands.PlayerStatus[playerName] = {
			GodMode = false,
			Flying = false,
			Invisible = false,
			Frozen = false,
		}
	end
	return AdminCommands.PlayerStatus[playerName]
end

-- Helper function to enable god mode with proper protection
local function enableGodMode(player: Player)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Clean up existing connections
	if AdminCommands.GodModeConnections[player.UserId] then
		for _, conn in ipairs(AdminCommands.GodModeConnections[player.UserId]) do
			conn:Disconnect()
		end
	end
	AdminCommands.GodModeConnections[player.UserId] = {}
	
	-- Set health to huge
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	
	-- Connect to HealthChanged to constantly restore health
	local healthConn = humanoid.HealthChanged:Connect(function(health)
		if health < humanoid.MaxHealth then
			humanoid.Health = math.huge
		end
	end)
	table.insert(AdminCommands.GodModeConnections[player.UserId], healthConn)
	
	-- Connect to Died to prevent death
	local diedConn = humanoid.Died:Connect(function()
		if getPlayerStatus(player.Name).GodMode then
			task.wait()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.Health = math.huge
		end
	end)
	table.insert(AdminCommands.GodModeConnections[player.UserId], diedConn)
	
	-- Prevent humanoid from entering dead state
	local stateConn = humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Dead and getPlayerStatus(player.Name).GodMode then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.Health = math.huge
		end
	end)
	table.insert(AdminCommands.GodModeConnections[player.UserId], stateConn)
	
	getPlayerStatus(player.Name).GodMode = true
end

-- Helper function to disable god mode
local function disableGodMode(player: Player)
	-- Disconnect all god mode connections
	if AdminCommands.GodModeConnections[player.UserId] then
		for _, conn in ipairs(AdminCommands.GodModeConnections[player.UserId]) do
			conn:Disconnect()
		end
		AdminCommands.GodModeConnections[player.UserId] = nil
	end
	
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = 100
			humanoid.Health = 100
		end
	end
	
	getPlayerStatus(player.Name).GodMode = false
end

-- Helper function untuk find player by name
local function findPlayer(name: string): Player?
	name = name:lower()
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #name) == name or player.DisplayName:lower():sub(1, #name) == name then
			return player
		end
	end
	
	return nil
end

-- Helper function untuk send notification
local function notify(player: Player, message: string, notifType: string?)
	AdminRemote.Notify:FireClient(player, message, notifType or "info")
end

-- ==================== COMMANDS ====================

-- Kill command
AdminCommands.Commands.kill = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;kill <player>", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local character = target.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
			notify(executor, "Killed " .. target.Name, "success")
		end
	end
end

-- Kick command
AdminCommands.Commands.kick = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;kick <player> [reason]", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local reason = table.concat(args, " ", 2) or "Kicked by an admin"
	target:Kick(reason)
	notify(executor, "Kicked " .. target.Name, "success")
end

-- Teleport to player
AdminCommands.Commands.tp = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;tp <player>", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local executorChar = executor.Character
	local targetChar = target.Character
	
	if executorChar and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
		local hrp = executorChar:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = targetChar.HumanoidRootPart.CFrame
			notify(executor, "Teleported to " .. target.Name, "success")
		end
	end
end

-- Bring player to you
AdminCommands.Commands.bring = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;bring <player>", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local executorChar = executor.Character
	local targetChar = target.Character
	
	if executorChar and targetChar and executorChar:FindFirstChild("HumanoidRootPart") then
		local hrp = targetChar:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = executorChar.HumanoidRootPart.CFrame
			notify(executor, "Brought " .. target.Name, "success")
		end
	end
end

-- Speed command
AdminCommands.Commands.speed = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;speed <number> [player]", "error")
		return
	end
	
	local speed = tonumber(args[1])
	if not speed then
		notify(executor, "Invalid speed value!", "error")
		return
	end
	
	local target = executor
	if args[2] then
		target = findPlayer(args[2])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	local character = target.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speed
			notify(executor, "Set speed to " .. speed .. " for " .. target.Name, "success")
		end
	end
end

-- Jump power command
AdminCommands.Commands.jp = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;jp <number> [player]", "error")
		return
	end
	
	local jumpValue = tonumber(args[1])
	if not jumpValue then
		notify(executor, "Invalid jump value!", "error")
		return
	end
	
	local target = executor
	if args[2] then
		target = findPlayer(args[2])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	local character = target.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Use JumpHeight (modern) or JumpPower (legacy)
			if humanoid.UseJumpPower then
				humanoid.JumpPower = jumpValue
			else
				humanoid.JumpHeight = jumpValue
			end
			notify(executor, "Set jump to " .. jumpValue .. " for " .. target.Name, "success")
		end
	end
end

-- God mode
AdminCommands.Commands.god = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	if target.Character then
		enableGodMode(target)
		notify(executor, "God mode enabled for " .. target.Name .. " (true invincibility)", "success")
	else
		notify(executor, "Character not found!", "error")
	end
end

-- Ungod mode
AdminCommands.Commands.ungod = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	disableGodMode(target)
	notify(executor, "God mode disabled for " .. target.Name, "success")
end

-- Respawn command
AdminCommands.Commands.respawn = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	target:LoadCharacter()
	notify(executor, "Respawned " .. target.Name, "success")
end

-- Invisible command
AdminCommands.Commands.invis = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	local character = target.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 1
				if part.Name == "Head" then
					local face = part:FindFirstChildOfClass("Decal")
					if face then
						face.Transparency = 1
					end
				end
			elseif part:IsA("Accessory") then
				local handle = part:FindFirstChild("Handle")
				if handle then
					handle.Transparency = 1
				end
			end
		end
		getPlayerStatus(target.Name).Invisible = true
		notify(executor, "Made " .. target.Name .. " invisible", "success")
	end
end

-- Visible command
AdminCommands.Commands.vis = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	local character = target.Character
	if character then
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
				if part.Name == "Head" then
					local face = part:FindFirstChildOfClass("Decal")
					if face then
						face.Transparency = 0
					end
				end
			elseif part:IsA("Decal") or part:IsA("Texture") then
				part.Transparency = 0
			end
		end
		
		-- Handle accessories more thoroughly
		for _, accessory in ipairs(character:GetChildren()) do
			if accessory:IsA("Accessory") then
				for _, desc in ipairs(accessory:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Transparency = 0
					end
				end
			end
		end
		
		getPlayerStatus(target.Name).Invisible = false
		notify(executor, "Made " .. target.Name .. " visible", "success")
	end
end

-- Freeze command
AdminCommands.Commands.freeze = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;freeze <player>", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local character = target.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = true
			getPlayerStatus(target.Name).Frozen = true
			notify(executor, "Froze " .. target.Name, "success")
		end
	end
end

-- Unfreeze command
AdminCommands.Commands.unfreeze = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;unfreeze <player>", "error")
		return
	end
	
	local target = findPlayer(args[1])
	if not target then
		notify(executor, "Player not found!", "error")
		return
	end
	
	local character = target.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
			getPlayerStatus(target.Name).Frozen = false
			notify(executor, "Unfroze " .. target.Name, "success")
		end
	end
end

-- Announce to all players
AdminCommands.Commands.announce = function(executor: Player, args: {string})
	if #args < 1 then
		notify(executor, "Usage: ;announce <message>", "error")
		return
	end
	
	local message = table.concat(args, " ")
	
	for _, player in ipairs(Players:GetPlayers()) do
		AdminRemote.Notify:FireClient(player, "📢 Announcement: " .. message, "announce")
	end
	
	notify(executor, "Announcement sent!", "success")
end

-- Fly command
AdminCommands.Commands.fly = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	AdminRemote.ToggleFly:FireClient(target, true)
	getPlayerStatus(target.Name).Flying = true
	notify(executor, "Fly enabled for " .. target.Name, "success")
end

-- Unfly command
AdminCommands.Commands.unfly = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	AdminRemote.ToggleFly:FireClient(target, false)
	getPlayerStatus(target.Name).Flying = false
	notify(executor, "Fly disabled for " .. target.Name, "success")
end

-- Reset/Normal command - mengembalikan semua ke default
AdminCommands.Commands.reset = function(executor: Player, args: {string})
	local target = executor
	if args[1] then
		target = findPlayer(args[1])
		if not target then
			notify(executor, "Player not found!", "error")
			return
		end
	end
	
	local character = target.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Reset speed & jump
			humanoid.WalkSpeed = 16
			if humanoid.UseJumpPower then
				humanoid.JumpPower = 50
			else
				humanoid.JumpHeight = 7.2
			end
			
			-- Reset health
			humanoid.MaxHealth = 100
			humanoid.Health = 100
			
			-- Unfreeze
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Anchored = false
			end
			
			-- Make visible
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Transparency = 0
					if part.Name == "Head" then
						local face = part:FindFirstChildOfClass("Decal")
						if face then
							face.Transparency = 0
						end
					end
				elseif part:IsA("Accessory") then
					local handle = part:FindFirstChild("Handle")
					if handle then
						handle.Transparency = 0
					end
				end
			end
		end
	end
	
	-- Disable fly
	AdminRemote.ToggleFly:FireClient(target, false)
	
	-- Reset all status
	local status = getPlayerStatus(target.Name)
	status.GodMode = false
	status.Flying = false
	status.Invisible = false
	status.Frozen = false
	
	-- Disable god mode properly
	disableGodMode(target)
	
	notify(executor, "Reset " .. target.Name .. " to normal", "success")
end

-- Alias untuk reset
AdminCommands.Commands.normal = AdminCommands.Commands.reset

-- Help command
AdminCommands.Commands.help = function(executor: Player, args: {string})
	local helpText = [[
Available Commands:
;kill <player> - Kill a player
;kick <player> [reason] - Kick a player
;tp <player> - Teleport to a player
;bring <player> - Bring a player to you
;speed <number> [player] - Set walk speed
;jp <number> [player] - Set jump power
;god [player] - Enable god mode
;ungod [player] - Disable god mode
;respawn [player] - Respawn a player
;invis [player] - Make invisible
;vis [player] - Make visible
;freeze <player> - Freeze a player
;unfreeze <player> - Unfreeze a player
;fly [player] - Enable fly mode
;unfly [player] - Disable fly mode
;reset [player] - Reset to normal state
;normal [player] - Same as reset
;announce <message> - Send announcement to all
;help - Show this help message
]]
	notify(executor, helpText, "info")
end

-- ==================== COMMAND HANDLER ====================

function AdminCommands:ExecuteCommand(player: Player, commandText: string)
	-- Check if player is admin
	if not AdminConfig:IsAdmin(player) then
		warn(player.Name .. " tried to use admin command but is not an admin!")
		return
	end
	
	-- Parse command
	local command, args = AdminConfig:ParseCommand(commandText)
	
	if command == "" then
		return
	end
	
	-- Execute command
	local commandFunc = self.Commands[command]
	if commandFunc then
		local success, err = pcall(commandFunc, player, args)
		if not success then
			warn("Error executing command '" .. command .. "': " .. tostring(err))
			notify(player, "Error executing command: " .. tostring(err), "error")
		end
	else
		notify(player, "Unknown command: " .. command, "error")
	end
end

-- Setup remote events
function AdminCommands:Initialize()
	-- Handle command execution from client
	AdminRemote.ExecuteCommand.OnServerEvent:Connect(function(player, commandText)
		self:ExecuteCommand(player, commandText)
	end)
	
	-- Handle get players request
	AdminRemote.GetPlayers.OnServerInvoke = function(player)
		if not AdminConfig:IsAdmin(player) then
			return {}
		end
		
		local playerList = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			table.insert(playerList, plr.Name)
		end
		return playerList
	end
	
	-- Handle get status request
	AdminRemote.GetStatus.OnServerInvoke = function(player, targetName)
		if not AdminConfig:IsAdmin(player) then
			return {}
		end
		
		if not targetName then
			targetName = player.Name
		end
		
		return getPlayerStatus(targetName)
	end
	
	-- Handle player character respawn (reapply god mode if it was active)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			if getPlayerStatus(player.Name).GodMode then
				-- Wait for humanoid to load
				task.wait(0.1)
				enableGodMode(player)
			end
		end)
	end)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(character)
			if getPlayerStatus(player.Name).GodMode then
				task.wait(0.1)
				enableGodMode(player)
			end
		end)
	end
	
	-- Cleanup on player leaving
	Players.PlayerRemoving:Connect(function(player)
		if AdminCommands.GodModeConnections[player.UserId] then
			for _, conn in ipairs(AdminCommands.GodModeConnections[player.UserId]) do
				conn:Disconnect()
			end
			AdminCommands.GodModeConnections[player.UserId] = nil
		end
		AdminCommands.PlayerStatus[player.Name] = nil
	end)
	
	print("Admin Commands System initialized!")
end

return AdminCommands
