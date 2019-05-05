LCWeightRandom = {}

LCWeightRandom.__index = LCWeightRandom
LCWeightRandom.Create = function()
    local instance = {
        totalWeight = 0,
        itemArray = {}
    }
    setmetatable(instance, LCWeightRandom)
    return instance -- body
end

function LCWeightRandom:add(weight, onGet)
    local item = {
        from = self.totalWeight,
        to = self.totalWeight + weight,
        onGet = onGet
    }
    table.insert(self.itemArray, item)
    self.totalWeight = self.totalWeight + weight
end

function LCWeightRandom:get(v)
    local value = math.min(1, math.max(0, v))
    local weight = v * self.totalWeight
    for i, item in pairs(self.itemArray) do
        if item.from <= weight and weight < item.to then
            item.onGet()
            break
        end
    end
end
