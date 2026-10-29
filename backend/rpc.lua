local cjson = require("cjson")
local millennium = require("millennium")
local service = require("storage.service")

---@ffi
---@return string
function getInstallationsJson()
    if millennium.config.get("drive-indicators.enabled") == false then
        service.clear()
        return cjson.encode({ available = false, disabled = true, games = {} })
    end
    local ok, result = pcall(service.get)
    if not ok then
        return cjson.encode({ available = false, games = {}, error = "Storage metadata unavailable" })
    end
    return cjson.encode(result)
end

---@ffi
---@return string
function refreshInstallationsJson()
    service.clear()
    return getInstallationsJson()
end
