--[[
	Anti-Staff Module  
	Helps avoid detection by staff/admins
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local AntiStaff = {}
AntiStaff.Enabled = false
AntiStaff.Connections = {}
AntiStaff.GuiFrame = nil

function AntiStaff:Enable(guiFrame)
	if self.Enabled then return end
	
	self.Enabled = true
	self.GuiFrame = guiFrame
	
	-- Hide all admin GUIs when staff joins
	local function checkForStaff()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player and (
				plr:IsInGroup(0) or -- Replace with actual staff group ID
				plr.Name:lower():find("admin") or
				plr.Name:lower():find("mod") or
				plr.Name:lower():find("staff") or
				plr.Name:lower():find("owner")
			) then
				return true
			end
		end
		return false
	end
	
	local function hideAdminGui()
		if self.GuiFrame then
			self.GuiFrame.Visible = false
		end
	end
	
	local function showAdminGui()
		if self.GuiFrame then
			self.GuiFrame.Visible = true
		end
	end
	end
	
	-- Check on player join/leave
	table.insert(self.Connections, Players.PlayerAdded:Connect(function(plr)
		if checkForStaff() then
			hideAdminGui()
		end
	end))
	
	table.insert(self.Connections, Players.PlayerRemoving:Connect(function(plr)
		task.wait(0.5)
		if not checkForStaff() then
			showAdminGui()
		end
	end))
	
	-- Initial check
	if checkForStaff() then
		hideAdminGui()
	end
	
	print("Anti-Staff enabled! GUI will auto-hide when staff joins.")
end

function AntiStaff:Disable()
	if not self.Enabled then return end
	
	self.Enabled = false
	
	-- Disconnect all connections
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = {}
	
	-- Show GUI
	if self.GuiFrame then
		self.GuiFrame.Visible = true
	end
	
	print("Anti-Staff disabled!")
end

function AntiStaff:Toggle(guiFrame)
	if self.Enabled then
		self:Disable()
	else
		self:Enable(guiFrame)
	end
	
	return self.Enabled
end

return AntiStaff
