local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.Parent.MockMemoryStoreUtils)

local MockMemoryStoreSortedMap = {}
MockMemoryStoreSortedMap.__index = MockMemoryStoreSortedMap;

function MockMemoryStoreSortedMap.new(name)
    return setmetatable({
        mapValues = {},
    }, MockMemoryStoreSortedMap)
end

function MockMemoryStoreSortedMap:GetAsync(key)
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    MockMemoryStoreQuota:ProcessReadRequest()

    local value = self.mapValues[key]
    if value then
        return value.innerValue
    else
        return nil
    end
end

function MockMemoryStoreSortedMap:SetAsync(key, value, expiration)
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    assert(expiration, "Expiration required")

    assert(expiration <= MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS, "Exceeds max expiration time")

    local mapValue = {
        innerValue = value,
        expiration = tick() + expiration
    }

    MockMemoryStoreQuota:ProcessWriteRequest()
    local isExistingItem = self.mapValues[key] ~= nil
    self.mapValues[key] = mapValue

    return isExistingItem
end

function MockMemoryStoreSortedMap:UpdateAsync(key, transformFunction, expiration)
    assert(typeof(key) == "string", "Expects key (argument #1)")
    assert(typeof(transformFunction) == "function", "Expects transformFunction (argument #2)")
    assert(typeof(expiration) == "number", "Expects expiration (argument #3)")

    local oldValue = self:GetAsync(key)

    local newValue = transformFunction(oldValue)
    if newValue ~= nil then
        self:SetAsync(key, newValue, expiration)
        return newValue
    else
        return nil
    end
end

function MockMemoryStoreSortedMap:RemoveAsync(key)
    MockMemoryStoreQuota:ProcessWriteRequest()

    self.mapValues[key] = nil
end

function MockMemoryStoreSortedMap:RemoveExpiringKey(key)
    self.mapValues[key] = nil
end

function MockMemoryStoreSortedMap:GetRangeAsync(direction, count, exclusiveLowerBound, exclusiveUpperBound)
    error("Not yet implemented", 2)
end

return MockMemoryStoreSortedMap