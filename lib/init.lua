--!strict
local MockMemoryStoreServiceModule = script.MockMemoryStoreService

local shouldUseMock = false
if game.GameId == 0 then
    shouldUseMock = true
elseif game:GetService("RunService"):IsStudio() then
	local status, message = pcall(function()
		-- This will error if current instance has no Studio API access:
		game:GetService("MemoryStoreService"):GetSortedMap("__TEST")
	end)
	if not status and message:find("403", 1, true) then -- HACK
		-- Can connect to datastores, but no API access
		shouldUseMock = true
	end
end

-- Return the mock or actual service depending on environment:
if shouldUseMock then
	warn("INFO: Using MockMemoryStoreService instead of MemoryStoreService")
	return require(MockMemoryStoreServiceModule) :: MemoryStoreService
else
	return game:GetService("MemoryStoreService") :: MemoryStoreService
end