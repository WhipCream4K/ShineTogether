
TorchFixNetwork = TorchFixNetwork or {}

TorchFixNetwork.Module = "TorchFixModule" -- !!This module name cannot be changed because it is hard coded in the GameServer.class
TorchFixNetwork.Commands = {
    SetActivate = "SetActivate",
    SendDefferedUpdate = "SendDefferedUpdate",
    PlayerDisconnected = "PlayerDisconnected",
    -- Attached = "Attached" -- !!This cannot be changed because it is hard coded in the GameServer.class
    requestAttachedLights = "requestAttachedLights",
    transmitToServer = "transmitToServer",
    transmitToClients = "transmitToClients"
}

return TorchFixNetwork