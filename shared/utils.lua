Utils = {}

Utils.IsDuplicityVersion = IsDuplicityVersion()

---@param source? number
---@param message string
---@param type? string
---@param duration? number
function Utils.Notification(source, message, type, duration)
    local data = {
        title = "Vehicle System",
        description = message,
        type = type or "inform",
        duration = duration or 5000,
        position = "center-right"
    }
    if not Utils.IsDuplicityVersion then
        return TriggerEvent("ox_lib:notify", data)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        return TriggerClientEvent("ox_lib:notify", source, data)
    end
end

---@param coords vector3
---@return table
function Utils.GetNearbyVehicles(coords)
    local vehicles = GetGamePool("CVehicle")
    local nearby = {}
    local count = 0

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehicleCoords = GetEntityCoords(vehicle)

        if #(coords - vehicleCoords) <= Config.MaxRemoteRange then
            count += 1
            nearby[count] = {
                vehicle = vehicle,
                coords = vehicleCoords
            }
        end
    end

    return nearby
end