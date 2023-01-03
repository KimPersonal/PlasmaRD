local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local running = {}

local function orderPoints(point1, point2)
	return point1.Time < point2.Time
end

local function ensureMatches(sequence1, sequence2)
	local currentPoints = sequence1.Keypoints
	local newPoints = {unpack(currentPoints)}
	for _, goalKeypoint in ipairs(sequence2.Keypoints) do
		for pos, keypoint in ipairs(currentPoints) do
			if goalKeypoint.Time == keypoint.Time then
				break
			elseif keypoint.Time > goalKeypoint.Time then
				local last = currentPoints[pos-1]
				local m = (keypoint.Value - last.Value)/(keypoint.Time - last.Time)
				local value = m*(goalKeypoint.Time - last.Time) + last.Value
				table.insert(newPoints, NumberSequenceKeypoint.new(goalKeypoint.Time, value))

				break
			end
		end
	end
	table.sort(newPoints, orderPoints)
	return NumberSequence.new(newPoints)
end

-- expects all goal properties to be a NumberSequence
return function(instance, info: TweenInfo, properties, hook)
	if running[instance] then
		for _, update in pairs(running[instance]) do
			update:Disconnect()
		end
	end
	running[instance] = {}
	local tweenStart = os.clock()

	for property, rawGoal in pairs(properties) do
		local start = ensureMatches(instance[property], rawGoal)
		local goal = ensureMatches(rawGoal, instance[property])

		local update update = runService.Stepped:Connect(function()
			local passed = os.clock() - tweenStart
			local rawAlpha = math.clamp(passed / info.Time, 0, 1)
			local alpha = tweenService:GetValue(rawAlpha, info.EasingStyle, info.EasingDirection)
			local points = {}

			for pos, keypoint in ipairs(start.Keypoints) do
				table.insert(points, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value + (goal.Keypoints[pos].Value - keypoint.Value) * alpha))
			end

			instance[property] = NumberSequence.new(points)

			if rawAlpha == 1 then
				instance[property] = rawGoal
				update:Disconnect()
				if hook then hook(instance) end
			end
		end)
		running[instance][property] = update
	end
end