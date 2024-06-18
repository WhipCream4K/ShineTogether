require "TorchFix_ModData"
require "TorchFix_LockTable"
require "TorchFix_AttachedLightManager"

TorchFix = {}

-- Main variables
TorchFix.AttachLightManager = nil
TorchFix.defferredUpdateLights = nil


TorchFix.isTableEmpty = function(table)
    if table == nil then return true end
    
    for _,_ in pairs(table) do
        return false
    end

    return true
end

TorchFix.isLightItem = function(item)
    return item ~= nil and (instanceof(item,"Drainable") and item:getLightStrength() > 0.001)
end

TorchFix.defferedUpdateRemotePlayers = function ()
    
    if TorchFix.defferredUpdateLights:isEmpty() then return end

    -- for now we just clear the list
    local defferedUpdateList = TorchFix.defferredUpdateLights:pop()

    for remotePlayerID, attachedItems in pairs(defferedUpdateList) do

        local remotePlayer = getPlayerByOnlineID(remotePlayerID)
        if remotePlayer ~= nil then

            local remoteAttachedItems = remotePlayer:getAttachedItems()

            -- we assume that the attachedIndex that we got from the server is the same as the client
            for attachedIndex, lightItem in pairs(attachedItems) do

                if lightItem.isActivated then

                    local item = remoteAttachedItems:getItemByIndex(attachedIndex)
    
                    if item ~= nil and item:canEmitLight() then
        
                        item:setActivated(lightItem.isActivated)
                        item:setUsedDelta(lightItem.battery)
        
                    end
                end

            end
        end

    end

end

local lpairs = pairs
TorchFix.stepUpdate = function()
    local player = getPlayer()

    if player == nil or player:isDead() then return end

    -- update deferred list
    -- the idea of deffered update is just to let the server have enough time to sync all the players
    -- attached items, so that the every client can update the attached items without problems

    -- ofc you can put this in player update function to maybe make it update faster but I prefer this way
    TorchFix.defferedUpdateRemotePlayers()

    if TorchFix.AttachLightManager:isEmpty() then return end


    -- you could always not overwriting all the vanila lua actions and just let the stepUpdate do the work
    -- depending on where you put the stepUpdate, the light sync for remote players will be different

    -- the problem is modData needs to track every light attachable items on the player
    -- and mainly I don't want to loop through all the attached items every time the stepUpdate is called

    local attachedItems = player:getAttachedItems()
    local modData = TorchFix.AttachLightManager:getRef()

    local keysToRemove = {}
    local hasLightChanged = false

    for attachedIndex, lightItem in lpairs(modData) do
        local item = attachedItems:getItemByIndex(attachedIndex)
        local isActivatedLastInit = lightItem.isActivated

        if TorchFix.isLightItem(item) then
            -- update light item if it doesn't follow vanilla light toggle
            if item:isEmittingLight() ~= isActivatedLastInit then
                TorchFix.syncRemoteTorches(player, attachedIndex, item:getUsedDelta(), not isActivatedLastInit)
            end
        else
            hasLightChanged = true
            table.insert(keysToRemove, attachedIndex)
        end
    end

    if hasLightChanged then
        for _, key in ipairs(keysToRemove) do
            modData[key] = nil
        end
    end

end

TorchFix.syncRemoteTorches = function(player, attachedIndex, battery, isActivated)

    local dataTable = {
        [TorchFixNetwork.ModData.OnlineID] = player:getOnlineID(),
        [TorchFixNetwork.ModData.AttachedLightIndex] = attachedIndex,
        [TorchFixNetwork.ModData.Battery] = battery,
        [TorchFixNetwork.ModData.IsActivated] = isActivated or false
    }

    sendClientCommand(player, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.SetActivate, dataTable)

    -- sync remote torces is called when the player is doing some actions that will change the state of the attached items
    local modData = TorchFix.AttachLightManager:getRef()
    modData[attachedIndex].isActivated = isActivated
    modData[attachedIndex].battery = battery

    -- send the update to the server
    TorchFix.AttachLightManager:transmit()
end

TorchFix.setActivatedAttachedItemForRemotePlayer = function(playerID, attachedIndex, batteryPercentage, isActivated)
    if isClient() then
        local player = getPlayerByOnlineID(playerID)

        if player ~= nil then

            local attachedItems = player:getAttachedItems()
            local item = attachedItems:getItemByIndex(attachedIndex)

            if TorchFix.isLightItem(item) then

                item:setActivated(isActivated)
                item:setUsedDelta(batteryPercentage) -- this is useless because the game doesn't have any update for remote players' items
            end
        end
    end
end

-- local function setUpPlayerLightAttachments(player)
--     local modData = {}

--     local attachedItems = player:getAttachedItems()

--     if attachedItems:size() <= 0 then
--         return modData
--     end

--     for i = 0, attachedItems:size() - 1 do
--         local attachItem = attachedItems:getItemByIndex(i)
--         if TorchFix.isLightItem(attachItem) then

--             modData[i] = {}
--             local lightAttachment = modData[i]

--             lightAttachment.slotType = attachItem:getAttachmentType()
--             lightAttachment.itemFullType = attachItem:getFullType()
--             lightAttachment.battery = attachItem:getUsedDelta()
--             lightAttachment.isActivated = attachItem:isActivated()
--         end
--     end

--     return modData
-- end

-- TorchFix.isPlayerSpawning = false

-- TorchFix.receiveModDataAfterSpawning = function(key, modData)

--     if ModDataHandler.checkGlobalModDataKey(key) and TorchFix.isPlayerSpawning and modData then

--         local copyDefferedUpdateList = TorchFix.defferredUpdateLights:getCopy()

--         for playerID, attachedItems in pairs(modData) do

--             if playerID ~= getPlayer():getOnlineID() then
--                 local remotePlayer = getPlayerByOnlineID(playerID)
--                 if remotePlayer then
--                     copyDefferedUpdateList[playerID] = attachedItems
--                 end
--             end
--         end

--         TorchFix.defferredUpdateLights:set(copyDefferedUpdateList)
--     end
-- end

TorchFix.onCreatePlayer = function(playerIndex)
    
    if playerIndex == 0 then
        
        -- this is for the time when the player is dead and want to start a new game
        Events.EveryOneMinute.Add(TorchFix.onFadeToWorld)
        Events.OnClothingUpdated.Add(TorchFix.onClothingUpdated)
        
    end

end

-- TorchFix.onPlayerDeath = function(player)

--     TorchFix.attachedLight:clear()
--     -- TorchFix.attachedLight:transmit()
--     TorchFix.isPlayerSpawning = false
    
--     Events.EveryOneMinute.Remove(TorchFix.stepUpdate)
--     Events.OnCreatePlayer.Add(TorchFix.onCreatePlayer)

-- end

-- TorchFix.onClothingUpdated = function (isoGameCharacter)

--     if isClient() then

--         local player = getPlayer()
--         if player == nil or player:isDead() then return end

--         -- not sure if it does anything
--         -- but mainly I don't want to update the attached items for other local players
--         if isoGameCharacter ~= player then return end

--         if getDebug() then
--             print("isoGameCharacter type: " .. tostring(isoGameCharacter))
--             print("Clothing updated")
--         end


--         local attachedItems = player:getAttachedItems()
--         local modData = TorchFix.AttachLightManager:getRef()

--         local lightActivatedAfterPickup = false

--         local currTrackedLight = {}

--         for i = 0, attachedItems:size() - 1 do
            
--             local item = attachedItems:getItemByIndex(i)
--             if TorchFix.isLightItem(item) then
                    
--                 currTrackedLight[i] = {}
--                 local lightItem = currTrackedLight[i]
--                 lightItem.slotType = item:getAttachmentType()

--                 if getDebug() then
--                     print("Item attached slot: " .. (item:getAttachedSlot() or "nil"))
--                     print("Item attachment type: " .. (item:getAttachmentType() or "nil"))
--                     print("Item attached to model: " .. (item:getAttachedToModel() or "nil"))
--                 end


--                 lightItem.itemFullType = item:getFullType()
--                 lightItem.battery = item:getUsedDelta()
--                 lightItem.isActivated = item:isActivated()

--                 if lightItem.isActivated then
--                     lightActivatedAfterPickup = true
--                 end
--             end

--         end

--         -- TODO: Handle the case when the player is damage by zombie and it resets the attached items
--         -- resulting in garbage data send to server

--         for attachedIndex,lightItem in pairs(currTrackedLight) do
--             local item = modData[attachedIndex]
--             if item == nil then
--                 modData[attachedIndex] = lightItem
--             end
--         end

--         if TorchFix.isTableEmpty(currTrackedLight) and not TorchFix.AttachLightManager:isEmpty() then
--             TorchFix.AttachLightManager:clear()
--             TorchFix.AttachLightManager:transmit()
--         else
--             TorchFix.AttachLightManager:transmit()
--         end

--         if lightActivatedAfterPickup and not TorchFix.isTableEmpty(currTrackedLight) then
--             sendClientCommand(player, TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.SendDefferedUpdate, currTrackedLight)
--         end

--     end

-- end

-- TorchFix.onPlayerSpawn = function (playerIndex)

--     -- if isClient() then

--     --     if not TorchFix.isPlayerSpawning then

--     --         TorchFix.isPlayerSpawning = true

--     --         if TorchFix.attachedLight == nil then
--     --             TorchFix.attachedLight = ModDataHandler:new()
--     --         end

--     --         local mainPlayer = getPlayer()

--     --         local globalModDataKey = ModDataHandler.getGlobalModDataKeyWithPlayer(mainPlayer)
    
--     --         local modData = setUpLocalModData(mainPlayer)

--     --         TorchFix.attachedLight:init(globalModDataKey, modData)
--     --         TorchFix.attachedLight:transmit()
--     --         ModDataHandler.request(ModDataHandler.getGlobalModDataKey())

--     --         Events.OnClothingUpdated.Add(TorchFix.onClothingUpdated)

--     --         Events.EveryOneMinute.Remove(TorchFix.onPlayerSpawn)

--     --     end
--     -- end
-- end

TorchFix.onFadeToWorld = function ()

    local player = getPlayer()
    if player == nil then return end

    TorchFix.AttachLightManager = AttachedLightManager:new(player)

    Events.EveryOneMinute.Remove(TorchFix.onFadeToWorld)
end

Events.OnCreatePlayer.Add(TorchFix.onCreatePlayer)


-- local function onGameStart()

--     Events.EveryOneMinute.Add(TorchFix.onPlayerSpawn)
--     Events.OnReceiveGlobalModData.Add(TorchFix.receiveModDataAfterSpawning)
--     Events.OnPlayerDeath.Add(TorchFix.onPlayerDeath)
--     Events.EveryOneMinute.Add(TorchFix.stepUpdate)

--     TorchFix.attachedLight = ModDataHandler:new()
--     TorchFix.defferredUpdateList = LockTable:new()

-- end

-- Events.OnGameStart.Add(onGameStart)

return TorchFix
