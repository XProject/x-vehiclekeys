---@param coords vector3
---@return table
function Utils.getNearbyVehicles(coords)
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