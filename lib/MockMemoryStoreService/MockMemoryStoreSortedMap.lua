--!strict
local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.Parent.MockMemoryStoreUtils)

export type ItemData = {
	innerValue: any,
	key: string,
	expiration: number,
}

export type MockMemoryStoreSortedMap = {
	__index: MockMemoryStoreSortedMap,
	_MapValues: {[string]: ItemData},
	new: (name: string) -> (),
	GetAsync: (self: MockMemoryStoreSortedMap, key: string) -> ItemData?,
	SetAsync: (self: MockMemoryStoreSortedMap, key: string, value: any?, expiration: number?) -> boolean,
	UpdateAsync: (self: MockMemoryStoreSortedMap, key: string, transformFunction: (v: any) -> any?, expiration: number?) -> any?,
	RemoveAsync: (self: MockMemoryStoreSortedMap, key: string) -> (),
	GetRangeAsync: (self: MockMemoryStoreSortedMap, direction: Enum.SortDirection, count: number, exclusiveLowerBound: string?, exclusiveUpperBound: string?) -> {[number]: ItemData},
	_RemoveExpiringKey: (self: MockMemoryStoreSortedMap, key: string) -> (),
}

local MockMemoryStoreSortedMap = {} :: MockMemoryStoreSortedMap
MockMemoryStoreSortedMap.__index = MockMemoryStoreSortedMap;

function MockMemoryStoreSortedMap.new(name: string)
    return setmetatable({
        mapValues = {},
    }, MockMemoryStoreSortedMap)
end

function MockMemoryStoreSortedMap:GetAsync(key: string): ItemData?
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    MockMemoryStoreQuota:ProcessReadRequest()

    local value = self._MapValues[key]
    if value then
        return value.innerValue
    else
        return nil
    end
end

function MockMemoryStoreSortedMap:SetAsync(key: string, value: any?, expiration: number?): boolean
    MockMemoryStoreUtils.AssertKeyIsValid(key)
    assert(expiration, "Expiration required")

    assert(expiration <= MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS, "Exceeds max expiration time")

    local mapValue: ItemData = {
        innerValue = value,
	   key = key,
        expiration = tick() + expiration
    }

    MockMemoryStoreQuota:ProcessWriteRequest()
    local isExistingItem = self._MapValues[key] ~= nil
    self._MapValues[key] = mapValue

    return isExistingItem
end

function MockMemoryStoreSortedMap:UpdateAsync(key: string, transformFunction: (any) -> any?, expiration: number?): any?
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

function MockMemoryStoreSortedMap:RemoveAsync(key: string): ()
    MockMemoryStoreQuota:ProcessWriteRequest()

    self._MapValues[key] = nil
end

function MockMemoryStoreSortedMap:_RemoveExpiringKey(key: string): ()
    self._MapValues[key] = nil
end

function MockMemoryStoreSortedMap:GetRangeAsync(direction: Enum.SortDirection, count: number, exclusiveLowerBound: string?, exclusiveUpperBound: string?)
	local keys: {[number]: string} = {}
	for k, v in pairs(self._MapValues) do
		table.insert(keys, k)
	end

	table.sort(keys, function(aKey: string, bKey: string): boolean
		local a: ItemData = self._MapValues[aKey]
		local b: ItemData = self._MapValues[bKey]
		if direction == Enum.SortDirection.Ascending then
			return a.innerValue < b.innerValue
		else
			return a.innerValue > b.innerValue
		end
	end)

	local out: {[number]: ItemData} = {}
	local isPastLowerBound = if exclusiveLowerBound == nil then true else false
	for i, key in ipairs(keys) do
		if key == exclusiveLowerBound then
			isPastLowerBound = true
		end
		if #out >= count then
			break
		end
		if isPastLowerBound then
			table.insert(out, table.clone(self._MapValues[key]))
		end
		if key == exclusiveUpperBound then
			break
		end
	end

	return out
end

return MockMemoryStoreSortedMap