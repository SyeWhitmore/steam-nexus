local M = {}

function M.parse(source)
    assert(type(source) == "string" and #source <= 4 * 1024 * 1024, "Invalid VDF size")
    source = source:gsub("^\239\187\191", "")
    local position, length = 1, #source
    local function token()
        while position <= length do
            local char = source:sub(position, position)
            if char:match("%s") then
                position = position + 1
            elseif source:sub(position, position + 1) == "//" then
                position = (source:find("\n", position + 2, true) or length) + 1
            else
                break
            end
        end
        if position > length then return nil end
        local char = source:sub(position, position)
        position = position + 1
        if char == "{" or char == "}" then return char, "brace" end
        if char == '"' then
            local parts = {}
            while position <= length do
                char = source:sub(position, position)
                position = position + 1
                if char == '"' then return table.concat(parts), "string" end
                if char == "\\" then
                    assert(position <= length, "Unterminated escape")
                    local next_char = source:sub(position, position)
                    position = position + 1
                    if next_char == '"' or next_char == "\\" then
                        char = next_char
                    else
                        char = "\\" .. next_char
                    end
                end
                parts[#parts + 1] = char
            end
            error("Unterminated string")
        end
        local start = position - 1
        while position <= length and not source:sub(position, position):match('[%s{}"]') do
            position = position + 1
        end
        return source:sub(start, position - 1), "string"
    end
    local function object(nested, depth)
        assert(depth <= 64, "VDF nesting too deep")
        local result = {}
        while true do
            local key, kind = token()
            if key == nil then
                assert(not nested, "Missing closing brace")
                return result
            end
            if kind == "brace" and key == "}" then
                assert(nested, "Unexpected closing brace")
                return result
            end
            assert(kind == "string", "Expected key")
            assert(result[key] == nil, "Duplicate key")
            local value, value_kind = token()
            assert(value ~= nil, "Missing value")
            if value_kind == "brace" then
                assert(value == "{", "Expected value")
                value = object(true, depth + 1)
            end
            result[key] = value
        end
    end
    return object(false, 0)
end

return M
