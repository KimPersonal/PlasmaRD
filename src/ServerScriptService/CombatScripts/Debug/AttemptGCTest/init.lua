local RunService = game:GetService("RunService")
return function(item)
	local weak = setmetatable({}, {__mode = "kv"})
	print("waiting for test to begin")
	-- for some reason, garbage collector becomes extremely timid if setting a value in weak table after resuming a thread
	-- compared to when a value is set in a stack thats never yielded at all
	-- i want to be absolutely sure that things are being collected even when thats happening
	-- and also see how much longer it takes
	task.wait(3)
	print("start gc test with", item)
	local start = os.clock()
	local gc2warned = false
	local clutter = {}
	weak[1] = item
	weak[2] = {}
	item = nil
	while weak[1] do
		for _ = 1, 10 do
			table.insert(clutter, Instance.new("Part"))
		end
		if not weak[2] and not gc2warned then
			gc2warned = true
			print("collected control object after", os.clock()-start, "secs")
		end
		RunService.Stepped:Wait()
	end
	for _, inst in ipairs(clutter) do inst:Destroy() end
	local passed = os.clock()-start
	print("collected focus object after", passed, "secs")
	return passed
end