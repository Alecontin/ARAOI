---@class TableUtils
local TableUtils = {}


---@param t table
---@return integer
function TableUtils.FindFirstInstanceInTable(value, t)
    for i, item in ipairs(t) do
        if value == item then
            return i
        end
    end

    return 0
end


---@param t table
---@return boolean
function TableUtils.IsValueInTable(value, t)
    for _, item in ipairs(t) do
        if value == item then
            return true
        end
    end

    return false
end


---@param t table
---@return table
function TableUtils.Keys(t)
    local keys = {}

    for key,_ in pairs(t) do
        table.insert(keys, key)
    end

    return keys
end

---@param t table
---@return table
function TableUtils.Values(t)
    local values = {}

    for _,value in ipairs(t) do
        table.insert(values, value)
    end

    return values
end

---@param t table
---@return table, table
function TableUtils.KeysAndValues(t)
    local keys = {}
    local values = {}

    for key,value in pairs(t) do
        table.insert(keys, key)
        table.insert(values, value)
    end

    return keys, values
end

---@param t table
---@return table
function TableUtils.ShallowCopy(t)
    local new = {}

    for i,v in pairs(t) do
        new[i] = v
    end

    return new
end

---@param t table
---@param weights? table
---@param rng? RNG
---@return any
function TableUtils.Choice(t, weights, rng)
    if rng == nil then
        rng = RNG()
        rng:SetSeed(math.random(99999999999))
    end

    -- If weights are not provided, initialize equal weights
    if weights == nil then
        weights = {}
        for i = 1, #t do
            weights[i] = 1
        end
    end

    -- Normalize the weights to avoid precision issues
    local weight_sum = 0
    for _, weight in ipairs(weights) do
        weight_sum = weight_sum + weight
    end

    -- Compute the cumulative sum of normalized weights
    local cumulative_weights = {}
    local cumulative_sum = 0
    for i, weight in ipairs(weights) do
        cumulative_sum = cumulative_sum + (weight / weight_sum)
        cumulative_weights[i] = cumulative_sum
    end

    -- Generate a random number in the range [0, 1)
    local random_number = rng:RandomFloat()

    -- Find the index corresponding to the random number
    for i, cumulative_weight in ipairs(cumulative_weights) do
        if random_number < cumulative_weight then
            return t[i]
        end
    end
end

-- Splits a table into a number of tables
function TableUtils.SplitTable(t, num_sublists)
    local sublists = {}
    for _ = 1, num_sublists do
        table.insert(sublists, {})
    end

    for i, item in ipairs(t) do
        local sublist_index = ((i - 1) % num_sublists) + 1
        table.insert(sublists[sublist_index], item)
    end

    return sublists
end

---@param rng? RNG
function TableUtils.ShuffleTable(t, rng)
    local n = #t
    for i = n, 2, -1 do
        local j
        if rng then
            j = rng:RandomInt(1, i)
        else
            j = math.random(i)
        end
        t[i], t[j] = t[j], t[i]
    end
end

-- Splits a string into a list of strings
function TableUtils.SplitStr(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function TableUtils.Join(t, sep)
    if sep == nil then
        sep = " "
    end
    local str = ""
    for i, v in ipairs(t) do
        if i > 0 then
            str = str..sep
        end
        str = str..v
    end
    return str
end

return TableUtils