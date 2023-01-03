local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local client = Players.LocalPlayer
local combatStorage = game:GetService("ReplicatedStorage").CombatStorage
local clientFolder = combatStorage.Client
local camFolder = clientFolder.Camera
local remoteFolder = combatStorage.Remote
local ThirdPersonCamera = require(camFolder.CameraController.ThirdPersonCamera)
local WeaponBehaviorInterface = require(script.Parent)
local Maid = require(clientFolder.Parent.Maid)
local Spring = require(clientFolder.Parent.Spring)
local CrosshairController = require(clientFolder.UI.CrosshairController)
local InfoDisplayController = require(clientFolder.UI.InfoDisplayController)
local CheckRig = require(combatStorage.CheckRig)
local shotFiredRemote = remoteFolder.ShotFired
local hitRemote = remoteFolder.ShotHit

local ProjectileWeapon = {}
setmetatable(ProjectileWeapon, {__index = WeaponBehaviorInterface})
ProjectileWeapon.fireButtonDown = false
ProjectileWeapon.lastFire = os.clock()

function ProjectileWeapon.fromServerInfo(info)
	local self = setmetatable(info, {__index = ProjectileWeapon})
	self.ammoType = require(self.ammoModule).fromServerInfo(self.ammoInfo)
	self.reloadDelegate = require(self.reloadModule).fromServerInfo(self.reloadInfo)
	self.recoilSpring = Spring.new(0)
	self.recoilSpring.t = 0
	self.recoilSpring.s = 15
	self.recoilSpring.d = 0.7
	self.maid = Maid.new()
	return self
end

local function setBackAccessoriesTransparency(char, value)
	for _, accessory in ipairs(char:GetChildren()) do
		if accessory:IsA("Accessory") and accessory.AccessoryType == Enum.AccessoryType.Back and accessory:FindFirstChild("Handle") then
			TweenService:Create(accessory.Handle, TweenInfo.new(0.3), {Transparency = value}):Play()
		end
	end
end

function ProjectileWeapon:bindLookDirection(weapon)
	if (self.firing and not self.aiming) or (not self.firing and self.aiming) then
		weapon.anims.aim:Play()
		CrosshairController.show(self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity)
		setBackAccessoriesTransparency(weapon.humanoidController.char, 0.9)
		--weapon.humanoidController.lookDirection.v = Vector3.zero
		weapon.humanoidController.lookEnabled = true
		RunService:BindToRenderStep("projWepRotUpdate", Enum.RenderPriority.Camera.Value+1, function()
			weapon.humanoidController.lookDirection = self.cameraController.camera.CFrame.LookVector
		end)
	end
end

function ProjectileWeapon:unbindLookDirection(weapon)
	if not self.firing and not self.aiming then
		weapon.anims.aim:Stop()
		CrosshairController.hide()
		setBackAccessoriesTransparency(weapon.humanoidController.char, 0)
		RunService:UnbindFromRenderStep("projWepRotUpdate")
		weapon.humanoidController.lookEnabled = false
	end
end

function ProjectileWeapon:initAsOwner(weapon)
	CheckRig(client.Character)
	
	weapon.tool.Equipped:Connect(function()
		weapon.anims.equip:Play(0)
		weapon.anims.idle:Play()
		self.cameraController = self.maid:add(ThirdPersonCamera.new(workspace.CurrentCamera))
		UserInputService.MouseIconEnabled = false
		InfoDisplayController.show(weapon.baseModel, self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity, self.displayName, self.ammoType.ammoImageName)
		
		ContextActionService:BindAction("projWepFire", function(_, state)
			if state == Enum.UserInputState.Begin and not weapon.anims.equip.IsPlaying then
				self.firing = true
				weapon.anims.reload:Stop()
				self:bindLookDirection(weapon)
				RunService:BindToRenderStep("projWepFireCheck", Enum.RenderPriority.Character.Value+1, function()
					if self.reloadDelegate:getCanFire() and os.clock() - self.lastFire >= self.fireDelay then
						self:fireAsync(weapon)
					end
					self.reloadDelegate:cancel()
				end)
				return Enum.ContextActionResult.Sink
			elseif state == Enum.UserInputState.End then
				self.firing = false
				self:unbindLookDirection(weapon)
				RunService:UnbindFromRenderStep("projWepFireCheck")
				return Enum.ContextActionResult.Sink
			else
				return Enum.ContextActionResult.Pass
			end
		end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
		
		ContextActionService:BindAction("projWepAim", function(_, state)
			if state == Enum.UserInputState.Begin then
				self.aiming = true
				UserInputService.MouseDeltaSensitivity = self.aimSensitivity
				self.cameraController:setFovOffset(self.aimFovAdjustment)
				self:bindLookDirection(weapon)
			elseif state == Enum.UserInputState.End then
				self.aiming = false
				UserInputService.MouseDeltaSensitivity = 1
				self.cameraController:setFovOffset(0)
				self:unbindLookDirection(weapon)
			end
			return Enum.ContextActionResult.Pass
		end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2)
		
		ContextActionService:BindAction("projWepReload", function(_, state)
			if state == Enum.UserInputState.Begin then
				if self.reloadDelegate:getCanReload() and self.reloadDelegate.currentAmmo < self.reloadDelegate.capacity then
					self.firing = false
					RunService:UnbindFromRenderStep("projWepFireCheck")
					weapon.anims.reload:Play()
					self.reloadDelegate:reloadAsync()
					if not self.reloadDelegate.cancelled then
						CrosshairController.tweenAmmo(self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity)
						InfoDisplayController.tweenAmmo(self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity, self.ammoType.ammoImageName)
					end
				end
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.R)
		
		RunService:BindToRenderStep("projWepRecoilUpdate", Enum.RenderPriority.Camera.Value, function()
			local pxPRad = self.cameraController.camera.ViewportSize.Y/math.rad(self.cameraController.camera.FieldOfView)
			CrosshairController.setRecoilDist((self.recoilSpring.p+self.ammoType.spread/4)*pxPRad*0.5)
		end)
	end)
	weapon.tool.Unequipped:Connect(function()
		UserInputService.MouseIconEnabled = true
		self.cameraController:destroy()
		self.reloadDelegate:cancel()
		self.firing = false
		self.aiming = false
		ContextActionService:UnbindAction("projWepFire")
		ContextActionService:UnbindAction("projWepAim")
		ContextActionService:UnbindAction("projWepReload")
		RunService:UnbindFromRenderStep("projWepFireCheck")
		RunService:UnbindFromRenderStep("projWepRecoilUpdate")
		self:unbindLookDirection(weapon)
		InfoDisplayController.hide()
		weapon.humanoidController.lookEnabled = false
		for _, anim in pairs(weapon.anims) do
			if typeof(anim) == "Instance" and anim:IsA("AnimationTrack") then
				anim:Stop()
			end
		end
	end)
end

function ProjectileWeapon:initAsObserver(unownedWeapon)
	shotFiredRemote.OnClientEvent:Connect(function(creator, movementInfo)
		if creator == unownedWeapon.owner then
			if unownedWeapon.anims.onShotFired then
				task.spawn(unownedWeapon.anims.onShotFired, unownedWeapon)
			end
			local shot = self.ammoType:new()
			shot:initAsObserver(creator, movementInfo)
			unownedWeapon.humanoidController.lookDirection = shot:getAimDirection()
			shot:fireAsync()
		end
	end)
end

function ProjectileWeapon:fireAsync(weapon)
	local recoil = client.Character.Humanoid.MoveDirection ~= Vector3.zero and self.movementRecoilPerShot or self.recoilPerShot
	self.lastFire = os.clock()
	self.recoilSpring:Impulse(recoil*self.recoilSpring.s)
	self.cameraController:impulseRecoil(recoil)
	if weapon.anims.onShotFired then
		task.spawn(weapon.anims.onShotFired, weapon)
	end
	self.reloadDelegate:onFired()
	
	CrosshairController.tweenAmmo(self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity)
	InfoDisplayController.tweenAmmo(self.reloadDelegate.currentAmmo, self.reloadDelegate.capacity, self.ammoType.ammoImageName)
	
	local shot = self.ammoType:new()
	shot:initAsOwner(weapon)
	shotFiredRemote:FireServer(shot.id, shot.movementInfo, self.reloadDelegate.currentAmmo)
	shot.onHit.Event:Connect(function(hitResult)
		local hum = hitResult and hitResult.Instance.Parent:FindFirstChildOfClass("Humanoid")
		if hum then
			CrosshairController.makeHitmarker()
			hitRemote:FireServer(shot.id, hum, hitResult.Position)
		end
	end)
	shot:fireAsync()
end

function ProjectileWeapon:destroy()
	self.maid:destroy()
end

return ProjectileWeapon