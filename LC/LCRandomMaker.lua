LCRandomMaker = {}

LCRandomMaker.__index = LCRandomMaker
LCRandomMaker.Create = function(seed)
    local instance = {
        seed = seed or 0
    }
    setmetatable(instance, LCRandomMaker)
    return instance
end
function LCRandomMaker:get()
    return self:random()
end
function LCRandomMaker:getNormalDistribution()
    return self:randomNormalDistribution()
end
function LCRandomMaker:randomNormalDistribution()
    local u = 0
    local v = 0
    local w = 0
    local c = 0
    while w == 0 or w >= 1 do
        u = self:random() * 2 - 1
        v = self:random() * 2 - 1
        w = u * u + v * v
    end
    c = math.sqrt((-2 * math.log(w)) / w)
    return u * c
end

function LCRandomMaker:random()
    self.seed = (self.seed * 9301 + 49297) % 233280
    return self.seed / 233280
end
