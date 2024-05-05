
-- Define a mutex-like construct
Mutex = {}

function Mutex:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.locked = false
    o.waitingCoroutines = {}
    return o
end

function Mutex:lock()
    while self.locked do
        -- if the mutex is locked, yield the coroutine
        -- local currentCoroutine = coroutine.running()
        -- table.insert(self.waitingCoroutines, currentCoroutine)
        -- coroutine.yield()
    end
    self.locked = true
end

function Mutex:unlock()
    self.locked = false
    -- local waitingCoroutines = table.remove(self.waitingCoroutines, 1)
    -- if waitingCoroutines then
    --     coroutine.resume(waitingCoroutines)
    -- end
end

return Mutex
