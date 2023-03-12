local startedEngines = GlobalState[Shared.State.globalStartedEngines]
local PLAYER_ID = PlayerId()
local outsideVehicleThread, insideVehicleThread
local isInsideVehicleThreadRunning, isOutsideVehicleThreadRunning = false, false

local function canControlVehicle(vehicleEntity)
    return NetworkGetEntityOwner(vehicleEntity) == PLAYER_ID and NetworkHasControlOfEntity(vehicleEntity)
end

function outsideVehicleThread()
    if Config.LockState ~= 4 then return end
    if isOutsideVehicleThreadRunning then return end
    isOutsideVehicleThreadRunning = true

    local vehicleEntity = 0
    while isOutsideVehicleThreadRunning and vehicleEntity == 0 do
        local playerPedId = PlayerPedId()
        vehicleEntity = GetVehiclePedIsIn(playerPedId, false)

        if vehicleEntity ~= 0 then break end

        local vehicleTryingToEnter = GetVehiclePedIsTryingToEnter(playerPedId)
        if DoesEntityExist(vehicleTryingToEnter) then
            if GetVehicleDoorLockStatus(vehicleTryingToEnter) == Config.LockState then
                ClearPedTasks(playerPedId)
            end
        end
        print("outsideVehicleThread")
        Wait(250)
    end
    isOutsideVehicleThreadRunning = false
end

function insideVehicleThread()
    if isInsideVehicleThreadRunning then return end
    isInsideVehicleThreadRunning = true

    local vehicleEntity
    while isInsideVehicleThreadRunning and vehicleEntity ~= 0 do
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
    isInsideVehicleThreadRunning = false
    CreateThread(outsideVehicleThread)
end

local function toggleVehicleEngine(vehicleEntity, state)
    if not canControlVehicle(vehicleEntity) then return end
    
    if state == nil then
        local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, not startedEngines[vehiclePlate], true)
    else
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, state, true)
    end
end

local function toggleVehicleLock(vehicleEntity, state)
    if state == nil then
        state = Entity(vehicleEntity).state[Shared.State.vehicleLock]
        Entity(vehicleEntity).state:set(Shared.State.vehicleLock, not state, true)
    else
        Entity(vehicleEntity).state:set(Shared.State.vehicleLock, state and "locked" or "unlocked", true)
    end
end

CreateThread(outsideVehicleThread)

AddEventHandler("gameEventTriggered", function(eventName)
    if eventName ~= "CEventNetworkPlayerEnteredVehicle" then return end

    CreateThread(insideVehicleThread)
end)

RegisterCommand("toggleVehicleEngine", function()
    local vehicleEntity = GetVehiclePedIsIn(PlayerPedId(), false)

    if not vehicleEntity or vehicleEntity == 0 then return end

    toggleVehicleEngine(vehicleEntity)
end, false)
RegisterKeyMapping("toggleVehicleEngine", "Toggle Vehicle Engine", "keyboard", Config.ToggleVehicleEngine)

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

RegisterCommand("lock", function(source, args)
    local nearbyVehicles = Utils.getNearbyVehicles(GetEntityCoords(PlayerPedId()))
    local vehicle = false

    for i = 1, #nearbyVehicles do
        local vehicleData = nearbyVehicles[i]
        local vehiclePlate = GetVehicleNumberPlateText(vehicleData.vehicle)

        if vehiclePlate == args[1] then
            vehicle = vehicleData.vehicle
            break
        end
    end

    if vehicle then toggleVehicleLock(vehicle, args[2]) end
end, false)

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