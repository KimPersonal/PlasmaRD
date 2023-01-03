local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage").CombatStorage
local Maid = require(storage.Maid)
local CheckRig = require(storage.CheckRig)
local creationRemote = storage.Remote.WeaponCreated
local requestRemote = storage.Remote.RequestReplication
local animFolder = storage.Animations

local WeaponBase = {}
WeaponBase.isWeapon = true

local function addModelJoints(model: Model)
	local grip = model:FindFirstChild("Grip")
	assert(grip, "model missing grip part \"Grip\"")
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= grip then
			local motor = Instance.new("Motor6D")
			motor.Part0 = grip
			motor.Part1 = part
			motor.C0 = grip.CFrame:ToObjectSpace(part.CFrame)
			motor.Parent = motor.Part1
		end
	end
	return model
end

function WeaponBase.new(weaponType, carrier, baseModel)
	assert(CheckRig(carrier.char), "Abnormal character")
	
	local self = setmetatable({}, {__index = WeaponBase})
	local animModule = animFolder:FindFirstChild(baseModel.Name)
	self.maid = Maid.new()
	self.baseModel = baseModel
	self.model = addModelJoints(baseModel:Clone())
	self.animModule = animModule
	self.tool = Instance.new("Tool")
	self.tool.RequiresHandle = false
	self.tool.Name = baseModel.Name
	
	self.tool.Destroying:Connect(function()
		self:destroy()
	end)
	self.tool.Equipped:Connect(function()
		self.equipped = true
	end)
	self.tool.Unequipped:Connect(function()
		self.equipped = false
	end)
	
	self.carrier = self.maid:add(carrier)
	self.weaponBehavior = self.maid:add(weaponType)
	self.carrier:init(self)
	self.weaponBehavior:init(self)
	
	local gripMotor = Instance.new("Motor6D")
	local attachment = self.carrier.char:FindFirstChild("RightGripAttachment", true)
	gripMotor.Part0 = attachment.Parent
	gripMotor.Part1 = self.model:FindFirstChild("Grip")
	gripMotor.Parent = gripMotor.Part1
	self.model.Parent = self.tool
	
	local replicatedTo = {}
	local replicationInfo = {
		behaviorModule = self.weaponBehavior.clientModule,
		behaviorInfo = self.weaponBehavior:getToReplicate(),
		animationModule = animModule,
		baseModel = baseModel
	}
	creationRemote:FireAllClients(self.carrier.player, self.tool, replicationInfo)
	for _, plr in ipairs(Players:GetPlayers()) do
		replicatedTo[plr.UserId] = true
	end
	
	self.maid:add(requestRemote.OnServerEvent:Connect(function(plr)
		if not replicatedTo[plr.UserId] then
			print("replicating to new player", plr)
			replicatedTo[plr.UserId] = true
			creationRemote:FireClient(plr, self.carrier.player, self.tool, replicationInfo)
		end
	end))
	self.maid:add(Players.PlayerRemoving:Connect(function(plr)
		replicatedTo[plr.UserId] = nil
	end))
	
	return self
end

function WeaponBase:destroy()
	self.equipped = false
	self.maid:destroy()
end

return WeaponBase