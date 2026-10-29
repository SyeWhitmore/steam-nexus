local vdf = require("storage.vdf")
local M = {}

local function join(root, suffix)
    return root:gsub("[\\/]+$", "") .. "/" .. suffix
end

local function parse_file(read, path)
    local source = read(path)
    assert(type(source) == "string", "Metadata unavailable")
    return vdf.parse(source)
end

local function valid_relative(path)
    if type(path) ~= "string" or path == "" or path:find('[%c:<>"|?*]') or path:match("^[\\/]") then return false end
    for segment in path:gmatch("[^\\/]+") do
        if segment == "." or segment == ".." then return false end
    end
    return true
end

function M.scan(steam_path, fs, read)
    assert(type(steam_path) == "string" and steam_path:match("^%a:[\\/]"), "Windows Steam path unavailable")
    local result = { available = true, games = {}, skippedLibraries = 0, skippedManifests = 0, metadataWarning = false }
    local libraries, seen = {}, {}
    local function add(path)
        if type(path) ~= "string" or not path:match("^%a:[\\/]") then return end
        local key = path:gsub("\\", "/"):gsub("/+$", ""):lower()
        if not seen[key] then
            seen[key] = true
            libraries[#libraries + 1] = path
        end
    end
    add(steam_path)
    local ok, folders = pcall(parse_file, read, join(steam_path, "steamapps/libraryfolders.vdf"))
    if ok and type(folders.libraryfolders) == "table" then
        for key, entry in pairs(folders.libraryfolders) do
            if key:match("^%d+$") then
                add(type(entry) == "table" and entry.path or entry)
            end
        end
    else
        result.metadataWarning = true
    end
    table.sort(libraries, function(a, b) return a:lower() < b:lower() end)
    for _, library in ipairs(libraries) do
        local listed, entries = pcall(fs.list, join(library, "steamapps"))
        if not listed or type(entries) ~= "table" then
            result.skippedLibraries = result.skippedLibraries + 1
        else
            for _, entry in ipairs(entries) do
                local app_id = type(entry.name) == "string" and entry.name:match("^appmanifest_(%d+)%.acf$")
                if app_id and entry.is_file then
                    local parsed, game = pcall(function()
                        local data = parse_file(read, join(library, "steamapps/" .. entry.name)).AppState
                        assert(type(data) == "table" and data.appid == app_id, "AppID mismatch")
                        assert(valid_relative(data.installdir), "Invalid install directory")
                        local flags = tonumber(data.StateFlags)
                        assert(flags and flags >= 0 and flags == math.floor(flags), "Invalid install state")
                        if math.floor(flags / 4) % 2 ~= 1 then return nil end
                        local path = join(library, "steamapps/common/" .. data.installdir)
                        if not fs.is_directory(path) then return nil end
                        return { appId = app_id, installPath = path:gsub("/", "\\"), drive = library:sub(1, 1):upper() .. ":" }
                    end)
                    if not parsed then
                        result.skippedManifests = result.skippedManifests + 1
                    elseif game and not result.games[app_id] then
                        result.games[app_id] = game
                    end
                end
            end
        end
    end
    return result
end

function M.cache(loader)
    local cached
    return {
        get = function()
            if not cached then cached = loader() end
            return cached
        end,
        clear = function() cached = nil end
    }
end

return M
