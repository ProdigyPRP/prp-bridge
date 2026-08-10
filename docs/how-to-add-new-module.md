# How to Add a New Module to prp-bridge

This document explains step by step how to add support for a new framework, inventory system, or any other external resource.

---

## How the Module System Works

`import.lua` loads modules automatically based on the values set in `BridgeConfig`. The `moduleToDependency` table inside `import.lua` maps each category name to the corresponding config value:

```lua
-- import.lua
local moduleToDependency = {
    fw        = BridgeConfig.FrameWork,
    inv       = BridgeConfig.Inventory,
    phone     = BridgeConfig.Phone,
    target    = BridgeConfig.Target,
    dispatch  = BridgeConfig.Dispatch,
    medical   = BridgeConfig.Medical,
    minigames = BridgeConfig.Minigames,
    vkeys     = BridgeConfig.VehicleKeys,
    vfuel     = BridgeConfig.VehicleFuel,
    voice     = BridgeConfig.Voice,
}
```

For each registered category, `import.lua` loads the matching file from `modules/[category]/[resource-name]/[context].lua`. All categories listed in `moduleToDependency` are pre-loaded at startup; any other module is loaded lazily on first access via `bridge.<moduleName>`.

Set a category to `false` in `BridgeConfig` (e.g. `BridgeConfig.Phone = false`) to skip loading that module. A no-op stub is exposed on `bridge` so resources that do not need the category can still start.

- **Adding a new implementation to an existing category** (e.g. a new framework under `fw`): no changes to `import.lua` are needed - just update `BridgeConfig` to point to the new folder.
- **Adding a completely new category**: you must also register it in `moduleToDependency` and add the corresponding key to `BridgeConfig`.

Every module file must return a table at the end (`return module`). The returned table becomes part of the global `bridge` table - for example `bridge.fw`, `bridge.inv`, `bridge.target`, `bridge.voice`.

If a module needs code shared between the client and the server, it can include a `shared.lua` file that is prepended before `client.lua` / `server.lua`.

---

## Example: Adding a New Framework

### 1. Create the module folder

```
modules/fw/<framework-name>/
├── client.lua
└── server.lua
```

Example for a fictional framework called `my_framework`:

```
modules/fw/my_framework/
├── client.lua
└── server.lua
```

### 2. Implement the required functions

Every framework module must expose the same set of functions so the rest of the bridge works regardless of which framework is selected. Use existing implementations as a reference (e.g. `modules/fw/qbx_core/`).

**`modules/fw/my_framework/server.lua`**

```lua
local fw = {}

-- Returns the character identifier (citizenid / identifier) of a player
function fw.getIdentifier(src)
    local player = exports.my_framework:GetPlayer(src)
    if not player then return end
    return player.data.identifier
end

-- Returns the source of a player by their identifier
function fw.getSrcFromIdentifier(identifier)
    local player = exports.my_framework:GetPlayerByIdentifier(identifier)
    if not player then return end
    return player.data.source
end

-- Returns the character name of a player
function fw.getCharacterName(src)
    local player = exports.my_framework:GetPlayer(src)
    if not player then return "" end
    return player.data.firstname .. " " .. player.data.lastname
end

-- Checks whether a player is online
function fw.isPlayerOnline(src)
    return exports.my_framework:GetPlayer(src) ~= nil
end

-- Adds money to a player (type: "cash" | "bank" | "black")
function fw.addMoney(src, type, amount)
    exports.my_framework:AddMoney(src, type, amount)
end

-- Returns a player's balance
function fw.getMoney(src, type)
    local player = exports.my_framework:GetPlayer(src)
    if not player then return 0 end
    return player.data.money[type] or 0
end

-- ... additional functions following the bridge.fw interface ...

return fw
```

**`modules/fw/my_framework/client.lua`**

```lua
local fw = {}

function fw.getHunger()
    return 100
end

function fw.getThirst()
    return 100
end

function fw.getStress()
    return 0
end

function fw.setStatus(statusType, value)
    if statusType == "stress" then
        -- sync stress
    elseif statusType == "hunger" then
        -- sync hunger (0-100, 100 = full)
    elseif statusType == "thirst" then
        -- sync thirst
    end
end

-- getHealth, getMaxHealth, getArmor, getMaxArmor are injected from modules/fw/shared/pedStatus.lua

-- Returns the local player's character data
function fw.getPlayerData()
    return exports.my_framework:GetPlayerData()
end

-- Returns the local player's job
function fw.getJob()
    local data = exports.my_framework:GetPlayerData()
    return data and data.job
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent('YourFramework:Client:OnPlayerLoaded', function()
        TriggerEvent('prp-bridge:client:playerLoad')
    end)

    RegisterNetEvent('YourFramework:Client:OnPlayerUnload', function()
        TriggerEvent('prp-bridge:client:playerUnload')
    end)
end

return fw
```

### 3. Update `config.lua`

```lua
BridgeConfig = {
    -- ...
    FrameWork = "my_framework",   -- must match the folder name exactly
    -- ...
}
```

### 4. Add the type alias to `types/config.lua`

Open `types/config.lua` and add the new value to the `BridgeFrameWork` alias:

```lua
---@alias BridgeFrameWork
---| "qbx_core"
---| "ox_core"
---| "qb-core"
---| "es_extended"
---| "nd_core"
---| "my_framework"   -- <-- add here
```

### 5. Add type definitions (optional but recommended)

If the framework introduces new data structures, add them to the relevant files in `types/`. This gives other resources using the bridge full IntelliSense support.

---

## Example: Adding a New Inventory System

The process is identical - just a different category folder.

### 1. Create the module folder

```
modules/inv/<inventory-name>/
├── client.lua
└── server.lua
```

### 2. Implement the required functions

Use `modules/inv/ox_inventory/` as a reference.

**`modules/inv/my_inventory/server.lua`**

```lua
local inv = {}

-- Returns inventory contents in the normalized bridge format
function inv.getInventoryItems(inventoryId)
    local rawItems = exports.my_inventory:GetItems(inventoryId)
    local items = {}
    for _, item in pairs(rawItems) do
        table.insert(items, {
            name     = item.name,
            count    = item.amount,
            metaData = item.metadata,
            slot     = item.slot,
        })
    end
    return items
end

-- Checks whether a player has an item
function inv.hasItem(src, itemName, count)
    return exports.my_inventory:HasItem(src, itemName, count or 1)
end

-- Adds an item to a player's inventory
function inv.addItem(src, itemName, count, metaData)
    exports.my_inventory:AddItem(src, itemName, count, metaData)
end

-- Removes an item from a player's inventory
function inv.removeItem(src, itemName, count, metaData)
    exports.my_inventory:RemoveItem(src, itemName, count, metaData)
end

-- ... additional functions following the bridge.inv interface ...

return inv
```

### 3. Update `config.lua` and `types/config.lua`

```lua
-- config.lua
BridgeConfig = {
    Inventory = "my_inventory",
}
```

```lua
-- types/config.lua
---@alias BridgeInventory
---| "ox_inventory"
---| "origen_inventory"
---| "tgiann-inventory"
---| "my_inventory"   -- <-- add here
```

---

## Example: Adding Any Other System (e.g. Dispatch)

All other categories work exactly the same way - only the category folder name and function interface differ.

```
modules/dispatch/my_dispatch/
└── server.lua
```

```lua
-- modules/dispatch/my_dispatch/server.lua
local dispatch = {}

function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    exports.my_dispatch:Notify({
        jobs   = jobs,
        coords = coords,
        code   = data.code,
        title  = data.title,
        -- ...
    })
end

return dispatch
```

`config.lua`:

```lua
BridgeConfig = {
    Dispatch = "my_dispatch",
}
```

`types/config.lua`:

```lua
---@alias BridgeDispatch
---| "ps-dispatch"
---| "origen_police"
---| "cd_dispatch"
---| "rcore_dispatch"
---| "my_dispatch"
```

---

## Example: Adding a Brand New Category

If you are introducing a completely new category that does not exist yet (e.g. `banking`), you need one extra step: register it in `moduleToDependency` inside `import.lua`.

### 1. Add the config key

```lua
-- config.lua
BridgeConfig = {
    -- ...
    Banking = "my_banking_resource",
}
```

### 2. Register the category in `import.lua`

```lua
local moduleToDependency = {
    fw        = BridgeConfig.FrameWork,
    inv       = BridgeConfig.Inventory,
    -- ... existing entries ...
    banking   = BridgeConfig.Banking,   -- <-- add here
}
```

### 3. Create the module folder and implement it

```
modules/banking/my_banking_resource/
├── client.lua
└── server.lua
```

### 4. Add the type alias to `types/config.lua`

```lua
---@alias BridgeBanking
---| "my_banking_resource"
```

After this the module will be accessible as `bridge.banking` in any resource that uses prp-bridge.

---

## The `shared.lua` File (Optional)

If a module needs code shared between the client and the server (e.g. constants, helper functions), create a `shared.lua` file in the module folder. It is automatically prepended before `client.lua` and `server.lua`.

```
modules/fw/my_framework/
├── shared.lua   -- loaded first
├── client.lua
└── server.lua
```

---

## Checklist - New Module

**New implementation in an existing category** (e.g. a new framework, inventory, dispatch):
- [ ] Folder `modules/<category>/<name>/` created
- [ ] `client.lua` and/or `server.lua` return a table (`return module`)
- [ ] All required interface functions implemented (use existing modules as reference)
- [ ] `BridgeConfig` value updated to the exact folder name
- [ ] Alias in `types/config.lua` updated with the new value
- [ ] (Optional) New data types added to the relevant files in `types/`
- [ ] (If targeting prp-hud) Client status getters + `setStatus` + lifecycle events — see [prp-hud Integration](./prp-hud-integration.md)

**Brand new category** (does not exist in `moduleToDependency` yet) - all of the above, plus:
- [ ] New config key added to `BridgeConfig` in `config.lua`
- [ ] New entry added to `moduleToDependency` in `import.lua`
- [ ] New type alias added to `types/config.lua`
