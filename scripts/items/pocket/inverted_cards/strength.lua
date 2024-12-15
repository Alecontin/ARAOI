local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Strength")
card.Replace = Card.CARD_REVERSE_STRENGTH

ARAOI.Inverted_Cards.Strength = card

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsActiveEnemy() then
            entity:ToNPC():MakeChampion(entity.InitSeed)
        end
    end
end, card.ID)


---@type EID
if EID then
    EID:addCard(card.ID,
        "#{{Crown}} Transforms all enemies in the room into a random champion variant"
    )
end

return card