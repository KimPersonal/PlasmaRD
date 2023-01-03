local WeaponBehaviorInterface = {}
WeaponBehaviorInterface.weapon = nil
WeaponBehaviorInterface.clientModule = nil

function WeaponBehaviorInterface:init()
	error("missing implementation")
end

function WeaponBehaviorInterface:getToReplicate()
	error("")
end

function WeaponBehaviorInterface:destroy()
	error("missing destroy implementation")
end

return WeaponBehaviorInterface