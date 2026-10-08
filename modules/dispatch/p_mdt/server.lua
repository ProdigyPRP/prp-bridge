local dispatch = {}

---@param src number | string
---@param coords vector3
---@param jobs string[]
---@param data AlertData
---@param blip AlertBlip
---@param alertFlash? boolean
function dispatch.sendAlert(src, jobs, coords, data, blip, alertFlash)
    exports["p_mdt"]:CreateAlert({
        title = data.title,
        description = data.description,
        priority = alertFlash and "high" or "medium",
        coords = coords,
        code = data.code,
        jobs = jobs,
        blip = blip and {
            sprite = blip.sprite,
            color = blip.colour,
            scale = blip.scale,
            shortRange = true,
            pulseBlip = blip.flash or alertFlash or false,
            name = blip.text or data.title,
        } or nil,
        alertTime = (data.length or blip?.length or 3) * 60, -- in seconds
        -- p_mdt plays its own sounds from `web/assets/sounds/<name>.mp3`
        sound = data.sound?.alert?.sound or data.sound?.name,
        playerId = src,
    })
end

return dispatch
