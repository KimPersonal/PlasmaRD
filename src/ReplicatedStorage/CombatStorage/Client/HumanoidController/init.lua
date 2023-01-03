local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Skeleton = require(script.Skeleton)
local Maid = require(script.Parent.Parent.Maid)
local Spring = require(script.Parent.Parent.Spring)
local MathUtil = require(script.Parent.Parent.MathUtil)
local CheckRig = require(script.Parent.Parent.CheckRig)
local DebugUI = require(script.Parent.Parent.Debug.UI)

local client = Players.LocalPlayer
local lookRemote = script.Parent.Parent.Remote.UpdateLookDirection
local HumanoidController = {}
HumanoidController.lookEnabled = false
HumanoidController.lookReplicationInterval = 0.15

function HumanoidController.newR15(humanoid: Humanoid)
	assert(humanoid and humanoid.Parent and humanoid.Parent:IsA("Model") and CheckRig(humanoid.Parent), "improper R15 character")
	local self = setmetatable({}, {__index = HumanoidController})
	self.hum = humanoid
	self.char = self.hum.Parent
	self.root = self.char.HumanoidRootPart
	self.lastCf = self.root.CFrame
	self.owner = Players:GetPlayerFromCharacter(self.char)
	self.clientOwned = self.owner == client
	self.maid = Maid.new()
	self.skeleton = self.maid:add(Skeleton.fromR15(humanoid.Parent))
	
	self.rotator = self.maid:add(Instance.new("AlignOrientation", self.root))
	self.rotator.Mode = Enum.OrientationAlignmentMode.OneAttachment
	self.rotator.Attachment0 = self.root.RootRigAttachment
	self.rotator.MaxAngularVelocity = math.pi*3
	self.rotator.MaxTorque = math.huge
	self.rotator.Responsiveness = 200
	--self.rotator.RigidityEnabled = true
	self.rotator.CFrame = self.root.CFrame
	self.rotator.Enabled = false
	
	self.lookDirection = self.root.CFrame.LookVector
	self.lastLookReplication = os.clock()
	
	--[[self.mover = self.maid:add(Instance.new("VectorForce", self.root))
	self.mover.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	self.mover.Attachment0 = self.root.RootRigAttachment
	self.mover.ApplyAtCenterOfMass = true
	self.mover.Enabled = false]]
	
	if not self.clientOwned then
		for _, chain in pairs(self.skeleton.chains) do
			chain.annealLimit = 1
		end
		self.maid:add(lookRemote.OnClientEvent:Connect(function(info)
			for _, info in ipairs(info) do
				if info.char == self.char then
					self.lookEnabled = info.lookEnabled
					self.lookDirection = info.lookT
					break
				end
			end
		end))
	end
	
	return self
end

function HumanoidController:init()
	self.hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	self.id = HttpService:GenerateGUID(false)
	-- Stepped -> apply trans internal -> Heartbeat -> RenderStepped: CCD, desync, await serial -> pll render start
	-- -> yield serial -> begin serial, reset joints, luau GC -> animation retargeting -> set trans internal -> Stepped
	RunService:BindToRenderStep("humControl" .. self.id, Enum.RenderPriority.Character.Value, function(dt)
		DebugUI.setListItem("prerender last", dt, "HUMCONTROL")
		local last = os.clock()
		self:preRender(dt)
		task.desynchronize()
		task.synchronize()
		self:postRender()
		DebugUI.setListItem("postrender insert", os.clock()-last, "HUMCONTROL")
	end)
end

function HumanoidController:getState()
	if self.clientOwned then
		return self.hum:GetState(), self.hum.MoveDirection
	else
		local newCf = self.root.CFrame
		local dp = self.root.AssemblyLinearVelocity
		if dp.Magnitude < 0.4 then
			return self.hum:GetState(), Vector3.zero
		end
		return self.hum:GetState(), dp.Unit*Vector3.new(1, 0, 1)
	end
end

function HumanoidController:preRender(dt)
	local humState, moveDirection = self:getState()
	
	if not self.clientOwned then
		self.skeleton:throttleAction(self)
	end
	self.skeleton:stepLowerBody(self)
	
	if self.clientOwned then
		DebugUI.setListItem("hum lookWORLD", self.lookDirection, "HUMCONTROL")
		self:lookDirectionStep(moveDirection)
		if humState == Enum.HumanoidStateType.Freefall then
			self.hum.AutoRotate = false
			self.hum.WalkSpeed = 0.5
			self.root:ApplyImpulse(self.root.CFrame.LookVector * (self.root.AssemblyMass*2.3))
		else
			if not self.lookEnabled then
				self.hum.AutoRotate = true
			end
			self.hum.WalkSpeed = 16
		end
	end
	
	self.skeleton:stepUpperBody(self, self.lookEnabled and self.lookDirection)
end

function HumanoidController:postRender()
	if not self.clientOwned then
		self.skeleton:savePose()
	end
	self.skeleton:resetJoints()
end

function HumanoidController:lookDirectionStep(moveDirection)
	if self.lookEnabled then
		moveDirection *= Vector3.new(1, 0, 1)
		local flatLook = self.lookDirection * Vector3.new(1, 0, 1)
		local rootCF = self.root.CFrame
		local rootFace = self.rotator.CFrame.LookVector * Vector3.new(1, 0, 1)
		local idle = moveDirection.Magnitude == 0
		local angle = math.acos(math.clamp(flatLook.Unit:Dot(rootFace.Unit), -1, 1))
		
		self.hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		self.hum.AutoRotate = false
		if not idle or angle > math.rad(40) then
			self.rotator.Enabled = true
			self.rotator.Responsiveness = idle and 50 or 140
			self.rotator.CFrame = CFrame.lookAt(rootCF.Position, rootCF.Position + flatLook)
		end
		DebugUI.setListItem("root phys y res", self.rotator.Responsiveness, "HUMCONTROL")
	else
		self.rotator.Enabled = false
		self.rotator.CFrame = self.root.CFrame
		self.hum.AutoRotate = true
		self.hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	
	local t = os.clock()
	if self.clientOwned and t - self.lastLookReplication >= self.lookReplicationInterval then
		self.lastLookReplication = t
		lookRemote:FireServer(self.lookEnabled, self.lookDirection)
	end
end

function HumanoidController:destroy()
	self.hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	self.hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	RunService:UnbindFromRenderStep("humControl" .. self.id)
	self.maid:destroy()
end

return HumanoidController