local phone = {}

---@param src number
---@param from number
---@param message string
function phone.sendMessage(src, from, message)
    local success = exports["meteo-phone"]:DispatchSMSToPlayer(src, tostring(from), message)
    return success
end

---@param src number
---@param from number
---@param coords vector3
function phone.sendCoords(src, from, coords)
    exports["meteo-phone"]:DispatchLocationToPlayer(src, tostring(from), coords)
end

---@param src number
---@param title string
---@param content? string
function phone.sendNotification(src, title, content)
    local phoneSerial = exports["meteo-phone"]:GetActivePhoneSerial(src)
    if not phoneSerial then return end
    exports["meteo-phone"]:SendNotificationToPhone(phoneSerial, title, "notifications", content or title, "normal")
end

return phone