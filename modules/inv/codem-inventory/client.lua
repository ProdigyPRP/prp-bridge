local inv = {}

---@param item string
---@param count number
---@return boolean
function inv.hasItem(item, count)
    return exports['codem-inventory']:HasItem(item, count or 1)
end

---@param itemName string
---@param minDurabilityAmount number | nil
---@return number | nil
function inv.findItemSlot(itemName, minDurabilityAmount)
    local items = exports['codem-inventory']:getUserInventory()
    if not items then return nil end

    for _, item in pairs(items) do
        if item and item.name == itemName then
            if minDurabilityAmount and item.info and item.info.quality and item.info.quality >= minDurabilityAmount then
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
    local items = exports['codem-inventory']:getUserInventory()
    if not items then return nil end

    for _, item in pairs(items) do
        if item and item.name == itemName then
            if metadata then
                local match = true
                for k, v in pairs(metadata) do
                    if not item.info or item.info[k] ~= v then
                        match = false
                        break
                    end
                end
                if match then
                    return {
                        name = item.name,
                        count = item.amount,
                        metadata = item.info,
                        slot = item.slot,
                    }
                end
            else
                return {
                    name = item.name,
                    count = item.amount,
                    metadata = item.info,
                    slot = item.slot,
                }
            end
        end
    end
    return nil
end

---@param data table<string, string>
function inv.registerDisplayMetaData(data)
    -- codem-inventory does not support registering display metadata
end

---@param name string
function inv.openShop(name)
    TriggerServerEvent("prp-bridge:inv:codem:openShop", name)
end

---@return table<{ name: string, count: number, metadata: table?, slot: number }>
function inv.getAllItems()
    local items = exports['codem-inventory']:getUserInventory()
    if not items then return {} end

    local formattedItems = {}

    for _, item in pairs(items) do
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

---@param itemName string
---@return number
function inv.getItemCount(itemName)
    local items = exports['codem-inventory']:getUserInventory()
    if not items then return 0 end

    local count = 0
    for _, item in pairs(items) do
        if item and item.name == itemName then
            count = count + item.amount
        end
    end
    return count
end

---@param itemName string
---@return string
function inv.getItemImageUrl(itemName)
    return ("https://cfx-nui-codem-inventory/html/images/%s.png"):format(itemName)
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent("prp-bridge:inv:forceClose", function()
        TriggerEvent("codem-inventory:client:closeInv")
    end)
end

return inv
