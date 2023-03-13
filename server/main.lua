local function initializeVehicleStateBags(vehicleEntity)
    Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, GetIsVehicleEngineRunning(vehicleEntity) or IsVehicleEngineStarting(vehicleEntity), true)
    Entity(vehicleEntity).state:set(Shared.State.vehicleLock, true, true)
end

AddEventHandler("entityCreated", function(entity)
    if not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end

    initializeVehicleStateBags(entity)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleLock, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)
    if not vehicleEntity or vehicleEntity == 0 then return end

    SetVehicleDoorsLocked(vehicleEntity, value and Config.LockState or Config.UnlockState)
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)