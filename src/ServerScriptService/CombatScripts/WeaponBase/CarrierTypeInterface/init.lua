local CarrierTypeInterface = {}
CarrierTypeInterface.weapon = nil
CarrierTypeInterface.char = nil

function CarrierTypeInterface:init()
	error("missing implementation")
end

function CarrierTypeInterface:getSignal(name)
	error("missing implementation")
end

function CarrierTypeInterface:setCallback(name, callback)
	error("missing implementation")
end

function CarrierTypeInterface:destroy()
	error("missing implementation")
end

return CarrierTypeInterface