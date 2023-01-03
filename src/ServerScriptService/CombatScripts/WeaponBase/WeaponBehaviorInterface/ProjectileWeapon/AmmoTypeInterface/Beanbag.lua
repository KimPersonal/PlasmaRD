local repStorage = game:GetService("ReplicatedStorage").CombatStorage
local clientFolder = repStorage.Client
local BulletGeneric = require(script.Parent.BulletGeneric)
local stunInfo = {}

local Beanbag = {}
Beanbag.clientModule = clientFolder.WeaponBase.WeaponBehaviorInterface.ProjectileWeapon.AmmoTypeInterface.Beanbag
Beanbag.damage = 5
Beanbag.pushVelocityMult = 3
Beanbag.stunTime = 1
setmetatable(Beanbag, {__index = BulletGeneric})

function Beanbag.new(inherit)
	return setmetatable({}, {__index = inherit or Beanbag})
end

function Beanbag:hit(hum: Humanoid)
	hum:TakeDamage(self.damage)
	hum.PlatformStand = true
	local primaryPart: BasePart? = hum.Parent and hum.Parent:IsA("Model") and hum.Parent.PrimaryPart or nil
	if primaryPart then
		primaryPart.AssemblyLinearVelocity = (primaryPart.Position - self.char:GetPivot().Position).Unit * primaryPart.AssemblyMass * self.pushVelocityMult
	end
	
	local key = {}
	stunInfo[hum] = key
	task.wait(self.stunTime)
	if stunInfo[hum] == key then
		hum.PlatformStand = false
	end
end

return Beanbag