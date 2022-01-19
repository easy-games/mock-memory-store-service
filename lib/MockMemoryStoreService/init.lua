local MockMemoryStoreSortedMap = require(script.MockMemoryStoreSortedMap)
local MockMemoryStoreQueue = require(script.MockMemoryStoreQueue)

local MockMemoryStoreService = {}
MockMemoryStoreService.__index = MockMemoryStoreService

function MockMemoryStoreService:GetSortedMap(name: string)
    return MockMemoryStoreSortedMap.new(name)
end

function MockMemoryStoreService:GetQueue(name: string, timeout: number)
    return MockMemoryStoreQueue.new(name, timeout)
end

return MockMemoryStoreService