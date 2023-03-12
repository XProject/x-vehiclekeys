local startedEngines = GlobalState[Shared.State.globalStartedEngines]
local PLAYER_ID = PlayerId()
local outsideVehicleLoop, insideVehicleLoop
local isInsideVehicleLoopRunning, isOutsideVehicleLoopRunning = false, false

local function canControlVehicle(vehicleEntity)
    return NetworkGetEntityOwner(vehicleEntity) == PLAYER_ID and NetworkHasControlOfEntity(vehicleEntity)
end

local function toggleVehicleEngine(vehicleEntity, state, checkCanControl, notify)
    if checkCanControl and not canControlVehicle(vehicleEntity) then return end

    if state == nil then
        local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
        state = not startedEngines[vehiclePlate]
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, state, true)
    else
        Entity(vehicleEntity).state:set(Shared.State.vehicleEngine, state, true)
    end

    if notify then
        Utils.Notification(nil, ("Engine Turned %s"):format(state and "On" or "Off"), state and "success" or "error")
    end
end

local function toggleVehicleLock(vehicleEntity, state, checkCanControl, notify)
    if checkCanControl and not canControlVehicle(vehicleEntity) then return end

    if state == nil then
        state = not Entity(vehicleEntity).state[Shared.State.vehicleLock]
        Entity(vehicleEntity).state:set(Shared.State.vehicleLock, state, true)
    else
        Entity(vehicleEntity).state:set(Shared.State.vehicleLock, state, true)
    end

    if notify then
        local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
        Utils.Notification(nil, ("%s Doors %s"):format(vehiclePlate, state and "Locked" or "Unlocked"), "success")
    end
end

function outsideVehicleLoop()
    if Config.LockState ~= 4 then return end
    if isOutsideVehicleLoopRunning then return end
    isOutsideVehicleLoopRunning = true

    while isOutsideVehicleLoopRunning do
        local playerPedId = PlayerPedId()
        local vehicleEntity = GetVehiclePedIsIn(playerPedId, false)

        if vehicleEntity == 0 then
            local vehicleTryingToEnter = GetVehiclePedIsTryingToEnter(playerPedId)
            if DoesEntityExist(vehicleTryingToEnter) then
                if GetVehicleDoorLockStatus(vehicleTryingToEnter) == Config.LockState then
                    ClearPedTasks(playerPedId)
                end
            end
        else
            break
        end
        Wait(250)
    end
    isOutsideVehicleLoopRunning = false
end

function insideVehicleLoop()
    if isInsideVehicleLoopRunning then return end
    isInsideVehicleLoopRunning = true

    local vehicleEntity
    while isInsideVehicleLoopRunning do
        local playerPedId = PlayerPedId()
        vehicleEntity = GetVehiclePedIsIn(playerPedId, false)

        if vehicleEntity ~= 0 then
            local vehiclePlate = GetVehicleNumberPlateText(vehicleEntity)
            local isVehicleEngineRunning = GetIsVehicleEngineRunning(vehicleEntity)

            if startedEngines[vehiclePlate] and not isVehicleEngineRunning then
                toggleVehicleEngine(vehicleEntity, true, false, false)
            elseif not startedEngines[vehiclePlate] and isVehicleEngineRunning then
                toggleVehicleEngine(vehicleEntity, false, false, false)
            end
        else
            break
        end
        Wait(250)
    end
    isInsideVehicleLoopRunning = false
    CreateThread(outsideVehicleLoop)
end

CreateThread(insideVehicleLoop)

AddEventHandler("gameEventTriggered", function(eventName)
    if eventName ~= "CEventNetworkPlayerEnteredVehicle" then return end

    CreateThread(insideVehicleLoop)
end)

RegisterCommand("toggleVehicleEngine", function()
    local vehicleEntity = GetVehiclePedIsIn(PlayerPedId(), false)

    if not vehicleEntity or vehicleEntity == 0 then return end

    toggleVehicleEngine(vehicleEntity, nil, true, true)
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
    local nearbyVehicles = Utils.GetNearbyVehicles(GetEntityCoords(PlayerPedId()))
    local vehicle = false

    for i = 1, #nearbyVehicles do
        local vehicleData = nearbyVehicles[i]
        local vehiclePlate = GetVehicleNumberPlateText(vehicleData.vehicle)

        if vehiclePlate == args[1] then
            vehicle = vehicleData.vehicle
            break
        end
    end

    toboolean = { ["true"] = true, ["false"] = false }
    if vehicle then toggleVehicleLock(vehicle, toboolean[args[2]:lower()], false, true) end
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