local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.Parent.MockMemoryStoreUtils)

local MockMemoryStoreHashMap = {}
MockMemoryStoreHashMap.__index = MockMemoryStoreHashMap;

function MockMemoryStoreHashMap.new(name)
    return setmetatable({
        mapValues = {},
    }, MockMemoryStoreHashMap)
end

function MockMemoryStoreHashMap:GetAsync(key)
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    MockMemoryStoreQuota:ProcessReadRequest()

    local value = self.mapValues[key]
    if value then
        return value.innerValue
    else
        return nil
    end
end

function MockMemoryStoreHashMap:SetAsync(key, value, expiration)
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

function MockMemoryStoreHashMap:UpdateAsync(key, transformFunction, expiration)
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

function MockMemoryStoreHashMap:RemoveAsync(key)
    MockMemoryStoreQuota:ProcessWriteRequest()

    self.mapValues[key] = nil
end

function MockMemoryStoreHashMap:RemoveExpiringKey(key)
    self.mapValues[key] = nil
end

return MockMemoryStoreHashMap
