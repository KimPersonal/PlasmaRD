local TestGun = require(script.Parent.Parent.Presets.M4A1)
local PlayerCarrier = require(script.Parent.Parent.WeaponBase.CarrierTypeInterface.PlayerCarrier)

game:GetService("Players").PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait()
		TestGun(PlayerCarrier.new(player))
	end)
end)