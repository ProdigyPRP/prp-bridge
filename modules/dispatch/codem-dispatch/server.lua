local dispatch = {}

--- Source: https://codem.gitbook.io/codem-documentation/m-series/essentials/mmdt-aio/dispatch

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    exports['codem-dispatch']:CustomDispatch({
        type = data.code or 'General',
        header = data.title,
        text = data.description,
        code = data.code,
    })
end

return dispatch
