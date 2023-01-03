local FakeCamera = {}

local meta = {
	__index = function(self, k)
		local getter = FakeCamera["_get" .. tostring(k)]
		if getter then
			return getter(self)
		end
		local run, res = pcall(function()
			return self.realCam[k]
		end)
		if run and res then
			return res
		end
		return FakeCamera[k]
	end,
	__newindex = function(self, k, v)
		local handler = self["_set" .. tostring(k)]
		if handler then
			handler(self, v)
		end
	end,
}

function FakeCamera.new(realCam: Camera)
	local self = {}
	
	self.realCam = realCam
	self._cframe = realCam.CFrame
	self._fov = realCam.FieldOfView
	self.framePart = Instance.new("Part", workspace)
	self.framePart.Anchored = true
	self.framePart.CanCollide = false
	self.framePart.CanTouch = false
	self.framePart.CanQuery = false
	self.framePart.Transparency = 1
	self.framePart.CFrame = realCam.CFrame
	self.framePart.Size = Vector3.new(0.1, 0.1, 0.1)
	
	setmetatable(self, meta)
	self:makeOutline()
	
	return self
end

function FakeCamera:makeOutline()
	local realCam = self.realCam
	local oldCamCf = realCam.CFrame
	self.framePart:ClearAllChildren()
	realCam.CFrame = self.framePart.CFrame
	
	local frameCenter = Instance.new("Attachment", self.framePart)
	local screenSize = realCam.ViewportSize
	local cornerAtts = {}
	local cornerRays: {Ray} = {
		realCam:ViewportPointToRay(0, 0, realCam.NearPlaneZ),
		realCam:ViewportPointToRay(0, screenSize.Y, realCam.NearPlaneZ),
		realCam:ViewportPointToRay(screenSize.X, screenSize.Y, realCam.NearPlaneZ),
		realCam:ViewportPointToRay(screenSize.X, 0, realCam.NearPlaneZ),
	}

	for _, ray: Ray in ipairs(cornerRays) do
		local att = Instance.new("Attachment", self.framePart)
		att.WorldPosition = ray.Origin + ray.Direction
		table.insert(cornerAtts, att)
	end
	for i, att: Attachment in ipairs(cornerAtts) do
		local beam = Instance.new("Beam", self.framePart)
		beam.Width0 = 0.05
		beam.Width1 = 0.05
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(Color3.new(1, 0, 1))
		beam.LightInfluence = 0
		beam.LightEmission = 1
		beam.Transparency = NumberSequence.new(0)
		beam.Attachment0 = frameCenter
		beam.Attachment1 = att

		local edgeBeam = beam:Clone()
		edgeBeam.Parent = self.framePart
		edgeBeam.Attachment0 = att
		edgeBeam.Attachment1 = cornerAtts[i+1] or cornerAtts[1]
	end
	
	realCam.CFrame = oldCamCf
end

function FakeCamera:_setCFrame(newCf: CFrame)
	self.framePart.CFrame = newCf
	self._cframe = newCf
end

function FakeCamera:_getCFrame()
	return self._cframe
end

function FakeCamera:_setFieldOfView(newFov: number)
	local oldFov = self.realCam.FieldOfView
	self.realCam.FieldOfView = newFov
	self:makeOutline()
	self.realCam.FieldOfView = oldFov
	self._fov = newFov
end

function FakeCamera:_getFieldOfView()
	return self._fov
end

return FakeCamera