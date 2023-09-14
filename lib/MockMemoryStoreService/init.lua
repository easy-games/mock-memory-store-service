--!strict
local MockMemoryStoreSortedMap = require(script.MockMemoryStoreSortedMap)
local MockMemoryStoreHashMap = require(script.MockMemoryStoreHashMap)
local MockMemoryStoreQueue = require(script.MockMemoryStoreQueue)
local MockMemoryStoreQuota = require(script.MockMemoryStoreQuota)
local MockMemoryStoreUtils = require(script.MockMemoryStoreUtils)

local RunService = game:GetService("RunService")

export type MockMemoryStoreSortedMap = MockMemoryStoreSortedMap.MockMemoryStoreSortedMap
export type MockMemoryStoreHashMap = MockMemoryStoreHashMap.MockMemoryStoreHashMap
export type MockMemoryStoreQueue = MockMemoryStoreQueue.MockMemoryStoreQueue
export type MockMemoryStoreService = {
	__index: MockMemoryStoreService,
	_Queues: {[string]: MockMemoryStoreQueue},
	_SortedMaps: {[string]: MockMemoryStoreSortedMap},
	_HashMaps: {[string]: MockMemoryStoreHashMap},
	new: () -> MockMemoryStoreService,
	GetSortedMap: (self: MockMemoryStoreService, name: string) -> MockMemoryStoreSortedMap,
	GetHashMap: (self: MockMemoryStoreService, name: string) -> MockMemoryStoreHashMap,
	GetQueue: (self: MockMemoryStoreService, name: string, timeout: number?) -> MockMemoryStoreQueue,
}

local MockMemoryStoreService = {} :: MockMemoryStoreService
MockMemoryStoreService.__index = MockMemoryStoreService

--[[
    Will retrieve a MockMemoryStoreSortedMap object under the specified name
]]
function MockMemoryStoreService:GetSortedMap(name: string): MockMemoryStoreSortedMap
    local sortedMap = self._SortedMaps[name];
    if sortedMap == nil then
        sortedMap = MockMemoryStoreSortedMap.new(name)
        self._SortedMaps[name] = sortedMap
    end

    return sortedMap
end


--[[
    Will retrieve a MockMemoryStoreHashMap object under the specified name
]]
function MockMemoryStoreService:GetHashMap(name: string): MockMemoryStoreHashMap
	local hashMap = self._HashMaps[name];
	if hashMap == nil then
		hashMap = MockMemoryStoreHashMap.new(name)
	    self._HashMaps[name] = hashMap
	end
 
	return hashMap
 end

--[[
    Will retrieve a MockMemoryStoreQueue object under the specified name
]]
function MockMemoryStoreService:GetQueue(name: string, timeout: number?): MockMemoryStoreQueue
    MockMemoryStoreUtils.warnOnce("MockMemoryStoreService queue is still in development, and may not work accurately just yet.")

    local queue = self._Queues[name]
    if queue == nil then
        queue = MockMemoryStoreQueue.new(name, timeout)
        self._Queues[name] = queue
    end

    return queue
end

function MockMemoryStoreService.new()
	local self: MockMemoryStoreService = setmetatable({}, MockMemoryStoreService) :: any
	self._Queues = {}
	self._SortedMaps = {}
	self._HashMaps = {}

	-- Lifetime handling
	local function onHeartbeat(deltaTime: number): ()
		MockMemoryStoreQuota:UpdateQuota()
	
		-- Need to handle expiration for each map value
		for _, map in pairs(self._SortedMaps) do
		-- Iterate through each value to check if they're expired
		-- Then expire them
		for key, value in pairs(map._MapValues) do
			if value.expiration <= tick() then
				map:_RemoveExpiringKey(key)
			end
		end
		end
	
		for _, queue in pairs(self._Queues) do
		queue:_HandleTimeouts()
		end
	end
	RunService.Heartbeat:Connect(onHeartbeat)

	return self
end


return MockMemoryStoreService.new()