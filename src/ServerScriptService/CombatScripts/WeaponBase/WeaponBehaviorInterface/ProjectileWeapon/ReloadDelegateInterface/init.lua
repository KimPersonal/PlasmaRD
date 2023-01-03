local ReloadDelegateInterface = {}
ReloadDelegateInterface.clientModule = nil
ReloadDelegateInterface.reloading = false
ReloadDelegateInterface.currentAmmo = 0
ReloadDelegateInterface.capacity = 0
ReloadDelegateInterface.reloadTime = 0

function ReloadDelegateInterface:reloadAsync(projWep)
	error("")
end

function ReloadDelegateInterface:getReplicationInfo()
	error("")
end

return ReloadDelegateInterface