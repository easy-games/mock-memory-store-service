local MockMemoryStoreService = require(game:GetService("ReplicatedStorage").MockMemoryStore)



return function ()
    it("Should retrieve the same map", function()
        local TestSortedMap = MockMemoryStoreService:GetSortedMap("TestSortedMap")
        expect(TestSortedMap).to.be.ok()

        local TestSortedMap2 = MockMemoryStoreService:GetSortedMap("TestSortedMap")
        expect(TestSortedMap2).to.equal(TestSortedMap) -- Should be same reference
    end)

    it("Should correctly use GetAsync/SetAsync", function()
        local TEST_VALUE = 10

        local TestSortedMap = MockMemoryStoreService:GetSortedMap("TestSortedMap")
        expect(TestSortedMap:SetAsync("TestSet", TEST_VALUE, 30)).to.equal(false)  -- false because new value, not update.

        expect(TestSortedMap:GetAsync("TestSet")).to.equal(TEST_VALUE)

        expect(TestSortedMap:SetAsync("TestSet", TEST_VALUE + 5, 30)).to.equal(true) -- true, because updating existing value
    end)

    it("Should correctly use UpdateAsync", function()
        local TEST_VALUE = 32

        local TestSortedMap = MockMemoryStoreService:GetSortedMap("TestSortedMap")

        -- This should return a value, since we've returned a value
        local value = TestSortedMap:UpdateAsync("TestUpdateKey", function(value)
            expect(value).to.be.equal(nil) -- value shouldn't be set since it's y'know, not set yet.
            return TEST_VALUE
        end, 20)

        -- Should have returned TEST_VALUE
        expect(value).to.be.equal(TEST_VALUE)

        local nilValue = TestSortedMap:UpdateAsync("TestUpdateKey", function(value)
            expect(value).to.equal(TEST_VALUE)
            return nil
        end, 20)

        -- Should be nil since we didn't transform
        expect(nilValue).to.equal(nil)
    end)

    it("Should correctly use RemoveAsync", function()
        local TEST_VALUE = 32
        local TestSortedMap = MockMemoryStoreService:GetSortedMap("TestSortedMap")

        expect(TestSortedMap:SetAsync("RemoveMe", TEST_VALUE, 30)).to.equal(false) -- new value, again

        TestSortedMap:RemoveAsync("RemoveMe")
        expect(TestSortedMap:GetAsync("RemoveMe")).to.equal(nil)
    end)
end