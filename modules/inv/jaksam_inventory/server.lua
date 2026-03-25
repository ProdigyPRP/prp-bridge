local inv = {}

--- Source: https://documentation.jaksam-scripts.com/jaksam-inventory/functions/server

local playerInventories = {} ---@type table<string, table<{ name: string, count: number, metaData: table?, slot: number }>>

local jaksam = exports['jaksam_inventory']
local items = jaksam:getStaticItemsList()

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
    return items
end

---@param inventoryId string|number
---@return table<{ name: string, count: number, metaData: table?, slot: number }>
function inv.getInventoryItems(inventoryId)
    local inventory = jaksam:getInventory(inventoryId)
    if not inventory or not inventory.items then
        return {}
    end

    local formattedItems = {}

    for _, item in pairs(inventory.items) do
        if item then
            formattedItems[#formattedItems + 1] = {
                name = item.name,
                count = item.amount or item.count,
                metadata = item.metadata,
                slot = item.slot,
            }
        end
    end

    return formattedItems
end

---@param inventoryId string | number
---@return table | nil
function inv.getInventory(inventoryId)
    local inventory = jaksam:getInventory(inventoryId)
    if not inventory or not inventory.items then
        return nil
    end

    local formattedItems = {}

    for _, item in pairs(inventory.items) do
        if item then
            formattedItems[#formattedItems + 1] = {
                name = item.name,
                count = item.amount or item.count,
                metadata = item.metadata,
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

    local formattedItems = {}
    for _, item in pairs(data.items or {}) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            amount = item.count,
            metadata = item.metaData or {},
        }
    end

    jaksam:createInventory(inventoryId, data.label, {
        maxSlots = data.slots or 100,
        maxWeight = data.maxWeight * 1000,
    }, formattedItems)

    return inventoryId
end

---@param data InvStashProps
function inv.createStash(data)
    jaksam:registerStash({
        id = data.id,
        label = data.label,
        maxSlots = data.slots,
        maxWeight = data.maxWeight * 1000,
        owner = data.owner,
        groups = data.groups or nil,
    })

    for _, item in pairs(data.items or {}) do
        jaksam:addItem(data.id, item.name, item.count, item.metaData or {})
    end
end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function inv.registerSwapItemsHook(cb, options)
    lib.print.warn("jaksam_inventory does not support inventory hooks")
    return -1
end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function inv.registerCreateItemHook(cb, options)
    lib.print.warn("jaksam_inventory does not support inventory hooks")
    return -1
end

---@param hookId number
function inv.removeHooks(hookId)
    lib.print.warn("jaksam_inventory does not support inventory hooks")
end

---@param inventoryId string
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function inv.clearInventory(inventoryId, keep)
    jaksam:clearInventory(inventoryId, keep)
end

---@param src number | string
---@param inventoryId string
function inv.openStash(src, inventoryId)
    jaksam:forceOpenInventory(src, inventoryId)
end

---@param src number | string
---@param inventoryId string
function inv.forceOpenStash(src, inventoryId)
    jaksam:forceOpenInventory(src, inventoryId)
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function inv.giveItem(inventoryId, itemName, count, metadata)
    return jaksam:addItem(inventoryId, itemName, count, metadata or {})
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function inv.removeItem(inventoryId, itemName, count, metadata, slot)
    return jaksam:removeItem(inventoryId, itemName, count, metadata, slot)
end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function inv.getItemLabel(itemName)
    return jaksam:getItemLabel(itemName)
end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function inv.getItemData(itemName)
    local item = items[itemName]
    return item
end

---@param prefix string
---@param items table<{ name: string, count: number, metaData: table? }>
---@param coords vector3
---@param slots number?
---@param maxWeight number?
---@param instance string|number|nil
---@param model number?
function inv.createCustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
    local formattedItems = {}

    for _, item in pairs(items) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            amount = item.count,
            metadata = item.metaData or {},
        }
    end

    local dropId = ("%s_%s"):format(prefix, generateUUID())
    jaksam:createInventory(dropId, prefix, {
        maxSlots = slots or 50,
        maxWeight = (maxWeight or 100) * 1000,
    }, formattedItems)

    return dropId
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
            jaksam:removeItem(src, item.name, item.count, nil, item.slot)

            currentLoadout[#currentLoadout + 1] = item
        end
    end

    for _, item in pairs(loadout) do
        jaksam:addItem(src, item.name, item.count, item.metaData or {})
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
        jaksam:removeItem(src, item.name, item.count)
    end

    Wait(0)
    for _, item in pairs(storedItems) do
        lib.print.debug('Restoring item to source:', src, 'item:', item)
        jaksam:addItem(src, item.name, item.count, item.metadata or {})
    end

    playerInventories[identifier] = nil
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function inv.count(inventoryId, lookFor)
    if type(lookFor) == "string" then
        return jaksam:getTotalItemAmount(inventoryId, lookFor) or 0
    end

    local items = inv.getInventoryItems(inventoryId)
    if not items or #items == 0 then
        return 0
    end

    if type(lookFor) == "table" then
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
    return jaksam:hasItem(inventoryId, item, amount or 1)
end

---@param inventoryId string|number
---@param slot number
---@return { weight: number, name: string, metadata: table?, count: number, slot: number } | nil
function inv.getSlot(inventoryId, slot)
    local item = jaksam:getItemFromSlot(inventoryId, slot)
    if not item then
        return nil
    end

    return {
        name = item.name,
        count = item.amount or item.count,
        metadata = item.metadata,
        slot = item.slot or slot,
        weight = item.weight,
    }
end

---@param inventoryId string|number
---@param slot number
---@return number|nil
function inv.getItemDurability(inventoryId, slot)
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return nil
    end

    if not item.metadata or not item.metadata.durability then
        return nil
    end

    return item.metadata.durability
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
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    return jaksam:setItemMetadataInSlot(inventoryId, slot, metaData)
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
    return jaksam:setItemMetadataInSlot(inventoryId, slot, newMeta)
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

    return jaksam:setItemMetadataInSlot(inventoryId, slot, newMeta)
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return InvSearchItem[] | nil
function inv.searchInventory(inventoryId, lookFor)
    local found = {}

    if type(lookFor) == "string" then
        local searchItems = jaksam:getItemsByName(inventoryId, lookFor)
        if searchItems then
            for _, item in pairs(searchItems) do
                found[#found + 1] = {
                    name = item.name,
                    count = item.amount or item.count,
                    metadata = item.metadata,
                    slot = item.slot,
                }
            end
        end
        return #found > 0 and found or nil
    end

    if type(lookFor) == "table" then
        for _, itemName in pairs(lookFor) do
            local searchItems = jaksam:getItemsByName(inventoryId, itemName)
            if searchItems then
                for _, item in pairs(searchItems) do
                    found[#found + 1] = {
                        name = item.name,
                        count = item.amount or item.count,
                        metadata = item.metadata,
                        slot = item.slot,
                    }
                end
            end
        end
        return #found > 0 and found or nil
    end

    return nil
end

---@param shopId string
---@param shopData InvShopData
function inv.registerShop(shopId, shopData)
    lib.print.warn("jaksam_inventory does not have a native shop system, creating as stash instead")
    local shopItems = {}
    for _, item in pairs(shopData.items) do
        shopItems[#shopItems + 1] = {
            name = item.name,
            amount = 50,
            metadata = {},
        }
    end

    jaksam:createInventory(("shop_%s"):format(shopId), shopData.name, {
        maxSlots = #shopData.items,
        maxWeight = 999999,
    }, shopItems)
end

---@param inventoryId string | number
---@param item string
---@param count number
---@param metaData table?
---@return boolean
function inv.canCarryItem(inventoryId, item, count, metaData)
    return jaksam:canCarryItem(inventoryId, item, count)
end

---@param type InvVehStashType
---@param plate string
---@return boolean
function inv.vehInvHasItems(type, plate)
    local inventoryId = jaksam:getInventoryIdFromPlate(plate, type)
    if not inventoryId then
        return false
    end

    local inventory = jaksam:getInventory(inventoryId)
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
    return exports['jaksam_inventory']:getItemImagePath(itemName)
end

RegisterNetEvent("prp-bridge:inv:jaksam:openShop", function(name)
    local src = source
    jaksam:forceOpenInventory(src, ("shop_%s"):format(name))
end)

return inv
