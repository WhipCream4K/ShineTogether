require "Light/PlayerPointLight"

PlayerPointLight = PlayerPointLight or {}
PlayerPointLight.Manager = PlayerPointLight.Manager or {}

local Manager = PlayerPointLight.Manager
local localGetSquare = getSquare

Manager.onPlayerUpdate = function (player)
    
    Manager.updateDeferredPointLights()
    Manager.updateActivePointLights()

end


Manager.forceRemoveLights = function (playerID)
    
    local lights = Manager.getLights(playerID)

    for _, pointLight in ipairs(lights) do
        pointLight:_remove()
    end

    Manager.removeActiveLights(playerID)
    Manager.removeDeferredLights(playerID)
end

Manager.removeLight = function (playerID,index)
    
    local lights = Manager.getLights(playerID)

    if lights[index] == nil then
        return
    end

    lights[index] = nil
end

Manager.updateDeferredPointLights = function ()
    
    local deferredLights = Manager.getDeferredLights()

    if deferredLights == nil then
        return
    end

    for playerID, lights in pairs(deferredLights) do
        local targetPlayer = getPlayerByOnlineID(playerID)
        if targetPlayer == nil then
            Manager.forceRemoveLights(playerID)
        else

            local playerX = targetPlayer:getX()
            local playerY = targetPlayer:getY()
            local playerZ = targetPlayer:getZ()

            -- check if this player is loaded in this client or not

            local square = localGetSquare(playerX, playerY, playerZ)
            if square ~= nil then
                
                for index, pointLight in pairs(lights) do
                    if not Manager.isLightExist(playerID,index) then
                        Manager.removeDeferredLight(playerID,index)
                    else
                        pointLight:update(false)

                        Manager.addActiveLight(playerID,index,pointLight)
                    end
                end

                Manager.removeDeferredLights(playerID)

            end

        end
    end

end

Manager.updateActivePointLights = function ()
    
    local activeLights = Manager.getActiveLights()

    if activeLights == nil then
        return
    end

    for playerID, lights in pairs(activeLights) do
        local targetPlayer = getPlayerByOnlineID(playerID)
        if targetPlayer == nil then
            Manager.forceRemoveLights(playerID)
        else

            local playerX = targetPlayer:getX()
            local playerY = targetPlayer:getY()
            local playerZ = targetPlayer:getZ()

            -- check if this player is loaded in this client or not

            local square = localGetSquare(playerX, playerY, playerZ)
            if square ~= nil then
                
                -- reverse loop to avoid index remapping
                for index, pointLight in pairs(lights) do
                    if not Manager.isLightExist(playerID,index) then
                        Manager.removeActiveLight(playerID,index)
                    else
                        if pointLight:isActive() then
                            pointLight:update(targetPlayer:isPlayerMoving())
                        else
                            pointLight:destroy()
                        end
                    end
                end
            
            else

                Manager.addDeferredLights(playerID,lights)
                Manager.removeActiveLights(playerID)

            end

        end
    end

end

Manager.isLightExist = function (playerID,index)
    return Manager.instances[playerID] ~= nil and Manager.instances[playerID][index] ~= nil
end

Manager.getActiveLights = function ()
    Manager.activeLights = Manager.activeLights or {}
    return Manager.activeLights
end

Manager.addActiveLight = function (playerID,index,playerLightInstance)
    Manager.activeLights = Manager.activeLights or {}
    Manager.activeLights[playerID] = Manager.activeLights[playerID] or {}
    Manager.activeLights[playerID][index] = playerLightInstance
end

Manager.removeActiveLight = function (playerID,index)
    
    local lights = Manager.getActiveLights()
    
    if lights[playerID] == nil then
        return
    end
    
    lights[playerID][index] = nil
    
end

Manager.removeActiveLights = function (playerID)
    Manager.activeLights[playerID] = nil
end

Manager.getDeferredLights = function ()
    Manager.deferredLights = Manager.deferredLights or {}
    return Manager.deferredLights
end

Manager.addDeferredLights = function (playerID,lights)
    Manager.deferredLights = Manager.deferredLights or {}
    Manager.deferredLights[playerID] = lights
end

Manager.addDeferredLight = function (playerID,index,playerLightInstance)
    
    Manager.deferredLights = Manager.deferredLights or {}
    Manager.deferredLights[playerID] = Manager.deferredLights[playerID] or {}
    Manager.deferredLights[playerID][index] = playerLightInstance
    
end

Manager.removeDeferredLight = function (playerID,index)
    
    local lights = Manager.getDeferredLights()
    
    if lights[playerID] == nil then
        return
    end
    
    lights[playerID][index] = nil
    
end

Manager.removeDeferredLights = function (playerID)
    Manager.deferredLights[playerID] = nil
end

Manager.getLights = function (playerID)
    return Manager.instances[playerID]
end

Manager.getLight = function (playerID,index)
    return Manager.instances[playerID] and Manager.instances[playerID][index]
end

Manager.getLightCountFromPlayerID = function (playerID)
    return Manager.instances[playerID] and #Manager.instances[playerID] or 0
end

Manager.addLight = function (playerID,playerLightInstance)
    
    Manager.instances[playerID] = Manager.instances[playerID] or {}
    local index = #Manager.instances[playerID] + 1
    Manager.instances[playerID][index] = playerLightInstance

    Manager.addDeferredLight(playerID,index,playerLightInstance)

end

Manager.onFadeToWorld = function ()


    sendClientCommand(getPlayer(), PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.requestAll, nil)

    Events.OnPlayerUpdate.Add(Manager.onPlayerUpdate)

    Events.EveryOneMinute.Remove(Manager.onFadeToWorld)

end

Manager.onPlayerSpawn = function (playerIndex)
    if playerIndex == 0 then
        
        PlayerPointLight.Manager.instances = {}

        Events.EveryOneMinute.Add(Manager.onFadeToWorld)
    end
end

Events.OnCreatePlayer.Add(Manager.onPlayerSpawn)

return PlayerPointLight.Manager