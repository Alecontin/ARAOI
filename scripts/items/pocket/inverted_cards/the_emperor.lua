local card = {}

card.ID = ARAOI.CardSubType.INVERTED_EMPEROR
card.Replace = Card.CARD_REVERSE_EMPEROR

ARAOI.Inverted_Cards.Emperor = card

---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_DELIRIOUS)
end, card.ID)

ARAOI.EIDWrapper(function ()
    local delirious = CollectibleType.COLLECTIBLE_DELIRIOUS
    EID:addCard(card.ID,
        "#{{Collectible"..delirious.."}} Uses the Delirious active item"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, "Twice!")
end)

return card