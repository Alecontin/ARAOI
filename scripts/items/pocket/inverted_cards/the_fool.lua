local card = {}

card.ID = ARAOI.CardSubType.INVERTED_FOOL
card.Replace = Card.CARD_REVERSE_FOOL

ARAOI.Inverted_Cards.Fool = card

local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) and 5 or 0
    local rng = player:GetCardRNG(card.ID)
    local room = game:GetRoom()

    local items = {}
    for item, amount in pairs(ARAOI.PlayerUtils.GetCollectibleListCurated(player, {ItemType.ITEM_ACTIVE}, ItemTag.TAG_QUEST)) do
        for _ = 1, amount do
            table.insert(items, item)
        end
    end

    ARAOI.TableUtils.ShuffleTable(items, rng)

    local pedestals = ARAOI.TableUtils.SplitTable(items, 10 + tarotClothModifier)

    for _, pedestal in ipairs(pedestals) do
        ---@type EntityPickup
        local collectible_pedestal
        for _, item in ipairs(pedestal) do
            player:RemoveCollectible(item)
            if collectible_pedestal == nil then
                collectible_pedestal = ARAOI.ItemUtils.SpawnCollectible(item, room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player, true)
            else
                collectible_pedestal:AddCollectibleCycle(item)
            end
        end
    end
end, card.ID)

ARAOI.ReloadableDescription(function ()
    local restock = CollectibleType.COLLECTIBLE_RESTOCK
    EID:addCard(card.ID,
        "#{{Collectible}} Drops all of Isaac's collectibles into 10 pedestals"..
        "#{{Collectible"..restock.."}} Excess items will be added to the pedestals item cycle"
    )
    EID:addTarotClothMetadata(card.ID, {10, 15})
end)

return card