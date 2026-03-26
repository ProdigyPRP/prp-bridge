local dispatch = {}

--- Source: https://forum.cfx.re/t/aty-disptach-advanced-disptach-system-free/5150150

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    TriggerEvent("aty_dispatch:server:customDispatch",
        data.title or "Alert",
        data.code or "10-11",
        { street = "", road = "" },
        coords,
        nil,
        nil,
        nil,
        nil,
        blip.sprite,
        jobs
    )
end

return dispatch
