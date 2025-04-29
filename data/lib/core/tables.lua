-- Table Utility Functions for Lua

-- Section: Table Manipulation

-- Alias for table.insert
function table.append(t, value)
    if type(t) ~= "table" then
        error("table.append: Expected table, got " .. type(t))
    end
    table.insert(t, value)
end

-- Check if a table is empty
-- @param t: The table to check
-- @return: True if empty, false otherwise
function table.isEmpty(t)
    if type(t) ~= "table" then
        return true
    end
    return next(t) == nil
end

-- Find the key of a value in a table
-- @param t: The table to search
-- @param value: The value to find
-- @return: The key (index) of the value, or nil if not found
function table.find(t, value)
    if type(t) ~= "table" then
        return nil
    end
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
    return nil
end

-- Count occurrences of a value in a table
-- @param t: The table to search
-- @param value: The value to count
-- @return: The number of occurrences
function table.count(t, value)
    if type(t) ~= "table" then
        return 0
    end
    local count = 0
    for _, v in pairs(t) do
        if v == value then
            count = count + 1
        end
    end
    return count
end

-- Generate all combinations of a table's elements
-- @param t: The input table
-- @param num: The number of elements in each combination
-- @return: A table containing all combinations
function table.getCombinations(t, num)
    if type(t) ~= "table" then
        error("table.getCombinations: Expected table, got " .. type(t))
    end
    if type(num) ~= "number" or num < 1 or num > #t then
        error("table.getCombinations: Invalid number of elements, got " .. tostring(num))
    end

    local result = {}
    local indices = {}
    for i = 1, num do
        indices[i] = i
    end

    while true do
        -- Generate current combination
        local combination = {}
        for i = 1, num do
            combination[i] = t[indices[i]]
        end
        table.insert(result, combination)

        -- Move to next combination
        local i = num
        while i >= 1 and indices[i] == #t - num + i do
            i = i - 1
        end

        if i < 1 then
            break
        end

        indices[i] = indices[i] + 1
        for j = i + 1, num do
            indices[j] = indices[i] + j - i
        end
    end

    return result
end

-- Section: String Operations on Tables

-- Check if a string contains any of the substrings in a table
-- @param txt: The string to search
-- @param substrings: A table of substrings to find
-- @return: True if any substring is found as a whole word, false otherwise
function table.stringContains(txt, substrings)
    if type(txt) ~= "string" or type(substrings) ~= "table" then
        return false
    end

    for _, substring in ipairs(substrings) do
        if type(substring) == "string" then
            -- Use word boundaries to ensure whole-word matching
            if txt:find("%f[%w]" .. substring .. "%f[%W]") then
                return true
            end
        end
    end
    return false
end

-- Alias for stringContains
table.isStringIn = table.stringContains

-- Section: Serialization

-- Serialize a value to a Lua string representation
-- @param x: The value to serialize
-- @param recur: Internal table to track recursive references (optional)
-- @return: The serialized string
function table.serialize(x, recur)
    recur = recur or {}
    local t = type(x)

    if t == "nil" then
        return "nil"
    elseif t == "string" then
        return string.format("%q", x)
    elseif t == "number" then
        return tostring(x)
    elseif t == "boolean" then
        return x and "true" or "false"
    elseif t == "table" then
        if getmetatable(x) then
            error("table.serialize: Cannot serialize a table with a metatable")
        end
        if table.find(recur, x) then
            error("table.serialize: Cannot serialize recursive tables")
        end
        table.insert(recur, x)

        local s = "{"
        local first = true
        for k, v in pairs(x) do
            if not first then
                s = s .. ","
            end
            first = false
            s = s .. "[" .. table.serialize(k, recur) .. "]=" .. table.serialize(v, recur)
        end
        s = s .. "}"
        table.remove(recur) -- Clean up recursion tracking
        return s
    else
        error("table.serialize: Cannot serialize value of type '" .. t .. "'")
    end
end

-- Deserialize a Lua string to a value
-- @param str: The serialized string
-- @return: The deserialized value or nil on failure
function table.unserialize(str)
    if type(str) ~= "string" or str == "" then
        print("[Warning] table.unserialize: Invalid input string")
        return nil
    end

    local func, err = load("return " .. str)
    if not func then
        print("[Error] table.unserialize: Failed to parse string: " .. tostring(err))
        return nil
    end

    local success, result = pcall(func)
    if not success then
        print("[Error] table.unserialize: Failed to execute: " .. tostring(result))
        return nil
    end

    return result
end