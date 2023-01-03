local cleaningMethods = {
	RBXScriptConnection = function(connection: RBXScriptConnection)
		connection:Disconnect()
	end,
	Instance = function(inst: Instance)
		pcall(inst.Destroy, inst)
	end,
	table = function(tab: {[any]: any})
		if tab.destroy then
			tab:destroy()
		else
			warn("Maid ignored object with no destroy method")
			print(tab)
		end
	end,
}

local Maid = {}

function Maid.new()
	return setmetatable(
		{
			_list = {}
		},
		{__index = Maid}
	)
end

function Maid:add(item)
	assert(self._list, "Attempt to add to destroyed Maid")
	if cleaningMethods[typeof(item)] then
		table.insert(self._list, item)
		return item
	else
		error("Attempt to add unknown data type to Maid")
	end
end

function Maid:destroy()
	if self._list then
		for _, item in ipairs(self._list) do
			--print("cleaning", item)
			cleaningMethods[typeof(item)](item)
		end
		self._list = nil
	else
		warn("Attempt to destroy already destroyed maid")
	end
end

Maid.clean = Maid.destroy
Maid.watch = Maid.add

return Maid