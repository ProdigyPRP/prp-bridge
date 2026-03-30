local inv = {}

local playerInventories = {} ---@type table<string, table<{ name: string, count: number, metaData: table?, slot: number }>>

local ox_inventory = exports.ox_inventory
local items = ox_inventory:Items()

---@param src? number
---@return table<string, table> --Returns a table of all registered items, where the key is the item name and the value is the item data table.
function inv.getRegisteredItems(src)
    return items
end

---@param inventoryId string|number
---@return table<{ name: string, count: number, metaData: table?, slot: number }>
function inv.getInventoryItems(inventoryId)
    local rawItems = ox_inventory:GetInventoryItems(inventoryId)
    if not rawItems then
        return {}
    end

    local formattedItems = {}

    for _, item in pairs(rawItems) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            count = item.count,
            metadata = item.metadata,
            slot = item.slot,
        }
    end

    return formattedItems
end

---@param inventoryId string | number
---@return table | nil
function inv.getInventory(inventoryId)
    return ox_inventory:GetInventory(inventoryId)
end

---@param data InvTempStashProps
---@return string inventoryId
function inv.createTemporaryStash(data)
    local formattedItems = {}

    for _, item in pairs(data.items or {}) do
        formattedItems[#formattedItems + 1] = { item.name, item.count, item.metaData or {} }
    end

    return ox_inventory:CreateTemporaryStash({
        label = data.label,
        slots = data.slots or 100,
        maxWeight = data.maxWeight * 1000,
        items = formattedItems,
    })
end

---@param data InvStashProps
function inv.createStash(data)
    ox_inventory:RegisterStash(data.id, data.label, data.slots, data.maxWeight, data.owner, data.groups or nil,
        data.coords or nil)

    for _, item in pairs(data.items or {}) do
        inv.giveItem(data.id, item.name, item.count, item.metaData or {})
    end
end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function inv.registerSwapItemsHook(cb, options)
    return ox_inventory:registerHook("swapItems", cb, options or nil)
end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function inv.registerCreateItemHook(cb, options)
    return ox_inventory:registerHook("createItem", cb, options or nil)
end

---@param hookId number
function inv.removeHooks(hookId)
    ox_inventory:removeHooks(hookId)
end

---@param inventoryId string
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function inv.clearInventory(inventoryId, keep)
    ox_inventory:ClearInventory(inventoryId, keep)
end

---@param src number | string
---@param inventoryId string
function inv.openStash(src, inventoryId)
    ---@diagnostic disable-next-line: param-type-mismatch
    TriggerClientEvent("ox_inventory:openInventory", src, "stash", inventoryId)
end

---@param src number | string
---@param inventoryId string
function inv.forceOpenStash(src, inventoryId)
    ox_inventory:forceOpenInventory(src, 'stash', inventoryId)
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function inv.giveItem(inventoryId, itemName, count, metadata)
    return ox_inventory:AddItem(inventoryId, itemName, count, metadata or {})
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function inv.removeItem(inventoryId, itemName, count, metadata, slot)
    return ox_inventory:RemoveItem(inventoryId, itemName, count, metadata, slot)
end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function inv.getItemLabel(itemName)
    local item = items[itemName]
    if not item then
        return nil
    end

    return item.label
end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function inv.getItemData(itemName)
    return items[itemName]
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
        formattedItems[#formattedItems + 1] = { item.name, item.count, item.metaData or {} }
    end

    return ox_inventory:CustomDrop(prefix, formattedItems, coords, slots, maxWeight * 1000, instance, model)
end

---@param src number | string
---@param loadout table<{ name: string, count: number, metaData: table? }>
---@param excludedItems table<string, boolean>
function inv.giveLoadoutItems(src, loadout, excludedItems)
    local identifier = bridge.fw.getIdentifier(src)
    if not identifier then return end

    local playerItems = inv.getInventoryItems(src)
    --lib.print.debug('Current inventory items for source:', src, 'identifier:', identifier, 'items:', playerItems)

    local currentLoadout = {}

    for _, item in pairs(playerItems) do
        if not excludedItems[item.name] then
            ox_inventory:RemoveItem(src, item.name, item.count, item.metaData, item.slot)

            currentLoadout[#currentLoadout + 1] = item
        end
    end

    for _, item in pairs(loadout) do
        ox_inventory:AddItem(src, item.name, item.count, item.metaData)
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
        ox_inventory:RemoveItem(src, item.name, item.count, nil, nil, nil, true)
    end

    Wait(0)
    for _, item in pairs(storedItems) do
        lib.print.debug('Restoring item to source:', src, 'item:', item)
        ox_inventory:AddItem(src, item.name, item.count, item.metaData or {})
    end

    playerInventories[identifier] = nil
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function inv.count(inventoryId, lookFor)
    local count = ox_inventory:Search(inventoryId, 'count', lookFor)
    return count
end

---@param inventoryId string|number
---@param item string
---@param amount number
---@return boolean
function inv.hasItem(inventoryId, item, amount)
    local count = inv.count(inventoryId, item)
    if type(count) == "table" then
        return (count[item:upper()] or count[item:lower()]) >= (amount or 1)
    end

    return count >= (amount or 1)
end

---@param src number
---@param slot number
---@return { weight: number, name: string, metadata: table?, count: number, slot: number } | nil
function inv.getSlot(src, slot)
    return ox_inventory:GetSlot(src, slot)
end

---@param inventoryId string|number
---@param slot number
---@return number|nil
function inv.getItemDurability(inventoryId, slot)
    local item = ox_inventory:GetSlot(inventoryId, slot)
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
    local slotItem = ox_inventory:GetSlot(inventoryId, slot)
    if not slotItem then return nil end
    return slotItem.metadata
end

---@param inventoryId string|number
---@param slot number
---@param metaData table
---@return boolean
function inv.setItemMetaData(inventoryId, slot, metaData)
    local item = ox_inventory:GetSlot(inventoryId, slot)
    if not item then
        return false
    end

    ox_inventory:SetMetadata(inventoryId, slot, metaData)
    return true
end

---@param inventoryId string|number
---@param slot number
---@param key string
---@param value any
---@return boolean
function inv.setItemMetaDataKey(inventoryId, slot, key, value)
    local item = ox_inventory:GetSlot(inventoryId, slot)
    if not item then
        return false
    end

    local newMeta = lib.table.deepclone(item.metadata or {})
    newMeta[key] = value
    ox_inventory:SetMetadata(inventoryId, slot, newMeta)
    return true
end

---@param inventoryId string|number
---@param slot number
---@param metaData table<string, any>
---@return boolean
function inv.setItemMetaDatasByKey(inventoryId, slot, metaData)
    local item = ox_inventory:GetSlot(inventoryId, slot)
    if not item then
        return false
    end

    local newMeta = lib.table.deepclone(item.metadata or {})
    for k, v in pairs(metaData) do
        newMeta[k] = v
    end

    ox_inventory:SetMetadata(inventoryId, slot, newMeta)
    return true
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return InvSearchItem[] | nil
function inv.searchInventory(inventoryId, lookFor)
    return ox_inventory:Search(inventoryId, "slots", lookFor)
end

---@param shopId string
---@param shopData InvShopData
function inv.registerShop(shopId, shopData)
    ox_inventory:RegisterShop(shopId, {
        name = shopData.name,
        inventory = shopData.items,
        groups = shopData.groups or nil,
    })
end

---@param inventoryId string | number
---@param item string
---@param count number
---@param metaData table?
---@return boolean
function inv.canCarryItem(inventoryId, item, count, metaData)
    return ox_inventory:CanCarryItem(inventoryId, item, count, metaData)
end

---@param vehType InvVehStashType
---@param plate string
---@return boolean
function inv.vehInvHasItems(vehType, plate)
    -- support ox inv plate trim convar
    local trimPlate = GetConvarInt('inventory:trimplate', 1) == 1
    if trimPlate then
        plate = string.strtrim(plate)
    end

    local inventoryId = ("%s%s"):format(vehType, plate)
    local inventory = ox_inventory:GetInventory(inventoryId)
    if not inventory or type(inventory) ~= "table" then
        return false
    end

    local inventoryItems = ox_inventory:GetInventoryItems(inventoryId) or {}
    return #inventoryItems > 0
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return ("https://cfx-nui-ox_inventory/web/images/%s.png"):format(itemName)
end

return inv
