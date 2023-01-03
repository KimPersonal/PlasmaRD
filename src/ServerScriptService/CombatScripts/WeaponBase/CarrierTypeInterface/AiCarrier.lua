local CarrierTypeInterface = require(script.Parent)

local AiCarrier = {}
setmetatable(AiCarrier, {__index = CarrierTypeInterface})

return AiCarrier