local fw = {}

local STATUS_HUNGER <const> = "PLAYER_HUNGER"
local STATUS_THIRST <const> = "PLAYER_THIRST"
local STATUS_STRESS <const> = "PLAYER_STRESS"
local TEXT_UI_ID <const> = "prp-bridge-textui"

local textUiOpen = false
local textUiMessage = nil
local contextMenus = {}
local contextActions = {}
local confirmPromise = nil
local inputPromise = nil
local inputEventToken = 0

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

---@param notifType string
---@return string
local function mapNotifyType(notifType)
    if notifType == "inform" then
        return "info"
    end
    return notifType or "info"
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
    local text = message or ""
    if title and title ~= "" then
        text = ("%s: %s"):format(title, text)
    end

    exports["sandbox-hud"]:Notification(mapNotifyType(type), text, duration or 3000)
end

---@param text string
---@param options? { position?: ShowTextUIPos, icon?: string | table<string>, iconColor?: string, iconAnimation?: ShowTextUIAnims, alignIcon?: "top" | "center" }
function fw.showTextUI(text, options)
    textUiOpen = true
    textUiMessage = text
    exports["sandbox-hud"]:ActionShow(TEXT_UI_ID, text or "")
end

function fw.hideTextUI()
    textUiOpen = false
    textUiMessage = nil
    exports["sandbox-hud"]:ActionHide(TEXT_UI_ID)
end

---@return boolean
---@return string | nil
function fw.isTextUIOpen()
    return textUiOpen, textUiMessage
end

---@param payload FWProgressBar
---@return boolean?
function fw.progressBar(payload)
    local p = promise.new()
    local action = {
        name = "prp-bridge-progress",
        duration = payload.duration or 5000,
        label = payload.label or "",
        useWhileDead = payload.useWhileDead or false,
        canCancel = payload.canCancel or false,
        controlDisables = {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false,
        },
    }

    if payload.controlDisables then
        action.controlDisables.disableMovement = payload.controlDisables.disableMovement or false
        action.controlDisables.disableCarMovement = payload.controlDisables.disableCarMovement or false
        action.controlDisables.disableMouse = payload.controlDisables.disableMouse or false
        action.controlDisables.disableCombat = payload.controlDisables.disableCombat or false
    end

    if payload.animation and payload.animation.animDict and payload.animation.animClip then
        action.animation = {
            animDict = payload.animation.animDict,
            anim = payload.animation.animClip,
            flags = payload.animation.animFlag,
        }
    elseif payload.animation and payload.animation.scenario then
        action.animation = {
            task = payload.animation.scenario,
        }
    end

    exports["sandbox-hud"]:Progress(action, function(cancelled)
        p:resolve(not cancelled)
    end)

    return Citizen.Await(p)
end

---@param header string
---@param content string
---@param labels? {cancel?: string, confirm?: string}
---@param timeout? number Force the window to timeout after `x` milliseconds.
---@return 'cancel'|'confirm'|nil
function fw.confirmDialog(header, content, labels, timeout)
    if confirmPromise then
        exports["sandbox-hud"]:ConfirmClose()
        confirmPromise:resolve("cancel")
        confirmPromise = nil
    end

    confirmPromise = promise.new()
    local labelSet = labels or {}

    exports["sandbox-hud"]:ConfirmShow(
        header,
        {
            yes = "prp-bridge:sandbox:confirmYes",
            no = "prp-bridge:sandbox:confirmNo",
        },
        content,
        {},
        labelSet.cancel or locale("Cancel"),
        labelSet.confirm or locale("Confirm")
    )

    if timeout and timeout > 0 then
        SetTimeout(timeout, function()
            if confirmPromise then
                exports["sandbox-hud"]:ConfirmClose()
                confirmPromise:resolve(nil)
                confirmPromise = nil
            end
        end)
    end

    return Citizen.Await(confirmPromise)
end

---@param heading string
---@param rows string[] | InputDialogRowProps[]
---@param options InputDialogOptionsProps[]?
---@return string[] | number[] | boolean[] | nil
function fw.inputDialog(heading, rows, options)
    if inputPromise then
        exports["sandbox-hud"]:InputClose()
        inputPromise:resolve(nil)
        inputPromise = nil
    end

    inputPromise = promise.new()
    inputEventToken = inputEventToken + 1
    local token = inputEventToken
    local eventName = ("prp-bridge:sandbox:input:%s"):format(token)
    local inputs = {}
    local order = {}

    for i, row in ipairs(rows or {}) do
        local id = ("field_%s"):format(i)
        local input

        if type(row) == "string" then
            input = {
                id = id,
                type = "text",
                label = row,
                options = {},
            }
        else
            id = row.name or id
            local rowType = row.type or "input"
            local mappedType = "text"
            if rowType == "number" then
                mappedType = "number"
            elseif rowType == "textarea" or rowType == "multiline" then
                mappedType = "multiline"
            end

            input = {
                id = id,
                type = mappedType,
                label = row.label or id,
                options = {
                    disabled = row.disabled == true,
                    value = row.default,
                    inputProps = {},
                },
            }

            if row.min ~= nil then
                input.options.inputProps.min = row.min
            end
            if row.max ~= nil then
                input.options.inputProps.max = row.max
            end
            if row.password then
                input.options.inputProps.type = "password"
            end
        end

        inputs[#inputs + 1] = input
        order[#order + 1] = id
    end

    local function resolveInput(result)
        if not inputPromise or token ~= inputEventToken then
            return
        end
        local pending = inputPromise
        inputPromise = nil
        pending:resolve(result)
    end

    local submitHandler
    submitHandler = AddEventHandler(eventName, function(values)
        RemoveEventHandler(submitHandler)
        local result = {}
        for i = 1, #order do
            result[i] = values and values[order[i]] or nil
        end
        resolveInput(result)
    end)

    local closeHandler
    closeHandler = AddEventHandler("Input:Closed", function(closedEvent)
        if closedEvent ~= eventName then
            return
        end
        RemoveEventHandler(closeHandler)
        if submitHandler then
            RemoveEventHandler(submitHandler)
        end
        resolveInput(nil)
    end)

    exports["sandbox-hud"]:InputShow(heading, heading, inputs, eventName, {})
    return Citizen.Await(inputPromise)
end

---@param options table
---@return table
local function optionsAsArray(options)
    if not options then
        return {}
    end

    if options[1] ~= nil then
        return options
    end

    local arr = {}
    for _, opt in pairs(options) do
        arr[#arr + 1] = opt
    end
    return arr
end

---@param payload FWContextMenuProps | FWContextMenuProps[]
function fw.contextMenu(payload)
    local menus = payload
    if payload.id then
        menus = { payload }
    end

    for _, menu in ipairs(menus) do
        if menu and menu.id then
            contextMenus[menu.id] = menu
        end
    end
end

---@param contextId string
function fw.showContext(contextId)
    local root = contextMenus[contextId]
    if not root then
        return
    end

    contextActions = {}
    local menus = {}
    local visited = {}

    local function addMenu(id, asMain)
        if visited[id] then
            return
        end

        local menu = contextMenus[id]
        if not menu then
            return
        end

        visited[id] = true
        local key = asMain and "main" or id
        local items = {}

        for index, opt in ipairs(optionsAsArray(menu.options)) do
            local item = {
                label = opt.title or ("Option %s"):format(index),
                description = opt.description,
                disabled = opt.disabled == true or opt.readOnly == true,
            }

            if opt.menu then
                item.submenu = opt.menu
                addMenu(opt.menu, false)
            elseif opt.onSelect or opt.event or opt.serverEvent then
                local actionId = ("%s:%s"):format(id, index)
                contextActions[actionId] = {
                    onSelect = opt.onSelect,
                    event = opt.event,
                    serverEvent = opt.serverEvent,
                    args = opt.args,
                }
                item.event = "prp-bridge:sandbox:listSelect"
                item.data = { actionId = actionId }
            end

            items[#items + 1] = item
        end

        menus[key] = {
            label = menu.title or id,
            items = items,
        }
    end

    addMenu(contextId, true)
    exports["sandbox-hud"]:ListMenuShow(menus)
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

AddEventHandler("prp-bridge:sandbox:confirmYes", function()
    if not confirmPromise then
        return
    end
    local pending = confirmPromise
    confirmPromise = nil
    pending:resolve("confirm")
end)

AddEventHandler("prp-bridge:sandbox:confirmNo", function()
    if not confirmPromise then
        return
    end
    local pending = confirmPromise
    confirmPromise = nil
    pending:resolve("cancel")
end)

AddEventHandler("prp-bridge:sandbox:listSelect", function(data)
    local action = data and contextActions[data.actionId]
    if not action then
        return
    end

    if action.onSelect then
        action.onSelect(action.args)
    end
    if action.event then
        TriggerEvent(action.event, action.args)
    end
    if action.serverEvent then
        TriggerServerEvent(action.serverEvent, action.args)
    end
end)

if bridge.name == bridge.currentResource then
    RegisterNetEvent("Characters:Client:Spawn", function()
        TriggerEvent("prp-bridge:client:playerLoad")
    end)

    RegisterNetEvent("Characters:Client:Logout", function()
        textUiOpen = false
        textUiMessage = nil
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
