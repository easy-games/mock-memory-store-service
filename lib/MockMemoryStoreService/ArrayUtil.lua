local function map(arr, mapFn)
    local alloc = table.create(#arr)
    for index, value in ipairs(arr) do
        table.insert(alloc, mapFn(value, index))
    end
    return alloc
end

return {
    Map = map
}