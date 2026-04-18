local task = {}

local tasksList = {}
local nextId = 0

function task.spawn(f, ...)
    local co = coroutine.create(f)

    nextId = nextId + 1
    local t = {
        id = nextId,
        co = co,
        args = {...},
        wakeTime = 0,
        canceled = false,
        finished = false
    }

    tasksList[t.id] = t
    return t
end

function task.cancel(t)
    if t then
        t.canceled = true
    end
end

function task.wait(sec)
    sec = sec or 0
    return coroutine.yield(sec)
end

function task.update()
    local now = os.clock()

    for id, t in pairs(tasksList) do
        if t.canceled then
            tasksList[id] = nil

        elseif not t.finished then
            if now >= t.wakeTime then
                local ok, waitTime = coroutine.resume(t.co, table.unpack(t.args))
                t.args = {}

                if not ok then
                    print("Task error:", waitTime)
                    tasksList[id] = nil

                elseif coroutine.status(t.co) == "dead" then
                    t.finished = true
                    tasksList[id] = nil

                else
                    t.wakeTime = now + (waitTime or 0)
                end
            end
        end
    end
end

function task.delay(sec, f, ...)
    local t = task.spawn(f, ...)
    t.wakeTime = os.clock() + sec
    return t
end

return task
