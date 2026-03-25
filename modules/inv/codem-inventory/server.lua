local inv = {}

local playerInventories = {} ---@type table<string, table<{ name: string, count: number, metaData: table?, slot: number }>>

local codem = exports['codem-inventory']
local items = codem:GetItemList()

---@return string, any
local function generateUUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

---@param stashId string
---@param itemName string
---@param count number
---@param metadata table|nil
local function addStashItem(stashId, itemName, count, metadata)
    local stashItems = codem:GetStashItems(stashId) or {}

    local foundSlot = false
    for _, item in pairs(stashItems) do
        if item and item.name == itemName then
            item.amount = item.amount + count
            foundSlot = true
            break
        end
    end

    if not foundSlot then
        stashItems[#stashItems + 1] = {
            name = itemName,
            amount = count,
            info = metadata or {},
            slot = #stashItems + 1,
        }
    end

    codem:UpdateStash(stashId, stashItems)
end

---@param src? number
---@return table<string, table> --Returns a table of all registered items, where the key is the item name and the value is the item data table.
function inv.getRegisteredItems(src)
    return items
end

---@param inventoryId string|number
---@return table<{ name: string, count: number, metaData: table?, slot: number }>
function inv.getInventoryItems(inventoryId)
    local rawItems

    if tonumber(inventoryId) ~= nil then
        rawItems = codem:GetInventory(nil, tonumber(inventoryId))
    else
        rawItems = codem:GetStashItems(inventoryId)
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
    local rawItems

    if tonumber(inventoryId) ~= nil then
        rawItems = codem:GetInventory(nil, tonumber(inventoryId))
    else
        rawItems = codem:GetStashItems(inventoryId)
    end

    if not rawItems then return nil end

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

    return { items = formattedItems }
end

---@param data InvTempStashProps
---@return string inventoryId
function inv.createTemporaryStash(data)
    local inventoryId = ("TEMP_%s"):format(generateUUID())

    local stashItems = {}
    for _, item in pairs(data.items or {}) do
        stashItems[#stashItems + 1] = {
            name = item.name,
            amount = item.count,
            info = item.metaData or {},
            slot = #stashItems + 1,
        }
    end

    codem:UpdateStash(inventoryId, stashItems)

    return inventoryId
end

---@param data InvStashProps
function inv.createStash(data)
    local stashItems = {}
    for _, item in pairs(data.items or {}) do
        stashItems[#stashItems + 1] = {
            name = item.name,
            amount = item.count,
            info = item.metaData or {},
            slot = #stashItems + 1,
        }
    end

    if #stashItems > 0 then
        codem:UpdateStash(data.id, stashItems)
    end
end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function inv.registerSwapItemsHook(cb, options)
    lib.print.warn("codem-inventory does not support inventory hooks")
    return -1
end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function inv.registerCreateItemHook(cb, options)
    lib.print.warn("codem-inventory does not support inventory hooks")
    return -1
end

---@param hookId number
function inv.removeHooks(hookId)
    lib.print.warn("codem-inventory does not support inventory hooks")
end

---@param inventoryId string
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function inv.clearInventory(inventoryId, keep)
    if tonumber(inventoryId) ~= nil then
        if keep then
            -- codem ClearInventory does not support keep, so manually handle it
            local playerItems = inv.getInventoryItems(tonumber(inventoryId))
            local keepSet = {}
            if type(keep) == "string" then
                keepSet[keep] = true
            elseif type(keep) == "table" then
                for _, name in pairs(keep) do
                    keepSet[name] = true
                end
            end

            for _, item in pairs(playerItems) do
                if not keepSet[item.name] then
                    codem:RemoveItem(tonumber(inventoryId), item.name, item.count, item.slot)
                end
            end
        else
            codem:ClearInventory(tonumber(inventoryId))
        end
    else
        codem:UpdateStash(inventoryId, {})
    end
end

---@param src number | string
---@param inventoryId string
function inv.openStash(src, inventoryId)
    ---@diagnostic disable-next-line: param-type-mismatch
    codem:OpenInventory(src, inventoryId)
end

---@param src number | string
---@param inventoryId string
function inv.forceOpenStash(src, inventoryId)
    ---@diagnostic disable-next-line: param-type-mismatch
    codem:OpenInventory(src, inventoryId)
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function inv.giveItem(inventoryId, itemName, count, metadata)
    if tonumber(inventoryId) ~= nil then
        return codem:AddItem(tonumber(inventoryId), itemName, count, false, metadata or {})
    end

    addStashItem(inventoryId, itemName, count, metadata)
    return true
end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function inv.removeItem(inventoryId, itemName, count, metadata, slot)
    if tonumber(inventoryId) ~= nil then
        return codem:RemoveItem(tonumber(inventoryId), itemName, count, slot)
    end

    local stashItems = codem:GetStashItems(inventoryId)
    if not stashItems then return false end

    local removed = false
    local remaining = count

    for i, item in pairs(stashItems) do
        if item and item.name == itemName and remaining > 0 then
            if slot and item.slot ~= slot then
                goto continue
            end

            if item.amount <= remaining then
                remaining = remaining - item.amount
                stashItems[i] = nil
            else
                item.amount = item.amount - remaining
                remaining = 0
            end

            if remaining <= 0 then
                removed = true
                break
            end
        end
        ::continue::
    end

    codem:UpdateStash(inventoryId, stashItems)
    return removed
end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function inv.getItemLabel(itemName)
    return codem:GetItemLabel(itemName)
end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function inv.getItemData(itemName)
    if not items then return nil end

    for _, item in pairs(items) do
        if item.name == itemName then
            return item
        end
    end

    return nil
end

---@param prefix string
---@param items table<{ name: string, count: number, metaData: table? }>
---@param coords vector3
---@param slots number?
---@param maxWeight number?
---@param instance string|number|nil
---@param model number?
function inv.createCustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
    error("codem-inventory does not support custom drops")
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
            codem:RemoveItem(src, item.name, item.count, item.slot)

            currentLoadout[#currentLoadout + 1] = item
        end
    end

    for _, item in pairs(loadout) do
        codem:AddItem(src, item.name, item.count, false, item.metaData or {})
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
        codem:RemoveItem(src, item.name, item.count)
    end

    Wait(0)
    for _, item in pairs(storedItems) do
        lib.print.debug('Restoring item to source:', src, 'item:', item)
        codem:AddItem(src, item.name, item.count, false, item.metadata or {})
    end

    playerInventories[identifier] = nil
end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function inv.count(inventoryId, lookFor)
    if tonumber(inventoryId) ~= nil and type(lookFor) == "string" then
        return codem:GetItemsTotalAmount(tonumber(inventoryId), lookFor) or 0
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
        return codem:HasItem(tonumber(inventoryId), item, amount or 1)
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
        local item = codem:GetItemBySlot(tonumber(inventoryId), slot)
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
        lib.print.warn("codem-inventory does not support setting metadata on stash items directly")
        return false
    end

    local item = inv.getSlot(inventoryId, slot)
    if not item then
        return false
    end

    codem:SetItemMetadata(tonumber(inventoryId), slot, metaData)
    return true
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

    codem:CreateShop({
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
    if tonumber(inventoryId) ~= nil then
        local canAdd = codem:CanAddItem(tonumber(inventoryId), item, count)
        return canAdd
    end

    return true
end

---@param type InvVehStashType
---@param plate string
---@return boolean
function inv.vehInvHasItems(type, plate)
    local inventoryId = ("%s-%s"):format(type, plate)
    local stashItems = codem:GetStashItems(inventoryId)
    if not stashItems then
        return false
    end

    for _, item in pairs(stashItems) do
        if item then
            return true
        end
    end

    return false
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return ("https://cfx-nui-codem-inventory/html/images/%s.png"):format(itemName)
end

RegisterNetEvent("prp-bridge:inv:codem:openShop", function(name)
    local src = source
    codem:OpenShop(src, name)
end)

return inv
