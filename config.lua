BridgeConfig = {}

-- Version Check (we recommend leaving this true)
---@type boolean
BridgeConfig.VersionCheck = true

-- Enables debug prints
---@type boolean
BridgeConfig.Debug = true

--[[
    Available Frameworks:
        - qbx_core
        - qb-core
        - es_extended
        - nd_core
]]
---@type AvailableFrameworks
BridgeConfig.FrameWork = "qbx_core"

--[[
    Available inventories
        - ox_inventory
        - origen_inventory
        - tgiann-inventory
]]
---@type AvailableInventories
BridgeConfig.Inventory = "ox_inventory"

--[[
    Available phones
        - lb-phone
        - yseries
        - yphone
        - yflip
        - npwd
        - roadphone
        - 17mov_phone
]]
---@type AvailablePhones
BridgeConfig.Phone = "lb-phone"

--[[
    Available targets
        - ox_target
        - qb-target
        - sleepless_interact
]]
---@type AvailableTargets
BridgeConfig.Target = "ox_target"

--[[
    Available Medical systems:
        - qbx_medical
        - esx_ambulancejob
        - wasabi_ambulance
        - ars_ambulancejob
        - osp_ambulance
        - p-ambulancejob
        - nd_ambulance
        - qb-ambulancejob
]]
---@type AvailableMedicals
BridgeConfig.Medical = 'qbx_medical'

--[[
    Available Dispatch Resources:
        - ps-dispatch
        - origen_police
        - cd_dispatch
        - tk_dispatch
        - rcore_dispatch
        - lb-tablet
]]
---@type AvailableDispatches
BridgeConfig.Dispatch = "ps-dispatch"

--[[
    AvailableVehicleKeys Resources:
        - qbx_vehiclekeys
        - cd_garage
        - mVehicle
        - okokGarage
        - qb-vehiclekeys
        - qbx_vehiclekeys
        - vehicles_keys
        - wasabi_carlock
        - nd_core
]]
---@type AvailableVehicleKeys
BridgeConfig.VehicleKeys = "qbx_vehiclekeys"

--[[
    AvailableVehicleFuel Resources:
        - ox_fuel
        - LegacyFuel
        - cdn-fuel
        - lc_fuel
        - qb-fuel
]]
---@type AvailableVehicleFuel
BridgeConfig.VehicleFuel = "ox_fuel"

---@type AvailableMinigames
BridgeConfig.Minigames = "prp-minigames"

---@type { CommandEnabled: boolean, CommandName: string }
BridgeConfig.Group = {
    CommandEnabled = true,
    CommandName = "group",
}

---@type { AdminCommandEnabled: boolean, AdminCommandName: string, AdminCommandRestriction: string }
BridgeConfig.Cooldowns = {
    AdminCommandEnabled = true,
    AdminCommandName = "cooldowns",
    AdminCommandRestriction = "group.admin",
}

---@type { MaxOverTimePriority: number, AddOverTimePriorityTime: number, HoldQueuesOnStartTime: number, PoliceStrengthPerPlayer: number, PoliceJobs: string[] }
BridgeConfig.Uniqueue = {
    MaxOverTimePriority = 30, -- How much priority player can gain while waiting in queue
    AddOverTimePriorityTime = math.floor(2.5 * 60), -- How often player gets over time priority (in seconds)
    HoldQueuesOnStartTime = 0, -- How long to hold all queues after server start (in seconds)
    PoliceStrengthPerPlayer = 1, -- How much police power each police player contributes
    PoliceJobs = {
        "lspd",
        "police",
        "bsco",
    }
}

---@type table<string, number>
BridgeConfig.LootRarityWeights = {
    ["COMMON"] = 800,
    ["RARE"] = 150,
    ["EPIC"] = 45,
    ["LEGENDARY"] = 5,
}