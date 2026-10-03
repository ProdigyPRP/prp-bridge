---@meta

bridge = {}

bridge.context = "server" ---@type "server" | "client" | "shared"
bridge.name = "" ---@type string
bridge.currentResource = "" ---@type string
bridge.usedInv = "ox_inventory" ---@type AvailableInventories
bridge.usedFw = "qbx_core" ---@type AvailableFrameworks

bridge.inv = {}

---@param inventoryId string|number
---@return table<{ name: string, count: number, metadata: table?, slot: number }>
function bridge.inv.getInventoryItems(inventoryId) end

---@param inventoryId string | number
---@return { items: table } | nil
function bridge.inv.getInventory(inventoryId) end

---@param data InvTempStashProps
---@return string inventoryId
function bridge.inv.createTemporaryStash(data) end

---@param data InvStashProps
function bridge.inv.createStash(data) end

---@param cb fun(payload: InvSwapHookPayload):boolean Return `false` to cancel the item swap.
---@param options? InvHookOptions
---@return number hookId
function bridge.inv.registerSwapItemsHook(cb, options) end

---@param cb fun(payload: InvCreateItemHookPayload):boolean
---@param options? table
---@return number hookId
function bridge.inv.registerCreateItemHook(cb, options) end

---@param hookId number
function bridge.inv.removeHooks(hookId) end

---@param inventoryId string|number
---@param keep? string | table<string> The keep argument is either a string or an array of strings containing the name(s) of the item(s) to keep in the inventory after clearing.
function bridge.inv.clearInventory(inventoryId, keep) end

---@param src number | string
---@param inventoryId string|number
function bridge.inv.openStash(src, inventoryId) end

---@param src number | string
---@param inventoryId string|number
function bridge.inv.forceOpenStash(src, inventoryId) end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@return boolean, InvGiveItemResp
function bridge.inv.giveItem(inventoryId, itemName, count, metadata) end

---@param inventoryId string|number
---@param itemName string
---@param count number
---@param metadata table|nil
---@param slot number|nil
---@return boolean, InvRemoveItemResp
function bridge.inv.removeItem(inventoryId, itemName, count, metadata, slot) end

---@param itemName string
---@return string|nil -- Returns the label of the item, or `nil` if not found.
function bridge.inv.getItemLabel(itemName) end

---@param itemName string
---@return table|nil -- Returns the item data table, or `nil` if not found.
function bridge.inv.getItemData(itemName) end

---@param prefix string
---@param items table<{ name: string, count: number, metaData: table? }>
---@param coords vector3
---@param slots number?
---@param maxWeight number?
---@param instance string|number|nil
---@param model number?
function bridge.inv.createCustomDrop(prefix, items, coords, slots, maxWeight, instance, model) end

---@param inventoryId string|number
---@param loadout table<{ name: string, count: number, metaData: table? }>
---@param excludedItems table<string, boolean>
function bridge.inv.giveLoadoutItems(inventoryId, loadout, excludedItems) end

---@param inventoryId string|number
---@param loadout table<{ name: string, count: number, metaData: table? }>
function bridge.inv.returnItems(inventoryId, loadout) end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return number | table<string, number>
function bridge.inv.count(inventoryId, lookFor) end

---@param inventoryId string|number
---@param item string
---@param count number
---@return boolean
---@overload fun(item: string, count: number):boolean
function bridge.inv.hasItem(inventoryId, item, count) end

---@param inventoryId string|number
---@param slot number
---@return { weight: number, name: string, metadata: table?, count: number, slot: number } | nil
function bridge.inv.getSlot(inventoryId, slot) end

---@param inventoryId string|number
---@param slot number
---@return number|nil
function bridge.inv.getItemDurability(inventoryId, slot) end

---@param inventoryId string|number
---@param slot number
---@return table | nil
function bridge.inv.getItemMetaData(inventoryId, slot) end

---@param inventoryId string|number
---@param slot number
---@param metaData table
---@return boolean
function bridge.inv.setItemMetaData(inventoryId, slot, metaData) end

---@param inventoryId string|number
---@param slot number
---@param key string
---@param value any
---@return boolean
function bridge.inv.setItemMetaDataKey(inventoryId, slot, key, value) end

---@param inventoryId string|number|table
---@param slot number
---@param metaData table<string, any>
---@return boolean
function bridge.inv.setItemMetaDatasByKey(inventoryId, slot, metaData) end

---@param inventoryId string|number
---@param lookFor string[] | string
---@return InvSearchItem[]
function bridge.inv.searchInventory(inventoryId, lookFor) end

---@param itemName string
---@param minDurabilityAmount number | nil
---@return number | nil -- Returns the slot number of the item, or `nil` if not found.
function bridge.inv.findItemSlot(itemName, minDurabilityAmount) end

---**`client`**
---@param itemName string
---@param metadata table|nil
---@return table | nil
function bridge.inv.getSlotWithItem(itemName, metadata) end

---@param data table<string, string>
function bridge.inv.registerDisplayMetaData(data) end

---@param name string
function bridge.inv.openShop(name) end

---@return table<{ name: string, count: number, metadata: table?, slot: number }>
function bridge.inv.getAllItems() end

---@param shopId string
---@param shopData InvShopData
function bridge.inv.registerShop(shopId, shopData) end

---@param inventoryId string | number
---@param item string
---@param count number
---@param metaData table?
---@return boolean
function bridge.inv.canCarryItem(inventoryId, item, count, metaData) end

---@param itemName string
---@return number
function bridge.inv.getItemCount(itemName) end

---**`client`**
---@param itemName string
---@return string
function bridge.inv.getItemImageUrl(itemName) end

---**`client`** Disarms the player, removing the current weapon from their hands.
function bridge.inv.disarm() end

---@param src? number
---@return table<string, table> --Returns a table of all registered items, where the key is the item name and the value is the item data table.
function bridge.inv.getRegisteredItems(src) end

---@param type InvVehStashType
---@param plate string
---@return boolean
function bridge.inv.vehInvHasItems(type, plate) end

bridge.fw = {}

---**`server`**
---@param src number | string
---@return string?
---@overload fun():string?
function bridge.fw.getIdentifier(src) end

---**`client`**
---@return string?
---@overload fun():string?
function bridge.fw.getIdentifier() end

---@param identifier string
---@return number?
function bridge.fw.getSrcFromIdentifier(identifier) end

---@param identifier string
---@return string?
---@overload fun():string?
function bridge.fw.getCharacterName(identifier) end

---@param src number | string
---@param type 'inform' | 'error' | 'success' | 'warning'
---@param message string
---@param title? string
---@param duration? number
function bridge.fw.notify(src, type, message, title, duration) end

---@alias ShowTextUIPos "right-center" | "left-center" | "top-center" | "bottom-center"
---@alias ShowTextUIAnims "spin" | "spinPulse" | "spinReverse" | "pulse" | "beat" | "fade" | "beatFade" | "bounce" | "shake"

---@param text string
---@param options? { position?: ShowTextUIPos, icon?: string | table<string>, iconColor?: string, iconAnimation?: ShowTextUIAnims, alignIcon?: "top" | "center" }
function bridge.fw.showTextUI(text, options) end
function bridge.fw.hideTextUI() end

---@return boolean
---@return string | nil
function bridge.fw.isTextUIOpen() end


---@alias CommandParamType "string" | "number" | "playerId" | "longString"

---@param commandName string
---@param helpText string
---@param params table<{ name: string, type: CommandParamType, help: string }>?
---@param restrictedGroup string?
---@param callback fun(src: number, args: table, rawCommand: string)
function bridge.fw.registerCommand(commandName, helpText, params, restrictedGroup, callback) end

---@param src string | number
---@return boolean
function bridge.fw.isAdmin(src) end

---@param src number | string
---@param payload table<string, { type: "set" | "add" | "remove", value: any }>
function bridge.fw.setMetadata(src, payload) end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function bridge.fw.addRep(src, rep, amount, reason) end

---@param src number | string
---@param rep string
---@param amount number
---@param reason string
function bridge.fw.removeRep(src, rep, amount, reason) end

---@param identifier string
---@param coords vector3
function bridge.fw.updateDisconnectLocation(identifier, coords) end

---@param explosionType number
function bridge.fw.isExplosionAllowed(explosionType) end

---@param explosionType number
---@param time number
function bridge.fw.allowExplosion(explosionType, time) end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function bridge.fw.addMoney(src, moneyType, moneyAmount, reason) end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@param moneyAmount number
---@param reason string | nil
---@return boolean
function bridge.fw.removeMoney(src, moneyType, moneyAmount, reason) end

---@param src number | string
---@param moneyType "cash" | "bank" | "crypto"
---@return number
function bridge.fw.getMoney(src, moneyType) end

---**`client`**
---@param header string
---@param content string
---@param labels? {cancel?: string, confirm?: string}
---@param timeout? number Force the window to timeout after `x` milliseconds.
---@return 'cancel'|'confirm'|nil
function bridge.fw.confirmDialog(header, content, labels, timeout) end

---@param heading string
---@param rows string[] | InputDialogRowProps[]
---@param options InputDialogOptionsProps[]?
---@return string[] | number[] | boolean[] | nil
function bridge.fw.inputDialog(heading, rows, options) end

---@return boolean
function bridge.fw.isOnDuty() end

---@return number
function bridge.fw.getStress() end

---@return number
function bridge.fw.getHunger() end

---@return number
function bridge.fw.getThirst() end

---@return number
function bridge.fw.getHealth() end

---@return number
function bridge.fw.getMaxHealth() end

---@return number
function bridge.fw.getArmor() end

---@return number
function bridge.fw.getMaxArmor() end

---@param src number | string
---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function bridge.fw.hasJob(src, job, grade, duty) end

---**`server`**
---@param src number | string
---@param gang string
---@param grade number? do they require a minimum grade
---@return boolean
function bridge.fw.hasGang(src, gang, grade) end

---@param jobName string
---@return number
function bridge.fw.getDutyCountJob(jobName) end

---@param jobName string
---@return table<number, true>
function bridge.fw.getPlayersOnDuty(jobName) end

---@param itemName string
---@param cb fun(src: number, item: { name: string, label: string, metaData: table?, slot: number, count: number })
function bridge.fw.registerItemUse(itemName, cb) end

---@param payload FWProgressBar
---@return boolean?
function bridge.fw.progressBar(payload) end

---@param type 'inform' | 'error' | 'success' | 'warning'
---@param message string
---@param title? string
---@param duration? number
function bridge.fw.notify(type, message, title, duration) end

---@param payload FWContextMenuProps | FWContextMenuProps[]
function bridge.fw.contextMenu(payload) end

---@param contextId string
function bridge.fw.showContext(contextId) end

---@param plate string
---@param returnEmpty? boolean should empty table format be returned
---@return OwnedVehicle | nil
function bridge.fw.getOwnedVehicleByPlate(plate, returnEmpty) end

---@param identifier string | number
---@param classes? string | table<string>
---@return table<number, OwnedVehicle> | nil
function bridge.fw.getAllOwnedVehicles(identifier, classes) end

---@param src number
---@param vehicleName string
---@return integer?
---@return string?
function bridge.fw.addOwnedVehicle(src, vehicleName) end

---@param plate string
---@param identifier string
---@return boolean
---@return string?
function bridge.fw.updateVehicleOwner(plate, identifier) end

bridge.dispatch = {}

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function bridge.dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash) end

bridge.phone = {}

---@param src number | string
---@param from number
---@param message string
bridge.phone.sendMessage = function(src, from, message) end

---@param src number | string
---@param from number
---@param coords vector3
bridge.phone.sendCoords = function(src, from, coords) end

---@param src number | string
---@param title string
---@param content? string
bridge.phone.sendNotification = function(src, title, content) end

bridge.medical = {}

---**`client`**
---@param serverId number
---@return boolean
function bridge.medical.isPlayerDead(serverId) end

bridge.appearance = {}

---**`client`**
---@param ped number
---@param data table|string
function bridge.appearance.setPedAppearance(ped, data) end

---**`client`**
---@param ped? number
---@return table?
function bridge.appearance.getPedAppearance(ped) end

---**`client`**
---@param isNew? boolean
function bridge.appearance.openCreator(isNew) end

bridge.minigames = {}

---@param gameName string
---@param gameOptions table?
---@param otherOptions OtherOptions?
---@return boolean
function bridge.minigames.play(gameName, gameOptions, otherOptions) end

function bridge.minigames.stop() end

---@return boolean
function bridge.minigames.isPlaying() end

---**`client`**
---@param value number
function bridge.medical.overrideMaxHealth(value) end

---**`server`**
---@param src number | string
---@param amount number
function bridge.medical.healPlayer(src, amount) end

bridge.target = {}

---@param zoneId number | string can be zoneId (number) or zone name (string)
bridge.target.removeZone = function(zoneId) end

---@param payload TargetBoxZone
---@return number | string
bridge.target.addBoxZone = function(payload) end

---@param payload TargetSphereZone
---@return number | string
bridge.target.addSphereZone = function(payload) end

---@param entities number | number[]
---@param options TargetOptions[]
bridge.target.addLocalEntity = function(entities, options) end

---@param entities number | number[]
---@param optionNames string | string[]
bridge.target.removeLocalEntity = function(entities, optionNames) end

---@param netIds number | number[]
---@param options TargetOptions[]
bridge.target.addEntity = function(netIds, options) end

---@param netIds number | number[]
---@param optionNames string | string[]
bridge.target.removeEntity = function(netIds, optionNames) end

---@param options TargetOptions[]
bridge.target.addGlobalPed = function(options) end

---@param optionNames string | string[]
bridge.target.removeGlobalPed = function(optionNames) end

---@param options TargetOptions[]
bridge.target.addGlobalPlayer = function(options) end

---@param optionNames string | string[]
bridge.target.removeGlobalPlayer = function(optionNames) end

---@param options TargetOptions[]
bridge.target.addGlobalVehicle = function(options) end

---@param optionNames string | string[]
bridge.target.removeGlobalVehicle = function(optionNames) end

---@param models number | string | (number | string)[]
---@param options TargetOptions[]
bridge.target.addModel = function(models, options) end

---@param models number | string | (number | string)[]
---@param optionNames string | string[]
bridge.target.removeModel = function(models, optionNames) end

---@param disable boolean
bridge.target.disableTargeting = function(disable) end

bridge.sound = {}

---@param src number | string
---@param fileName string
---@param volume number
---@param noAutoPath boolean? This lets you decide, if you want prp-bridge to search for sounds in `sounds` folder of resource.
---@overload fun(fileName: string, volume: number, noAutoPath: boolean?): string soundId
bridge.sound.play = function(src, fileName, volume, noAutoPath) end

---@param src number | string
---@param fileName string
---@param volume number
---@param coords vector3
---@param distance number Max distance where the sound can be heard.
---@param shouldMuffle boolean? Whether the sound should be muffled when behind walls.
---@param noAutoPath boolean? This lets you decide, if you want prp-bridge to search for sounds in `sounds` folder of resource.
---@overload fun(fileName: string, volume: number, coords: vector3, distance: number, shouldMuffle: boolean?, noAutoPath: boolean?): string? soundId
bridge.sound.playSpatial = function(src, fileName, volume, coords, distance, shouldMuffle, noAutoPath) end

bridge.log = {}

---@param webhookUrl string
---@param title string
---@param message string
---@param args? table<string, any>
bridge.log.send = function(webhookUrl, title, message, args) end

bridge.vkeys = {}

---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
---@overload fun(src: number | string, vehicle: number, plate?: string)
bridge.vkeys.give = function(vehicle, plate) end

---@param vehicle number Vehicle entity
---@param plate? string Vehicle plate
---@overload fun(src: number | string, vehicle: number, plate?: string)
bridge.vkeys.remove = function(vehicle, plate) end

bridge.vfuel = {}

---@param vehicle number Vehicle entity
---@return number 0-100
function bridge.vfuel.get(vehicle) end

---**`server`**
---@param src number | string
---@param vehicle number Vehicle entity
---@param amount number Fuel amount to set
---@return boolean
function bridge.vfuel.set(src, vehicle, amount) end

bridge.voice = {}

---@return AvailableVoice
bridge.voice.getProvider = function() end

---@return VoiceHudData
bridge.voice.getHudData = function() end
