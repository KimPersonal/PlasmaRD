local BulletGeneric = require(script.Parent.BulletGeneric)
local Beanbag = {}
setmetatable(Beanbag, {__index = BulletGeneric})

function BulletGeneric.new(inherit)
	local self = setmetatable({}, {__index = inherit or Beanbag})
	return self
end

function BulletGeneric.fromServerInfo(info)
	local self = setmetatable(info, {__index = Beanbag})
	return self
end

return Beanbag