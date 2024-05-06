require "TorchFix_Variables"
require "TorchFix_Mutex"

ModDataHandler = {}

ModDataHandler.getOnlineIDFromKey = function(key)
    local startPos = string.find(key,":")

    if startPos == nil then
        return false
    end
   
    return tonumber(string.sub(key,startPos + 1))
end

ModDataHandler.getGlobalModDataKeyWithPlayer = function(player)
    return TorchFixNetwork.ModuleName .. ":" .. tostring(player:getOnlineID())
end

ModDataHandler.getGlobalModDataKeyWithOnlineID = function(onlineID)
    return TorchFixNetwork.ModuleName .. ":" .. tostring(onlineID)
end

ModDataHandler.getGlobalModDataKey = function ()
    return TorchFixNetwork.ModuleName
end

ModDataHandler.checkGlobalModDataKey = function(key)
    -- check if the key contains the module name
    return string.find(key,TorchFixNetwork.ModuleName) ~= nil
end

ModDataHandler.getLocalModData = function (player)
    return ModData.getOrCreate(ModDataHandler.getGlobalModDataKeyWithPlayer(player))
end

ModDataHandler.request = function (key)
    ModData.request(key)
end

ModDataHandler.isSameType = function (other)
    if other == nil then return false end
    return other.type == "TorchFixModData"
end

function ModDataHandler:init(key,modData)
    self.key = key
    ModData.add(key,modData)
    self.modData = ModData.get(key)
end

function ModDataHandler:getRef()
    return self.modData
end

function ModDataHandler:getCopy()
    -- self.mutex:lock()
    local copy = {}
    for k,v in pairs(self.modData) do
        copy[k] = v
    end
    -- self.mutex:unlock()
    return copy
end

local function isTableEmpty(t)
    if t == nil then return true end
    for _,_ in pairs(t) do
        return false
    end
    return true
end

function ModDataHandler:isEmpty()
    -- self.mutex:lock()
    local empty = isTableEmpty(self.modData)
    -- self.mutex:unlock()
    return empty
end

function ModDataHandler:add(index,data)
    -- self.mutex:lock()
    self.modData[index] = data
    -- self.mutex:unlock()
end

function ModDataHandler:transmit()
    ModData.transmit(self.key)
end

function ModDataHandler:clear()
    ModData.add(self.key,{})
    self.modData = ModData.get(self.key)
end

function ModDataHandler:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.type = "TorchFixModData"
    o.modData = nil
    o.key = nil
    -- o.mutex = Mutex:new()
    return o
end

return ModDataHandler
