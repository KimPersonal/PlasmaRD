local RunService = game:GetService("RunService")
local JointChain = require(script.Parent.JointChain)
local Maid = require(script.Parent.Parent.Parent.Maid)
local MathUtil = require(script.Parent.Parent.Parent.MathUtil)
local Spring = require(script.Parent.Parent.Parent.Spring)
local DebugVisualize = require(script.Parent.Parent.Parent.Debug.Visualize)
local DebugUI = require(script.Parent.Parent.Parent.Debug.UI)
local FootholdBase = require(script.Parent.Foothold)
local DefineR15 = require(script.DefineR15)
local activeSkeletons = {}
local activeCount = 0
setmetatable(activeSkeletons, {__mode = "k"})

local DEBUG_TAG = "SKELETON"

local function setActive(skel, active)
	activeSkeletons[skel] = active
	activeCount = 0
	for skel, act in pairs(activeSkeletons) do
		if act then
			activeCount += 1
		end
	end
	--print("new active count", activeCount)
end

local Skeleton = {}
Skeleton.lastMoveDirection = Vector3.zero
Skeleton.framesPerUpdate = 1
Skeleton.skippedFrames = 0
Skeleton.canStep = true
Skeleton.throttlePerDepth = 1/25
Skeleton.throttlePerScreenScale = 1/0.3
Skeleton.throttlePerSkeleton = 1/4
Skeleton.savedPoses = nil

function Skeleton.new(hum, rootMotor, torsoMotor, chains, footholds)
	local self = setmetatable({}, {__index = Skeleton})
	self.hum = hum
	self.char = hum.Parent
	self.root = self.char.PrimaryPart
	self.rootMotor = rootMotor
	self.rootMotorC0 = rootMotor.C0
	self.torsoMotor = torsoMotor
	self.torsoMotorC0 = torsoMotor.C0
	self.chains = chains
	self.footholds = footholds
	self.maid = Maid.new()
	self.leanSpring = Spring.new(Vector3.yAxis)
	self.leanSpring.s = 25
	self.hipTwistSpring = Spring.new(0)
	self.hipTwistSpring.s = 15
	self.rootMotorSpring = Spring.new(Vector3.zero)
	self.rootMotorSpring.d = 0.7
	self.rootMotorSpring.s = 10
	self.lookAngleSpring = Spring.new(Vector3.zero)
	self.lookAngleSpring.s = 25
	self.lastStep = os.clock()
	setActive(self, true)
	
	for _, chain in pairs(self.chains) do
		self.maid:add(chain)
	end
	
	self.maid:add(self.hum.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Landed then
			self.rootMotorSpring:Impulse(self.rootMotor.Part0.AssemblyLinearVelocity.Unit*20)
		end
	end))
	
	self.maid:add(RunService.Stepped:Connect(function()
		if self.lookAngleSpring.t ~= Vector3.zero then
			self.torsoMotor.Transform = CFrame.identity
		end
	end))
	
	return self
end

function Skeleton.fromR15(char: Model)
	local chains = {}
	for effectorName, config in pairs(DefineR15) do
		local effector = char:FindFirstChild(effectorName)
		assert(effector and effector:IsA("BasePart"), "improper r15 effector")
		local chain = JointChain.fromEffectorTo(effector, char:FindFirstChild(config.root))
		chain.pullWeight = config.pullWeight
		chain.pullTolerance = config.pullTolerance
		chain.allowTransform = config.allowTransform
		
		for i, jointInfo in pairs(config.jointInfo) do
			for k, v in pairs(jointInfo) do
				chain.joints[i][k] = v
			end
		end
		
		chains[effectorName] = chain
	end
	
	local root = char:FindFirstChild("HumanoidRootPart")
	local rightLeg = char:FindFirstChild("RightUpperLeg")
	local leftLeg = char:FindFirstChild("LeftUpperLeg")
	
	local footholds = {
		FootholdBase.new(chains.RightFoot, CFrame.new(0.1, 0, 0), root),
		FootholdBase.new(chains.LeftFoot, CFrame.new(-0.1, 0, 0), root)
	}
	
	return Skeleton.new(char:FindFirstChildWhichIsA("Humanoid"), char:FindFirstChild("LowerTorso"):FindFirstChild("Root"), char:FindFirstChild("UpperTorso"):FindFirstChild("Waist"), chains, footholds)
end

function Skeleton:resetJoints()
	self.rootMotor.C0 = self.rootMotorC0
	self.torsoMotor.C0 = self.torsoMotorC0
	for _, chain in pairs(self.chains) do
		chain:reset()
	end
end

function Skeleton:throttleAction(controller)
	local rootPos = controller.root.Position
	local screenPoint: Vector3, inBounds = workspace.CurrentCamera:WorldToViewportPoint(rootPos)
	local screenSize = workspace.CurrentCamera.ViewportSize
	if inBounds then
		local ignore = {controller.char}
		local obscuringParts = workspace.CurrentCamera:GetPartsObscuringTarget({rootPos}, ignore)
		local blocked = false
		for _, part in ipairs(obscuringParts) do
			if part.Transparency <= 0 and part.Size.Magnitude >= controller.char:GetExtentsSize().Magnitude then
				blocked = true
			end
		end
		if not blocked then
			local pointScale = Vector2.new(screenPoint.X/screenSize.X, screenPoint.Y/screenSize.Y)
			local dist = (pointScale - Vector2.new(0.5, 0.5)).Magnitude
			local frameDelay = math.floor(self.throttlePerScreenScale*dist + self.throttlePerDepth*screenPoint.Z + self.throttlePerSkeleton*activeCount)
			self.framesPerUpdate = math.min(6, frameDelay)
		else
			self.framesPerUpdate = math.huge
		end
	else
		self.framesPerUpdate = math.huge
	end
	
	self.skippedFrames += 1
	if self.skippedFrames >= self.framesPerUpdate then
		self.skippedFrames = 0
		self.canStep = true
		setActive(self, true)
	else
		self.canStep = false
		setActive(self, nil)
		if self.framesPerUpdate ~= math.huge then
			if self.savedPoses then
				for motor, c0 in pairs(self.savedPoses) do
					motor.C0 = c0
				end
			else
				warn("skipping skeleton update this frame without fallback poses")
			end
		end
	end
	DebugUI.setListItem("skeleton frame delay", self.framesPerUpdate, "SKELETON")
end

function Skeleton:stepUpperBody(controller, lookDirection: Vector3?)
	if not self.canStep then return end
	local motor: Motor6D = self.torsoMotor
	if lookDirection then
		--lookDirection = lookDirection.Unit
		motor.C0 = self.torsoMotorC0
		local part1 = motor.Part1
		local jointCf = JointChain.jointToWorldCf(motor)
		DebugVisualize.showRay(part1.Position, lookDirection*9, DEBUG_TAG, ColorSequence.new(Color3.new(0, 0.784314, 1)))
		DebugVisualize.showRay(part1.Position, part1.CFrame.UpVector*5, DEBUG_TAG, ColorSequence.new(Color3.new(1, 1, 0)))
		DebugVisualize.showCFrame(part1.CFrame, 0.2, "SKELETON", Color3.new(1, 1, 0))
		local lookObjectSpace = jointCf:VectorToObjectSpace(lookDirection).Unit
		lookObjectSpace = Vector3.new(math.clamp(lookObjectSpace.X, -0.5, 0.5), math.clamp(lookObjectSpace.Y, -0.8, 0.8), math.clamp(lookObjectSpace.Z, -1, -0.15))
		local rotation = MathUtil.getRotationBetween(Vector3.new(0, 0, -1), lookObjectSpace)
		--[[local x, y, z = rotation:ToEulerAnglesXYZ()
		x = math.clamp(x, -math.rad(30), math.rad(30))
		y = math.clamp(y, -math.rad(70), math.rad(70))
		z = math.clamp(z, -math.rad(10), math.rad(10))]]
		self.lookAngleSpring.t = Vector3.new(rotation:ToEulerAnglesXYZ())
	else
		self.lookAngleSpring.t = Vector3.zero
	end
	motor.C0 *= CFrame.Angles(self.lookAngleSpring.p.X, self.lookAngleSpring.p.Y, self.lookAngleSpring.p.Z)
	motor.C0 *= CFrame.Angles(self.rootMotorSpring.p.Magnitude * -math.rad(20), 0, 0)
	DebugUI.setListItem("lookAngle T", self.lookAngleSpring.t, "SKELETON")
	DebugVisualize.showCFrame(JointChain.jointToWorldCf(motor), 0.1, "SKELETON")
	DebugVisualize.showCFrame(JointChain.jointToWorldCf(self.chains.RightHand.joints[1].motor), 0.1, "SKELETON")
	DebugVisualize.showCFrame(JointChain.jointToWorldCf(self.chains.LeftHand.joints[1].motor), 0.1, "SKELETON")
end

function Skeleton:stepLowerBody(controller)
	if not self.canStep then return end
	local t = os.clock()
	local dt = t - self.lastStep
	local humState, moveDirection = controller:getState()
	local rootCf: CFrame = controller.root.CFrame
	local idle = moveDirection.Magnitude == 0
	local stateRunning = humState == Enum.HumanoidStateType.Running
	DebugVisualize.showRay(controller.root.Position, rootCf.LookVector*3, DEBUG_TAG)
	DebugVisualize.showRay(controller.root.Position, moveDirection*3, DEBUG_TAG, ColorSequence.new(Color3.new(1, 0, 0)))
	DebugVisualize.showCFrame(controller.root.CFrame, 0.2, "SKELETON")
	
	do
		DebugVisualize.showCFrame(self.rootMotor.Part1.CFrame, 0.1, "SKELETON")
		if (idle and self.lastMoveDirection ~= Vector3.zero or not idle and math.acos(math.clamp(moveDirection:Dot(self.lastMoveDirection), -1, 1)) > math.pi/6) and stateRunning then
			self.rootMotorSpring:Impulse(self.lastMoveDirection*4 - Vector3.new(0, 3, 0))
		end
		local motor = self.rootMotor
		local part1 = motor.Part1
		motor.C0 = self.rootMotorC0 + self.rootMotorSpring.p
		
		do
			local jointWorld = JointChain.jointToWorldCf(motor)
			local adjustedJoint = CFrame.fromMatrix(jointWorld.Position, rootCf.RightVector, rootCf.UpVector)
			local objectMove = -(adjustedJoint:VectorToObjectSpace(moveDirection))
			local angle = math.atan(objectMove.X/math.abs(objectMove.Z))
			DebugUI.setListItem("hip angle raw", math.deg(angle), "SKELETON")
			if math.abs(objectMove.X) < 0.1 then angle = math.abs(angle) end
			if objectMove.Z < -0.1 then angle -= math.pi/2*math.sign(angle) end
			angle = math.pi/4 * math.tanh(angle)
			self.hipTwistSpring.t = not idle and angle or 0
			DebugUI.setListItem("hip angle t", math.deg(angle), DEBUG_TAG)
			DebugUI.setListItem("hip strafe x", objectMove.X, DEBUG_TAG)
			DebugUI.setListItem("hip strafe z", objectMove.Z, DEBUG_TAG)
			adjustedJoint *= CFrame.fromAxisAngle(Vector3.yAxis, self.hipTwistSpring.p)
			motor.C0 *= jointWorld:ToObjectSpace(adjustedJoint)
		end
		
		do
			self.leanSpring.t = moveDirection + Vector3.yAxis
			motor.C0 *= CFrame.new():Lerp(MathUtil.getRotationBetween(
				Vector3.new(0, 1, 0),
				part1.CFrame:VectorToObjectSpace(self.leanSpring.p)
			), 0.2)
			DebugVisualize.showPoint(motor.Part1.Position, 0.1, DEBUG_TAG, Color3.new(0, 1, 0))
			DebugVisualize.showCFrame(self.rootMotor.Part0.CFrame * motor.C0, 0.2, "SKELETON", Color3.new(1, 1, 1))
			DebugVisualize.showPoint((self.rootMotor.Part0.CFrame * motor.C0 + self.rootMotorSpring.v.Unit).Position, 0.2, "SKELETON", Color3.new(0.219608, 1, 0.780392))
			DebugVisualize.showPoint((self.rootMotor.Part0.CFrame * motor.C0 + self.rootMotorSpring.p).Position, 0.2, "SKELETON", Color3.new(1, 0.254902, 0.254902))
		end
	end
	
	for i, foothold in ipairs(self.footholds) do
		local last = self.footholds[i-1]
		local unstableCount = 0
		if not idle then
			foothold.alpha = last and last.alpha + 0.5 or foothold.alpha + dt * (((0.035/16) * controller.hum.WalkSpeed) / (1/60))
		end
		DebugUI.setListItem("unstable body", unstableCount, "SKELETON")
		
		for _, other in ipairs(self.footholds) do
			if other ~= foothold and other.offset.v.Magnitude > other.offset.s*0.1 then
				unstableCount += 1
			end
		end
		foothold:step(humState, moveDirection ~= Vector3.zero and moveDirection, unstableCount < #self.footholds-1)
	end
	
	self.lastMoveDirection = moveDirection
	self.lastStep = t
end

-- will only search for joints once, so i'll make sure theres some
-- rig check before this is run
function Skeleton:savePose()
	if self.canStep then
		if not self.savedPoses then
			self.savedPoses = {}
			for _, desc in ipairs(self.char:GetDescendants()) do
				if desc:IsA("Motor6D") then
					self.savedPoses[desc] = desc.C0
				end
			end
		else
			for motor in pairs(self.savedPoses) do
				self.savedPoses[motor] = motor.C0
			end
		end
	end
end

function Skeleton:destroy()
	self.maid:destroy()
	setActive(self, nil)
end

return Skeleton