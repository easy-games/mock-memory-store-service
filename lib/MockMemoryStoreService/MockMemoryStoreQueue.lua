local httpService = game:GetService("HttpService")

local MockMemoryStoreQueue = {}
MockMemoryStoreQueue.__index = MockMemoryStoreQueue;

type Value = {
    id: string,
    value: any,
    expiration: number,
    priority: number,
    mutex: boolean,
}

function MockMemoryStoreQueue.new(name)
    return setmetatable({
        __queue = {},
        __refs = {}
    }, MockMemoryStoreQueue)
end

function MockMemoryStoreQueue:ReadAsync(count, allOrNothing, waitTimeout)
    local results = table.move(#self.__queue - count, #self.__queue, 1, #self.__queue, {})

    local ref = httpService:GenerateGUID(false)
    self.__refs[ref] = results

    for _, value in ipairs(results) do
        value.mutex = true
    end
    return results
end

function MockMemoryStoreQueue:RemoveAsync(ref)
    local valueRef = self.__refs[ref]
    if valueRef then
        for _, value in ipairs(valueRef) do
            local index = table.find(self.__queue, value)
            table.remove(self.__queue, index)
        end
    end
end

function MockMemoryStoreQueue:AddAsync(value: any, expiration: number, priority: number)
    table.insert(self.__queue, {
        value = value,
        expiration = expiration,
        priority = priority,
        id = httpService:GenerateGUID(false),
        mutex = false
    } :: Value)

    table.sort(self.__queue, function(a: Value, b: Value)
        return a.priority > b.priority
    end)
end

return MockMemoryStoreQueue