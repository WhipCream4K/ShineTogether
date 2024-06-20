require "TorchFix_Main"
local Network = require "TorchFix_Network"
require "TorchFix_AttachedLightManager"

TorchFixClient = {}
TorchFixClient[Network.Module] = {}

local ClientOps = TorchFixClient[Network.Module]

ClientOps[Network.Commands.transmitToClients] = function (args)

    if args == nil then return end

    local attachLightManager = TorchFix.getAttachedLightManager()
    if attachLightManager == nil then return end

    local remotePlayer = args.senderID
    if args.senderID == attachLightManager:getOnlineID() then return end
    if getPlayerByOnlineID(remotePlayer) == nil then return end

    local lightStates = args.lights

    attachLightManager:addRemoteUpdateLists(remotePlayer, lightStates)

end

ClientOps[Network.Commands.requestAttachedLights] = function(args)

    if args == nil then return end

    local attachLightManager = TorchFix.getAttachedLightManager()
    if attachLightManager == nil then return end
    
    for playerID, lights in pairs(args) do
        attachLightManager:addRemoteUpdateLists(playerID, lights)
    end

end

local function onServerToClient(module, command, args)
    if TorchFixClient[module] and TorchFixClient[module][command] then
        TorchFixClient[module][command](args)
    end
end


Events.OnServerCommand.Add(onServerToClient)


return TorchFixClient
