require "TorchFix_Network"

AttachedLightManager = {}

local function isLightItem(item)
    return item ~= nil and (instanceof(item,"Drainable") and item:getLightStrength() > 0.001)
end

local function setupLightAttachment(player)
    
    local outData = nil
    local attachedItems = player:getAttachedItems()
    for i = 0, attachedItems:size() - 1 do
        local item = attachedItems:getItemByIndex(i)
        if isLightItem(item) then

            outData = outData or {}
            outData[i] = {}
            local lightAttachment = outData[i]

            -- lightAttachment.slotType = item:getAttachmentType()
            -- lightAttachment.itemFullType = item:getType()
            -- lightAttachment.battery = item:getUsedDelta()
            lightAttachment.itemID = item:getID()
            lightAttachment.isActivated = item:isActivated()

        end
    end

    return outData
    
end

---check if the given table is a valid AttachedLightManager lights table
---@param table table
---@return boolean
AttachedLightManager.isValid = function (table)

    if table == nil then
        return false
    end

    for i,light in pairs(table) do
        if light.itemID == nil or light.isActivated == nil then
            return false
        end
    end

    return true

end

function AttachedLightManager:new(playerObj)

    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.chr = playerObj
    o.lights = setupLightAttachment(playerObj)
    o.remoteUpdateLists = nil
    o.remoteUpdateCount = 0

    if o.lights ~= nil then
        sendClientCommand(playerObj, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitToServer, o.lights)
    end

    sendClientCommand(playerObj, TorchFixNetwork.Module, TorchFixNetwork.Commands.requestAttachedLights, nil)

    return o
end

function AttachedLightManager:addRemoteUpdateLists(playerID,lights)
    -- self.remoteUpdateLists = remoteUpdateLists
    if self.remoteUpdateLists == nil then
        self.remoteUpdateLists = {}
    end

    self.remoteUpdateLists[playerID] = lights
end

function AttachedLightManager:refresh(player)
    
    if player ~= self.chr then return end

    local attachedItems = player:getAttachedItems()
    local currentLights = {}

    local preActivateLights = nil

    for i = 0, attachedItems:size() - 1 do
        local item = attachedItems:getItemByIndex(i)
        if isLightItem(item) then
            currentLights[i] = {}
            local lightItem = currentLights[i]

            -- lightAttachment.slotType = item:getAttachmentType()
            -- lightAttachment.itemType = item:getType()
            -- lightAttachment.battery = item:getUsedDelta()
            lightItem.itemID = item:getID()
            lightItem.isActivated = item:isActivated()

            if item:isActivated() then
                preActivateLights = preActivateLights or {}
                preActivateLights[i] = lightItem
            end

        end
    end

    local isSame = true

    -- Remove lights that are no longer attached
    if self.lights ~= nil then
        for i,light in pairs(self.lights) do
            if currentLights[i] == nil then
                self.lights[i] = nil
                isSame = false
            end
        end
    end


    -- Add new lights
    for i,light in pairs(currentLights) do
        if self.lights == nil or self.lights[i] == nil then
            self.lights = self.lights or {}
            self.lights[i] = light
            isSame = false
        end
    end

    if not isSame then
        self:sendToServer()
        if preActivateLights ~= nil then
            self:transmitToClients(preActivateLights)
        end
    end


end

function AttachedLightManager:getOnlineID()
    return self.chr:getOnlineID()
end

function AttachedLightManager:remotePlayerUpdate()
    
    if self.remoteUpdateLists == nil then return end
    
    for playerID,lightAttachment in pairs(self.remoteUpdateLists) do

        local remotePlayer = getPlayerByOnlineID(playerID)

        if remotePlayer ~= nil then

            local remoteAttachedItems = remotePlayer:getAttachedItems()
            for attachedIndex,lightItem in pairs(lightAttachment) do

                local item = remoteAttachedItems:getItemByIndex(attachedIndex)
                if isLightItem(item) then
                    item:setActivated(lightItem.isActivated)
                    item:setUsedDelta(1.0)
                end

            end

        end

    end

    self.remoteUpdateCount = self.remoteUpdateCount + 1
    
    -- This is a naive solution to handle a situation when player is attaching a light item that is already activated
    -- and the data is sent to the server before the light item is properly propagates to clients.
    if self.remoteUpdateCount == 2 then
        self.remoteUpdateCount = 0
        self.remoteUpdateLists = nil
    end

end



local localPairs = pairs

function AttachedLightManager:onOneMinute()
    
    self:remotePlayerUpdate()

end

function AttachedLightManager:playerUpdate(player)
    
    if player ~= self.chr then return end

    self:remotePlayerUpdate()

    if self.lights == nil then return end

    local hasLightChanged = false
    local attachedItems = player:getAttachedItems()
    local lightStates = {}

    for attachedIndex, lightItem in localPairs(self.lights) do
        local item = attachedItems:getItemByIndex(attachedIndex)
        local isActivatedLastInit = lightItem.isActivated

        if isLightItem(item) then
            -- update light item if it doesn't follow vanilla light toggle
            local isEmittingLight = item:isEmittingLight()
            if isEmittingLight ~= isActivatedLastInit then
                hasLightChanged = true

                lightStates[attachedIndex] = self.lights[attachedIndex]
                lightStates[attachedIndex].isActivated = isEmittingLight
            end
        end
    end

    if hasLightChanged then
        self:transmitToClients(lightStates)
    end

end

function AttachedLightManager:transmitToClients(lightStates)
    sendClientCommand(self.chr, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitToClients, lightStates)
end

function AttachedLightManager:getAttachedLights()
    return self.lights
end

function AttachedLightManager:sendToServer()
    sendClientCommand(self.chr, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitToServer, self.lights)
end

return AttachedLightManager