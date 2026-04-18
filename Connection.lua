local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
    return setmetatable({
        _signal = signal,
        _fn = fn,
        Connected = true
    }, Connection)
end

function Connection:Disconnect()
    if not self.Connected then return end
    self.Connected = false

    local list = self._signal._connections
    for i = #list, 1, -1 do
        if list[i] == self then
            table.remove(list, i)
            break
        end
    end
end

return Connection
