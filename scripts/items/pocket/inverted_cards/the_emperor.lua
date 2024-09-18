local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Emperor")
card.Replace = Card.CARD_REVERSE_EMPEROR

---@param Mod ModReference
function card:init(Mod)
    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        player:UseActiveItem(CollectibleType.COLLECTIBLE_DELIRIOUS)
    end, card.ID)

    ---@type EID
    if EID then
        local delirious = CollectibleType.COLLECTIBLE_DELIRIOUS
        EID:addCard(card.ID,
            "#{{Collectible"..delirious.."}} Uses the Delirious active item"
        )
    end
end

return card