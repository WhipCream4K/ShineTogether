require "TorchFix_Main"
require "Items/ItemBindingHandler"

if ItemBindingHandler == nil then return end

local baseItemBindingHandlerToggleLight = ItemBindingHandler.toggleLight
function ItemBindingHandler.toggleLight(key)
    
    baseItemBindingHandlerToggleLight(key)

    local player = getPlayer()
    if player == nil or player:isDead() then return end
    
    if TorchFix.AttachLightManager:isEmpty() then return end

    local copyModData = TorchFix.AttachLightManager:getCopy()
    local attachedItems = player:getAttachedItems()

    for attachedIndex, lightItem in pairs(copyModData) do
        local attachedItem = attachedItems:getItemByIndex(attachedIndex)
        if TorchFix.isLightItem(attachedItem) then
            local isActivated = attachedItem:isActivated()
            if lightItem.isActivated ~= isActivated then
                TorchFix.syncRemoteTorches(player, attachedIndex, attachedItem:getUsedDelta(), isActivated)
                return
            end
        end
    end

end