---@type table<string, OxTimer>
local cooldowns = {}

---@param cooldownKey string
---@param minutes number
local function startGlobalCooldown(cooldownKey, minutes)
    local cooldown = cooldowns[cooldownKey]

    if cooldown then
        lib.print.debug('Tried to start a global cooldown that already exists', cooldownKey, minutes)
        return
    end

    cooldowns[cooldownKey] = lib.timer((minutes * 60 * 1000), function()
        TriggerEvent('prp-bridge:cooldowns:finished', cooldownKey)
        cooldowns[cooldownKey] = nil
    end, true)
end
exports('startGlobalCooldown', startGlobalCooldown)

---@param identifier string
---@param cooldownKey string
---@param minutes number
---@param applyToAllCharacters boolean
local function startCooldownByIdentifier(identifier, cooldownKey, minutes, applyToAllCharacters)
    local cooldownIdentifier = ('character-%s-%s'):format(identifier, cooldownKey)

    if cooldowns[cooldownIdentifier] then
        lib.print.debug('Tried to start a player cooldown that already exists', identifier, cooldownKey,
            minutes,
            applyToAllCharacters)
        return
    end

    cooldowns[cooldownIdentifier] = lib.timer((minutes * 60 * 1000), function()
        TriggerEvent('prp-bridge:cooldowns:finished', cooldownIdentifier)
        cooldowns[cooldownIdentifier] = nil
    end, true)
end
exports('startCooldownByIdentifier', startCooldownByIdentifier)

---@param playerId number | string
---@param cooldownKey string
---@param minutes number
---@param applyToAllCharacters boolean
local function startCooldownByPlayerId(playerId, cooldownKey, minutes, applyToAllCharacters)
    local identifier = bridge.fw.getIdentifier(playerId)
    startCooldownByIdentifier(identifier, cooldownKey, minutes, applyToAllCharacters)
end
exports('startCooldownByPlayerId', startCooldownByPlayerId)

---@param cooldownKey string
---@return boolean
local function isCooldownActive(cooldownKey)
    return cooldowns[cooldownKey] ~= nil
end
exports('isCooldownActive', isCooldownActive)

---@param identifier number | string
---@param cooldownKey string
---@return boolean
local function isCooldownActiveForIdentifier(identifier, cooldownKey)
    return cooldowns[('character-%s-%s'):format(identifier, cooldownKey)] ~= nil
end
exports('isCooldownActiveForIdentifier', isCooldownActiveForIdentifier)

---@param source number | string
---@param key string
local function resetCooldown(source, key)
    local playerId = source

    if not bridge.fw.isAdmin(playerId) then
        return
    end

    local timer = cooldowns[key]

    if not timer then
        bridge.fw.notify(playerId, 'error', locale("NO_ACTIVE_COOLDOWN_KEY", key))
        return
    end

    bridge.fw.notify(playerId, 'inform', locale("SUCCESSFUL_RESET_KEY", key))
    timer:forceEnd(true)
end

RegisterNetEvent('prp-bridge:cooldowns:server:resetKey', function(key)
    resetCooldown(source, key)
end)

---@param source number | string
local function cooldownsMenu(source)
    local cooldownsMap = {}

    for cooldownKey, timer in pairs(cooldowns) do
        cooldownsMap[cooldownKey] = math.ceil(timer:getTimeLeft('m'))
    end
    
    if next(cooldownsMap) == nil then
        bridge.fw.notify(source, 'inform', locale("NO_ACTIVE_COOLDOWNS"))
        return
    end

    TriggerClientEvent('prp-bridge:cooldowns:openMenu', source, cooldownsMap)
end

if BridgeConfig.Cooldowns.AdminCommandEnabled then
    bridge.fw.registerCommand(
        BridgeConfig.Cooldowns.AdminCommandName,
        locale("ADMIN_COMMAND_COOLDOWN_MENU_HELP"),
        {
            {
                name = 'target',
                type = 'playerId',
                help = 'Target player\'s server id',
            },
        },
        BridgeConfig.Cooldowns.AdminCommandRestriction,
        cooldownsMenu
    )
end
