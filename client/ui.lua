local export = exports[Shared.currentResourceName]
local isUiOpen = false

local function ui(state, vehiclePlate)
    SetNuiFocus(state, state)
    SendNUIMessage({
        type = state and "OpenUI" or "CloseUI",
        plate = vehiclePlate
    })
end

local function openUi(vehiclePlate)
    if isUiOpen then return end
    isUiOpen = true

    ui(true, vehiclePlate)

    if Config.AllowSomeKeyboardAndMouseInputs then SetNuiFocusKeepInput(true) end
    if Config.SetMouseCursorNearRemote then SetCursorLocation(0.9, 0.85) end
end

local function closeUi()
    if not isUiOpen then return end
    isUiOpen = false

    ui(false)
end

local function modifyVehicle(action, plate, state)
    local nearbyVehicles = Utils.GetNearbyVehicles(GetEntityCoords(PlayerPedId()))
    local vehicleEntity = false

    for i = 1, #nearbyVehicles do
        local vehicleData = nearbyVehicles[i]
        local vehiclePlate = GetVehicleNumberPlateText(vehicleData.vehicle)

        if vehiclePlate == plate then
            vehicleEntity = vehicleData.vehicle
            break
        end
    end

    if not vehicleEntity then return Utils.Notification(nil, ("No vehicle with the plate of %s is in range of the remote."):format(plate), "error") end

    if action == "lock" then
        export:toggleVehicleLock(vehicleEntity, state, false)
    elseif action == "engine" then
        export:toggleVehicleEngine(vehicleEntity, state, false, true)
    elseif action == "trunk" then
        local isTrunkOpen = GetVehicleDoorAngleRatio(vehicleEntity, 5) > 0.0
        if isTrunkOpen then
            SetVehicleDoorShut(vehicleEntity, 5, false)
        else
            SetVehicleDoorOpen(vehicleEntity, 5, false, false)
        end
        Utils.Notification(nil, ("%s Trunk %s"):format(plate, isTrunkOpen and "Closed" or "Opened"), "inform")
    elseif action == "alarm" then
        local isAlarmActive = IsVehicleAlarmActivated(vehicleEntity)
        if isAlarmActive then
            export:stopVehicleAlarm(vehicleEntity)
        else
            export:playVehicleAlarm(vehicleEntity, state)
        end
        Utils.Notification(nil, ("%s Alarm %s"):format(plate, isAlarmActive and "Off" or "On"), "inform")
    end
end

RegisterNUICallback("Close", function(data, cb)
    closeUi()
    cb(true)
end)

RegisterNUICallback("Lock", function(data, cb)
    modifyVehicle("lock", data.plate, true)
    cb(true)
end)

RegisterNUICallback("Unlock", function(data, cb)
    modifyVehicle("lock", data.plate, false)
    cb(true)
end)

RegisterNUICallback("Engine", function(data, cb)
    modifyVehicle("engine", data.plate)
    cb(true)
end)

RegisterNUICallback("Trunk", function(data, cb)
    modifyVehicle("trunk", data.plate)
    cb(true)
end)

RegisterNUICallback("Alarm", function(data, cb)
    modifyVehicle("alarm", data.plate, 60000)
    cb(true)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= Shared.currentResourceName then return end
    closeUi()
end)

if Config.Debug then
    RegisterCommand("toggleVehicleRemote", function()
        local vehicleEntity = GetVehiclePedIsIn(playerPedId, false)
        vehicleEntity = vehicleEntity == 0 and Utils.GetClosestVehicle(GetEntityCoords(PlayerPedId())) or vehicleEntity
    
        if vehicleEntity then openUi(GetVehicleNumberPlateText(vehicleEntity)) end
    end, false)
    RegisterKeyMapping("toggleVehicleRemote", "Toggle Vehicle Remote", "keyboard", "K")
end