local R6Base = Instance.new("Model")
local R15Base = script.R15

local function awaitDescendants(char, base): boolean
	for _, lookFor in ipairs(base:GetChildren()) do
		local found = char:WaitForChild(lookFor.Name, 5)
		if not found then warn(lookFor.Name .. " " .. char.Name) return false end
		local success = awaitDescendants(found, lookFor)
		if not success then return false end
	end
	return true
end

return function(char: Model?): boolean
	local hum = char and char:WaitForChild("Humanoid", 10)
	if hum then
		local base = hum.RigType == Enum.HumanoidRigType.R15 and R15Base or R6Base
		return awaitDescendants(char, base)
	end
	return false
end