-- require "TorchFix_Variables"
require "TorchFix_Main"

if isClient() then return end

TF_ServerCommands                = {}
TF_ServerCommands.TorchFixModule = {}

TF_Server                        = {}
TF_Server.modData                = {}


TF_ServerCommands.TorchFixModule.SetActivate = function(player, args)
    sendServerCommand(TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.SetActivate, args)
end

TF_ServerCommands.TorchFixModule.SendDefferedUpdate = function(player, args)
    local playerID = player:getOnlineID()

    local outData = {}
    outData.senderID = playerID
    outData.modData = args

    -- print("Call deffered update for all players from playerID: " .. playerID)

    for attachedIndex, lightItem in pairs(args) do
        -- print("Attached Index: " .. attachedIndex)
        for i, v in pairs(lightItem) do
            print(tostring(i), tostring(v))
        end
    end

    sendServerCommand(TorchFixNetwork.ModuleName, TorchFixNetwork.Commands.SendDefferedUpdate, outData)
end

local function onClientCommand(module, command, player, args)
    if TF_ServerCommands[module] and TF_ServerCommands[module][command] then
        TF_ServerCommands[module][command](player, args)
    end
end

local function onRecieveGlobalModData(key, modData)
    if ModDataHandler.checkGlobalModDataKey(key) then
        if getDebug() then
            print("Received global modData with key: " .. key)
        end

        local requesterOnlineID = ModDataHandler.getOnlineIDFromKey(key)

        if requesterOnlineID then
            -- player might want to save to server global mod data
            local globalModData = TF_Server.modData:getRef()
            globalModData[requesterOnlineID] = modData


            for attachedIndex, attachedData in pairs(modData) do
                print("Received attachedIndex: " .. attachedIndex)
                print("SlotType: " .. attachedData.slotType)
                print("ItemFullType: " .. attachedData.itemFullType)
                print("Battery: " .. attachedData.battery)
                print("IsActivated: " .. tostring(attachedData.isActivated))
            end
        end
    end
end

local lpairs = pairs
local function onServerStepUpdate()
    -- we are going to update the modData
    if TF_Server.modData:isEmpty() then return end

    local serverModData = TF_Server.modData:getRef()

    local removeList = {}
    for playerIndex, _ in lpairs(serverModData) do
        local player = getPlayerByOnlineID(playerIndex)
        if player == nil then
            table.insert(removeList, playerIndex)
            print("Player with onlineID: " .. playerIndex .. " has disconnected. Removing from serverModData.")
        end
    end


    for _, playerIndex in lpairs(removeList) do
        serverModData[playerIndex] = nil
    end
end

local function onGlobalModDataLoad(isNewGame)
    -- print("TorchFix Server is starting")
    TF_Server.modData = ModDataHandler:new()
    TF_Server.modData:init(ModDataHandler.getGlobalModDataKey(), {})
end

Events.EveryOneMinute.Add(onServerStepUpdate)
Events.OnInitGlobalModData.Add(onGlobalModDataLoad)
Events.OnClientCommand.Add(onClientCommand)
Events.OnReceiveGlobalModData.Add(onRecieveGlobalModData)
