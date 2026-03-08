--[[
	Admin Configuration Module
	Konfigurasi untuk sistem admin commands
]]

local AdminConfig = {}

-- Daftar admin (gunakan Username atau UserId)
-- Tambahkan username Roblox kamu di sini
AdminConfig.Admins = {
	"Danielle_0021", -- Ganti dengan username Roblox kamu
	-- Atau gunakan UserId:
	-- [8987066648] = true,
}

-- Prefix untuk command
AdminConfig.Prefix = ";"

-- Warna tema UI
AdminConfig.Theme = {
	Primary = Color3.fromRGB(45, 45, 45),
	Secondary = Color3.fromRGB(35, 35, 35),
	Accent = Color3.fromRGB(0, 170, 255),
	Text = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(0, 255, 0),
	Error = Color3.fromRGB(255, 0, 0),
}

-- Fungsi untuk cek apakah player adalah admin
function AdminConfig:IsAdmin(player: Player): boolean
	-- Cek berdasarkan username
	for _, adminName in ipairs(self.Admins) do
		if typeof(adminName) == "string" and player.Name == adminName then
			return true
		end
	end
	
	-- Cek berdasarkan UserId
	if self.Admins[player.UserId] then
		return true
	end
	
	return false
end

-- Fungsi untuk parse command dan arguments
function AdminConfig:ParseCommand(input: string): (string, {string})
	if not input:sub(1, #self.Prefix) == self.Prefix then
		return "", {}
	end
	
	local withoutPrefix = input:sub(#self.Prefix + 1)
	local parts = withoutPrefix:split(" ")
	local command = parts[1]:lower()
	
	table.remove(parts, 1)
	
	return command, parts
end

return AdminConfig
