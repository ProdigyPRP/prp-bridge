local vkeys = {}

---@param src number | string Player server id
---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
function vkeys.give(src, vehicle, plate)
    local target = tonumber(src)
    if not target then return end

    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    local netId = vehicle and vehicle ~= 0 and NetworkGetNetworkIdFromEntity(vehicle) or nil

    TriggerClientEvent("p_vehiclekeys:prp-bridge:giveKey", target, plate, netId)
end

---@param src number | string Player server id
---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
function vkeys.remove(src, vehicle, plate)
    local target = tonumber(src)
    if not target then return end

    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    TriggerClientEvent("p_vehiclekeys:prp-bridge:removeKey", target, plate)
end

return vkeys
