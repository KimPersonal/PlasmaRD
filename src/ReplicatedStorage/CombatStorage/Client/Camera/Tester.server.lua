task.wait(4)
local ThirdPersonCamera = require(script.Parent.CameraController.ThirdPersonCamera)
local FakeCamera = require(script.Parent.FakeCamera)
local CurrentCam = ThirdPersonCamera.new(FakeCamera.new(workspace.CurrentCamera))