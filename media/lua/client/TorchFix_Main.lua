require "TorchFix_AttachedLightManager"

TorchFix = {}

-- Main variables
TorchFix.AttachLightManager = nil

TorchFix.stepUpdate = function ()
    TorchFix.AttachLightManager:onOneMinute()
end

TorchFix.onPlayerUpdate = function (player)
    
    TorchFix.AttachLightManager:playerUpdate(player)

end

TorchFix.onCreatePlayer = function(playerIndex)
    
    if playerIndex == 0 then
        
        -- this is for the time when the player is dead and want to start a new game
        Events.EveryOneMinute.Add(TorchFix.onFadeToWorld)
        
    end

end

TorchFix.getAttachedLightManager = function()
    return TorchFix.AttachLightManager
end

TorchFix.onClothingUpdated = function(player)

    if isClient() then
        TorchFix.AttachLightManager:refresh(player)        
    end

end

TorchFix.onFadeToWorld = function ()

    local player = getPlayer()
    if player == nil then return end

    TorchFix.AttachLightManager = AttachedLightManager:new(player)

    Events.OnPlayerUpdate.Add(TorchFix.onPlayerUpdate)
    Events.OnClothingUpdated.Add(TorchFix.onClothingUpdated)
    -- Events.EveryOneMinute.Add(TorchFix.stepUpdate)

    Events.EveryOneMinute.Remove(TorchFix.onFadeToWorld)
end

Events.OnCreatePlayer.Add(TorchFix.onCreatePlayer)

return TorchFix
