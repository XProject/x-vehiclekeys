Shared = {}

Shared.currentResourceName = GetCurrentResourceName()

Shared.State = {}

Shared.State.vehicleEngine = ("%s_vehicleEngine"):format(Shared.currentResourceName)

Shared.State.vehicleLock = ("%s_vehicleLock"):format(Shared.currentResourceName)

Shared.Event = {}

Shared.Event.vehicleLock = ("%s:vehicleLock"):format(Shared.currentResourceName)

function dumpTable(table, nb)
    if nb == nil then
        nb = 0
    end

    if type(table) == 'table' then
        local s = ''
        for i = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = '{\n'
        for k, v in pairs(table) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            for i = 1, nb, 1 do
                s = s .. "    "
            end
            s = s .. '[' .. k .. '] = ' .. dumpTable(v, nb + 1) .. ',\n'
        end

        for i = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. '}'
    else
        return tostring(table)
    end
end