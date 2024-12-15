local card = {}

card.ID = ARAOI.CardSubType.INVERTED_MAGICIAN
card.Replace = Card.CARD_REVERSE_MAGICIAN

ARAOI.Inverted_Cards.Magician = card

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    player:UseCard(Card.CARD_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
    player:UseCard(Card.CARD_REVERSE_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
    player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_FATE, true)
end, card.ID)

---@param player EntityPlayer
---@param flag CacheFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
    if flag == CacheFlag.CACHE_FLYING then
        if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_FATE) then
            player.CanFly = true
        end
    end
end)

ARAOI.ReloadableDescription(function ()
    local the_magician = Card.CARD_MAGICIAN
    EID:addCard(card.ID,
        "#{{ArrowUp}} Activates the effects of both {{Card"..the_magician.."}} The Magician and {{Card"..card.Replace.."}} The Magician? and gives you flight for the room"
    )
end)

return card