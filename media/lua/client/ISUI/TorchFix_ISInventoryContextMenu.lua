require "ISUI/ISInventoryContextMenu"
require "TorchFix_Main"

local baseISInventoryPaneContextMenuOnActivateItem = ISInventoryPaneContextMenu.onActivateItem

ISInventoryPaneContextMenu.onActivateItem = function(light, playerIndex)

    baseISInventoryPaneContextMenuOnActivateItem(light, playerIndex)

    local player = getPlayer()
    if player == nil or player:isDead() then return end

    if not player:isAttachedItem(light) then return end

    local isActivated = light:isActivated()

    local copyModData = TorchFix.attachedLight:getCopy()
    local attachedItems = player:getAttachedItems()

    for attachedIndex, lightItem in pairs(copyModData) do
        local item = attachedItems:getItemByIndex(attachedIndex)
        if item == light then
            if lightItem.isActivated ~= isActivated then
                TorchFix.syncRemoteTorches(player, attachedIndex, light:getUsedDelta(), isActivated)
            end
            return
        end
    end
end
