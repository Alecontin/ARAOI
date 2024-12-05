local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Hierophant")
card.Replace = Card.CARD_REVERSE_HIEROPHANT

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    ---@param useFlags UseFlag
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player, useFlags)
        local isTarotCloth = useFlags & UseFlag.USE_CARBATTERY ~= 0
        local room = game:GetRoom()
        for _ = 1, isTarotCloth and 1 or 2 do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK,
                        room:FindFreePickupSpawnPosition(player.Position,50), Vector.Zero, player)
        end
    end, card.ID)

    ---@type EID
    if EID then
        EID:addCard(card.ID,
            "#{{BlackHeart}} Spawns 2 Black Hearts"
        )
        EID:addTarotClothMetadata(card.ID, {2, 3})
    end
end

return card