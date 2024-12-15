local card = {}

card.ID = ARAOI.CardSubType.INVERTED_CHARIOT
card.Replace = Card.CARD_REVERSE_CHARIOT

ARAOI.Inverted_Cards.Chariot = card

---@param player EntityPlayer
---@param useFlags UseFlag
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
    if useFlags & UseFlag.USE_CARBATTERY ~= 0 then return end
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsActiveEnemy() then
            if entity:IsBoss() then
                entity:AddFreeze(EntityRef(player), 150)
                Isaac.CreateTimer(function ()
                    entity:AddFreeze(EntityRef(player), 150)
                end, 15, 10, false)
            else
                entity:AddFreeze(EntityRef(player), 150)
                Isaac.CreateTimer(function ()
                    entity:AddFreeze(EntityRef(player), 150)
                end, 15, 999999, false)
            end
        end
    end
end, card.ID)

---@type EID
if EID then
    EID:addCard(card.ID,
        "#{{Freezing}} Petrifies all enemies in the room"
    )
end

return card