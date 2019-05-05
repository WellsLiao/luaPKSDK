local msgPong =
    protobuf.encode(
    "gameProto.Msg",
    {
        ID = "Pong"
    }
)
local msgPing =
    protobuf.encode(
    "gameProto.Msg",
    {
        ID = "Ping"
    }
)

local LCWebsocketClientStatus = {
    CLOSED = 0,
    CLOSING = 1,
    CONNECTING = 2,
    OPEN = 3
}

LCWebsocketClient = {}
LCWebsocketClient.__index = LCWebsocketClient
function LCWebsocketClient.Create(config)
    local instance = {
        conn = nil,
        joinID = nil,
        status = LCWebsocketClientStatus.CLOSED,
        isSendReady = false,
        isSendResult = false,
        hasRecvResult = false,
        sendIndex = 0,
        sendHistory = {},
        recvIndex = 0,
        scheduler = nil,
        pingInterval = 3,
        timeoutInterval = 6,
        closeInterval = 15,
        pingDuration = 0,
        timeoutDuration = 0,
        closeDuration = 0
    }
    setmetatable(instance, LCWebsocketClient)
    instance:init()
    return instance
end

function LCWebsocketClient:startScheduler()
    local scheduler = store.schedulerManager:newScheduler()
    scheduler:addTaskCall(
        function()
            self.pingDuration = self.pingDuration + 1
            self.timeoutDuration = self.timeoutDuration + 1
            self.closeDuration = self.closeDuration + 1

            if (self.pingDuration >= self.pingInterval) then
                self.pingDuration = self.pingDuration - self.pingInterval
                self:sendPing()
            end
            if (self.timeoutDuration >= self.timeoutInterval) then
                self.timeoutDuration = self.timeoutDuration - self.timeoutInterval
                self:timeout()
            end
            if (self.closeDuration >= self.closeInterval) then
                self.closeDuration = self.closeDuration - self.closeInterval
                self:close()
            end
        end,
        1000
    )
    scheduler.loop = true
    scheduler:start()
    self.scheduler = scheduler
    print("[startScheduler]")
end

function LCWebsocketClient:resetDuration()
    self.pingDuration = 0
    self.timeoutDuration = 0
    self.closeDuration = 0
end

function LCWebsocketClient:connect(url)
    if self.status ~= LCWebsocketClientStatus.CLOSED then
        return
    end
    self.status = LCWebsocketClientStatus.CONNECTING
    self.conn = cc.WebSocket:create(url)
    if self.conn.setDataType ~= nil then
        self.conn:setDataType(1)
    end
    self.conn:registerScriptHandler(handler(self, self.onWebsocketOpen), cc.WEBSOCKET_OPEN)
    self.conn:registerScriptHandler(handler(self, self.onWebsocketClose), cc.WEBSOCKET_CLOSE)
    self.conn:registerScriptHandler(handler(self, self.onWebsocketMessage), cc.WEBSOCKET_MESSAGE)
    self:startScheduler()
    print("[onConnect]")
end

function LCWebsocketClient:disconnect()
    print("[disconnect]")
    if self.conn ~= nil then
        self.conn:close()
        return
    end
    if self.isClose == false then
        self:onDisconnect()
        local schedulerReconnect = store.schedulerManager:newScheduler()
        schedulerReconnect:addTaskCall(
            function()
                if (self.isClose == false) then
                    self:connect()
                end
            end,
            1000
        )
        schedulerReconnect:start()
        return
    end
end

function LCWebsocketClient:close()
    if self.isClose then
        return
    end
    self.isClose = true
    if (self.scheduler) then
        self.scheduler:stop()
        self.scheduler = nil
    end
    if self.conn ~= nil then
        self.conn:close()
    end
    self.onClose()
end

function LCWebsocketClient:onWebsocketOpen()
    self:resetDuration()
    if (self.joinID == null) then
        self.onConnect()
        self:join()
    else
        self.onReconnect()
        self.recvErr()
    end
end

function LCWebsocketClient:onWebsocketMessage(data)
    self.resetDuration()
    local msg = protobuf.decode("gameProto.Msg", data)
    if msg.ID == "Ping" then
        self:send(msgPong)
    elseif msg.ID == "JoinResp" then
        local msgJoinResp = protobuf.decode("gameProto.MsgJoinResp", data)
        self.joinID = msgJoinResp.joinID
        self.onJoin()
    elseif msg.ID == "Create" then
        self.isCreate = true
        local msg = protobuf.decode("gameProto.MsgJoinResp", data)
        self:recvMsg(msg.index)
        self.onCreate(msg)
    elseif msg.ID == "Start" then
        local msg = protobuf.decode("gameProto.MsgStart", data)
        self:recvMsg(msg.index)
        self.onStart(msg)
    elseif msg.ID == "Custom" then
        local msg = protobuf.decode("gameProto.MsgCustom", data)
        self:recvMsg(msg.index)
        self.onCustom(msg)
    elseif msg.ID == "Error" then
        local msg = protobuf.decode("gameProto.MsgError", data)
        self.onError(msg.msg)
        self:close()
    elseif msg.ID == "SendError" then
        local msg = protobuf.decode("gameProto.MsgSendError", data)
        self:sendSaveMsg(msg.from)
    elseif msg.ID == "End" then
        local msg = protobuf.decode("gameProto.MsgEnd", data)
        self.isEnd = true
        if (msgEnd.type == 0) then
            self.onNoStart()
            self.isSurrender = true
        elseif (msgEnd.type == 1) then
            self.onEndWin()
        elseif (msgEnd.type == 2) then
            self.onEndLose()
        else
            self.onEndDraw()
        end
        local result = {
            timestamp = msgEnd.timestamp,
            nonstr = msgEnd.nonstr,
            sign = msgEnd.sign,
            resultrawdata = msgEnd.resultrawdata,
            result = json.decode(msgEnd.resultrawdata)
        }
        if self.isSurrender then
            NativeBridge:onPKFinish(json.encode(result))
        else
            NativeBridge:onPKFinish(json.encode(result))
        end
    end
end

function LCWebsocketClient:onWebsocketClose()
    self.conn:unregisterScriptHandler(cc.WEBSOCKET_OPEN)
    self.conn:unregisterScriptHandler(cc.WEBSOCKET_CLOSE)
    self.conn:unregisterScriptHandler(cc.WEBSOCKET_MESSAGE)
    self:disconnect()
end

function LCWebsocketClient:isSocketOpen()
    if self.conn and self.conn:getReadyState() == 1 then
        return true
    end
    return false
end
function LCWebsocketClient:send(msg)
    if self.stause then
        self.conn:sendString(msg)
    end
end
function LCWebsocketClient:close()
    --print("[onClose]")
    if self.conn ~= nil then
        self:disconnect()
        self.schedulerTimeout:stop()
        self.schedulerReconnect:stop()
    end
    self.em:dispatchEvent(LCWebsocketClientEvent.Close)
end

function LCWebsocketClient:sendPing()
    self:send(msgPing)
end

function LCWebsocketClient:sendJoin(userData, roomData)
    local msg =
        protobuf.encode(
        "gameProto.MsgJoin",
        {
            ID = "Join",
            userData = userData,
            roomData = roomData
        }
    )
    self:send(msg)
end

function LCWebsocketClient:sendRejoin()
    local msg =
        protobuf.encode(
        "gameProto.MsgRejoin",
        {
            ID = "Rejoin",
            joinID = self.joinID
        }
    )
    self:send(msg)
end

function LCWebsocketClient:sendRecvError()
    local msg =
        protobuf.encode(
        "gameProto.MsgRecvError",
        {
            ID = "RecvError",
            from = self.recvIndex
        }
    )
    self:send(msg)
end

function LCWebsocketClient:sendReady()
    local msg =
        protobuf.encode(
        "gameProto.MsgReady",
        {
            ID = "Ready",
            index = self.sendIndex
        }
    )
    self:saveSend(msg)
    self:send(msg)
end

function LCWebsocketClient:sendCustom(data)
    local msg =
        protobuf.encode(
        "gameProto.MsgCustom",
        {
            ID = "Custom",
            index = self.sendIndex,
            data = data
        }
    )
    self:saveSend(msg)
    self:send(msg)
end

function LCWebsocketClient:sendResult(type)
    if self.isSendResult then
        return
    end
    local msg =
        protobuf.encode(
        "gameProto.MsgResult",
        {
            ID = "Result",
            index = self.sendIndex,
            type = type
        }
    )
    self:saveSend(msg)
    self:send(msg)
end

function LCWebsocketClient:saveSend(msg)
    self.sendIndex = self.sendIndex + 1
    self.sendHistory[self.sendIndex] = msg
end

function LCWebsocketClient:sendSaveMsg(from)
    for i = 1, from do
        self:send(self.sendHistory[i])
    end
end

return LCWebsocketClient
