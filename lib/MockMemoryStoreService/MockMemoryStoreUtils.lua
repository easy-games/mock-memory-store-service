--!strict
local MockMemoryStoreUtils = {}

local onceUsedLocations = {}

local MAX_KEY_LENGTH = 128
MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS = 2_592_000

function MockMemoryStoreUtils.assertKeyIsValid(key: string)
    assert(type(key) == "string", "Expects string got " .. typeof(key))

    if #key >= MAX_KEY_LENGTH then
        error("Key '" .. tostring(key) .. "' exceeds maximum length of " .. MAX_KEY_LENGTH, 3)
    end
end

function MockMemoryStoreUtils.warnOnce(message: string)
    local trace = debug.traceback()

    if onceUsedLocations[trace] then
        return
    end

    onceUsedLocations[trace] = true;
    warn(message)
end

return MockMemoryStoreUtils