local activeAnimLocation = game:GetService("ReplicatedStorage").CombatStorage.Animations.M4A1.Reload
for _, pose: Pose in ipairs(activeAnimLocation:GetDescendants()) do
	if pose:IsA("Pose") and pose.EasingStyle == Enum.PoseEasingStyle.Cubic then
		pose.EasingDirection = if pose.EasingDirection == Enum.PoseEasingDirection.In then Enum.PoseEasingDirection.Out else Enum.PoseEasingDirection.In
	end
end
print("good")