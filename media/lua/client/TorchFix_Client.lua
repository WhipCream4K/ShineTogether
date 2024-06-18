require "TorchFix_Main"
local Network = require "TorchFix_Variables"

TorchFixClient = {}
TorchFixClient[Network.ModuleName] = {}

local ClientOps = TorchFixClient[Network.ModuleName]

ClientOps[Network.Commands.SendDefferedUpdate] = function (args)
   
    if args == nil then return end

    local senderID = args.senderID

    if senderID == getPlayer():getOnlineID() then return end

    local modData = args.modData

    local copyDefferedUpdateList = TorchFix.defferredUpdateLights:getCopy()

    copyDefferedUpdateList[senderID] = modData

    TorchFix.defferredUpdateLights:set(copyDefferedUpdateList)

    -- if getDebug() then
    --     for playerID, modData in pairs(copyDefferedUpdateList) do
    --         print("PlayerID: " .. playerID)
    --         for attchedIndex,lightItem in pairs(modData) do
    --             print("Attached Index: " .. attchedIndex)
    --             for i,v in pairs(lightItem) do
    --                 print(tostring(i),tostring(v))
    --             end
    --         end
    --     end
    -- end

end

ClientOps[Network.Commands.SetActivate] = function(args)
    local playerID = args[TorchFixNetwork.ModData.OnlineID]
    if playerID == getPlayer():getOnlineID() then
        return
    end

    local attachedIndex = args[TorchFixNetwork.ModData.AttachedLightIndex]
    local batteryPercentage = args[TorchFixNetwork.ModData.Battery]
    local isActivated = args[TorchFixNetwork.ModData.IsActivated]

    TorchFix.setActivatedAttachedItemForRemotePlayer(playerID, attachedIndex, batteryPercentage, isActivated)
end

local function onServerToClient(module, command, args)
    if TorchFixClient[module] and TorchFixClient[module][command] then
        TorchFixClient[module][command](args)
    end
end


Events.OnServerCommand.Add(onServerToClient)


return TorchFixClient
