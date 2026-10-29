local millennium = require("millennium")
local service = require("storage.service")
require("rpc")

local function on_load()
    local defaults = {
        ["drive-indicators.enabled"] = true,
        ["drive-indicators.format"] = "brackets",
        ["drive-indicators.showPath"] = true
    }
    for key, value in pairs(defaults) do
        if millennium.config.get(key) == nil then millennium.config.set(key, value) end
    end
    millennium.config.on_change(function(key, value)
        if key == "drive-indicators.enabled" and value == false then service.clear() end
    end)
    millennium.ready()
end

return { on_load = on_load, on_unload = service.clear }
