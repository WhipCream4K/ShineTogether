-- require "TorchFix_Variables"
-- require "TorchFix_Main"
require "TorchFix_AttachedLightManager"
local Network = require "TorchFix_Network"

if isClient() then return end

-- TF_ServerCommands                = {}
-- TF_ServerCommands.TorchFixModule = {}

-- TF_Server                        = {}
-- TF_Server.modData                = {}

TorchFixServer = {}
TorchFixServer.tempData = nil
TorchFixServer[Network.Module] = {}

local ServerOps = TorchFixServer[Network.Module]
ServerOps[Network.Commands.transmitAttachedLights] = function(player, args)

    local playerID = player:getOnlineID()

    local serverTempData = TorchFixServer.tempData
    serverTempData[playerID] = AttachedLightManager.isValid(args) and args or nil

end

ServerOps[Network.Commands.requestAttachedLights] = function(player, args)
    sendServerCommand(player, Network.Module, Network.Commands.requestAttachedLights, TorchFixServer.tempData)
end

ServerOps[Network.Commands.transmitLightState] = function(player, args)
    local outData = {}
    outData.senderID = player:getOnlineID()
    outData.lights = AttachedLightManager.isValid(args) and args or nil
    sendServerCommand(Network.Module, Network.Commands.transmitLightState, outData)
end



-- TF_ServerCommands.TorchFixModule.SetActivate = function(player, args)
--     sendServerCommand(TorchFix_Network.Module, TorchFix_Network.Commands.SetActivate, args)
-- end

-- TF_ServerCommands.TorchFixModule.SendDefferedUpdate = function(player, args)
--     local playerID = player:getOnlineID()

--     local outData = {}
--     outData.senderID = playerID
--     outData.modData = args


--     -- for attachedIndex, lightItem in pairs(args) do
--     --     -- print("Attached Index: " .. attachedIndex)
--     --     for i, v in pairs(lightItem) do
--     --         print(tostring(i), tostring(v))
--     --     end
--     -- end

--     sendServerCommand(TorchFix_Network.Module, TorchFix_Network.Commands.SendDefferedUpdate, outData)
-- end

-- local function onClientCommand(module, command, player, args)
--     if TF_ServerCommands[module] and TF_ServerCommands[module][command] then
--         TF_ServerCommands[module][command](player, args)
--     end
-- end

-- local function onRecieveGlobalModData(key, modData)
--     if ModDataHandler.checkGlobalModDataKey(key) then

--         -- print("Received global modData with key: " .. key)

--         local requesterOnlineID = ModDataHandler.getOnlineIDFromKey(key)

--         if requesterOnlineID then
            
--             -- player might want to save to server global mod data
--             local globalModData = TF_Server.modData:getRef()
--             globalModData[requesterOnlineID] = modData

--         end
--     end
-- end

-- local lpairs = pairs
-- local function onServerStepUpdate()
--     -- we are going to update the modData
--     if TF_Server.modData:isEmpty() then return end

--     local serverModData = TF_Server.modData:getRef()

--     local removeList = {}
--     for playerIndex, _ in lpairs(serverModData) do
--         local player = getPlayerByOnlineID(playerIndex)
--         if player == nil then
--             table.insert(removeList, playerIndex)
--             print("Player with onlineID: " .. playerIndex .. " has disconnected. Removing from serverModData.")
--         end
--     end


--     for _, playerIndex in lpairs(removeList) do
--         serverModData[playerIndex] = nil
--     end
-- end

-- local function onGlobalModDataLoad(isNewGame)
--     -- print("TorchFix Server is starting")
--     TF_Server.modData = ModDataHandler:new()
--     TF_Server.modData:init(ModDataHandler.getGlobalModDataKey(), {})
-- end

TorchFixServer.onGameStart = function()
    TorchFixServer.tempData = {}
end

Events.OnGameStart.Add(TorchFixServer.onGameStart)

-- Events.EveryOneMinute.Add(onServerStepUpdate)
-- Events.OnInitGlobalModData.Add(onGlobalModDataLoad)
-- Events.OnClientCommand.Add(onClientCommand)
-- Events.OnReceiveGlobalModData.Add(onRecieveGlobalModData)
