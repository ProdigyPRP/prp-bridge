local inv = {}

---Source: https://tgiann.gitbook.io/tgiann/scripts/tgiann-inventory/exports/server

local playerInventories = {} ---@type table<string, table<{ name: string, count: number, metaData: table?, slot: number }>>

---@return string, any
local function generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

local tgiann = exports["tgiann-inventory"]
local items = tgiann:Items()

---@param inventoryId string | number
---@param slot number
---@param metaData? table
---@return boolean
local function updateItemMetadata(inventoryId, slot, metaData)
    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    if tonumber(inventoryId) == nil then
        local removed = exports["tgiann-inventory"]:RemoveItemFromSecondaryInventory("stash", inventoryId, item.name, item.count, item.slot, item.metadata)
        if not removed then
            lib.print.error("Unable to remove item from stash to update metadata", inventoryId, item.name, item.slot)
            return false
        end

        item.metadata = metaData
        return tgiann:AddItemToSecondaryInventory("stash", inventoryId, item.name, item.count, item.slot, item.metadata)
    end

    tgiann:UpdateItemMetadata(inventoryId, item.name, item.slot, item.metadata)
    return true
end

---@param src? number
---@return table<string, table> --Returns a table of all registered items, where the key is the item name and the value is the item data table.
function inv.getRegisteredItems(src)
    -- We have to grab the players locale since tgiann uses locale type in item label and stores their locale in the database...
    if not src then
        lib.print.error("No player provided in `getRegisteredItems` for tgiann-inventory")
        return {}
    end

    local identifier = GetPlayerIdentifierByType(src, "license") or GetPlayerIdentifierByType(src, "license2")
    if not identifier then return {} end

    local success, language = pcall(function()
        return MySQL.single.await('SELECT `lang` FROM `tgiann_core_lang` WHERE `identifier` = ? LIMIT 1', {
            identifier
        })
    end)

    if not success then
        lib.print.error("Error occured getting player tgiann language")
        return {}
    end

    if not language then
        lib.print.error("No tgiann language found for player:", identifier)
        return {}
    end

    local formattedItems = {}
    for name, itemData in pairs(items) do
        if type(itemData.label) == "table" then
            formattedItems[name] = {
                name = name,
                label = itemData.label[language] or "Unknown"
            }
        else
            formattedItems[name] = {
                name = name,
                label = itemData.label
            }
        end
    end

    return formattedItems
end

---@param inventoryId string|number
---@return table<{ name: string, count: number, metaData: table?, slot: number }>
function inv.getInventoryItems(inventoryId)
    local rawItems = {}

    if tonumber(inventoryId) ~= nil then
        rawItems = tgiann:GetPlayerItems(inventoryId)
    else
        rawItems = tgiann:GetSecondaryInventoryItems("stash", inventoryId)
    end

    if not rawItems then
        return {}
    end

    local formattedItems = {}

    for _, item in pairs(rawItems) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            count = item.count or item.amount,
            metadata = item.metadata or item.info,
            slot = item.slot,
        }
    end

    return formattedItems
end

---@param inventoryId string | number
---@return table | nil
function inv.getInventory(inventoryId)
    local raw = tgiann:GetSecondaryInventoryItems("stash", inventoryId)

    local formattedItems = {}

    for _, item in pairs(raw) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            count = item.count or item.amount,
            metadata = item.metadata or item.info,
            slot = item.slot,
        }
    end

    return {
        items = formattedItems
    }
end

---@param data InvTempStashProps
---@return string inventoryId
function inv.createTemporaryStash(data)
    local formattedItems = {}

    for _, item in pairs(data.items or {}) do
        formattedItems[#formattedItems + 1] = {
            name = item.name,
            amount = item.count,
            info = item.metaData or {}
        }
    end

    local inventoryId = ("TEMP_%s"):format(generateUUID())
    tgiann:CreateCustomStashWithItem(inventoryId, formattedItems)

    return inventoryId
end

---@param data InvStashProps
function inv.createStash(data)
    tgiann:RegisterStash(data.id, data.label, data.slots, data.maxWeight, data.owner, data.groups or nil, data.coords or nil)
end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function inv.registerSwapItemsHook(cb, options)
    return tgiann:RegisterHook("swapItems", cb, options)
end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function inv.registerCreateItemHook(cb, options)
    return tgiann:RegisterHook("createItem", cb, options or nil)
end

---@param hookId number
function inv.removeHooks(hookId)
    tgiann:RemoveHooks(hookId)
end

---@param inventoryId string
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function inv.clearInventory(inventoryId, keep)
    tgiann:ClearInventory(inventoryId, keep)
end

---@param src number | string
---@param inventoryId string
function inv.openStash(src, inventoryId)
    tgiann:ForceOpenInventory(src, "stash", inventoryId)
end

---@param src number | string
---@param inventoryId string
function inv.forceOpenStash(src, inventoryId)
    tgiann:ForceOpenInventory(src, 'stash', inventoryId)
end

---@param inventoryId number | string
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function inv.giveItem(inventoryId, itemName, count, metadata)
    if tonumber(inventoryId) == nil then
        return tgiann:AddItemToSecondaryInventory("stash", inventoryId, itemName, count, nil, metadata)
    end
    
    return tgiann:AddItem(inventoryId, itemName, count, nil, metadata, false)
end

---@param inventoryId number | string
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function inv.removeItem(inventoryId, itemName, count, metadata, slot)
    if tonumber(inventoryId) == nil then
        return tgiann:RemoveItemFromSecondaryInventory("stash", inventoryId, itemName, count, slot, metadata)
    end
    
    return tgiann:RemoveItem(inventoryId, itemName, count, slot, metadata)
end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function inv.getItemLabel(itemName)
    return tgiann:GetItemLabel(itemName)
end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function inv.getItemData(itemName)
    return tgiann:Items(itemName)
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
            amount = item.count or item.amount or 1,
            info = item.metaData or item.metadata or item.info or {}
        }
    end

    return tgiann:CustomDrop(prefix, formattedItems, coords, slots, maxWeight * 1000, instance)
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
            inv.removeItem(src, item.name, item.count, item.metaData, item.slot)

            currentLoadout[#currentLoadout + 1] = item
        end
    end

    for _, item in pairs(loadout) do
        inv.addItem(src, item.name, item.count, item.metaData)
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

    tgiann:ClearInventory(src)

    Wait(0)
    for _, item in pairs(storedItems) do
        inv.addItem(src, item.name, item.count, item.metaData)
    end

    playerInventories[identifier] = nil
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function inv.count(inventoryId, lookFor)
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
                counts[itemName] = counts[itemName] and counts[itemName] + items[i].count or items[i].count
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
    local count = inv.count(inventoryId, item)
    if type(count) == "table" then
        return (count[item:upper()] or count[item:lower()]) >= (amount or 1)
    end

    return count >= (amount or 1)
end

---@param inventoryId string|number
---@param slot number
---@return { weight: number, name: string, metadata: table?, count: number, slot: number } | nil
function inv.getSlot(inventoryId, slot)
    local items = inv.getInventoryItems(inventoryId)
    if not items or #items == 0 then
        return
    end

    local item = nil
    for i = 1, #items do
        if items[i].slot == slot then
            item = items[i]
            break
        end
    end

    if not item then
        return
    end

    return {
        weight = item.weight,
        name = item.name,
        metadata = item.info or item.metadata,
        count = item.count or item.amount,
        slot = item.slot,
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

---@param src number | string
---@param slot number
---@return table | nil
function inv.getItemMetaData(src, slot)
    local slotItem = inv.getSlot(src, slot)
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

    return updateItemMetadata(inventoryId, slot, metaData)
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
    local updated = updateItemMetadata(inventoryId, slot, newMeta)
    return updated
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

    return updateItemMetadata(inventoryId, slot, newMeta)
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
    local items = shopData.items
    for _, item in pairs(items) do
        item.amount = 50
        item.type = "item"
    end

    tgiann:RegisterShop(shopId, items)
end

---@param inventoryId string | number
---@param item string
---@param count number
---@return boolean
function inv.canCarryItem(inventoryId, item, count)
    return tgiann:CanCarryItem(inventoryId, item, count)
end

---@param type InvVehStashType
---@param plate string
---@return boolean
function inv.vehInvHasItems(type, plate)
    local inventoryItems = tgiann:GetSecondaryInventoryItems(type, plate) or {}
    return #inventoryItems > 0
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return ("https://cfx-nui-inventory_images/images/%s.webp"):format(itemName)
end

return inv
