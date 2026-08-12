local shops = {}
local DEFAULT_SELL_SHOP_DISTANCE <const> = 5.0

local function getShopCoordsList(coords)
    if not coords then
        return nil
    end

    if coords.x then
        return { coords }
    end

    return coords
end

local function getPrimaryShopCoords(coords)
    local coordsList = getShopCoordsList(coords)
    if not coordsList then
        return nil
    end

    return coordsList[1]
end

local function isPlayerNearShop(src, shop)
    if not shop then
        return false
    end

    local coordsList = getShopCoordsList(shop.coords)
    if not coordsList then
        return true
    end

    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    local maxDistance = shop.distance or shop.maxDistance or DEFAULT_SELL_SHOP_DISTANCE

    for i = 1, #coordsList do
        local coords = coordsList[i]
        local shopCoords = vector3(coords.x, coords.y, coords.z)
        if #(playerCoords - shopCoords) <= maxDistance then
            return true
        end
    end

    return false
end

bridge.inv.registerSwapItemsHook(function(payload)
    local src = payload.source
    local item = payload.fromSlot.name:lower()
    local inventory = payload.toInventory == src and payload.fromInventory or payload.toInventory

    if payload.toInventory == payload.fromInventory then
        return false
    end

    if payload.action ~= 'move' then
        return false
    end

    if payload.toInventory == src then
        return true
    end

    if not inventory:match('^sell_shop_[%w]+') then
        return false
    end

    local shop = shops[inventory]
    if not shop then
        return false
    end

    if not isPlayerNearShop(src, shop) then
        return false
    end

    local shopItem = shop.items[item]
    if not shopItem then
        bridge.fw.notify(src, 'error', locale('SUCH_ITEM_CANNOT_BE_SOLD'))
        return false
    end

    local amount = shopItem.price * payload.count

    local added = bridge.fw.addMoney(src, "cash", amount, shop.reason)
    if not added then
        return false
    end

    SetTimeout(0, function()
        bridge.inv.clearInventory(inventory)
    end)

    bridge.fw.notify(src, 'success', locale('SOLD_ITEM', payload.count, shopItem.label))

    return true
end, {
    inventoryFilter = {
        '^sell_shop_[%w]+'
    }
})

local function registerShop(id, payload)
    local shopId = ("sell_shop_%s"):format(id)

    if shops[shopId] then
        return
    end

    shops[shopId] = payload

    bridge.inv.createStash({
        id = shopId,
        label = payload.label,
        slots = 1,
        maxWeight = 9000000,
        coords = getPrimaryShopCoords(payload.coords),
    })

    bridge.inv.clearInventory(shopId)
end
exports("RegisterSellShop", registerShop)

local function openShop(src, id)
    local shopId = ("sell_shop_%s"):format(id)

    local shop = shops[shopId]

    if not shop then
        lib.print.error(("No shop found with id %s"):format(shopId))
        return
    end

    if not isPlayerNearShop(src, shop) then
        return
    end

    bridge.inv.forceOpenStash(src, shopId)
end
exports("OpenSellShop", openShop)
