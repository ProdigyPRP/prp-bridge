local NDCore = exports["ND_Core"]
local fw = {}

---Returns true if the given plate exists
---@param plate string
---@return boolean
local function doesVehiclePlateExist(plate)
    local result = MySQL.scalar.await('SELECT 1 FROM nd_vehicles WHERE plate = ? LIMIT 1', { plate })
    return result ~= nil
end

---@param src number | string
---@return string?
function fw.getIdentifier(src)
    local player = NDCore:getPlayer(src)
    if not player then
        return nil
    end

    return tostring(player.id)
end

local function getPlayerByIdentifier(identifier)
    for _, info in pairs(NDCore:getPlayers()) do
        if tostring(info.id) == tostring(identifier) then
            return info
        end
    end

    return nil
end

---@param identifier string
---@return number?
function fw.getSrcFromIdentifier(identifier)
    local player = getPlayerByIdentifier(identifier)

    if player then
        return player.source
    end

    return nil
end

---@param identifier string
---@return string?
function fw.getCharacterName(identifier)
    local player = getPlayerByIdentifier(identifier)
    if not player then
        return nil
    end

    return player.fullname
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
    local player = NDCore:getPlayer(src)
    if not player then return end

    -- TODO: needs split logic, like ESX
    for key, data in pairs(payload) do
        if data.type == "add" or data.type == "remove" then
            local currentValue = player.getMetadata(key) or 0
            local newValue = data.type == "add" and (currentValue + data.value) or (currentValue - data.value)

            if newValue > 100 then
                newValue = 100
            elseif newValue < 0 then
                newValue = 0
            end

            player.setMetadata(key, newValue)
        else
            player.setMetadata(key, data.value)
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
    local player = getPlayerByIdentifier(identifier)
    if not player then
        MySQL.update([[
            UPDATE nd_characters
            SET metadata = JSON_SET(
                metadata,
                '$.location',
                JSON_OBJECT('x', ?, 'y', ?, 'z', ?, 'w', ?)
            )
            WHERE charId = ?
        ]], {
            coords.x,
            coords.y,
            coords.z,
            coords.w or 0.0,
            identifier
        })
        return
    end

    player.setMetadata('position', coords)
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
    local player = NDCore:getPlayer(src)
    if not player then return false end

    return player.addMoney(moneyType, moneyAmount, reason)
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@return number
function fw.getMoney(src, moneyType)
    local player = NDCore:getPlayer(src)
    if not player then
        return 0
    end

    return player[moneyType]
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.removeMoney(src, moneyType, moneyAmount, reason)
    local player = NDCore:getPlayer(src)
    if not player then return false end

    return player.deductMoney(moneyType, moneyAmount, reason)
end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(src, job, grade, duty)
    local player = NDCore:getPlayer(src)
    if not player then
        return false
    end

    local playerJob = player.getGroup(job)

    if not playerJob then
        return false
    end

    if grade then
        local gradeId = playerJob.rank
        if gradeId < grade then
            return false
        end
    end

    if duty then
        -- ND Core does not have duty system
        return true
    end

    return true
end

---@param src number | string
---@param gang string
---@param grade number? do they require a minimum grade
---@return boolean
function fw.hasGang(src, gang, grade)
    local player = NDCore:getPlayer(src)
    if not player then
        return false
    end

    local playerGang = player.getGroup(gang)

    if not playerGang then
        return false
    end

    if grade then
        local gradeId = playerGang.rank
        if gradeId < grade then
            return false
        end
    end

    return true
end

---@param jobName string
---@return number
function fw.getDutyCountJob(jobName)
    local players = NDCore:getPlayers("job", jobName, true)
    return #players
end

---@param jobName string
---@return table<number, true>
function fw.getPlayersOnDuty(jobName)
    local formattedPlayers = {}
    local players = NDCore:getPlayers("job", jobName, true)
    for _, player in ipairs(players) do
        formattedPlayers[player.source] = true
    end
    return formattedPlayers
end

---@type table<string, fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })>
local itemsRegistry = {}
---@type table<string, string>
local itemUseHooks = {}

local function dispatchRegisteredItemUse(success, payload)
    if not success then return end

    local item = payload.item
    local handler = itemsRegistry[item.name]
    if not handler then return lib.print.debug("No handler found for item:", item.name) end

    lib.print.debug(('prp-bridge: Player %d used item %s from slot %d'):format(payload.source, json.encode(item, { indent = true }), item.slot))

    local data = {
        name = item.name,
        label = item.label,
        metaData = item.metadata,
        slot = item.slot,
        count = item.count,
    }

    local s, e = pcall(handler, payload.source, data)
    if not s then
        lib.print.debug(("prp-bridge: Error in item usage handler for item '%s': %s"):format(item.name, e))
    end
end

---@param itemName string
---@param cb fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })
function fw.registerItemUse(itemName, cb)
    lib.print.debug('Registering item use for item:', itemName)
    itemsRegistry[itemName] = cb

    if itemUseHooks[itemName] then
        return
    end

    local hookId = exports.ox_inventory:registerHook("usingItem", nil, {
        itemFilter = {
            [itemName] = true,
        }
    })

    itemUseHooks[itemName] = hookId
    AddEventHandler(hookId, dispatchRegisteredItemUse)
end

---@param plate string
---@param returnEmpty? boolean should empty table format be returned
---@return OwnedVehicle | nil
function fw.getOwnedVehicleByPlate(plate, returnEmpty)
    local success, vehicle = pcall(function()
        return MySQL.single.await('SELECT `plate`, `properties` FROM `nd_vehicles` WHERE `plate` = ? LIMIT 1', {
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

    if not vehicle.properties then
        lib.print.error("No vehicle properties found in database for vehicle plate:", plate)
        return
    end

    vehicle.properties = json.decode(vehicle.properties)
    if not vehicle.properties.model then
        lib.print.error("No vehicle model found in properties in database for vehicle plate:", plate)
        return
    end

    if type(vehicle.properties.model) ~= "number" then
        vehicle.properties.model = joaat(vehicle.properties.model)
    end

    if not BridgeConfig.VehicleData[vehicle.properties.model] then
        lib.print.error(
            "No vehicle data found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicle.properties.model)
        return
    end

    if not BridgeConfig.VehicleData[vehicle.properties.model].class then
        lib.print.error(
            "No vehicle class found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", plate,
            " with model:", vehicle.properties.model)
        return
    end

    local vehData = lib.table.deepclone(BridgeConfig.VehicleData[vehicle.properties.model])
    return lib.table.merge(vehData, vehicle, false)
end

---@param identifier string | number
---@param classes? string | table<string>
---@return table<number, OwnedVehicle> | nil
function fw.getAllOwnedVehicles(identifier, classes)
    local success, vehicles = pcall(function()
        return MySQL.query.await('SELECT `plate`, `properties` FROM `nd_vehicles` WHERE `owner` = ?', {
            identifier
        })
    end)

    if not success then
        lib.print.error("Unable to get owned vehicles from database in framework:", BridgeConfig.FrameWork)
        return nil
    end

    local filtered = {}
    for _, vehicle in pairs(vehicles) do
        if not vehicle.properties then
            goto continue
        end

        vehicle.properties = json.decode(vehicle.properties)
        if not vehicle.properties or not vehicle.properties.model then
            goto continue
        end

        if type(vehicle.properties.model) ~= "number" then
            vehicle.properties.model = joaat(vehicle.properties.model)
        end

        local vehData = BridgeConfig.VehicleData[vehicle.properties.model]
        if not classes or vehData and vehData.class and (type(classes) == "table" and lib.table.contains(classes, vehData.class) or vehData.class == classes) then
            local newData = lib.table.deepclone(vehData)
            filtered[#filtered + 1] = lib.table.merge(newData, vehicle, false)
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

    local insertId = nil
    local properties = {
        model = joaat(vehicleName),
        plate = plate,
        plateIndex = 0,
        bodyHealth = 1000,
        engineHealth = 1000,
        tankHealth = 1000,
        fuelLevel = 100
    }

    local s, e = pcall(function()
        local id, err = MySQL.insert.await('INSERT INTO nd_vehicles (owner, plate, properties) VALUES (?, ?, ?)', {
            stateId,
            plate,
            json.encode(properties)
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
        return MySQL.update.await("UPDATE `nd_vehicles` SET `owner` = ? WHERE `plate` = ?", { identifier, plate })
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
    RegisterNetEvent('ND:characterLoaded', function(data)
        print("(nd) player loaded")
        if not data or not data.source then return end
        local stateId = fw.getIdentifier(data.source)
        if not stateId then return end
        TriggerEvent('prp-bridge:server:playerLoad', data.source)
    end)

    AddEventHandler('ND:characterUnloaded', function(src)
        TriggerEvent('prp-bridge:server:playerUnload', src)
    end)
end

return fw
