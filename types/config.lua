---@meta

---@alias AvailableFrameworks 'qbx_core' | 'qb-core' | 'es_extended' | 'nd_core' | 'ox_core' | false

---@alias AvailableInventories 'ox_inventory' | 'origen_inventory' | 'tgiann-inventory' | false

---@alias AvailablePhones 'lb-phone' | 'yseries' | 'yphone' | 'yflip' | 'npwd' | 'roadphone' | '17mov_phone' | 'gksphone' | 'meteo-phone' | 'qs-smartphone-pro' | false

---@alias AvailableTargets 'ox_target' | 'qb-target' | 'sleepless_interact' | false

---@alias AvailableMedicals 'qbx_medical' | 'esx_ambulancejob' | 'wasabi_ambulance' | 'ars_ambulancejob' | 'osp_ambulance' | 'p-ambulancejob' | 'nd_ambulance' | 'qb-ambulancejob' | 'randol_medical' | 'tk_ambulancejob' | false

---@alias AvailableDispatches 'ps-dispatch' | 'origen_police' | 'cd_dispatch' | 'rcore_dispatch' | 'tk_dispatch' | 'lb-tablet' | 'aty_dispatch' | 'codem-dispatch' | 'core_dispatch' | 'qs-dispatch' | false

---@alias AvailableMinigames 'prp-minigames' | false

---@alias AvailableAppearances 'illenium-appearance' | 'fivem-appearance' | 'qb-clothing' | 'esx_skin' | false

---@alias AvailableVoice 'pma-voice' | false

---@class VoiceHudData
---@field connected boolean
---@field isTalking boolean
---@field radioTalking boolean
---@field volume number
---@field volumeCount number
---@field indicator string

---@alias AvailableVehicleKeys 'cd_garage' | 'mVehicle' | 'okokGarage' | 'qb-vehiclekeys' | 'qbx_vehiclekeys' | 'vehicles_keys' | 'wasabi_carlock' | 'nd_core' | 'mrnewbvehiclekeys' | 'Renewed-Vehiclekeys' | false

---@alias VehicleClasses 'X' | 'S' | 'A' | 'B' | 'C' | 'D' | 'E' | 'EV1' | 'EV2'
---@alias VehicleTypes 'car' | 'bike' | 'quadbike' | 'bicycle' | 'heli' | 'plane' | 'boat' | 'trailer' | 'train' | 'blimp' | 'submarine' | 'submarinecar' | 'amphibious_quadbike' | 'amphibious_automobile'

---@class VehicleData
---@field manufacturer string
---@field label string
---@field name string
---@field class VehicleClasses
---@field type VehicleTypes
---@field inBoosting boolean

---@alias AvailableVehicleFuel 'ox_fuel' | 'LegacyFuel' | 'cdn-fuel' | 'lc_fuel' | 'qb-fuel' | 'Renewed-Fuel' | 'rcore_fuel' | false
