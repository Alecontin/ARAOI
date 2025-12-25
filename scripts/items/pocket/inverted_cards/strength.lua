local card = {}

card.ID = ARAOI.CardSubType.INVERTED_STRENGTH
card.Replace = Card.CARD_REVERSE_STRENGTH

ARAOI.Inverted_Cards.Strength = card

---@param player EntityPlayer
---@param useFlags UseFlag
function ARAOI:_OnInvertedCardStrengthUse(_, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsActiveEnemy() then
            entity:ToNPC():MakeChampion(entity.InitSeed)
        end
    end
end
ARAOI:AddCallback(ModCallbacks.MC_USE_CARD, ARAOI._OnInvertedCardStrengthUse, card.ID)


ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{Crown}} Transforms all enemies in the room into a random champion variant"
    )
end)

return card