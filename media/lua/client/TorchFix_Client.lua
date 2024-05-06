require "TorchFix_Main"

TF_ClientCommands = {}
TF_ClientCommands.TorchFixModule = {}

TF_ClientCommands.TorchFixModule.SendDefferedUpdate = function (args)
   
    if args == nil then return end

    local senderID = args.senderID

    if senderID == getPlayer():getOnlineID() then return end

    local modData = args.modData

    local copyDefferedUpdateList = TorchFix.defferredUpdateList:getCopy()

    copyDefferedUpdateList[senderID] = modData

    TorchFix.defferredUpdateList:set(copyDefferedUpdateList)

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

TF_ClientCommands.TorchFixModule.SetActivate = function(args)
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
    if TF_ClientCommands[module] and TF_ClientCommands[module][command] then
        TF_ClientCommands[module][command](args)
    end
end


Events.OnServerCommand.Add(onServerToClient)


return TF_ClientCommands
