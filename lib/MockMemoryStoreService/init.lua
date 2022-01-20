local MockMemoryStoreSortedMap = require(script.MockMemoryStoreSortedMap)
local MockMemoryStoreQueue = require(script.MockMemoryStoreQueue)
local MockMemoryStoreQuota = require(script.MockMemoryStoreQuota)

local RunService = game:GetService("RunService")

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
function MockMemoryStoreService:GetQueue(name: string, timeout: number?)
    warn("MockMemoryStoreService queue is still in development, and may not work accurately just yet.")

    local queue = self.queues[name]
    if queue == nil then
        queue = MockMemoryStoreQueue.new(name, timeout)
        self.queues[name] = queue
    end

    return queue
end

-- Lifetime handling
local function onHeartbeat(deltaTime)
    MockMemoryStoreQuota:UpdateQuota()

    -- Need to handle expiration for each map value
    for _, map in pairs(MockMemoryStoreService.sortedMaps) do
        -- Iterate through each value to check if they're expired
        -- Then expire them
        for key, value in pairs(map.mapValues) do
            if value.expiration <= tick() then
                map:RemoveExpiringKey(key)
            end
        end
    end

    for _, queue in pairs(MockMemoryStoreService.queues) do
        queue:HandleTimeouts()
    end
end
RunService.Heartbeat:Connect(onHeartbeat)

return MockMemoryStoreService