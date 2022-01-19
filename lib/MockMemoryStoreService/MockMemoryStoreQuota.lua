local MockMemoryStoreQuota = {
    quota = 1000,
    lastQuotaCheckTime = 0
}

function MockMemoryStoreQuota:GetRequestBaseQuota()
    return 1000
end

function MockMemoryStoreQuota:GetRequestPlayerQuota(numPlayers)
    return 100 * (if numPlayers ~= nil then numPlayers else #game:GetService("Players"):GetPlayers())
end

function MockMemoryStoreQuota:Get()
    return self.quota
end

function MockMemoryStoreQuota:ProcessWriteRequest()
    if self.quota <= 0 then
        error("Exceeded MemoryStore quota (on write)", 2)
    end

    self.quota -= 1
end

function MockMemoryStoreQuota:ProcessReadRequest()
    if self.quota <= 0 then
        error("Exceeded MemoryStore quota (on read)", 2)
    end

    self.quota -= 1
end

function MockMemoryStoreQuota:UpdateQuota()
    -- Every 60 seconds, we're resetting teh quota.
    if self.lastQuotaCheckTime < tick() + 60 then
        self.quota = self:GetRequestBaseQuota() + self:GetRequestPlayerQuota()
        self.lastQuotaCheckTime = tick()
    end
end

return MockMemoryStoreQuota