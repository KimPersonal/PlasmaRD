return {
	LeftHand = {
		root = "LeftUpperArm",
		pullWeight = 0,
		pullTolerance = 1,
		allowTransform = true,
		jointInfo = {
			{weight = 0},
			{
				axis = Vector3.new(1, 0, 0),
				limits = {
					x = {0, math.pi}
				}
			},
			{annealOffset = CFrame.Angles(-math.pi/4, 0, 0)},
		}
	},
	RightHand = {
		root = "RightUpperArm",
		pullWeight = 0,
		pullTolerance = 1,
		allowTransform = true,
		jointInfo = {
			{weight = 0},
			{
				axis = Vector3.new(1, 0, 0),
				limits = {
					x = {0, math.pi}
				}
			},
			{annealOffset = CFrame.Angles(-math.pi/4, 0, 0)},
		}
	},
	LeftFoot = {
		root = "LeftUpperLeg",
		pullWeight = 0.25,
		pullTolerance = 0.7,
		jointInfo = {
			{weight = 0},
			{
				axis = Vector3.new(1, 0, 0),
				annealOffset = CFrame.Angles(-math.rad(5), 0, 0),
				limits = {
					x = {-math.pi, 0}
				}
			},
			{
				preOffset = CFrame.Angles(math.pi/2, 0, 0),
				annealOffset = CFrame.Angles(math.rad(10), 0, 0),
				limits = {
					y = {-math.rad(45), math.rad(45)}
				}
			},
			--{weight = 0, lengthless = true}
		}
	},
	RightFoot = {
		root = "RightUpperLeg",
		pullWeight = 0.25,
		pullTolerance = 0.7,
		jointInfo = {
			{weight = 0},
			{
				axis = Vector3.new(1, 0, 0),
				annealOffset = CFrame.Angles(-math.rad(5), 0, 0),
				limits = {
					x = {-math.pi, 0}
				}
			},
			{
				preOffset = CFrame.Angles(math.pi/2, 0, 0),
				annealOffset = CFrame.Angles(math.rad(10), 0, 0),
				limits = {
					y = {-math.rad(45), math.rad(45)}
				}
			},
			--{weight = 0, lengthless = true}
		}
	},
}