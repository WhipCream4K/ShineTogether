
AttachedLightManager = {}
AttachedLightManager.instances = {}

local function isLightItem(item)
    return item ~= nil and (instanceof(item,"Drainable") and item:getLightStrength() > 0.001)
end

local function setupLightAttachment(player)
    
    local outData = {}
    local attachedItems = player:getAttachedItems()
    for i = 0, attachedItems:size() - 1 do
        local item = attachedItems:getItemByIndex(i)
        if isLightItem(item) then
            
            local itemID = item:getID()
            outData[itemID] = {}
            local lightAttachment = outData[itemID]

            lightAttachment.slotType = item:getAttachmentType()
            lightAttachment.itemFullType = item:getType()
            lightAttachment.battery = item:getUsedDelta()
            lightAttachment.isActivated = item:isActivated()

        end
    end

    return outData
    
end

local function onClothingUpdated(player)

    if isClient() then
        
        if not player:isDead() then
            for _,lightAttachment in ipairs(AttachedLightManager.instances) do
                lightAttachment:update(player)
            end
        end

    end
    
end

Events.OnClothingUpdated.Add(onClothingUpdated)

function AttachedLightManager:new(playerObj)

    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.chr = playerObj
    o.lights = setupLightAttachment(playerObj)
    o.onlineID = playerObj:getOnlineID()
    AttachedLightManager.instances[o.onlineID] = o

    sendClientCommand(playerObj, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.transmitAttachedLights, o.lights)
    sendClientCommand(playerObj, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.requestAttachedLights, nil)

    return o
end

function AttachedLightManager:update(player)
    
    if player ~= self.chr then return end

    local attachedItems = player:getAttachedItems()
    local currentLights = {}

    local isLightPreActivated = false

    for i = 0, attachedItems:size() - 1 do
        local item = attachedItems:getItemByIndex(i)
        if isLightItem(item) then
            currentLights[i] = {}
            local lightAttachment = currentLights[i]

            lightAttachment.slotType = item:getAttachmentType()
            lightAttachment.itemType = item:getType()
            lightAttachment.battery = item:getUsedDelta()
            lightAttachment.isActivated = item:isActivated()

            if lightAttachment.isActivated then
                isLightPreActivated = true
            end

        end
    end

    local isSame = true

    -- Remove lights that are no longer attached
    for i,light in pairs(self.lights) do
        if currentLights[i] == nil then
            self.lights[i] = nil
            isSame = false
        end
    end

    -- Add new lights
    for i,light in pairs(currentLights) do
        if self.lights[i] == nil then
            self.lights[i] = light
            isSame = false
        end
    end

    if not isSame then
        self:sendToServer()
    end

    if isLightPreActivated then
        self:sendToClients()
    end


end

function AttachedLightManager:getAttachedLights()
    return self.lights
end

function AttachedLightManager:sendToServer()
    sendClientCommand(self.chr, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.transmitAttachedLights, self.lights)
end

function AttachedLightManager:sendToClients()
    sendClientCommand(self.chr, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.SendDefferedUpdate, self.lights)
end

function AttachedLightManager:delete()
    table.remove(AttachedLightManager.instances, self.instanceIdx)
end

return AttachedLightManager