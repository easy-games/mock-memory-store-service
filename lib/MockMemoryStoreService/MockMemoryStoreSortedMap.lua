local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.Parent.MockMemoryStoreUtils)

type ItemData = {
	innerValue: any,
	expiration: number,
}

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

    local mapValue: ItemData = {
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

function MockMemoryStoreSortedMap:GetRangeAsync(direction: Enum.SortDirection, count: number, exclusiveLowerBound: string?, exclusiveUpperBound: string?)
	local keys: {[number]: string} = {}
	for k, v in pairs(self.mapValues) do
		table.insert(keys, k)
	end

	table.sort(keys, function(aKey: string, bKey: string): boolean
		local a: ItemData = self.mapValues[aKey]
		local b: ItemData = self.mapValues[bKey]
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
			table.insert(out, table.clone(self.mapValues[key]))
		end
		if key == exclusiveUpperBound then
			break
		end
	end

	return out
end

return MockMemoryStoreSortedMap