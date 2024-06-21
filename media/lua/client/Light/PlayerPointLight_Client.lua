require "Light/PlayerPointLight"

local Manager = require "Light/PlayerPointLight_Manager"
local Network = require "Light/PlayerPointLight_Network"

if not isClient() then return end

PlayerPointLight_Client = {}
PlayerPointLight_Client[Network.Module] = {}
local ClientOps = PlayerPointLight_Client[Network.Module]

ClientOps[Network.Commands.createRemote] = function (args)
    
    if args == nil then return end

    if getPlayer():getOnlineID() == args.playerID then return end

    local playerID = args.playerID
    local r = args.r
    local g = args.g
    local b = args.b
    local radius = args.radius

    PlayerPointLight:new(playerID,r,g,b,radius)

end


ClientOps[Network.Commands.removeRemote] = function (args)
    
    local player = getPlayer()
    if player == nil then return end

    if player:getOnlineID() == args.playerID then return end

    local playerID = args.playerID
    local index = args.index

    local pointLight = Manager.getLight(playerID,index)

    if getDebug() then
        print("Remove remote point light for playerID: " .. playerID)
        print("index: " .. index)
    end

    pointLight:_remove()

end

ClientOps[Network.Commands.setRemoteActive] = function (args)
    
    local player = getPlayer()
    if player == nil then return end

    if player:getOnlineID() == args.playerID then return end

    local playerID = args.playerID
    local index = args.index
    local active = args.value

    local pointLight = Manager.getLight(playerID,index)

    if pointLight == nil then return end

    if getDebug() then
        print("Set remote active for playerID: " .. playerID)
        print("index: " .. index)
        print("value: " .. tostring(active))
    end

    pointLight:setActive(active)

end

ClientOps[Network.Commands.receiveAll] = function (args)
    
    local player = getPlayer()
    if player == nil then return end

    local clientPlayerID = player:getOnlineID()
    local activePointLights = args

    if activePointLights == nil then return end

    for playerID, pointLights in pairs(activePointLights) do
        for index, pointLight in pairs(pointLights) do

            if playerID ~= clientPlayerID then

                if getDebug() then
                    for key, value in pairs(pointLight) do
                        print(key .. " = " .. tostring(value))
                    end
                end

                local newPointLight = PlayerPointLight:new(playerID,pointLight.r,pointLight.g,pointLight.b,pointLight.radius)
                newPointLight:setActive(pointLight.isActive)
            end

        end
    end

end

local function onServerToClient(module, command, args)
    if PlayerPointLight_Client[module] and PlayerPointLight_Client[module][command] then
        PlayerPointLight_Client[module][command](args)
    end
end

Events.OnServerCommand.Add(onServerToClient)

return PlayerPointLight_Client