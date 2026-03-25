local dispatch = {}

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    -- Source: https://docs.lbscripts.com/tablet/script-integration/server-exports/
    for i = 1, #jobs do
        exports["lb-tablet"]:AddDispatch({
            priority = "high",
            code = data.code,
            title = data.title,
            description = data.description,
            location = {
                label = blip.text or data.title,
                coords = vec2(coords.x, coords.y),
            },
            time = (data.length or blip.length or 5) * 60,
            job = jobs[i],
            blip = {
                sprite = blip.sprite,
                color = blip.colour,
                size = blip.scale,
                label = blip.text,
            },
        })
    end
end

return dispatch
