---@type startedEngines[]
local startedEngines = {}

local function syncEngines()
    GlobalState:set(Shared.State.globalStartedEngines, startedEngines, true)
end

local function syncData()
    syncEngines()
end
CreateThread(syncData)

local function initializeVehicleStateBags(vehicleEntity)
    Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, false, true)
end

--[[AddEventHandler("entityCreated", function(entity)
    if not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end

    initializeVehicleStateBags(entity)
end)]]

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleEngine, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)

    if value == nil or not vehicleEntity or vehicleEntity == 0 then return end

    local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
    startedEngines[vehiclePlate] = value

    syncEngines()
    print(dumpTable(startedEngines))
end)

local function onResourceStop(resource)
    if resource ~= Shared.currentResourceName then return end
    GlobalState:set(Shared.State.globalStartedEngines, {}, true)
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)