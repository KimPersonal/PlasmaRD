local CarrierTypeInterface = require(script.Parent)

local storage = game:GetService("ReplicatedStorage").CombatStorage
local Maid = require(storage.Maid)
local remoteCallbacks = {}

local PlayerCarrier = {}
setmetatable(PlayerCarrier, {__index = CarrierTypeInterface})
PlayerCarrier.player = nil
PlayerCarrier.char = nil

function PlayerCarrier.new(player: Player)
	local self = setmetatable({}, {__index = PlayerCarrier})
	self.maid = Maid.new()
	self.player = player
	self.char = player.Character
	return self
end

function PlayerCarrier:init(weapon)
	weapon.tool.Parent = self.player.Backpack
end

-- signal name is based on remote event name
function PlayerCarrier:getSignal(name)
	local remote = storage.Remote:FindFirstChild(name)
	assert(remote, "Unknown RemoteEvent '" .. name .. "'")
	local proxy = self.maid:add(Instance.new("BindableEvent"))
	self.maid:add(remote.OnServerEvent:Connect(function(player, ...)
		if player == self.player then
			proxy:Fire(...)
		end
	end))
	return proxy.Event
end

function PlayerCarrier:getLatency()
	return self.player:GetNetworkPing()
end

--fixed now?
function PlayerCarrier:setCallback(name, callback)
	local remote = storage.Remote:FindFirstChild(name)
	assert(remote, "Unknown RemoteEvent '" .. name .. "'")
	if not remoteCallbacks[name] then
		remoteCallbacks[name] = {}
		remote.OnServerInvoke = function(player, ...)
			local found = remoteCallbacks[name][player.Name]
			if found then
				return found(...)
			end
		end
	end
	remoteCallbacks[name][self.player.Name] = callback
end

function PlayerCarrier:destroy()
	self.maid:destroy()
end

return PlayerCarrier