local card = {}

card.ID = ARAOI.CardSubType.INVERTED_LOVERS
card.Replace = Card.CARD_REVERSE_LOVERS

ARAOI.Inverted_Cards.Lovers = card

local game = Game()

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local room = game:GetRoom()
    local rng = player:GetCardRNG(card.ID)

    local familiars = ARAOI.PlayerUtils.GetCollectibleListCurated(player, nil, ItemTag.TAG_QUEST, {ItemType.ITEM_FAMILIAR})
    if #ARAOI.TableUtils.Keys(familiars) < 3 then
        player:UseCard(card.Replace, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        return
    end

    -- Store this for later, so we can bypass damocles
    local removed_familiars = 0
    for familiar_id, familiar_amount in pairs(familiars) do
        for _ = 1, familiar_amount do
            player:RemoveCollectible(familiar_id)
            removed_familiars = removed_familiars + 1
        end
    end
    for _ = 1, math.floor(removed_familiars / 3) do
        ARAOI.ItemUtils.SpawnCollectible(room:GetSeededCollectible(rng:GetSeed()), room:FindFreePickupSpawnPosition(player.Position, 50), Vector.Zero, player)
    end
end, card.ID)

ARAOI.ReloadableDescription(function ()
    local altar = CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR
    EID:addCard(card.ID,
        "#{{Collectible"..altar.."}} Removes all familiars and spawns an item from the current room's item pool for every 3 familiars removed"..
        "#{{Card"..card.Replace.."}} If used when having less than 3 familiars, it will act like {{Card"..card.Replace.."}} The Lovers?"
    )
    EID:addTarotClothMetadata(card.ID, "I had to rebalance this items 3 times already, so this is not gonna happen any time soon.")
end)

return card