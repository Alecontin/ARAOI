local card = {}

card.Replace = Card.CARD_REVERSE_DEATH
card.ID = Isaac.GetCardIdByName("Inverted Death")

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local entity = Isaac.Spawn(EntityType.ENTITY_DEATH, 0, 0, room:GetRandomPosition(0), Vector.Zero, player)
        entity:AddCharmed(EntityRef(player), -1)
    end, card.ID)

    ---@type EID
    if EID then
        EID:addCard(card.ID,
            "#{{DeathMark}} Spawns a friendly Death Horseman"
        )
    end
end

return card