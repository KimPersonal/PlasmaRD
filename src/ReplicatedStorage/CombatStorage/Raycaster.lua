local DEF_ITER_LIMIT = 15
local Raycaster = {}

function Raycaster.iterativeSearch(origin, direction, filter0, mode, props, limit)
	limit = limit or DEF_ITER_LIMIT
	local param = RaycastParams.new()
	param.FilterType = mode
	param.FilterDescendantsInstances = filter0
	local result
	local lastStop = origin
	local goal = origin + direction
	for _ = 1, limit do
		local tempRes = workspace:Raycast(lastStop, goal - lastStop, param)
		if tempRes then
			for name, range in pairs(props) do
				if name ~= "siblingClass" then
					local value = tempRes.Instance[name]
					if typeof(value) == "number" then
						if value >= range[1] and value <= range[2] then
							result = tempRes
						end
					else
						if value == range then
							result = tempRes
						end
					end
				else
					for _, class in ipairs(range) do
						if tempRes.Instance.Parent:FindFirstChildWhichIsA(class) then
							result = tempRes
							break
						end
					end
				end
			end
			if not result then
				table.insert(filter0, tempRes.Instance)
				param.FilterDescendantsInstances = filter0
			end
			lastStop = tempRes.Position
		end
		if result or not tempRes then
			break
		end
	end
	return result, filter0
end

function Raycaster.getPartsOnRay(origin, direction, filter)
	filter = filter or {}
	local param = RaycastParams.new()
	param.FilterType = Enum.RaycastFilterType.Blacklist
	param.FilterDescendantsInstances = filter
	
	local result
	local lastStop = origin
	local goal = origin + direction
	repeat
		result = workspace:Raycast(lastStop, goal - lastStop, param)
		if result then
			table.insert(filter, result.Instance)
			param.FilterDescendantsInstances = filter
			lastStop = result.Position
		end
	until not result
	return filter
end

return Raycaster