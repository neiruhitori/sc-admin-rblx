--[[
	Admin Remote Events
	Untuk komunikasi antara client dan server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminRemote = {}

-- Buat RemoteEvent jika belum ada
local function getOrCreateRemote(name: string, className: string)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end
	
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

-- RemoteEvent untuk execute command
AdminRemote.ExecuteCommand = getOrCreateRemote("AdminExecuteCommand", "RemoteEvent")

-- RemoteFunction untuk get player list
AdminRemote.GetPlayers = getOrCreateRemote("AdminGetPlayers", "RemoteFunction")

-- RemoteEvent untuk notifikasi ke client
AdminRemote.Notify = getOrCreateRemote("AdminNotify", "RemoteEvent")

-- RemoteEvent untuk toggle fly mode
AdminRemote.ToggleFly = getOrCreateRemote("AdminToggleFly", "RemoteEvent")

-- RemoteFunction untuk get status (god, fly, etc)
AdminRemote.GetStatus = getOrCreateRemote("AdminGetStatus", "RemoteFunction")

return AdminRemote
