local Ox = require "@ox_core.lib.init"

local DEFAULT_STORED_LOCATION <const> = "motelgarage"
local fw = {}

local function getPlayer(src)
    return Ox.GetPlayer(tonumber(src))
end

local function getPlayerByIdentifier(identifier)
    local charId = tonumber(identifier)

    if charId then
        return Ox.GetPlayerFromCharId(charId)
    end

    return Ox.GetPlayerFromFilter({ stateId = identifier })
end

local function getAccount(src, moneyType)
    if moneyType ~= "bank" then
        return nil
    end

    local player = getPlayer(src)
    if not player then
        return nil
    end

    return player.getAccount()
end

local function inventoryMoney(src, action, amount)
    if GetResourceState("ox_inventory") ~= "started" then
        return action == "get" and 0 or false
    end

    if action == "add" then
        return exports.ox_inventory:AddItem(src, "money", amount) == true
    elseif action == "remove" then
        return exports.ox_inventory:RemoveItem(src, "money", amount) == true
    end

    return exports.ox_inventory:GetItemCount(src, "money") or 0
end

local function getVehicleModel(vehicle)
    if vehicle.model then
        return type(vehicle.model) == "number" and vehicle.model or joaat(vehicle.model)
    end

    if vehicle.properties then
        local properties = type(vehicle.properties) == "string" and json.decode(vehicle.properties) or vehicle.properties
        if properties?.model then
            return type(properties.model) == "number" and properties.model or joaat(properties.model)
        end
    end
end

local function formatVehicle(vehicle)
    local vehicleModel = getVehicleModel(vehicle)
    if not vehicleModel then
        lib.print.error("No vehicle model found for vehicle plate:", vehicle.plate)
        return
    end

    if not BridgeConfig.VehicleData[vehicleModel] then
        lib.print.error(
            "No vehicle data found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", vehicle.plate,
            " with model:", vehicleModel)
        return
    end

    if not BridgeConfig.VehicleData[vehicleModel].class then
        lib.print.error(
            "No vehicle class found in bridge vehicle data config `BridgeConfig.VehicleData`, for vehicle plate:", vehicle.plate,
            " with model:", vehicleModel)
        return
    end

    local vehData = lib.table.deepclone(BridgeConfig.VehicleData[vehicleModel])
    return lib.table.merge(vehData, vehicle, false)
end

local function formatOxVehicle(vehicle)
    if not vehicle then
        return nil
    end

    local properties = vehicle.getProperties and vehicle.getProperties() or nil

    return formatVehicle({
        id = vehicle.id,
        owner = vehicle.owner,
        plate = vehicle.plate,
        model = vehicle.model,
        properties = properties
    })
end

---@param src number | string
---@return string?
function fw.getIdentifier(src)
    return getPlayer(src)?.stateId
end

---@param identifier string
---@return number?
function fw.getSrcFromIdentifier(identifier)
    return getPlayerByIdentifier(identifier)?.source
end

---@param identifier string
---@return string?
function fw.getCharacterName(identifier)
    local player = getPlayerByIdentifier(identifier)
    if not player then
        return nil
    end

    local firstName = player.get("firstName") or player.get("firstname")
    local lastName = player.get("lastName") or player.get("lastname")

    if (not firstName or not lastName) and player.charId then
        local success, character = pcall(function()
            return MySQL.single.await("SELECT `firstname`, `lastname` FROM `characters` WHERE `charid` = ? LIMIT 1", {
                player.charId
            })
        end)

        if success and character then
            firstName = character.firstname
            lastName = character.lastname
        end
    end

    if not firstName or not lastName then
        return nil
    end

    return ("%s %s"):format(firstName, lastName)
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

    return IsPlayerAceAllowed(src, "admin")
end

---@param src number | string
---@param payload table<string, { type: "set" | "add" | "remove", value: any }>
function fw.setMetadata(src, payload)
    local player = getPlayer(src)
    if not player then return end

    for key, data in pairs(payload) do
        if data.type == "add" or data.type == "remove" then
            local currentValue = player.get(key) or 0
            local newValue = data.type == "add" and (currentValue + data.value) or (currentValue - data.value)

            if newValue > 100 then
                newValue = 100
            elseif newValue < 0 then
                newValue = 0
            end

            player.set(key, newValue, true)
        else
            player.set(key, data.value, true)
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
        local charId = tonumber(identifier) or Ox.GetCharIdFromStateId(identifier)
        if not charId then return end

        MySQL.update([[
            UPDATE characters
            SET x = ?, y = ?, z = ?, heading = ?
            WHERE charid = ?
        ]], {
            coords.x,
            coords.y,
            coords.z,
            coords.w or 0.0,
            charId
        })
        return
    end

    player.set("position", coords, true)
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
---@param moneyType "cash" | "bank"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.addMoney(src, moneyType, moneyAmount, reason)
    if moneyType == "cash" then
        return inventoryMoney(src, "add", moneyAmount)
    end

    if moneyType ~= "bank" then
        lib.print.error(("ox_core does not support money type '%s' (use 'cash' or 'bank')"):format(tostring(moneyType)))
        return false
    end

    local account = getAccount(src, moneyType)
    if not account then
        return false
    end

    local result = account.addBalance({
        amount = moneyAmount,
        message = reason
    })

    return result?.success == true
end

---@param src number | string
---@param moneyType "cash" | "bank"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.removeMoney(src, moneyType, moneyAmount, reason)
    if moneyType == "cash" then
        return inventoryMoney(src, "remove", moneyAmount)
    end

    if moneyType ~= "bank" then
        lib.print.error(("ox_core does not support money type '%s' (use 'cash' or 'bank')"):format(tostring(moneyType)))
        return false
    end

    local account = getAccount(src, moneyType)
    if not account then
        return false
    end

    local result = account.removeBalance({
        amount = moneyAmount,
        message = reason
    })

    return result?.success == true
end

---@param src number | string
---@param moneyType "cash" | "bank"
---@return number
function fw.getMoney(src, moneyType)
    if moneyType == "cash" then
        return inventoryMoney(src, "get")
    end

    if moneyType ~= "bank" then
        lib.print.error(("ox_core does not support money type '%s' (use 'cash' or 'bank')"):format(tostring(moneyType)))
        return 0
    end

    local account = getAccount(src, moneyType)
    if not account then
        return 0
    end

    return account.get("balance") or 0
end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(src, job, grade, duty)
    local player = getPlayer(src)
    if not player then
        return false
    end

    local playerGrade = player.getGroup(job)
    if not playerGrade then
        return false
    end

    if grade and playerGrade < grade then
        return false
    end

    if duty and player.get("activeGroup") ~= job then
        return false
    end

    return true
end

---@param src number | string
---@param gang string
---@param grade number? do they require a minimum grade
---@return boolean
function fw.hasGang(src, gang, grade)
    local player = getPlayer(src)
    if not player then
        return false
    end

    local playerGrade = player.getGroup(gang)
    if not playerGrade then
        return false
    end

    if grade and playerGrade < grade then
        return false
    end

    return true
end

---@param jobName string
---@return number
function fw.getDutyCountJob(jobName)
    local players = Ox.GetGroupActivePlayers(jobName)
    return players and #players or 0
end

---@param jobName string
---@return table<number, true>
function fw.getPlayersOnDuty(jobName)
    local formattedPlayers = {}
    local players = Ox.GetGroupActivePlayers(jobName)

    for i = 1, #(players or {}) do
        formattedPlayers[players[i]] = true
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

    lib.print.debug(("prp-bridge: Player %d used item %s from slot %d"):format(payload.source, json.encode(item, { indent = true }), item.slot))

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
    lib.print.debug("Registering item use for item:", itemName)
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
    local activeVehicle = Ox.GetVehicleFromFilter({ plate = plate })
    if activeVehicle then
        return formatOxVehicle(activeVehicle)
    end

    local success, vehicle = pcall(function()
        return MySQL.single.await("SELECT `id`, `owner`, `plate`, `model`, `data` AS `properties` FROM `vehicles` WHERE `plate` = ? LIMIT 1", {
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

    return formatVehicle(vehicle)
end

---@param identifier string | number
---@param classes? string | table<string>
---@return table<number, OwnedVehicle> | nil
function fw.getAllOwnedVehicles(identifier, classes)
    local charId = tonumber(identifier) or Ox.GetCharIdFromStateId(identifier)
    if not charId then
        return {}
    end

    local success, vehicles = pcall(function()
        return MySQL.query.await("SELECT `id`, `owner`, `plate`, `model`, `data` AS `properties` FROM `vehicles` WHERE `owner` = ?", {
            charId
        })
    end)

    if not success then
        lib.print.error("Unable to get owned vehicles from database in framework:", BridgeConfig.FrameWork)
        return nil
    end

    local filtered = {}
    for _, vehicle in pairs(vehicles) do
        local formattedVehicle = formatVehicle(vehicle)
        if formattedVehicle and (not classes or formattedVehicle.class and (type(classes) == "table" and lib.table.contains(classes, formattedVehicle.class) or formattedVehicle.class == classes)) then
            filtered[#filtered + 1] = formattedVehicle
        end
    end

    return filtered
end

---@param src number
---@param vehicleName string
---@return integer?
---@return string?
function fw.addOwnedVehicle(src, vehicleName)
    local player = getPlayer(src)
    if not player or not player.charId then
        return nil, "CHARACTER_NOT_LOGGED_IN"
    end

    local s, vehicle = pcall(function()
        return Ox.CreateVehicle({
            model = vehicleName,
            owner = player.charId,
            stored = DEFAULT_STORED_LOCATION
        })
    end)

    if not s or not vehicle then
        return nil, vehicle
    end

    return vehicle.id
end

---@param plate string
---@param identifier string
---@return boolean
---@return string?
function fw.updateVehicleOwner(plate, identifier)
    local charId = tonumber(identifier) or Ox.GetCharIdFromStateId(identifier)
    if not charId then
        return false, "CHARACTER_NOT_FOUND"
    end

    local vehicle = Ox.GetVehicleFromFilter({ plate = plate })
    if vehicle then
        vehicle.setOwner(charId)
        return true
    end

    local ownedVehicle = bridge.fw.getOwnedVehicleByPlate(plate)
    if not ownedVehicle then
        return false, "VEHICLE_NOT_FOUND"
    end

    local s, r = pcall(function()
        return MySQL.update.await("UPDATE `vehicles` SET `owner` = ? WHERE `plate` = ?", { charId, plate })
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
    AddEventHandler("ox:playerLoaded", function(playerId)
        local stateId = fw.getIdentifier(playerId)
        if not stateId then return end
        TriggerEvent("prp-bridge:server:playerLoad", playerId)
    end)

    AddEventHandler("ox:playerLogout", function(playerId)
        TriggerEvent("prp-bridge:server:playerUnload", playerId)
    end)
end

return fw
