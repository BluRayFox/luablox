local Signal = {}
Signal.__index = Signal

local Connection = require("Connection")

-- optional task support
local hasTask, taskLib = pcall(function()
    return require("task") or getfenv()['task'] or _G['task'] 
end)

local function spawn(fn, ...)
    if hasTask and taskLib.spawn then
        taskLib.spawn(fn, ...)
    else
        fn(...)
    end
end

function Signal.new()
    return setmetatable({
        _connections = {},
        _waiting = {}
    }, Signal)
end

function Signal:Connect(fn)
    local conn = Connection.new(self, fn)
    table.insert(self._connections, conn)
    return conn
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    local args = table.pack(...)

    for _, thread in ipairs(self._waiting) do
        spawn(function()
            coroutine.resume(thread, table.unpack(args, 1, args.n))
        end)
    end
    self._waiting = {}

    for _, conn in ipairs(self._connections) do
        if conn.Connected then
            spawn(conn._fn, table.unpack(args, 1, args.n))
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    table.insert(self._waiting, thread)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

return Signal
