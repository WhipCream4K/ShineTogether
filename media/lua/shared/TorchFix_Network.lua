
TorchFixNetwork = TorchFixNetwork or {}

TorchFixNetwork.Module = "TorchFixModule" -- !!This module name cannot be changed because it is hard coded in the GameServer.class
TorchFixNetwork.Commands = {
    requestAttachedLights = "requestAttachedLights",
    transmitToServer = "transmitToServer",
    transmitToClients = "transmitToClients"
}

return TorchFixNetwork