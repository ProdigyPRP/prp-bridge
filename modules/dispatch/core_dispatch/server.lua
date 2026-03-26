local dispatch = {}

--- Source: https://docs.c8re.store/core-dispatch/api

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    for _, job in pairs(jobs) do
        exports['core_dispatch']:sendAlert({
            code = data.code,
            message = data.description,
            extraInfo = {},
            coords = coords,
            priority = alertFlash or false,
            job = job,
            time = (data.length or blip.length or 5) * 60000,
            blip = blip.sprite,
            color = blip.colour,
        })
    end
end

return dispatch
