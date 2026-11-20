local DEFAULT_CRYPTO_COIN <const> = "MALD"

local fw = {}

---@param src number | string
---@return table?
local function getCharacter(src)
    return exports["sandbox-characters"]:FetchCharacterSource(tonumber(src) or src)
end

---@param identifier string | number
---@return number?
local function toStateId(identifier)
    return tonumber(identifier) or identifier
end

---@param src number | string
---@return string?
function fw.getIdentifier(src)
    local char = getCharacter(src)
    if not char then
        return nil
    end

    local sid = char:GetData("SID")
    if sid == nil then
        return nil
    end

    return tostring(sid)
end

---@param identifier string
---@return number?
function fw.getSrcFromIdentifier(identifier)
    local char = exports["sandbox-characters"]:FetchBySID(toStateId(identifier))
    if not char then
        return nil
    end

    return char:GetData("Source")
end

---@param identifier string
---@return string?
function fw.getCharacterName(identifier)
    local char = exports["sandbox-characters"]:FetchBySID(toStateId(identifier))
    if not char then
        local first = exports["sandbox-characters"]:FetchGetOfflineData(toStateId(identifier), "First")
        local last = exports["sandbox-characters"]:FetchGetOfflineData(toStateId(identifier), "Last")
        if not first or not last then
            return nil
        end
        return ("%s %s"):format(first, last)
    end

    local first = char:GetData("First")
    local last = char:GetData("Last")
    if not first or not last then
        return nil
    end

    return ("%s %s"):format(first, last)
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
    local player = exports["sandbox-base"]:FetchSource(tonumber(src) or src)
    if player and player.Permissions then
        return player.Permissions:IsAdmin() == true
    end

    if type(src) == "number" then
        src = tostring(src)
    end

    return IsPlayerAceAllowed(src, "admin")
end

local statusMetaKeys = {
    hunger = "PLAYER_HUNGER",
    thirst = "PLAYER_THIRST",
    stress = "PLAYER_STRESS",
}

---@param src number | string
---@param payload table<string, { type: "set" | "add" | "remove", value: any }>
function fw.setMetadata(src, payload)
    local source = tonumber(src) or src
    local char = getCharacter(source)
    if not char then return end

    for key, data in pairs(payload) do
        local statusName = statusMetaKeys[key]
        if statusName then
            local current = 0
            if data.type == "add" or data.type == "remove" then
                local status = exports["sandbox-status"]:GetSingle(statusName)
                current = (status and status.value) or 0
                local newValue = data.type == "add" and (current + data.value) or (current - data.value)
                if newValue > 100 then newValue = 100 end
                if newValue < 0 then newValue = 0 end
                exports["sandbox-status"]:Set(source, statusName, newValue)
            else
                exports["sandbox-status"]:Set(source, statusName, data.value)
            end
        else
            if data.type == "add" or data.type == "remove" then
                local currentValue = char:GetData(key) or 0
                if type(currentValue) ~= "number" then
                    currentValue = 0
                end
                local newValue = data.type == "add" and (currentValue + data.value) or (currentValue - data.value)
                char:SetData(key, newValue)
            else
                char:SetData(key, data.value)
            end
        end
    end
end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function fw.addRep(src, rep, amount, reason)
    exports["sandbox-characters"]:RepAdd(tonumber(src) or src, rep, amount)
end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function fw.removeRep(src, rep, amount, reason)
    exports["sandbox-characters"]:RepRemove(tonumber(src) or src, rep, amount)
end

---@param identifier string
---@param coords vector3
function fw.updateDisconnectLocation(identifier, coords)
    -- Sandbox persists last location via Characters logout / playerDropped middleware.
    -- There is no public cross-resource setter for arbitrary coords by SID.
    local char = exports["sandbox-characters"]:FetchBySID(toStateId(identifier))
    if not char or not coords then
        return
    end
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
---@return number|false|nil
local function getPersonalAccountNumber(src)
    local char = getCharacter(src)
    if not char then
        return nil
    end

    local account = char:GetData("BankAccount")
    if account then
        return account
    end

    local personal = exports["sandbox-finance"]:AccountsGetPersonal(char:GetData("SID"))
    return personal and personal.Account or nil
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.addMoney(src, moneyType, moneyAmount, reason)
    local source = tonumber(src) or src
    if not getCharacter(source) then
        return false
    end

    moneyAmount = math.floor(tonumber(moneyAmount) or 0)
    if moneyAmount <= 0 then
        return false
    end

    if moneyType == "cash" then
        return exports["sandbox-finance"]:WalletModify(source, moneyAmount, true) ~= false
    end

    if moneyType == "bank" then
        local account = getPersonalAccountNumber(source)
        if not account then
            return false
        end

        return exports["sandbox-finance"]:BalanceDeposit(account, moneyAmount, {
            type = 1,
            title = reason or "Deposit",
            description = reason or "prp-bridge addMoney",
        }, true) == true
    end

    if moneyType == "crypto" then
        local char = getCharacter(source)
        local wallet = char and char:GetData("CryptoWallet")
        if not wallet then
            return false
        end

        return exports["sandbox-finance"]:CryptoExchangeAdd(DEFAULT_CRYPTO_COIN, wallet, moneyAmount, true) == true
    end

    return false
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function fw.removeMoney(src, moneyType, moneyAmount, reason)
    local source = tonumber(src) or src
    if not getCharacter(source) then
        return false
    end

    moneyAmount = math.floor(tonumber(moneyAmount) or 0)
    if moneyAmount <= 0 then
        return false
    end

    if moneyType == "cash" then
        return exports["sandbox-finance"]:WalletModify(source, -moneyAmount, true) ~= false
    end

    if moneyType == "bank" then
        local account = getPersonalAccountNumber(source)
        if not account then
            return false
        end

        if not exports["sandbox-finance"]:BalanceHas(account, moneyAmount) then
            return false
        end

        return exports["sandbox-finance"]:BalanceWithdraw(account, moneyAmount, {
            type = 0,
            title = reason or "Withdrawal",
            description = reason or "prp-bridge removeMoney",
        }) == true
    end

    if moneyType == "crypto" then
        local char = getCharacter(source)
        local wallet = char and char:GetData("CryptoWallet")
        if not wallet then
            return false
        end

        return exports["sandbox-finance"]:CryptoExchangeRemove(DEFAULT_CRYPTO_COIN, wallet, moneyAmount, true) == true
    end

    return false
end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@return number
function fw.getMoney(src, moneyType)
    local source = tonumber(src) or src
    local char = getCharacter(source)
    if not char then
        return 0
    end

    if moneyType == "cash" then
        return exports["sandbox-finance"]:WalletGet(source) or 0
    end

    if moneyType == "bank" then
        local account = getPersonalAccountNumber(source)
        if not account then
            return 0
        end

        return exports["sandbox-finance"]:BalanceGet(account) or 0
    end

    if moneyType == "crypto" then
        local crypto = char:GetData("Crypto") or {}
        local total = 0
        for _, amount in pairs(crypto) do
            total = total + (tonumber(amount) or 0)
        end
        return total
    end

    return 0
end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(src, job, grade, duty)
    local source = tonumber(src) or src
    local result = exports["sandbox-jobs"]:HasJob(source, job, nil, nil, grade, duty and true or false)
    return result ~= false and result ~= nil
end

---@param src number | string
---@param gang string
---@param grade number? do they require a minimum grade
---@return boolean
function fw.hasGang(src, gang, grade)
    -- Sandbox has no separate gang system; criminal orgs are modeled as jobs.
    return false
end

---@param jobName string
---@return number
function fw.getDutyCountJob(jobName)
    local dutyData = exports["sandbox-jobs"]:DutyGetDutyData(jobName)
    return (dutyData and dutyData.Count) or 0
end

---@param jobName string
---@return table<number, true>
function fw.getPlayersOnDuty(jobName)
    local dutyData = exports["sandbox-jobs"]:DutyGetDutyData(jobName)
    local formatted = {}
    if dutyData and dutyData.DutyPlayers then
        for i = 1, #dutyData.DutyPlayers do
            formatted[dutyData.DutyPlayers[i]] = true
        end
    end
    return formatted
end

---@param itemName string
---@param cb fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })
function fw.registerItemUse(itemName, cb)
    exports.ox_inventory:RegisterUse(itemName, ("prp-bridge:%s"):format(itemName), function(src, item)
        local data = {
            name = item.Name or item.name or itemName,
            label = item.Label or item.label or itemName,
            metaData = item.MetaData or item.metadata or item.info,
            slot = item.Slot or item.slot,
            count = item.Count or item.count or item.amount or 1,
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
        return MySQL.single.await(
            "SELECT `RegisteredPlate` AS `plate`, `Vehicle` AS `vehicle`, `Make`, `Model`, `Class`, `VIN`, `id` FROM `vehicles` WHERE `RegisteredPlate` = ? LIMIT 1",
            { plate }
        )
    end)

    if not success or not vehicle then
        return returnEmpty and {
            label = locale("UNKNOWN"),
            class = "OPEN",
            plate = plate
        } or nil
    end

    local vehicleModel = tonumber(vehicle.vehicle) or joaat(vehicle.vehicle)
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
        return MySQL.query.await(
            "SELECT `RegisteredPlate` AS `plate`, `Vehicle` AS `vehicle`, `Make`, `Model`, `Class`, `VIN`, `id` FROM `vehicles` WHERE `OwnerType` = 0 AND `OwnerId` = ?",
            { tostring(identifier) }
        )
    end)

    if not success then
        lib.print.error("Unable to get owned vehicles from database in framework:", BridgeConfig.FrameWork)
        return nil
    end

    local filtered = {}
    for _, vehicle in pairs(vehicles or {}) do
        local vehicleModel = tonumber(vehicle.vehicle) or joaat(vehicle.vehicle)
        local vehData = BridgeConfig.VehicleData[vehicleModel]
        if not classes or vehData and vehData.class and (type(classes) == "table" and lib.table.contains(classes, vehData.class) or vehData.class == classes) then
            if vehData then
                local newData = lib.table.deepclone(vehData)
                filtered[#filtered + 1] = lib.table.merge(newData, vehicle, false)
            end
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

    local vehicleHash = type(vehicleName) == "number" and vehicleName or joaat(vehicleName)
    local vehData = BridgeConfig.VehicleData[vehicleHash]
    local insertId = nil
    local errMsg = nil

    local s, e = pcall(function()
        local done = false
        exports["sandbox-vehicles"]:OwnedAddToCharacter(
            tonumber(stateId),
            vehicleHash,
            0,
            "automobile",
            {
                make = vehData and vehData.brand or "Unknown",
                model = vehData and vehData.name or tostring(vehicleName),
                class = vehData and vehData.class or "Unknown",
                value = 0,
            },
            function(success, vehicle)
                if success and vehicle then
                    insertId = vehicle.id or vehicle._id
                else
                    errMsg = "VEHICLE_NOT_CREATED"
                end
                done = true
            end
        )

        local timeout = GetGameTimer() + 5000
        while not done and GetGameTimer() < timeout do
            Wait(0)
        end

        if not done then
            error("VEHICLE_CREATE_TIMEOUT")
        end
    end)

    if not s or not insertId then
        return nil, errMsg or e
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
        return MySQL.update.await(
            "UPDATE `vehicles` SET `OwnerType` = 0, `OwnerId` = ? WHERE `RegisteredPlate` = ?",
            { tostring(identifier), plate }
        )
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
    CreateThread(function()
        while GetResourceState("sandbox-base") ~= "started" do
            Wait(100)
        end

        Wait(1000)

        exports["sandbox-base"]:MiddlewareAdd("Characters:Spawning", function(source)
            TriggerEvent("prp-bridge:server:playerLoad", source)
        end)

        exports["sandbox-base"]:MiddlewareAdd("Characters:Logout", function(source)
            TriggerEvent("prp-bridge:server:playerUnload", source)
        end)
    end)
end

return fw
