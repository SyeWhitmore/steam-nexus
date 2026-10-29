local fs = require("fs")
local millennium = require("millennium")
local installations = require("storage.installations")

local function read(path)
    local file = assert(io.open(path, "rb"))
    local ok, text = pcall(file.read, file, 4 * 1024 * 1024 + 1)
    file:close()
    assert(ok, "Metadata read failed")
    return text
end

return installations.cache(function()
    return installations.scan(millennium.steam_path(), fs, read)
end)
