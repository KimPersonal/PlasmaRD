local MathUtil = {}

function MathUtil.getRotationBetween(u: Vector3, v: Vector3)	
	local normU_normV = math.sqrt(u:Dot(u) * v:Dot(v))
	local real = normU_normV + u:Dot(v)
	local w
	if real < 1.e-4 * normU_normV then
		real = 0
		w = if math.abs(u.X) > math.abs(u.Z) then Vector3.new(-u.Y, u.X, 0) else Vector3.new(0, -u.Z, u.Y)
	else
		w = u:Cross(v)
	end
	
	return CFrame.new(0, 0, 0, w.x, w.y, w.z, real) --pretty sure roblox normalizes this internally
end

function MathUtil.swingTwist(cf, direction)
	local axis, theta = cf:ToAxisAngle()
	-- convert to quaternion
	local w, v = math.cos(theta/2),  math.sin(theta/2)*axis

	-- plug qp into the constructor and it will be normalized automatically
	local proj = v:Dot(direction)*direction
	local twist = CFrame.new(0, 0, 0, proj.x, proj.y, proj.z, w)

	-- cf = swing * twist, thus...
	local swing = cf * twist:Inverse()

	return swing, twist
end

return MathUtil