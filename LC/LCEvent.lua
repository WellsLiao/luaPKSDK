LCEvent = {}
LCEvent.__index = LCEvent
LCEvent.Create = function()
    local instance = {
        listenerArray = {},
        IDCount = 0
    }
    setmetatable(instance, LCEvent)
    instance.listenerArray = {}
    instance.IDCount = 0
    return instance
end
function LCEvent:addListener(func)
    self.IDCount = self.IDCount + 1
    local id = self.IDCount
    table.insert(
        self.listenerArray,
        {
            id = self.IDCount,
            func = func
        }
    )
    return id
end
function LCEvent:removeListener(listenerID)
    for k, v in pairs(self.listenerArray) do
        if v.id == listenerID then
            table.remove(self.listenerArray, k)
            return true
        end
    end
    return false
end
function LCEvent:removeAllListener(key)
    self.listenerArray = {}
end
function LCEvent:dispatch(data)
    local funcArray = {}
    for k, v in pairs(self.listenerArray) do
        funcArray[k] = v.func
    end
    for k, v in pairs(funcArray) do
        v(data)
    end
end
