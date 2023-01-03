local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CameraController = {}

function CameraController.new()
	error("what do you think youre doing")
end

function CameraController:bindRendering()
	self.camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep(self.bindName, Enum.RenderPriority.Camera.Value, function(dt)
		self:update(dt)
	end)
end

function CameraController:impulseRecoil(baseAngle)
	error("recoil method not defined")
end

function CameraController:update()
	error("camera update method not defined")
end

function CameraController:destroy()
	RunService:UnbindFromRenderStep(self.bindName)
	self.camera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function CameraController:getOccludingParts()
	return {}
end

return CameraController