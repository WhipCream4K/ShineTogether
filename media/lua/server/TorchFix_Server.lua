require "TorchFix_AttachedLightManager"
local Network = require "TorchFix_Network"

if isClient() then return end


TorchFixServer = {}
TorchFixServer.tempData = nil
TorchFixServer[Network.Module] = {}

local ServerOps = TorchFixServer[Network.Module]
ServerOps[Network.Commands.transmitToServer] = function(player, args)


    local playerID = player:getOnlineID()

    local serverTempData = TorchFixServer.tempData
    serverTempData[playerID] = AttachedLightManager.isValid(args) and args or nil

end

ServerOps[Network.Commands.requestAttachedLights] = function(player, args)
    sendServerCommand(player, Network.Module, Network.Commands.requestAttachedLights, TorchFixServer.tempData)
end

ServerOps[Network.Commands.transmitToClients] = function(player, args)


    local serverTempData = TorchFixServer.tempData
    local playerID = player:getOnlineID()
    serverTempData[playerID] = AttachedLightManager.isValid(args) and args or nil

    local outData = {}
    outData.senderID = player:getOnlineID()
    outData.lights = AttachedLightManager.isValid(args) and args or nil

    print("PlayerID: " .. playerID)
    for attachedIndex, lightItem in pairs(outData.lights) do
        print("Attached Index: " .. attachedIndex)
        for i, v in pairs(lightItem) do
            print(tostring(i), tostring(v))
        end
    end

    sendServerCommand(Network.Module, Network.Commands.transmitToClients, outData)
end

local function onClientCommand(module, command, player, args)
    if TorchFixServer[module] and TorchFixServer[module][command] then
        TorchFixServer[module][command](player, args)
    end
end

local lpairs = pairs
TorchFixServer.onServerStepUpdate = function ()

    if TorchFixServer.tempData == nil then return end

    local serverTempData = TorchFixServer.tempData

    for playerID, _ in lpairs(serverTempData) do
        local player = getPlayerByOnlineID(playerID)
        if player == nil then
            serverTempData[playerID] = nil
            print("Player with onlineID: " .. playerID .. " has disconnected. Removing from serverModData.")
        end
    end
end

local function onGlobalModDataLoad(isNewGame)
    TorchFixServer.tempData = {}
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(TorchFixServer.onServerStepUpdate)
Events.OnInitGlobalModData.Add(onGlobalModDataLoad)
