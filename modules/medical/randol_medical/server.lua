local medical = {}

--- Source: https://randolio.gitbook.io/docs/paid-scripts/medical/exports

---@param src number | string
---@param amount number
function medical.healPlayer(src, amount)
    exports['randol_medical']:Heal(src)
end

return medical
