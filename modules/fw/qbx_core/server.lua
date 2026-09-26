local DEFAULT_GARAGE_ID <const> = "motelgarage"

local fw = {}

---@param src number | string
---@return string?
function fw.getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return nil
    end

    if not player.PlayerData then
        return nil
    end

    return player.PlayerData.citizenid
end

---@param identifier string
---@return number?
function fw.getSrcFromIdentifier(identifier)
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not player then
        return nil
    end

    if not player.PlayerData then
        return nil
    end

    return player.PlayerData.source
end

---@param identifier string
---@return string?
function fw.getCharacterName(identifier)
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not player then
        return nil
    end

    if not player.PlayerData then
        return nil
    end

    local charInfo = player.PlayerData.charinfo

    if not charInfo then
        return nil
    end

    return ("%s %s"):format(charInfo.firstname, charInfo.lastname)
end

---@param src number | string
---@param type 'inform' | 'error' | 'success'| 'warning'
---@param message string
---@param title? string
---@param duration? number
function fw.notify(src, type, message, title, duration)
    TriggerClientEvent("prp-bridge:notify", src, type, message, title, duration)
end

---@param commandName string
---@param helpText string
---@param params table<{ name: string, type: string, help: string }>?
---@param restrictedGroup string?
---@param callback fun(src: number, args: table, rawCommand: string)
function fw.registerCommand(commandName, helpText, params, restrictedGroup, callback)
    lib.addCommand(commandName, {
        help = helpText,
        params = params,
        restricted = restrictedGroup
    }, callback)
end

---@param src string | number
---@return boolean
function fw.isAdmin(src)
    if type(src) == "number" then
        src = tostring(src)
    end

    return IsPlayerAceAllowed(src, 'admin')
end

---@param src number | string
---@param payload table<string, { type: "set" | "add" | "remove", value: any }>
function fw.setMetadata(src, payload)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    for key, data in pairs(payload) do
        if data.type == "add" or data.type == "remove" then
            local currentValue = exports.qbx_core:GetMetadata(src, key) or 0
            local newValue = data.type == "add" and (currentValue + data.value) or (currentValue - data.value)

            if newValue > 100 then
                newValue = 100
            elseif newValue < 0 then
                newValue = 0
            end

            exports.qbx_core:SetMetadata(src, key, newValue)
        else
            exports.qbx_core:SetMetadata(src, key, data.value)
        end
    end
end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function fw.addRep(src, rep, amount, reason)

end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function fw.removeRep(src, rep, amount, reason)

end

---@param identifier string
---@param coords vector3
function fw.updateDisconnectLocation(identifier, coords)
    local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
    if not player then
        MySQL.update('UPDATE players SET position = ? WHERE citizenid = ?', {
            json.encode(coords),
            identifier
        })
        return
    end

    exports.qbx_core:SetPlayerData(player.PlayerData.source, 'position', coords)
end

---@param explosionType number
function fw.isExplosionAllowed(explosionType)
    -- Use your anticheat for checking
    return true
end

---@param explosionType number
---@param time number
function fw.allowExplosion(explosionType, time)
    -- Use your anticheat for allowing
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.addMoney(src, moneyType, moneyAmount, reason)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    return exports.qbx_core:AddMoney(src, moneyType, moneyAmount, reason)
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.removeMoney(src, moneyType, moneyAmount, reason)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end

    return exports.qbx_core:RemoveMoney(src, moneyType, moneyAmount, reason)
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@return number
function fw.getMoney(src, moneyType)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return 0 end

    return exports.qbx_core:GetMoney(src, moneyType)
end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(src, job, grade, duty)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return false
    end

    local jobId = player.PlayerData.job.name
    if jobId ~= job then
        return false
    end

    if grade then
        local gradeId = player.PlayerData.job.grade.level
        if gradeId < grade then
            return false
        end
    end

    if duty then
        if not player.PlayerData.job.onduty then
            return false
        end
    end

    return true
end

---@param src number | string
---@param gang string
---@param grade number? do they require a minimum grade
---@return boolean
function fw.hasGang(src, gang, grade)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return false
    end

    local gangId = player.PlayerData.gang.name
    if gangId ~= gang then
        return false
    end

    if grade then
        local gradeId = player.PlayerData.gang.grade.level
        if gradeId < grade then
            return false
        end
    end

    return true
end

---@param jobName string
---@return number
function fw.getDutyCountJob(jobName)
    return exports.qbx_core:GetDutyCountJob(jobName)
end

---@param jobName string
---@return table<number, true>
function fw.getPlayersOnDuty(jobName)
    local count, players = exports.qbx_core:GetDutyCountJob(jobName)
    local formattedPlayers = {}
    for i=1, #players do
        formattedPlayers[players[i]] = true
    end
    return formattedPlayers
end

---@param itemName string
---@param cb fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })
function fw.registerItemUse(itemName, cb)
    exports.qbx_core:CreateUseableItem(itemName, function(src, item)
        local data = {
            name = item.name,
            label = item.label,
            metaData = item.info or item.metadata,
            slot = item.slot,
            count = item.amount or item.count,
        }

        local s, e = pcall(cb, src, data)

        if not s then
            print(("prp-bridge: Error in item usage handler for item '%s': %s"):format(itemName, e))
        end
    end)
end

---@param plate string
---@param returnEmpty? boolean should empty table format be returned
---@return OwnedVehicle | nil
function fw.getOwnedVehicleByPlate(plate, returnEmpty)
    local success, vehicle = pcall(function()
        return MySQL.single.await('SELECT `plate`, `vehicle` FROM `player_vehicles` WHERE `plate` = ? LIMIT 1', {
            plate
        })
    end)

    if not success or not vehicle then
        return returnEmpty and {
            label = locale("UNKNOWN"),
            class = "OPEN",
            plate = plate
        } or nil
    end

    local vehicleModel = joaat(vehicle.vehicle)
    if not BridgeConfig.VehicleData[vehicleModel] then
        lib.print.error(
            "No vehicle data found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicleModel)
        return
    end

    if not BridgeConfig.VehicleData[vehicleModel].class then
        lib.print.error(
        "No vehicle class found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicleModel)
        return
    end

    local vehData = lib.table.deepclone(BridgeConfig.VehicleData[vehicleModel])
    return lib.table.merge(vehData, vehicle, false)
end

---@param identifier string | number
---@param classes? string | table<string>
---@return table<number, OwnedVehicle> | nil
function fw.getAllOwnedVehicles(identifier, classes)
    local success, vehicles = pcall(function()
        return MySQL.query.await('SELECT `vehicle`, `plate` FROM `player_vehicles` WHERE `citizenid` = ?', {
            identifier
        })
    end)

    if not success then
        lib.print.error("Unable to get owned vehicles from database in framework:", BridgeConfig.FrameWork)
        return nil
    end

    local filtered = {}
    for _, vehicle in pairs(vehicles) do
        local vehData = BridgeConfig.VehicleData[joaat(vehicle.vehicle)]
        if not classes or vehData and vehData.class and (type(classes) == "table" and lib.table.contains(classes, vehData.class) or vehData.class == classes) then
            local newData = lib.table.deepclone(vehData)
            filtered[#filtered+1] = lib.table.merge(newData, vehicle, false)
        end
    end

    return filtered
end

---@param src number
---@param vehicleName string
---@return integer?
---@return string?
function fw.addOwnedVehicle(src, vehicleName)
    local stateId = bridge.fw.getIdentifier(src)
    if not stateId then
        return nil, "CHARACTER_NOT_LOGGED_IN"
    end

    local insertId = nil
    local s, e = pcall(function()
        local id, err = exports.qbx_vehicles:CreatePlayerVehicle({
            citizenid = stateId,
            model = vehicleName,
            garage = DEFAULT_GARAGE_ID
        })

        if err then
            lib.print.error(err)
            error(err)
            return
        end

        insertId = id
    end)

    if not s or not insertId then
        return nil, e
    end

    return insertId
end

---@param plate string
---@param identifier string
---@return boolean
---@return string?
function fw.updateVehicleOwner(plate, identifier)
    local vehicle = bridge.fw.getOwnedVehicleByPlate(plate)
    if not vehicle then
        return false, "VEHICLE_NOT_FOUND"
    end

    local s, r = pcall(function()
        return MySQL.update.await("UPDATE `player_vehicles` SET `citizenid` = ? WHERE `plate` = ?", { identifier, plate })
    end)

    if not s then
        return false, r
    end

    if r == 0 then
        return false, "OWNER_NOT_UPDATED"
    end

    return true
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        local stateId = fw.getIdentifier(src)
        if not stateId then return end
        TriggerEvent('prp-bridge:server:playerLoad', src)
    end)

    AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
        TriggerEvent('prp-bridge:server:playerUnload', src)
    end)
end

return fw
