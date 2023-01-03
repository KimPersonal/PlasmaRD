local TweenService = game:GetService("TweenService")
local client = game:GetService("Players").LocalPlayer
local screenUI = script.Crosshair
local topFrame = screenUI.Frame
local circleLeft = topFrame.AmmoCircleLeft.Image
local leftGrad = circleLeft.UIGradient
local circleRight = topFrame.AmmoCircleRight.Image
local rightGrad = circleRight.UIGradient
local hitmarkerBase = topFrame.Hitmarker
local crosslines = {topFrame.Crossline1, topFrame.Crossline2}
local crosshairParts = {}
local allTweens: {Tween} = {}

for i = 1, 4 do
	table.insert(crosshairParts, topFrame:FindFirstChild("Crosshair" .. i))
end

local function stopAllTweens()
	for _, tween in pairs(allTweens) do
		tween:Cancel()
	end
	allTweens = {}
end

local function getGradRotations(ammoFrac)
	local left = 180 * (1-math.clamp(ammoFrac*2, 0, 1))
	local right = 180 * (1-math.clamp((ammoFrac-0.5)*2, 0, 1))
	return left, right
end

local function addTween(inst: Instance, info: TweenInfo, prop): Tween
	local tween = TweenService:Create(inst, info, prop)
	table.insert(allTweens, tween)
	tween:Play()
	return tween
end


local CrosshairController = {}

function CrosshairController.show(current, capacity)
	stopAllTweens()
	screenUI.Parent = client.PlayerGui
	for _, crosshair in ipairs(crosshairParts) do
		crosshair.BackgroundTransparency = 1
		addTween(crosshair, TweenInfo.new(0.3), {BackgroundTransparency = 0})
		addTween(crosshair.UIStroke, TweenInfo.new(0.3), {Transparency = 0})
	end
	for _, crossline in ipairs(crosslines) do
		crossline.BackgroundTransparency = 1
		addTween(crossline, TweenInfo.new(0.7), {BackgroundTransparency = 0})
	end
	leftGrad.Rotation = 180
	rightGrad.Rotation = 180
	circleLeft.ImageTransparency = 0.1
	circleRight.ImageTransparency = 0.1
	CrosshairController.tweenAmmo(current, capacity)
end

function CrosshairController.hide()
	stopAllTweens()
	addTween(circleLeft, TweenInfo.new(0.8), {ImageTransparency = 1})
	addTween(circleRight, TweenInfo.new(0.8), {ImageTransparency = 1})
	for _, crosshair in ipairs(crosshairParts) do
		addTween(crosshair, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		addTween(crosshair.UIStroke, TweenInfo.new(0.3), {Transparency = 1})
	end
	for _, crossline in ipairs(crosslines) do
		addTween(crossline, TweenInfo.new(0.5), {BackgroundTransparency = 1})
	end
end

function CrosshairController.setRecoilDist(distPx)
	topFrame.Crosshair1.Position = UDim2.new(0.5, 0, 0.5, -10 - distPx)
	topFrame.Crosshair2.Position = UDim2.new(0.5, -10-distPx, 0.5, 0)
	topFrame.Crosshair3.Position = UDim2.new(0.5, 0, 0.5, 10 + distPx)
	topFrame.Crosshair4.Position = UDim2.new(0.5, 10+distPx, 0.5, 0)
	
	local size = topFrame.Crosshair1.AbsoluteSize
	local length = math.max(size.X, size.Y)*0.77
	circleLeft.Parent.Size = UDim2.new(0.25, distPx/2+length/4, 0.5, distPx+length/2)
	circleRight.Parent.Size = UDim2.new(0.25, distPx/2+length/4, 0.5, distPx+length/2)
end

function CrosshairController.tweenAmmo(current, capacity)
	local empty = current == 0
	local color = not empty and Color3.new(1, 1, 1) or Color3.fromRGB(255, 0, 34)
	local ammoFrac = not empty and current/capacity or 1
	local leftRot, rightRot = getGradRotations(ammoFrac)
	local first = ammoFrac > 0.5 and leftGrad or rightGrad
	local second = ammoFrac <= 0.5 and leftGrad or rightGrad
	local firstRot = first == leftGrad and leftRot or rightRot
	local secondRot = second == leftGrad and leftRot or rightRot
	local firstTime = math.abs(firstRot - first.Rotation) * 0.002
	local secondTime = math.abs(secondRot - second.Rotation) * 0.004
	
	--[[if empty then
		for _, crosshair in ipairs(crosshairParts) do
			addTween(crosshair, TweenInfo.new(0.3), {BackgroundTransparency = empty and 0.6 or 0})
		end
	end]]
	
	addTween(circleLeft, TweenInfo.new(0.05), {ImageTransparency = empty and 0.2 or 0.4, ImageColor3 = color})
	addTween(circleRight, TweenInfo.new(0.05), {ImageTransparency = empty and 0.2 or 0.4, ImageColor3 = color})
	
	addTween(first, TweenInfo.new(firstTime, Enum.EasingStyle.Linear), {Rotation = firstRot}).Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			addTween(second, TweenInfo.new(secondTime, Enum.EasingStyle.Quart), {Rotation = secondRot}).Completed:Connect(function(state2)
				if not empty and state2 == Enum.PlaybackState.Completed then
					addTween(circleLeft, TweenInfo.new(0.5), {ImageTransparency = 1})
					addTween(circleRight, TweenInfo.new(0.5), {ImageTransparency = 1})
				end
			end)
		end
	end)
end

function CrosshairController.setCircleFill(frac)
	stopAllTweens()
	local left, right = getGradRotations(frac)
	local startColor = frac>0.5 and Color3.fromRGB(255, 128, 0) or Color3.new(1, 0, 0)
	local goalColor = frac>0.5 and Color3.new(1, 1, 1) or Color3.fromRGB(255, 128, 0)
	local color = startColor:Lerp(goalColor, frac>0.5 and (frac-0.5)*2 or frac*2)
	addTween(circleLeft, TweenInfo.new(0.05), {ImageTransparency = 0.2})
	addTween(circleRight, TweenInfo.new(0.05), {ImageTransparency = 0.2})
	circleLeft.ImageColor3 = color
	circleRight.ImageColor3 = color
	leftGrad.Rotation = left
	rightGrad.Rotation = right
end

function CrosshairController.makeHitmarker()
	local marker = hitmarkerBase:Clone()
	marker.Parent = topFrame
	marker.Rotation = Random.new():NextInteger(-45, 45)
	marker.Sound:Play()
	local tw1 = TweenService:Create(marker, TweenInfo.new(0.15, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0.3, 0.3)})
	local tw2 = TweenService:Create(marker, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {ImageTransparency = 1, Size = UDim2.fromScale(0.7, 0.7)})
	tw1.Completed:Connect(function()
		tw2:Play()
	end)
	tw2.Completed:Connect(function()
		marker:Destroy()
	end)
	tw1:Play()
end

return CrosshairController