local combatStorage = game:GetService("ReplicatedStorage").CombatStorage
local MathUtil = require(combatStorage.MathUtil)
local Spring = require(combatStorage.Spring)
local DebugVisualize = require(combatStorage.Debug.Visualize)
local DebugUI = require(combatStorage.Debug.UI)

local OFFSET_SPEED = 20
local OFFSET_DAMPEN = 1.5

local Foothold = {}
Foothold.alpha = 0
Foothold.lastStrafe = nil
Foothold.lastGoalJointSpace = nil

function Foothold.new(chain, originMod, root)
	local self =  setmetatable({}, {__index = Foothold})
	self.offset = Spring.new(Vector3.zero)
	self.offset.s = OFFSET_SPEED
	self.offset.d = OFFSET_DAMPEN
	self.offset.t = Vector3.zero
	self.originMod = originMod
	self.chain = chain
	self.length = self.chain:getLength()
	self.topMotor = chain.joints[#chain.joints].motor
	self.rootPart = root
	self.char = self.rootPart.Parent
	self:resetState()
	return self
end

function Foothold:resetState()
	self.offset.p = Vector3.zero
	self.offset.v = Vector3.zero
	
	local world = self.chain.jointToWorldCf(self.topMotor)
	self.lastGoalJointSpace = world:ToObjectSpace(self.chain.effector.CFrame)
	self.lastGoalWorldSpace = self.chain.effector.CFrame
	self.lastJointRootOffset = self.rootPart.CFrame:ToObjectSpace(world)
end

function Foothold:getEllipseOrigin(strafeDir: Vector3)
	local origin: CFrame = CFrame.new(0, -self.length*0.7, 0)
	
	if strafeDir then
		origin *= CFrame.new(0, 0, self.rootPart.Size.Z/2)
		if self.originMod then
			origin *= self.originMod:Inverse()
		end
	elseif self.originMod then
		origin *= self.originMod	
	end
	
	return origin
end

function Foothold:getEllipseOffset(alpha: number)
	local t = alpha * 2*math.pi
	local x = self.length/2 * math.cos(t)
	local y = self.length/2 * math.sin(t)
	
	return CFrame.new(0, y, x)
end

function Foothold:step(humState: Enum.HumanoidStateType, newStrafeDir: Vector3, allowReplant: boolean)
	local goalJointSpace
	local strafeJointSpace
	local jointPos = self.chain.jointToWorldCf(self.topMotor).Position
	local parentCf = self.rootPart.CFrame
	local jointWorld: CFrame = CFrame.fromMatrix(jointPos, parentCf.RightVector, parentCf.UpVector)
	local originJointSpace = self:getEllipseOrigin(newStrafeDir)
	if newStrafeDir then
		strafeJointSpace = parentCf:VectorToObjectSpace(newStrafeDir)
		originJointSpace *= MathUtil.getRotationBetween(-Vector3.zAxis, strafeJointSpace)
	end
	local originOffset = self:getEllipseOffset(newStrafeDir and humState == Enum.HumanoidStateType.Running and self.alpha or 0.75)
	goalJointSpace = originJointSpace * originOffset
	DebugVisualize.showCFrame(jointWorld * originJointSpace, 0.1, "SKELETON")
	
	local rayResult
	do
		local param = RaycastParams.new()
		param.FilterType = Enum.RaycastFilterType.Blacklist
		param.FilterDescendantsInstances = {self.char}

		local toGoal = jointWorld:VectorToWorldSpace(goalJointSpace.Position)
		rayResult = workspace:Raycast(jointPos, toGoal, param)
		DebugUI.setListItem(self.chain.effector.Name .. " raycast", rayResult ~= nil, "SKELETON")
		if rayResult then
			goalJointSpace = jointWorld:ToObjectSpace(jointWorld + toGoal.Unit * rayResult.Distance)
		end
	end

	if
		humState ~= self.lastHumState and (humState == Enum.HumanoidStateType.Running or self.lastHumState == Enum.HumanoidStateType.Running)
		or (strafeJointSpace and not self.lastStrafe)
		or (not strafeJointSpace and self.lastStrafe)
		or strafeJointSpace and self.lastStrafe and math.acos(math.clamp(strafeJointSpace:Dot(self.lastStrafe), -1, 1)) > math.rad(15)
		-- dont delete this its for smoothing large changes in move dir
		-- NOT some leftover redundancy for replanting
	then
		local newGoalWorld = jointWorld * goalJointSpace
		local last = parentCf * self.lastJointRootOffset * self.lastGoalJointSpace + self.offset.p
		--self.offset.v = Vector3.zero
		self.offset.p = last.Position - newGoalWorld.Position
	end

	if strafeJointSpace or self.lastStrafe or humState ~= Enum.HumanoidStateType.Running then
		self.lastGoalJointSpace = goalJointSpace
	elseif humState == Enum.HumanoidStateType.Running then --idle, feet already planted last frame
		local dot = self.lastGoalJointSpace.Position.Unit:Dot(goalJointSpace.Position.Unit)
		local angle = math.acos(math.clamp(dot, -1, 1))
		local lastWorld = parentCf * self.lastJointRootOffset * self.lastGoalJointSpace + self.offset.p
		local newWorld = jointWorld * goalJointSpace
		if (angle > math.rad(20) or newWorld.Position.Y - lastWorld.Position.Y > 0.1) and allowReplant then
			self.lastGoalJointSpace = goalJointSpace
			self.offset.p = lastWorld.Position - newWorld.Position
			-- check if foot is far enough to replant
			if self.offset.v.Magnitude <= self.offset.s*0.1 and jointWorld.Position.Y - newWorld.Position.Y > 0.5 then
				self.offset.v = Vector3.new(0, self.offset.s*1.5, 0) - jointWorld.LookVector*self.offset.s
			end
		elseif self.lastGoalWorldSpace then
			self.lastGoalJointSpace = jointWorld:ToObjectSpace(self.lastGoalWorldSpace)
		end
	end
	self.lastGoalWorldSpace = jointWorld * self.lastGoalJointSpace
	self.chain:cycleCCD((self.lastGoalWorldSpace + self.offset.p).Position)
	self.lastStrafe = strafeJointSpace
	self.lastHumState = humState
	self.lastJointRootOffset = parentCf:ToObjectSpace(jointWorld)
	if not newStrafeDir and rayResult then
		self.chain.joints[1].motor.C0 *= CFrame.identity:Lerp(
			MathUtil.getRotationBetween(Vector3.yAxis, self.chain.effector.CFrame:VectorToObjectSpace(rayResult.Normal)),
			math.clamp(1 - math.tanh(self.offset.p.Magnitude/2), 0, 1)
		)
	end
	
	DebugVisualize.showPoint(self.lastGoalWorldSpace.Position + self.offset.p, 0.2, "SKELETON", Color3.new(0, 1, 0))
	DebugVisualize.showPoint(self.lastGoalWorldSpace.Position, 0.1, "SKELETON")
	DebugVisualize.showCFrame(jointWorld, 0.1, "SKELETON")
	DebugUI.setListItem(self.chain.effector.Name .. " offset", self.offset.p.Magnitude, "SKELETON")
end

return Foothold