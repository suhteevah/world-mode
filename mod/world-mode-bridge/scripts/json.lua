-- json.lua — Minimal JSON encoder for Factorio mods
-- Based on rxi/json.lua (MIT license), stripped to essentials.
-- Factorio RCON needs JSON output. We only need encode() for state serialization.

local json = {}

local encode_value -- forward declaration

local function encode_string(val)
    return '"' .. val:gsub('[\\"]', '\\%0')
                     :gsub('\n', '\\n')
                     :gsub('\r', '\\r')
                     :gsub('\t', '\\t')
                     :gsub('[\x00-\x1f]', function(c)
                         return string.format('\\u%04x', c:byte())
                     end) .. '"'
end

local function encode_table(val)
    -- Detect array vs object
    local is_array = true
    local max_index = 0
    for k, _ in pairs(val) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
            is_array = false
            break
        end
        if k > max_index then max_index = k end
    end
    -- Also check for sparse arrays
    if is_array and max_index ~= #val then
        is_array = false
    end

    local parts = {}
    if is_array then
        for i = 1, #val do
            table.insert(parts, encode_value(val[i]))
        end
        return '[' .. table.concat(parts, ',') .. ']'
    else
        for k, v in pairs(val) do
            local key = type(k) == "string" and k or tostring(k)
            table.insert(parts, encode_string(key) .. ':' .. encode_value(v))
        end
        return '{' .. table.concat(parts, ',') .. '}'
    end
end

encode_value = function(val)
    local t = type(val)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "number" then
        if val ~= val then return "null" end  -- NaN
        if val == math.huge or val == -math.huge then return "null" end
        -- Use integer format when possible
        if math.floor(val) == val and val < 2^53 and val > -2^53 then
            return string.format("%d", val)
        end
        return string.format("%.14g", val)
    elseif t == "string" then
        return encode_string(val)
    elseif t == "table" then
        return encode_table(val)
    else
        return '"[' .. t .. ']"'
    end
end

function json.encode(val)
    return encode_value(val)
end

return json
