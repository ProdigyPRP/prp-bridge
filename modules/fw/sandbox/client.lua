local fw = {}

local STATUS_HUNGER <const> = "PLAYER_HUNGER"
local STATUS_THIRST <const> = "PLAYER_THIRST"
local STATUS_STRESS <const> = "PLAYER_STRESS"

---@param name string
---@param fallback number
---@return number
local function getStatusValue(name, fallback)
    local ok, status = pcall(function()
        return exports["sandbox-status"]:GetSingle(name)
    end)

    if ok and status and status.value ~= nil then
        return status.value
    end

    return fallback
end

---@return number
function fw.getStress()
    return getStatusValue(STATUS_STRESS, 0)
end

---@return number
function fw.getHunger()
    return getStatusValue(STATUS_HUNGER, 100)
end

---@return number
function fw.getThirst()
    return getStatusValue(STATUS_THIRST, 100)
end

---@param statusType string
---@param value number
function fw.setStatus(statusType, value)
    local name = statusType
    if statusType == "stress" then
        name = STATUS_STRESS
    elseif statusType == "hunger" then
        name = STATUS_HUNGER
    elseif statusType == "thirst" then
        name = STATUS_THIRST
    end

    pcall(function()
        exports["sandbox-status"]:SetSingle(name, value)
    end)
end

function fw.applyBuff(buff, data)
    if type(buff) ~= "string" then
        return
    end

    local val = 0
    if type(data) == "table" then
        val = data.val or data.value or data.duration or 0
    elseif type(data) == "number" then
        val = data
    end

    pcall(function()
        exports["sandbox-hud"]:ApplyBuff(buff, val)
    end)
end

function fw.clearBuffs()
    pcall(function()
        exports["sandbox-hud"]:RemoveBuffType("prog_mod")
        exports["sandbox-hud"]:RemoveBuffType("stress_ticks")
        exports["sandbox-hud"]:RemoveBuffType("heal_ticks")
        exports["sandbox-hud"]:RemoveBuffType("armor_ticks")
    end)
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

---@param text string
---@param options? { position?: ShowTextUIPos, icon?: string | table<string>, iconColor?: string, iconAnimation?: ShowTextUIAnims, alignIcon?: "top" | "center" }
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
        labels = labels or { cancel = locale("Cancel"), confirm = locale("Confirm") },
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
    return LocalPlayer.state.onDuty ~= nil and LocalPlayer.state.onDuty ~= false
end

---@param job string
---@param grade number? do they require a minimum grade
---@param duty boolean? do they need to be on duty
---@return boolean
function fw.hasJob(job, grade, duty)
    local result = exports["sandbox-jobs"]:HasJob(job, nil, nil, grade, duty and true or false)
    return result ~= false and result ~= nil
end

---@return string?
function fw.getIdentifier()
    local char = LocalPlayer.state.Character
    if not char then
        return LocalPlayer.state.SID and tostring(LocalPlayer.state.SID) or nil
    end

    local sid = char:GetData("SID")
    if sid == nil then
        return nil
    end

    return tostring(sid)
end

---@return string?
function fw.getCharacterName()
    local char = LocalPlayer.state.Character
    if not char then
        return nil
    end

    local first = char:GetData("First")
    local last = char:GetData("Last")
    if not first or not last then
        return nil
    end

    return ("%s %s"):format(first, last)
end

---@return table?
local function getPrimaryJobPayload()
    local jobs = exports["sandbox-jobs"]:GetJobs()
    if not jobs or #jobs == 0 then
        return nil
    end

    local onDuty = LocalPlayer.state.onDuty
    local selected = jobs[1]
    if onDuty then
        for i = 1, #jobs do
            if jobs[i].Id == onDuty then
                selected = jobs[i]
                break
            end
        end
    end

    if not selected then
        return nil
    end

    return {
        name = selected.Id,
        label = selected.Name or selected.Id,
        onduty = onDuty ~= nil and onDuty == selected.Id,
        grade = {
            level = selected.Grade and selected.Grade.Level or 0,
            name = selected.Grade and (selected.Grade.Name or selected.Grade.Id) or nil,
        },
    }
end

if bridge.name == bridge.currentResource then
    RegisterNetEvent("Characters:Client:Spawn", function()
        TriggerEvent("prp-bridge:client:playerLoad")
    end)

    RegisterNetEvent("Characters:Client:Logout", function()
        TriggerEvent("prp-bridge:client:playerUnload")
    end)

    RegisterNetEvent("Characters:Client:Updated", function(key)
        if key == "Jobs" or key == -1 then
            TriggerEvent("prp-bridge:client:jobChanged", getPrimaryJobPayload())
        end
    end)

    AddEventHandler("Status:Client:Update", function(name, value)
        if name == STATUS_HUNGER then
            TriggerEvent("prp-bridge:client:statusChanged", "hunger", value)
        elseif name == STATUS_THIRST then
            TriggerEvent("prp-bridge:client:statusChanged", "thirst", value)
        elseif name == STATUS_STRESS then
            TriggerEvent("prp-bridge:client:statusChanged", "stress", value)
        end
    end)
end

return fw
