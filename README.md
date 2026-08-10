# prp-bridge

A framework bridge for FiveM resources in the Prodigy Studios ecosystem. Instead of writing support for multiple frameworks, inventories, or phone systems directly in each script, resources use prp-bridge to get a unified API that is independent of the underlying tech stack.

## Dependencies

- [`ox_lib`](https://github.com/overextended/ox_lib)
- [`oxmysql`](https://github.com/overextended/oxmysql)

## Installation

1. Place `prp-bridge` in your `resources` folder.
2. Add `ensure prp-bridge` to `server.cfg` **before** any resources that depend on it.
3. Configure `config.lua` (see section below).
4. Start the server.

---

## Configuration (`config.lua`)

```lua
BridgeConfig = {
    VersionCheck = true,   -- check resource version on start
    Debug        = false,  -- enable debug logging

    -- Framework selection
    FrameWork  = "qbx_core",         -- qbx_core | ox_core | qb-core | es_extended | nd_core

    -- External systems (set any to false to disable that category)
    Inventory   = "ox_inventory",    -- ox_inventory | origen_inventory | tgiann-inventory | false
    Phone       = "lb-phone",        -- lb-phone | yseries | yphone | yflip | npwd | roadphone | 17mov_phone | gksphone | meteo-phone | qs-smartphone-pro | false
    Target      = "ox_target",       -- ox_target | qb-target | sleepless_interact | false
    Medical     = "qbx_medical",     -- qbx_medical | esx_ambulancejob | wasabi_ambulance | ars_ambulancejob | osp_ambulance | p-ambulancejob | nd_ambulance | qb-ambulancejob | randol_medical | tk_ambulancejob | false
    Dispatch    = "ps-dispatch",     -- ps-dispatch | origen_police | cd_dispatch | rcore_dispatch | tk_dispatch | lb-tablet | aty_dispatch | codem-dispatch | core_dispatch | qs-dispatch | false
    VehicleKeys = "qbx_vehiclekeys", -- qbx_vehiclekeys | cd_garage | mVehicle | okokGarage | vehicles_keys | wasabi_carlock | nd_core | mrnewbvehiclekeys | Renewed-Vehiclekeys | qb-vehiclekeys | false
    VehicleFuel = "ox_fuel",         -- ox_fuel | LegacyFuel | cdn-fuel | lc_fuel | qb-fuel | Renewed-Fuel | rcore_fuel | false
    Appearance  = "illenium-appearance", -- illenium-appearance | fivem-appearance | qb-clothing | esx_skin | false
    Voice       = "pma-voice",       -- pma-voice | false
    Minigames   = "prp-minigames",   -- prp-minigames | false

    -- Group command
    Group = {
        CommandEnabled = true,
        CommandName    = "group",
    },

    -- Cooldown admin command
    Cooldowns = {
        AdminCommandEnabled     = true,
        AdminCommandName        = "cooldowns",
        AdminCommandRestriction = "group.admin",
    },

    -- UniQueue system
    Uniqueue = {
        MaxOverTimePriority      = 30,
        AddOverTimePriorityTime  = 150,  -- seconds between priority increments
        HoldQueuesOnStartTime    = 0,    -- ms to hold all queues after server start
        PoliceStrengthPerPlayer  = 1,
        PoliceJobs               = { "lspd", "police", "bsco" },
    },

    -- Loot rarity weights
    LootRarityWeights = {
        ["COMMON"]    = 800,
        ["RARE"]      = 150,
        ["EPIC"]      = 45,
        ["LEGENDARY"] = 5,
    },
}
```
---

## Module Architecture

The `modules/` folder contains implementations for external resources. Each category has its own subfolder:

```
modules/
├── fw/          # frameworks  (qbx_core, ox_core, qb-core, es_extended, nd_core)
├── inv/         # inventories (ox_inventory, origen_inventory, tgiann-inventory)
├── target/      # targeting   (ox_target, qb-target, sleepless_interact)
├── dispatch/    # dispatch    (ps-dispatch, origen_police, cd_dispatch, rcore_dispatch, tk_dispatch, lb-tablet, aty_dispatch, codem-dispatch, core_dispatch, qs-dispatch)
├── medical/     # medical     (qbx_medical, esx_ambulancejob, wasabi_ambulance, tk_ambulancejob, nd_ambulance, osp_ambulance, p-ambulancejob, randol_medical, qb-ambulancejob)
├── appearance/  # appearance  (illenium-appearance, fivem-appearance, qb-clothing, esx_skin)
├── phone/       # phones      (lb-phone, yseries, yphone, yflip, npwd, roadphone, 17mov_phone, gksphone, meteo-phone, qs-smartphone-pro)
├── vkeys/       # vehicle keys (qbx_vehiclekeys, qb-vehiclekeys, cd_garage, mVehicle, okokGarage, vehicles_keys, wasabi_carlock, nd_core, mrnewbvehiclekeys, Renewed-Vehiclekeys)
├── vfuel/       # vehicle fuel (ox_fuel, LegacyFuel, cdn-fuel, lc_fuel, qb-fuel, Renewed-Fuel, rcore_fuel)
├── voice/       # voice systems (pma-voice)
├── minigames/   # minigames
├── log/         # Discord logging
└── sound/       # sound system
```

Each module is loaded automatically based on the values in `BridgeConfig`. The selected module exposes a unified API available through the global `bridge` table.

For instructions on adding a new framework or system, see [`docs/how-to-add-new-module.md`](docs/how-to-add-new-module.md).

---

## Utility Modules

### allowlist

Manages player access to specific criminal activities. Data is persistent - stored in the database (`criminal_allowlists` table).

**Server exports**

| Function | Description |
|---|---|
| `GetAllowlist(stateId)` | Returns the allowlist table for a character |
| `HasAllowlist(stateId, allowlist)` | Checks whether a character has the given allowlist |
| `AddAllowlist(src, stateId, allowlist)` | Grants an allowlist to a character |
| `RemoveAllowlist(src, stateId, allowlist)` | Revokes an allowlist from a character |

**Client export**

| Function | Description |
|---|---|
| `IsAllowlisted(allowlist)` | Checks whether the local player has the given allowlist |

**Admin commands:** `/add_allowlist`, `/remove_allowlist`

---

### attachobject

Attaches non-networked objects to a player or vehicle (skeleton bones). Supports animations and particle effects (PTFX).

**Server exports**

| Function | Description |
|---|---|
| `RegisterObject(data)` | Registers an object template |
| `UnregisterObject(objectName)` | Removes a registered template |
| `CreateAttachObject(src, objectName, weaponData?)` | Attaches an object to a player; returns `objectId` |
| `RemoveAttachObject(src, objectId)` | Detaches an object from a player |
| `GetObjectsOnPlayer(src)` | Returns a list of objects attached to the player |
| `ClearPlayerObjects(src, objectName?)` | Removes player's attached objects |
| `CreateVehTempAttachObject(entity, objectData)` | Attaches an object to a vehicle |
| `RemoveVehTempAttachObject(entity, objectId)` | Detaches an object from a vehicle |
| `ClearVehTempAttachObjects(entity)` | Removes all objects from a vehicle |

**Client export**

| Function | Description |
|---|---|
| `GetObjectHandle(objectId)` | Returns the entity handle of an attached object |

<details>
<summary><code>ObjectData</code> structure</summary>

```lua
{
    objectName                 = "string",          -- unique name (required)
    modelHash                  = number | string,   -- model hash or name
    offset                     = vector3,
    rotation                   = vector3,
    boneId                     = number | string,
    disableCollision           = boolean,
    completelyDisableCollision = boolean,
    isWeapon                   = boolean?,
    dict                       = string?,           -- animation dictionary
    anim                       = string?,           -- animation name
    ptfxAsset                  = string?,
    ptfxName                   = string?,
    ptfxOffset                 = vector3?,
    ptfxRot                    = vector3?,
    ptfxScale                  = number?,
    ptfxColor                  = vector3?,
}
```
</details>

---

### cooldowns

Global and per-character cooldown management.

**Server exports**

| Function | Description |
|---|---|
| `startGlobalCooldown(key, minutes)` | Starts a server-wide cooldown |
| `startCooldownByIdentifier(identifier, key, minutes, allChars)` | Starts a per-character cooldown |
| `startCooldownByPlayerId(playerId, key, minutes, allChars)` | Starts a cooldown by player ID |
| `isCooldownActive(key)` | Checks whether a global cooldown is active |
| `isCooldownActiveForIdentifier(identifier, key)` | Checks a character's cooldown |

When a cooldown finishes, the server emits the event `prp-bridge:cooldowns:finished`.

**Admin command:** `/cooldowns` (cooldown management menu)

---

### groups

A simple player grouping system for shared activities. Groups integrate with UniQueue and support invitations.

**Server exports**

| Function | Description |
|---|---|
| `CreateGroup(leaderSrc)` | Creates a group; returns the group object |
| `GetGroupFromMember(src)` | Returns a group by player ID |
| `GetGroupFromMemberByIdentifier(identifier)` | Returns a group by character identifier |
| `GetGroupByUuid(uuid)` | Returns a group by UUID |
| `GetGroupByPartyUuid(partyUuid)` | Returns the group associated with a UniQueue party |
| `GetGroupIdFromMember(src)` | Returns the group UUID for a player |
| `GetGroupPlayerIds(uuid)` | Returns a list of player IDs in the group |

<details>
<summary>Group object methods</summary>

```lua
group:getUuid()
group:getPartyUuid()
group:setLeader(src)
group:getLeader()                    -- { identifier, src, characterName }
group:addMember(src)
group:removeMember(src)
group:getMembers()
group:getMembersCount()
group:getMembersPlayerIds()
group:isSrcAMember(src)
group:isSrcALeader(src)
group:setActivity({ activityId, activityName })
group:getActivity()
group:clearActivity()
group:triggerEvent(eventName, ...)
group:isAnyoneOnline()
group:disband()
group:isInviting() / group:toggleInviting()
group:addPendingInvite(inviteUuid, targetSrc)
group:removePendingInvite(inviteUuid)
group:isPendingInviteValid(inviteUuid, targetSrc)
group:createUniqueueParty(partyType)
group:enterUniqueue(queueName)
```
</details>

**Command:** `/group`

---

### pedinteractions

Places peds on the map with context menu interactions. Uses the ox_lib point system and the configured targeting system.

**Client exports**

| Function | Description |
|---|---|
| `AddPedInteraction(id, payload)` | Creates a ped interaction point |
| `RemovePedInteraction(id)` | Removes an interaction point |

<details>
<summary><code>PedInteractionPayload</code> structure</summary>

```lua
{
    model    = number | string,  -- ped model
    coords   = vector3,
    heading  = number,
    radius   = number,           -- interaction activation radius
    options  = table,            -- target options (same format as bridge.target)
    component = {                -- optional outfit
        componentId, drawableId, textureId, paletteId
    },
    anim = {                     -- optional ped animation
        animDict, anim, blendIn, blendOut, duration, flag, playback,
        lockX, lockY, lockZ
    },
    scenario = string?,          -- task scenario (alternative to anim)
    weapon   = number?,          -- weapon hash to give the ped
}
```
</details>

---

### propplacer

An interactive utility for manually placing props on the map (e.g. by an admin or an activity script).

**Client export**

```lua
-- Returns vector4(x, y, z, heading) or nil if cancelled
exports["prp-bridge"]:PropPlacer(model, forceGround?, allowedMaterials?, maxDistance?)
```

Controls during placement:
- **Scroll** - rotate
- **E** - confirm placement
- **Backspace** - cancel
- **H** (debug mode) - display the surface material hash

---

### sellshops

Registers locations where players can sell items. Internally uses an inventory stash system.

**Server exports**

| Function | Description |
|---|---|
| `RegisterSellShop(id, payload)` | Registers a sell shop location |
| `OpenSellShop(src, id)` | Opens the shop for a player |

---

### sounds

Client-side playback of `.ogg` audio files. Available through the unified bridge API:

```lua
bridge.sound.play(soundName, volume?)
bridge.sound.playSpatial(soundName, coords, volume?, maxDistance?)
```

Place audio files in the `sounds/` folder as `*.ogg`.

---

### uniqueue

Queues players (or groups) for structured activities, enforces police presence requirements, and manages priorities.

**Server exports**

| Function | Description |
|---|---|
| `CreateQueue(name, type, requiredPolicePower, maxConcurrentTasks, cooldown)` | Creates a queue |
| `CreateParty(type)` | Creates a party (`"civ"` or `"crime"`) |
| `GetQueue(name)` | Returns a queue by name |
| `GetQueuesByType(type)` | Returns all queues of a given type |
| `GetParty(uuid)` | Returns a party by UUID |
| `GetPartiesByType(type)` | Returns all parties of a given type |
| `GetPartiesFromPlayer(identifier)` | Returns all parties a player belongs to |

<details>
<summary>Selected queue and party methods</summary>

```lua
-- Queue
queue:setExecFunction(func)      -- callback triggered when a party is dequeued
queue:setCheckFunction(func)     -- validation callback (can the party enter?)
queue:add(party)
queue:remove(party)
queue:setBlocked(bool)
queue:setCooldown(seconds)
queue:clearCooldown()

-- Party
party:addMember(identifier)
party:removeMember(identifier)
party:getMembers()
party:setPriority(priority)
party:addOverTimePrio()          -- grants priority for long wait times
party:destroy()
```
</details>

**Admin commands:**
`/uni_findplayer`, `/uni_setprio`, `/uni_rmfromque`, `/uni_setblocked`, `/uni_setcooldown`, `/uni_clearcooldown`, `/uni_totalblock`, `/uni_cleartask`, `/uni_devmode`

---

## License

prp-bridge is licensed under the **GNU Lesser General Public License v3.0 or later (LGPL-3.0-or-later)**.

This resource is built on top of [ox_lib](https://github.com/CommunityOx/ox_lib) (Copyright © 2025 Overextended), which is distributed under the same license. In accordance with the LGPL-3.0 terms and the ox_lib [NOTICE](https://github.com/CommunityOx/ox_lib/blob/main/NOTICE.md), the following conditions apply:

- Credit must be given to the original authors and a link to the original project must be provided.
- Any modifications to the original work must be documented.
- The full LGPL-3.0 license text must be included with any distribution.
- This project must remain available under the LGPL-3.0 or a compatible open-source license.
- All existing copyright and licensing notices must be preserved.
