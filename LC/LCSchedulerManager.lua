LCSchedulerManager = {}
LCSchedulerManager.__index = LCSchedulerManager
LCSchedulerManager.Create = function()
    local instance = {
        schedulerArray = {},
        timeScale = 1,
        currentTime = 0
    }
    setmetatable(instance, LCSchedulerManager)
    return instance -- body
end

function LCSchedulerManager:getCurrentTime()
    return self.currentTime
end

function LCSchedulerManager:newScheduler()
    local scheduler = LCScheduler.Create()
    table.insert(self.schedulerArray, scheduler)
    scheduler.em:addEventListener(
        LCSchedulerEvent.Play,
        function()
            self:addScheduler(scheduler)
        end
    )
    return scheduler
end

function LCSchedulerManager:addScheduler(scheduler)
    for k, v in pairs(self.schedulerArray) do
        if v == scheduler then
            return false
        end
    end
    table.insert(self.schedulerArray, scheduler)
    scheduler.em:addEventListener(
        LCSchedulerEvent.Stop,
        function()
            for i, s in pairs(self.schedulerArray) do
                if s == scheduler then
                    table.remove(self.schedulerArray, i)
                    scheduler.removeAllEvent()
                    break
                end
            end
        end
    )
    return true
end

function LCSchedulerManager:update(v)
    local dt = v * self.timeScale
    self.currentTime = self.currentTime + dt

    local schedulerArray = {}
    for k, v in pairs(self.schedulerArray) do
        table.insert(schedulerArray, v)
    end
    for k, v in pairs(schedulerArray) do
        v:update(dt)
    end
end
