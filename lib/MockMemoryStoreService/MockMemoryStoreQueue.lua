local MockMemoryStoreQuota = require(script.Parent.MockMemoryStoreQuota)

local httpService = game:GetService("HttpService")

local MockMemoryStoreQueue = {}
MockMemoryStoreQueue.index = MockMemoryStoreQueue;

type Value = {
    id: string,
    value: any,
    expiration: number,
    priority: number,
    mutex: boolean,
    mutexExpiration: number?,
}

function MockMemoryStoreQueue.new(name)
    return setmetatable({
        queue = {},
        refs = {}
    }, MockMemoryStoreQueue)
end

function MockMemoryStoreQueue:ReadAsync(count, allOrNothing, waitTimeout)
    MockMemoryStoreQuota:ProcessReadRequest()

    local results = table.move(#self.queue - count, #self.queue, 1, #self.queue, {})

    local ref = httpService:GenerateGUID(false)
    self.refs[ref] = results

    for _, value in ipairs(results) do
        value.mutex = true
        value.mutexExpiration = tick() + waitTimeout
    end
    return results
end

function MockMemoryStoreQueue:RemoveAsync(ref)
    MockMemoryStoreQuota:ProcessWriteRequest()

    local valueRef = self.refs[ref]
    if valueRef then
        for _, value in ipairs(valueRef) do
            local index = table.find(self.queue, value)
            table.remove(self.queue, index)
        end
    end
end

function MockMemoryStoreQueue:AddAsync(value: any, expiration: number, priority: number)
    MockMemoryStoreQuota:ProcessWriteRequest()

    table.insert(self.queue, {
        value = value,
        expiration = expiration,
        priority = priority,
        id = httpService:GenerateGUID(false),
        mutex = false
    } :: Value)

    table.sort(self.queue, function(a: Value, b: Value)
        return a.priority > b.priority
    end)
end

return MockMemoryStoreQueue