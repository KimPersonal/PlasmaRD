local HumanoidController = require(script.Parent.HumanoidController)
local CheckRig = require(script.Parent.Parent.CheckRig)
local Maid = require(script.Parent.Parent.Maid)

local UnownedWeapon = {}

function UnownedWeapon.new(owner, tool: Tool, weaponInfo)
	local self = setmetatable(weaponInfo, {__index = UnownedWeapon})
	self.maid = Maid.new()
	self.weaponBehavior = self.maid:add(require(self.behaviorModule).fromServerInfo(self.behaviorInfo))
	self.anims = require(self.animationModule)
	self.owner = owner
	
	local char = owner:IsA("Player") and owner.Character or owner
	assert(CheckRig(char), "Abnormal character")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	
	tool.AncestryChanged:Connect(function()
		if self.humanoidController then
			self.humanoidController:destroy()
		end
		if tool.Parent == char then
			self.humanoidController = HumanoidController.newR15(hum)
			self.humanoidController:init()
		end
	end)
	
	tool.Destroying:Connect(function()
		self:destroy()
	end)
	
	self.weaponBehavior:initAsObserver(self)
	
	return self
end

function UnownedWeapon:destroy()
	self.maid:destroy()
	if self.humanoidController then
		self.humanoidController:destroy()
	end
end

return UnownedWeapon