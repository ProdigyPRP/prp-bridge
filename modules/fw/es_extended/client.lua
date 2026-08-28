local ESX = exports.es_extended:getSharedObject()
local fw = {}

local PlayerData = ESX.GetPlayerData()

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)

local stress, hunger, thirst

local function fetchStress()
    TriggerEvent("esx_status:getStatus", 'stress', function(status)
        if not status then return end
        if not status?.val then return end

        stress = math.floor(status.val / 100)
    end)
end

AddEventHandler("esx_status:onTick", function(data)
    if not data then return end

    for _, status in pairs(data) do
        if status.name == 'thirst' then
            thirst = math.floor(status.percent)
        end

        if status.name == 'hunger' then
            hunger = math.floor(status.percent)
        end
    end

    fetchStress()

    if bridge.name == bridge.currentResource then
        if hunger then
            TriggerEvent('prp-bridge:client:statusChanged', 'hunger', hunger)
        end

        if thirst then
            TriggerEvent('prp-bridge:client:statusChanged', 'thirst', thirst)
        end

        if stress then
            TriggerEvent('prp-bridge:client:statusChanged', 'stress', stress)
        end
    end
end)

---@return number
function fw.getStress()
    return stress or 0
end

---@return number
function fw.getHunger()
    return hunger or 100
end

---@return number
function fw.getThirst()
    return thirst or 100
end

---@param statusType string
---@param value number
function fw.setStatus(statusType, value)
    if statusType == "stress" then
        TriggerEvent("esx_status:set", 'stress', value)
    elseif statusType == "hunger" then
        TriggerEvent("esx_status:set", 'hunger', value)
    elseif statusType == "thirst" then
        TriggerEvent("esx_status:set", 'thirst', value)
    end
end

function fw.applyBuff(buff, data)
    --- Integrations with other resources
end

function fw.clearBuffs()
    --- Integrations with other resources
end

---@param type 'inform' | 'error' | 'success'| 'warning'
---@param message string
---@param title? string
---@param duration? number
function fw.notify(type, message, title, duration)
    lib.notify({
        type = type or "inform",
        title = title or nil,
        description = message or "",
        duration = duration or 3000,
    })
end

--- https://coxdocs.dev/ox_lib/Modules/Interface/Client/textui#libshowtextui

---@param text string
---@param options { position?: ShowTextUIPos, icon?: string | table<string>, iconColor?: string, iconAnimation?: ShowTextUIAnims, alignIcon?: "top" | "center" }
function fw.showTextUI(text, options)
    lib.showTextUI(text, options)
end

function fw.hideTextUI()
    lib.hideTextUI()
end

---@return boolean
---@return string | nil
function fw.isTextUIOpen()
    return lib.isTextUIOpen()
end

---@param payload FWProgressBar
---@return boolean?
function fw.progressBar(payload)
    local options = {
        duration = payload.duration or 5000,
        label = payload.label,
        useWhileDead = false,
        allowRagdoll = payload.allowRagdoll or false,
        allowSwimming = payload.allowSwimming or false,
        allowCuffed = payload.allowCuffed or false,
        allowFalling = payload.allowFalling or false,
        canCancel = payload.canCancel or false,
        disable = {}
    }

    if payload.controlDisables then
        if payload.controlDisables.disableMovement then
            options.disable.move = true
        end
        if payload.controlDisables.disableCarMovement then
            options.disable.car = true
        end
        if payload.controlDisables.disableMouse then
            options.disable.mouse = true
        end
        if payload.controlDisables.disableCombat then
            options.disable.combat = true
        end
        if payload.controlDisables.disableSprint then
            options.disable.sprint = true
        end
    end

    if payload.animation and payload.animation.animDict and payload.animation.animClip then
        options.anim = {
            dict = payload.animation.animDict,
            clip = payload.animation.animClip,
        }

        if payload.animation.animFlag then
            options.anim.flag = payload.animation.animFlag
        end
    elseif payload.animation and payload.animation.scenario then
        options.anim = {
            scenario = payload.animation.scenario
        }
    end

    return lib.progressBar(options)
end

---@param header string
---@param content string
---@param labels? {cancel?: string, confirm?: string}
---@param timeout? number Force the window to timeout after `x` milliseconds.
---@return 'cancel'|'confirm'|nil
function fw.confirmDialog(header, content, labels, timeout)
    return lib.alertDialog({
        header = header,
        content = content,
        centered = true,
        cancel = true,
        labels = labels or {cancel = locale("Cancel"), confirm = locale("Confirm")},
    }, timeout)
end

---@param heading string
---@param rows string[] | InputDialogRowProps[]
---@param options InputDialogOptionsProps[]?
---@return string[] | number[] | boolean[] | nil
function fw.inputDialog(heading, rows, options)
    return lib.inputDialog(heading, rows, options)
end

---@param payload FWContextMenuProps | FWContextMenuProps[]
function fw.contextMenu(payload)
    lib.registerContext(payload)
end

---@param contextId string
function fw.showContext(contextId)
    lib.showContext(contextId)
end

function fw.isOnDuty()
    return PlayerData.job.onDuty
end

---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(job, grade, duty)
    if not PlayerData or not PlayerData.job then
        return false
    end

    local jobId = PlayerData.job.name
    if jobId ~= job then
        return false
    end

    if grade then
        local gradeId = PlayerData.job.grade
        if gradeId < grade then
            return false
        end
    end

    if duty then
        return fw.isOnDuty()
    end

    return true
end

---@return string | nil
function fw.getIdentifier()
    return PlayerData?.identifier
end

---@return string?
function fw.getCharacterName()
    local player = PlayerData
    if not player then
        return nil
    end

    if not player.firstName or not player.lastName then
        return nil
    end

    return ("%s %s"):format(player.firstName, player.lastName)
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent('esx:playerLoaded', function()
        TriggerEvent('prp-bridge:client:playerLoad')
    end)

    RegisterNetEvent('esx:onPlayerLogout', function()
        TriggerEvent('prp-bridge:client:playerUnload')
    end)

    RegisterNetEvent('esx:setJob', function(job)
        TriggerEvent('prp-bridge:client:jobChanged', job)
    end)
end

return fw
