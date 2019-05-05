LCSchedulerTaskType = {
    Step = 0,
    To = 1,
    Call = 3
}

LCSchedulerEvent = {
    Stop = 1,
    Play = 2
}

LCScheduler = {}
LCScheduler.__index = LCScheduler
LCScheduler.Create = function()
    local instance = {
        taskArray = {},
        currentTaskIndex = 1,
        currentTask = nil,
        currentTaskProgress = 0,
        playing = false,
        loop = false,
        timeScale = 1,
        em = LCEventManager.Create()
    }
    setmetatable(instance, LCScheduler)
    return instance
end

function LCScheduler:play()
    if self.playing == false and #self.taskArray > 0 then
        self.playing = true
        self.currentTaskIndex = 1
        self.currentTaskProgress = 0
        self.currentTask = self.taskArray[self.currentTaskIndex]
    end
end

function LCScheduler:reset()
    if self.playing == true then
        self.currentTaskIndex = 1
        self.currentTaskProgress = 0
        self.currentTask = self.taskArray[self.currentTaskIndex]
    end
end
function LCScheduler:stop()
    if self.playing then
        self.playing = false
        self.em:dispatchEvent(LCSchedulerEvent.Stop)
    end
end
function LCScheduler:addTaskStep(cb)
    table.insert(
        self.taskArray,
        {
            duration = 0,
            type = LCSchedulerTaskType.Step,
            cb = cb
        }
    )
end
function LCScheduler:addTaskTo(cb, duration, ease)
    table.insert(
        self.taskArray,
        {
            type = LCSchedulerTaskType.To,
            duration = duration,
            cb = cb,
            ease = ease or LCEaseFunc.linear
        }
    )
end
function LCScheduler:addTaskWait(duration)
    table.insert(
        self.taskArray,
        {
            type = LCSchedulerTaskType.Call,
            duration = duration
        }
    )
end
function LCScheduler:addTaskCall(cb, duration)
    table.insert(
        self.taskArray,
        {
            type = LCSchedulerTaskType.Call,
            cb = cb,
            duration = duration or 0
        }
    )
end

function LCScheduler:nextTask()
    if self.currentTaskIndex == #self.taskArray then
        if self.loop then
            self.currentTaskIndex = 1
            self.currentTask = self.taskArray[self.currentTaskIndex]
        else
            self:stop()
        end
    else
        self.currentTaskIndex = self.currentTaskIndex + 1
        self.currentTask = self.taskArray[self.currentTaskIndex]
    end
end
function LCScheduler:update(dt)
    self.currentTaskProgress = self.currentTaskProgress + dt * self.timeScale
    local finish = false
    while not finish do
        if self.playing then
            local task = self.currentTask
            if self.currentTaskProgress >= task.duration then
                if task.type == LCSchedulerTaskType.Step then
                    finish = true
                    task.cb(self.currentTaskProgress)
                    self.currentTaskProgress = 0
                elseif task.type == LCSchedulerTaskType.To then
                    self.currentTaskProgress = self.currentTaskProgress - task.duration
                    task.cb(1)
                elseif task.type == LCSchedulerTaskType.Call then
                    self.currentTaskProgress = self.currentTaskProgress - task.duration
                    if task.cb ~= nil then
                        task.cb(1)
                    end
                end
                self:nextTask()
            else
                finish = true
                if task.type == LCSchedulerTaskType.To then
                    task.cb(task.ease(self.currentTaskProgress, task.duration))
                end
            end
        else
            finish = true
        end
    end
end
