local TweenService = game:GetService("TweenService")
local TweenNumberSequence = require(game:GetService("ReplicatedStorage").CombatStorage.TweenNumberSequence)

local beamInfo = TweenInfo.new(0.04, Enum.EasingStyle.Linear)
local function fireEffect(weapon)
	local model = weapon.tool:FindFirstChildWhichIsA("Model")
	local effectPart = model.EffectPart
	local frontAtt = effectPart.Front
	local backAtt = effectPart.Back
	frontAtt.Position = backAtt.Position
	backAtt.Star:Emit(1)
	
	local beams = {effectPart.Type1, effectPart.Type2}
	for _, beam in ipairs(beams) do
		TweenNumberSequence(beam, beamInfo, {Transparency = NumberSequence.new(0.2)}, function()
			TweenNumberSequence(beam, beamInfo, {Transparency = NumberSequence.new(1)})
		end)
	end
	TweenService:Create(frontAtt, TweenInfo.new(0.07, Enum.EasingStyle.Linear), {Position = -backAtt.Position}):Play()
	
	local sound: Sound = effectPart.fire:Clone()
	sound.Parent = effectPart
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	local light = effectPart.Light
	light.Enabled = true
	task.wait(0.09)
	light.Enabled = false
end

local studioAnims = {
	equip = script.Raws.Equip2,
	idle = script.Raws.Idle2,
	aim = script.Raws.AimRaw,
	reload = script.Raws.Reload,
	onShotFired = fireEffect
}

local plasmaAnims = {
	equip = script.Uploaded.Equip,
	idle = script.Uploaded.Idle,
	aim = script.Uploaded.Aim,
	reload = script.Uploaded.Reload,
	onShotFired = fireEffect
}

local psdAnims = {

}

return {
	[0] = plasmaAnims,
	[4192306] = plasmaAnims,	--plasma group
	[105312406] = plasmaAnims,	--viz
}