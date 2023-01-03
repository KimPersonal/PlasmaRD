local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local combatFolder = ReplicatedStorage.CombatStorage
local ReloadDelegateInterface = require(script.Parent)
local InfoDisplayController = require(combatFolder.Client.UI.InfoDisplayController)
local CrosshairController = require(combatFolder.Client.UI.CrosshairController)
local startEvent = combatFolder.Remote.ReloadStarted
local syncFunc = combatFolder.Remote.SyncAmmo

local FullRefill = {}
setmetatable(FullRefill, {__index = ReloadDelegateInterface})
FullRefill.reloading = false

function FullRefill.fromServerInfo(info)
	local self = setmetatable(info, {__index = FullRefill})
	return self
end

function FullRefill:getCanFire()
	return self.currentAmmo > 0 and not self.reloading
end

function FullRefill:getCanReload()
	return not self.reloading
end

function FullRefill:onFired()
	self.currentAmmo -= self.reductionAmount
end

function FullRefill:reloadAsync()
	self.reloading = true
	self.cancelled = false
	startEvent:FireServer()
	local passed = 0
	while not self.cancelled and passed < self.reloadTime do
		InfoDisplayController.setOutlineFill(passed/self.reloadTime)
		CrosshairController.setCircleFill(passed/self.reloadTime)
		passed += RunService.RenderStepped:Wait()
	end
	self.currentAmmo = syncFunc:InvokeServer(self.cancelled)
	self.reloading = false
	print("finished with", self.currentAmmo, self.cancelled)
end

function FullRefill:cancel()
	if self.reloading then
		self.cancelled = true
	end
end

return FullRefill