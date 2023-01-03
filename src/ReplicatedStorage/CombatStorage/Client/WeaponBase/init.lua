local Players = game:GetService("Players")
local Maid = require(script.Parent.Parent.Maid)
local HumanoidController = require(script.Parent.HumanoidController)
local AnimationClipProvider = game:GetService("AnimationClipProvider")
local client = Players.LocalPlayer

local WeaponBase = {}

function WeaponBase.fromServerInfo(tool, weaponInfo)
	local self = setmetatable(weaponInfo, {__index = WeaponBase})
	self.tool = tool
	self.maid = Maid.new()
	self.weaponBehavior = self.maid:add(require(self.behaviorModule).fromServerInfo(self.behaviorInfo))

	self.tool.Destroying:Connect(function()
		self:destroy()
	end)
	self.tool.Equipped:Connect(function()
		self.humanoidController = HumanoidController.newR15(client.Character.Humanoid)
		self.humanoidController:init()
	end)
	self.tool.Unequipped:Connect(function()
		self.humanoidController:destroy()
		self.humanoidController = nil
	end)
	
	self.anims = {}
	local animsToLoad = require(self.animationModule)
	local animator: Animator = client.Character.Humanoid.Animator
	for name, animBase in pairs(animsToLoad[game.CreatorId]) do
		if typeof(animBase) == "Instance" then
			if animBase:IsA("Animation") then
				animBase = animator:LoadAnimation(animBase)
			elseif animBase:IsA("AnimationClip") then
				local animation = Instance.new("Animation")
				animation.AnimationId = AnimationClipProvider:RegisterAnimationClip(animBase)
				animBase = animator:LoadAnimation(animation)
			end
		end
		self.anims[name] = animBase
	end
	
	self.weaponBehavior:initAsOwner(self)
	return self
end

function WeaponBase:destroy()
	self.maid:destroy()
	if self.humanoidController then
		self.humanoidController:destroy()
		self.humanoidController = nil
	end
end

return WeaponBase