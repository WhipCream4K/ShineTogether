require "TimedActions/ISInventoryTransferAction"
require "TorchFix_Main"


local baseISInventoryTransferActionPerform = ISInventoryTransferAction.perform
function ISInventoryTransferAction:perform()
    
    baseISInventoryTransferActionPerform(self)

    local player = self.character
    local item = self.item

    if TorchFix.isLightItem(item) then return end

    if TorchFix.AttachLightManager:isEmpty() then return end

    local copyModData = TorchFix.AttachLightManager:getCopy()

    local attachedItems = player:getAttachedItems()

    for attachedIndex,lightItem in pairs(copyModData) do
        local attachedItem = attachedItems:getItemByIndex(attachedIndex)
        if attachedItem == item  then
            local isActivated = attachedItem:isActivated()
            if lightItem.isActivated ~= isActivated then
                TorchFix.syncRemoteTorches(player, attachedIndex, attachedItem:getUsedDelta(), not isActivated)
            end
            return
        end
    end

end