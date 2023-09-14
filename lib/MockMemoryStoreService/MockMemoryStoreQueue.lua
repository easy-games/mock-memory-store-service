--!strict
local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local ArrayUtil = require(script.Parent.ArrayUtil)

local HttpService = game:GetService("HttpService")

export type ItemData = {
	value: any,
	priority: number,
	expiration: number,
}

type RefData = {
	results: {[number]: any},
	timeout: number,
}

export type MockMemoryStoreQueue = {
	__index: MockMemoryStoreQueue,
	_Queue: {[number]: ItemData},
	_Refs: {[string]: RefData},
	_InvisibilityTimeout: number,
	new: (name: string, timeout: number?) -> (),
	_HandleTimeouts: (self: MockMemoryStoreQueue) -> (),
	ReadAsync: (self: MockMemoryStoreQueue, count: number, allOrNothing: boolean?, waitTimeout: number?) -> ({[number]: any?}, string),
	RemoveAsync: (self: MockMemoryStoreQueue, key: string) -> (),
	AddAsync: (self: MockMemoryStoreQueue, value: any, expirationSeconds: number, priority: number?) -> (),
	_GetRef: (self: MockMemoryStoreQueue, key: string) -> RefData?,
	_AddAsync: (self: MockMemoryStoreQueue, item: ItemData) -> (),
}

local MockMemoryStoreQueue = {} :: MockMemoryStoreQueue
MockMemoryStoreQueue.__index = MockMemoryStoreQueue;

function MockMemoryStoreQueue.new(name: string, timeout: number?)
	local self: MockMemoryStoreQueue = setmetatable({}, MockMemoryStoreQueue) :: any
	self._Queue = {}
	self._Refs = {}
	self._InvisibilityTimeout = timeout or 30
	return self
end

function MockMemoryStoreQueue:_GetRef(id: string): RefData?
    return self._Refs[id]
end

function MockMemoryStoreQueue:ReadAsync(count: number, allOrNothing: boolean?, waitTimeout: number?): ({[number]: any?}, string)
    assert(typeof(count) == "number", "Expected count (number)")
    assert(count < 100 and count >= 0, "Expected count of 0 - 100")
    allOrNothing = if allOrNothing then allOrNothing else false
    waitTimeout = if waitTimeout then waitTimeout else -1

    assert(type(allOrNothing) == "boolean")
    assert(type(waitTimeout) == "number")

    MockMemoryStoreQuota:ProcessReadRequest()

    local t = 0
    repeat
        print("yield", t);
        t += task.wait()
    until (waitTimeout ~= -1 and t >= waitTimeout) or (not allOrNothing or #self._Queue >= count)

    local queueCount = #self._Queue

    local results = table.move(self._Queue, queueCount + 1 - count, queueCount, 1, {})
    local refId = HttpService:GenerateGUID(false)

    self._Queue = table.move(self._Queue, 1, #self._Queue - count, 1, {})
    self._Refs[refId] = {
        results = results,
        timeout = tick() + self._InvisibilityTimeout
    }

    local mapped: {[number]: any?} = ArrayUtil.Map(results, function(v: ItemData): any?
        return v.value
    end)

    return mapped, refId--, { time = t, queue = self._Queue, refs = self._Refs }
end

function MockMemoryStoreQueue:_HandleTimeouts(): ()
    -- Remove expired values in queue
    for index, value in ipairs(self._Queue) do
        if value.expiration < tick() then
            table.remove(self._Queue, index)
        end
    end

    -- Push any timed out values back into queue if not used
    for index, value in pairs(self._Refs) do
        if value.timeout < tick() then
            self._Refs[index] = nil
            for _, result in pairs(value.results) do
                self:_AddAsync(result)
            end
        end
    end
end

function MockMemoryStoreQueue:RemoveAsync(ref: string)
    MockMemoryStoreQuota:ProcessWriteRequest()

    local valueRef = self._Refs[ref]
    if valueRef then
        self._Refs[ref] = nil
    end
end

function MockMemoryStoreQueue:_AddAsync(item: ItemData)
    -- First index, since FIFO
    table.insert(self._Queue, 1, item)

    table.sort(self._Queue, function(a: ItemData, b: ItemData): boolean
        return a.priority > b.priority
    end)
end

function MockMemoryStoreQueue:AddAsync(value: any, expirationSeconds: number, priority: number?)
    assert(typeof(expirationSeconds) == "number", "Expected 'expirationSeconds' (number) at argument #2")

    MockMemoryStoreQuota:ProcessWriteRequest()
    self:_AddAsync({
        value = value,
        expiration = tick() + expirationSeconds,
        priority = priority or 3
    })
end

return MockMemoryStoreQueue