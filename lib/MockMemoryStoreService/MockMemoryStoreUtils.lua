local MockMemoryStoreUtils = {}

local MAX_KEY_LENGTH = 128

function MockMemoryStoreUtils.AssertKeyIsValid(key: string)
    assert(type(key) == "string", "Expects string got " .. typeof(key))

    if #key >= MAX_KEY_LENGTH then
        error("Key '" .. tostring(key) .. "' exceeds maximum length of " .. MAX_KEY_LENGTH, 3)
    end
end

local onceUsedLocations = {}
function MockMemoryStoreUtils.WarnOnce(message: string)
    local trace = debug.traceback()

    if onceUsedLocations[trace] then
        return
    end

    onceUsedLocations[trace] = true;
    warn(message)
end

MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS = 2_592_000

return MockMemoryStoreUtils