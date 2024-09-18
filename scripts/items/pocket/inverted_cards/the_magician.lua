local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Magician")
card.Replace = Card.CARD_REVERSE_MAGICIAN

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseCard(Card.CARD_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        player:UseCard(Card.CARD_REVERSE_MAGICIAN, UseFlag.USE_NOANIM | UseFlag.USE_NOANNOUNCER)
        player:AddCollectibleEffect(CollectibleType.COLLECTIBLE_FATE, true)
    end, card.ID)

    ---@param player EntityPlayer
    ---@param flag CacheFlag
    Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
        if flag == CacheFlag.CACHE_FLYING then
            if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_FATE) then
                player.CanFly = true
            end
        end
    end)

    ---@class EID
    if EID then
        local the_magician = Card.CARD_MAGICIAN
        EID:addCard(card.ID,
            "#{{ArrowUp}} Activates the effects of both {{Card"..the_magician.."}} The Magician and {{Card"..card.Replace.."}} The Magician? and gives you flight for the room"
        )
    end
end

return card