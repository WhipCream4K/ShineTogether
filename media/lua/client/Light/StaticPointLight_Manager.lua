require "Light/StaticPointLight"

StaticPointLight = StaticPointLight or {}
StaticPointLight.Manager = StaticPointLight.Manager or {}

local Manager = StaticPointLight.Manager

local localGetSquare = getSquare

Manager.onPlayerUpdate = function (player)
    
    Manager.updateDeferredPointLights()
    Manager.updateActivePointLights()

end

Manager.removeLight = function (uniqueID)
    
    local light = Manager.getLight(uniqueID)
    
    if light == nil then
        return
    end

    light = nil
end

Manager.updateDeferredPointLights = function ()
    
    local deferredLights = Manager.getDeferredLights()

    if deferredLights == nil then
        return
    end

    for uniqueID, light in pairs(deferredLights) do
        local square = localGetSquare(light.x, light.y, light.z)
        if not Manager.isLightExist(uniqueID) == nil then
            Manager.removeDeferredLight(uniqueID)
        elseif square ~= nil then

            light:setActive(true)

            Manager.removeDeferredLight(uniqueID)
            Manager.addActiveLight(uniqueID,light)
        end
    end

end

Manager.updateActivePointLights = function ()
    
    local activeLights = Manager.getActiveLights()

    if activeLights == nil then
        return
    end

    for uniqueID,light in pairs(activeLights) do
        local square = localGetSquare(light.x, light.y, light.z)
        if not Manager.isLightExist(uniqueID) then
            Manager.removeActiveLight(uniqueID)
        elseif square == nil then

            light:destroy()

            Manager.removeActiveLight(uniqueID)
            Manager.addDeferredLight(uniqueID,light)
        end

    end

end

Manager.isLightExist = function (uniqueID)
    return Manager.instances[uniqueID] ~= nil
end

Manager.getActiveLights = function ()
    Manager.activeLights = Manager.activeLights or {}
    return Manager.activeLights
end

Manager.addActiveLight = function (uniqueID,playerLightInstance)
    Manager.activeLights = Manager.activeLights or {}
    Manager.activeLights[uniqueID] = playerLightInstance
end

Manager.removeActiveLight = function (uniqueID)
    
    local light = Manager.getActiveLights()[uniqueID]

    if light == nil then
        return
    end

    light = nil
    
end

Manager.removeActiveLights = function (playerID)
    Manager.activeLights[playerID] = nil
end

Manager.getDeferredLights = function ()
    Manager.deferredLights = Manager.deferredLights or {}
    return Manager.deferredLights
end

Manager.addDeferredLight = function (uniqueID, playerLightInstance)
    
    Manager.deferredLights = Manager.deferredLights or {}
    Manager.deferredLights[uniqueID] = playerLightInstance
    
end

Manager.removeDeferredLight = function (uniqueID)
    
    local light = Manager.getDeferredLights()[uniqueID]
    
    if light == nil then
        return
    end
    
    light = nil
    
end

Manager.getLights = function ()
    return Manager.instances
end

Manager.getLight = function (uniqueID)
    return Manager.instances[uniqueID]
end

Manager.getLightCount = function ()
    return Manager.instances and #Manager.instances or 0
end

Manager.addLight = function (uniqueID,playerLightInstance)
    
    Manager.instances[uniqueID] = Manager.instances[uniqueID] or {}
    Manager.instances[uniqueID] = playerLightInstance

    Manager.addActiveLight(uniqueID,playerLightInstance)

end

Manager.onFadeToWorld = function ()

    sendClientCommand(getPlayer(), StaticPointLight_Network.Module, StaticPointLight_Network.Commands.requestAll, nil)

    Events.OnPlayerUpdate.Add(Manager.onPlayerUpdate)

    Events.EveryOneMinute.Remove(Manager.onFadeToWorld)

end

Manager.onPlayerSpawn = function (playerIndex)
    if playerIndex == 0 then
        
        StaticPointLight.Manager.instances = {}

        Events.EveryOneMinute.Add(Manager.onFadeToWorld)
    end
end

Events.OnCreatePlayer.Add(Manager.onPlayerSpawn)

return StaticPointLight.Manager