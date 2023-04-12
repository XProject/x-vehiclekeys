local PLAYER_ID = PlayerId()
local isInsideVehicleLoopRunning, isOutsideVehicleLoopRunning = false, false

local function canControlVehicle(vehicleEntity)
    return NetworkGetEntityOwner(vehicleEntity) == PLAYER_ID and NetworkHasControlOfEntity(vehicleEntity)
end

local function playVehicleAlarm(vehicleEntity, duration)
    SetVehicleAlarm(vehicleEntity, true)
    SetVehicleAlarmTimeLeft(vehicleEntity, duration)
end
exports("playVehicleAlarm", playVehicleAlarm)

local function stopVehicleAlarm(vehicleEntity)
    SetVehicleAlarm(vehicleEntity, false)
end
exports("stopVehicleAlarm", stopVehicleAlarm)

local function blinkVehicleLights(vehicleEntity)
    NetworkRequestControlOfEntity(vehicleEntity)
    CreateThread(function()
        for _ = 1, 5 do
            Wait(200)
            SetVehicleLights(vehicleEntity, 2)
            playVehicleAlarm(vehicleEntity, 150)
            Wait(200)
            SetVehicleLights(vehicleEntity, 0)
        end
    end)
end
exports("blinkVehicleLights", blinkVehicleLights)

local function loadAnimDictionary(animDictionary)
    if not DoesAnimDictExist(animDictionary) then return end
    while not HasAnimDictLoaded(animDictionary) do
        RequestAnimDict(animDictionary)
        Wait(0)
    end
end

local function playKeyfobAnimation()
    loadAnimDictionary("anim@mp_player_intmenu@key_fob@")

    local playerPedId = PlayerPedId()
    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
    local keyFob = CreateObject(`p_car_keys_01`, GetEntityCoords(playerPedId), true, true, true)

    AttachEntityToEntity(keyFob, playerPedId, GetPedBoneIndex(playerPedId, 57005), 0.12, 0.02, -0.02, 0.0, 180.0, 130.0, true, true, false, true, 1, true)
    TaskPlayAnim(PlayerPedId(), "anim@mp_player_intmenu@key_fob@", "fob_click", 3.0, 3.0, -1, 49, 0, false, false, false)

    SetTimeout(1000, function() StopAnimTask(playerPedId, "anim@mp_player_intmenu@key_fob@", "fob_click", 1.0) DeleteEntity(keyFob) end)
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
exports("toggleVehicleEngine", toggleVehicleEngine)

local function toggleVehicleLock(vehicleEntity, state, checkCanControl)
    if checkCanControl and not canControlVehicle(vehicleEntity) then return end

    if state then SetVehicleDoorsShut(vehicleEntity, false) end

    TriggerServerEvent(Shared.Event.vehicleLock, VehToNet(vehicleEntity), state)

    blinkVehicleLights(vehicleEntity)

    playKeyfobAnimation()
end
exports("toggleVehicleLock", toggleVehicleLock)

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
    if not vehicleEntity or vehicleEntity == 0 --[[or not canControlVehicle(vehicleEntity)]] then return end

    SetVehicleEngineOn(vehicleEntity, value, true, true)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(Shared.State.vehicleLock, nil, function(bagName, _, value)
    local vehicleEntity = GetEntityFromStateBagName(bagName)
    if not vehicleEntity or vehicleEntity == 0 then return end

    SetVehicleDoorsLocked(vehicleEntity, value and Config.LockState or Config.UnlockState)
end)

RegisterCommand("toggleVehicleEngine", function()
    local playerPedId = PlayerPedId()
    local vehicleEntity = GetVehiclePedIsIn(playerPedId, false)

    if not vehicleEntity or vehicleEntity == 0 or GetPedInVehicleSeat(vehicleEntity, -1) ~= playerPedId then return end

    toggleVehicleEngine(vehicleEntity, nil, true, true)
end, false)
RegisterKeyMapping("toggleVehicleEngine", "Toggle Vehicle Engine", "keyboard", Config.ToggleVehicleEngine)

RegisterCommand("toggleVehicleLock", function()
    local vehicleEntity = GetVehiclePedIsIn(playerPedId, false)
    vehicleEntity = (vehicleEntity == 0 and Utils.GetClosestVehicle(GetEntityCoords(PlayerPedId()))) or vehicleEntity

    if not vehicleEntity or vehicleEntity == 0 then return end

    toggleVehicleLock(vehicleEntity, GetVehicleDoorLockStatus(vehicleEntity) == 1, false)
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
        if vehicle then toggleVehicleLock(vehicle, toboolean[args[2]:lower()], false) end
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