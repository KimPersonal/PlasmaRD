local RunService = game:GetService("RunService")
local moduleFolder = game:GetService("ReplicatedStorage").CombatStorage
local MathUtil = require(moduleFolder.MathUtil)
local DebugUI = require(moduleFolder.Debug.UI)
local DebugVisualize = require(moduleFolder.Debug.Visualize)

local JointChain = {}
JointChain.pullWeight = 0
JointChain.pullTolerance = 1
JointChain.annealLimit = 2
JointChain.allowTransform = false

function JointChain.jointToWorldCf(motor: Motor6D): CFrame
	assert(motor.Part0, "inactive motor")
	return motor.Part0.CFrame * motor.C0 * motor.Transform
end

function JointChain.new(joints)
	local self = setmetatable({}, {__index = JointChain})
	self.joints = joints
	self.effector = self.joints[1].motor.Part1
	self.debug_tag = "JOINT" .. self.effector.Name
	self.lastEffectorPos = self.effector.Position
	self.stepConnection = RunService.Stepped:Connect(function()
		if not self.allowTransform then
			for _, joint in ipairs(self.joints) do
				joint.motor.Transform = CFrame.identity
			end
		end
	end)
	return self
end

-- root's joint is included at the end
function JointChain.fromEffectorTo(effector: BasePart, root)
	assert(effector, "missing effector")
	local nextPart = effector
	local joints = {}
	while nextPart do
		local motor = nextPart:FindFirstChildWhichIsA("Motor6D")
		local joint = {motor = motor, weight = 1, weightMod = 0, C0Def = motor.C0, axis = nil}
		table.insert(joints, joint)
		if nextPart == root then break end
		nextPart = motor and motor.Part0
	end
	return JointChain.new(joints)
end

function JointChain:reset()
	for _, joint in ipairs(self.joints) do
		joint.motor.C0 = joint.C0Def
		joint.weightMod = 1
	end
end

function JointChain:stepCCD(goal: Vector3, showDebug: boolean)
	for _, joint in ipairs(self.joints) do
		if joint.weight <= 0 then continue end
		local motor = joint.motor
		local jointWorld = JointChain.jointToWorldCf(motor)
		local toEffector = jointWorld:PointToObjectSpace(self.effector.Position)
		local toGoal = jointWorld:PointToObjectSpace(goal)
		
		local rot = MathUtil.getRotationBetween(toEffector, toGoal)
		if showDebug then DebugVisualize.showPoint(jointWorld.Position, 0.1, self.debug_tag) end
		local finalWeight = math.clamp(joint.weight * joint.weightMod, 0, 1)
		rot = CFrame.new():Lerp(rot, finalWeight)
		motor.C0 *= rot
		
		if joint.axis then
			local invRot = rot:Inverse()
			local parentAxis = invRot * joint.axis 
			local axisRot = MathUtil.getRotationBetween(joint.axis, parentAxis)
			motor.C0 *= axisRot
		end
		
		local limits = joint.limits
		if limits then
			local x, y, z = motor.C0:ToEulerAnglesXYZ()
			x = limits.x and math.clamp(x, limits.x[1], limits.x[2]) or x
			y = limits.y and math.clamp(y, limits.y[1], limits.y[2]) or y
			z = limits.z and math.clamp(z, limits.z[1], limits.z[2]) or z
			motor.C0 = CFrame.new(motor.C0.Position) * CFrame.Angles(x, y, z)
		end
		DebugVisualize.showRay(jointWorld.Position, motor.C0.LookVector, self.debug_tag)
	end
end

function JointChain:cycleCCD(goal: Vector3)
	if not self.allowTransform then
		for _, joint in ipairs(self.joints) do
			if joint.preOffset then joint.motor.C0 *= joint.preOffset end
		end
	end
	
	local cycleLimit = #self.joints*2
	local success = false
	for attempt = 0, self.annealLimit do
		for i, joint in ipairs(self.joints) do
			if joint.annealOffset then joint.motor.C0 *= joint.annealOffset end
			joint.weightMod = (i/#self.joints)^(attempt)
		end
		for _ = 1, cycleLimit do
			self:stepCCD(goal)
			if (goal - self.effector.Position).Magnitude <= 0.1 then
				success = true
				DebugVisualize.showPoint(self.effector.Position, 0.1, self.debug_tag, Color3.new(0, 1, 0))
				break
			end
		end
		DebugUI.setListItem(self.effector.Name .. "CCD anneal", attempt, self.debug_tag)
		if success then
			break
		end
	end
	self.lastEffectorPos = self.effector.Position
end

function JointChain:getRootPulled(root)
	
end

function JointChain:getLength()
	local length = 0
	local lastJoint
	for _, joint in ipairs(self.joints) do
		if not joint.lengthless then
			local motor = joint.motor
			length += motor.C1.Position.Magnitude
			if lastJoint then
				length += lastJoint.motor.C0.Position.Magnitude
			end
			lastJoint = joint
		end
	end
	return length
end

function JointChain:destroy()
	self.stepConnection:Disconnect()
	for _, joint in ipairs(self.joints) do
		joint.motor.C0 = joint.C0Def
	end
end

return JointChain