require "ISUI/ISCrafting"
require "TorchFix_Main"

-- We only have problem with remove battery because it is the only action that if done,
-- the item still remain attached to the player but the light is turned off
-- so we need to update to remote players
local baseISCraftActionPerform = ISCraftAction.perform
function ISCraftAction:perform()

    baseISCraftActionPerform(self)

    print("Performing crafting using torch as a base item")
    print("Item name: " .. self.item:getName())

    local player = self.character
    local item = self.item

    if not TorchFix.isLightItem(item) then return end

    if TorchFix.AttachLightManager:isEmpty() then return end

    local copyModData = TorchFix.AttachLightManager:getCopy()

    local attachedItems = player:getAttachedItems()

    for attachedIndex,lightItem in pairs(copyModData) do
        local attachedItem = attachedItems:getItemByIndex(attachedIndex)
        if attachedItem == item then
            -- this means that the item is still attached to the player
            -- check if it's still activated
            if not attachedItem:canEmitLight() then
                print("Item is not emitting light")
                TorchFix.syncRemoteTorches(player, attachedIndex, attachedItem:getUsedDelta(), false)
            end

            break
        end
    end
end
