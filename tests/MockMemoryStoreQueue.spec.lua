local MockMemoryStoreService = require(game:GetService("ReplicatedStorage").MockMemoryStore)

return function ()
    it("Should retrieve the same queue", function()
        local TestQueue = MockMemoryStoreService:GetQueue("TestQueue")
        expect(TestQueue).to.be.ok()

        local TestQueue2 = MockMemoryStoreService:GetQueue("TestQueue")
        expect(TestQueue2).to.equal(TestQueue)
    end)

    it("Should do AddAsync", function()
        local TEST_VALUE = "Hello, World!"
        local TestQueue = MockMemoryStoreService:GetQueue("TestQueue")
        expect(TestQueue).to.be.ok()

        TestQueue:AddAsync(TEST_VALUE, 60)

        local topValues, ref, debugging = TestQueue:ReadAsync(1) -- read the last value

        -- Should have one value, at least.
        expect(topValues[1]).to.equal(TEST_VALUE)

        -- Should have a reference
        expect(TestQueue:GetRef(ref)).to.be.ok()
    end)

    it("Should handle invisTimeout correctly", function()
        local TestQueue = MockMemoryStoreService:GetQueue("TestQueueInvisTimeout", 2)
        local TEST_VALUE = "hi there"
        
        -- We're adding a value, it expires in 60 seconds
        TestQueue:AddAsync(TEST_VALUE, 60)

        -- The value in question here should be retrieved, and unaccessible for 2 seconds.
        local values1, ref, debug = TestQueue:ReadAsync(1, true, 10)
        print(values1, ref, debug)
        expect(values1[1]).to.equal(TEST_VALUE)

        -- This value shouldn't be retrievable.
        local values2 = TestQueue:ReadAsync(1, false)
        expect(#values2).to.equal(0)

        task.wait(2)
        -- It should be available again
        local values2 = TestQueue:ReadAsync(1, false)
        expect(#values2).to.equal(1)
    end)

    it("Should remove expired items correctly", function()
        local TestQueue = MockMemoryStoreService:GetQueue("TestExpirationQueue", 0)
        TestQueue:AddAsync("Queue Value", 2)
        task.wait(2)
        
        -- The item should've been removed after 2 seconds, so nmo items in the queue.
        local result = TestQueue:ReadAsync(1, false, 0)
        expect(#result).to.equal(0)
    end)

    it("Should handle removing items correctly", function()
        local TestQueue = MockMemoryStoreService:GetQueue("TestRemovalQueue", 5)
        TestQueue:AddAsync("One", 60)
        TestQueue:AddAsync("Two", 30)

        local results, id = TestQueue:ReadAsync(2, true, 10)
        expect(#results).to.equal(2)

        TestQueue:RemoveAsync(id)
        task.wait(5)
        
        local results2 = TestQueue:ReadAsync(1)
        expect(#results2).to.equal(0)
    end)
end