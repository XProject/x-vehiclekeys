local PLAYER_ID = PlayerId()
local isInsideVehicleLoopRunning, isOutsideVehicleLoopRunning = false, false

local function canControlVehicle(vehicleEntity)
    return NetworkGetEntityOwner(vehicleEntity) == PLAYER_ID and NetworkHasControlOfEntity(vehicleEntity)
end

local function playSoundFromEntity(vehicleEntity, audioName, audioRef)
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, audioName, vehicleEntity, audioRef, true, false)
    ReleaseSoundId(soundId)
end

local function blinkVehicleLights(vehicleEntity)
    CreateThread(function()
        NetworkRequestControlOfEntity(vehicleEntity)
        for _ = 1, 5 do
            Wait(200)
            SetVehicleLights(vehicleEntity, 2)
            Wait(200)
            SetVehicleLights(vehicleEntity, 0)
        end
    end)
end

local function toggleVehicleEngine(vehicleEntity, state, checkCanControl, notify)
    if checkCanControl and not canControlVehicle(vehicleEntity) then return end

    if state == nil then
        state = not Entity(vehicleEntity).state[Shared.State.vehicleEngine]
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

    TriggerServerEvent(Shared.Event.vehicleLock, VehToNet(vehicleEntity), state)

    playSoundFromEntity(vehicleEntity, "Door_Open", "Lowrider_Super_Mod_Garage_Sounds")
    blinkVehicleLights(vehicleEntity)
end

local function outsideVehicleLoop()
    if Config.LockState ~= 4 and not Config.PreventBreakingWindows then return end
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
        Wait(350)
    end
    isOutsideVehicleLoopRunning = false
end

local function insideVehicleLoop()
    if isInsideVehicleLoopRunning then return end
    isInsideVehicleLoopRunning = true

    local vehicleEntity
    while isInsideVehicleLoopRunning do
        local playerPedId = PlayerPedId()
        vehicleEntity = GetVehiclePedIsIn(playerPedId, false)
        if vehicleEntity ~= 0 then
            local isVehicleEngineRunning = GetIsVehicleEngineRunning(vehicleEntity) or IsVehicleEngineStarting(vehicleEntity)
            local isVehicleStarted = Entity(vehicleEntity).state[Shared.State.vehicleEngine]
            if isVehicleStarted and not isVehicleEngineRunning then
                toggleVehicleEngine(vehicleEntity, true, false, false)
            elseif not isVehicleStarted and isVehicleEngineRunning then
                toggleVehicleEngine(vehicleEntity, false, false, false)
            end
        else
            break
        end
        Wait(350)
    end
    isInsideVehicleLoopRunning = false
    CreateThread(outsideVehicleLoop)
end

CreateThread(insideVehicleLoop)

AddEventHandler("gameEventTriggered", function(eventName)
    if eventName ~= "CEventNetworkPlayerEnteredVehicle" then return end

    CreateThread(insideVehicleLoop)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleEngine, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)
    if not vehicleEntity or vehicleEntity == 0 or not canControlVehicle(vehicleEntity) then return end

    SetVehicleEngineOn(vehicleEntity, value, true, true)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleLock, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)
    if not vehicleEntity or vehicleEntity == 0 then return end

    SetVehicleDoorsLocked(vehicleEntity, value and Config.LockState or Config.UnlockState)
    if value then SetVehicleDoorsShut(vehicleEntity, false) end
end)

RegisterCommand("toggleVehicleEngine", function()
    local vehicleEntity = GetVehiclePedIsIn(PlayerPedId(), false)

    if not vehicleEntity or vehicleEntity == 0 then return end

    toggleVehicleEngine(vehicleEntity, nil, true, true)
end, false)
RegisterKeyMapping("toggleVehicleEngine", "Toggle Vehicle Engine", "keyboard", Config.ToggleVehicleEngine)

RegisterCommand("toggleVehicleLock", function()
    local vehicleEntity = GetVehiclePedIsIn(playerPedId, false)
    vehicleEntity = vehicleEntity == 0 and Utils.GetClosestVehicle(GetEntityCoords(PlayerPedId())) or vehicleEntity

    if vehicleEntity then toggleVehicleLock(vehicleEntity, nil, false, true) end
end, false)
RegisterKeyMapping("toggleVehicleLock", "Toggle Vehicle Lock", "keyboard", Config.ToggleVehicleLock)

if Config.Debug then
    RegisterCommand("lock", function(_, args)
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
end

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