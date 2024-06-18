require "TorchFix_Main"
require "ISUI/ISHotbar"

local baseISHotbarActivateSlot = ISHotbar.activateSlot
function ISHotbar:activateSlot(slotIndex)

	local item = self.attachedItems[slotIndex]
	if not item then return end
	if item:getAttachedSlot() ~= slotIndex then
		error "item:getAttachedSlot() ~= slotIndex"
	end

    baseISHotbarActivateSlot(self, slotIndex)

    if not item:canEmitLight() then
        return
    end
    
    local player = getPlayer()

    if player == nil or player:isDead() then return end

    if TorchFix.AttachLightManager:isEmpty() then return end

    local attachedItems = player:getAttachedItems()
    local copyModData = TorchFix.AttachLightManager:getCopy()

    for attachedIndex, lightItem in pairs(copyModData) do
        local attachedItem = attachedItems:getItemByIndex(attachedIndex)
        if attachedItem == item then
            local isActivated = attachedItem:isActivated()
            if lightItem.isActivated ~= isActivated then
                TorchFix.syncRemoteTorches(player, attachedIndex, attachedItem:getUsedDelta(), isActivated)
            end
            return
        end
    end


end