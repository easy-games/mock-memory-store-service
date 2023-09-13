--!strict
local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.Parent.MockMemoryStoreUtils)

export type ItemData = {
	innerValue: any,
	key: string,
	expiration: number,
}

export type MockMemoryStoreHashMap = {
	__index: MockMemoryStoreHashMap,
	_MapValues: {[string]: ItemData},
	new: (name: string) -> (),
	GetAsync: (self: MockMemoryStoreHashMap, key: string) -> ItemData?,
	SetAsync: (self: MockMemoryStoreHashMap, key: string, value: any?, expiration: number?) -> boolean,
	UpdateAsync: (self: MockMemoryStoreHashMap, key: string, transformFunction: (v: any) -> any?, expiration: number?) -> any?,
	RemoveAsync: (self: MockMemoryStoreHashMap, key: string) -> (),
	_RemoveExpiringKey: (self: MockMemoryStoreHashMap, key: string) -> (),
}


local MockMemoryStoreHashMap = {} :: MockMemoryStoreHashMap
MockMemoryStoreHashMap.__index = MockMemoryStoreHashMap;

function MockMemoryStoreHashMap.new(name: string): ()
	local self: MockMemoryStoreHashMap = setmetatable({}, MockMemoryStoreHashMap) :: any
	self._MapValues = {}
	return self
end

function MockMemoryStoreHashMap:GetAsync(key: string): ItemData?
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    MockMemoryStoreQuota:ProcessReadRequest()

    local value = self.mapValues[key]
    if value then
        return value.innerValue
    else
        return nil
    end
end

function MockMemoryStoreHashMap:SetAsync(key: string, value, expiration)
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    assert(expiration, "Expiration required")

    assert(expiration <= MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS, "Exceeds max expiration time")

    local mapValue = {
        innerValue = value,
	   key = key,
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

function MockMemoryStoreHashMap:_RemoveExpiringKey(key)
    self.mapValues[key] = nil
end

return MockMemoryStoreHashMap
