local inv = {}

local playerInventories = {} ---@type table<string, table<{ name: string, count: number, metaData: table?, slot: number }>>

local QBCore = exports['qb-core']:GetCoreObject()
local qb_inventory = exports['qb-inventory']

---@return string, any
local function generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

---@param src? number
---@return table<string, table> --Returns a table of all registered items, where the key is the item name and the value is the item data table.
function inv.getRegisteredItems(src)
    return QBCore.Shared.Items
end

---@param inventoryId string|number
---@return table<{ name: string, count: number, metaData: table?, slot: number }>
function inv.getInventoryItems(inventoryId)
    local rawItems

    if tonumber(inventoryId) ~= nil then
        local Player = QBCore.Functions.GetPlayer(tonumber(inventoryId))
        if not Player then return {} end
        rawItems = Player.PlayerData.items
    else
        local inventory = qb_inventory:GetInventory(inventoryId)
        if not inventory then return {} end
        rawItems = inventory.items
    end

    if not rawItems then
        return {}
    end

    local formattedItems = {}

    for _, item in pairs(rawItems) do
        if item then
            formattedItems[#formattedItems + 1] = {
                name = item.name,
                count = item.amount,
                metadata = item.info,
                slot = item.slot,
            }
        end
    end

    return formattedItems
end

---@param inventoryId string | number
---@return table | nil
function inv.getInventory(inventoryId)
    if tonumber(inventoryId) ~= nil then
        local Player = QBCore.Functions.GetPlayer(tonumber(inventoryId))
        if not Player then return nil end

        local formattedItems = {}
        for _, item in pairs(Player.PlayerData.items) do
            if item then
                formattedItems[#formattedItems + 1] = {
                    name = item.name,
                    count = item.amount,
                    metadata = item.info,
                    slot = item.slot,
                }
            end
        end

        return { items = formattedItems }
    end

    local inventory = qb_inventory:GetInventory(inventoryId)
    if not inventory then return nil end

    local formattedItems = {}
    for _, item in pairs(inventory.items or {}) do
        if item then
            formattedItems[#formattedItems + 1] = {
                name = item.name,
                count = item.amount,
                metadata = item.info,
                slot = item.slot,
            }
        end
    end

    return { items = formattedItems }
end

---@param data InvTempStashProps
---@return string inventoryId
function inv.createTemporaryStash(data)
    local inventoryId = ("TEMP_%s"):format(generateUUID())

    qb_inventory:CreateInventory(inventoryId, {
        label = data.label,
        maxweight = data.maxWeight * 1000,
        slots = data.slots or 100,
    })

    for _, item in pairs(data.items or {}) do
        qb_inventory:AddItem(inventoryId, item.name, item.count, false, item.metaData or {})
    end

    return inventoryId
end

---@param data InvStashProps
function inv.createStash(data)
    qb_inventory:CreateInventory(data.id, {
        label = data.label,
        maxweight = data.maxWeight * 1000,
        slots = data.slots,
    })

    for _, item in pairs(data.items or {}) do
        qb_inventory:AddItem(data.id, item.name, item.count, false, item.metaData or {})
    end
end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function inv.registerSwapItemsHook(cb, options)
    lib.print.warn("qb-inventory does not support inventory hooks")
    return -1
end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function inv.registerCreateItemHook(cb, options)
    lib.print.warn("qb-inventory does not support inventory hooks")
    return -1
end

---@param hookId number
function inv.removeHooks(hookId)
    lib.print.warn("qb-inventory does not support inventory hooks")
end

---@param inventoryId string
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function inv.clearInventory(inventoryId, keep)
    if tonumber(inventoryId) ~= nil then
        qb_inventory:ClearInventory(tonumber(inventoryId), keep)
    else
        qb_inventory:ClearStash(inventoryId)
    end
end

---@param src number | string
---@param inventoryId string
function inv.openStash(src, inventoryId)
    ---@diagnostic disable-next-line: param-type-mismatch
    qb_inventory:OpenInventory(src, inventoryId)
end

---@param src number | string
---@param inventoryId string
function inv.forceOpenStash(src, inventoryId)
    ---@diagnostic disable-next-line: param-type-mismatch
    qb_inventory:OpenInventory(src, inventoryId)
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function inv.giveItem(inventoryId, itemName, count, metadata)
    return qb_inventory:AddItem(inventoryId, itemName, count, false, metadata or {})
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function inv.removeItem(inventoryId, itemName, count, metadata, slot)
    return qb_inventory:RemoveItem(inventoryId, itemName, count, slot)
end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function inv.getItemLabel(itemName)
    local item = QBCore.Shared.Items[itemName]
    if not item then
        return nil
    end

    return item.label
end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function inv.getItemData(itemName)
    return QBCore.Shared.Items[itemName]
end

---@param prefix string
---@param items table<{ name: string, count: number, metaData: table? }>
---@param coords vector3
---@param slots number?
---@param maxWeight number?
---@param instance string|number|nil
---@param model number?
function inv.createCustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
    error("qb-inventory does not support custom drops")
end

---@param src number | string
---@param loadout table<{ name: string, count: number, metaData: table? }>
---@param excludedItems table<string, boolean>
function inv.giveLoadoutItems(src, loadout, excludedItems)
    local identifier = bridge.fw.getIdentifier(src)
    if not identifier then return end

    local playerItems = inv.getInventoryItems(src)

    local currentLoadout = {}

    for _, item in pairs(playerItems) do
        if not excludedItems[item.name] then
            qb_inventory:RemoveItem(src, item.name, item.count, item.slot)

            currentLoadout[#currentLoadout + 1] = item
        end
    end

    for _, item in pairs(loadout) do
        qb_inventory:AddItem(src, item.name, item.count, false, item.metaData or {})
    end

    playerInventories[identifier] = currentLoadout
end

---@param src number | string
---@param loadout table<{ name: string, count: number, metaData: table? }>
function inv.returnItems(src, loadout)
    local identifier = bridge.fw.getIdentifier(src)
    if not identifier then return lib.print.debug('No identifier for source:', src) end

    local storedItems = playerInventories[identifier]
    if not storedItems then return lib.print.debug('No stored items for identifier:', identifier) end

    for _, item in pairs(loadout) do
        lib.print.debug('Removing loadout item from source:', src, 'item:', item)
        qb_inventory:RemoveItem(src, item.name, item.count)
    end

    Wait(0)
    for _, item in pairs(storedItems) do
        lib.print.debug('Restoring item to source:', src, 'item:', item)
        qb_inventory:AddItem(src, item.name, item.count, false, item.metadata or {})
    end

    playerInventories[identifier] = nil
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function inv.count(inventoryId, lookFor)
    if tonumber(inventoryId) ~= nil and type(lookFor) == "string" then
        return qb_inventory:GetItemCount(tonumber(inventoryId), lookFor) or 0
    end

    local items = inv.getInventoryItems(inventoryId)
    if not items or #items == 0 then
        return 0
    end

    if type(lookFor) == "string" then
        local count = 0
        for i = 1, #items do
            if items[i].name:lower() == lookFor:lower() then
                count = count + items[i].count
            end
        end
        return count
    elseif type(lookFor) == "table" then
        local mappedLookFor = {}
        for i = 1, #lookFor do
            mappedLookFor[lookFor[i]:lower()] = true
        end

        local counts = {}
        for i = 1, #items do
            local itemName = items[i].name:lower()
            if mappedLookFor[itemName] then
                counts[itemName] = (counts[itemName] or 0) + items[i].count
            end
        end
        return counts
    end

    return 0
end

---@param inventoryId string|number
---@param item string
---@param amount number
---@return boolean
function inv.hasItem(inventoryId, item, amount)
    if tonumber(inventoryId) ~= nil then
        return qb_inventory:HasItem(tonumber(inventoryId), item, amount or 1)
    end

    local count = inv.count(inventoryId, item)
    if type(count) == "table" then
        return (count[item:upper()] or count[item:lower()] or 0) >= (amount or 1)
    end

    return count >= (amount or 1)
end

---@param inventoryId string|number
---@param slot number
---@return { weight: number, name: string, metadata: table?, count: number, slot: number } | nil
function inv.getSlot(inventoryId, slot)
    if tonumber(inventoryId) ~= nil then
        local item = qb_inventory:GetItemBySlot(tonumber(inventoryId), slot)
        if not item then return nil end

        return {
            name = item.name,
            count = item.amount,
            metadata = item.info,
            slot = item.slot,
            weight = item.weight,
        }
    end

    local items = inv.getInventoryItems(inventoryId)
    for _, item in pairs(items) do
        if item.slot == slot then
            return {
                name = item.name,
                count = item.count,
                metadata = item.metadata,
                slot = item.slot,
                weight = item.weight,
            }
        end
    end

    return nil
end

---@param inventoryId string|number
---@param slot number
---@return number|nil
function inv.getItemDurability(inventoryId, slot)
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return nil
    end

    if not item.metadata or not item.metadata.quality then
        return nil
    end

    return item.metadata.quality
end

---@param inventoryId string|number
---@param slot number
---@return table | nil
function inv.getItemMetaData(inventoryId, slot)
    local slotItem = inv.getSlot(inventoryId, slot)
    if not slotItem then return nil end
    return slotItem.metadata
end

---@param inventoryId string|number
---@param slot number
---@param metaData table
---@return boolean
function inv.setItemMetaData(inventoryId, slot, metaData)
    if tonumber(inventoryId) == nil then
        lib.print.warn("qb-inventory does not support setting metadata on stash items directly")
        return false
    end

    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    return qb_inventory:SetItemData(tonumber(inventoryId), item.name, 'info', metaData, slot) or false
end

---@param inventoryId string|number
---@param slot number
---@param key string
---@param value any
---@return boolean
function inv.setItemMetaDataKey(inventoryId, slot, key, value)
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    local newMeta = lib.table.deepclone(item.metadata or {})
    newMeta[key] = value
    return inv.setItemMetaData(inventoryId, slot, newMeta)
end

---@param inventoryId string|number
---@param slot number
---@param metaData table<string, any>
---@return boolean
function inv.setItemMetaDatasByKey(inventoryId, slot, metaData)
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    local newMeta = lib.table.deepclone(item.metadata or {})
    for k, v in pairs(metaData) do
        newMeta[k] = v
    end

    return inv.setItemMetaData(inventoryId, slot, newMeta)
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return InvSearchItem[] | nil
function inv.searchInventory(inventoryId, lookFor)
    local found = {}

    local inventoryItems = inv.getInventoryItems(inventoryId)
    if not inventoryItems or #inventoryItems == 0 then
        return
    end

    for i = 1, #inventoryItems do
        local item = inventoryItems[i]
        if type(lookFor) == "table" then
            if lib.table.contains(lookFor, item.name) then
                found[#found + 1] = item
            end
        elseif type(lookFor) == "string" then
            if item.name == lookFor then
                found[#found + 1] = item
            end
        end
    end

    return found
end

---@param shopId string
---@param shopData InvShopData
function inv.registerShop(shopId, shopData)
    local shopItems = {}
    for _, item in pairs(shopData.items) do
        shopItems[#shopItems + 1] = {
            name = item.name,
            price = item.price,
            amount = 50,
            info = {},
        }
    end

    qb_inventory:CreateShop({
        name = shopId,
        label = shopData.name,
        items = shopItems,
    })
end

---@param inventoryId string | number
---@param item string
---@param count number
---@param metaData table?
---@return boolean
function inv.canCarryItem(inventoryId, item, count, metaData)
    local canAdd = qb_inventory:CanAddItem(inventoryId, item, count)
    return canAdd
end

---@param type InvVehStashType
---@param plate string
---@return boolean
function inv.vehInvHasItems(type, plate)
    local inventoryId = ("%s-%s"):format(type, plate)
    local inventory = qb_inventory:GetInventory(inventoryId)
    if not inventory or not inventory.items then
        return false
    end

    for _, item in pairs(inventory.items) do
        if item then
            return true
        end
    end

    return false
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return ("https://cfx-nui-qb-inventory/html/images/%s.png"):format(itemName)
end

RegisterNetEvent("prp-bridge:inv:qb:openShop", function(name)
    local src = source
    qb_inventory:OpenShop(src, name)
end)

return inv
