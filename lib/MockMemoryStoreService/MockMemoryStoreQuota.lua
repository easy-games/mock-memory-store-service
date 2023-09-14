--!strict

export type MockMemoryStoreQuota = {
	__index: MockMemoryStoreQuota,
	_Quota: number,
	_LastQuotaCheckTime: number,
	GetRequestBaseQuota: (self: MockMemoryStoreQuota) -> number,
	GetRequestPlayerQuota: (self: MockMemoryStoreQuota, numPlayers: number?) -> number,
	Get: (self: MockMemoryStoreQuota) -> number,
	ProcessWriteRequest: (self: MockMemoryStoreQuota) -> (),
	ProcessReadRequest: (self: MockMemoryStoreQuota) -> (),
	UpdateQuota: (self: MockMemoryStoreQuota) -> (),
	new: () -> MockMemoryStoreQuota,
}

local MockMemoryStoreQuota = {} :: MockMemoryStoreQuota
MockMemoryStoreQuota.__index = MockMemoryStoreQuota

function MockMemoryStoreQuota:GetRequestBaseQuota(): number
    return 1000
end

function MockMemoryStoreQuota:GetRequestPlayerQuota(numPlayers: number?): number
    return 100 * (if numPlayers ~= nil then numPlayers else #game:GetService("Players"):GetPlayers())
end

function MockMemoryStoreQuota:Get(): number
    return self._Quota
end

function MockMemoryStoreQuota:ProcessWriteRequest(): ()
    if self._Quota <= 0 then
        error("Exceeded MemoryStore quota (on write)", 2)
    end

    self._Quota -= 1
end

function MockMemoryStoreQuota:ProcessReadRequest(): ()
    if self._Quota <= 0 then
        error("Exceeded MemoryStore quota (on read)", 2)
    end

    self._Quota -= 1
end

function MockMemoryStoreQuota:UpdateQuota(): ()
    -- Every 60 seconds, we're resetting teh quota.
    if self._LastQuotaCheckTime < tick() + 60 then
        self._Quota = self:GetRequestBaseQuota() + self:GetRequestPlayerQuota()
        self._LastQuotaCheckTime = tick()
    end
end

function MockMemoryStoreQuota.new(): MockMemoryStoreQuota
	local self: MockMemoryStoreQuota = setmetatable({}, MockMemoryStoreQuota) :: any
	self._Quota = 1000
	self._LastQuotaCheckTime = 0
	return self
end

return MockMemoryStoreQuota.new()