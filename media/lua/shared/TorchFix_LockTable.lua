require "TorchFix_Mutex"

LockTable = {}

function LockTable:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.data = {}
    o.mutex = Mutex:new()
    return o
end

function LockTable:getCopy()
    self.mutex:lock()
    local copy = {}
    for k,v in pairs(self.data) do
        copy[k] = v
    end
    self.mutex:unlock()
    return copy
end

function LockTable:pop()
    local outData = nil
    self.mutex:lock()
    outData = self.data
    self.data = {}
    self.mutex:unlock()

    return outData
end

function LockTable:size()
    local count = 0
    for _ in pairs(self.data) do count = count + 1 end
    return count
end

function LockTable:set(data)
    self.mutex:lock()
    self.data = data
    self.mutex:unlock()
end

function LockTable:clear()
    self.mutex:lock()
    self.data = {}
    self.mutex:unlock()
end

local function internEmpty(inTable)
    if inTable == nil then return true end
    for _,_ in pairs(inTable) do
        return false
    end
    return true
end

function LockTable:isEmpty()
    self.mutex:lock()
    local empty = internEmpty(self.data)
    self.mutex:unlock()
    return empty
end

return LockTable