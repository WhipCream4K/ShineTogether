require "TorchFix_Network"

AttachedLightManager = {}

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

    sendClientCommand(playerObj, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitAttachedLights, o.lights)
    sendClientCommand(playerObj, TorchFixNetwork.Module, TorchFixNetwork.Commands.requestAttachedLights, nil)

    return o
end

function AttachedLightManager:setRemoteUpdateLists(remoteUpdateLists)
    self.remoteUpdateLists = remoteUpdateLists
end

function AttachedLightManager:refresh(player)
    
    if player ~= self.chr then return end

    local attachedItems = player:getAttachedItems()
    local currentLights = {}

    local preActivateLights = {}

    for i = 0, attachedItems:size() - 1 do
        local item = attachedItems:getItemByIndex(i)
        if isLightItem(item) then
            currentLights[i] = {}
            local lightAttachment = currentLights[i]

            -- lightAttachment.slotType = item:getAttachmentType()
            -- lightAttachment.itemType = item:getType()
            -- lightAttachment.battery = item:getUsedDelta()
            lightAttachment.itemID = item:getID()
            lightAttachment.isActivated = item:isActivated()

            if item:isActivated() then
                preActivateLights[i] = lightAttachment
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
        if preActivateLights ~= nil then
            self:transmitLightStates(preActivateLights)
        end
    end


end

function AttachedLightManager:remotePlayerUpdate()
    
    if self.remoteUpdateLists == nil then return end
    
    for playerID,lightAttachment in pairs(self.remoteUpdateLists) do

        local remotePlayer = getPlayerByOnlineID(playerID)

        if remotePlayer ~= nil then

            local remoteAttachedItems = remotePlayer:getAttachedItems()
            for attachedIndex,lightItem in pairs(lightAttachment) do

                local item = remoteAttachedItems:getItemByIndex(attachedIndex)
                if item ~= nil then
                    item:setActivated(lightItem.isActivated)
                end

            end

        end

    end

    self.remoteUpdateLists = nil

end

local localPairs = pairs
function AttachedLightManager:playerUpdate(player)
    
    if player ~= self.chr then return end

    self:remotePlayerUpdate()

    local hasLightChanged = false
    local attachedItems = player:getAttachedItems()
    local lightStates = {}

    for attachedIndex, lightItem in localPairs(self.lights) do
        local item = attachedItems:getItemByIndex(attachedIndex)
        local isActivatedLastInit = lightItem.isActivated

        if TorchFix.isLightItem(item) then
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
        self:transmitLightStates(lightStates)
    end

end

function AttachedLightManager:transmitLightStates(lightStates)
    sendClientCommand(self.chr, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitLightState, lightStates)
end

function AttachedLightManager:getAttachedLights()
    return self.lights
end

function AttachedLightManager:sendToServer()
    sendClientCommand(self.chr, TorchFixNetwork.Module, TorchFixNetwork.Commands.transmitAttachedLights, self.lights)
end

function AttachedLightManager:delete()
    table.remove(AttachedLightManager.instances, self.instanceIdx)
end

return AttachedLightManager