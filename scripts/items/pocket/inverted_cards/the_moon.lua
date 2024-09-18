local card = {}

card.ID = Isaac.GetCardIdByName("Inverted Moon")
card.Replace = Card.CARD_REVERSE_MOON

---@param Mod ModReference
function card:init(Mod)
    local game = Game()

    ---@param player EntityPlayer
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, function (_, _, player)
        local room = game:GetRoom()
        local rng = player:GetCardRNG(card.ID)

        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DICE_FLOOR, rng:RandomInt(6), room:GetCenterPos(), Vector.Zero, player)
    end, card.ID)

    ---@class EID
    if EID then
        EID:addCard(card.ID,
            "#{{DiceRoom}} Spawns a random Dice Room floor"
        )
    end
end

return card