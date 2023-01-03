local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

local client = PlayerService.LocalPlayer
local storage = ReplicatedStorage.CombatStorage
local CameraController = require(script.Parent)
local FakeCamera = require(script.Parent.Parent.FakeCamera)
local Spring = require(storage.Spring)

local DebugVisualize = require(storage.Debug.Visualize)
local DebugUI = require(storage.Debug.UI)
local DEBUG_TAG = "TPCAM"

local ThirdPersonCamera = {}
setmetatable(ThirdPersonCamera, {__index = CameraController})
ThirdPersonCamera.bindName = "thirdPersonCombatCamera"
ThirdPersonCamera.whiskerCount = 6
ThirdPersonCamera.whiskerAngleRange = math.rad(50)
ThirdPersonCamera.whiskerLength = 3
ThirdPersonCamera.angleX = 0
ThirdPersonCamera.angleY = 0
ThirdPersonCamera.absdx = 0
ThirdPersonCamera.yRadianPerPixel = math.rad(0.5)
ThirdPersonCamera.xRadianPerPixel = math.rad(0.36)
ThirdPersonCamera.angleXLimit = math.pi/2*0.8
ThirdPersonCamera.subjectPointOffset = Vector3.new(0, 2, 0)
ThirdPersonCamera.cameraPointOffset = CFrame.new(2.5, 0, 7)
ThirdPersonCamera.springSpeedBase = 20

function ThirdPersonCamera.new(camera)
	local self =  setmetatable({}, {__index = ThirdPersonCamera})
	self.camera = camera
	self.angleX, self.angleY = camera.CFrame:ToOrientation()
	self.subjectPop = Spring.new(0)
	self.subjectPop.s = self.springSpeedBase
	self.zPop = Spring.new(0)
	self.zPop.s = self.springSpeedBase
	self.recoilSpring = Spring.new(Vector3.zero)
	self.recoilSpring.t = Vector3.zero
	self.recoilSpring.s = self.springSpeedBase
	self.recoilSpring.d = 0.6
	self.fovAdjust = Instance.new("NumberValue")
	self:bindRendering()
	
	ContextActionService:BindAction(self.bindName, function(_, state: Enum.UserInputState, input: InputObject)
		self.angleY -= input.Delta.X * self.yRadianPerPixel
		self.angleX -= input.Delta.Y * self.xRadianPerPixel
		self.angleX = math.clamp(self.angleX, -self.angleXLimit, self.angleXLimit)
		self.absdx += math.abs(input.Delta.X)
	end, false, Enum.UserInputType.MouseMovement)
	
	return self
end

function ThirdPersonCamera:impulseRecoil(baseAngle)
	local gen = Random.new()
	local impulse = Vector3.new(baseAngle, gen:NextNumber(-baseAngle/5, baseAngle/5), 0)
	self.recoilSpring:Impulse(impulse*self.recoilSpring.s)
end

function ThirdPersonCamera:setFovOffset(setting)
	TweenService:Create(self.fovAdjust, TweenInfo.new(0.3), {Value = setting}):Play()
end

function ThirdPersonCamera:getWhiskersOrigin(cameraPoint: CFrame)
	local whiskers = {}
	local originFromCamPlaneZ = cameraPoint * CFrame.new(0, 0, -self.cameraPointOffset.Z) * CFrame.Angles(0, math.pi, 0)
	local originStart = originFromCamPlaneZ * CFrame.Angles(0, -self.whiskerAngleRange/2, 0)
	for i = 1, self.whiskerCount do
		local angle = (i-1) * (self.whiskerAngleRange / (self.whiskerCount-1))
		local rotatedOrigin = originStart * CFrame.Angles(0, angle, 0)
		table.insert(whiskers, rotatedOrigin)
	end
	return whiskers, originFromCamPlaneZ
end

function ThirdPersonCamera:getCircumscribedRadius()
	local viewportSize = self.camera.ViewportSize
	local ratio = viewportSize.X / viewportSize.Y
	local portStudHeight = math.tan(math.rad(self.camera.FieldOfView)/2) * -self.camera.NearPlaneZ * 2
	local portStudWidth = ratio * portStudHeight
	local tipEdge =  -self.camera.NearPlaneZ / math.cos(math.rad(self.camera.DiagonalFieldOfView)/2)
	return math.max(portStudHeight, portStudWidth, tipEdge)
end

function ThirdPersonCamera:getCurveFov()
	return math.deg(math.rad(70) + 0.15*math.sin(self.angleX) + 0.1*math.sqrt(math.max(0, self.angleX))) + self.zPop.p
end

function ThirdPersonCamera:getCurveDist()
	return self.cameraPointOffset.Z - 2*math.sinh(self.angleX)
end

function ThirdPersonCamera:getSubjectPoint(): Vector3
	return self.camera.CameraSubject.Parent:GetPivot().Position + self.subjectPointOffset
end

function ThirdPersonCamera:getCameraPoint(subjectPoint: Vector3): CFrame
	local rotated = CFrame.new(subjectPoint) * CFrame.Angles(0, self.angleY, 0) * CFrame.Angles(self.angleX, 0, 0)
	local camPointAdjusted = CFrame.new(self.cameraPointOffset.X, self.cameraPointOffset.Y, self:getCurveDist())
	return rotated * camPointAdjusted
end

local function getRaycastPush(origin: Vector3, direction: Vector3, param: RaycastParams?, radius: number?): number?
	local goal = origin + direction
	local result = workspace:Raycast(origin, direction, param)
	if result then
		local castPush = (goal - result.Position).Magnitude
		local spherePush = radius and radius / (-direction).Unit:Dot(result.Normal) or 0
		return castPush + math.min(spherePush, direction.Magnitude), result
	end
	return nil
end

function ThirdPersonCamera:update(dt)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	local subjectPoint: Vector3 = self:getSubjectPoint()
	local cameraPoint: CFrame = self:getCameraPoint(subjectPoint)
	local camRadius: number = self:getCircumscribedRadius()
	local rayParam = RaycastParams.new()
	rayParam.FilterType = Enum.RaycastFilterType.Blacklist
	rayParam.FilterDescendantsInstances = {client.Character}
	cameraPoint *= CFrame.Angles(self.recoilSpring.p.X, self.recoilSpring.p.Y, self.recoilSpring.p.Z)
	DebugVisualize.showPoint(subjectPoint, 0.2, DEBUG_TAG)
	
	do local whiskers, centerOrigin = self:getWhiskersOrigin(cameraPoint)
		--resetting t and s directly causes p to update early
		--which causes some jitter, so im using these locals instead
		local tFinal = 0
		local sFinal = self.springSpeedBase
		DebugUI.setListItem("whisker collide n", 0, DEBUG_TAG)
		for i, origin: CFrame in ipairs(whiskers) do
			local totalLength = self.whiskerLength + self.cameraPointOffset.Z
			local direction = origin.LookVector * totalLength
			local result = workspace:Raycast(origin.Position, direction, rayParam)
			DebugVisualize.showRay(origin.Position, direction, DEBUG_TAG, result and DebugVisualize.redSeq or DebugVisualize.greenSeq, 0.02)
			if result then
				DebugUI.incrementListItem("whisker collide n", 1)
				local planePll = CFrame.lookAt(result.Position, result.Position+cameraPoint.LookVector)
				local resSpace = planePll:ToObjectSpace(cameraPoint)
				local push = math.max(0, resSpace.Z + camRadius)
				DebugVisualize.showCFrame(planePll, 0.3, DEBUG_TAG)
				
				local nearCamAdjust = 1 / (math.pi/5 + math.acos(centerOrigin.LookVector:Dot(direction.Unit)))
				push *= nearCamAdjust
				push = math.min(push, self.cameraPointOffset.Z)
				
				local dxAdjust = 1 + math.max(0, self.absdx * 0.08 * -math.sign(self.absdx) * math.sign(resSpace.X))
				local newSpeed = self.springSpeedBase * dxAdjust * nearCamAdjust
				if newSpeed > sFinal then
					sFinal = newSpeed
				end
				
				if push > tFinal then
					tFinal = push
				end
			end
		end
		self.zPop.t = tFinal
		self.zPop.s = sFinal
	end
	cameraPoint *= CFrame.new(0, 0, -self.zPop.p)
	
	local toCam = cameraPoint.Position - subjectPoint
	do local push, result = getRaycastPush(subjectPoint, toCam, rayParam, camRadius)
		if push and push > self.subjectPop.p then
			--print("hit hard limit")
			self.subjectPop.t = push
			self.subjectPop.p = push
		else
			self.subjectPop.t = 0
			self.subjectPop.p = math.min(self.subjectPop.p, math.sqrt(self.cameraPointOffset.X^2 + (self.cameraPointOffset.Z-self.zPop.p)^2))
		end
	end
	cameraPoint += -toCam.Unit * self.subjectPop.p
	
	self.camera.CFrame = cameraPoint
	self.camera.FieldOfView = self:getCurveFov() + self.fovAdjust.Value
	self.absdx = math.sqrt(self.absdx)
	
	DebugUI.setListItem("zpop p", self.zPop.p, DEBUG_TAG)
	DebugUI.setListItem("zpop t", self.zPop.t, DEBUG_TAG)
	DebugUI.setListItem("subjpop p", self.subjectPop.p, DEBUG_TAG)
	DebugUI.setListItem("subjpop t", self.subjectPop.t, DEBUG_TAG)
end

return ThirdPersonCamera