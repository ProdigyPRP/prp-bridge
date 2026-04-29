local ESX = exports.es_extended:getSharedObject()
local fw = {}

---Returns true if the given plate exists
---@param plate string
---@return boolean
local function doesVehiclePlateExist(plate)
    local result = MySQL.scalar.await('SELECT 1 FROM owned_vehicles WHERE plate = ? LIMIT 1', { plate })
    return result ~= nil
end

local playerToJob = {} ---@type table<number, string>
local jobToPlayers = {} ---@type table<string, table<number, true>>

---@param src number | string
---@return string?
function fw.getIdentifier(src)
    local player = ESX.GetPlayerFromId(src)
    if not player then
        return nil
    end

    return player.getIdentifier()
end

---@param identifier string
---@return number?
function fw.getSrcFromIdentifier(identifier)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if not player then
        return nil
    end

    return player.source
end

---@param identifier string
---@return string?
function fw.getCharacterName(identifier)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if not player then
        return nil
    end

    return player.name
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

    local player = ESX.GetPlayerFromId(src)
    if not player then
        return false
    end

    return player.isAdmin()
end

---@param src number | string
---@param payload table<string, { type: "set" | "add" | "remove", value: any }>
function fw.setMetadata(src, payload)
    local player = ESX.GetPlayerFromId(src)
    if not player then
        return
    end

    -- TODO: Might need to split logic for thirst, hunger and etc.
    for key, data in pairs(payload) do
        if data.type == "add" or data.type == "remove" then
            local currentValue = player.getMeta(key) or 0
            local newValue = data.type == "add" and (currentValue + data.value) or (currentValue - data.value)

            if newValue > 100 then
                newValue = 100
            elseif newValue < 0 then
                newValue = 0
            end


            player.setMeta(key, newValue)
        else
            player.setMeta(key, data.value)
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
    local player = QBCore.Functions.GetPlayerByCitizenId(identifier)
    if not player then
        MySQL.update('UPDATE players SET position = ? WHERE citizenid = ?', {
            json.encode(coords),
            identifier
        })
        return
    end

    player.Functions.SetPlayerData('position', coords)
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
    local player = ESX.GetPlayerFromId(src)
    if not player then return false end

    if moneyType == "cash" then
        ---@diagnostic disable-next-line
        moneyType = "money"
    end

    player.addAccountMoney(moneyType, moneyAmount, reason)
    return true
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@return number
function fw.getMoney(src, moneyType)
    local player = ESX.GetPlayerFromId(src)
    if not player then
        return 0
    end

    if moneyType == "cash" then
        ---@diagnostic disable-next-line
        moneyType = "money"
    end


    local account = player.getAccount(moneyType)
    if not account then
        return 0
    end

    return account.money
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.removeMoney(src, moneyType, moneyAmount, reason)
    local player = ESX.GetPlayerFromId(src)
    if not player then return false end

    if moneyType == "cash" then
        ---@diagnostic disable-next-line
        moneyType = "money"
    end

    local account = player.getAccount(moneyType)
    if not account or account.money < moneyAmount then
        return false
    end

    player.removeAccountMoney(moneyType, moneyAmount, reason)
    return true
end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(src, job, grade, duty)
    local player = ESX.GetPlayerFromId(src)
    if not player then
        return false
    end

    local playerJob = player.getJob()

    local jobId = playerJob.name
    if jobId ~= job then
        return false
    end

    if grade then
        local gradeId = playerJob.grade
        if gradeId < grade then
            return false
        end
    end

    if duty then
        if not playerJob.onDuty then
            return false
        end
    end

    return true
end

---@param jobName string
---@return number
function fw.getDutyCountJob(jobName)
    local count = 0
    for src, _ in pairs(jobToPlayers[jobName] or {}) do
        count = count + 1
    end
    return count
end

---@param jobName string
---@return table<number, true>
function fw.getPlayersOnDuty(jobName)
    return jobToPlayers[jobName] or {}
end

---@param itemName string
---@param cb fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })
function fw.registerItemUse(itemName, cb)
    ESX.RegisterUsableItem(itemName, function(src, _, item)
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
        return MySQL.single.await('SELECT `plate`, `vehicle` FROM `owned_vehicles` WHERE `plate` = ? LIMIT 1', {
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

    if not vehicle.vehicle then
        lib.print.error("No vehicle properties found in database for vehicle plate:", plate)
        return
    end

    vehicle.vehicle = json.decode(vehicle.vehicle)
    if not vehicle.vehicle.model then
        lib.print.error("No vehicle model found in properties in database for vehicle plate:", plate)
        return
    end

    if type(vehicle.vehicle.model) ~= "number" then
        vehicle.vehicle.model = joaat(vehicle.vehicle.model)
    end

    if not BridgeConfig.VehicleData[vehicle.vehicle.model] then
        lib.print.error(
            "No vehicle data found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicle.vehicle.model)
        return
    end

    if not BridgeConfig.VehicleData[vehicle.vehicle.model].class then
        lib.print.error(
            "No vehicle class found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicle.vehicle.model)
        return
    end

    local vehData = lib.table.deepclone(BridgeConfig.VehicleData[vehicle.vehicle.model])
    vehData.plate = vehicle.plate
    return lib.table.merge(vehData, vehicle, false)
end

---@param identifier string | number
---@param classes? string | table<string>
---@return table<number, OwnedVehicle> | nil
function fw.getAllOwnedVehicles(identifier, classes)
    local success, vehicles = pcall(function()
        return MySQL.query.await('SELECT `plate`, `vehicle` FROM `owned_vehicles` WHERE `owner` = ?', {
            identifier
        })
    end)

    if not success then
        lib.print.error("Unable to get owned vehicles from database in framework:", BridgeConfig.FrameWork)
        return nil
    end

    local filtered = {}
    for _, vehicle in pairs(vehicles) do
        if not vehicle.vehicle then
            goto continue
        end

        vehicle.properties = json.decode(vehicle.vehicle)
        if not vehicle.properties or not vehicle.properties.model then
            goto continue
        end

        if type(vehicle.properties.model) ~= "number" then
            vehicle.properties.model = joaat(vehicle.properties.model)
        end

        local vehData = lib.table.deepclone(BridgeConfig.VehicleData[vehicle.properties.model])
        vehData.plate = vehicle.plate
        if not classes or vehData and vehData.class and (type(classes) == "table" and lib.table.contains(classes, vehData.class) or vehData.class == classes) then
            filtered[#filtered+1] = lib.table.merge(vehData, vehicle, false)
        end

        ::continue::
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

    local license = GetPlayerIdentifierByType(src --[[@as string]], 'license2') or
        GetPlayerIdentifierByType(src --[[@as string]], 'license')
    if not license then
        return nil, "NO_PLAYER_LICENSE"
    end

    local plate = lib.string.random("........"):upper()
    local timeout = os.time() + 5
    repeat
        plate = lib.string.random("........"):upper()
    until not doesVehiclePlateExist(plate) or os.time() >= timeout

    if os.time() >= timeout then
        return nil, "TIMED_OUT_GETTING_PLATE"
    end

    local properties = {
        model = joaat(vehicleName),
        plate = plate
    }

    local s, e = pcall(function()
        return MySQL.insert.await('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)',
        {
            stateId,
            plate,
            json.encode(properties),
            true
        })
    end)

    if not s then
        lib.print.error(e)
        return nil, e
    end

    -- esx doesn't have pk as vehicle table id
    ---@diagnostic disable-next-line
    return plate
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
        return MySQL.update.await("UPDATE `owned_vehicles` SET `owner` = ? WHERE `plate` = ?", { identifier, plate })
    end)

    if not s then
        return false, r
    end

    if r == 0 then
        return false, "OWNER_NOT_UPDATED"
    end

    return true
end

AddEventHandler("esx:setJob", function(src, job)
    src = tonumber(src)
    if not src then return end
    playerToJob[src] = job.name
    jobToPlayers[job.name] = jobToPlayers[job.name] or {}
    jobToPlayers[job.name][src] = true
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    src = tonumber(src)
    if not src then return end
    local jobName = playerToJob[src]
    if jobName and jobToPlayers[jobName] then
        jobToPlayers[jobName][src] = nil
    end
    playerToJob[src] = nil
end)

AddEventHandler("prp-bridge:server:playerUnload", function(src)
    src = tonumber(src)
    if not src then return end
    local jobName = playerToJob[src]
    if jobName and jobToPlayers[jobName] then
        jobToPlayers[jobName][src] = nil
    end
    playerToJob[src] = nil
end)

if bridge.name == bridge.currentResource then
    AddEventHandler('esx:playerLoaded', function(src)
        local stateId = fw.getIdentifier(src)
        if not stateId then return end
        Wait(1000)
        TriggerEvent('prp-bridge:server:playerLoad', src)
    end)


    AddEventHandler("esx:playerLogout", function(src)
        TriggerEvent("prp-bridge:server:playerUnload", src)
    end)
end

SetTimeout(0, function()
    if ESX.GetPlayers ~= nil then
        local players = ESX.GetPlayers()
        for _, src in ipairs(players) do
            local player = ESX.GetPlayerFromId(src)
            if player then
                local job = player.getJob()
                playerToJob[src] = job.name
                jobToPlayers[job.name] = jobToPlayers[job.name] or {}
                jobToPlayers[job.name][src] = true
            end
        end
    else
        local players = ESX.GetExtendedPlayers()
        for _, player in ipairs(players) do
            local src = tonumber(player.source)
            if src ~= nil then
                playerToJob[src] = player.job.name
                jobToPlayers[player.job.name] = jobToPlayers[player.job.name] or {}
                jobToPlayers[player.job.name][src] = true
            end
        end
    end
end)

return fw
