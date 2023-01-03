local combatFolder = game:GetService("ReplicatedStorage").CombatStorage
local shotRemote = combatFolder.Remote.ShotFired

local function createShot(owner, clientModule, animModule, replInfo, movementInfo)
	local shot = require(clientModule).fromServerInfo(replInfo)
	shot:initAsObserver(owner, movementInfo)
	shot:fireAsync()
end

shotRemote.OnClientEvent:Connect(createShot)