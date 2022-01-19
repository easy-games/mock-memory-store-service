local MockMemoryStoreSortedMap = require(script.MockMemoryStoreSortedMap)
local MockMemoryStoreQueue = require(script.MockMemoryStoreQueue)

local MockMemoryStoreService = {
    queues = {},
    sortedMaps = {}
}
MockMemoryStoreService.__index = MockMemoryStoreService

--[[
    Will retrieve a MockMemoryStoreSortedMap object under the specified name
]]
function MockMemoryStoreService:GetSortedMap(name: string)
    local sortedMap = self.sortedMaps[name];
    if sortedMap == nil then
        sortedMap = MockMemoryStoreSortedMap.new(name)
        self.sortedMaps[name] = sortedMap
    end

    return sortedMap
end

--[[
    Will retrieve a MockMemoryStoreQueue object under the specified name
]]
function MockMemoryStoreService:GetQueue(name: string, timeout: number)
    local queue = self.queues[name]
    if queue == nil then
        queue = MockMemoryStoreQueue.new(name, timeout)
        self.queues[name] = queue
    end

    return queue
end

return MockMemoryStoreService