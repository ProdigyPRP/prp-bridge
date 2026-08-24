local phone = {}

---@param value any
---@return any
local function awaitNpwdExport(value)
    if value == nil then
        return nil
    end

    if type(value) == 'table' and value.phoneNumber ~= nil then
        return value
    end

    local ok, awaited = pcall(Citizen.Await, value)
    if ok then
        return awaited
    end

    return value
end

---@param args { source?: number | string, identifier?: string, phoneNumber?: string }
---@return table|nil
local function getNpwdPlayerData(args)
    local ok, result = pcall(function()
        return awaitNpwdExport(exports.npwd:getPlayerData(args))
    end)

    if not ok then
        if BridgeConfig.Debug then
            lib.print.debug('[npwd] getPlayerData failed:', result)
        end
        return nil
    end

    if type(result) ~= 'table' then
        return nil
    end

    return result
end

---@param src number | string
---@return string|nil
local function getPhoneNumber(src)
    src = tonumber(src)
    if not src then
        return nil
    end

    local playerData = getNpwdPlayerData({ source = src })
    if playerData and playerData.phoneNumber then
        return tostring(playerData.phoneNumber)
    end

    local identifier = bridge.fw.getIdentifier(src)
    if identifier then
        playerData = getNpwdPlayerData({ identifier = identifier })
        if playerData and playerData.phoneNumber then
            return tostring(playerData.phoneNumber)
        end
    end

    if BridgeConfig.Debug then
        lib.print.debug('[npwd] Failed to resolve phone number for source', src, 'identifier', identifier)
    end

    return nil
end

---@param payload table
---@return boolean
local function emitMessage(payload)
    local ok, err = pcall(function()
        awaitNpwdExport(exports.npwd:emitMessage(payload))
    end)

    if not ok and BridgeConfig.Debug then
        lib.print.debug('[npwd] emitMessage failed:', err, payload)
    end

    return ok
end

---@param src number
---@param from number | string
---@param message string
function phone.sendMessage(src, from, message)
    local phoneNumber = getPhoneNumber(src)
    if not phoneNumber then
        return false
    end

    return emitMessage({
        senderNumber = tostring(from),
        targetNumber = phoneNumber,
        message = message,
    })
end

---@param src number | string
---@param from number | string
---@param coords vector3
function phone.sendCoords(src, from, coords)
    local phoneNumber = getPhoneNumber(src)
    if not phoneNumber then
        return false
    end

    return emitMessage({
        senderNumber = tostring(from),
        targetNumber = phoneNumber,
        message = '',
        embed = {
            type = 'location',
            coords = { coords.x, coords.y, coords.z },
            phoneNumber = tostring(from),
        },
    })
end

---@param src number
---@param title string
---@param content? string
function phone.sendNotification(src, title, content)
    TriggerClientEvent('prp-bridge:phone:sendNotification', src, title, content)
end

return phone
