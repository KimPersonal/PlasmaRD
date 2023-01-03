local ReloadDelegateInterface = require(script.Parent)

local clientFolder = game:GetService("ReplicatedStorage").CombatStorage.Client

local FullRefill = {}
setmetatable(FullRefill, {__index = ReloadDelegateInterface})
FullRefill.clientModule = clientFolder.WeaponBase.WeaponBehaviorInterface.ProjectileWeapon.ReloadDelegateInterface.FullRefill
FullRefill.capacity = 30
FullRefill.currentAmmo = 30
FullRefill.reductionAmount = 1
FullRefill.reloadTime = 1.5
FullRefill.reloading = false
FullRefill.maxLatency = 0.4
FullRefill.minLatency = 0.1

function FullRefill.new()
	local self = setmetatable({}, {__index = FullRefill})
	return self
end

function FullRefill:onFired()
	self.currentAmmo -= self.reductionAmount
	self.currentAmmo = math.max(0, self.currentAmmo)
end

function FullRefill:start()
	if not self.startTime then
		self.reloading = true
		self.startTime = os.clock()
	end
end

function FullRefill:stop(cancelled, latency)
	if self.startTime then
		if not cancelled and os.clock() - self.startTime >= self.reloadTime - math.clamp(latency, self.minLatency, self.maxLatency) then
			self.currentAmmo = self.capacity
		end
		self.startTime = nil
	end
end

function FullRefill:getReplicationInfo()
	return {
		capacity = self.capacity,
		currentAmmo = self.currentAmmo,
		reductionAmount = self.reductionAmount,
		reloadTime = self.reloadTime
	}
end

return FullRefill