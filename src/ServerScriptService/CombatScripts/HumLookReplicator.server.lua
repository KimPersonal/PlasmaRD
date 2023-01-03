local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local INTERVAL = 0.5
local storageFolder = ReplicatedStorage.CombatStorage
local lookRemote = storageFolder.Remote.UpdateLookDirection
local lookInfo = {}

lookRemote.OnServerEvent:Connect(function(player, lookEnabled, lookT)
	local char = player.Character
	if char then
		if not lookInfo[char] then
			char.Destroying:Connect(function()
				lookInfo[char] = nil
			end)
		end
		lookInfo[char] = {
			lookEnabled = lookEnabled,
			lookT = lookT
		}
	end
end)

while true do
	task.wait(INTERVAL)
	local toSend = {}
	for char, info in pairs(lookInfo) do
		table.insert(toSend, {
			char = char,
			lookEnabled = info.lookEnabled,
			lookT = info.lookT
		})
	end
	lookRemote:FireAllClients(toSend)
end