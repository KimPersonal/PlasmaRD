local repStorage = game:GetService("ReplicatedStorage").CombatStorage
local clientFolder = repStorage.Client
local Raycaster = require(repStorage.Raycaster)
local AmmoTypeInterface = require(script.Parent)

local BulletGeneric = {}
setmetatable(BulletGeneric, {__index = AmmoTypeInterface})
BulletGeneric.clientModule = clientFolder.WeaponBase.WeaponBehaviorInterface.ProjectileWeapon.AmmoTypeInterface.BulletGeneric
BulletGeneric.damage = 5
BulletGeneric.originRadiusLimit = 10
BulletGeneric.hitRadiusLimit = 5
BulletGeneric.maxDist = 800
BulletGeneric.speed = 1200
BulletGeneric.spread = math.rad(1)
BulletGeneric.movementSpread = math.rad(2)
BulletGeneric.charCheckLength = 15
BulletGeneric.ammoImageName = "Bullet"

BulletGeneric.castProps = {
	CanCollide = true,
	siblingClass = {"Humanoid"}
}

function BulletGeneric.new(inherit)
	return setmetatable({}, {__index = inherit or BulletGeneric})
end

function BulletGeneric:init(id, ownerChar, movementInfo)
	self.id = id
	self.char = ownerChar
	self.movementInfo = movementInfo
	return self
end

function BulletGeneric:verifySpawn()
	return (self.char:GetPivot().Position - self.movementInfo.origin).Magnitude <= self.originRadiusLimit/16 * self.char.Humanoid.WalkSpeed
end

function BulletGeneric:spawn()
	self.spawnTime = os.clock()
end

function BulletGeneric:verifyHit(hum, hitPos)
	local score = 0
	
	do
		local result = Raycaster.iterativeSearch(self.movementInfo.origin, self.movementInfo.direction, {hum.Parent, self.char}, Enum.RaycastFilterType.Blacklist, self.castProps)
		if result then
			score += 1
		end
	end
	
	do
		local hitToPos = hum.Parent:GetPivot().Position - hitPos
		if hitToPos.Magnitude > self.hitRadiusLimit then
			score += (hitToPos.Magnitude - self.hitRadiusLimit) * 0.5
		end
	end
	
	return score < 4
end

function BulletGeneric:hit(hum)
	hum:TakeDamage(self.damage)
end

function BulletGeneric:getReplicationInfo()
	return {
		damage = self.damage,
		maxDist = self.maxDist,
		speed = self.speed,
		spread = self.spread,
		movementSpread = self.movementSpread,
		castProps = self.castProps,
		charCheckLength = self.charCheckLength,
		ammoImageName = self.ammoImageName,
	}
end

function BulletGeneric:destroy()
	--print("nothing to worry about destroying here")
end

return BulletGeneric