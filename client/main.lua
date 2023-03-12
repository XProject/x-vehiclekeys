local startedEngines = GlobalState[Shared.State.globalStartedEngines]
local PLAYER_ID = PlayerId()
local inVehicleThreadRunning = false

local function canControlVehicle(vehicleEntity)
    return NetworkGetEntityOwner(vehicleEntity) == PLAYER_ID and NetworkHasControlOfEntity(vehicleEntity)
end

local function inVehicleThread()
    if inVehicleThreadRunning then return end
    inVehicleThreadRunning = true

    local vehicleEntity
    while vehicleEntity ~= 0 do
        local playerPedId = PlayerPedId()
        vehicleEntity = GetVehiclePedIsIn(playerPedId, false)

        if vehicleEntity ~= 0 then
            local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
            local isVehicleEngineRunning = GetIsVehicleEngineRunning(vehicleEntity)

            if startedEngines[vehiclePlate] and not isVehicleEngineRunning then
                Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, true, true)
            elseif not startedEngines[vehiclePlate] and isVehicleEngineRunning then
                Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, false, true)
            end
        end
        Wait(250)
    end
    inVehicleThreadRunning = false
    Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, startedEngines[vehiclePlate], true) -- to keep the engine running in case it has been left on before exiting the vehicle
end

local function toggleEngine(vehicleEntity, state)
    if not canControlVehicle(vehicleEntity) then return end

    if state == nil then
        local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, not startedEngines[vehiclePlate], true)
    else
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, state, true)
    end
end

AddEventHandler("gameEventTriggered", function(eventName)
    if eventName ~= "CEventNetworkPlayerEnteredVehicle" then return end

    inVehicleThread()
end)

RegisterKeyMapping("toggleEngine", "Toggle Vehicle Engine", "keyboard", "G")
RegisterCommand("toggleEngine", function()
    toggleEngine(GetVehiclePedIsIn(PlayerPedId(), false))
end, false)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.globalStartedEngines, nil, function(_, _, value)
    startedEngines = value
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleEngine, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)

    if value == nil or not vehicleEntity or vehicleEntity == 0 or not canControlVehicle(vehicleEntity) then return end

    SetVehicleEngineOn(vehicleEntity, value, true, true)
end)

--[[
AddEventHandler("gameEventTriggered", function(eventName)
    if eventName ~= "CEventNetworkPlayerEnteredVehicle" then return end

    local ped = PlayerPedId()
    local vehicleEntity = GetVehiclePedIsIn(ped, false)

    for i = 1, 5 do
        if GetIsTaskActive(ped, 165) and GetSeatPedIsTryingToEnter(ped) == -1 then
            SetPedConfigFlag(ped, 184, true)
            SetPedIntoVehicle(ped, vehicleEntity, 0)
            SetVehicleActiveForPedNavigation(vehicleEntity, false)
            SetVehicleDoorShut(vehicleEntity, 1, false)
        end
        Wait(400)
    end
end)
]]