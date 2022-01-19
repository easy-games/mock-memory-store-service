local MockMemoryStoreSortedMap = {}
MockMemoryStoreSortedMap.__index = MockMemoryStoreSortedMap;

function MockMemoryStoreSortedMap.new(name)
    return setmetatable({
        __store = {}
    }, MockMemoryStoreSortedMap)
end

function MockMemoryStoreSortedMap:GetAsync(key)
    return self.__store[key].value
end

function MockMemoryStoreSortedMap:SetAsync(key, value, expiration)
    local value = {
        value = value,
        expiration = tick() + expiration
    }

    self.__store[key] = value
    return true
end

function MockMemoryStoreSortedMap:UpdateAsync(key, transformFunction, expiration)
    local oldValue = self.__store[key]

    local newValue = transformFunction(if oldValue then oldValue.value else nil)
    if newValue ~= nil then
        self:SetAsync(key, newValue, expiration)
        return newValue
    else
        return nil
    end
end

function MockMemoryStoreSortedMap:RemoveAsync(key)
    self.__store[key] = nil
end

local function sortPairsAscending(valueA, valueB)
    return utf8.codepoint(valueA[1]) < utf8.codepoint(valueB[1])
end

local function sortPairsDescending(valueA, valueB)
    return utf8.codepoint(valueA[1]) > utf8.codepoint(valueB[1])
end

function MockMemoryStoreSortedMap:GetRangeAsync(direction, count, exclusiveLowerBound, exclusiveUpperBound)
    assert(direction ~= nil)
    assert(count ~= nil)
    
    local keyPairs = {}
    for key, value in pairs(self.__store) do
        table.insert(keyPairs, {key, value})
    end

    if direction == Enum.SortDirection.Ascending then
        table.sort(keyPairs, sortPairsAscending)
    elseif direction == Enum.SortDirection.Descending then
        table.sort(keyPairs, sortPairsDescending)
    end
end

return MockMemoryStoreSortedMap