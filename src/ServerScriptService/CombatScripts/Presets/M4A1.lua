local WeaponBaseInstance = script.Parent.Parent.WeaponBase
local WeaponBase = require(WeaponBaseInstance)
local ProjectileWeapon = require(WeaponBaseInstance.WeaponBehaviorInterface.ProjectileWeapon)
local BulletGeneric = require(WeaponBaseInstance.WeaponBehaviorInterface.ProjectileWeapon.AmmoTypeInterface.BulletGeneric)
local Beanbag = require(WeaponBaseInstance.WeaponBehaviorInterface.ProjectileWeapon.AmmoTypeInterface.Beanbag)
local MagazineGeneric = require(WeaponBaseInstance.WeaponBehaviorInterface.ProjectileWeapon.ReloadDelegateInterface.FullRefill)
local model = game:GetService("ReplicatedStorage").CombatStorage.Models.M4A1

return function(carrier)
	local ammo = BulletGeneric.new()
	ammo.damage = 18
	local projWep = ProjectileWeapon.new(ammo, MagazineGeneric.new())
	projWep.displayName = "M4A1"
	local wep = WeaponBase.new(projWep, carrier, model)
	return wep
end