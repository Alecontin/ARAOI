local card = {}

card.ID = ARAOI.CardSubType.INVERTED_TOWER
card.Replace = Card.CARD_REVERSE_TOWER

ARAOI.Inverted_Cards.Tower = card

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnInvertedCardTowerUse(_, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    local tarotClothModifier = player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) and 3 or 0

    local rng = player:GetCardRNG(card.ID)

    for _ = 1, rng:RandomInt(2+tarotClothModifier, 4+tarotClothModifier) do
        local velocity = EntityPickup.GetRandomPickupVelocity(player.Position) / 2
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_THROWABLEBOMB, 0, player.Position, velocity, player)
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardTowerUse, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{Bomb}} Spawns 2-4 throwable bombs"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {2, 5, 4, 7})
end)

return card