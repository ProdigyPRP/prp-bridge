local vkeys = {}

---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
function vkeys.give(vehicle, plate)
    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    exports["p_vehiclekeys"]:createKey(plate, vehicle)
end

---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
function vkeys.remove(vehicle, plate)
    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    exports["p_vehiclekeys"]:removeKey(plate, vehicle, true)
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent("p_vehiclekeys:prp-bridge:giveKey", function(plate, netId)
        local vehicle = netId and NetworkGetEntityFromNetworkId(netId) or 0

        if vehicle == 0 then
            return lib.print.debug("p_vehiclekeys: vehicle is not streamed in, cannot give key for plate", plate)
        end

        exports["p_vehiclekeys"]:createKey(plate, vehicle)
    end)

    RegisterNetEvent("p_vehiclekeys:prp-bridge:removeKey", function(plate)
        exports["p_vehiclekeys"]:removeKey(plate, nil, true)
    end)
end

return vkeys
