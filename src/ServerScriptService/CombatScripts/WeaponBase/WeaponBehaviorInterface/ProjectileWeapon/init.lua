local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponType = require(script.Parent)

local storage = ReplicatedStorage.CombatStorage
local shotFiredRemote = storage.Remote.ShotFired
local clientFolder = storage.Client

local ProjectileWeapon = {}
setmetatable(ProjectileWeapon, {__index = WeaponType})
ProjectileWeapon.clientModule = clientFolder.WeaponBase.WeaponBehaviorInterface.ProjectileWeapon
ProjectileWeapon.fireDelay = 0.15
ProjectileWeapon.recoilPerShot = math.rad(3)
ProjectileWeapon.movementRecoilPerShot = math.rad(6)
ProjectileWeapon.displayName = "missing str"
ProjectileWeapon.aimSensitivity = 0.6
ProjectileWeapon.aimFovAdjustment = -15

function ProjectileWeapon.new(ammoType, reloadDelegate)
	local self = setmetatable({}, {__index = ProjectileWeapon})
	self.ammoType = ammoType
	self.reloader = reloadDelegate
	self.activeShots = {}
	return self
end

function ProjectileWeapon:init(weapon)
	weapon.carrier:getSignal("ShotFired"):Connect(function(...)
		if weapon.equipped then
			self:fire(weapon, ...)
		end
	end)
	weapon.carrier:getSignal("ShotHit"):Connect(function(...)
		self:shotHit(...)
	end)
	weapon.carrier:getSignal("ReloadStarted"):Connect(function(...)
		if weapon.equipped then
			self.reloader:start()
		end
	end)
	weapon.carrier:setCallback("SyncAmmo", function(cancelled)
		self.reloader:stop(cancelled, weapon.carrier:getLatency())
		return self.reloader.currentAmmo
	end)
end

function ProjectileWeapon:fire(weapon, id, movementInfo, claimedAmmoCount)
	assert(typeof(id) == "string", "improper id sent")
	assert(not self.activeShots[id], "uuid taken")
	self.reloader:onFired()
	if self.reloader.currentAmmo == claimedAmmoCount then
		local activeShot = self.ammoType:new()
		self.activeShots[id] = activeShot
		activeShot:init(id, weapon.carrier.char, movementInfo)
		if self.noVerify or activeShot:verifySpawn(movementInfo) then
			activeShot:spawn()
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= weapon.carrier.player then
					shotFiredRemote:FireClient(player, weapon.carrier.player or weapon.carrier.char, movementInfo)
				end
			end
		end
	else
		warn("!ammo mismatch!", weapon.carrier.player, "claimed:", claimedAmmoCount, "actually:", self.reloader.currentAmmo)
	end
end

function ProjectileWeapon:shotHit(id, hum, ...)
	local activeShot = self.activeShots[id]
	if activeShot then
		if self.noVerify or activeShot:verifyHit(hum, ...) then
			task.spawn(activeShot.hit, activeShot, hum, ...)
		end
		self.activeShots[id] = nil
		activeShot:destroy()
	else
		print("unknown shot id")
	end
end

function ProjectileWeapon:getToReplicate()
	local info = {}
	info.fireDelay = self.fireDelay
	info.ammoModule = self.ammoType.clientModule
	info.reloadModule = self.reloader.clientModule
	info.ammoInfo = self.ammoType:getReplicationInfo()
	info.reloadInfo = self.reloader:getReplicationInfo()
	info.displayName = self.displayName
	info.recoilPerShot = self.recoilPerShot
	info.movementRecoilPerShot = self.movementRecoilPerShot
	info.aimSensitivity = self.aimSensitivity
	info.aimFovAdjustment = self.aimFovAdjustment
	return info
end

function ProjectileWeapon:destroy()
	--print("nothing to destroy yet")
end

return ProjectileWeapon