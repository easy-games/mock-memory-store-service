local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.rbxts.testez.src)

local results = TestEZ.TestBootstrap:run({
    ReplicatedStorage.Tests
})

if (#results.errors > 0 or results.failureCount > 0) then
    error("Tests failed!")
end