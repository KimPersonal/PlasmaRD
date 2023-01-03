local Debris = game:GetService("Debris")
local Tags = require(script.Parent.Tags)
local UI = require(script.Parent.UI)

local Visualize = {}
Visualize.redSeq = ColorSequence.new(Color3.new(1, 0, 0))
Visualize.greenSeq = ColorSequence.new(Color3.new(0, 1, 0))

local function checkTag(tag: string?): boolean
	if tag then
		Tags.newTag(tag)
		UI.makeTagToggle(tag)
		return Tags.get(tag)
	end
	return false
end

function Visualize.showPoint(pos: Vector3, size: number, tag: string?, color: Color3?, lifetime: number?, transparency: number?): BasePart?
	if not checkTag(tag) then return end
	color = color or Color3.fromRGB(255, 0, 255)
	lifetime = lifetime or 0
	
	local part = Instance.new("Part", workspace)
	part.Shape = Enum.PartType.Ball
	part.CFrame = CFrame.new(pos)
	part.Size = Vector3.new(size, size, size)
	part.Color = color
	part.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	part.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	Debris:AddItem(part, lifetime)
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = transparency or 0
	highlight.OutlineTransparency = 1
	highlight.Enabled = true
	highlight.Adornee = part
	highlight.Parent = part
	return part
end

function Visualize.showRay(origin: Vector3, direction: Vector3, tag: string?, color: ColorSequence?, width: number?, lifetime: number?): BasePart?
	if not checkTag(tag) then return end
	color = color or ColorSequence.new(Color3.new(255, 0, 255))
	lifetime = lifetime or 0
	width = width or 0.05
	
	local part = Instance.new("Part", workspace)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CFrame = CFrame.new(origin)
	part.Size = Vector3.new(0.1, 0.1, 0.1)
	part.Transparency = 1
	Debris:AddItem(part, lifetime)
	
	local att0 = Instance.new("Attachment", part)
	local att1 = Instance.new("Attachment", part)
	att0.WorldPosition = origin
	att1.WorldPosition = origin + direction
	
	local beam = Instance.new("Beam", part)
	beam.FaceCamera = true
	beam.Color = color
	beam.Transparency = NumberSequence.new(0.2)
	beam.Width0 = width
	beam.Width1 = width
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	return part
end

function Visualize.showCFrame(cf: CFrame, size: number, tag: string?, color: Color3?, lifetime: number?)
	if not checkTag(tag) then return end
	local part = Visualize.showPoint(cf.Position, size, tag, color, lifetime)
	part.CFrame = cf
	Visualize.showRay(cf.Position, cf.RightVector*0.7, tag, ColorSequence.new(Color3.new(255, 0, 0)), 0.1, lifetime)
	Visualize.showRay(cf.Position, cf.UpVector*0.7, tag, ColorSequence.new(Color3.new(0, 255, 0)), 0.1, lifetime)
	Visualize.showRay(cf.Position, cf.LookVector*0.7, tag, ColorSequence.new(Color3.new(0, 0, 255)), 0.1, lifetime)
end

return Visualize