---Generates a random item based on rarity weights.
---@return string The selected rarity.
local function selectRarity()
    local totalWeight = 0
    for _, weight in pairs(BridgeConfig.LootRarityWeights) do
        totalWeight = totalWeight + weight
    end

    local randomNumber = math.random(1, totalWeight)
    local cumulativeWeight = 0

    for rarity, weight in pairs(BridgeConfig.LootRarityWeights) do
        cumulativeWeight = cumulativeWeight + weight
        if randomNumber <= cumulativeWeight then
            return rarity
        end
    end

    return "COMMON"
end

---Retrieves a random item from a given rarity list.
---@param items table A list of item tables for a specific rarity.
---@return table|nil A randomly selected item table.
local function getRandomItemFromList(items)
    if items and #items > 0 then
        return items[math.random(1, #items)]
    end

    return nil
end

---Generates loot from a specified pool.
---@param pool table  The name of the loot pool, or a direct loot pool table.
---@param itemCount number The total number of items to generate. Defaults to 1.
---@param guaranteedRarities table|nil An optional table specifying guaranteed rarity drops.
---                                     Format: { ["RARITY_NAME"] = count, ... }
---@return table A table containing the generated loot items.
local function GenerateLoot(pool, itemCount, guaranteedRarities)
    local loot = {}
    if not itemCount then
        itemCount = 1
    end

    if not pool then
        return loot
    end

    if guaranteedRarities and type(guaranteedRarities) == "table" then
        for rarity, count in pairs(guaranteedRarities) do
            local itemsOfRarity = pool[rarity]
            if itemsOfRarity and #itemsOfRarity > 0 then
                for i = 1, count do
                    local chosenItem = getRandomItemFromList(itemsOfRarity)

                    if chosenItem then
                        local itemAmt = math.random(
                            chosenItem.min or 1,
                            chosenItem.max or 1
                        )

                        table.insert(
                            loot,
                            {
                                name = chosenItem.name,
                                count = itemAmt,
                                metadata = chosenItem.metadata or {},
                                rarity = rarity,
                            }
                        )

                        itemCount = itemCount - 1
                    end
                end
            else
                lib.print.warn(("Guaranteed rarity '%s' specified, but no items found in pool '%s' for this rarity."):format(rarity, 'custom_pool'))
            end
        end
    end

    for i = 1, math.max(0, itemCount) do
        local selectedRarity = selectRarity()
        local itemsOfSelectedRarity = pool[selectedRarity]

        if itemsOfSelectedRarity and #itemsOfSelectedRarity > 0 then
            local chosenItem = getRandomItemFromList(itemsOfSelectedRarity)

            if chosenItem and chosenItem.name ~= "_NOTHING_" then
                local count = math.random(
                    chosenItem.min or 1,
                    chosenItem.max or 1
                )

                table.insert(
                    loot,
                    {
                        name = chosenItem.name,
                        count = count,
                        metadata = chosenItem.metadata or {},
                        rarity = selectedRarity,
                    }
                )
            end
        end
    end

    return loot
end
exports("GenerateLoot", GenerateLoot)