local card = {}

card.ID = ARAOI.CardSubType.INVERTED_DEATH
card.Replace = Card.CARD_REVERSE_DEATH

ARAOI.Inverted_Cards.Death = card

local game = Game()

---@param player EntityPlayer
ARAOI.Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
    local room = game:GetRoom()
    local entity = Isaac.Spawn(EntityType.ENTITY_DEATH, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
    entity:AddCharmed(EntityRef(player), -1)
end, card.ID)

ARAOI.EIDWrapper(function ()
    EID:addCard(card.ID,
        "#{{DeathMark}} Spawns a friendly Death Horseman"
    )
    ARAOI.EIDUtils.TarotClothMetadata(card.ID, {" a ", " two "})
end)

return card