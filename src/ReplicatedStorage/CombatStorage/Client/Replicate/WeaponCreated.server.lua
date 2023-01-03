local ReplicatedStorage = game:GetService("ReplicatedStorage")
local storage = ReplicatedStorage.CombatStorage
local WeaponBase = require(storage.Client.WeaponBase)
local UnownedWeapon = require(storage.Client.UnownedWeapon)
local client = game:GetService("Players").LocalPlayer
local creationRemote = storage.Remote.WeaponCreated

creationRemote.OnClientEvent:Connect(function(owner, tool: Tool, weaponInfo)
	print("received", tool)
	if owner == client then
		local weapon = WeaponBase.fromServerInfo(tool, weaponInfo)
	else
		UnownedWeapon.new(owner, tool, weaponInfo)
	end
end)

storage.Remote.RequestReplication:FireServer()