local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local client = game:GetService("Players").LocalPlayer
local UI_GRAV = 3000
local screenUI = script.InfoDisplay
local topFrame = screenUI.Container
local viewport = topFrame.ModelView
local innerEdgeFrame = topFrame.Edges
local radialFill = topFrame.Fill
local leftFill = radialFill.Left.ImageLabel
local rightFill = radialFill.Right.ImageLabel
local leftGrad = leftFill.UIGradient
local rightGrad = rightFill.UIGradient
local background = topFrame.Background
local nameText = background.WepName
local ammoText = topFrame.Ammo
local ammoBox = topFrame.AmmoBox
local ammoIconFolder = script.AmmoIcons
local totalAmmoText = ammoText.TotalAmmo
local shotIcons = {}
local allTweens: {Tween} = {}
local edgeAnimConnection: RBXScriptConnection? = nil
viewport.CurrentCamera = Instance.new("Camera", viewport)

local edges = {
	{
		frame = innerEdgeFrame.Top,
		defPos = UDim2.fromScale(0, 0.1),
		moveDir = Vector2.new(0, -1),
		startAlpha = 0
	},
	{
		frame = innerEdgeFrame.Right,
		defPos = UDim2.fromScale(0.9, 0),
		moveDir = Vector2.new(1, 0),
		startAlpha = -0.25
	},
	{
		frame = innerEdgeFrame.Bottom,
		defPos = UDim2.fromScale(0, 0.9),
		moveDir = Vector2.new(0, 1),
		startAlpha = -0.5
	},
	{
		frame = innerEdgeFrame.Left,
		defPos = UDim2.fromScale(0.1, 0),
		moveDir = Vector2.new(-1, 0),
		startAlpha = -0.75
	}
}

local function stopAllTweens()
	for _, tween in pairs(allTweens) do
		tween:Cancel()
	end
	allTweens = {}
end

local function addTween(inst: Instance, info: TweenInfo, prop): Tween
	local tween = TweenService:Create(inst, info, prop)
	table.insert(allTweens, tween)
	tween:Play()
	return tween
end

local function getGradRotations(ammoFrac)
	local left = 180 * (1-math.clamp(ammoFrac*2, 0, 1))
	local right = 180 * (1-math.clamp((ammoFrac-0.5)*2, 0, 1))
	return left, right
end

local function popAmmoIcon()
	local image: ImageLabel = shotIcons[1]
	table.remove(shotIcons, 1)
	task.spawn(function()
		TweenService:Create(image, TweenInfo.new(0.7), {ImageTransparency = 1}):Play()
		local rotSpeed = Random.new():NextNumber(-10, 10)
		local t0 = os.clock()
		local v0 = UDim2.fromOffset(Random.new():NextInteger(20, 100), -Random.new():NextInteger(500, 1000))
		local x0 = image.Position.X.Offset
		local y0 = image.Position.Y.Offset
		--local absx0 = image.AbsolutePosition.X
		local ax = UI_GRAV * math.sin(math.rad(ammoBox.Rotation))
		local ay = UI_GRAV * math.cos(math.rad(ammoBox.Rotation))
		local w = Random.new():NextInteger(-40, 40)
		while image.ImageTransparency < 1 do
			local t = os.clock() - t0
			local x = 0.5*ax*t^2 + v0.X.Offset*t + x0
			local y = 0.5*ay*t^2 + v0.Y.Offset*t + y0
			image.Position = UDim2.fromOffset(x, y)
			image.Rotation += w
			RunService.RenderStepped:Wait()
			--print(image.AbsolutePosition.X - absx0)
		end
		image:Destroy()
	end)
end

local function updateAmmoIcons(amount: number, imageBase: ImageLabel)
	if #shotIcons > amount then
		for _ = 1, #shotIcons - amount do
			popAmmoIcon()
		end
	end
	
	local x = 0
	for i = 1, amount do
		local image = shotIcons[i] or imageBase:Clone()
		shotIcons[i] = image
		image.Image = imageBase.Image
		image.Parent = ammoBox
		TweenService:Create(image, TweenInfo.new(0.07), {Position = UDim2.fromOffset(x, 0)}):Play()
		x += image.AbsoluteSize.X
		TweenService:Create(image, TweenInfo.new(0.25), {ImageTransparency = x <= ammoBox.AbsoluteSize.X and 0 or 1}):Play()
	end
end

local DisplayController = {}

function DisplayController.startEdgeAnim()
	if not edgeAnimConnection then
		local alphaList = {}
		local alphaPSec = 1.5*math.pi
		for i, edge in ipairs(edges) do
			alphaList[i] = edge.startAlpha
			TweenService:Create(edge.frame.ImageLabel,
				TweenInfo.new(0.3),
				{ImageColor3 = Color3.new(1, 0, 0)}
			):Play()
		end
		edgeAnimConnection = RunService.Heartbeat:Connect(function(dt)
			for i, edge in ipairs(edges) do
				alphaList[i] += alphaPSec*dt
				local sin = math.sin(math.max(alphaList[i], 0))+1
				local scale = sin*0.07
				local moveVec = Vector2.new(scale, scale) * edge.moveDir
				edge.frame.Position = edge.defPos + UDim2.fromScale(moveVec.X, moveVec.Y)
				edge.frame.ImageLabel.ImageTransparency = math.sin(alphaList[i]*2)
			end
		end)
	end
end

function DisplayController.stopEdgeAnim()
	if edgeAnimConnection then
		edgeAnimConnection:Disconnect()
		edgeAnimConnection = nil
		for _, edge in ipairs(edges) do
			TweenService:Create(edge.frame.ImageLabel,
				TweenInfo.new(0.3),
				{ImageTransparency = 1, ImageColor3 = Color3.new(1, 1, 1)}
			):Play()
		end
	end
end

function DisplayController.tweenAmmo(current: number, total: number?, imageName: string?)
	ammoText.Text = tostring(current)
	totalAmmoText.Text = "/ " .. tostring(total)
	updateAmmoIcons(current, imageName and ammoIconFolder:FindFirstChild(imageName) or ammoIconFolder.Bullet)
	
	local ammoFrac = total and current/total or 1e-4
	local backgroundColor = ammoFrac ~= 0 and Color3.fromRGB(31, 31, 31) or Color3.fromRGB(134, 0, 2)
	local fillLineColor = ammoFrac ~= 0 and Color3.new(1, 1, 1) or Color3.fromRGB(255, 34, 34)
	
	addTween(leftFill, TweenInfo.new(0.4), {ImageColor3 = fillLineColor})
	addTween(rightFill, TweenInfo.new(0.4), {ImageColor3 = fillLineColor})
	
	if ammoFrac == 0 then
		ammoFrac = 1
		DisplayController.startEdgeAnim()
	else
		DisplayController.stopEdgeAnim()
	end
	
	local leftRot, rightRot = getGradRotations(ammoFrac)
	local first = ammoFrac > 0.5 and leftGrad or rightGrad
	local second = ammoFrac <= 0.5 and leftGrad or rightGrad
	local firstRot = first == leftGrad and leftRot or rightRot
	local secondRot = second == leftGrad and leftRot or rightRot
	local firstTime = math.abs(firstRot - first.Rotation) * 0.002
	local secondTime = math.abs(secondRot - second.Rotation) * 0.004
	addTween(first, TweenInfo.new(firstTime, Enum.EasingStyle.Linear), {Rotation = firstRot}).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			addTween(second, TweenInfo.new(secondTime, Enum.EasingStyle.Quart), {Rotation = secondRot})
		end
	end)
end

function DisplayController.setOutlineFill(frac)
	stopAllTweens()
	local color = Color3.new(1, 0, 0)
	local leftRot, rightRot = getGradRotations(frac)
	leftFill.ImageColor3 = color
	rightFill.ImageColor3 = color
	leftGrad.Rotation = leftRot
	rightGrad.Rotation = rightRot
end

function DisplayController.show(modelTemplate: Model, currentAmmo, totalAmmo, displayName, imageName)
	stopAllTweens()
	screenUI.Parent = client.PlayerGui
	background.BackgroundTransparency = 1
	nameText.TextTransparency = 1
	ammoText.TextTransparency = 1
	totalAmmoText.TextTransparency = 1
	leftGrad.Rotation = 180
	rightGrad.Rotation = 180
	nameText.Text = displayName
	addTween(background, TweenInfo.new(0.1), {BackgroundTransparency = 0.5})
	addTween(nameText, TweenInfo.new(0.1), {TextTransparency = 0})
	addTween(ammoText, TweenInfo.new(0.1), {TextTransparency = 0})
	addTween(totalAmmoText, TweenInfo.new(0.1), {TextTransparency = 0})
	DisplayController.tweenAmmo(currentAmmo, totalAmmo, imageName)
	
	local viewModel = modelTemplate:Clone()
	local boxSize = viewModel:GetExtentsSize()
	local maxSize = math.max(boxSize.X, boxSize.Y, boxSize.Z)
	local modelBaseCf = viewport.CurrentCamera.CFrame * CFrame.new(0, 0, -maxSize+1)
	local t0 = os.clock()
	
	viewport.ImageTransparency = 1
	addTween(viewport, TweenInfo.new(0.4), {ImageTransparency = 0})
	viewport.WorldModel:ClearAllChildren()
	viewModel.Parent = viewport.WorldModel
	viewModel:PivotTo(modelBaseCf)
	task.spawn(function()
		while viewModel.Parent == viewport.WorldModel do
			local t = os.clock() - t0
			viewModel:PivotTo(modelBaseCf * CFrame.Angles(0, math.rad(30) * t, 0))
			RunService.RenderStepped:Wait()
		end
	end)
end

function DisplayController.hide()
	stopAllTweens()
	DisplayController.stopEdgeAnim()
	addTween(background, TweenInfo.new(0.1), {BackgroundTransparency = 1})
	addTween(nameText, TweenInfo.new(0.1), {TextTransparency = 1})
	addTween(ammoText, TweenInfo.new(0.1), {TextTransparency = 1})
	addTween(totalAmmoText, TweenInfo.new(0.1), {TextTransparency = 1})
	addTween(viewport, TweenInfo.new(0.15), {ImageTransparency = 1})
	DisplayController.tweenAmmo(0)
end

return DisplayController