local vdf = require("storage.vdf")
local installations = require("storage.installations")
local tests = {}

local function fixture()
    local files = {
        ["C:/Steam/steamapps/libraryfolders.vdf"] = [["libraryfolders" { "0" { "path" "C:\\Steam" } "1" { "path" "D:\\Games" } "2" { "path" "E:\\Missing" } }]],
        ["C:/Steam/steamapps/appmanifest_10.acf"] = [["AppState" { "appid" "10" "installdir" "Game A" "StateFlags" "4" }]],
        ["D:/Games/steamapps/appmanifest_20.acf"] = [["AppState" { "appid" "20" "installdir" "Game B" "StateFlags" "6" }]]
    }
    local directories = {
        ["C:/Steam/steamapps/common/Game A"] = true,
        ["D:/Games/steamapps/common/Game B"] = true
    }
    local function normalize(path) return path:gsub("\\", "/") end
    local fs = {
        list = function(path)
            path = normalize(path)
            if path == "E:/Missing/steamapps" then return nil, "Access denied" end
            local entries = {}
            for name in pairs(files) do
                if name:match("^(.*)/[^/]+$") == path then
                    entries[#entries + 1] = { name = name:match("[^/]+$"), is_file = true }
                end
            end
            return entries
        end,
        is_directory = function(path) return directories[normalize(path)] == true end
    }
    local function read(path) return files[normalize(path)] end
    return files, directories, fs, read
end

function tests.multiple_drives_and_inaccessible_library()
    local _, _, fs, read = fixture()
    local result = installations.scan("C:\\Steam", fs, read)
    assert(result.games["10"].drive == "C:")
    assert(result.games["20"].drive == "D:")
    assert(result.games["20"].installPath == "D:\\Games\\steamapps\\common\\Game B")
    assert(result.skippedLibraries == 1)
end

function tests.malformed_manifest_and_id_mismatch()
    local files, _, fs, read = fixture()
    files["C:/Steam/steamapps/appmanifest_10.acf"] = '"AppState" {'
    files["D:/Games/steamapps/appmanifest_20.acf"] = [["AppState" { "appid" "99" "installdir" "Game B" "StateFlags" "4" }]]
    local result = installations.scan("C:/Steam", fs, read)
    assert(next(result.games) == nil and result.skippedManifests == 2)
end

function tests.excludes_uninstalled_and_missing_directories()
    local files, dirs, fs, read = fixture()
    files["C:/Steam/steamapps/appmanifest_10.acf"] = [["AppState" { "appid" "10" "installdir" "Game A" "StateFlags" "1" }]]
    dirs["D:/Games/steamapps/common/Game B"] = nil
    assert(next(installations.scan("C:/Steam", fs, read).games) == nil)
end

function tests.rejects_path_traversal()
    local files, _, fs, read = fixture()
    files["C:/Steam/steamapps/appmanifest_10.acf"] = [["AppState" { "appid" "10" "installdir" "../escape" "StateFlags" "4" }]]
    local result = installations.scan("C:/Steam", fs, read)
    assert(result.games["10"] == nil and result.skippedManifests == 1)
end

function tests.falls_back_to_primary_library()
    local files, _, fs, read = fixture()
    files["C:/Steam/steamapps/libraryfolders.vdf"] = nil
    local result = installations.scan("C:/Steam", fs, read)
    assert(result.games["10"] and result.metadataWarning)
end

function tests.old_library_format_and_deduplication()
    local files, _, fs, read = fixture()
    files["C:/Steam/steamapps/libraryfolders.vdf"] = [[libraryfolders { 0 "c:/steam/" 1 "D:\\Games" }]]
    local result = installations.scan("C:/Steam", fs, read)
    assert(result.games["10"] and result.games["20"] and result.skippedManifests == 0)
end

function tests.parser_comments_escapes_and_empty_strings()
    local result = vdf.parse('\239\187\191// comment\r\n"root" { "key" "a\\\\b\\\"c" "empty" "" }')
    assert(result.root.key == 'a\\b"c' and result.root.empty == "")
    assert(vdf.parse('root { path "C:\\Games" }').root.path == 'C:\\Games')
end

function tests.parser_rejects_invalid_documents()
    for _, source in ipairs({ 'root {', 'root "unterminated', '}', 'root }', 'a b a c', 'a', '{ a b }' }) do
        assert(not pcall(vdf.parse, source), source)
    end
    assert(not pcall(vdf.parse, string.rep('x { ', 66) .. string.rep('}', 66)))
    assert(not pcall(vdf.parse, string.rep('x', 4 * 1024 * 1024 + 1)))
end

function tests.cache_refresh()
    local loads = 0
    local cache = installations.cache(function() loads = loads + 1; return { count = loads } end)
    assert(cache.get() == cache.get() and loads == 1)
    cache.clear()
    assert(cache.get().count == 2)
end

function tests.invalid_steam_location()
    local _, _, fs, read = fixture()
    assert(not pcall(installations.scan, nil, fs, read))
    assert(not pcall(installations.scan, "/linux/steam", fs, read))
end

function tests.backend_defaults_preserve_preferences_and_disabling_clears_cache()
    local saved = { ["drive-indicators.enabled"] = false, ["drive-indicators.format"] = "plain" }
    local clears, ready, listener = 0, false, nil
    package.loaded["millennium"] = {
        ready = function() ready = true end,
        config = {
            get = function(key) return saved[key] end,
            set = function(key, value) saved[key] = value end,
            on_change = function(callback) listener = callback end
        }
    }
    package.loaded["storage.service"] = { clear = function() clears = clears + 1 end }
    package.loaded["rpc"] = true
    package.loaded["main"] = nil
    local plugin = require("main")
    plugin.on_load()
    assert(ready and saved["drive-indicators.enabled"] == false)
    assert(saved["drive-indicators.format"] == "plain" and saved["drive-indicators.showPath"] == true)
    listener("unrelated", false)
    assert(clears == 0)
    listener("drive-indicators.enabled", false)
    plugin.on_unload()
    assert(clears == 2)
end

return tests
