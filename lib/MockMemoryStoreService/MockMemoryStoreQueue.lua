local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)
local ArrayUtil = require(script.Parent.ArrayUtil)

local httpService = game:GetService("HttpService")

local MockMemoryStoreQueue = {}
MockMemoryStoreQueue.__index = MockMemoryStoreQueue;

type Value = {
    value: any,
    priority: number,
    expiration: number,
}

function MockMemoryStoreQueue.new(name: string, timeout: number)
    return setmetatable({
        queue = {},
        refs = {},
        invisibilityTimeout = timeout or 30
    }, MockMemoryStoreQueue)
end

function MockMemoryStoreQueue:GetRef(id)
    return self.refs[id]
end

function MockMemoryStoreQueue:ReadAsync(count: number, allOrNothing: boolean?, waitTimeout: number?)
    assert(typeof(count) == "number", "Expected count (number)")
    assert(count < 100 and count >= 0, "Expected count of 0 - 100")
    allOrNothing = if allOrNothing then allOrNothing else false
    waitTimeout = if waitTimeout then waitTimeout else -1

    assert(type(allOrNothing) == "boolean")
    assert(type(waitTimeout) == "number")

    MockMemoryStoreQuota:ProcessReadRequest()

    local time = 0
    repeat
        print("yield", time);
        time += task.wait()
    until (waitTimeout == -1 or time >= waitTimeout) and (not allOrNothing or #self.queue >= count)

    local queueCount = #self.queue

    local results = table.move(self.queue, queueCount + 1 - count, queueCount, 1, {})
    local refId = httpService:GenerateGUID(false)

    self.queue = table.move(self.queue, 1, #self.queue - count, 1, {})
    self.refs[refId] = {
        results = results,
        timeout = tick() + self.invisibilityTimeout
    }

    local mapped = ArrayUtil.Map(results, function(v)
        return v.value
    end)

    return mapped, refId, { time = time, queue = self.queue, refs = self.refs }
end

function MockMemoryStoreQueue:HandleTimeouts()
    -- Remove expired values in queue
    for index, value in ipairs(self.queue) do
        if value.expiration < tick() then
            table.remove(self.queue, index)
        end
    end

    -- Push any timed out values back into queue if not used
    for index, value in pairs(self.refs) do
        if value.timeout < tick() then
            self.refs[index] = nil
            for _, result in pairs(value.results) do
                self:AddAsyncInternal(result)
            end
        end
    end
end

function MockMemoryStoreQueue:RemoveAsync(ref: string)
    MockMemoryStoreQuota:ProcessWriteRequest()

    local valueRef = self.refs[ref]
    if valueRef then
        for _, value in ipairs(valueRef) do
            local index = table.find(self.queue, value)
            table.remove(self.queue, index)
        end
    end
end

function MockMemoryStoreQueue:AddAsyncInternal(value: Value)
    -- First index, since FIFO
    table.insert(self.queue, 1, value)

    table.sort(self.queue, function(a: Value, b: Value)
        return a.priority > b.priority
    end)
end

function MockMemoryStoreQueue:AddAsync(value: any, expiration: number, priority: number?)
    assert(typeof(expiration) == "number", "Expected 'expiration' (number) at argument #2")

    MockMemoryStoreQuota:ProcessWriteRequest()
    self:AddAsyncInternal({
        value = value,
        expiration = expiration,
        priority = priority
    })
end

return MockMemoryStoreQueue