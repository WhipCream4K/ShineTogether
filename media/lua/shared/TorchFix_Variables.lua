
TorchFixNetwork = {}

TorchFixNetwork.ModuleName = "TorchFixModule" -- !!This module name cannot be changed because it is hard coded in the GameServer.class
TorchFixNetwork.Commands = {
    SetActivate = "SetActivate",
    SendDefferedUpdate = "SendDefferedUpdate",
    PlayerDisconnected = "PlayerDisconnected",
    Attached = "Attached" -- !!This cannot be changed because it is hard coded in the GameServer.class
}

TorchFixNetwork.ModData = {
    AttachedLightIndicies = "attachedLightIndicies",
    DirtyIndicies = "dirtyIndicies",
    AttachedLightIndex = "attachedLightIndex", -- !!This cannot be changed because it is hard coded in the GameServer.class
    OnlineID = "onlineID", -- !!This cannot be changed because it is hard coded in the GameServer.class
    Battery = "battery",
    IsActivated = "isActivated",
    SlotType = "slotType", -- !!This cannot be changed because it is hard coded in the GameServer.class
    ItemFullType = "itemFullType" -- !!This cannot be changed because it is hard coded in the GameServer.class
}

return TorchFixNetwork