LCEventManager = {}
LCEventManager.__index = LCEventManager
LCEventManager.Create = function()
    local instance = {
        eventMap = {}
    }
    setmetatable(instance, LCEventManager)
    return instance
end
function LCEventManager:removeAllEvent()
    for k, v in pairs(self.eventMap) do
        v:removeAllListener()
    end
    self.eventMap = {}
end
function LCEventManager:removeEvent(eventKey)
    for k, v in pairs(self.eventMap) do
        if eventKey == k then
            v:removeAllListener()
            table.remove(self.eventMap, k)
            return true
        end
    end
    return false
end
function LCEventManager:getEvent(eventKey)
    return self.eventMap[eventKey]
end
function LCEventManager:addEventListener(eventKey, func)
    local event = self.eventMap[eventKey]
    if event == nil then
        event = LCEvent.Create()
        self.eventMap[eventKey] = event
    end
    return event:addListener(func)
end
function LCEventManager:removeEventListener(eventKey, eventID)
    local event = self.eventMap[eventKey]
    if event ~= nil then
        return event:removeListener(eventID)
    end
    return false
end
function LCEventManager:dispatchEvent(eventKey, data)
    local event = self.eventMap[eventKey]
    if event ~= nil then
        event:dispatch(data)
    end
end
