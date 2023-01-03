local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local client = Players.LocalPlayer
local combatStorage = ReplicatedStorage.CombatStorage
local Raycaster = require(combatStorage.Raycaster)
local DebugVisualize = require(combatStorage.Debug.Visualize)

local flybySounds = script.FlybySounds:GetChildren()
local impactSoundFolder = script.ImpactSounds

local BulletGeneric = {}
setmetatable(BulletGeneric, {__index = require(script.Parent)})
BulletGeneric.owner = nil

function BulletGeneric.new(inherit)
	local self = setmetatable({}, {__index = inherit or BulletGeneric})
	return self
end

function BulletGeneric.fromServerInfo(info)
	local self = setmetatable(info, {__index = BulletGeneric})
	return self
end

function BulletGeneric:initAsOwner(weapon)
	self.owner = client
	self.id = HttpService:GenerateGUID(false)
	self.movementInfo = self:getMovementInfo(weapon)
	self.onHit = Instance.new("BindableEvent")
	self.spread = client.Character.Humanoid.MoveDirection ~= Vector3.zero and self.movementSpread or self.spread
end

function BulletGeneric:initAsObserver(owner, movementInfo)
	self.owner = owner
	self.movementInfo = movementInfo
	self.onHit = Instance.new("BindableEvent")
end

function BulletGeneric:getMovementInfo(weapon)
	local behavior = weapon.weaponBehavior
	local tool = weapon.tool
	local info = {}
	local camCf: CFrame = behavior.cameraController.camera.CFrame
	local camForward = camCf.LookVector*self.maxDist
	local camResult = Raycaster.iterativeSearch(camCf.Position, camForward, {client.Character}, Enum.RaycastFilterType.Blacklist, self.castProps)
	local targetPosRaw = camResult and camResult.Position or camCf.Position + camForward
	local modelSpawnPos = tool:FindFirstChild("SpawnPart", true).Position
	targetPosRaw += camCf.LookVector*0.1
	local modelSpawnCf = CFrame.lookAt(modelSpawnPos, targetPosRaw)
	local rand = Random.new()
	local halfSpread = self.spread/2
	modelSpawnCf *= CFrame.Angles(rand:NextNumber(-halfSpread, halfSpread), rand:NextNumber(-halfSpread, halfSpread), 0)
	local targetPos = modelSpawnPos + modelSpawnCf.LookVector * (targetPosRaw-modelSpawnPos).Magnitude
	DebugVisualize.showPoint(targetPos, 1, "SHOT", Color3.new(0, 1, 0), 5, 0.4)
	DebugVisualize.showCFrame(modelSpawnCf, 0.5, "SHOT", nil, 5)
	DebugVisualize.showRay(modelSpawnCf.Position, modelSpawnCf.LookVector*(targetPos-modelSpawnPos).Magnitude, "SHOT", nil, nil, 5)
	
	local charCf = client.Character:GetPivot()
	local charBlockResult, savedList = Raycaster.iterativeSearch(charCf.Position, (targetPos - charCf.Position).Unit*self.charCheckLength, {client.Character}, Enum.RaycastFilterType.Blacklist, self.castProps)
	if charBlockResult then
		targetPos = charBlockResult.Position
	else
		savedList = Raycaster.getPartsOnRay(modelSpawnPos, targetPos - modelSpawnPos, savedList)
	end
	for i = #savedList, 1, -1 do
		local part = savedList[i]
		if part.Parent:FindFirstChildWhichIsA("Humanoid") then
			table.remove(savedList, i)
		end
	end
	info.ignoreList = savedList
	info.origin = modelSpawnPos
	info.direction = targetPos - info.origin
	DebugVisualize.showPoint(targetPos, 1, "SHOT", Color3.new(0, 1, 1), 5, 0.6)
	return info
end

function BulletGeneric:getAimDirection()
	return self.movementInfo.direction
end

function BulletGeneric:fireAsync()
	local movementInfo = self.movementInfo
	local curPos = movementInfo.origin
	local reached = false
	local clientCharPos = client.Character:GetPivot().Position
	local playFlyby = (movementInfo.origin - clientCharPos).Magnitude > 30
	self.part = script.BulletPart:Clone()
	self.part.Parent = workspace
	self.part.CFrame = CFrame.new(curPos)
	
	while not self.hitResult and not reached do
		local moveVector = movementInfo.direction.Unit * self.speed * RunService.RenderStepped:Wait()
		local goalPos = curPos + moveVector
		local param = RaycastParams.new()
		param.FilterType = Enum.RaycastFilterType.Blacklist
		param.FilterDescendantsInstances = movementInfo.ignoreList
		self.hitResult = workspace:Raycast(curPos, moveVector, param)
		if self.hitResult then
			goalPos = self.hitResult.Position
		end
		if (goalPos - movementInfo.origin).Magnitude > movementInfo.direction.Magnitude then
			goalPos = movementInfo.origin + movementInfo.direction
			reached = true
		end
		
		if playFlyby and (goalPos - clientCharPos).Magnitude <= 15 then
			playFlyby = false
			local sound: Sound = flybySounds[Random.new():NextInteger(1, #flybySounds)]:Clone()
			sound.PlaybackSpeed += Random.new():NextNumber(-0.1, 0.5)
			sound.Parent = self.part
			sound:Play()
		end
		local maxEffectLength = self.speed*0.05
		self.part.CFrame = CFrame.lookAt(goalPos, goalPos+moveVector)
		self.part.Back.Position = Vector3.new(0, 0, math.min((goalPos - movementInfo.origin).Magnitude, maxEffectLength))
		curPos = goalPos
	end
	
	self.onHit:Fire(self.hitResult)
	task.spawn(self.despawnAsync, self)
end

function BulletGeneric:despawnAsync()
	local impactSound: Sound = (self.hitResult and impactSoundFolder:FindFirstChild(self.hitResult.Material.Name) or impactSoundFolder.Any):Clone()
	impactSound.Parent = self.part
	impactSound:Play()
	
	while self.part.Back.Position.Z > 0 do
		self.part.Back.Position -= Vector3.zAxis * self.speed*0.5 * RunService.RenderStepped:Wait()
	end
	self.part.Glow.Enabled = false
	self.part.Light.Enabled = false
	if impactSound.Playing then
		impactSound.Ended:Wait()
	end
	self:destroy()
end

function BulletGeneric:destroy()
	self.part:Destroy()
	self.movementInfo = nil
	self.id = nil
	if self.onHit then
		self.onHit:Destroy()
		self.onHit = nil
	end
end

return BulletGeneric