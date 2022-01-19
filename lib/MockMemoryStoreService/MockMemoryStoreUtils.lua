local MockMemoryStoreUtils = {}

local MAX_KEY_LENGTH = 128

function MockMemoryStoreUtils.AssertKeyIsValid(key: string)
    if #key >= MAX_KEY_LENGTH then
        error("Key '" .. tostring(key) .. "' exceeds maximum length of " .. MAX_KEY_LENGTH, 3)
    end
end

MockMemoryStoreUtils.MAX_EXPIRATION_SECONDS = 2_592_000

return MockMemoryStoreUtils