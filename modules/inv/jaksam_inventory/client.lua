local inv = {}

--- Source: https://documentation.jaksam-scripts.com/jaksam-inventory/functions/client

---@param item string
---@param count number
---@return boolean
function inv.hasItem(item, count)
    local total = exports['jaksam_inventory']:getTotalItemAmount(item)
    return total >= (count or 1)
end

---@param itemName string
---@param minDurabilityAmount number | nil
---@return number | nil
function inv.findItemSlot(itemName, minDurabilityAmount)
    local items = exports['jaksam_inventory']:getItemsByName(itemName)
    for _, item in pairs(items) do
        if item.name == itemName then
            if minDurabilityAmount and item.metadata and item.metadata.durability and item.metadata.durability >= minDurabilityAmount then
                return item.slot
            elseif not minDurabilityAmount then
                return item.slot
            end
        end
    end
    return nil
end

---@param itemName string
---@param metadata table|nil
---@return table | nil
function inv.getSlotWithItem(itemName, metadata)
    local items = exports['jaksam_inventory']:getItemsByName(itemName)
    for _, item in pairs(items) do
        if item.name == itemName then
            if metadata then
                local match = true
                for k, v in pairs(metadata) do
                    if not item.metadata or item.metadata[k] ~= v then
                        match = false
                        break
                    end
                end
                if match then
                    return {
                        name = item.name,
                        count = item.amount or item.count,
                        metadata = item.metadata,
                        slot = item.slot,
                    }
                end
            else
                return {
                    name = item.name,
                    count = item.amount or item.count,
                    metadata = item.metadata,
                    slot = item.slot,
                }
            end
        end
    end
    return nil
end

---@param data table<string, string>
function inv.registerDisplayMetaData(data)
    -- jaksam_inventory does not support registering display metadata
end

---@param name string
function inv.openShop(name)
    -- jaksam_inventory shops are managed server-side
    TriggerServerEvent("prp-bridge:inv:jaksam:openShop", name)
end

---@return table<{ name: string, count: number, metadata: table?, slot: number }>
function inv.getAllItems()
    local inventory = exports['jaksam_inventory']:getInventory()
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

---@param itemName string
---@return number
function inv.getItemCount(itemName)
    return exports['jaksam_inventory']:getTotalItemAmount(itemName) or 0
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return exports['jaksam_inventory']:getItemImagePath(itemName)
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent("prp-bridge:inv:forceClose", function()
        exports['jaksam_inventory']:closeInventory()
    end)
end

return inv
